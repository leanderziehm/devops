#!/usr/bin/env bash
# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REPO="/opt/lz/devops/"
VMS_DIR="/opt/lz/devops/vm"
NOTIFY_SCRIPT="/opt/lz/devops/scripts/notify.sh"
UPDATE_SCRIPT="/opt/lz/devops/vm/update.sh"

echo "REPO: $REPO"
echo "VMS_DIR: $VMS_DIR"

export REPO VMS_DIR NOTIFY_SCRIPT UPDATE_SCRIPT

bash "$NOTIFY_SCRIPT" --echo --log "$(hostname -s): Environment Loaded"