
#!/usr/bin/env bash

set -euo pipefail

if [[ ! -f .env ]]; then
    echo ".env not found, copying example.env..."
    cp example.env .env
fi

mkdir -p ~/container_mounts/immich/{library,postgres}

podman compose up -d

# generate secrets 

# UPLOAD_LOCATION=/tmp/immich-library DB_DATA_LOCATION=/tmp/immich-postgres IMMICH_VERSION=v3 DB_PASSWORD="$(openssl rand -hex 32)" DB_USERNAME=postgres DB_DATABASE_NAME=immich 