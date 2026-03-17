variable "app_gateway_subnet_prefix" {
  type        = string
  description = "(Optional) CIDR prefix used by the dedicated Application Gateway subnet"
  default     = "10.20.1.0/24"
}

variable "azure_devops_jwt_backend_description" {
  type        = string
  description = "(Optional) Description for the Azure DevOps JWT/OIDC auth backend in Vault"
  default     = "JWT/OIDC auth backend for Azure DevOps pipelines"
}

variable "azure_devops_jwt_backend_path" {
  type        = string
  description = "(Optional) Path of the existing Azure DevOps JWT/OIDC auth backend in Vault"
  default     = "jwt_azure_devops"
}

variable "azure_devops_jwt_bound_audiences" {
  type        = list(string)
  description = "(Optional) Accepted audience claims for Azure DevOps OIDC tokens"
  default     = ["vault.workload.identity"]
}

variable "azure_devops_jwt_bound_claims" {
  type        = map(string)
  description = "(Optional) Additional bound claims for the Azure DevOps JWT role"
  default     = {}
}

variable "azure_devops_jwt_bound_issuer" {
  type        = string
  description = "(Optional) Expected issuer claim for Azure DevOps OIDC tokens"
  default     = "https://vstoken.dev.azure.com"
}

variable "azure_devops_jwt_discovery_url" {
  type        = string
  description = "(Optional) OIDC discovery URL used by Vault to validate Azure DevOps tokens"
  default     = "https://vstoken.dev.azure.com"
}

variable "azure_devops_jwt_role_name" {
  type        = string
  description = "(Optional) Vault JWT role name used by Azure DevOps pipeline login"
  default     = "jwt_azure_devops_role"
}

variable "azure_devops_jwt_token_max_ttl" {
  type        = number
  description = "(Optional) Maximum lifetime in seconds for Vault tokens issued to Azure DevOps JWT logins"
  default     = 600
}

variable "azure_devops_jwt_token_ttl" {
  type        = number
  description = "(Optional) Default lifetime in seconds for Vault tokens issued to Azure DevOps JWT logins"
  default     = 300
}

variable "azure_devops_jwt_user_claim" {
  type        = string
  description = "(Optional) JWT claim used as user identity in the Vault Azure DevOps JWT role"
  default     = "sub"
}

variable "bootstrap_certificate_from_vault" {
  type        = bool
  description = "(Optional) When true, bootstraps the initial Key Vault certificate from Vault PKI instead of generating a self-signed certificate"
  default     = true
}

variable "bootstrap_pfx_password" {
  type        = string
  description = "(Required when bootstrap_certificate_from_vault=true) Password used for the PKCS#12 bundle imported to Key Vault"
  sensitive   = true
  default     = ""
}

variable "enable_bootstrap_pfx_password_kv_mount" {
  type        = bool
  description = "(Optional) When true, creates the KVv2 mount used to store generated bootstrap PFX passwords"
  default     = true
}

variable "bootstrap_pfx_password_kv_mount" {
  type        = string
  description = "(Optional) Vault KVv2 mount path where generated bootstrap PFX password is stored"
  default     = "kvv2"
}

variable "bootstrap_pfx_password_kv_path" {
  type        = string
  description = "(Optional) Vault KVv2 secret path where generated bootstrap PFX password is stored"
  default     = "azure-vaultpki-renewal/bootstrap"
}

variable "enable_azure_devops_jwt_auth" {
  type        = bool
  description = "(Optional) When true, creates the Vault JWT role and policy for Azure DevOps pipeline authentication"
  default     = true
}

variable "generate_bootstrap_pfx_password" {
  type        = bool
  description = "(Optional) When true and bootstrap_pfx_password is empty, generates a random PFX password and stores it in Vault KVv2"
  default     = false
}

variable "initial_certificate_common_name" {
  type        = string
  description = "(Optional) Common Name requested from Vault PKI for the initial bootstrap certificate"
  default     = "appgw.demo.example.com"
}

variable "initial_certificate_ttl" {
  type        = string
  description = "(Optional) TTL sent to Vault PKI for the initial bootstrap certificate"
  default     = "24h"
}

variable "key_vault_certificate_name" {
  type        = string
  description = "(Optional) Certificate name created in Key Vault and referenced by Application Gateway"
  default     = "demo-tls-cert"
}

variable "location" {
  type        = string
  description = "(Optional) Azure region where the demo resources are deployed"
  default     = "canadacentral"
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

variable "subscription_id" {
  type        = string
  description = "(Required) Azure subscription ID used by the AzureRM provider"
}

variable "tags" {
  type        = map(string)
  description = "(Optional) Tags applied to Azure resources"
  default     = {}
}

variable "vault_addr" {
  type        = string
  description = "(Required when bootstrap_certificate_from_vault=true) Vault address used for initial certificate issuance"
  default     = ""
}

variable "vault_namespace" {
  type        = string
  description = "(Optional) Vault namespace used for initial certificate issuance"
  default     = ""
}

variable "vault_pki_path" {
  type        = string
  description = "(Optional) Vault PKI mount path used for certificate issuance"
  default     = "pki-int"
}

variable "vault_pki_role" {
  type        = string
  description = "(Optional) Vault PKI role used for certificate issuance"
  default     = "gw-cert-issuer"
}

variable "vault_token" {
  type        = string
  description = "(Required when bootstrap_certificate_from_vault=true) Vault token used for initial certificate issuance"
  sensitive   = true
  default     = ""
}

variable "vnet_address_space" {
  type        = list(string)
  description = "(Optional) Address space assigned to the demo virtual network"
  default     = ["10.20.0.0/16"]
}
