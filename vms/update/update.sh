#!/usr/bin/env bash
set -euo pipefail
# Load environment variables
source "$(dirname "${BASH_SOURCE[0]}")/../environment.sh"

bash $NOTIFY_SCRIPT "$(hostname): update using update.sh as user $(whoami)"

git -C /opt/lz/devops pull