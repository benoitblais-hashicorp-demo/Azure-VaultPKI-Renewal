<!-- BEGIN_TF_DOCS -->
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

- `Key Vault Certificates Officer` (import/update certificates).
- `Key Vault Secrets User` (read certificate secrets for import/validation).

### Vault

The Vault identity used by Terraform needs a policy that allows:

- `create`, `update`, `read`, `delete`, `list` on `sys/auth/*` (enable AppRole).
- `create`, `update`, `read`, `delete`, `list` on `sys/policies/acl/*` (manage policy).
- `create`, `update`, `read`, `delete`, `list` on `auth/approle/*` (manage AppRole and secret IDs).
- `create`, `update`, `read`, `delete`, `list` on `<pki_mount>/roles/*` (manage PKI role).
- `update` on `<pki_mount>/issue/<pki_role>` (issue certificates).

## Authentications

### Azure Authentication

Use one of the following methods (same pattern as the Azure Storage Account module):

Service Principal and Client Secret

```hcl
provider "azurerm" {
	features {}

	subscription\_id = "<subscription-id>"
	tenant\_id       = "<tenant-id>"
	client\_id       = "<client-id>"
	client\_secret   = "<client-secret>"
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
	use\_msi = true
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
```

## Documentation

## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.6.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.64.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.7)

- <a name="requirement_vault"></a> [vault](#requirement\_vault) (~> 5.8.0)

## Modules

The following Modules are called:

### <a name="module_keyvault"></a> [keyvault](#module\_keyvault)

Source: app.terraform.io/benoitblais-hashicorp/keyvault/azurerm

Version: 0.0.1

### <a name="module_storage_account"></a> [storage\_account](#module\_storage\_account)

Source: app.terraform.io/benoitblais-hashicorp/storage-account/azurerm

Version: 0.0.4

## Required Inputs

The following input variables are required:

### <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id)

Description: (Required) Azure subscription ID used by the AzureRM provider.

Type: `string`

### <a name="input_vault_addr"></a> [vault\_addr](#input\_vault\_addr)

Description: (Required) Vault address used by certificate renewal automation.

Type: `string`

### <a name="input_vault_namespace"></a> [vault\_namespace](#input\_vault\_namespace)

Description: (Required) Vault namespace used by certificate renewal automation.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_app_gateway_autoscale_max_capacity"></a> [app\_gateway\_autoscale\_max\_capacity](#input\_app\_gateway\_autoscale\_max\_capacity)

Description: (Optional) Maximum autoscale capacity for Application Gateway.

Type: `number`

Default: `2`

### <a name="input_app_gateway_autoscale_min_capacity"></a> [app\_gateway\_autoscale\_min\_capacity](#input\_app\_gateway\_autoscale\_min\_capacity)

Description: (Optional) Minimum autoscale capacity for Application Gateway.

Type: `number`

Default: `1`

### <a name="input_app_gateway_backend_address_pool_fqdns"></a> [app\_gateway\_backend\_address\_pool\_fqdns](#input\_app\_gateway\_backend\_address\_pool\_fqdns)

Description: (Optional) Backend pool FQDNs for Application Gateway.

Type: `list(string)`

Default:

```json
[
  "example.com"
]
```

### <a name="input_app_gateway_backend_address_pool_name"></a> [app\_gateway\_backend\_address\_pool\_name](#input\_app\_gateway\_backend\_address\_pool\_name)

Description: (Optional) Backend address pool name in Application Gateway.

Type: `string`

Default: `"demo-backend-pool"`

### <a name="input_app_gateway_backend_http_settings_cookie_based_affinity"></a> [app\_gateway\_backend\_http\_settings\_cookie\_based\_affinity](#input\_app\_gateway\_backend\_http\_settings\_cookie\_based\_affinity)

Description: (Optional) Cookie-based affinity mode for backend HTTP settings.

Type: `string`

Default: `"Disabled"`

### <a name="input_app_gateway_backend_http_settings_name"></a> [app\_gateway\_backend\_http\_settings\_name](#input\_app\_gateway\_backend\_http\_settings\_name)

Description: (Optional) Backend HTTP settings name in Application Gateway.

Type: `string`

Default: `"demo-backend-http-settings"`

### <a name="input_app_gateway_backend_http_settings_path"></a> [app\_gateway\_backend\_http\_settings\_path](#input\_app\_gateway\_backend\_http\_settings\_path)

Description: (Optional) Backend path for Application Gateway HTTP settings.

Type: `string`

Default: `"/"`

### <a name="input_app_gateway_backend_http_settings_port"></a> [app\_gateway\_backend\_http\_settings\_port](#input\_app\_gateway\_backend\_http\_settings\_port)

Description: (Optional) Backend port for Application Gateway HTTP settings.

Type: `number`

Default: `80`

### <a name="input_app_gateway_backend_http_settings_protocol"></a> [app\_gateway\_backend\_http\_settings\_protocol](#input\_app\_gateway\_backend\_http\_settings\_protocol)

Description: (Optional) Backend protocol for Application Gateway HTTP settings.

Type: `string`

Default: `"Http"`

### <a name="input_app_gateway_backend_http_settings_request_timeout"></a> [app\_gateway\_backend\_http\_settings\_request\_timeout](#input\_app\_gateway\_backend\_http\_settings\_request\_timeout)

Description: (Optional) Backend request timeout in seconds for Application Gateway HTTP settings.

Type: `number`

Default: `30`

### <a name="input_app_gateway_frontend_ip_configuration_name"></a> [app\_gateway\_frontend\_ip\_configuration\_name](#input\_app\_gateway\_frontend\_ip\_configuration\_name)

Description: (Optional) Frontend IP configuration name in Application Gateway.

Type: `string`

Default: `"public-frontend"`

### <a name="input_app_gateway_frontend_port"></a> [app\_gateway\_frontend\_port](#input\_app\_gateway\_frontend\_port)

Description: (Optional) Frontend listener port for Application Gateway.

Type: `number`

Default: `443`

### <a name="input_app_gateway_frontend_port_name"></a> [app\_gateway\_frontend\_port\_name](#input\_app\_gateway\_frontend\_port\_name)

Description: (Optional) Frontend port name in Application Gateway.

Type: `string`

Default: `"https-443"`

### <a name="input_app_gateway_gateway_ip_configuration_name"></a> [app\_gateway\_gateway\_ip\_configuration\_name](#input\_app\_gateway\_gateway\_ip\_configuration\_name)

Description: (Optional) Gateway IP configuration name in Application Gateway.

Type: `string`

Default: `"gateway-ip-config"`

### <a name="input_app_gateway_http_listener_name"></a> [app\_gateway\_http\_listener\_name](#input\_app\_gateway\_http\_listener\_name)

Description: (Optional) HTTP listener name in Application Gateway.

Type: `string`

Default: `"https-listener"`

### <a name="input_app_gateway_http_listener_protocol"></a> [app\_gateway\_http\_listener\_protocol](#input\_app\_gateway\_http\_listener\_protocol)

Description: (Optional) HTTP listener protocol in Application Gateway.

Type: `string`

Default: `"Https"`

### <a name="input_app_gateway_request_routing_rule_name"></a> [app\_gateway\_request\_routing\_rule\_name](#input\_app\_gateway\_request\_routing\_rule\_name)

Description: (Optional) Request routing rule name in Application Gateway.

Type: `string`

Default: `"demo-routing-rule"`

### <a name="input_app_gateway_request_routing_rule_priority"></a> [app\_gateway\_request\_routing\_rule\_priority](#input\_app\_gateway\_request\_routing\_rule\_priority)

Description: (Optional) Request routing rule priority in Application Gateway.

Type: `number`

Default: `100`

### <a name="input_app_gateway_request_routing_rule_type"></a> [app\_gateway\_request\_routing\_rule\_type](#input\_app\_gateway\_request\_routing\_rule\_type)

Description: (Optional) Request routing rule type in Application Gateway.

Type: `string`

Default: `"Basic"`

### <a name="input_app_gateway_sku_name"></a> [app\_gateway\_sku\_name](#input\_app\_gateway\_sku\_name)

Description: (Optional) SKU name for Application Gateway.

Type: `string`

Default: `"Standard_v2"`

### <a name="input_app_gateway_sku_tier"></a> [app\_gateway\_sku\_tier](#input\_app\_gateway\_sku\_tier)

Description: (Optional) SKU tier for Application Gateway.

Type: `string`

Default: `"Standard_v2"`

### <a name="input_app_gateway_ssl_certificate_name"></a> [app\_gateway\_ssl\_certificate\_name](#input\_app\_gateway\_ssl\_certificate\_name)

Description: (Optional) SSL certificate name in Application Gateway.

Type: `string`

Default: `"tls-from-key-vault"`

### <a name="input_app_gateway_subnet_name"></a> [app\_gateway\_subnet\_name](#input\_app\_gateway\_subnet\_name)

Description: (Optional) Subnet name for the Application Gateway.

Type: `string`

Default: `"app-gateway"`

### <a name="input_app_gateway_subnet_prefix"></a> [app\_gateway\_subnet\_prefix](#input\_app\_gateway\_subnet\_prefix)

Description: (Optional) CIDR prefix used by the dedicated Application Gateway subnet.

Type: `string`

Default: `"10.20.1.0/24"`

### <a name="input_azure_automation_account_name"></a> [azure\_automation\_account\_name](#input\_azure\_automation\_account\_name)

Description: (Optional) Azure Automation Account name used for runbook-based certificate renewal.

Type: `string`

Default: `"aa-vault-pki-renewal"`

### <a name="input_azure_automation_runbook_log_verbose"></a> [azure\_automation\_runbook\_log\_verbose](#input\_azure\_automation\_runbook\_log\_verbose)

Description: (Optional) When true, enables verbose logging on the Azure Automation runbook.

Type: `bool`

Default: `true`

### <a name="input_azure_automation_runbook_name"></a> [azure\_automation\_runbook\_name](#input\_azure\_automation\_runbook\_name)

Description: (Optional) Azure Automation runbook name used for certificate renewal.

Type: `string`

Default: `"renew-certificate"`

### <a name="input_azure_automation_schedule_interval_hours"></a> [azure\_automation\_schedule\_interval\_hours](#input\_azure\_automation\_schedule\_interval\_hours)

Description: (Optional) Hour interval for Azure Automation schedule recurrence.

Type: `number`

Default: `1`

### <a name="input_azure_automation_schedule_name"></a> [azure\_automation\_schedule\_name](#input\_azure\_automation\_schedule\_name)

Description: (Optional) Azure Automation schedule name used for runbook recurrence.

Type: `string`

Default: `"hourly-certificate-renewal"`

### <a name="input_azure_automation_schedule_start_time"></a> [azure\_automation\_schedule\_start\_time](#input\_azure\_automation\_schedule\_start\_time)

Description: (Optional) RFC3339 UTC start time for the Azure Automation schedule.

Type: `string`

Default: `"2026-03-19T00:37:00Z"`

### <a name="input_azure_automation_schedule_timezone"></a> [azure\_automation\_schedule\_timezone](#input\_azure\_automation\_schedule\_timezone)

Description: (Optional) Azure Automation schedule timezone.

Type: `string`

Default: `"Etc/UTC"`

### <a name="input_azure_automation_vault_auth_path"></a> [azure\_automation\_vault\_auth\_path](#input\_azure\_automation\_vault\_auth\_path)

Description: (Optional) Vault auth path used by the Azure Automation runbook.

Type: `string`

Default: `""`

### <a name="input_initial_certificate_common_name"></a> [initial\_certificate\_common\_name](#input\_initial\_certificate\_common\_name)

Description: (Optional) Common Name requested from Vault PKI for the initial bootstrap certificate.

Type: `string`

Default: `"appgw.demo.example.com"`

### <a name="input_initial_certificate_ttl"></a> [initial\_certificate\_ttl](#input\_initial\_certificate\_ttl)

Description: (Optional) TTL sent to Vault PKI for the initial bootstrap certificate.

Type: `string`

Default: `"24h"`

### <a name="input_key_vault_certificate_name"></a> [key\_vault\_certificate\_name](#input\_key\_vault\_certificate\_name)

Description: (Optional) Certificate name created in Key Vault and referenced by Application Gateway.

Type: `string`

Default: `"gw-demo-tls-cert"`

### <a name="input_key_vault_soft_delete_retention_days"></a> [key\_vault\_soft\_delete\_retention\_days](#input\_key\_vault\_soft\_delete\_retention\_days)

Description: (Optional) Soft delete retention (days) for Key Vault. Minimum is 7 in Azure.

Type: `number`

Default: `7`

### <a name="input_location"></a> [location](#input\_location)

Description: (Optional) Azure region where the demo resources are deployed.

Type: `string`

Default: `"canadacentral"`

### <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix)

Description: (Optional) Prefix used for Azure resource naming.

Type: `string`

Default: `"vault-pki"`

### <a name="input_resource_suffix"></a> [resource\_suffix](#input\_resource\_suffix)

Description: (Optional) Resource name suffix used to build shared resource names.

Type: `string`

Default: `"vault-pki-renewal"`

### <a name="input_storage_account_name"></a> [storage\_account\_name](#input\_storage\_account\_name)

Description: (Optional) Storage account name override. Leave empty to derive from resource group suffix.

Type: `string`

Default: `""`

### <a name="input_storage_allow_nested_items_to_be_public"></a> [storage\_allow\_nested\_items\_to\_be\_public](#input\_storage\_allow\_nested\_items\_to\_be\_public)

Description: (Optional) Allow nested items within the storage account to be public.

Type: `bool`

Default: `true`

### <a name="input_storage_blob_access_tier"></a> [storage\_blob\_access\_tier](#input\_storage\_blob\_access\_tier)

Description: (Optional) Access tier for the package blob.

Type: `string`

Default: `"Hot"`

### <a name="input_storage_blob_change_feed_enabled"></a> [storage\_blob\_change\_feed\_enabled](#input\_storage\_blob\_change\_feed\_enabled)

Description: (Optional) Enable blob change feed on the storage account.

Type: `bool`

Default: `false`

### <a name="input_storage_blob_content_type"></a> [storage\_blob\_content\_type](#input\_storage\_blob\_content\_type)

Description: (Optional) Content type for the package blob.

Type: `string`

Default: `"application/octet-stream"`

### <a name="input_storage_blob_last_access_time_enabled"></a> [storage\_blob\_last\_access\_time\_enabled](#input\_storage\_blob\_last\_access\_time\_enabled)

Description: (Optional) Enable blob last access time tracking.

Type: `bool`

Default: `false`

### <a name="input_storage_blob_name"></a> [storage\_blob\_name](#input\_storage\_blob\_name)

Description: (Optional) Package blob name stored in the container.

Type: `string`

Default: `"cryptography-3.2.1-cp38-cp38-win_amd64.whl"`

### <a name="input_storage_blob_parallelism"></a> [storage\_blob\_parallelism](#input\_storage\_blob\_parallelism)

Description: (Optional) Upload parallelism for the package blob.

Type: `number`

Default: `8`

### <a name="input_storage_blob_source"></a> [storage\_blob\_source](#input\_storage\_blob\_source)

Description: (Optional) Local path to the package blob source file.

Type: `string`

Default: `"./packages/cryptography-3.2.1-cp38-cp38-win_amd64.whl"`

### <a name="input_storage_blob_type"></a> [storage\_blob\_type](#input\_storage\_blob\_type)

Description: (Optional) Storage blob type for the package.

Type: `string`

Default: `"Block"`

### <a name="input_storage_blob_versioning_enabled"></a> [storage\_blob\_versioning\_enabled](#input\_storage\_blob\_versioning\_enabled)

Description: (Optional) Enable blob versioning on the storage account.

Type: `bool`

Default: `false`

### <a name="input_storage_container_access_type"></a> [storage\_container\_access\_type](#input\_storage\_container\_access\_type)

Description: (Optional) Access level for the storage container.

Type: `string`

Default: `"private"`

### <a name="input_storage_container_name"></a> [storage\_container\_name](#input\_storage\_container\_name)

Description: (Optional) Storage container name for the automation package.

Type: `string`

Default: `"python-packages"`

### <a name="input_storage_infrastructure_encryption_enabled"></a> [storage\_infrastructure\_encryption\_enabled](#input\_storage\_infrastructure\_encryption\_enabled)

Description: (Optional) Enable infrastructure encryption for the storage account.

Type: `bool`

Default: `false`

### <a name="input_storage_local_user_enabled"></a> [storage\_local\_user\_enabled](#input\_storage\_local\_user\_enabled)

Description: (Optional) Enable local users for the storage account.

Type: `bool`

Default: `true`

### <a name="input_storage_shared_access_key_enabled"></a> [storage\_shared\_access\_key\_enabled](#input\_storage\_shared\_access\_key\_enabled)

Description: (Optional) Enable shared access key authorization for the storage account.

Type: `bool`

Default: `true`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: (Optional) Tags applied to Azure resources.

Type: `map(string)`

Default: `{}`

### <a name="input_vault_approle_role_name"></a> [vault\_approle\_role\_name](#input\_vault\_approle\_role\_name)

Description: (Optional) Vault AppRole name used by the automation workload.

Type: `string`

Default: `"pki-renewal-automation"`

### <a name="input_vault_approle_token_max_ttl"></a> [vault\_approle\_token\_max\_ttl](#input\_vault\_approle\_token\_max\_ttl)

Description: (Optional) Vault AppRole token max TTL in seconds.

Type: `number`

Default: `600`

### <a name="input_vault_approle_token_ttl"></a> [vault\_approle\_token\_ttl](#input\_vault\_approle\_token\_ttl)

Description: (Optional) Vault AppRole token TTL in seconds.

Type: `number`

Default: `300`

### <a name="input_vault_pki_path"></a> [vault\_pki\_path](#input\_vault\_pki\_path)

Description: (Optional) Vault PKI mount path used for certificate issuance.

Type: `string`

Default: `"pki-int"`

### <a name="input_vault_pki_role"></a> [vault\_pki\_role](#input\_vault\_pki\_role)

Description: (Optional) Vault PKI role used for certificate issuance.

Type: `string`

Default: `"gw-cert-issuer"`

### <a name="input_vault_pki_role_max_ttl"></a> [vault\_pki\_role\_max\_ttl](#input\_vault\_pki\_role\_max\_ttl)

Description: (Optional) Maximum TTL in seconds for certificates issued by the Vault PKI role.

Type: `number`

Default: `86400`

### <a name="input_vault_policy_name"></a> [vault\_policy\_name](#input\_vault\_policy\_name)

Description: (Optional) Vault policy name used for certificate issuance permissions.

Type: `string`

Default: `"vault-pki-renewal"`

### <a name="input_vnet_address_space"></a> [vnet\_address\_space](#input\_vnet\_address\_space)

Description: (Optional) Address space assigned to the demo virtual network.

Type: `list(string)`

Default:

```json
[
  "10.20.0.0/16"
]
```

## Resources

The following resources are used by this module:

- [azurerm_application_gateway.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway) (resource)
- [azurerm_automation_account.certificate_renewal](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_account) (resource)
- [azurerm_automation_job_schedule.certificate_renewal](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_job_schedule) (resource)
- [azurerm_automation_python3_package.cryptography](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_python3_package) (resource)
- [azurerm_automation_runbook.certificate_renewal](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_runbook) (resource)
- [azurerm_automation_schedule.certificate_renewal](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_schedule) (resource)
- [azurerm_automation_variable_string.app_gateway_name](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_variable_string) (resource)
- [azurerm_automation_variable_string.app_gateway_resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_variable_string) (resource)
- [azurerm_automation_variable_string.app_gateway_ssl_cert_name](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_variable_string) (resource)
- [azurerm_automation_variable_string.cert_common_name](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_variable_string) (resource)
- [azurerm_automation_variable_string.cert_ttl](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_variable_string) (resource)
- [azurerm_automation_variable_string.key_vault_cert_name](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_variable_string) (resource)
- [azurerm_automation_variable_string.key_vault_name](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_variable_string) (resource)
- [azurerm_automation_variable_string.pfx_password](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_variable_string) (resource)
- [azurerm_automation_variable_string.subscription_id](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_variable_string) (resource)
- [azurerm_automation_variable_string.vault_addr](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_variable_string) (resource)
- [azurerm_automation_variable_string.vault_approle_role_id](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_variable_string) (resource)
- [azurerm_automation_variable_string.vault_approle_secret_id](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_variable_string) (resource)
- [azurerm_automation_variable_string.vault_auth_path](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_variable_string) (resource)
- [azurerm_automation_variable_string.vault_namespace](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_variable_string) (resource)
- [azurerm_automation_variable_string.vault_pki_path](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_variable_string) (resource)
- [azurerm_automation_variable_string.vault_pki_role](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_variable_string) (resource)
- [azurerm_automation_variable_string.vault_tls_skip_verify](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_variable_string) (resource)
- [azurerm_key_vault_certificate.bootstrap](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_certificate) (resource)
- [azurerm_public_ip.app_gateway](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_role_assignment.automation_app_gateway_update](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_subnet.app_gateway](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_user_assigned_identity.app_gateway](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) (resource)
- [azurerm_virtual_network.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
- [random_password.bootstrap_pfx_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) (resource)
- [vault_approle_auth_backend_role.workload](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/approle_auth_backend_role) (resource)
- [vault_approle_auth_backend_role_secret_id.workload](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/approle_auth_backend_role_secret_id) (resource)
- [vault_auth_backend.approle](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/auth_backend) (resource)
- [vault_pki_secret_backend_role.bootstrap](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/pki_secret_backend_role) (resource)
- [vault_policy.workload_pki_issue](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) (resource)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [azurerm_storage_account_sas.automation_packages](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/storage_account_sas) (data source)

## Outputs

The following outputs are exported:

### <a name="output_application_gateway_name"></a> [application\_gateway\_name](#output\_application\_gateway\_name)

Description: Application Gateway name receiving TLS certificate updates from Key Vault

### <a name="output_application_gateway_public_ip"></a> [application\_gateway\_public\_ip](#output\_application\_gateway\_public\_ip)

Description: Public IP address of the Application Gateway

### <a name="output_azure_automation_account_name"></a> [azure\_automation\_account\_name](#output\_azure\_automation\_account\_name)

Description: Azure Automation Account name for certificate renewal. Null when Azure Automation is disabled.

### <a name="output_azure_automation_runbook_name"></a> [azure\_automation\_runbook\_name](#output\_azure\_automation\_runbook\_name)

Description: Azure Automation runbook name for certificate renewal. Null when Azure Automation is disabled.

### <a name="output_key_vault_certificate_name"></a> [key\_vault\_certificate\_name](#output\_key\_vault\_certificate\_name)

Description: Certificate name in Azure Key Vault updated by the renewal automation

### <a name="output_key_vault_name"></a> [key\_vault\_name](#output\_key\_vault\_name)

Description: Azure Key Vault name storing the TLS certificate

### <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name)

Description: Resource group that contains the demo resources

<!-- markdownlint-enable -->
# External Documentation

- [Azure Resource Group resource](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group)
- [Azure Virtual Network resource](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network)
- [Azure Subnet resource](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet)
- [Azure Public IP resource](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip)
- [Azure User Assigned Identity resource](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity)
- [Azure Key Vault resource](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault)
- [Azure Key Vault Certificate resource](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault\_certificate)
- [Azure Application Gateway resource](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway)
- [Vault PKI issue certificate API](https://developer.hashicorp.com/vault/api-docs/secret/pki#generate-certificate-and-key)
- [Azure Key Vault certificate import CLI](https://learn.microsoft.com/cli/azure/keyvault/certificate#az-keyvault-certificate-import)
- [Application Gateway TLS with Key Vault certificates](https://learn.microsoft.com/azure/application-gateway/key-vault-certs)
- [Azure Key Vault VM extension overview](https://learn.microsoft.com/azure/virtual-machines/extensions/key-vault-windows)
<!-- END_TF_DOCS -->