#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ENVIRONMENT="${ENVIRONMENT:-}"

if [[ -z "$ENVIRONMENT" ]]; then
    if [[ "$SCRIPT_DIR" == "/opt/lz/devops/vms" ]]; then
        ENVIRONMENT="prod"
    else
        ENVIRONMENT="dev"
    fi
fi

case "$ENVIRONMENT" in
    prod)
        VMS_DIR="/opt/lz/devops/vms"
        VM_NAME="$(hostname -s)"
        ;;
    dev)
        VMS_DIR="$SCRIPT_DIR"
        VM_NAME="${VM_NAME:-alma-vm1}"
        ;;
    *)
        echo "Unknown environment: $ENVIRONMENT"
        return 1 2>/dev/null || exit 1
        ;;
esac

VM_DIR="$VMS_DIR/$VM_NAME"
REPO="$(dirname "$VMS_DIR")"
NOTIFY_SCRIPT="$REPO/scripts/notify.sh"
UPDATE_SCRIPT="$REPO/vms/update/update.sh"

echo "ENVIRONMENT: $ENVIRONMENT"
echo "VM_NAME: $VM_NAME"
echo "REPO: $REPO"
echo "VMS_DIR: $VMS_DIR"
echo "VM_DIR: $VM_DIR"

export ENVIRONMENT VM_NAME REPO VMS_DIR VM_DIR NOTIFY_SCRIPT UPDATE_SCRIPT

bash $NOTIFY_SCRIPT --echo --log "Environment Loaded on $(hostname -s): $ENVIRONMENT $VM_NAME"