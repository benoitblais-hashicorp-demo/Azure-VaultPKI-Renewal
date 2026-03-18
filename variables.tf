variable "subscription_id" {
  type        = string
  description = "(Required) Azure subscription ID used by the AzureRM provider."

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "`subscription_id` must be a valid GUID (for example: 00000000-0000-0000-0000-000000000000)."
  }
}

variable "vault_addr" {
  type        = string
  description = "(Required) Vault address injected into the generated Azure DevOps pipeline file."

  validation {
    condition     = can(regex("^https?://", var.vault_addr))
    error_message = "`vault_addr` must start with http:// or https://."
  }
}

variable "app_gateway_autoscale_max_capacity" {
  type        = number
  description = "(Optional) Maximum autoscale capacity for Application Gateway."
  default     = 2

  validation {
    condition     = var.app_gateway_autoscale_max_capacity >= 1
    error_message = "`app_gateway_autoscale_max_capacity` must be greater than or equal to 1."
  }
}

variable "app_gateway_autoscale_min_capacity" {
  type        = number
  description = "(Optional) Minimum autoscale capacity for Application Gateway."
  default     = 1

  validation {
    condition     = var.app_gateway_autoscale_min_capacity >= 0
    error_message = "`app_gateway_autoscale_min_capacity` must be greater than or equal to 0."
  }
}

variable "app_gateway_backend_address_pool_fqdns" {
  type        = list(string)
  description = "(Optional) Backend pool FQDNs for Application Gateway."
  default     = ["example.com"]

  validation {
    condition     = length(var.app_gateway_backend_address_pool_fqdns) > 0 && alltrue([for fqdn in var.app_gateway_backend_address_pool_fqdns : trimspace(fqdn) != ""])
    error_message = "`app_gateway_backend_address_pool_fqdns` must contain at least one non-empty FQDN."
  }
}

variable "app_gateway_backend_address_pool_name" {
  type        = string
  description = "(Optional) Backend address pool name in Application Gateway."
  default     = "demo-backend-pool"

  validation {
    condition     = trimspace(var.app_gateway_backend_address_pool_name) != ""
    error_message = "`app_gateway_backend_address_pool_name` cannot be empty."
  }
}

variable "app_gateway_backend_http_settings_cookie_based_affinity" {
  type        = string
  description = "(Optional) Cookie-based affinity mode for backend HTTP settings."
  default     = "Disabled"

  validation {
    condition     = contains(["Enabled", "Disabled"], var.app_gateway_backend_http_settings_cookie_based_affinity)
    error_message = "`app_gateway_backend_http_settings_cookie_based_affinity` must be `Enabled` or `Disabled`."
  }
}

variable "app_gateway_backend_http_settings_name" {
  type        = string
  description = "(Optional) Backend HTTP settings name in Application Gateway."
  default     = "demo-backend-http-settings"

  validation {
    condition     = trimspace(var.app_gateway_backend_http_settings_name) != ""
    error_message = "`app_gateway_backend_http_settings_name` cannot be empty."
  }
}

variable "app_gateway_backend_http_settings_path" {
  type        = string
  description = "(Optional) Backend path for Application Gateway HTTP settings."
  default     = "/"

  validation {
    condition     = trimspace(var.app_gateway_backend_http_settings_path) != ""
    error_message = "`app_gateway_backend_http_settings_path` cannot be empty."
  }
}

variable "app_gateway_backend_http_settings_port" {
  type        = number
  description = "(Optional) Backend port for Application Gateway HTTP settings."
  default     = 80

  validation {
    condition     = var.app_gateway_backend_http_settings_port >= 1 && var.app_gateway_backend_http_settings_port <= 65535
    error_message = "`app_gateway_backend_http_settings_port` must be between 1 and 65535."
  }
}

variable "app_gateway_backend_http_settings_protocol" {
  type        = string
  description = "(Optional) Backend protocol for Application Gateway HTTP settings."
  default     = "Http"

  validation {
    condition     = contains(["Http", "Https"], var.app_gateway_backend_http_settings_protocol)
    error_message = "`app_gateway_backend_http_settings_protocol` must be `Http` or `Https`."
  }
}

variable "app_gateway_backend_http_settings_request_timeout" {
  type        = number
  description = "(Optional) Backend request timeout in seconds for Application Gateway HTTP settings."
  default     = 30

  validation {
    condition     = var.app_gateway_backend_http_settings_request_timeout >= 1 && var.app_gateway_backend_http_settings_request_timeout <= 86400
    error_message = "`app_gateway_backend_http_settings_request_timeout` must be between 1 and 86400 seconds."
  }
}

variable "app_gateway_frontend_ip_configuration_name" {
  type        = string
  description = "(Optional) Frontend IP configuration name in Application Gateway."
  default     = "public-frontend"

  validation {
    condition     = trimspace(var.app_gateway_frontend_ip_configuration_name) != ""
    error_message = "`app_gateway_frontend_ip_configuration_name` cannot be empty."
  }
}

variable "app_gateway_frontend_port" {
  type        = number
  description = "(Optional) Frontend listener port for Application Gateway."
  default     = 443

  validation {
    condition     = var.app_gateway_frontend_port >= 1 && var.app_gateway_frontend_port <= 65535
    error_message = "`app_gateway_frontend_port` must be between 1 and 65535."
  }
}

variable "app_gateway_frontend_port_name" {
  type        = string
  description = "(Optional) Frontend port name in Application Gateway."
  default     = "https-443"

  validation {
    condition     = trimspace(var.app_gateway_frontend_port_name) != ""
    error_message = "`app_gateway_frontend_port_name` cannot be empty."
  }
}

variable "app_gateway_gateway_ip_configuration_name" {
  type        = string
  description = "(Optional) Gateway IP configuration name in Application Gateway."
  default     = "gateway-ip-config"

  validation {
    condition     = trimspace(var.app_gateway_gateway_ip_configuration_name) != ""
    error_message = "`app_gateway_gateway_ip_configuration_name` cannot be empty."
  }
}

variable "app_gateway_http_listener_name" {
  type        = string
  description = "(Optional) HTTP listener name in Application Gateway."
  default     = "https-listener"

  validation {
    condition     = trimspace(var.app_gateway_http_listener_name) != ""
    error_message = "`app_gateway_http_listener_name` cannot be empty."
  }
}

variable "app_gateway_http_listener_protocol" {
  type        = string
  description = "(Optional) HTTP listener protocol in Application Gateway."
  default     = "Https"

  validation {
    condition     = contains(["Http", "Https"], var.app_gateway_http_listener_protocol)
    error_message = "`app_gateway_http_listener_protocol` must be `Http` or `Https`."
  }
}

variable "app_gateway_request_routing_rule_name" {
  type        = string
  description = "(Optional) Request routing rule name in Application Gateway."
  default     = "demo-routing-rule"

  validation {
    condition     = trimspace(var.app_gateway_request_routing_rule_name) != ""
    error_message = "`app_gateway_request_routing_rule_name` cannot be empty."
  }
}

variable "app_gateway_request_routing_rule_priority" {
  type        = number
  description = "(Optional) Request routing rule priority in Application Gateway."
  default     = 100

  validation {
    condition     = var.app_gateway_request_routing_rule_priority >= 1 && var.app_gateway_request_routing_rule_priority <= 20000
    error_message = "`app_gateway_request_routing_rule_priority` must be between 1 and 20000."
  }
}

variable "app_gateway_request_routing_rule_type" {
  type        = string
  description = "(Optional) Request routing rule type in Application Gateway."
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "PathBasedRouting"], var.app_gateway_request_routing_rule_type)
    error_message = "`app_gateway_request_routing_rule_type` must be `Basic` or `PathBasedRouting`."
  }
}

variable "app_gateway_sku_name" {
  type        = string
  description = "(Optional) SKU name for Application Gateway."
  default     = "Standard_v2"

  validation {
    condition     = trimspace(var.app_gateway_sku_name) != ""
    error_message = "`app_gateway_sku_name` cannot be empty."
  }
}

variable "app_gateway_sku_tier" {
  type        = string
  description = "(Optional) SKU tier for Application Gateway."
  default     = "Standard_v2"

  validation {
    condition     = trimspace(var.app_gateway_sku_tier) != ""
    error_message = "`app_gateway_sku_tier` cannot be empty."
  }
}

variable "app_gateway_ssl_certificate_name" {
  type        = string
  description = "(Optional) SSL certificate name in Application Gateway."
  default     = "tls-from-key-vault"

  validation {
    condition     = trimspace(var.app_gateway_ssl_certificate_name) != ""
    error_message = "`app_gateway_ssl_certificate_name` cannot be empty."
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

variable "vault_namespace" {
  type        = string
  description = "(Optional) Vault namespace injected into the generated Azure DevOps pipeline file."
  default     = ""

  validation {
    condition     = var.vault_namespace == "" || (trimspace(var.vault_namespace) == var.vault_namespace && !can(regex("\\s", var.vault_namespace)))
    error_message = "`vault_namespace` must not include whitespace characters."
  }
}

variable "tags" {
  type        = map(string)
  description = "(Optional) Tags applied to Azure resources."
  default     = {}
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

variable "vnet_address_space" {
  type        = list(string)
  description = "(Optional) Address space assigned to the demo virtual network."
  default     = ["10.20.0.0/16"]

  validation {
    condition     = length(var.vnet_address_space) > 0 && alltrue([for cidr in var.vnet_address_space : can(cidrnetmask(cidr))])
    error_message = "`vnet_address_space` must contain at least one valid CIDR block."
  }
}
