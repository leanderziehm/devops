#!/usr/bin/env bash
# source: https://github.com/leanderziehm/devops/main/scripts/utils/notify.sh
# dependency: npm  
# todo:maybe swap out with python3 as dependency instead. not sure yet. 
set -euo pipefail

if [[ $# -eq 0 ]]; then
    echo "Usage: notify <message>" >&2
    exit 1
fi

if ! command -v node >/dev/null 2>&1; then
    echo "Error: Node.js is required but not installed." >&2
    echo "Install it using: pkg install nodejs" >&2
    exit 1
fi

message="$*"
payload=$(node -p 'JSON.stringify({ text: process.argv[1] })' "$message")

curl --fail --silent --show-error \
    -X POST 'https://notify.leanderziehm.com/notify/me' \
    -H 'accept: */*' \
    -H 'Content-Type: application/json' \
    -d "$payload"
