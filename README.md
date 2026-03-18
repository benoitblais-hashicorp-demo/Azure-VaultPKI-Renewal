<!-- BEGIN_TF_DOCS -->
# Azure Vault PKI Renewal Demo

This Terraform project provisions Azure infrastructure to demonstrate automatic TLS certificate renewal using Vault PKI and an Azure Automation runbook.

## What This Demo Demonstrates

- A scheduled Azure Automation runbook requests a renewed certificate from Vault PKI.
- The runbook imports the renewed certificate into Azure Key Vault under a stable certificate name.
- Azure Application Gateway reads TLS material from Azure Key Vault and serves HTTPS.
- Certificate rotation happens by updating the same Key Vault certificate object used by Application Gateway.

## Demo Components

- Azure Resource Group, Virtual Network, and dedicated Application Gateway subnet
- Azure Key Vault storing the TLS certificate
- Azure Application Gateway (Standard v2) with HTTPS listener
- User-assigned managed identity for Application Gateway to read Key Vault secrets
- Azure Automation Account + Python3 runbook for hourly renewal automation
- Python runbook script (`scripts/automation_runbook.py`) for Vault PKI issue + Key Vault import

## Authentication

### Azure

- Terraform authenticates through the AzureRM provider using your standard Azure identity flow.
- Azure Automation runbook authenticates with its managed identity.

### Vault

- Terraform `vault` provider uses dynamic credentials from environment variables.
- Runbook uses either:
  - `VAULT_TOKEN` (static token), or
  - Vault JWT auth (`VAULT_AUTH_PATH`, `VAULT_AUTH_ROLE`, `VAULT_JWT_AUDIENCE`).

## Notes

- Legacy pipeline resources and variables were removed from this module.
- If your existing state still contains prior pipeline resources, remove them from state before apply.

## External Documentation

- [Azure Application Gateway](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway)
- [Azure Key Vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault)
- [Vault PKI certificate issuance API](https://developer.hashicorp.com/vault/api-docs/secret/pki#generate-certificate-and-key)
- [Azure Key Vault certificate import REST API](https://learn.microsoft.com/rest/api/keyvault/certificates/import-certificate/import-certificate)

<!-- END_TF_DOCS -->
