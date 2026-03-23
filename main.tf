# Create resource group for all resources.

resource "azurerm_resource_group" "this" {
  name     = "rg-${var.resource_suffix}"
  location = var.location
  tags     = var.tags
}

# Create virtual network for the Application Gateway.

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.resource_suffix}"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

# Create subnet for the Application Gateway.

resource "azurerm_subnet" "app_gateway" {
  name                 = var.app_gateway_subnet_name
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.app_gateway_subnet_prefix]
}

# Retreive information about the current Azure client configuration, including tenant ID and object ID, for use in configuring access policies in Key Vault.

data "azurerm_client_config" "current" {}

# Create an Azure Key Vault to store the TLS certificate for the Application Gateway. 
# The Key Vault is configured with access policies to allow the Application Gateway's user assigned identity to read the certificate, and to allow the Azure Automation runbook for certificate renewal to manage the certificate.

module "keyvault" {
  source  = "app.terraform.io/benoitblais-hashicorp/keyvault/azurerm"
  version = "0.0.1"

  name                            = "kv-${var.resource_suffix}"
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = "standard"
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  purge_protection_enabled        = false
  soft_delete_retention_days      = var.key_vault_soft_delete_retention_days
  public_network_access_enabled   = true
  tags                            = var.tags

  access_policies = concat(
    [
      {
        tenant_id               = data.azurerm_client_config.current.tenant_id
        object_id               = azurerm_user_assigned_identity.app_gateway.principal_id
        certificate_permissions = []
        key_permissions         = []
        secret_permissions      = ["Get", "List"]
        storage_permissions     = []
      },
      {
        tenant_id               = data.azurerm_client_config.current.tenant_id
        object_id               = data.azurerm_client_config.current.object_id
        certificate_permissions = ["Create", "Delete", "Get", "Import", "List", "Purge", "Recover", "Update"]
        key_permissions         = []
        secret_permissions      = ["Get", "List", "Set"]
        storage_permissions     = []
      }
    ],
    [
      {
        tenant_id               = data.azurerm_client_config.current.tenant_id
        object_id               = azurerm_automation_account.certificate_renewal.identity[0].principal_id
        certificate_permissions = ["Create", "Get", "Import", "List", "Update"]
        key_permissions         = []
        secret_permissions      = ["Get", "List", "Set"]
        storage_permissions     = []
      }
    ]
  )

  network_acls = {
    bypass                     = "AzureServices"
    default_action             = "Allow"
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }
}

# Create an initial certificate in Key Vault to be used by the Application Gateway. 
# The certificate is configured with a short validity period to allow testing of the renewal process. 
# The certificate resource is configured to ignore changes to the certificate and certificate policy in order to prevent unnecessary updates when the certificate is renewed in Key Vault.

resource "azurerm_key_vault_certificate" "bootstrap" {
  name         = var.key_vault_certificate_name
  key_vault_id = module.keyvault.id

  certificate_policy {
    issuer_parameters {
      name = "Unknown"
    }

    lifetime_action {
      action {
        action_type = "EmailContacts"
      }

      trigger {
        days_before_expiry  = 0
        lifetime_percentage = 80
      }
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = false
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      subject            = "CN=${var.initial_certificate_common_name}"
      validity_in_months = 1

      key_usage = [
        "digitalSignature",
        "keyAgreement",
        "keyEncipherment"
      ]

      extended_key_usage = [
        "1.3.6.1.5.5.7.3.1",
        "1.3.6.1.5.5.7.3.2"
      ]

      subject_alternative_names {
        dns_names = [var.initial_certificate_common_name]
        emails    = []
        upns      = []
      }
    }
  }

  lifecycle {
    ignore_changes = [certificate, certificate_policy]
  }

  depends_on = [module.keyvault]
}

# Create a user assigned identity for the Application Gateway and assign it to the resource.
# This identity will be used to access the SSL certificate stored in Key Vault.

resource "azurerm_user_assigned_identity" "app_gateway" {
  name                = "appgw-identity-${var.resource_suffix}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = var.tags
}

# Create a public IP address for the Application Gateway frontend configuration. The public IP is required for the Application Gateway to be able to access the SSL certificate in Key Vault using the user assigned identity.

resource "azurerm_public_ip" "app_gateway" {
  name                = "appgw-pip-${var.resource_suffix}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Create an Azure Application Gateway with a frontend IP configuration, backend pool, HTTP settings, and an SSL certificate sourced from Azure Key Vault.
# The Application Gateway is configured to ignore changes to the SSL certificate in order to prevent unnecessary updates when the certificate is renewed in Key Vault.

resource "azurerm_application_gateway" "this" {
  name                = "appgw-${var.resource_suffix}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = var.tags

  sku {
    name = var.app_gateway_sku_name
    tier = var.app_gateway_sku_tier
  }

  autoscale_configuration {
    min_capacity = var.app_gateway_autoscale_min_capacity
    max_capacity = var.app_gateway_autoscale_max_capacity
  }

  gateway_ip_configuration {
    name      = var.app_gateway_gateway_ip_configuration_name
    subnet_id = azurerm_subnet.app_gateway.id
  }

  frontend_port {
    name = var.app_gateway_frontend_port_name
    port = var.app_gateway_frontend_port
  }

  frontend_ip_configuration {
    name                 = var.app_gateway_frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.app_gateway.id
  }

  backend_address_pool {
    name  = var.app_gateway_backend_address_pool_name
    fqdns = var.app_gateway_backend_address_pool_fqdns
  }

  backend_http_settings {
    name                  = var.app_gateway_backend_http_settings_name
    cookie_based_affinity = var.app_gateway_backend_http_settings_cookie_based_affinity
    path                  = var.app_gateway_backend_http_settings_path
    port                  = var.app_gateway_backend_http_settings_port
    protocol              = var.app_gateway_backend_http_settings_protocol
    request_timeout       = var.app_gateway_backend_http_settings_request_timeout
  }

  ssl_certificate {
    name                = var.app_gateway_ssl_certificate_name
    key_vault_secret_id = azurerm_key_vault_certificate.bootstrap.versionless_secret_id
  }

  http_listener {
    name                           = var.app_gateway_http_listener_name
    frontend_ip_configuration_name = var.app_gateway_frontend_ip_configuration_name
    frontend_port_name             = var.app_gateway_frontend_port_name
    protocol                       = var.app_gateway_http_listener_protocol
    ssl_certificate_name           = var.app_gateway_ssl_certificate_name
  }

  request_routing_rule {
    name                       = var.app_gateway_request_routing_rule_name
    priority                   = var.app_gateway_request_routing_rule_priority
    rule_type                  = var.app_gateway_request_routing_rule_type
    http_listener_name         = var.app_gateway_http_listener_name
    backend_address_pool_name  = var.app_gateway_backend_address_pool_name
    backend_http_settings_name = var.app_gateway_backend_http_settings_name
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app_gateway.id]
  }

  lifecycle {
    ignore_changes = [ssl_certificate]
  }

  depends_on = [
    azurerm_key_vault_certificate.bootstrap
  ]
}

# Use the storage account module to create a storage account for hosting Python packages used by the automation runbook for certificate renewal.
# The module also creates a blob container and uploads the specified Python package wheel file.

module "storage_account" {
  source  = "app.terraform.io/benoitblais-hashicorp/storage-account/azurerm"
  version = "0.0.4"

  name                              = trimspace(var.storage_account_name) != "" ? var.storage_account_name : substr("st${replace(lower(var.resource_suffix), "-", "")}", 0, 24)
  resource_group_name               = azurerm_resource_group.this.name
  location                          = azurerm_resource_group.this.location
  allow_nested_items_to_be_public   = var.storage_allow_nested_items_to_be_public
  infrastructure_encryption_enabled = var.storage_infrastructure_encryption_enabled
  local_user_enabled                = var.storage_local_user_enabled
  shared_access_key_enabled         = var.storage_shared_access_key_enabled
  tags                              = var.tags

  blob_properties = {
    change_feed_enabled      = var.storage_blob_change_feed_enabled
    last_access_time_enabled = var.storage_blob_last_access_time_enabled
    versioning_enabled       = var.storage_blob_versioning_enabled
  }

  storage_containers = [
    {
      name                  = var.storage_container_name
      container_access_type = var.storage_container_access_type
    }
  ]

  storage_blobs = [
    {
      name           = var.storage_blob_name
      container_name = var.storage_container_name
      type           = var.storage_blob_type
      source         = var.storage_blob_source
      access_tier    = var.storage_blob_access_tier
      content_type   = var.storage_blob_content_type
      parallelism    = var.storage_blob_parallelism
    }
  ]
}

# Generate a SAS token for the storage account to allow the automation runbook to access the Python package blob for certificate renewal.

data "azurerm_storage_account_sas" "automation_packages" {
  connection_string = module.storage_account.storage_account_primary_connection_string
  https_only        = true
  start             = "2024-01-01"
  expiry            = "2099-01-01"

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  resource_types {
    service   = true
    container = true
    object    = true
  }

  permissions {
    read    = true
    list    = true
    write   = false
    add     = false
    create  = false
    delete  = false
    update  = false
    process = false
    tag     = false
    filter  = false
  }
}

# Create an Azure Automation Python 3 package for the cryptography library used by the certificate renewal runbook, with content sourced from the storage account blob.

resource "azurerm_automation_python3_package" "cryptography" {
  name                    = "cryptography"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal.name
  content_uri             = "${module.storage_account.storage_blob_urls["${var.storage_container_name}/${var.storage_blob_name}"]}?${data.azurerm_storage_account_sas.automation_packages.sas}"
  tags                    = var.tags

  lifecycle {
    ignore_changes = [content_uri]
  }
}

# Creating policy to allow certificate issuance from Vault PKI secrets engine for workloads authenticated with AppRole. 

resource "vault_policy" "workload_pki_issue" {
  name = var.vault_policy_name

  policy = <<EOT
path "${var.vault_pki_path}/issue/${var.vault_pki_role}" {
  capabilities = ["create", "update"]
}
EOT
}

# Enable AppRole auth method for workload authentication to Vault.

resource "vault_auth_backend" "approle" {
  type = "approle"
  path = "approle"
}

# Create AppRole with permissions to request certificate issuance from Vault PKI secrets engine.

resource "vault_approle_auth_backend_role" "workload" {
  backend                 = vault_auth_backend.approle.path
  role_name               = var.vault_approle_role_name
  bind_secret_id          = true
  secret_id_num_uses      = 0
  secret_id_ttl           = 0
  token_num_uses          = 0
  token_ttl               = var.vault_approle_token_ttl
  token_max_ttl           = var.vault_approle_token_max_ttl
  token_explicit_max_ttl  = 0
  token_period            = 0
  token_no_default_policy = false
  token_type              = "default"
  token_policies          = [vault_policy.workload_pki_issue.name]
}

# Create AppRole secret ID for workload authentication.

resource "vault_approle_auth_backend_role_secret_id" "workload" {
  backend   = vault_auth_backend.approle.path
  role_name = vault_approle_auth_backend_role.workload.role_name
  metadata  = jsonencode({})
  num_uses  = 0
  ttl       = 0
}

# Create Vault PKI secret backend role for certificate issuance by automation.

resource "vault_pki_secret_backend_role" "bootstrap" {
  backend        = var.vault_pki_path
  name           = var.vault_pki_role
  allow_any_name = true
  max_ttl        = var.vault_pki_role_max_ttl
}

# Compute the Vault auth path used by the runbook when no token is provided.

locals {
  automation_vault_auth_path = trimspace(var.azure_automation_vault_auth_path) != "" ? var.azure_automation_vault_auth_path : "approle"
}

# Generate a stable PFX password for the runbook.

resource "random_password" "bootstrap_pfx_password" {
  length           = 32
  special          = true
  override_special = "!@#%^*-_=+"
}

# Create the Azure Automation account that runs the renewal workflow.

resource "azurerm_automation_account" "certificate_renewal" {
  name                = var.azure_automation_account_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "Basic"
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }
}

# Upload the runbook that issues and imports certificates.

resource "azurerm_automation_runbook" "certificate_renewal" {
  name                    = var.azure_automation_runbook_name
  location                = azurerm_resource_group.this.location
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal.name
  log_progress            = true
  log_verbose             = var.azure_automation_runbook_log_verbose
  runbook_type            = "Python"
  content                 = file("${path.module}/scripts/automation_runbook.py")
}

# Configure certificate request inputs for the runbook.

resource "azurerm_automation_variable_string" "cert_common_name" {
  name                    = "CERT_COMMON_NAME"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal.name
  value                   = var.initial_certificate_common_name
}

# Configure certificate TTL input for the runbook.

resource "azurerm_automation_variable_string" "cert_ttl" {
  name                    = "CERT_TTL"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal.name
  value                   = var.initial_certificate_ttl
}

# Provide Key Vault certificate name to the runbook.

resource "azurerm_automation_variable_string" "key_vault_cert_name" {
  name                    = "AZURE_KEYVAULT_CERT_NAME"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal.name
  value                   = var.key_vault_certificate_name
}

# Provide Key Vault name to the runbook.

resource "azurerm_automation_variable_string" "key_vault_name" {
  name                    = "AZURE_KEYVAULT_NAME"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal.name
  value                   = module.keyvault.keyvault.name
}

# Provide the PFX password used when importing the certificate.

resource "azurerm_automation_variable_string" "pfx_password" {
  name                    = "PFX_PASSWORD"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal.name
  value                   = random_password.bootstrap_pfx_password.result
  encrypted               = true
}

# Provide Application Gateway name to the runbook.

resource "azurerm_automation_variable_string" "app_gateway_name" {
  name                    = "AZURE_APP_GATEWAY_NAME"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal.name
  value                   = azurerm_application_gateway.this.name
}

# Provide Application Gateway resource group to the runbook.

resource "azurerm_automation_variable_string" "app_gateway_resource_group" {
  name                    = "AZURE_APP_GATEWAY_RESOURCE_GROUP"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal.name
  value                   = azurerm_resource_group.this.name
}

# Provide Application Gateway SSL certificate name to the runbook.

resource "azurerm_automation_variable_string" "app_gateway_ssl_cert_name" {
  name                    = "AZURE_APP_GATEWAY_SSL_CERT_NAME"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal.name
  value                   = var.app_gateway_ssl_certificate_name
}

# Provide subscription ID to the runbook.

resource "azurerm_automation_variable_string" "subscription_id" {
  name                    = "AZURE_SUBSCRIPTION_ID"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal.name
  value                   = var.subscription_id
}

# Provide Vault address to the runbook.

resource "azurerm_automation_variable_string" "vault_addr" {
  name                    = "VAULT_ADDR"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal.name
  value                   = var.vault_addr
}

# Provide Vault auth path override to the runbook.

resource "azurerm_automation_variable_string" "vault_auth_path" {
  name                    = "VAULT_AUTH_PATH"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal.name
  value                   = local.automation_vault_auth_path
}

# Provide Vault namespace to the runbook.

resource "azurerm_automation_variable_string" "vault_namespace" {
  name                    = "VAULT_NAMESPACE"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal.name
  value                   = var.vault_namespace
}

# Provide Vault PKI mount path to the runbook.

resource "azurerm_automation_variable_string" "vault_pki_path" {
  name                    = "VAULT_PKI_PATH"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal.name
  value                   = var.vault_pki_path
}

# Provide Vault PKI role name to the runbook.

resource "azurerm_automation_variable_string" "vault_pki_role" {
  name                    = "VAULT_PKI_ROLE"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal.name
  value                   = var.vault_pki_role
}

# Provide Vault AppRole role ID to the runbook.

resource "azurerm_automation_variable_string" "vault_approle_role_id" {
  name                    = "VAULT_APPROLE_ROLE_ID"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal.name
  value                   = vault_approle_auth_backend_role.workload.role_id
}

# Provide Vault AppRole secret ID to the runbook.

resource "azurerm_automation_variable_string" "vault_approle_secret_id" {
  name                    = "VAULT_APPROLE_SECRET_ID"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal.name
  value                   = vault_approle_auth_backend_role_secret_id.workload.secret_id
  encrypted               = true
}

# Provide Vault TLS behavior to the runbook.

resource "azurerm_automation_variable_string" "vault_tls_skip_verify" {
  name                    = "VAULT_TLS_SKIP_VERIFY"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal.name
  value                   = "true"
}

# Schedule the runbook execution.

resource "azurerm_automation_schedule" "certificate_renewal" {
  name                    = var.azure_automation_schedule_name
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal.name
  frequency               = "Hour"
  interval                = var.azure_automation_schedule_interval_hours
  timezone                = var.azure_automation_schedule_timezone
  start_time              = var.azure_automation_schedule_start_time
  description             = "Hourly certificate renewal runbook schedule"
}

# Link the runbook to the schedule.

resource "azurerm_automation_job_schedule" "certificate_renewal" {
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal.name
  schedule_name           = azurerm_automation_schedule.certificate_renewal.name
  runbook_name            = azurerm_automation_runbook.certificate_renewal.name

  depends_on = [module.keyvault]
}

# Allow Automation to update Application Gateway.

resource "azurerm_role_assignment" "automation_app_gateway_update" {
  scope                = azurerm_resource_group.this.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_automation_account.certificate_renewal.identity[0].principal_id
}
