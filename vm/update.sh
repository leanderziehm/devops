#!/usr/bin/env bash
set -euo pipefail
# Load environment variables
source "$(dirname "${BASH_SOURCE[0]}")/environment.sh"

bash $NOTIFY_SCRIPT "$(hostname): update using update.sh as user $(whoami)"

git -C /opt/lz/devops pull

# todo maybe detech if there where any changes in git and if so then deploy only on changes 

# setup systemd
sudo cp /opt/lz/devops/vm/systemd/devops-update.service /etc/systemd/system/
sudo cp /opt/lz/devops/vm/systemd/devops-update.timer /etc/systemd/system/
sudo cp /opt/lz/devops/vm/systemd/on-startup.service /etc/systemd/system/
sudo chmod +x /opt/lz/devops/vm/update.sh
sudo chmod +x /opt/lz/devops/vm/on-startup.sh

sudo systemctl daemon-reload
sudo systemctl enable --now devops-update.timer

### CONTAINERS:

# --------------------------------------------------
# LOAD VM CONFIGURATION
# --------------------------------------------------

source "$SCRIPT_DIR/vms.conf"


VM_NAME=$(hostname)

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

for container in $CONTAINERS; do

    KUBE_FILE="$VMS_DIR/containers/$container/$container.kube"

    if [[ ! -f "$KUBE_FILE" ]]; then
        bash "$NOTIFY_SCRIPT" --echo --log "Missing Quadlet file: $KUBE_FILE"
        exit 1
    fi

    bash "$NOTIFY_SCRIPT" --echo --log "Installing Quadlet unit: $container cp $KUBE_FILE -> $QUADLET_DIR/$container.kube"

    cp "$KUBE_FILE" "$QUADLET_DIR/$container.kube"

done

# does this need to run every 5 minues or no?
USER_ID=$(id -u "$USER")
sudo systemctl start "user@${USER_ID}.service"
bash "$NOTIFY_SCRIPT" --echo --log "$(hostname): sudo systemctl start user@${USER_ID}.service"

export XDG_RUNTIME_DIR="/run/user/${USER_ID}"
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
echo "DBUS_SESSION_BUS_ADDRESS: $DBUS_SESSION_BUS_ADDRESS"
echo "XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"

systemctl --user daemon-reload

# --------------------------------------------------
# START CONTAINERS
# --------------------------------------------------

for container in $CONTAINERS; do
    bash "$NOTIFY_SCRIPT" --echo --log "Starting $container.service:  systemctl --user start $container.service"
    
    systemctl --user start "$container.service"
done

bash "$NOTIFY_SCRIPT" "All workloads deployed successfully"
