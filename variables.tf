variable "subscription_id" {
  type        = string
  description = "(Required) Azure subscription ID used by the AzureRM provider."

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "`subscription_id` must be a valid GUID (for example: 00000000-0000-0000-0000-000000000000)."
  }
}

variable "app_gateway_subnet_prefix" {
  type        = string
  description = "(Optional) CIDR prefix used by the dedicated Application Gateway subnet."
  default     = "10.20.1.0/24"

  validation {
    condition     = can(cidrnetmask(var.app_gateway_subnet_prefix))
    error_message = "`app_gateway_subnet_prefix` must be a valid CIDR range (for example: 10.20.1.0/24)."
  }
}

variable "azure_devops_jwt_backend_description" {
  type        = string
  description = "(Optional) Description for the Azure DevOps JWT/OIDC auth backend in Vault."
  default     = "JWT/OIDC auth backend for Azure DevOps pipelines"
}

variable "azure_devops_jwt_backend_path" {
  type        = string
  description = "(Optional) Path for the Azure DevOps JWT/OIDC auth backend in Vault."
  default     = "jwt_azure_devops"

  validation {
    condition     = trimspace(var.azure_devops_jwt_backend_path) != ""
    error_message = "`azure_devops_jwt_backend_path` cannot be empty."
  }
}

variable "azure_devops_jwt_bound_audiences" {
  type        = list(string)
  description = "(Optional) Accepted audience claims for the Azure DevOps OIDC tokens."
  default     = ["vault.workload.identity"]

  validation {
    condition     = length(var.azure_devops_jwt_bound_audiences) > 0 && alltrue([for audience in var.azure_devops_jwt_bound_audiences : trimspace(audience) != ""])
    error_message = "`azure_devops_jwt_bound_audiences` must contain at least one non-empty audience value."
  }
}

variable "azure_devops_jwt_bound_claims" {
  type        = map(string)
  description = "(Optional) Additional bound claims for the Azure DevOps JWT role."
  default     = {}
}

variable "azure_devops_jwt_bound_issuer" {
  type        = string
  description = "(Optional) Expected issuer claim for the Azure DevOps OIDC tokens."
  default     = "https://vstoken.dev.azure.com"

  validation {
    condition     = can(regex("^https?://", var.azure_devops_jwt_bound_issuer))
    error_message = "`azure_devops_jwt_bound_issuer` must start with http:// or https://."
  }
}

variable "azure_devops_jwt_discovery_url" {
  type        = string
  description = "(Optional) OIDC discovery URL used by Vault to validate Azure DevOps tokens."
  default     = "https://vstoken.dev.azure.com"

  validation {
    condition     = can(regex("^https?://", var.azure_devops_jwt_discovery_url))
    error_message = "`azure_devops_jwt_discovery_url` must start with http:// or https://."
  }
}

variable "azure_devops_jwt_role_name" {
  type        = string
  description = "(Optional) Vault JWT role name for the Azure DevOps pipeline login."
  default     = "jwt_azure_devops_role"

  validation {
    condition     = trimspace(var.azure_devops_jwt_role_name) != ""
    error_message = "`azure_devops_jwt_role_name` cannot be empty."
  }
}

variable "azure_devops_jwt_token_max_ttl" {
  type        = number
  description = "(Optional) Maximum lifetime in seconds for Vault tokens issued to Azure DevOps JWT logins."
  default     = 600

  validation {
    condition     = var.azure_devops_jwt_token_max_ttl > 0
    error_message = "`azure_devops_jwt_token_max_ttl` must be greater than 0."
  }
}

variable "azure_devops_jwt_token_ttl" {
  type        = number
  description = "(Optional) Default lifetime in seconds for Vault tokens issued to Azure DevOps JWT logins."
  default     = 300

  validation {
    condition     = var.azure_devops_jwt_token_ttl > 0
    error_message = "`azure_devops_jwt_token_ttl` must be greater than 0."
  }
}

variable "azure_devops_jwt_user_claim" {
  type        = string
  description = "(Optional) JWT claim used as user identity in the Vault Azure DevOps JWT role."
  default     = "sub"

  validation {
    condition     = trimspace(var.azure_devops_jwt_user_claim) != ""
    error_message = "`azure_devops_jwt_user_claim` cannot be empty."
  }
}

variable "bootstrap_pfx_password_kv_mount" {
  type        = string
  description = "(Optional) Vault KVv2 mount path where the generated bootstrap PFX password is stored."
  default     = "kvv2_azure_devops"

  validation {
    condition     = trimspace(var.bootstrap_pfx_password_kv_mount) != ""
    error_message = "`bootstrap_pfx_password_kv_mount` cannot be empty."
  }
}

variable "bootstrap_pfx_password_kv_path" {
  type        = string
  description = "(Optional) Vault KVv2 secret path where the generated bootstrap PFX password is stored."
  default     = "azure-vaultpki-renewal/bootstrap"

  validation {
    condition     = trimspace(var.bootstrap_pfx_password_kv_path) != ""
    error_message = "`bootstrap_pfx_password_kv_path` cannot be empty."
  }
}

variable "enable_azure_devops_jwt_auth" {
  type        = bool
  description = "(Optional) When true, creates the Vault JWT role and policy for Azure DevOps pipeline authentication."
  default     = true
}

variable "initial_certificate_common_name" {
  type        = string
  description = "(Optional) Common Name requested from Vault PKI for the initial bootstrap certificate."
  default     = "appgw.demo.example.com"

  validation {
    condition     = trimspace(var.initial_certificate_common_name) != "" && !can(regex("\\s", var.initial_certificate_common_name))
    error_message = "`initial_certificate_common_name` must be non-empty and must not contain whitespace."
  }
}

variable "initial_certificate_ttl" {
  type        = string
  description = "(Optional) TTL sent to Vault PKI for the initial bootstrap certificate."
  default     = "24h"

  validation {
    condition     = can(regex("^[0-9]+[smhdw]$", var.initial_certificate_ttl))
    error_message = "`initial_certificate_ttl` must follow a Vault duration format like 30m, 12h, or 7d."
  }
}

variable "key_vault_certificate_name" {
  type        = string
  description = "(Optional) Certificate name created in Key Vault and referenced by Application Gateway."
  default     = "gw-demo-tls-cert"

  validation {
    condition     = can(regex("^[0-9A-Za-z-]{1,127}$", var.key_vault_certificate_name))
    error_message = "`key_vault_certificate_name` must be 1-127 characters and contain only letters, numbers, and hyphens."
  }
}

variable "location" {
  type        = string
  description = "(Optional) Azure region where the demo resources are deployed."
  default     = "canadacentral"

  validation {
    condition     = trimspace(var.location) != ""
    error_message = "`location` cannot be empty."
  }
}

variable "name_prefix" {
  type        = string
  description = "(Optional) Prefix used for Azure resource naming."
  default     = "vault-pki"

  validation {
    condition     = trimspace(var.name_prefix) != ""
    error_message = "`name_prefix` cannot be empty."
  }
}

variable "resource_group_name" {
  type        = string
  description = "(Optional) Resource group name for all demo resources."
  default     = "rg-vault-pki-renewal"

  validation {
    condition     = trimspace(var.resource_group_name) != ""
    error_message = "`resource_group_name` cannot be empty."
  }
}

variable "tags" {
  type        = map(string)
  description = "(Optional) Tags applied to Azure resources."
  default     = {}
}

variable "vault_addr" {
  type        = string
  description = "(Required) Vault address used for initial certificate issuance."
  default     = ""

  validation {
    condition     = var.vault_addr == "" || can(regex("^https?://", var.vault_addr))
    error_message = "`vault_addr` must be empty or start with http:// or https://."
  }
}

variable "vault_namespace" {
  type        = string
  description = "(Optional) Vault namespace used for initial certificate issuance."
  default     = ""

  validation {
    condition     = var.vault_namespace == "" || (trimspace(var.vault_namespace) == var.vault_namespace && !can(regex("\\s", var.vault_namespace)))
    error_message = "`vault_namespace` must not include whitespace characters."
  }
}

variable "vault_pki_path" {
  type        = string
  description = "(Optional) Vault PKI mount path used for certificate issuance."
  default     = "pki-int"

  validation {
    condition     = trimspace(var.vault_pki_path) != ""
    error_message = "`vault_pki_path` cannot be empty."
  }
}

variable "vault_pki_role" {
  type        = string
  description = "(Optional) Vault PKI role used for certificate issuance."
  default     = "gw-cert-issuer"

  validation {
    condition     = trimspace(var.vault_pki_role) != ""
    error_message = "`vault_pki_role` cannot be empty."
  }
}

variable "vault_token" {
  type        = string
  description = "(Optional) Vault token used for initial certificate issuance. Leave empty to use JWT/OIDC auth."
  sensitive   = true
  default     = ""
}

variable "vnet_address_space" {
  type        = list(string)
  description = "(Optional) Address space assigned to the demo virtual network."
  default     = ["10.20.0.0/16"]

  validation {
    condition     = length(var.vnet_address_space) > 0 && alltrue([for cidr in var.vnet_address_space : can(cidrnetmask(cidr))])
    error_message = "`vnet_address_space` must contain at least one valid CIDR block."
  }
}
