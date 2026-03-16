locals {
  name_prefix = lower(replace(var.name_prefix, "_", "-"))
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

resource "azurerm_key_vault_certificate" "bootstrap" {
  name         = var.key_vault_certificate_name
  key_vault_id = azurerm_key_vault.this.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      subject            = "CN=appgw.demo.example.com"
      validity_in_months = 12

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment"
      ]

      extended_key_usage = [
        "1.3.6.1.5.5.7.3.1"
      ]

      subject_alternative_names {
        dns_names = ["appgw.demo.example.com"]
      }
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
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
    name = "Standard_v2"
    tier = "Standard_v2"
  }

  autoscale_configuration {
    min_capacity = 1
    max_capacity = 2
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = azurerm_subnet.app_gateway.id
  }

  frontend_port {
    name = "https-443"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "public-frontend"
    public_ip_address_id = azurerm_public_ip.app_gateway.id
  }

  backend_address_pool {
    name  = "demo-backend-pool"
    fqdns = ["example.com"]
  }

  backend_http_settings {
    name                  = "demo-backend-http-settings"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  ssl_certificate {
    name                = "tls-from-key-vault"
    key_vault_secret_id = azurerm_key_vault_certificate.bootstrap.versionless_secret_id
  }

  http_listener {
    name                           = "https-listener"
    frontend_ip_configuration_name = "public-frontend"
    frontend_port_name             = "https-443"
    protocol                       = "Https"
    ssl_certificate_name           = "tls-from-key-vault"
  }

  request_routing_rule {
    name                       = "demo-routing-rule"
    priority                   = 100
    rule_type                  = "Basic"
    http_listener_name         = "https-listener"
    backend_address_pool_name  = "demo-backend-pool"
    backend_http_settings_name = "demo-backend-http-settings"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app_gateway.id]
  }

  depends_on = [
    azurerm_key_vault_access_policy.app_gateway_identity,
    azurerm_key_vault_certificate.bootstrap
  ]
}
