output "application_gateway_name" {
  description = "Application Gateway name receiving TLS certificate updates from Key Vault"
  value       = azurerm_application_gateway.this.name
}

output "application_gateway_public_ip" {
  description = "Public IP address of the Application Gateway"
  value       = azurerm_public_ip.app_gateway.ip_address
}

output "azure_automation_account_name" {
  description = "Azure Automation Account name for certificate renewal. Null when Azure Automation is disabled."
  value       = try(azurerm_automation_account.certificate_renewal[0].name, null)
}

output "azure_automation_runbook_name" {
  description = "Azure Automation runbook name for certificate renewal. Null when Azure Automation is disabled."
  value       = try(azurerm_automation_runbook.certificate_renewal[0].name, null)
}

output "key_vault_certificate_name" {
  description = "Certificate name in Azure Key Vault updated by the renewal automation"
  value       = var.key_vault_certificate_name
}

output "key_vault_name" {
  description = "Azure Key Vault name storing the TLS certificate"
  value       = azurerm_key_vault.this.name
}

output "resource_group_name" {
  description = "Resource group that contains the demo resources"
  value       = azurerm_resource_group.this.name
}

output "vault_jwt_backend_path" {
  description = "Vault JWT/OIDC auth backend path for workload logins"
  value       = var.vault_jwt_backend_path
}

output "vault_jwt_role_name" {
  description = "Vault JWT role name for workload logins. Null when disabled."
  value       = try(vault_jwt_auth_backend_role.workload[0].role_name, null)
}

output "vault_bootstrap_pfx_password_kv_mount" {
  description = "Vault KVv2 mount used for generated bootstrap PFX password storage"
  value       = var.bootstrap_pfx_password_kv_mount
}

output "vault_bootstrap_pfx_password_secret_path" {
  description = "Vault KVv2 secret path storing generated bootstrap PFX password"
  value       = try(vault_kv_secret_v2.bootstrap_pfx_password[0].path, null)
}
