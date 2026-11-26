#!/usr/bin/env bash
set -euo pipefail
# Load environment variables
source "$(dirname "${BASH_SOURCE[0]}")/environment.sh"

bash $NOTIFY_SCRIPT "$(hostname): on startup as user $(whoami)  ip: $(hostname -I)"
