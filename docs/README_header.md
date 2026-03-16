# Azure Vault PKI Renewal Demo

This Terraform project provisions Azure infrastructure to demonstrate automatic TLS certificate renewal using Vault PKI.

## What This Demo Demonstrates

- A scheduled Azure DevOps pipeline requests a renewed certificate from Vault PKI.
- The pipeline imports the renewed certificate (PFX) into Azure Key Vault under a stable certificate name.
- Azure Application Gateway reads TLS material from Azure Key Vault and serves HTTPS.
- Certificate rotation happens by updating the same Key Vault certificate object used by Application Gateway.

## Demo Components

- Azure Resource Group, Virtual Network, and dedicated Application Gateway subnet
- Azure Key Vault storing the TLS certificate
- Azure Application Gateway (Standard v2) with HTTPS listener
- User-assigned managed identity for Application Gateway to read Key Vault secrets
- Azure DevOps pipeline (`azure-pipelines.yml`) for hourly renewal automation
- Python renewal script (`scripts/renew_certificate.py`) for Vault PKI issue + Key Vault import

## Permissions

### Azure

The Azure identity running Terraform needs permission to create and manage:

- Resource Group, VNet/Subnet, Public IP, Application Gateway, and Managed Identity
- Azure Key Vault, access policies, and certificates

The Azure DevOps service connection needs permission to:

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
- Azure DevOps authenticates with an Azure service connection (`AZURE_SERVICE_CONNECTION`).

### Vault Authentication

Terraform `vault` provider uses dynamic credentials from environment variables (for example HCP Terraform dynamic credentials), not a hardcoded token in code.

The renewal automation authenticates to Vault using environment variables available to the pipeline (for example secure Azure DevOps variables).

Required pipeline Vault environment values:

- `VAULT_ADDR`
- `VAULT_NAMESPACE` (optional)
- `VAULT_TOKEN`
- `VAULT_PKI_PATH`
- `VAULT_PKI_ROLE`

## Features

- End-to-end hourly renewal workflow from Vault PKI to Azure Key Vault
- Application Gateway HTTPS configuration backed by Key Vault certificate reference
- Minimal infrastructure footprint for demo purposes
- Parameterized naming, addressing, and tagging

## How Certificate Renewal Works in this Demo

This demo uses a scheduled pipeline model where Azure DevOps runs every hour, issues a certificate from Vault PKI, converts it to PFX, and imports it back to Azure Key Vault.

### The Workflow

1. Azure DevOps pipeline runs on schedule (`0 * * * *`) or manual execution.
2. Pipeline calls Vault PKI issue API with configured role and Common Name.
3. Script builds a PKCS#12 (PFX) bundle from issued cert and private key.
4. Script imports the renewed PFX to the same certificate name in Key Vault.
5. Application Gateway continues referencing Key Vault certificate and uses renewed material.

### Run the Demo Immediately (No 1-Hour Wait)

You can run the Azure DevOps pipeline manually from the Azure DevOps UI to force immediate certificate renewal.

## Azure Key Vault VM Extension Relevance

This is relevant only when your workload terminates TLS directly on VMs that use the Key Vault VM extension to pull certificates.

- If your TLS endpoint is Application Gateway, the VM extension is not part of the datapath and is not required for this demo.
- If you also have VM-based workloads, this same renewal pattern still helps because importing a renewed certificate to Key Vault enables the VM extension to fetch updated certificate versions.


