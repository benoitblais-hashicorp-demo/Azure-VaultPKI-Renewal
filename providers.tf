provider "azurerm" {
  features {}
  subscription_id                 = var.subscription_id
  resource_provider_registrations = "none"
}

provider "vault" {
  address   = var.vault_addr != "" ? var.vault_addr : null
  namespace = var.vault_namespace != "" ? var.vault_namespace : null
  token     = var.vault_token != "" ? var.vault_token : null
}
