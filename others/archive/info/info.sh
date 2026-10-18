#!/bin/bash

# Get system information
LOAD=$(uptime | awk -F'load average:' '{print $2}' | xargs | cut -d',' -f1)
PROCESSES=$(ps -e --no-headers | wc -l)
DISK=$(df -h / | awk 'NR==2 {print $5}')
DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
USERS=$(who | wc -l)
MEMORY=$(free | awk '/Mem:/ {printf "%.0f%%", $3/$2 * 100}')
SWAP=$(free | awk '/Swap:/ {if ($2==0) print "0%"; else printf "%.0f%%", $3/$2 * 100}')
IP=$(ip -4 addr show enp0s6 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1)

# Print output
cat <<EOF
  System load:  $LOAD               Processes:  $PROCESSES
  Usage of /:   $DISK of $DISK_TOTAL    Users logged in: $USERS
  Memory usage: $MEMORY               IPv4 address for enp0s6:  $IP
  Swap usage:   $SWAP
EOF