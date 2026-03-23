# Azure Vault PKI Renewal Demo

This Terraform project provisions Azure infrastructure to demonstrate automatic TLS certificate renewal using Vault PKI.

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

## Permissions

### Azure

The Azure identity running Terraform needs permission to create and manage:

- Resource Group, VNet/Subnet, Public IP, Application Gateway, and Managed Identity
- Azure Key Vault, access policies, and certificates

The Azure Automation managed identity needs permission to:

- Import certificates to the target Key Vault
- Read certificate metadata from the target Key Vault

### Vault

Terraform identity for Vault provider must be able to manage:

- Vault policy
- Vault auth role or token suitable for automation
- Certificate issuance from an existing Vault PKI mount and PKI role

The automation token is expected to be scoped to:

- `update` on `/<pki_mount>/issue/<pki_role>`

## Authentications

### Azure Authentication

- Terraform authenticates through the AzureRM provider using your standard Azure identity flow.
- Azure Automation runbook authenticates with its managed identity.

### Vault Authentication

Terraform `vault` provider uses dynamic credentials from environment variables (for example HCP Terraform dynamic credentials), not a hardcoded token in code.

The renewal automation authenticates to Vault using runbook variables and AppRole.

Required runbook Vault values:

- `VAULT_ADDR`
- `VAULT_NAMESPACE` (required in this module)
- `VAULT_AUTH_PATH`
- `VAULT_APPROLE_ROLE_ID`
- `VAULT_APPROLE_SECRET_ID`
- `VAULT_PKI_PATH`
- `VAULT_PKI_ROLE`

## Features

- End-to-end hourly renewal workflow from Vault PKI to Azure Key Vault
- Application Gateway HTTPS configuration backed by Key Vault certificate reference
- Minimal infrastructure footprint for demo purposes
- Parameterized naming, addressing, and tagging

## How Certificate Renewal Works in this Demo

This demo uses a scheduled runbook model where Azure Automation runs every hour, issues a certificate from Vault PKI, and imports it to Azure Key Vault.

### The Workflow

1. Azure Automation runbook runs on schedule or manual execution.
2. Runbook calls Vault PKI issue API with configured role and Common Name.
3. Runbook imports the renewed certificate to the same certificate name in Key Vault.
5. Application Gateway continues referencing Key Vault certificate and uses renewed material.

### Run the Demo Immediately (No 1-Hour Wait)

You can run the Azure Automation runbook manually from the Azure Portal to force immediate certificate renewal.

## Demo Cleanup Note

Azure Key Vault enforces soft delete with a minimum 7-day retention. This demo sets purge protection to false, so you can delete and then purge the vault to recreate it immediately. Use Azure CLI after destroy:

```bash
# Azure Vault PKI Renewal Demo

This Terraform project provisions a focused Azure stack that renews a TLS certificate every hour using Vault PKI, imports it into Azure Key Vault, and serves it through Azure Application Gateway.

## What This Demo Demonstrates

- Automated hourly certificate rotation using Vault PKI and Azure Automation.
- Stable Key Vault certificate name used by Application Gateway for zero-touch rotation.
- End-to-end integration between Vault, Key Vault, and Application Gateway.
- Minimal, repeatable infrastructure built for a demo lifecycle.

## Key Integration Points

- Vault PKI issue API -> Azure Automation runbook.
- Runbook imports a new PFX into the same Key Vault certificate object.
- Application Gateway references Key Vault and picks up the refreshed material.

## Demo Components

- Azure Resource Group, Virtual Network, and dedicated Application Gateway subnet.
- Azure Key Vault holding the TLS certificate.
- Azure Application Gateway (Standard v2) with HTTPS listener.
- User-assigned managed identity for Application Gateway to read Key Vault secrets.
- Azure Automation Account, schedule, and Python runbook for renewal.
- Runbook script at `scripts/automation_runbook.py`.

## How This Demo Works

1. Terraform provisions Azure resources plus Vault policy/AppRole wiring.
2. The runbook runs hourly and requests a certificate from Vault PKI.
3. The runbook imports the new certificate into Key Vault under a stable name.
4. Application Gateway continues to reference the Key Vault certificate and serves HTTPS.

# Azure Vault PKI Renewal Demo

This Terraform project provisions a focused Azure stack that renews a TLS certificate every hour using Vault PKI, imports it into Azure Key Vault, and serves it through Azure Application Gateway.

## What This Demo Demonstrates

- Automated hourly certificate rotation using Vault PKI and Azure Automation.
- Stable Key Vault certificate name used by Application Gateway for zero-touch rotation.
- End-to-end integration between Vault, Key Vault, and Application Gateway.
- Minimal, repeatable infrastructure built for a demo lifecycle.

## Key Integration Points

- Vault PKI issue API to Azure Automation runbook.
- Runbook imports a new PFX into the same Key Vault certificate object.
- Application Gateway references Key Vault and picks up the refreshed material.

## Demo Components

- Azure Resource Group, Virtual Network, and dedicated Application Gateway subnet.
- Azure Key Vault holding the TLS certificate.
- Azure Application Gateway (Standard v2) with HTTPS listener.
- User-assigned managed identity for Application Gateway to read Key Vault secrets.
- Azure Automation Account, schedule, and Python runbook for renewal.
- Runbook script at `scripts/automation_runbook.py`.

## How This Demo Works

1. Terraform provisions Azure resources plus Vault policy and AppRole wiring.
2. The runbook runs hourly and requests a certificate from Vault PKI.
3. The runbook imports the new certificate into Key Vault under a stable name.
4. Application Gateway continues to reference the Key Vault certificate and serves HTTPS.

### Run Once Immediately (No 1-Hour Wait)

Trigger the Azure Automation runbook manually once so the initial bootstrap certificate is imported immediately.

## Demo Value Proposition

- Shows certificate rotation without downtime or manual reconfiguration.
- Demonstrates secure, automated use of Vault PKI in Azure.
- Highlights least-effort operational cadence for certificate hygiene.

## Expected Behavior

- The first runbook execution creates or updates the Key Vault certificate.
- Application Gateway serves the Key Vault certificate name configured in Terraform.
- Subsequent hourly runs rotate the certificate and keep HTTPS valid.

## Permissions

### Azure

The Terraform identity needs the following roles:

- `Contributor` on the target resource group (resource lifecycle for VNet, App Gateway, Automation, Public IP, and identities).
- `Key Vault Administrator` on the Key Vault (manage certificates and access policies).

The Azure Automation managed identity needs data-plane access to Key Vault. If you use Key Vault RBAC, grant:

- `Key Vault Certificates Officer` (import and update certificates).
- `Key Vault Secrets User` (read certificate secrets for import and validation).

### Vault

The Vault identity used by Terraform needs a policy that allows:

- `create`, `update`, `read`, `delete`, `list` on `sys/auth/*` (enable AppRole).
- `create`, `update`, `read`, `delete`, `list` on `sys/policies/acl/*` (manage policy).
- `create`, `update`, `read`, `delete`, `list` on `auth/approle/*` (manage AppRole and secret IDs).
- `create`, `update`, `read`, `delete`, `list` on `<pki_mount>/roles/*` (manage PKI role).
- `update` on `<pki_mount>/issue/<pki_role>` (issue certificates).

## Authentications

### Azure Authentication

Use one of the following methods:

Service Principal and Client Secret

```hcl
provider "azurerm" {
	features {}

	subscription_id = "<subscription-id>"
	tenant_id       = "<tenant-id>"
	client_id       = "<client-id>"
	client_secret   = "<client-secret>"
}
```

Or environment variables:

- `ARM_SUBSCRIPTION_ID`
- `ARM_TENANT_ID`
- `ARM_CLIENT_ID`
- `ARM_CLIENT_SECRET`

Managed Identity

```hcl
provider "azurerm" {
	features {}
	use_msi = true
}
```

Or environment variables:

- `ARM_USE_MSI=true`
- `ARM_SUBSCRIPTION_ID`
- `ARM_TENANT_ID`

### Vault Authentication

Terraform provider authentication (environment variables or HCP Terraform dynamic credentials):

- `VAULT_ADDR`
- `VAULT_NAMESPACE` (required in this module)
- `VAULT_TOKEN`

Runbook authentication (AppRole):

- `VAULT_ADDR`
- `VAULT_NAMESPACE`
- `VAULT_AUTH_PATH`
- `VAULT_APPROLE_ROLE_ID`
- `VAULT_APPROLE_SECRET_ID`
- `VAULT_PKI_PATH`
- `VAULT_PKI_ROLE`

## Demo Cleanup Note

Azure Key Vault enforces soft delete with a minimum 7-day retention. This demo sets purge protection to false, so you can delete and then purge the vault to recreate it immediately. Use Azure CLI after destroy:

```bash
az keyvault purge --name <key-vault-name>
az keyvault purge --name kv-vault-pki-renewal
```
## Demo Cleanup Note

Azure Key Vault enforces soft delete with a minimum 7-day retention. This demo sets purge protection to false, so you can delete and then purge the vault to recreate it immediately. Use Azure CLI after destroy:

```bash
az keyvault purge --name <key-vault-name>
az keyvault purge --name kv-vault-pki-renewal
```
