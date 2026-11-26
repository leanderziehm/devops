#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Cloud-init Progress Monitor
# ============================================================

if [[ $EUID -ne 0 ]]; then
    echo "Please run as root."
    exit 1
fi

MONITOR="/usr/local/sbin/cloud-init-monitor"
SERVICE="/etc/systemd/system/cloud-init-monitor.service"

echo "Installing cloud-init monitor..."

# ------------------------------------------------------------
# Install monitoring daemon
# ------------------------------------------------------------

cat > "$MONITOR" <<'MONITOR_EOF'
#!/usr/bin/env bash
set -uo pipefail

LOG="/var/log/cloud-init-output.log"
INTERVAL=5
NOTIFY_INTERVAL=15

API="https://notify.leanderziehm.com/notify/me"

START_TIME=$(date +%s)
LAST_NOTIFY=0

HOSTNAME=$(hostname)

# ------------------------------------------------------------
# Send notification
# ------------------------------------------------------------

notify() {
    local message="$1"

    printf '%s' "$message" |
        python3 -c '
import json, sys
print(json.dumps({"text": sys.stdin.read()}))
' |
        curl -fsS --max-time 15 \
            -X POST "$API" \
            -H 'accept: */*' \
            -H 'Content-Type: application/json' \
            --data-binary @- \
            >/dev/null || logger -t cloud-init-monitor \
                "Notification delivery failed"
}

# ------------------------------------------------------------
# Get latest logs
# ------------------------------------------------------------

get_logs() {
    if [[ -f "$LOG" ]]; then
        tail -n 10 "$LOG"
    else
        echo "Waiting for cloud-init output..."
    fi
}

# ------------------------------------------------------------
# Check cloud-init status
# ------------------------------------------------------------

get_status() {
    local output rc

    output=$(cloud-init status --long 2>&1) && rc=0 || rc=$?

    if grep -qE '^status: (done|error)' <<< "$output"; then
        if grep -q '^status: error' <<< "$output" || (( rc != 0 )); then
            echo "FAILED"
        else
            echo "SUCCESS"
        fi
    else
        echo "RUNNING"
    fi
}

# ------------------------------------------------------------
# Initial notification
# ------------------------------------------------------------

notify "CLOUD-INIT STARTED

Host: $HOSTNAME
Time: $(date '+%Y-%m-%d %H:%M:%S')

Monitoring provisioning progress."

# ------------------------------------------------------------
# Monitoring loop
# ------------------------------------------------------------

while true; do

    sleep "$INTERVAL"

    NOW=$(date +%s)
    ELAPSED=$((NOW - START_TIME))

    STATUS=$(get_status)

    # Final notification: success or failure

    if [[ "$STATUS" == "SUCCESS" || "$STATUS" == "FAILED" ]]; then

        if [[ "$STATUS" == "SUCCESS" ]]; then
            ICON="🟢"
        else
            ICON="🔴"
        fi

        notify "$ICON CLOUD-INIT $STATUS

Host: $HOSTNAME
Duration: ${ELAPSED}s
Time: $(date '+%Y-%m-%d %H:%M:%S')

Latest logs:
$(get_logs)"

        logger -t cloud-init-monitor "Cloud-init finished: $STATUS"
        exit 0
    fi

    # Periodic progress notification

    if (( NOW - LAST_NOTIFY >= NOTIFY_INTERVAL )); then

        notify "CLOUD-INIT IN PROGRESS

Host: $HOSTNAME
Elapsed: ${ELAPSED}s
Time: $(date '+%Y-%m-%d %H:%M:%S')

Latest 10 log lines:
$(get_logs)"

        LAST_NOTIFY=$NOW
    fi

done
MONITOR_EOF

chmod 0755 "$MONITOR"

# ------------------------------------------------------------
# Create systemd service
# ------------------------------------------------------------

cat > "$SERVICE" <<'SERVICE_EOF'
[Unit]
Description=Cloud-init Progress Monitor
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/sbin/cloud-init-monitor
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE_EOF

# ------------------------------------------------------------
# Enable and start
# ------------------------------------------------------------

systemctl daemon-reload
systemctl enable --now cloud-init-monitor.service

echo "Cloud-init monitor installed and running!"



# setup terminal login info tips:
curl -fsSL https://raw.githubusercontent.com/leanderziehm/devops/refs/heads/main/scripts/setups/setup-terminal-login-info.sh| sudo bash
