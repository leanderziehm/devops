#!/usr/bin/env bash
set -euo pipefail
# Load environment variables
source "$(dirname "${BASH_SOURCE[0]}")/environment.sh"

bash $NOTIFY_SCRIPT "setting up vm using devops setup.sh"

if [[ ! -d "$VM_DIR/containers" ]]; then
    bash "$NOTIFY_SCRIPT" --echo --log "No containers directory found for $VM_NAME"
    exit 1
fi

shopt -s nullglob

# 1. Ensure the Quadlet directory exists (rootless user path)
QUADLET_DIR="$HOME/.config/containers/systemd"
mkdir -p "$QUADLET_DIR"

# 2. Copy every .kube file from your repo into the Quadlet directory
KUBE_UNITS=("$VM_DIR"/containers/*/*.kube)
if [[ ${#KUBE_UNITS[@]} -eq 0 ]]; then
    bash "$NOTIFY_SCRIPT" --echo --log "No .kube unit files found"
    exit 0
fi

for kube_file in "${KUBE_UNITS[@]}"; do
    name="$(basename "$kube_file")"
    bash "$NOTIFY_SCRIPT" --echo --log "Installing Quadlet unit: $name  $kube_file $QUADLET_DIR/$name"
    cp "$kube_file" "$QUADLET_DIR/$name"
done

# 3. Reload systemd so Quadlet generates the services
systemctl --user daemon-reload

# 4. Enable and start each generated service
for kube_file in "${KUBE_UNITS[@]}"; do
    service_name="$(basename "$kube_file" .kube)"
    bash "$NOTIFY_SCRIPT" --echo --log "Start: systemctl --user start $service_name.service"
    systemctl --user start "$service_name.service"
done

# 5. CRITICAL for rootless: enable lingering so services start on boot
loginctl enable-linger "$USER"

bash "$NOTIFY_SCRIPT" "All workloads deployed successfully"

### Old:

# if [[ ! -d "$VM_DIR/containers" ]]; then
#     bash $NOTIFY_SCRIPT --echo --log "No containers directory found for $VM_NAME"
#     exit 1
# fi

# shopt -s nullglob

# DEPLOYMENTS=("$VM_DIR"/containers/*/deployment.yaml)

# if [[ ${#DEPLOYMENTS[@]} -eq 0 ]]; then
#     bash $NOTIFY_SCRIPT --echo --log "No deployments found"
#     exit 0
# fi

# for deployment in "${DEPLOYMENTS[@]}"; do
#     name="$(basename "$(dirname "$deployment")")"
#     bash $NOTIFY_SCRIPT --echo --log "Running deployment: $deployment for $VM_NAME"
#     podman kube play --replace "$deployment"
# done

# ## instead of kube play copy files over to ~/.config/containers/systemd/

# bash $NOTIFY_SCRIPT "All workloads deployed successfully"
# tools: firewalld.
# os: linux usually rhel based so rocky, alma, fedora but can be debian or others
# systemctl daemon-reload
# systemctl enable --now devops-update.timer