#!/usr/bin/env bash
set -euo pipefail
# Load environment variables
source "$(dirname "${BASH_SOURCE[0]}")/environment.sh"
echo "Running setup.sh for $VM_NAME"
bash $NOTIFY_SCRIPT "setting up vm using devops setup.sh"

bash "$VM_DIR/run.sh"

# TODO: automatic updating, systemd timer

# this script gets called after cloud-init for a new vm of mine. cloud init clones this repo and runs this script then it should take over and be like ansible or k8s but light. i want podman and notification autiomation and such and check update 
# aproach: infrastructure as code from a git repo and secureity pull based design and decuple. so admin pushes changes to repo and each vm that is running check every 5 min if new changes in git repo if yes pull and apply not sure how to best do apply but thats a todo
# tools: git, podman, systemd, curl, firewalld.
# os: linux usually rhel based so rocky, alma, fedora but can be debian or others
# systemctl daemon-reload
# systemctl enable --now devops-update.timer