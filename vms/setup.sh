#!/usr/bin/env bash
set -euo pipefail
# Load environment variables
source "$(dirname "${BASH_SOURCE[0]}")/environment.sh"

bash $NOTIFY_SCRIPT "setting up vm using devops setup.sh"

bash $NOTIFY_SCRIPT "setting up update.sh as user $(whoami)"
bash $UPDATE_SCRIPT

sudo cp /opt/lz/devops/vms/update/devops-update.service /etc/systemd/system/
sudo cp /opt/lz/devops/vms/update/devops-update.timer /etc/systemd/system/
sudo chmod +x /opt/lz/devops/vms/update/update.sh

sudo systemctl daemon-reload
sudo systemctl enable --now devops-update.timer

### CONTAINERS:

# --------------------------------------------------
# LOAD VM CONFIGURATION
# --------------------------------------------------

source "$SCRIPT_DIR/vms.conf"


VM_NAME = $(hostname)

# Get containers for current VM, otherwise fallback
CONTAINERS="${VM_CONTAINERS[$VM_NAME]:-${VM_CONTAINERS[fallback]:-}}"

if [[ -z "$CONTAINERS" ]]; then
    bash "$NOTIFY_SCRIPT" --echo --log "No containers configured for $VM_NAME"
    exit 0
fi

bash "$NOTIFY_SCRIPT" "Deploying containers for $VM_NAME: $CONTAINERS"
# --------------------------------------------------
# INSTALL QUADLET FILES
# --------------------------------------------------

QUADLET_DIR="$HOME/.config/containers/systemd"
mkdir -p "$QUADLET_DIR"

export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"

for container in $CONTAINERS; do

    KUBE_FILE="$VMS_DIR/containers/$container/$container.kube"

    if [[ ! -f "$KUBE_FILE" ]]; then
        bash "$NOTIFY_SCRIPT" --echo --log "Missing Quadlet file: $KUBE_FILE"
        exit 1
    fi

    bash "$NOTIFY_SCRIPT" --echo --log "Installing Quadlet unit: $container"

    cp "$KUBE_FILE" "$QUADLET_DIR/$container.kube"

done

systemctl --user daemon-reload

# --------------------------------------------------
# START CONTAINERS
# --------------------------------------------------

for container in $CONTAINERS; do
    bash "$NOTIFY_SCRIPT" --echo --log "Starting $container.service"
    systemctl --user enable --now "$container.service"
done

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