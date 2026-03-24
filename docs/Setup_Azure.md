# Azure Setup for HCP Terraform Agent with Managed Identity

This guide creates an Azure Linux VM, installs the HCP Terraform Agent, and uses a User Assigned Managed Identity (UAMI) so Terraform
runs can provision Azure resources without an SPN secret.

## Architecture

1. A Linux VM runs the HCP Terraform Agent.
2. The VM is assigned a UAMI.
3. HCP Terraform workspace runs in **Agent** execution mode.
4. AzureRM provider authenticates through MSI using workspace environment variables.

## Prerequisites

- Azure subscription where infrastructure will be created
- Permission to create resource groups, managed identities, VMs, and role assignments
- HCP Terraform organization and workspace
- Existing HCP Terraform Agent Pool and agent token
- Azure CLI access (Cloud Shell or local shell)

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
az account set --subscription $SUBSCRIPTION_ID

# Register required resource providers (one-time per subscription).
az provider register --namespace Microsoft.Automation --subscription "$SUBSCRIPTION_ID"
az provider register --namespace Microsoft.KeyVault --subscription "$SUBSCRIPTION_ID"

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

## 4) Assign Azure RBAC to the Managed Identity

To allow Terraform to create role assignments (for example, granting the Automation account access to the App Gateway), the identity
running Terraform must have either `Owner` or `User Access Administrator` at the target scope. `Contributor` alone is not enough for
role assignment writes.

For broad testing, assign `Contributor` plus `User Access Administrator`:

```bash
az role assignment create \
  --assignee-object-id "$UAMI_PRINCIPAL_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

az role assignment create \
  --assignee-object-id "$UAMI_PRINCIPAL_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "User Access Administrator" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"
```

## 5) Create Linux VM and Attach UAMI

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

### 6a) Disable Agent Auto-Update (Optional)

Check supported update behavior values on the VM, then set one of those values in the agent environment file.

```bash
ssh -t "$ADMIN_USER@$VM_PUBLIC_IP" "sudo /usr/local/bin/tfc-agent -h"
```

Then update the config (replace `<AUTO_UPDATE>` with a supported value like `disabled`, `patch`, or `minor`):

```bash
ssh -t "$ADMIN_USER@$VM_PUBLIC_IP" "sudo sed -i '/TFC_AGENT_AUTO_UPDATE/d' /etc/tfc-agent.d/agent.env && echo 'TFC_AGENT_AUTO_UPDATE=<AUTO_UPDATE>' | sudo tee -a /etc/tfc-agent.d/agent.env >/dev/null && sudo systemctl restart tfc-agent"
```

## 7) Configure HCP Terraform Workspace

In HCP Terraform workspace settings:

1. Set **Execution Mode** to **Agent**.
2. Select your Agent Pool.
3. Add these environment variables:

```bash
ARM_USE_MSI=true
ARM_CLIENT_ID=<UAMI_CLIENT_ID>
ARM_SUBSCRIPTION_ID=<SUBSCRIPTION_ID>
ARM_TENANT_ID=<TENANT_ID>
ARM_ENVIRONMENT=public
```

## 8) Validation

### Validate Agent Registration

- HCP Terraform UI should show the agent as healthy in the selected pool.

### Validate Agent Service on VM

```bash
ssh "$ADMIN_USER@$VM_PUBLIC_IP" "sudo journalctl -u tfc-agent -n 200 --no-pager"
```

### Agent Health Checks

```bash
ssh -t "$ADMIN_USER@$VM_PUBLIC_IP" "sudo systemctl status tfc-agent --no-pager"
ssh -t "$ADMIN_USER@$VM_PUBLIC_IP" "sudo systemctl show tfc-agent -p User -p Group -p ExecStart"
```

Tail logs live:

```bash
ssh -t "$ADMIN_USER@$VM_PUBLIC_IP" "sudo journalctl -u tfc-agent -f --no-pager"
```

### Prevent Run Directory Permission Errors (Optional)

If you see teardown warnings about failing to remove files under the run directory, install a small systemd path/service to keep
permissions writable.

```bash
ssh -t "$ADMIN_USER@$VM_PUBLIC_IP" "sudo tee /usr/local/bin/tfc-agent-fix-perms.sh >/dev/null <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
chmod -R u+rwx /opt/tfc-agent/.tfc-agent/component/terraform/runs || true
EOF
sudo chmod +x /usr/local/bin/tfc-agent-fix-perms.sh

sudo tee /etc/systemd/system/tfc-agent-fix-perms.service >/dev/null <<'EOF'
[Unit]
Description=Fix tfc-agent run dir permissions

[Service]
Type=oneshot
ExecStart=/usr/local/bin/tfc-agent-fix-perms.sh
EOF

sudo tee /etc/systemd/system/tfc-agent-fix-perms.path >/dev/null <<'EOF'
[Unit]
Description=Watch for tfc-agent run dirs

[Path]
PathChanged=/opt/tfc-agent/.tfc-agent/component/terraform/runs

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now tfc-agent-fix-perms.path
"
```
