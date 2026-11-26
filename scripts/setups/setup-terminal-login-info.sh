
#!/usr/bin/env bash
set -euo pipefail

# ==========================================
# VM Welcome Message & Help
# ==========================================

if [[ $EUID -ne 0 ]]; then
    echo "Please run as root."
    exit 1
fi

# Static MOTD
cat > /etc/motd <<'EOF'
==================================================
             Welcome to your VM!
==================================================

 Useful commands:

   help-vm                 Show VM command cheat sheet
   podman ps               List running containers
   podman images           List container images
   podman logs <name>      View container logs
   podman stats            Container resource usage
   systemctl status <svc>  Check a service
   df -h                   Check disk space
   free -h                 Check memory usage
   ip addr                 Network information
   sudo -i                 Become root

==================================================
EOF

# Dynamic login information
cat > /etc/profile.d/vm-welcome.sh <<'EOF'
#!/bin/bash

[[ $- == *i* ]] || return

echo ""
echo " VM:       $(hostname)"
echo " IP:       $(hostname -I 2>/dev/null | awk '{print $1}')"
echo " Uptime:   $(uptime -p 2>/dev/null)"
echo " Disk:     $(df -h / | awk 'NR==2 {print $5 " used"}')"
echo " Memory:   $(free -h | awk '/Mem:/ {print $3 " / " $2}')"
echo ""
EOF

chmod 644 /etc/profile.d/vm-welcome.sh

# Reusable help command
cat > /usr/local/bin/help-vm <<'EOF'
#!/usr/bin/env bash

cat <<'HELP'
==================================================
                 VM COMMAND HELP
==================================================

CONTAINERS (PODMAN)
  podman ps                  Running containers
  podman ps -a               All containers
  podman images              Available images
  podman logs <name>         Container logs
  podman logs -f <name>      Follow container logs
  podman stats               Resource usage
  podman exec -it <name> bash  Enter container

SYSTEM
  systemctl status <svc>     Service status
  systemctl restart <svc>    Restart service
  systemctl list-units       Running services
  journalctl -xe             Recent system logs
  journalctl -u <svc> -f     Follow service logs

RESOURCES
  df -h                      Disk usage
  free -h                    Memory usage
  top                        Process monitor
  uptime                     System uptime
  ip addr                    Network interfaces

GENERAL
  sudo -i                    Become root
  help-vm                    Show this help

==================================================
HELP
EOF

chmod 755 /usr/local/bin/help-vm

echo "[init] VM welcome message and help installed"
