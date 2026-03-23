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

The Azure identity running Terraform needs permissions such as:

- `Contributor` (resource group and Azure resource lifecycle operations).
- `Network Contributor` (virtual network and subnet operations).
- `User Access Administrator` (role assignments for managed identities if required).
- `Key Vault Administrator` (manage Key Vault access policies and certificates).

The Azure Automation managed identity needs data-plane access to Key Vault. If you use Key Vault RBAC, grant:

- `Key Vault Certificates Officer` (import and update certificates).
- `Key Vault Secrets User` (read certificate secrets and metadata).

### Vault

The Vault identity used by Terraform needs a policy that allows:

- `create`, `update`, `read`, `delete`, `list` on `sys/auth/approle` and `sys/auth/approle/*` (enable AppRole).
- `create`, `update`, `read`, `delete`, `list` on `sys/policies/acl/*` (manage policy).
- `create`, `update`, `read`, `delete`, `list` on `auth/approle/role/*` (manage AppRole roles).
- `create`, `update`, `read`, `delete`, `list` on `auth/approle/role/*/secret-id` (manage secret IDs).
- `create`, `update`, `read`, `delete`, `list` on `<pki_mount>/roles/*` (manage PKI role).
- `update` on `<pki_mount>/issue/<pki_role>` (issue certificates).

## Authentications

### Azure Authentication

Authentication to Azure can be configured using one of the following methods:

#### Service Principal and Client Secret

Use an Azure AD service principal for non-interactive runs (CI/CD, automation).

You can configure this method in either of the following ways:

- **Inside the provider block**

  ```hcl
  provider "azurerm" {
    features {}

    subscription_id = "<subscription-id>"
    tenant_id       = "<tenant-id>"
    client_id       = "<client-id>"
    client_secret   = "<client-secret>"
  }
  ```

- **Using environment variables**

  - `ARM_SUBSCRIPTION_ID`
  - `ARM_TENANT_ID`
  - `ARM_CLIENT_ID`
  - `ARM_CLIENT_SECRET`

#### Managed Service Identity

Use Managed Identity when Terraform runs on Azure-hosted compute (for example, Azure VM, VMSS, App Service, AKS).

- **Inside the provider block**

  ```hcl
  provider "azurerm" {
    features {}
    use_msi = true
  }
  ```

- **Using environment variables**

  - `ARM_USE_MSI=true`
  - `ARM_SUBSCRIPTION_ID`
  - `ARM_TENANT_ID` (optional in some environments, but recommended for clarity)

Documentation:

- [Authenticating to Azure](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure)
- [Service Principal and Client Secret](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret)
- [Managed Service Identity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/managed_service_identity)

### Vault Authentication

#### HCP Terraform Dynamic Credentials (Recommended)

For enhanced security, use HCP Terraform's dynamic provider credentials feature to authenticate to Vault without storing static tokens.
This method uses workload identity (JWT/OIDC) to generate short-lived Vault tokens automatically.

**Benefits:**

- No static credentials stored in Terraform Cloud/Enterprise
- Automatic token rotation with short TTL
- Improved security posture with just-in-time authentication
- Centralized audit trail in both HCP Terraform and Vault

Use environment variables to authenticate with a static Vault token:

- **TFC\_VAULT\_PROVIDER\_AUTH**: Set the `TFC_VAULT_PROVIDER_AUTH` environment variable to `true`.
- **TFC\_VAULT\_ADDR**: Set the `TFC_VAULT_ADDR` environment variable to your Vault server address (e.g., `https://vault.example.com:8200`)
- **TFC\_VAULT\_NAMESPACE**: (Optional) Set the `TFC_VAULT_NAMESPACE` environment variable to the parent namespace where the module will create the sub-namespace (e.g., `admin`). If not set, the namespace will be created at the root level.
- **TFC\_VAULT\_RUN\_ROLE**: Set the `TFC_VAULT_RUN_ROLE` environment variable to the JWT role name configured in Vault (e.g., `hcp-terraform`)

**Documentation:**

- [HCP Terraform Dynamic Credentials](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials)
- [Vault JWT Auth Method](https://developer.hashicorp.com/vault/docs/auth/jwt)

#### Runbook Authentication (AppRole)

The Azure Automation runbook authenticates to Vault using AppRole credentials passed as automation variables.

**Required automation variables:**

- **VAULT_ADDR**: Vault address (e.g., `https://vault.example.com:8200`)
- **VAULT_NAMESPACE**: Vault namespace (if applicable)
- **VAULT_AUTH_PATH**: AppRole auth mount path (default: `approle`)
- **VAULT_APPROLE_ROLE_ID**: AppRole role ID
- **VAULT_APPROLE_SECRET_ID**: AppRole secret ID
- **VAULT_PKI_PATH**: PKI mount path (e.g., `pki-int`)
- **VAULT_PKI_ROLE**: PKI role name (e.g., `gw-cert-issuer`)

## Demo Cleanup Note

Azure Key Vault enforces soft delete with a minimum 7-day retention. This demo sets purge protection to false, so you can delete and then purge the vault to recreate it immediately. Use Azure CLI after destroy:

```bash
az keyvault purge --name <key-vault-name>
az keyvault purge --name kv-vault-pki-renewal
```
