#!/usr/bin/env bash
set -euo pipefail

# Load environment variables
source "$(dirname "${BASH_SOURCE[0]}")/../environment.sh"

echo "Running deployment for $VM_NAME"
bash $NOTIFY_SCRIPT "Running deployment for $VM_NAME"

if [[ ! -d "$VM_DIR/containers" ]]; then
    echo "No containers directory found for $VM_NAME"
    exit 1
fi

shopt -s nullglob

DEPLOYMENTS=("$VM_DIR"/containers/*/deployment.yaml)

bash $NOTIFY_SCRIPT "DEPLOYMENTS: $DEPLOYMENTS"

if [[ ${#DEPLOYMENTS[@]} -eq 0 ]]; then
    echo "No deployments found"
    exit 0
fi

for deployment in "${DEPLOYMENTS[@]}"; do
    name="$(basename "$(dirname "$deployment")")"

    echo "Applying deployment: $name"
    bash $NOTIFY_SCRIPT "Running deployment: $deployment for $VM_NAME"

    podman kube play --replace "$deployment"
done

echo "All workloads deployed successfully"
bash $NOTIFY_SCRIPT "All workloads deployed successfully"