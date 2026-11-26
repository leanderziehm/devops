#!/usr/bin/env bash
set -euo pipefail

# --------------------------------------------------
# CONFIGURATION
# --------------------------------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/environment.sh"

ADMIN_USER="admin"
PODMAN_USER="podmanager"

REPO="/opt/lz/devops"

# This script requires root for system-level operations.
if [[ $EUID -ne 0 ]]; then
    echo "Please run with sudo: sudo $0"
    exit 1
fi

ADMIN_HOME="$(getent passwd "$ADMIN_USER" | cut -d: -f6)"
PODMAN_HOME="$(getent passwd "$PODMAN_USER" | cut -d: -f6)"

if [[ -z "$ADMIN_HOME" || -z "$PODMAN_HOME" ]]; then
    echo "Required user does not exist"
    exit 1
fi

PODMAN_UID="$(id -u "$PODMAN_USER")"
PODMAN_GID="$(id -g "$PODMAN_USER")"

PODMAN_RUNTIME="/run/user/$PODMAN_UID"

# --------------------------------------------------
# HELPER FUNCTIONS
# --------------------------------------------------

notify() {
    bash "$NOTIFY_SCRIPT" "$(hostname): $@ as user $(whoami)"
}

run_podmanager() {
    sudo -u "$PODMAN_USER" \
        env \
        HOME="$PODMAN_HOME" \
        USER="$PODMAN_USER" \
        LOGNAME="$PODMAN_USER" \
        XDG_RUNTIME_DIR="$PODMAN_RUNTIME" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=$PODMAN_RUNTIME/bus" \
        "$@"
}

# --------------------------------------------------
# NOTIFY
# --------------------------------------------------

notify "update using update.sh"

# --------------------------------------------------
# UPDATE GIT REPOSITORY AS ADMIN
# --------------------------------------------------

notify "Updating DevOps repository..."

sudo -u "$ADMIN_USER" -H \
    git -C "$REPO" pull --ff-only

# --------------------------------------------------
# INSTALL SYSTEMD FILES
# --------------------------------------------------

SYSTEMD_SOURCE="$REPO/vm/systemd"

install -m 0644 \
    "$SYSTEMD_SOURCE/devops-update.service" \
    /etc/systemd/system/

install -m 0644 \
    "$SYSTEMD_SOURCE/devops-update.timer" \
    /etc/systemd/system/

install -m 0644 \
    "$SYSTEMD_SOURCE/on-startup.service" \
    /etc/systemd/system/

chmod +x "$REPO/vm/update.sh"
chmod +x "$REPO/vm/on-startup.sh"

systemctl daemon-reload
systemctl enable --now devops-update.timer

# --------------------------------------------------
# LOAD VM CONFIGURATION
# --------------------------------------------------

source "$SCRIPT_DIR/vms.conf"

VM_NAME="$(hostname)"

CONTAINERS="${VM_CONTAINERS[$VM_NAME]:-${VM_CONTAINERS[fallback]:-}}"

if [[ -z "$CONTAINERS" ]]; then
    notify --echo --log "No containers configured for $VM_NAME"
    exit 0
fi

notify "Deploying containers for $VM_NAME: $CONTAINERS"

# --------------------------------------------------
# PREPARE ROOTLESS PODMAN USER
# --------------------------------------------------

loginctl enable-linger "$PODMAN_USER"

# Start the user systemd manager.
systemctl start "user@${PODMAN_UID}.service"

# Ensure runtime directory exists.
if [[ ! -d "$PODMAN_RUNTIME" ]]; then
    notify --echo --log "User runtime directory missing: $PODMAN_RUNTIME"
    exit 1
fi

# Prepare Quadlet directory.
# Ensure the complete configuration directory hierarchy belongs to podmanager.
install -d \
    -o "$PODMAN_USER" \
    -g "$PODMAN_USER" \
    -m 0755 \
    "$PODMAN_HOME/.config/containers/systemd"

chown "$PODMAN_USER:$PODMAN_USER" "$PODMAN_HOME/.config"
chown "$PODMAN_USER:$PODMAN_USER" "$PODMAN_HOME/.config/containers"

QUADLET_DIR="$PODMAN_HOME/.config/containers/systemd"
chown -R "$PODMAN_UID:$PODMAN_GID" "$QUADLET_DIR"
# --------------------------------------------------
# INSTALL QUADLET FILES
# --------------------------------------------------

declare -A CHANGED_CONTAINERS=()
CHANGED=0

for container in $CONTAINERS; do

    KUBE_FILE="$VMS_DIR/containers/$container/$container.kube"
    TARGET_FILE="$QUADLET_DIR/$container.kube"

    if [[ ! -f "$KUBE_FILE" ]]; then
        notify --echo --log "Missing Quadlet file: $KUBE_FILE"
        exit 1
    fi

    if ! cmp -s "$KUBE_FILE" "$TARGET_FILE" 2>/dev/null; then

        notify "Installing Quadlet: $container"

        install \
            -o "$PODMAN_UID" \
            -g "$PODMAN_GID" \
            -m 0644 \
            "$KUBE_FILE" \
            "$TARGET_FILE"

        CHANGED_CONTAINERS["$container"]=1
        CHANGED=1
    fi
done

# --------------------------------------------------
# RELOAD USER SYSTEMD
# --------------------------------------------------

if [[ "$CHANGED" -eq 1 ]]; then
    notify "Quadlet configuration changed. Reloading user systemd..."

    run_podmanager systemctl --user daemon-reload
else
    notify --echo --log "No Quadlet configuration changes detected"
fi

# --------------------------------------------------
# START / RESTART CONTAINERS
# --------------------------------------------------

for container in $CONTAINERS; do

    SERVICE="$container.service"

    if [[ -n "${CHANGED_CONTAINERS[$container]:-}" ]]; then

        if run_podmanager systemctl --user is-active --quiet "$SERVICE"; then
            notify "Restarting $SERVICE"
            run_podmanager systemctl --user restart "$SERVICE"
        else
            notify "Starting $SERVICE"
            run_podmanager systemctl --user start "$SERVICE"
        fi

    else

        if ! run_podmanager systemctl --user is-active --quiet "$SERVICE"; then
            notify "Starting $SERVICE"
            run_podmanager systemctl --user start "$SERVICE"
        fi

    fi

done

notify "All workloads deployed successfully"
