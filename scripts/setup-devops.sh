runasuser(){
    local user="$1"
    shift
    if groups | grep -qwE 'sudo|wheel'; then
        echo "User is in the sudo/wheel group. Running command as $user" >&2
        sudo -u "$user" bash -c "$*"
    else
        echo "User is NOT in the sudo/wheel group. Switching user to $user" >&2
        su - "$user" -c "$*"
    fi
}

runasuser admin "sudo -S install -d -o admin -g admin -m 755 /opt/lz && git -C /opt/lz clone https://github.com/leanderziehm/devops ; git -C /opt/lz/devops pull ; bash /opt/lz/devops/vms/setup.sh"

# sudo -u admin -c "sudo -S install -d -o admin -g admin -m 755 /opt/lz git -C /opt/lz clone https://github.com/leanderziehm/devops ; git -C /opt/lz/devops pull"
# bash /opt/lz/devops/vms/setup.sh

# su admin -c "sudo -S install -d -o admin -g admin -m 755 /opt/lz git -C /opt/lz clone https://github.com/leanderziehm/devops ; git -C /opt/lz/devops pull"
# bash /opt/lz/devops/vms/setup.sh