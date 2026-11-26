#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Please run with sudo: sudo $0"
    exit 1
fi

# setup rootless podman user
PODMAN_USER="podmanager"
if ! id "$PODMAN_USER" &>/dev/null; then
    echo "Creating user: $PODMAN_USER"
    useradd --create-home --shell /bin/bash "$PODMAN_USER"
else
    echo "User already exists: $PODMAN_USER"
fi
loginctl enable-linger "$PODMAN_USER"

## setup git repo:

ADMIN_USER="admin"
REPO="/opt/lz/devops"
REPO_URL="https://github.com/leanderziehm/devops"

install -d -o "$ADMIN_USER" -g "$ADMIN_USER" -m 755 /opt/lz

if [[ -d "$REPO/.git" ]]; then
    sudo -u "$ADMIN_USER" -H git -C "$REPO" pull --ff-only
else
    sudo -u "$ADMIN_USER" -H git clone "$REPO_URL" "$REPO"
fi

sudo -u "$ADMIN_USER" -H git -C "$REPO" config core.fileMode false

sudo bash "$REPO/vm/update.sh"

curl -X 'POST' 'https://notify.leanderziehm.com/notify/me' -H 'accept: */*' -H 'Content-Type: application/json' -d "{ \"text\": \"$(hostname): setup-devops.sh ran with user: $(whoami)\" }"


# old sudo version
# sudo mkdir -p /opt/lz
# sudo git -C /opt/lz clone https://github.com/leanderziehm/devops
# sudo git -C /opt/lz/devops config core.fileMode false
# sudo git -C /opt/lz/devops pull
# sudo bash /opt/lz/devops/vm/update.sh
# echo "enable linger"
# sudo loginctl enable-linger "$USER"


# tools: firewalld.
# os: linux usually rhel based so rocky, alma, fedora but can be debian or others


# sudo install -d -o admin -g admin -m 755 /opt/lz
# sudo -u admin -c "git clone https://github.com/leanderziehm/devops /opt/lz/devops"
# sudo -u admin -c "bash /opt/lz/devops/vm/update.sh"

###

# runasuser(){
#     local user="$1"
#     shift
#     if groups | grep -qwE 'sudo|wheel'; then
#         echo "User is in the sudo/wheel group. Running command as $user" >&2
#         sudo -u "$user" bash -c "$*"
#     else
#         echo "User is NOT in the sudo/wheel group. Switching user to $user" >&2
#         su - "$user" -c "$*"
#     fi
# }

# runasuser admin "sudo -S install -d -o admin -g admin -m 755 /opt/lz && git -C /opt/lz clone https://github.com/leanderziehm/devops ; git -C /opt/lz/devops pull ; bash /opt/lz/devops/vm/update.sh"

###

# sudo -u admin -c "sudo -S install -d -o admin -g admin -m 755 /opt/lz git -C /opt/lz clone https://github.com/leanderziehm/devops ; git -C /opt/lz/devops pull"
# bash /opt/lz/devops/vm/update.sh

# su admin -c "sudo -S install -d -o admin -g admin -m 755 /opt/lz git -C /opt/lz clone https://github.com/leanderziehm/devops ; git -C /opt/lz/devops pull"
# bash /opt/lz/devops/vm/update.sh