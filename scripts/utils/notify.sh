#!/usr/bin/env bash
# source: https://github.com/leanderziehm/devops/tree/main/others/work-in-progress/notify.sh
# sudo chmod +x /notify.sh
# sudo ln -s /notify.sh /usr/local/bin/notify
# sudo apt install jq
set -euo pipefail

if [[ $# -eq 0 ]]; then
    echo "Usage: notify <message>" >&2
    exit 1
fi

message="$*"

curl --fail --silent --show-error \
    -X POST 'https://notify.leanderziehm.com/notify/me' \
    -H 'accept: */*' \
    -H 'Content-Type: application/json' \
    -d "$(jq -n --arg text "$message" '{text: $text}')"
