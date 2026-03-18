# Azure Setup for HCP Terraform Agent with Managed Identity

This guide creates an Azure Linux VM, installs the HCP Terraform Agent, and uses a User Assigned Managed Identity (UAMI) so Terraform
runs can provision Azure resources without an SPN secret.

## Prerequisites

- Azure Cloud Shell (Bash)
- Access to the target Azure subscription
- HCP Terraform organization and workspace
- HCP Terraform Agent Pool already created
- Agent Pool Token generated from HCP Terraform

## 1) Define Variables

Run in Azure Cloud Shell:

```bash
# Required values
export SUBSCRIPTION_ID="<PASTE_SUBSCRIPTION_ID>"
export LOCATION="canadacentral"
export RG_NAME="rg-hcp-agent-demo"
export VM_NAME="vm-hcp-agent-01"
export UAMI_NAME="id-hcp-agent-uami"
export ADMIN_USER="azureuser"

# Paste the token from HCP Terraform -> Agent Pool -> Create Token
export TFC_AGENT_TOKEN="<PASTE_AGENT_POOL_TOKEN>"

# Update if you prefer another release
export TFC_AGENT_VERSION="1.19.0"
```

## 2) Select Subscription and Create Base Resources

```bash
az account set --subscription "$SUBSCRIPTION_ID"

az group create \
  --name "$RG_NAME" \
  --location "$LOCATION"

az identity create \
  --name "$UAMI_NAME" \
  --resource-group "$RG_NAME" \
  --location "$LOCATION"
```

## 3) Capture Managed Identity and Tenant Attributes

```bash
export UAMI_ID=$(az identity show -g "$RG_NAME" -n "$UAMI_NAME" --query id -o tsv)
export UAMI_CLIENT_ID=$(az identity show -g "$RG_NAME" -n "$UAMI_NAME" --query clientId -o tsv)
export UAMI_PRINCIPAL_ID=$(az identity show -g "$RG_NAME" -n "$UAMI_NAME" --query principalId -o tsv)
export TENANT_ID=$(az account show --query tenantId -o tsv)
```

## 4) Assign RBAC to Managed Identity

Use least privilege for your scope. For demo simplicity, Contributor on the resource group:

```bash
az role assignment create \
  --assignee-object-id "$UAMI_PRINCIPAL_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME"
```

Grant your HCP Terraform agent identity enough scope to create/read the demo resource group and its resources.

```bash
# Use your actual agent principal object ID (from step 3) and subscription
az role assignment create \
  --assignee-object-id "$UAMI_PRINCIPAL_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"
```

Optional (only if Terraform must manage role assignments itself):

```bash
# az role assignment create \
#   --assignee-object-id "$UAMI_PRINCIPAL_ID" \
#   --assignee-principal-type ServicePrincipal \
#   --role "User Access Administrator" \
#   --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME"
```

## 5) Create Linux VM and Attach UAMI

This setup uses an approved base image from your image-factory subscription (`hashicorp02-image-factory-prod`).

Set your approved image definition ID (Azure Compute Gallery):

```bash
export IMAGE_DEFINITION_ID="<PASTE_IMAGE_DEFINITION_ID>"
```

Resolve the latest version from that definition:

```bash
# Parse fields from IMAGE_DEFINITION_ID
export IMAGE_GALLERY_RG=$(echo "$IMAGE_DEFINITION_ID" | awk -F/ '{for(i=1;i<=NF;i++) if($i=="resourceGroups") print $(i+1)}')
export IMAGE_GALLERY_NAME=$(echo "$IMAGE_DEFINITION_ID" | awk -F/ '{for(i=1;i<=NF;i++) if($i=="galleries") print $(i+1)}')
export IMAGE_DEFINITION_NAME=$(echo "$IMAGE_DEFINITION_ID" | awk -F/ '{for(i=1;i<=NF;i++) if($i=="images") print $(i+1)}')

export IMAGE_VERSION=$(az sig image-version list \
  --subscription "338f0fa5-b5ae-4847-9821-1808613db6c5" \
  --resource-group "$IMAGE_GALLERY_RG" \
  --gallery-name "$IMAGE_GALLERY_NAME" \
  --gallery-image-definition "$IMAGE_DEFINITION_NAME" \
  --query "[].name" -o tsv | sort -V | tail -n 1)

export IMAGE_ID="${IMAGE_DEFINITION_ID}/versions/${IMAGE_VERSION}"
echo "$IMAGE_ID"
```

Optional: verify selected image version is available in your target region:

```bash
az sig image-version show \
  --ids "$IMAGE_ID" \
  --query "publishingProfile.targetRegions[].name" \
  -o tsv
```

First pick an available VM size in your target region:

```bash
az vm list-skus \
  --location "$LOCATION" \
  --all \
  --resource-type virtualMachines \
  --query "[].name" \
  -o tsv | sort -u | grep -E '^Standard_(B|D|E)[0-9]'
```

Set one of the returned sizes (example below):

```bash
export VM_SIZE="Standard_D2s_v5"
```

Create the VM:

```bash
az vm create \
  --resource-group "$RG_NAME" \
  --name "$VM_NAME" \
  --image "${IMAGE_ID}" \
  --size "$VM_SIZE" \
  --admin-username "$ADMIN_USER" \
  --generate-ssh-keys \
  --assign-identity "$UAMI_ID"
```

If capacity is still constrained, retry with another value from `az vm list-skus`.

## 6) Install and Configure HCP Terraform Agent on VM

```bash
export VM_PUBLIC_IP=$(az vm show -d -g "$RG_NAME" -n "$VM_NAME" --query publicIps -o tsv)
echo "VM Public IP: $VM_PUBLIC_IP"

ssh -o StrictHostKeyChecking=accept-new "$ADMIN_USER@$VM_PUBLIC_IP" <<EOF
set -euo pipefail

sudo apt-get update
sudo apt-get install -y unzip curl ca-certificates

sudo useradd --system --create-home --home-dir /opt/tfc-agent --shell /usr/sbin/nologin tfc-agent || true

cd /tmp
curl -fsSLO "https://releases.hashicorp.com/tfc-agent/${TFC_AGENT_VERSION}/tfc-agent_${TFC_AGENT_VERSION}_linux_amd64.zip"
unzip -o "tfc-agent_${TFC_AGENT_VERSION}_linux_amd64.zip"
sudo install -m 0755 tfc-agent /usr/local/bin/tfc-agent
sudo install -m 0755 tfc-agent-core /usr/local/bin/tfc-agent-core

test -x /usr/local/bin/tfc-agent
test -x /usr/local/bin/tfc-agent-core

sudo mkdir -p /etc/tfc-agent.d /var/lib/tfc-agent
sudo chown -R tfc-agent:tfc-agent /var/lib/tfc-agent

sudo tee /etc/tfc-agent.d/agent.env >/dev/null <<ENVVARS
TFC_AGENT_TOKEN=${TFC_AGENT_TOKEN}
TFC_AGENT_NAME=${VM_NAME}
TFC_ADDRESS=https://app.terraform.io
TFC_AGENT_LOG_LEVEL=info
ENVVARS

sudo chmod 600 /etc/tfc-agent.d/agent.env
sudo chown root:root /etc/tfc-agent.d/agent.env

sudo tee /etc/systemd/system/tfc-agent.service >/dev/null <<SERVICE
[Unit]
Description=HCP Terraform Agent
After=network-online.target
Wants=network-online.target

[Service]
User=tfc-agent
Group=tfc-agent
EnvironmentFile=/etc/tfc-agent.d/agent.env
WorkingDirectory=/var/lib/tfc-agent
ExecStart=/usr/local/bin/tfc-agent
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

sudo systemctl daemon-reload
sudo systemctl enable --now tfc-agent
sudo systemctl status tfc-agent --no-pager
EOF
```

## 7) Configure HCP Terraform Workspace

In HCP Terraform:

1. Set workspace **Execution Mode** to **Agent**.
2. Select your agent pool.
3. Add these environment variables in the workspace:

```bash
ARM_USE_MSI=true
ARM_CLIENT_ID=<UAMI_CLIENT_ID>
ARM_SUBSCRIPTION_ID=<SUBSCRIPTION_ID>
ARM_TENANT_ID=<TENANT_ID>
ARM_ENVIRONMENT=public
```

If this workspace also needs Vault provider access using HCP Terraform dynamic credentials (JWT/OIDC), add:

```bash
TFC_VAULT_PROVIDER_AUTH=true
TFC_VAULT_ADDR=<vault-cluster-url>
TFC_VAULT_NAMESPACE=<namespace_path>
TFC_VAULT_RUN_ROLE=<role_name>
```

Use outputs from your `HCPVault-PKI` deployment:

- `pki_intermediate_namespace_path`
- `jwt_hcp_role_name_azure`

Note: `azure_auth_backend_path` is for Azure DevOps JWT/OIDC backend. `TFC_VAULT_RUN_ROLE` for HCP Terraform workspace runs should use
the HCP JWT role output.

## 8) Validation

### Validate Agent Registration

- HCP Terraform UI should show the agent as healthy in the selected pool.

### Validate Agent Service on VM

```bash
ssh "$ADMIN_USER@$VM_PUBLIC_IP" "sudo journalctl -u tfc-agent -n 200 --no-pager"
```

### Validate Managed Identity Access

From an agent-based Terraform run, verify provider authentication succeeds without SPN secret variables.

## Security Notes

- Treat `TFC_AGENT_TOKEN` as sensitive and rotate it regularly.
- Prefer private networking, NSGs, and no public IP for production.
- Scope RBAC permissions to least privilege.
- Use sensitive workspace variables for secrets.
- Ensure the identity creating the VM has read access to the selected Shared Image Gallery image version in the image-factory subscription.
