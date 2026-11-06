#!/usr/bin/env bash

set -euo pipefail

HOSTNAME="$(hostname)"

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <service>"
    echo "Example: $0 immich"
    exit 1
fi

SERVICE="$1"
SERVICE_PATH="vps/$HOSTNAME/$SERVICE"
cd $SERVICE_PATH

SCRIPT="start.sh"

if [[ ! -f "$SCRIPT" ]]; then
    echo "Service script not found: $SCRIPT"
    exit 1
fi

bash $SCRIPT