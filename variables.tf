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
  description = "(Required) Vault address used by certificate renewal automation."

  validation {
    condition     = can(regex("^https?://", var.vault_addr))
    error_message = "`vault_addr` must start with \"http://\" or \"https://\"."
  }
}

variable "vault_namespace" {
  type        = string
  description = "(Required) Vault namespace used by certificate renewal automation."

  validation {
    condition     = trimspace(var.vault_namespace) != "" && !can(regex("\\s", var.vault_namespace))
    error_message = "`vault_namespace` must not be empty and must not include whitespace characters."
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
    error_message = "`app_gateway_backend_address_pool_name` must not be empty."
  }
}

variable "app_gateway_backend_http_settings_cookie_based_affinity" {
  type        = string
  description = "(Optional) Cookie-based affinity mode for backend HTTP settings."
  default     = "Disabled"

  validation {
    condition     = contains(["Enabled", "Disabled"], var.app_gateway_backend_http_settings_cookie_based_affinity)
    error_message = "`app_gateway_backend_http_settings_cookie_based_affinity` must be \"Enabled\" or \"Disabled\"."
  }
}

variable "app_gateway_backend_http_settings_name" {
  type        = string
  description = "(Optional) Backend HTTP settings name in Application Gateway."
  default     = "demo-backend-http-settings"

  validation {
    condition     = trimspace(var.app_gateway_backend_http_settings_name) != ""
    error_message = "`app_gateway_backend_http_settings_name` must not be empty."
  }
}

variable "app_gateway_backend_http_settings_path" {
  type        = string
  description = "(Optional) Backend path for Application Gateway HTTP settings."
  default     = "/"

  validation {
    condition     = trimspace(var.app_gateway_backend_http_settings_path) != ""
    error_message = "`app_gateway_backend_http_settings_path` must not be empty."
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
    error_message = "`app_gateway_backend_http_settings_protocol` must be \"Http\" or \"Https\"."
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
    error_message = "`app_gateway_frontend_ip_configuration_name` must not be empty."
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
    error_message = "`app_gateway_frontend_port_name` must not be empty."
  }
}

variable "app_gateway_gateway_ip_configuration_name" {
  type        = string
  description = "(Optional) Gateway IP configuration name in Application Gateway."
  default     = "gateway-ip-config"

  validation {
    condition     = trimspace(var.app_gateway_gateway_ip_configuration_name) != ""
    error_message = "`app_gateway_gateway_ip_configuration_name` must not be empty."
  }
}

variable "app_gateway_http_listener_name" {
  type        = string
  description = "(Optional) HTTP listener name in Application Gateway."
  default     = "https-listener"

  validation {
    condition     = trimspace(var.app_gateway_http_listener_name) != ""
    error_message = "`app_gateway_http_listener_name` must not be empty."
  }
}

variable "app_gateway_http_listener_protocol" {
  type        = string
  description = "(Optional) HTTP listener protocol in Application Gateway."
  default     = "Https"

  validation {
    condition     = contains(["Http", "Https"], var.app_gateway_http_listener_protocol)
    error_message = "`app_gateway_http_listener_protocol` must be \"Http\" or \"Https\"."
  }
}

variable "app_gateway_request_routing_rule_name" {
  type        = string
  description = "(Optional) Request routing rule name in Application Gateway."
  default     = "demo-routing-rule"

  validation {
    condition     = trimspace(var.app_gateway_request_routing_rule_name) != ""
    error_message = "`app_gateway_request_routing_rule_name` must not be empty."
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
    error_message = "`app_gateway_request_routing_rule_type` must be \"Basic\" or \"PathBasedRouting\"."
  }
}

variable "app_gateway_sku_name" {
  type        = string
  description = "(Optional) SKU name for Application Gateway."
  default     = "Standard_v2"

  validation {
    condition     = trimspace(var.app_gateway_sku_name) != ""
    error_message = "`app_gateway_sku_name` must not be empty."
  }
}

variable "app_gateway_sku_tier" {
  type        = string
  description = "(Optional) SKU tier for Application Gateway."
  default     = "Standard_v2"

  validation {
    condition     = trimspace(var.app_gateway_sku_tier) != ""
    error_message = "`app_gateway_sku_tier` must not be empty."
  }
}

variable "app_gateway_ssl_certificate_name" {
  type        = string
  description = "(Optional) SSL certificate name in Application Gateway."
  default     = "tls-from-key-vault"

  validation {
    condition     = trimspace(var.app_gateway_ssl_certificate_name) != ""
    error_message = "`app_gateway_ssl_certificate_name` must not be empty."
  }
}

variable "app_gateway_subnet_name" {
  type        = string
  description = "(Optional) Subnet name for the Application Gateway."
  default     = "app-gateway"

  validation {
    condition     = trimspace(var.app_gateway_subnet_name) != ""
    error_message = "`app_gateway_subnet_name` must not be empty."
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

variable "azure_automation_account_name" {
  type        = string
  description = "(Optional) Azure Automation Account name used for runbook-based certificate renewal."
  default     = "aa-vault-pki-renewal"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9-]{4,49}$", var.azure_automation_account_name))
    error_message = "`azure_automation_account_name` must be 5-50 characters, start with a letter, and contain only letters, numbers, and hyphens."
  }
}

variable "azure_automation_runtime_environment_name" {
  type        = string
  description = "(Optional) Azure Automation runtime environment name for Python runbooks."
  default     = "python"

  validation {
    condition     = trimspace(var.azure_automation_runtime_environment_name) != ""
    error_message = "`azure_automation_runtime_environment_name` must not be empty."
  }
}

variable "azure_automation_runtime_environment_version" {
  type        = string
  description = "(Optional) Azure Automation runtime environment version for Python runbooks."
  default     = "3.8"

  validation {
    condition     = trimspace(var.azure_automation_runtime_environment_version) != ""
    error_message = "`azure_automation_runtime_environment_version` must not be empty."
  }
}

variable "azure_automation_runbook_log_verbose" {
  type        = bool
  description = "(Optional) When true, enables verbose logging on the Azure Automation runbook."
  default     = true
}

variable "azure_automation_runbook_name" {
  type        = string
  description = "(Optional) Azure Automation runbook name used for certificate renewal."
  default     = "renew-certificate"

  validation {
    condition     = trimspace(var.azure_automation_runbook_name) != ""
    error_message = "`azure_automation_runbook_name` must not be empty."
  }
}

variable "azure_automation_runbook_run_once_delay_minutes" {
  type        = number
  description = "(Optional) Delay in minutes before the one-time runbook schedule starts."
  default     = 10

  validation {
    condition     = var.azure_automation_runbook_run_once_delay_minutes >= 6 && var.azure_automation_runbook_run_once_delay_minutes <= 60
    error_message = "`azure_automation_runbook_run_once_delay_minutes` must be between 6 and 60."
  }
}

variable "azure_automation_runbook_run_once_schedule_name" {
  type        = string
  description = "(Optional) One-time runbook schedule name."
  default     = "renew-certificate-run-once"

  validation {
    condition     = trimspace(var.azure_automation_runbook_run_once_schedule_name) != ""
    error_message = "`azure_automation_runbook_run_once_schedule_name` must not be empty."
  }
}

variable "azure_automation_runbook_trigger_once" {
  type        = bool
  description = "(Optional) Whether to trigger the runbook once shortly after provisioning."
  default     = true
}

variable "azure_automation_schedule_interval_hours" {
  type        = number
  description = "(Optional) Hour interval for Azure Automation schedule recurrence."
  default     = 1

  validation {
    condition     = var.azure_automation_schedule_interval_hours >= 1 && var.azure_automation_schedule_interval_hours <= 24
    error_message = "`azure_automation_schedule_interval_hours` must be between 1 and 24."
  }
}

variable "azure_automation_schedule_name" {
  type        = string
  description = "(Optional) Azure Automation schedule name used for runbook recurrence."
  default     = "hourly-certificate-renewal"

  validation {
    condition     = trimspace(var.azure_automation_schedule_name) != ""
    error_message = "`azure_automation_schedule_name` must not be empty."
  }
}

variable "azure_automation_schedule_timezone" {
  type        = string
  description = "(Optional) Azure Automation schedule timezone."
  default     = "Etc/UTC"

  validation {
    condition     = trimspace(var.azure_automation_schedule_timezone) != ""
    error_message = "`azure_automation_schedule_timezone` must not be empty."
  }
}

variable "azure_automation_vault_auth_path" {
  type        = string
  description = "(Optional) Vault auth path used by the Azure Automation runbook."
  default     = ""

  validation {
    condition     = trimspace(var.azure_automation_vault_auth_path) == "" || !can(regex("\\s", var.azure_automation_vault_auth_path))
    error_message = "`azure_automation_vault_auth_path` must not include whitespace characters."
  }
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

variable "key_vault_soft_delete_retention_days" {
  type        = number
  description = "(Optional) Soft delete retention (days) for Key Vault. Minimum is 7 in Azure."
  default     = 7

  validation {
    condition     = var.key_vault_soft_delete_retention_days >= 7 && var.key_vault_soft_delete_retention_days <= 90
    error_message = "`key_vault_soft_delete_retention_days` must be between 7 and 90."
  }
}

variable "location" {
  type        = string
  description = "(Optional) Azure region where the demo resources are deployed."
  default     = "canadacentral"

  validation {
    condition     = trimspace(var.location) != ""
    error_message = "`location` must not be empty."
  }
}

variable "resource_suffix" {
  type        = string
  description = "(Optional) Resource name suffix used to build shared resource names."
  default     = "vault-pki-renewal"

  validation {
    condition     = trimspace(var.resource_suffix) != ""
    error_message = "`resource_suffix` must not be empty."
  }
}

variable "storage_account_name" {
  type        = string
  description = "(Optional) Storage account name override. Leave empty to derive from resource group suffix."
  default     = ""

  validation {
    condition     = trimspace(var.storage_account_name) == "" || can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "`storage_account_name` must be 3-24 lowercase letters/numbers when set."
  }
}

variable "storage_allow_nested_items_to_be_public" {
  type        = bool
  description = "(Optional) Allow nested items within the storage account to be public."
  default     = true
}

variable "storage_blob_access_tier" {
  type        = string
  description = "(Optional) Access tier for the package blob."
  default     = "Hot"

  validation {
    condition     = contains(["Hot", "Cool", "Archive"], var.storage_blob_access_tier)
    error_message = "`storage_blob_access_tier` must be \"Hot\", \"Cool\", or \"Archive\"."
  }
}

variable "storage_blob_change_feed_enabled" {
  type        = bool
  description = "(Optional) Enable blob change feed on the storage account."
  default     = false
}

variable "storage_blob_content_type" {
  type        = string
  description = "(Optional) Content type for the package blob."
  default     = "application/octet-stream"

  validation {
    condition     = trimspace(var.storage_blob_content_type) != ""
    error_message = "`storage_blob_content_type` must not be empty."
  }
}

variable "storage_blob_last_access_time_enabled" {
  type        = bool
  description = "(Optional) Enable blob last access time tracking."
  default     = false
}

variable "storage_blob_name" {
  type        = string
  description = "(Optional) Package blob name stored in the container."
  default     = "cryptography-41.0.7-cp38-cp38-win_amd64.whl"

  validation {
    condition     = trimspace(var.storage_blob_name) != ""
    error_message = "`storage_blob_name` must not be empty."
  }
}

variable "storage_blob_parallelism" {
  type        = number
  description = "(Optional) Upload parallelism for the package blob."
  default     = 8

  validation {
    condition     = var.storage_blob_parallelism >= 1
    error_message = "`storage_blob_parallelism` must be at least 1."
  }
}

variable "storage_blob_source" {
  type        = string
  description = "(Optional) Local path to the package blob source file."
  default     = "./packages/cryptography-41.0.7-cp38-cp38-win_amd64.whl"

  validation {
    condition     = trimspace(var.storage_blob_source) != ""
    error_message = "`storage_blob_source` must not be empty."
  }
}

variable "storage_blob_type" {
  type        = string
  description = "(Optional) Storage blob type for the package."
  default     = "Block"

  validation {
    condition     = contains(["Block", "Append", "Page"], var.storage_blob_type)
    error_message = "`storage_blob_type` must be \"Block\", \"Append\", or \"Page\"."
  }
}

variable "storage_blob_versioning_enabled" {
  type        = bool
  description = "(Optional) Enable blob versioning on the storage account."
  default     = false
}

variable "storage_container_access_type" {
  type        = string
  description = "(Optional) Access level for the storage container."
  default     = "private"

  validation {
    condition     = contains(["private", "blob", "container"], var.storage_container_access_type)
    error_message = "`storage_container_access_type` must be \"private\", \"blob\", or \"container\"."
  }
}

variable "storage_container_name" {
  type        = string
  description = "(Optional) Storage container name for the automation package."
  default     = "python-packages"

  validation {
    condition     = trimspace(var.storage_container_name) != ""
    error_message = "`storage_container_name` must not be empty."
  }
}

variable "storage_infrastructure_encryption_enabled" {
  type        = bool
  description = "(Optional) Enable infrastructure encryption for the storage account."
  default     = false
}

variable "storage_local_user_enabled" {
  type        = bool
  description = "(Optional) Enable local users for the storage account."
  default     = true
}

variable "storage_shared_access_key_enabled" {
  type        = bool
  description = "(Optional) Enable shared access key authorization for the storage account."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "(Optional) Tags applied to Azure resources."
  default     = {}

  validation {
    condition     = alltrue([for tag_key, tag_value in var.tags : trimspace(tag_key) != "" && trimspace(tag_value) != ""])
    error_message = "`tags` must contain only non-empty keys and values."
  }
}

variable "vault_approle_role_name" {
  type        = string
  description = "(Optional) Vault AppRole name used by the automation workload."
  default     = "pki-renewal-automation"

  validation {
    condition     = trimspace(var.vault_approle_role_name) != ""
    error_message = "`vault_approle_role_name` must not be empty."
  }
}

variable "vault_approle_token_max_ttl" {
  type        = number
  description = "(Optional) Vault AppRole token max TTL in seconds."
  default     = 600

  validation {
    condition     = var.vault_approle_token_max_ttl > 0
    error_message = "`vault_approle_token_max_ttl` must be greater than 0."
  }
}

variable "vault_approle_token_ttl" {
  type        = number
  description = "(Optional) Vault AppRole token TTL in seconds."
  default     = 300

  validation {
    condition     = var.vault_approle_token_ttl > 0
    error_message = "`vault_approle_token_ttl` must be greater than 0."
  }
}

variable "vault_pki_path" {
  type        = string
  description = "(Optional) Vault PKI mount path used for certificate issuance."
  default     = "pki-int"

  validation {
    condition     = trimspace(var.vault_pki_path) != ""
    error_message = "`vault_pki_path` must not be empty."
  }
}

variable "vault_pki_role" {
  type        = string
  description = "(Optional) Vault PKI role used for certificate issuance."
  default     = "gw-cert-issuer"

  validation {
    condition     = trimspace(var.vault_pki_role) != ""
    error_message = "`vault_pki_role` must not be empty."
  }
}

variable "vault_pki_role_max_ttl" {
  type        = number
  description = "(Optional) Maximum TTL in seconds for certificates issued by the Vault PKI role."
  default     = 86400

  validation {
    condition     = var.vault_pki_role_max_ttl > 0
    error_message = "`vault_pki_role_max_ttl` must be greater than 0."
  }
}

variable "vault_policy_name" {
  type        = string
  description = "(Optional) Vault policy name used for certificate issuance permissions."
  default     = "vault-pki-renewal"

  validation {
    condition     = trimspace(var.vault_policy_name) != ""
    error_message = "`vault_policy_name` must not be empty."
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
