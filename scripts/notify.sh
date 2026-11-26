#!/usr/bin/env bash
set -euo pipefail

echo_flag=false
log_flag=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --echo) echo_flag=true; shift ;;
        --log)  log_flag=true;  shift ;;
        *) break ;;
    esac
done

if [[ $# -eq 0 ]]; then
    echo "Usage: notify [--echo] [--log] <message>" >&2
    exit 1
fi

message="$*"

$echo_flag && echo "$message"
$log_flag  && printf '%s %s\n' "$(date '+%F %T')" "$message" >> "$HOME/notify.log"

send_notify() {
    curl -sS -X POST 'https://notify.leanderziehm.com/notify/me' \
        -H 'accept: */*' \
        -H 'Content-Type: application/json' \
        -d "$1"
}

# Characters that require JSON escaping: \ " and any control char (0x00–0x1F, 0x7F)
if [[ "$message" != *[\\\"]* && ! "$message" =~ [[:cntrl:]] ]]; then
    # Nothing to escape — send as-is
    send_notify "{ \"text\": \"$message\" }"
    exit 0
fi

# Message contains something that needs escaping
if command -v jq >/dev/null 2>&1; then
    payload=$(jq -n --arg text "$message" '{text: $text}')
    send_notify "$payload"
    exit 0
fi

# after the jq check, before manual escaping:
if [[ "$message" =~ [[:cntrl:]] ]]; then
    echo "notify: message contains control chars and jq is unavailable" >&2
    exit 1
fi

# Fallback: manual escaping
escaped=${message//\\/\\\\}
escaped=${escaped//\"/\\\"}
escaped=${escaped//$'\n'/\\n}
escaped=${escaped//$'\r'/\\r}
escaped=${escaped//$'\t'/\\t}
escaped=${escaped//$'\b'/\\b}
escaped=${escaped//$'\f'/\\f}

send_notify "{ \"text\": \"$escaped\" }"



# message="$*"
# curl -X 'POST' 'https://notify.leanderziehm.com/notify/me' -H 'accept: */*' -H 'Content-Type: application/json' -d '{ "text": "cloud-init of a qemu vm is running now." }'
# curl -X 'POST' 'https://notify.leanderziehm.com/notify/me' -H 'accept: */*' -H 'Content-Type: application/json' -d "{ \"text\": \"$message\" }"
# ##### escape
# # Escape backslashes first, then double quotes, then control chars
# escaped=${message//\\/\\\\}      # \  -> \\
# escaped=${escaped//\"/\\\"}      # "  -> \"
# escaped=${escaped//$'\n'/\\n}    # newline -> \n
# escaped=${escaped//$'\r'/\\r}    # CR -> \r
# escaped=${escaped//$'\t'/\\t}    # tab -> \t
# curl -X POST 'https://notify.leanderziehm.com/notify/me' \
#     -H 'accept: */*' \
#     -H 'Content-Type: application/json' \
#     -d "{ \"text\": \"$escaped\" }"

# ##### jq
# message="$*"
# payload=$(jq -n --arg text "$message" '{text: $text}')
# curl -X POST 'https://notify.leanderziehm.com/notify/me' \
#     -H 'accept: */*' \
#     -H 'Content-Type: application/json' \
#     -d "$payload"
# #####

# source: https://github.com/leanderziehm/devops/main/scripts/notify.sh