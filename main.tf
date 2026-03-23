locals {
  bootstrap_key_vault_secret_id = module.keyvault_certificate_management.certificates[var.key_vault_certificate_name].versionless_secret_id
  bootstrap_pem_bundle = join("\n", compact([
    vault_pki_secret_backend_cert.bootstrap.certificate,
    vault_pki_secret_backend_cert.bootstrap.private_key
  ]))
  create_azure_automation_runbook = var.enable_azure_automation_runbook
  store_bootstrap_pfx_password    = var.bootstrap_pfx_password_store_in_vault && trimspace(var.bootstrap_pfx_password_kv_mount) != "" && trimspace(var.bootstrap_pfx_password_kv_path) != ""
  create_vault_jwt_auth           = var.enable_vault_jwt_auth && var.vault_pki_path != "" && var.vault_pki_role != ""
  key_vault_access_configurations = concat(
    [
      {
        tenant_id               = data.azurerm_client_config.current.tenant_id
        object_id               = data.azurerm_client_config.current.object_id
        certificate_permissions = ["Create", "Delete", "Get", "Import", "List", "Update"]
        secret_permissions      = ["Get", "List", "Set"]
      },
      {
        tenant_id          = azurerm_user_assigned_identity.app_gateway.tenant_id
        object_id          = azurerm_user_assigned_identity.app_gateway.principal_id
        secret_permissions = ["Get", "List"]
      }
    ],
    local.create_azure_automation_runbook ? [
      {
        tenant_id               = data.azurerm_client_config.current.tenant_id
        object_id               = azurerm_automation_account.certificate_renewal[0].identity[0].principal_id
        certificate_permissions = ["Create", "Get", "Import", "List", "Update"]
        secret_permissions      = ["Get", "List", "Set"]
      }
    ] : []
  )
  name_prefix                     = lower(replace(var.name_prefix, "_", "-"))
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "this" {
  name                = "${local.name_prefix}-vnet"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

resource "azurerm_subnet" "app_gateway" {
  name                 = "${local.name_prefix}-appgw-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.app_gateway_subnet_prefix]
}

resource "azurerm_public_ip" "app_gateway" {
  name                = "${local.name_prefix}-appgw-pip"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "app_gateway" {
  name                = "${local.name_prefix}-appgw-identity"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = var.tags
}

module "keyvault" {
  source  = "app.terraform.io/benoitblais-hashicorp/terraform-azurerm-keyvault/azurerm"
  version = "0.0.1"

  name                            = substr(replace("${local.name_prefix}kv", "-", ""), 0, 24)
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = "standard"
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  purge_protection_enabled        = false
  soft_delete_retention_days      = 7
  tags                            = var.tags

  access_configurations = local.key_vault_access_configurations
}

resource "azurerm_automation_account" "certificate_renewal" {
  count = local.create_azure_automation_runbook ? 1 : 0

  name                = var.azure_automation_account_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "Basic"
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_automation_runbook" "certificate_renewal" {
  count = local.create_azure_automation_runbook ? 1 : 0

  name                    = var.azure_automation_runbook_name
  location                = azurerm_resource_group.this.location
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal[0].name
  log_progress            = true
  log_verbose             = var.azure_automation_runbook_log_verbose
  runbook_type            = "Python3"
  content                 = file("${path.module}/scripts/automation_runbook.py")
}

resource "azurerm_automation_variable_string" "cert_common_name" {
  count = local.create_azure_automation_runbook ? 1 : 0

  name                    = "CERT_COMMON_NAME"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal[0].name
  value                   = var.initial_certificate_common_name
}

resource "azurerm_automation_variable_string" "cert_ttl" {
  count = local.create_azure_automation_runbook ? 1 : 0

  name                    = "CERT_TTL"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal[0].name
  value                   = var.initial_certificate_ttl
}

resource "azurerm_automation_variable_string" "key_vault_cert_name" {
  count = local.create_azure_automation_runbook ? 1 : 0

  name                    = "AZURE_KEYVAULT_CERT_NAME"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal[0].name
  value                   = var.key_vault_certificate_name
}

resource "azurerm_automation_variable_string" "key_vault_name" {
  count = local.create_azure_automation_runbook ? 1 : 0

  name                    = "AZURE_KEYVAULT_NAME"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal[0].name
  value                   = module.keyvault.keyvault.name
}

resource "azurerm_automation_variable_string" "pfx_password" {
  count = local.create_azure_automation_runbook ? 1 : 0

  name                    = "PFX_PASSWORD"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal[0].name
  value                   = random_password.bootstrap_pfx_password.result
  encrypted               = true
}

resource "azurerm_automation_variable_string" "vault_addr" {
  count = local.create_azure_automation_runbook ? 1 : 0

  name                    = "VAULT_ADDR"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal[0].name
  value                   = var.vault_addr
}

resource "azurerm_automation_variable_string" "vault_auth_path" {
  count = local.create_azure_automation_runbook ? 1 : 0

  name                    = "VAULT_AUTH_PATH"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal[0].name
  value                   = var.azure_automation_vault_auth_path
}

resource "azurerm_automation_variable_string" "vault_auth_role" {
  count = local.create_azure_automation_runbook ? 1 : 0

  name                    = "VAULT_AUTH_ROLE"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal[0].name
  value                   = var.azure_automation_vault_auth_role
}

resource "azurerm_automation_variable_string" "vault_jwt_audience" {
  count = local.create_azure_automation_runbook ? 1 : 0

  name                    = "VAULT_JWT_AUDIENCE"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal[0].name
  value                   = var.azure_automation_vault_jwt_audience
}

resource "azurerm_automation_variable_string" "vault_namespace" {
  count = local.create_azure_automation_runbook ? 1 : 0

  name                    = "VAULT_NAMESPACE"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal[0].name
  value                   = var.vault_namespace
}

resource "azurerm_automation_variable_string" "vault_pki_path" {
  count = local.create_azure_automation_runbook ? 1 : 0

  name                    = "VAULT_PKI_PATH"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal[0].name
  value                   = var.vault_pki_path
}

resource "azurerm_automation_variable_string" "vault_pki_role" {
  count = local.create_azure_automation_runbook ? 1 : 0

  name                    = "VAULT_PKI_ROLE"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal[0].name
  value                   = var.vault_pki_role
}

resource "azurerm_automation_variable_string" "vault_token" {
  count = local.create_azure_automation_runbook ? 1 : 0

  name                    = "VAULT_TOKEN"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal[0].name
  value                   = var.azure_automation_vault_token
  encrypted               = true
}

resource "azurerm_automation_schedule" "certificate_renewal" {
  count = local.create_azure_automation_runbook ? 1 : 0

  name                    = var.azure_automation_schedule_name
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal[0].name
  frequency               = "Hour"
  interval                = var.azure_automation_schedule_interval_hours
  timezone                = var.azure_automation_schedule_timezone
  start_time              = timeadd(timestamp(), "5m")
  description             = "Hourly certificate renewal runbook schedule"
}

resource "azurerm_automation_job_schedule" "certificate_renewal" {
  count = local.create_azure_automation_runbook ? 1 : 0

  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.certificate_renewal[0].name
  schedule_name           = azurerm_automation_schedule.certificate_renewal[0].name
  runbook_name            = azurerm_automation_runbook.certificate_renewal[0].name

  depends_on = [module.keyvault]
}

resource "vault_policy" "workload_pki_issue" {
  count = local.create_vault_jwt_auth ? 1 : 0

  name = "${local.name_prefix}-workload-pki-issue"

  policy = <<EOT
path "${var.vault_pki_path}/issue/${var.vault_pki_role}" {
  capabilities = ["create", "update"]
}
EOT
}

resource "vault_jwt_auth_backend" "workload" {
  count = local.create_vault_jwt_auth ? 1 : 0

  description        = var.vault_jwt_backend_description
  path               = var.vault_jwt_backend_path
  type               = "jwt"
  oidc_discovery_url = var.vault_jwt_discovery_url
  bound_issuer       = var.vault_jwt_bound_issuer
}

resource "vault_jwt_auth_backend_role" "workload" {
  count = local.create_vault_jwt_auth ? 1 : 0

  backend         = vault_jwt_auth_backend.workload[0].path
  role_name       = var.vault_jwt_role_name
  role_type       = "jwt"
  user_claim      = var.vault_jwt_user_claim
  bound_audiences = var.vault_jwt_bound_audiences
  bound_claims    = var.vault_jwt_bound_claims
  token_policies  = [vault_policy.workload_pki_issue[0].name]
  token_ttl       = var.vault_jwt_token_ttl
  token_max_ttl   = var.vault_jwt_token_max_ttl
}

resource "random_password" "bootstrap_pfx_password" {
  length           = 32
  special          = true
  override_special = "!@#%^*-_=+"
}

resource "vault_mount" "bootstrap_pfx_password_kvv2" {
  count = local.store_bootstrap_pfx_password && var.bootstrap_pfx_password_create_kv_mount ? 1 : 0

  path = var.bootstrap_pfx_password_kv_mount
  type = "kv-v2"
}

resource "vault_kv_secret_v2" "bootstrap_pfx_password" {
  count = local.store_bootstrap_pfx_password ? 1 : 0

  mount = var.bootstrap_pfx_password_kv_mount
  name  = var.bootstrap_pfx_password_kv_path

  data_json = jsonencode({
    bootstrap_pfx_password = random_password.bootstrap_pfx_password.result
  })

  depends_on = [vault_mount.bootstrap_pfx_password_kvv2]
}

resource "vault_pki_secret_backend_role" "bootstrap" {
  backend        = var.vault_pki_path
  name           = var.vault_pki_role
  allow_any_name = true
  max_ttl        = var.initial_certificate_ttl
}

resource "vault_pki_secret_backend_cert" "bootstrap" {
  backend            = var.vault_pki_path
  name               = var.vault_pki_role
  common_name        = var.initial_certificate_common_name
  ttl                = var.initial_certificate_ttl
  format             = "pem"
  private_key_format = "pkcs8"

  lifecycle {
    precondition {
      condition     = var.vault_pki_path != "" && var.vault_pki_role != ""
      error_message = "Set vault_pki_path and vault_pki_role for bootstrap certificate issuance."
    }
  }

  depends_on = [vault_pki_secret_backend_role.bootstrap]
}

module "keyvault_certificate_management" {
  source  = "app.terraform.io/benoitblais-hashicorp/terraform-azurerm-keyvault-cert-management/azurerm"
  version = "0.0.1"

  key_vault_id = module.keyvault.id

  certificates = [
    {
      name = var.key_vault_certificate_name
      certificate = {
        contents = base64encode(local.bootstrap_pem_bundle)
      }
      certificate_policy = {
        issuer_parameters = {
          name = "Unknown"
        }
        key_properties = {
          exportable = true
          key_size   = 2048
          key_type   = "RSA"
          reuse_key  = false
        }
        secret_properties = {
          content_type = "application/x-pem-file"
        }
      }
    }
  ]

  depends_on = [module.keyvault]
}

resource "azurerm_application_gateway" "this" {
  name                = "${local.name_prefix}-appgw"
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
    key_vault_secret_id = local.bootstrap_key_vault_secret_id
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

  depends_on = [
    module.keyvault_certificate_management,
    module.keyvault
  ]
}

import {
  to = azurerm_application_gateway.this
  id = format(
    "/subscriptions/%s/resourceGroups/%s/providers/Microsoft.Network/applicationGateways/%s",
    var.subscription_id,
    var.resource_group_name,
    "${local.name_prefix}-appgw"
  )
}

moved {
  from = azurerm_key_vault.this
  to   = module.keyvault.azurerm_key_vault.this
}

moved {
  from = azurerm_key_vault_access_policy.terraform_identity
  to   = module.keyvault.azurerm_key_vault_access_policy.custom_policy["0"]
}

moved {
  from = azurerm_key_vault_access_policy.app_gateway_identity
  to   = module.keyvault.azurerm_key_vault_access_policy.custom_policy["1"]
}

moved {
  from = azurerm_key_vault_access_policy.automation_identity[0]
  to   = module.keyvault.azurerm_key_vault_access_policy.custom_policy["2"]
}

moved {
  from = azurerm_key_vault_certificate.bootstrap
  to   = module.keyvault_certificate_management.azurerm_key_vault_certificate.this["appgw.demo.example.com"]
}
