#!/usr/bin/env bash
set -euo pipefail
# Load environment variables
source "$(dirname "${BASH_SOURCE[0]}")/environment.sh"


bash $NOTIFY_SCRIPT "setting up vm using devops setup.sh"
loginctl enable-linger "$USER"
echo "enable linger"
bash $NOTIFY_SCRIPT "setting up update.sh as user $(whoami)"
bash $UPDATE_SCRIPT

# tools: firewalld.
# os: linux usually rhel based so rocky, alma, fedora but can be debian or others
