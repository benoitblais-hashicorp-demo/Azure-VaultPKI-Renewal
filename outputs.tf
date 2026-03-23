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
  value       = azurerm_automation_account.certificate_renewal.name
}

output "azure_automation_runbook_name" {
  description = "Azure Automation runbook name for certificate renewal. Null when Azure Automation is disabled."
  value       = azurerm_automation_runbook.certificate_renewal.name
}

output "key_vault_certificate_name" {
  description = "Certificate name in Azure Key Vault updated by the renewal automation"
  value       = var.key_vault_certificate_name
}

output "key_vault_name" {
  description = "Azure Key Vault name storing the TLS certificate"
  value       = module.keyvault.keyvault.name
}

output "resource_group_name" {
  description = "Resource group that contains the demo resources"
  value       = azurerm_resource_group.this.name
}
