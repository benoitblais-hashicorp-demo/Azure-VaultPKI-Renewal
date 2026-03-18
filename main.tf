locals {
  bootstrap_key_vault_secret_id = "https://${azurerm_key_vault.this.name}.vault.azure.net/secrets/${var.key_vault_certificate_name}"
  create_azure_devops_jwt_auth  = var.enable_azure_devops_jwt_auth && var.vault_pki_path != "" && var.vault_pki_role != ""
  name_prefix                   = lower(replace(var.name_prefix, "_", "-"))
}

resource "local_file" "azure_pipelines_yaml" {
  filename = "${path.module}/azure-pipelines.yml"
  content = templatefile("${path.module}/templates/azure-pipelines.yml.tftpl", {
    vault_addr      = var.vault_addr
    vault_namespace = var.vault_namespace
  })
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

resource "azurerm_key_vault" "this" {
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
}

resource "azurerm_key_vault_access_policy" "terraform_identity" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  certificate_permissions = [
    "Create",
    "Delete",
    "Get",
    "Import",
    "List",
    "Update"
  ]

  secret_permissions = [
    "Get",
    "List",
    "Set"
  ]
}

resource "azurerm_key_vault_access_policy" "app_gateway_identity" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = azurerm_user_assigned_identity.app_gateway.tenant_id
  object_id    = azurerm_user_assigned_identity.app_gateway.principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

resource "vault_policy" "azure_devops_pki_issue" {
  count = local.create_azure_devops_jwt_auth ? 1 : 0

  name = "${local.name_prefix}-azure-devops-pki-issue"

  policy = <<EOT
path "${var.vault_pki_path}/issue/${var.vault_pki_role}" {
  capabilities = ["create", "update"]
}
EOT
}

resource "vault_jwt_auth_backend" "azure_devops" {
  count = local.create_azure_devops_jwt_auth ? 1 : 0

  description        = var.azure_devops_jwt_backend_description
  path               = var.azure_devops_jwt_backend_path
  type               = "jwt"
  oidc_discovery_url = var.azure_devops_jwt_discovery_url
  bound_issuer       = var.azure_devops_jwt_bound_issuer
}

resource "vault_jwt_auth_backend_role" "azure_devops" {
  count = local.create_azure_devops_jwt_auth ? 1 : 0

  backend         = vault_jwt_auth_backend.azure_devops[0].path
  role_name       = var.azure_devops_jwt_role_name
  role_type       = "jwt"
  user_claim      = var.azure_devops_jwt_user_claim
  bound_audiences = var.azure_devops_jwt_bound_audiences
  bound_claims    = var.azure_devops_jwt_bound_claims
  token_policies  = [vault_policy.azure_devops_pki_issue[0].name]
  token_ttl       = var.azure_devops_jwt_token_ttl
  token_max_ttl   = var.azure_devops_jwt_token_max_ttl
}

resource "random_password" "bootstrap_pfx_password" {
  length           = 32
  special          = true
  override_special = "!@#%^*-_=+"
}

resource "vault_mount" "bootstrap_pfx_password_kvv2" {
  path = var.bootstrap_pfx_password_kv_mount
  type = "kv-v2"
}

resource "vault_kv_secret_v2" "bootstrap_pfx_password" {
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
  backend     = var.vault_pki_path
  name        = var.vault_pki_role
  common_name = var.initial_certificate_common_name
  ttl         = var.initial_certificate_ttl
  format      = "pem"

  lifecycle {
    precondition {
      condition     = var.vault_pki_path != "" && var.vault_pki_role != ""
      error_message = "Set vault_pki_path and vault_pki_role for bootstrap certificate issuance."
    }
  }

  depends_on = [vault_pki_secret_backend_role.bootstrap]
}

resource "azurerm_key_vault_certificate" "bootstrap" {
  name         = var.key_vault_certificate_name
  key_vault_id = azurerm_key_vault.this.id

  certificate {
    contents = base64encode(join("\n", compact(concat([
      vault_pki_secret_backend_cert.bootstrap.private_key,
      vault_pki_secret_backend_cert.bootstrap.certificate
    ], try(vault_pki_secret_backend_cert.bootstrap.ca_chain, [])))))
  }

  certificate_policy {
    issuer_parameters {
      name = "Unknown"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = false
    }

    secret_properties {
      content_type = "application/x-pem-file"
    }
  }

  depends_on = [azurerm_key_vault_access_policy.terraform_identity]
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
    azurerm_key_vault_certificate.bootstrap,
    azurerm_key_vault_access_policy.app_gateway_identity
  ]
}
