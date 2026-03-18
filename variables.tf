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
    error_message = "`app_gateway_backend_address_pool_name` must not be empty."
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
    error_message = "`app_gateway_http_listener_protocol` must be `Http` or `Https`."
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
    error_message = "`app_gateway_request_routing_rule_type` must be `Basic` or `PathBasedRouting`."
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
  default     = "UTC"

  validation {
    condition     = trimspace(var.azure_automation_schedule_timezone) != ""
    error_message = "`azure_automation_schedule_timezone` must not be empty."
  }
}

variable "azure_automation_vault_auth_path" {
  type        = string
  description = "(Optional) Vault auth path used by the Azure Automation runbook when VAULT_TOKEN is not supplied."
  default     = ""

  validation {
    condition     = !var.enable_azure_automation_runbook || trimspace(var.azure_automation_vault_token) != "" || trimspace(var.azure_automation_vault_auth_path) != ""
    error_message = "`azure_automation_vault_auth_path` must be set when `enable_azure_automation_runbook` is true and `azure_automation_vault_token` is empty."
  }
}

variable "azure_automation_vault_auth_role" {
  type        = string
  description = "(Optional) Vault auth role used by the Azure Automation runbook when VAULT_TOKEN is not supplied."
  default     = ""

  validation {
    condition     = !var.enable_azure_automation_runbook || trimspace(var.azure_automation_vault_token) != "" || trimspace(var.azure_automation_vault_auth_role) != ""
    error_message = "`azure_automation_vault_auth_role` must be set when `enable_azure_automation_runbook` is true and `azure_automation_vault_token` is empty."
  }
}

variable "azure_automation_vault_jwt_audience" {
  type        = string
  description = "(Optional) Audience/resource used to request a managed-identity JWT for Vault login when VAULT_TOKEN and VAULT_JWT are not supplied."
  default     = ""

  validation {
    condition     = !var.enable_azure_automation_runbook || trimspace(var.azure_automation_vault_token) != "" || trimspace(var.azure_automation_vault_jwt_audience) != ""
    error_message = "`azure_automation_vault_jwt_audience` must be set when `enable_azure_automation_runbook` is true and `azure_automation_vault_token` is empty."
  }
}

variable "azure_automation_vault_token" {
  type        = string
  description = "(Optional) Static Vault token used by Azure Automation runbook. Prefer short-lived tokens and rotate regularly."
  default     = ""
  sensitive   = true
}

variable "enable_azure_automation_runbook" {
  type        = bool
  description = "(Optional) When true, creates Azure Automation resources to run certificate renewal on an hourly schedule."
  default     = false
}

variable "azure_devops_azure_service_connection_name" {
  type        = string
  description = "(Optional) Azure Resource Manager service connection name used by AzureCLI@2 in the generated pipeline. Must be set when Azure DevOps pipeline creation is enabled."
  default     = ""

  validation {
    condition     = trimspace(var.azure_devops_project_name) == "" || trimspace(var.azure_devops_azure_service_connection_name) != ""
    error_message = "`azure_devops_azure_service_connection_name` must be set when `azure_devops_project_name` is set."
  }
}

variable "azure_devops_jwt_backend_description" {
  type        = string
  description = "(Optional) Description for the Azure DevOps JWT/OIDC auth backend in Vault."
  default     = "JWT/OIDC auth backend for Azure DevOps pipelines"

  validation {
    condition     = trimspace(var.azure_devops_jwt_backend_description) != ""
    error_message = "`azure_devops_jwt_backend_description` must not be empty."
  }
}

variable "azure_devops_jwt_backend_path" {
  type        = string
  description = "(Optional) Path for the Azure DevOps JWT/OIDC auth backend in Vault."
  default     = "jwt_azure_devops"

  validation {
    condition     = trimspace(var.azure_devops_jwt_backend_path) != ""
    error_message = "`azure_devops_jwt_backend_path` must not be empty."
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

  validation {
    condition     = alltrue([for claim_key, claim_value in var.azure_devops_jwt_bound_claims : trimspace(claim_key) != "" && trimspace(claim_value) != ""])
    error_message = "`azure_devops_jwt_bound_claims` must contain only non-empty keys and values."
  }
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
    error_message = "`azure_devops_jwt_role_name` must not be empty."
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
    error_message = "`azure_devops_jwt_user_claim` must not be empty."
  }
}

variable "azure_devops_pipeline_branch_name" {
  type        = string
  description = "(Optional) Branch used by the Azure DevOps pipeline definition. Leave empty to use the repository default branch for Azure Repos Git or `main` for GitHub."
  default     = ""

  validation {
    condition     = var.azure_devops_pipeline_branch_name == "" || trimspace(var.azure_devops_pipeline_branch_name) == var.azure_devops_pipeline_branch_name
    error_message = "`azure_devops_pipeline_branch_name` must not include leading or trailing whitespace."
  }
}

variable "azure_devops_pipeline_folder" {
  type        = string
  description = "(Optional) Azure DevOps pipeline folder path. Use `\\` for the root folder."
  default     = "\\"

  validation {
    condition     = var.azure_devops_pipeline_folder == "\\" || (trimspace(var.azure_devops_pipeline_folder) != "" && !endswith(var.azure_devops_pipeline_folder, "\\"))
    error_message = "`azure_devops_pipeline_folder` must be `\\` or a non-empty folder path that does not end with `\\`."
  }
}

variable "azure_devops_pipeline_name" {
  type        = string
  description = "(Optional) Name of the Azure DevOps pipeline created by Terraform."
  default     = "vault-pki-renewal"

  validation {
    condition     = trimspace(var.azure_devops_pipeline_name) != ""
    error_message = "`azure_devops_pipeline_name` must not be empty."
  }
}

variable "azure_devops_pipeline_yaml_path" {
  type        = string
  description = "(Optional) Path to the Azure Pipelines YAML file in the source repository."
  default     = "azure-pipelines.yml"

  validation {
    condition     = trimspace(var.azure_devops_pipeline_yaml_path) != ""
    error_message = "`azure_devops_pipeline_yaml_path` must not be empty."
  }
}

variable "azure_devops_project_name" {
  type        = string
  description = "(Optional) Azure DevOps project name where the pipeline will be created. Leave empty to skip Azure DevOps pipeline creation."
  default     = ""

  validation {
    condition     = var.azure_devops_project_name == "" || trimspace(var.azure_devops_project_name) == var.azure_devops_project_name
    error_message = "`azure_devops_project_name` must not include leading or trailing whitespace."
  }
}

variable "azure_devops_repository_id" {
  type        = string
  description = "(Optional) Repository identifier used by Azure DevOps pipeline creation for external repositories. For GitHub, use `<owner>/<repo>`. Leave empty when `azure_devops_repository_type` is `TfsGit`."
  default     = ""

  validation {
    condition     = trimspace(var.azure_devops_project_name) == "" || var.azure_devops_repository_type == "TfsGit" || trimspace(var.azure_devops_repository_id) != ""
    error_message = "`azure_devops_repository_id` must be set when `azure_devops_project_name` is set and `azure_devops_repository_type` is not `TfsGit`."
  }
}

variable "azure_devops_repository_name" {
  type        = string
  description = "(Optional) Azure Repos Git repository name used when `azure_devops_repository_type` is `TfsGit`."
  default     = ""

  validation {
    condition     = trimspace(var.azure_devops_project_name) == "" || var.azure_devops_repository_type != "TfsGit" || trimspace(var.azure_devops_repository_name) != ""
    error_message = "`azure_devops_repository_name` must be set when `azure_devops_project_name` is set and `azure_devops_repository_type` is `TfsGit`."
  }
}

variable "azure_devops_repository_service_connection_id" {
  type        = string
  description = "(Optional) Azure DevOps service connection ID for external repositories such as GitHub. Leave empty for `TfsGit`."
  default     = ""

  validation {
    condition     = trimspace(var.azure_devops_project_name) == "" || !contains(["GitHub", "GitHubEnterprise"], var.azure_devops_repository_type) || trimspace(var.azure_devops_repository_service_connection_id) != ""
    error_message = "`azure_devops_repository_service_connection_id` must be set when `azure_devops_project_name` is set and `azure_devops_repository_type` is `GitHub` or `GitHubEnterprise`."
  }
}

variable "azure_devops_repository_type" {
  type        = string
  description = "(Optional) Repository type used by the Azure DevOps pipeline definition. Supported values are `GitHub`, `GitHubEnterprise`, and `TfsGit`."
  default     = "GitHub"

  validation {
    condition     = contains(["GitHub", "GitHubEnterprise", "TfsGit"], var.azure_devops_repository_type)
    error_message = "`azure_devops_repository_type` must be one of `GitHub`, `GitHubEnterprise`, or `TfsGit`."
  }
}

variable "bootstrap_pfx_password_create_kv_mount" {
  type        = bool
  description = "(Optional) When true, Terraform creates the KVv2 mount for bootstrap PFX password storage; set false when the mount already exists or mount management is not permitted."
  default     = false
}

variable "bootstrap_pfx_password_kv_mount" {
  type        = string
  description = "(Optional) Vault KVv2 mount path where the generated bootstrap PFX password is stored."
  default     = "kvv2_azure_devops"

  validation {
    condition     = trimspace(var.bootstrap_pfx_password_kv_mount) != ""
    error_message = "`bootstrap_pfx_password_kv_mount` must not be empty."
  }
}

variable "bootstrap_pfx_password_kv_path" {
  type        = string
  description = "(Optional) Vault KVv2 secret path where the generated bootstrap PFX password is stored."
  default     = "azure-vaultpki-renewal/bootstrap"

  validation {
    condition     = trimspace(var.bootstrap_pfx_password_kv_path) != ""
    error_message = "`bootstrap_pfx_password_kv_path` must not be empty."
  }
}

variable "bootstrap_pfx_password_store_in_vault" {
  type        = bool
  description = "(Optional) When true, Terraform writes the generated bootstrap PFX password into Vault KVv2. Defaults to false so least-privilege Vault configurations do not require KV write access unless explicitly enabled."
  default     = false
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
    error_message = "`location` must not be empty."
  }
}

variable "name_prefix" {
  type        = string
  description = "(Optional) Prefix used for Azure resource naming."
  default     = "vault-pki"

  validation {
    condition     = trimspace(var.name_prefix) != ""
    error_message = "`name_prefix` must not be empty."
  }
}

variable "resource_group_name" {
  type        = string
  description = "(Optional) Resource group name for all demo resources."
  default     = "rg-vault-pki-renewal"

  validation {
    condition     = trimspace(var.resource_group_name) != ""
    error_message = "`resource_group_name` must not be empty."
  }
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

variable "vault_namespace" {
  type        = string
  description = "(Optional) Vault namespace injected into the generated Azure DevOps pipeline file."
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

variable "vnet_address_space" {
  type        = list(string)
  description = "(Optional) Address space assigned to the demo virtual network."
  default     = ["10.20.0.0/16"]

  validation {
    condition     = length(var.vnet_address_space) > 0 && alltrue([for cidr in var.vnet_address_space : can(cidrnetmask(cidr))])
    error_message = "`vnet_address_space` must contain at least one valid CIDR block."
  }
}
