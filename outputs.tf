output "application_gateway_name" {
  description = "Application Gateway name receiving TLS certificate updates from Key Vault"
  value       = azurerm_application_gateway.this.name
}

output "application_gateway_public_ip" {
  description = "Public IP address of the Application Gateway"
  value       = azurerm_public_ip.app_gateway.ip_address
}

output "key_vault_certificate_name" {
  description = "Certificate name in Azure Key Vault updated by the renewal automation"
  value       = azurerm_key_vault_certificate.bootstrap.name
}

output "key_vault_name" {
  description = "Azure Key Vault name storing the TLS certificate"
  value       = azurerm_key_vault.this.name
}

output "resource_group_name" {
  description = "Resource group that contains the demo resources"
  value       = azurerm_resource_group.this.name
}
