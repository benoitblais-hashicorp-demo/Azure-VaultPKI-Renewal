variable "location" {
  type        = string
  description = "(Required) Azure region where the demo resources are deployed"
}

variable "subscription_id" {
  type        = string
  description = "(Required) Azure subscription ID used by the AzureRM provider"
}

variable "app_gateway_subnet_prefix" {
  type        = string
  description = "(Optional) CIDR prefix used by the dedicated Application Gateway subnet"
  default     = "10.20.1.0/24"
}

variable "key_vault_certificate_name" {
  type        = string
  description = "(Optional) Certificate name created in Key Vault and referenced by Application Gateway"
  default     = "demo-tls-cert"
}

variable "name_prefix" {
  type        = string
  description = "(Optional) Prefix used for Azure resource naming"
  default     = "vault-pki"
}

variable "resource_group_name" {
  type        = string
  description = "(Optional) Resource group name for all demo resources"
  default     = "rg-vault-pki-renewal"
}

variable "tags" {
  type        = map(string)
  description = "(Optional) Tags applied to Azure resources"
  default     = {}
}

variable "vnet_address_space" {
  type        = list(string)
  description = "(Optional) Address space assigned to the demo virtual network"
  default     = ["10.20.0.0/16"]
}
