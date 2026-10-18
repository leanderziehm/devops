#!/usr/bin/env bash
set -euo pipefail

START_TIME="$(date +%s)"

# to run this every day on 3AM write this: chmod +x backup-ssh-logs.sh
# crontab -e
# 0 3 * * * ~/devops/backup-ssh-logs.sh >> ~/logs/backup-ssh-logs.log 2>&1
# or 
# 0 3 * * * /bin/bash ~/devops/backup-ssh-logs.sh >> ~/logs/backup-ssh-logs.log 2>&1

# ---- config ----

BACKUP_DIR="$HOME/backups/backup-ssh-logs"
RETENTION_DAYS=180

HOSTNAME="$(hostname -s)"
RCLONE_REMOTE="dropbox:backups/backup-ssh-logs/${HOSTNAME}"

DATE="$(date -d yesterday +%F)"

RAW_FILE="ssh_${DATE}.json"
ARCHIVE_FILE="${RAW_FILE}.gz"
CHECKSUM_FILE="${ARCHIVE_FILE}.sha256"


trap 'curl -s -X POST https://notify.leanderziehm.com/notify/me \
-H "Content-Type: application/json" \
-d "$(jq -n --arg text "SSH journal backup FAILED on ${HOSTNAME} at $(date -Is)" "{text: \$text}")"' ERR


mkdir -p "${BACKUP_DIR}"


# ---- export yesterday ssh journal ----

journalctl \
    -u ssh.service \
    --since "${DATE} 00:00:00" \
    --until "${DATE} 23:59:59" \
    -o json \
    > "${BACKUP_DIR}/${RAW_FILE}"


# ---- compress ----

gzip \
    -f "${BACKUP_DIR}/${RAW_FILE}"


# ---- checksum ----

sha256sum \
    "${BACKUP_DIR}/${ARCHIVE_FILE}" \
    > "${BACKUP_DIR}/${CHECKSUM_FILE}"


# ---- upload ----

rclone copy \
    "${BACKUP_DIR}/${ARCHIVE_FILE}" \
    "${RCLONE_REMOTE}" \
    --stats=1m \
    --log-level NOTICE


rclone copy \
    "${BACKUP_DIR}/${CHECKSUM_FILE}" \
    "${RCLONE_REMOTE}" \
    --stats=1m \
    --log-level NOTICE


# ---- local retention ----

find "${BACKUP_DIR}" \
    -type f \
    -mtime +"${RETENTION_DAYS}" \
    -delete



# ---- notification ----

FILE_SIZE="$(du -h "${BACKUP_DIR}/${ARCHIVE_FILE}" | cut -f1)"

END_TIME="$(date +%s)"
DURATION=$((END_TIME-START_TIME))

MESSAGE=$(cat <<EOF
SSH journal backup completed

Host: ${HOSTNAME}
Date: ${DATE}
File: ${ARCHIVE_FILE}
Size: ${FILE_SIZE}
Duration: ${DURATION}s
Timestamp: $(date -Is)
EOF
)


curl -s -X POST \
'https://notify.leanderziehm.com/notify/me' \
-H 'Content-Type: application/json' \
-d "$(jq -n --arg text "$MESSAGE" '{text:$text}')"


echo "Completed ${ARCHIVE_FILE}"