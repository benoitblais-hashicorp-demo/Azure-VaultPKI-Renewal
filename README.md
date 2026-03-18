<!-- BEGIN_TF_DOCS -->
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

## Documentation

## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.6.0)

- <a name="requirement_azuredevops"></a> [azuredevops](#requirement\_azuredevops) (~> 1.14.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.64.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.7)

- <a name="requirement_vault"></a> [vault](#requirement\_vault) (~> 5.8.0)

## Modules

No modules.

## Required Inputs

The following input variables are required:

### <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id)

Description: (Required) Azure subscription ID used by the AzureRM provider.

Type: `string`

### <a name="input_vault_addr"></a> [vault\_addr](#input\_vault\_addr)

Description: (Required) Vault address injected into the generated Azure DevOps pipeline file.

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

### <a name="input_app_gateway_subnet_prefix"></a> [app\_gateway\_subnet\_prefix](#input\_app\_gateway\_subnet\_prefix)

Description: (Optional) CIDR prefix used by the dedicated Application Gateway subnet.

Type: `string`

Default: `"10.20.1.0/24"`

### <a name="input_azure_devops_jwt_backend_description"></a> [azure\_devops\_jwt\_backend\_description](#input\_azure\_devops\_jwt\_backend\_description)

Description: (Optional) Description for the Azure DevOps JWT/OIDC auth backend in Vault.

Type: `string`

Default: `"JWT/OIDC auth backend for Azure DevOps pipelines"`

### <a name="input_azure_devops_jwt_backend_path"></a> [azure\_devops\_jwt\_backend\_path](#input\_azure\_devops\_jwt\_backend\_path)

Description: (Optional) Path for the Azure DevOps JWT/OIDC auth backend in Vault.

Type: `string`

Default: `"jwt_azure_devops"`

### <a name="input_azure_devops_jwt_bound_audiences"></a> [azure\_devops\_jwt\_bound\_audiences](#input\_azure\_devops\_jwt\_bound\_audiences)

Description: (Optional) Accepted audience claims for the Azure DevOps OIDC tokens.

Type: `list(string)`

Default:

```json
[
  "vault.workload.identity"
]
```

### <a name="input_azure_devops_jwt_bound_claims"></a> [azure\_devops\_jwt\_bound\_claims](#input\_azure\_devops\_jwt\_bound\_claims)

Description: (Optional) Additional bound claims for the Azure DevOps JWT role.

Type: `map(string)`

Default: `{}`

### <a name="input_azure_devops_jwt_bound_issuer"></a> [azure\_devops\_jwt\_bound\_issuer](#input\_azure\_devops\_jwt\_bound\_issuer)

Description: (Optional) Expected issuer claim for the Azure DevOps OIDC tokens.

Type: `string`

Default: `"https://vstoken.dev.azure.com"`

### <a name="input_azure_devops_jwt_discovery_url"></a> [azure\_devops\_jwt\_discovery\_url](#input\_azure\_devops\_jwt\_discovery\_url)

Description: (Optional) OIDC discovery URL used by Vault to validate Azure DevOps tokens.

Type: `string`

Default: `"https://vstoken.dev.azure.com"`

### <a name="input_azure_devops_jwt_role_name"></a> [azure\_devops\_jwt\_role\_name](#input\_azure\_devops\_jwt\_role\_name)

Description: (Optional) Vault JWT role name for the Azure DevOps pipeline login.

Type: `string`

Default: `"jwt_azure_devops_role"`

### <a name="input_azure_devops_jwt_token_max_ttl"></a> [azure\_devops\_jwt\_token\_max\_ttl](#input\_azure\_devops\_jwt\_token\_max\_ttl)

Description: (Optional) Maximum lifetime in seconds for Vault tokens issued to Azure DevOps JWT logins.

Type: `number`

Default: `600`

### <a name="input_azure_devops_jwt_token_ttl"></a> [azure\_devops\_jwt\_token\_ttl](#input\_azure\_devops\_jwt\_token\_ttl)

Description: (Optional) Default lifetime in seconds for Vault tokens issued to Azure DevOps JWT logins.

Type: `number`

Default: `300`

### <a name="input_azure_devops_jwt_user_claim"></a> [azure\_devops\_jwt\_user\_claim](#input\_azure\_devops\_jwt\_user\_claim)

Description: (Optional) JWT claim used as user identity in the Vault Azure DevOps JWT role.

Type: `string`

Default: `"sub"`

### <a name="input_azure_devops_pipeline_branch_name"></a> [azure\_devops\_pipeline\_branch\_name](#input\_azure\_devops\_pipeline\_branch\_name)

Description: (Optional) Branch used by the Azure DevOps pipeline definition. Leave empty to use the repository default branch for Azure Repos Git or `main` for GitHub.

Type: `string`

Default: `""`

### <a name="input_azure_devops_pipeline_folder"></a> [azure\_devops\_pipeline\_folder](#input\_azure\_devops\_pipeline\_folder)

Description: (Optional) Azure DevOps pipeline folder path. Use `\` for the root folder.

Type: `string`

Default: `"\\"`

### <a name="input_azure_devops_pipeline_name"></a> [azure\_devops\_pipeline\_name](#input\_azure\_devops\_pipeline\_name)

Description: (Optional) Name of the Azure DevOps pipeline created by Terraform.

Type: `string`

Default: `"vault-pki-renewal"`

### <a name="input_azure_devops_pipeline_yaml_path"></a> [azure\_devops\_pipeline\_yaml\_path](#input\_azure\_devops\_pipeline\_yaml\_path)

Description: (Optional) Path to the Azure Pipelines YAML file in the source repository.

Type: `string`

Default: `"azure-pipelines.yml"`

### <a name="input_azure_devops_project_name"></a> [azure\_devops\_project\_name](#input\_azure\_devops\_project\_name)

Description: (Optional) Azure DevOps project name where the pipeline will be created. Leave empty to skip Azure DevOps pipeline creation.

Type: `string`

Default: `""`

### <a name="input_azure_devops_repository_id"></a> [azure\_devops\_repository\_id](#input\_azure\_devops\_repository\_id)

Description: (Optional) Repository identifier used by Azure DevOps pipeline creation for external repositories. For GitHub, use `<owner>/<repo>`. Leave empty when `azure_devops_repository_type` is `TfsGit`.

Type: `string`

Default: `""`

### <a name="input_azure_devops_repository_name"></a> [azure\_devops\_repository\_name](#input\_azure\_devops\_repository\_name)

Description: (Optional) Azure Repos Git repository name used when `azure_devops_repository_type` is `TfsGit`.

Type: `string`

Default: `""`

### <a name="input_azure_devops_repository_service_connection_id"></a> [azure\_devops\_repository\_service\_connection\_id](#input\_azure\_devops\_repository\_service\_connection\_id)

Description: (Optional) Azure DevOps service connection ID for external repositories such as GitHub. Leave empty for `TfsGit`.

Type: `string`

Default: `""`

### <a name="input_azure_devops_repository_type"></a> [azure\_devops\_repository\_type](#input\_azure\_devops\_repository\_type)

Description: (Optional) Repository type used by the Azure DevOps pipeline definition. Supported values are `GitHub`, `GitHubEnterprise`, and `TfsGit`.

Type: `string`

Default: `"GitHub"`

### <a name="input_bootstrap_pfx_password_create_kv_mount"></a> [bootstrap\_pfx\_password\_create\_kv\_mount](#input\_bootstrap\_pfx\_password\_create\_kv\_mount)

Description: (Optional) When true, Terraform creates the KVv2 mount for bootstrap PFX password storage; set false when the mount already exists or mount management is not permitted.

Type: `bool`

Default: `false`

### <a name="input_bootstrap_pfx_password_kv_mount"></a> [bootstrap\_pfx\_password\_kv\_mount](#input\_bootstrap\_pfx\_password\_kv\_mount)

Description: (Optional) Vault KVv2 mount path where the generated bootstrap PFX password is stored.

Type: `string`

Default: `"kvv2_azure_devops"`

### <a name="input_bootstrap_pfx_password_kv_path"></a> [bootstrap\_pfx\_password\_kv\_path](#input\_bootstrap\_pfx\_password\_kv\_path)

Description: (Optional) Vault KVv2 secret path where the generated bootstrap PFX password is stored.

Type: `string`

Default: `"azure-vaultpki-renewal/bootstrap"`

### <a name="input_bootstrap_pfx_password_store_in_vault"></a> [bootstrap\_pfx\_password\_store\_in\_vault](#input\_bootstrap\_pfx\_password\_store\_in\_vault)

Description: (Optional) When true, Terraform writes the generated bootstrap PFX password into Vault KVv2. Defaults to false so least-privilege Vault configurations do not require KV write access unless explicitly enabled.

Type: `bool`

Default: `false`

### <a name="input_enable_azure_devops_jwt_auth"></a> [enable\_azure\_devops\_jwt\_auth](#input\_enable\_azure\_devops\_jwt\_auth)

Description: (Optional) When true, creates the Vault JWT role and policy for Azure DevOps pipeline authentication.

Type: `bool`

Default: `true`

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

### <a name="input_location"></a> [location](#input\_location)

Description: (Optional) Azure region where the demo resources are deployed.

Type: `string`

Default: `"canadacentral"`

### <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix)

Description: (Optional) Prefix used for Azure resource naming.

Type: `string`

Default: `"vault-pki"`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: (Optional) Resource group name for all demo resources.

Type: `string`

Default: `"rg-vault-pki-renewal"`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: (Optional) Tags applied to Azure resources.

Type: `map(string)`

Default: `{}`

### <a name="input_vault_namespace"></a> [vault\_namespace](#input\_vault\_namespace)

Description: (Optional) Vault namespace injected into the generated Azure DevOps pipeline file.

Type: `string`

Default: `""`

### <a name="input_vault_pki_path"></a> [vault\_pki\_path](#input\_vault\_pki\_path)

Description: (Optional) Vault PKI mount path used for certificate issuance.

Type: `string`

Default: `"pki-int"`

### <a name="input_vault_pki_role"></a> [vault\_pki\_role](#input\_vault\_pki\_role)

Description: (Optional) Vault PKI role used for certificate issuance.

Type: `string`

Default: `"gw-cert-issuer"`

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

- [azuredevops_build_definition.certificate_renewal](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/build_definition) (resource)
- [azurerm_application_gateway.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway) (resource)
- [azurerm_key_vault.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) (resource)
- [azurerm_key_vault_access_policy.app_gateway_identity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy) (resource)
- [azurerm_key_vault_access_policy.terraform_identity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy) (resource)
- [azurerm_key_vault_certificate.bootstrap](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_certificate) (resource)
- [azurerm_public_ip.app_gateway](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_subnet.app_gateway](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_user_assigned_identity.app_gateway](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) (resource)
- [azurerm_virtual_network.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
- [random_password.bootstrap_pfx_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) (resource)
- [vault_jwt_auth_backend.workload](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/jwt_auth_backend) (resource)
- [vault_jwt_auth_backend_role.workload](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/jwt_auth_backend_role) (resource)
- [vault_kv_secret_v2.bootstrap_pfx_password](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kv_secret_v2) (resource)
- [vault_mount.bootstrap_pfx_password_kvv2](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/mount) (resource)
- [vault_pki_secret_backend_cert.bootstrap](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/pki_secret_backend_cert) (resource)
- [vault_pki_secret_backend_role.bootstrap](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/pki_secret_backend_role) (resource)
- [vault_policy.workload_pki_issue](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) (resource)
- [azuredevops_git_repository.pipeline_repository](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/data-sources/git_repository) (data source)
- [azuredevops_project.pipeline_project](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/data-sources/project) (data source)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)

## Outputs

The following outputs are exported:

### <a name="output_application_gateway_name"></a> [application\_gateway\_name](#output\_application\_gateway\_name)

Description: Application Gateway name receiving TLS certificate updates from Key Vault

### <a name="output_application_gateway_public_ip"></a> [application\_gateway\_public\_ip](#output\_application\_gateway\_public\_ip)

Description: Public IP address of the Application Gateway

### <a name="output_azure_devops_pipeline_id"></a> [azure\_devops\_pipeline\_id](#output\_azure\_devops\_pipeline\_id)

Description: Azure DevOps build definition ID for the certificate renewal pipeline. Null when pipeline creation is not configured.

### <a name="output_azure_devops_pipeline_name"></a> [azure\_devops\_pipeline\_name](#output\_azure\_devops\_pipeline\_name)

Description: Azure DevOps pipeline name for the certificate renewal pipeline. Null when pipeline creation is not configured.

### <a name="output_key_vault_certificate_name"></a> [key\_vault\_certificate\_name](#output\_key\_vault\_certificate\_name)

Description: Certificate name in Azure Key Vault updated by the renewal automation

### <a name="output_key_vault_name"></a> [key\_vault\_name](#output\_key\_vault\_name)

Description: Azure Key Vault name storing the TLS certificate

### <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name)

Description: Resource group that contains the demo resources

### <a name="output_vault_azure_devops_jwt_backend_path"></a> [vault\_azure\_devops\_jwt\_backend\_path](#output\_vault\_azure\_devops\_jwt\_backend\_path)

Description: Vault JWT/OIDC auth backend path for Azure DevOps pipeline logins

### <a name="output_vault_azure_devops_jwt_role_name"></a> [vault\_azure\_devops\_jwt\_role\_name](#output\_vault\_azure\_devops\_jwt\_role\_name)

Description: Vault JWT role name for Azure DevOps pipeline logins. Null when disabled.

### <a name="output_vault_bootstrap_pfx_password_kv_mount"></a> [vault\_bootstrap\_pfx\_password\_kv\_mount](#output\_vault\_bootstrap\_pfx\_password\_kv\_mount)

Description: Vault KVv2 mount used for generated bootstrap PFX password storage

### <a name="output_vault_bootstrap_pfx_password_secret_path"></a> [vault\_bootstrap\_pfx\_password\_secret\_path](#output\_vault\_bootstrap\_pfx\_password\_secret\_path)

Description: Vault KVv2 secret path storing generated bootstrap PFX password

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
