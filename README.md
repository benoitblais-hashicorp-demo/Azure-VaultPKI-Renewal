<!-- BEGIN_TF_DOCS -->
# Azure Vault PKI Renewal Demo

This repository provides an Azure equivalent of the AWS Vault PKI renewal demo:

- Infrastructure: Azure Key Vault + Azure Application Gateway
- Automation: Azure DevOps scheduled pipeline
- Certificate source: HashiCorp Vault PKI

## Quick Start

1. Create `terraform.tfvars`:

```hcl
subscription_id     = "de9a4ec1-655a-4d76-9e59-c285c2ee7290"
location            = "canadacentral"
resource_group_name = "rg-vault-pki-renewal"
name_prefix         = "vault-pki-az"
```

2. Deploy infrastructure:

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

3. In Azure DevOps, configure secure variables used by `azure-pipelines.yml`:

- `AZURE_SERVICE_CONNECTION`
- `VAULT_ADDR`
- `VAULT_NAMESPACE` (optional)
- `VAULT_TOKEN`
- `VAULT_PKI_PATH`
- `VAULT_PKI_ROLE`
- `CERT_COMMON_NAME`
- `CERT_TTL`
- `AZURE_KEYVAULT_NAME`
- `AZURE_KEYVAULT_CERT_NAME`
- `PFX_PASSWORD`

4. Run pipeline manually once, then let the hourly schedule handle renewals.

## Notes About Azure Key Vault VM Extension

- Relevant when TLS is terminated directly on VMs.
- Not required for Application Gateway TLS termination.
- Still compatible with this pattern: renewed cert versions in Key Vault can be consumed by VM extensions.

## Documentation

Run Terraform Docs if available to refresh this README from [docs/README_header.md](docs/README_header.md) and [docs/README_footer.md](docs/README_footer.md):

```bash
terraform-docs --config .github/terraform-docs/.tfdocs-config.yml .
```
<!-- END_TF_DOCS -->
