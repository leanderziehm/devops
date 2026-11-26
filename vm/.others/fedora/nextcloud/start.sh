
#!/usr/bin/env bash

set -euo pipefail

if [[ ! -f .env ]]; then
    echo ".env not found, copying example.env..."
    cp example.env .env
fi

mkdir -p ~/container_mounts/nextcloud/{postgres,redis,nextcloud}

podman compose up -d
