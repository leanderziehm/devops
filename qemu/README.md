# qemu

# 1. Download linux vm image:

run one of the commandds
```
curl -L -o rocky10.qcow2 https://dl.rockylinux.org/pub/rocky/10/images/x86_64/Rocky-10-GenericCloud-Base.latest.x86_64.qcow2
curl -L -o alma10.qcow2 https://repo.almalinux.org/almalinux/10/cloud/x86_64/images/AlmaLinux-10-GenericCloud-10.3-20261116.0.x86_64.qcow2
curl -L -o fedora45.qcow2 https://download.fedoraproject.org/pub/fedora/linux/releases/45/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-45-1.4.x86_64.qcow2
```

# 2. Setup Overlay Image
```
qemu-img create -f qcow2 -b rocky10.qcow2 -F qcow2 rocky10-overlay1.qcow2
qemu-img create -f qcow2 -b alma10.qcow2 -F qcow2 alma10-overlay1.qcow2
qemu-img create -f qcow2 -b fedora45.qcow2 -F qcow2 fedora45-overlay1.qcow2
```

# 3. Run once with cloudinit

setup cloud init config files:
```
cat > meta-data <<'EOF'
instance-id: rocky10-cloud-01
local-hostname: rocky10-vm
EOF

cat > user-data <<'EOF'
#cloud-config
users:
  - name: root
    lock_passwd: false
    plain_text_passwd:  rootroot

  - name: roots
    shell: /bin/bash
    groups: wheel
    lock_passwd: false
    plain_text_passwd: rootroot
  
  - name: admin
    shell: /bin/bash
    # Adds user to the wheel group (standard for AlmaLinux/Fedora sudo access)
    groups: wheel
    # Grants full sudo privileges. Remove NOPASSWD if you want a password prompt.
    sudo: "ALL=(ALL) NOPASSWD:ALL"
    lock_passwd: true
    ssh_authorized_keys:
      - ssh-ed25519 AAAAC3NzaC1lZDI1NT...put_you_ssh_key_here pc@user

  - name: user
    shell: /bin/bash
    lock_passwd: true
    sudo: null
    ssh_authorized_keys:
      - ssh-ed25519 AAAAC3NzaC1lZDI1NT...put_you_ssh_key_here pc@user
ssh_pwauth: true
chpasswd:
  expire: false

packages:
  - podman
  - git

bootcmd:
  - |
    (
      HOSTNAME=$(hostname)
      IPV4=$(hostname -I | awk '{print $1}')
      INSTANCE_ID=$(cloud-init query instance_id 2>/dev/null || echo unknown)

      curl -fsS --connect-timeout 3 --max-time 10 \
        -X POST 'https://notify.leanderziehm.com/notify/me' \
        -H 'Content-Type: application/json' \
        --data "{\"text\":\"VM started. You can connect over ssh now. ${HOSTNAME} | IPv4: ${IPV4} | Instance: ${INSTANCE_ID}\"}"
    ) &
  - |
    (
      curl -fsSL https://raw.githubusercontent.com/leanderziehm/devops/refs/heads/main/scripts/cloud-init-monitor.sh | sudo bash
    ) &
  

runcmd:
  - >-
    curl --silent --show-error --fail --max-time 10 -X POST 'https://notify.leanderziehm.com/notify/me' -H 'accept: */*' -H 'Content-Type: application/json' -d "{\"text\":\"$(hostname): cloud-init runcmd just started.\"}"
  - sudo timedatectl set-timezone Europe/Berlin
  - sudo -u admin bash -c "curl -fsSL https://raw.githubusercontent.com/leanderziehm/devops/refs/heads/main/vm/setup.sh | sudo bash"
  - |
    set -e
    HOSTNAME=$(hostname)
    FQDN=$(hostname -f 2>/dev/null || hostname)
    IPV4=$(hostname -I | awk '{print $1}')
    IPV6=$(hostname -I | awk '{print $2}')
    INSTANCE_ID=$(cloud-init query instance_id 2>/dev/null || echo unknown)
    REGION=$(cloud-init query region 2>/dev/null || echo unknown)
    IMAGE=$(cloud-init query --format '{{ v1.cloud_name }}' 2>/dev/null || echo unknown)
    TEXT="qemu cloudinit runcmd finished. VM initialized
      hostname: ${HOSTNAME}
      fqdn: ${FQDN}
      ipv4: ${IPV4}
      ipv6: ${IPV6:-n/a}
      instance_id: ${INSTANCE_ID}
      region: ${REGION}
      cloud: ${IMAGE}
      time: $(date -u +%FT%TZ)"
    curl -sS -X POST 'https://notify.leanderziehm.com/notify/me' \
      -H 'accept: */*' \
      -H 'Content-Type: application/json' \
      --data "$(jq -n --arg text "$TEXT" '{text: $text}')"
EOF
```

Optional: check if cloud init user-data config is valid
```
sudo cloud-init schema --config-file user-data --annotate
```

Manditory: create cloud init seed iso:
```
genisoimage -output seed.iso -volid cidata -joliet -rock user-data meta-data
```

run qemu with seed.iso:
```
qemu-system-x86_64 -enable-kvm -m 2048 -cpu host -drive file=rocky10-overlay1.qcow2,if=virtio,format=qcow2 -netdev user,id=net0,hostfwd=tcp::2222-:22 -device virtio-net-pci,netdev=net0 -cdrom seed.iso
```

if sshd is enabled you can connect over ssh: 
```
ssh -p 2222 roots@127.0.0.1
```
# 4. Better qemu command to connect only over ssh
```
qemu-system-x86_64 -enable-kvm -m 2048 -cpu host -drive file=rocky10-overlay1.qcow2,if=virtio,format=qcow2 -nic user,model=virtio-net-pci,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:8081,hostfwd=tcp::8443-:8443 -display none
```

use ssh with ssh key:
```
ssh -p 2222 admin@127.0.0.1
```

# 4.2 Tap networking:


```
# Create TAP interface
sudo ip tuntap add dev tap0 mode tap user "$USER"
sudo ip addr add 192.168.100.1/24 dev tap0
sudo ip link set tap0 up


sudo ip link set tap0 down
sudo ip tuntap del dev tap0 mode tap

sudo ip tuntap add dev tap0 mode tap user thesis
sudo ip addr add 192.168.100.1/24 dev tap0
sudo ip link set tap0 up

# Enable IP forwarding
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-qemu-forward.conf
sudo sysctl --system

# Configure firewalld
sudo firewall-cmd --permanent --zone=trusted --add-interface=tap0
sudo firewall-cmd --permanent --zone=trusted --add-masquerade
sudo firewall-cmd --reload



# Create a forwarding policy from TAP to internet
sudo firewall-cmd --permanent --new-policy=qemu-tap

# Define incoming and outgoing zones
sudo firewall-cmd --permanent --policy=qemu-tap \
  --add-ingress-zone=trusted

sudo firewall-cmd --permanent --policy=qemu-tap \
  --add-egress-zone=FedoraWorkstation

# Allow forwarding
sudo firewall-cmd --permanent --policy=qemu-tap \
  --set-target=ACCEPT

# Enable NAT/masquerading
sudo firewall-cmd --permanent --policy=qemu-tap \
  --add-masquerade

# Apply configuration
sudo firewall-cmd --reload
```

```
qemu-system-x86_64 \
  -enable-kvm \
  -m 2048 \
  -cpu host \
  -drive file=rocky10-overlay1.qcow2,if=virtio,format=qcow2 \
  -netdev tap,id=net0,ifname=tap0,script=no,downscript=no \
  -device virtio-net-pci,netdev=net0 \
  -cdrom seed.iso -nographic
```

```
ssh admin@192.168.100.2
```

```
# Remove TAP interface
sudo ip link set tap0 down
sudo ip tuntap del dev tap0 mode tap

# Remove firewalld configuration
sudo firewall-cmd --permanent --zone=trusted --remove-interface=tap0
sudo firewall-cmd --permanent --zone=trusted --remove-masquerade
sudo firewall-cmd --reload

# Remove persistent IP forwarding configuration
sudo rm -f /etc/sysctl.d/99-qemu-forward.conf

# Disable IP forwarding (if you enabled it only for QEMU)
sudo sysctl -w net.ipv4.ip_forward=0
```


# security considerations:
todo: firewall ip securiyt

## never run as root

creade dedicated user:
```
sudo useradd --system --no-create-home --shell /usr/sbin/nologin myqemu
sudo chown myqemu:myqemu overlay.qcow2
```

## create secure network:
download the sh scrip in this github repo and run it (on rhel linux: fedora,rockylinux, almalinux because it assumes firewalld)
```
bash ./setup-network.sh
```
## Strip unnecessary hardware. 
Use -nodefaults to prevent QEMU from loading default devices (such as sound cards, floppy controllers, parallel ports, and unnecessary USB controllers) that you do not need, drastically reducing the code paths the guest can interact with.

## Disable host-guest bridges. 
Never use shared folders (virtio-9p, virtio-fs, or -drive file=fat:rw:...), clipboard sharing (SPICE agent), or drag-and-drop features. Malware can traverse shared directories or exploit parsing bugs in clipboard handlers.

## Use mandatory access controls.
On Linux, wrap the QEMU process in an AppArmor profile, SELinux context, or a bubblewrap/seccomp sandbox to restrict which syscalls and host file paths the binary can access.

## Cap host resources.
Enforce strict CPU and memory limits (using -m and host cgroups) so a fork bomb or cryptominer inside the guest cannot lock up your host operating system

## Avoid hardware passthrough. 
Do not pass through physical USB devices or PCI hardware (VFIO) to an infected guest, as malware can flash malicious firmware onto the physical device itself.

## Use secure cli parameters:

Strip unnecessary hardware.  =  -nodefaults

• Disable host-guest bridges. Never use shared folders (virtio-9p, virtio-fs, or -drive file=fat:rw:...), clipboard sharing (SPICE agent), or drag-and-drop features. Malware can traverse shared directories or exploit parsing bugs in clipboard handlers.

-sandbox on,obsolete=deny,elevateprivileges=deny,spawn=deny,resourcecontrol=deny

```
qemu-system-x86_64 \
  -enable-kvm \
  -cpu host \
  -m 4G \
  -smp 2 \
  -nodefaults \
  -sandbox on,obsolete=deny,elevateprivileges=deny,spawn=deny,resourcecontrol=deny \
  -vga virtio \
  -display gtk \
  -device virtio-net-pci,netdev=net0,mac=52:54:00:12:34:56 \
  -netdev tap,id=net0,ifname=tap0,script=no,downscript=no \
  -device virtio-blk-pci,drive=hd0 \
  -drive id=hd0,file=guest_overlay.qcow2,format=qcow2,if=none
```

# Other Information

discard know host for ip and port:
```
ssh-keygen -R "[127.0.0.1]:2222"
```

## cloud init 

```
sudo cloud-init status --long
sudo vi /var/log/cloud-init-output.log
sudo vi /var/log/cloud-init.log

cd /var/lib/cloud/
```

in vm check is sshd is enabled and running:
```
systemctl status sshd
```


## qemu cli settings

### display

normal same if you dont write it:
-display none default

text only similar to ssh without needing ssh:
-nographic

no input or output, input only over ssh:
-display none

### port forwarding
-netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:80,hostfwd=tcp::4443-:443 -device virtio-net-pci,netdev=net0



## Optional

you can expand you virtual storage size when vm sotrage gets low 
```
qemu-img resize debian-overlay.qcow2 +10G
```



## Gui
you can also use virtual machine manager virsh as a gui and abstraction layer above qemu. 


---

## other notable linux vm images:

```
curl -L -o debian13.qcow2 https://cloud.debian.org/images/cloud/trixie/latest/debian-13-nocloud-amd64.qcow2
```

```
qemu-img create -f qcow2 -b debian13.qcow2 -F qcow2 debian13-overlay1.qcow2

```



### Alpine Linux

```
curl -L -o alpine.qcow2 https://dl-cdn.alpinelinux.org/alpine/v3.24/releases/cloud/alpine-3.24.4-x86_64-cloudinit-r0.qcow2
```


### Flatcar
```
curl -L -o flatcar.img https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu_image.img
curl -L -o flatcar.img.sig https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu_image.img.sig

gpg --verify flatcar_production_qemu_image.img.sig
```


### Arch Linux

```
curl -L -o arch.qcow2 https://gitlab.archlinux.org/archlinux/arch-boxes/-/package_files/13663/download
```