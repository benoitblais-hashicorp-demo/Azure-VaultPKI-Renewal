# Azure Vault PKI Renewal Demo

This Terraform project provisions Azure infrastructure to demonstrate automatic TLS certificate renewal using Vault PKI.

## What This Demo Demonstrates



## Demo Components


## Permissions

### Azure



### Vault

Terraform identity for Vault provider must be able to manage:

- Vault policy
- Vault AWS auth role
- Certificate issuance from an existing Vault PKI mount and PKI role

The Lambda Vault token created dynamically through AWS auth is scoped by the Terraform-managed policy to:

- `update` on `/<pki_mount>/issue/<pki_role>`

## Authentications

### Azure Authentication



### Vault Authentication

Terraform `vault` provider uses dynamic credentials from environment variables (for example HCP Terraform dynamic credentials), not a hardcoded token in code.

The Lambda authenticates to Vault using AWS IAM auth and its own execution role.

Required Lambda Vault environment values:

- `VAULT_ADDR`
- `VAULT_NAMESPACE` (optional)
- `VAULT_AUTH_PATH`
- `VAULT_AUTH_ROLE`
- `VAULT_PKI_PATH`
- `VAULT_PKI_ROLE`

## Features



## How Certificate Renewal Works in this Demo



### The Workflow



### Run the Demo Immediately (No 1-Hour Wait)


