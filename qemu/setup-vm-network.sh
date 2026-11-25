#!/usr/bin/env bash
set -e

WAN_IF="wlp0s20f3"      # <-- CHANGE THIS to your Fedora internet interface (e.g., enp3s0 or wlp0s20f3)
VM_USER="qemu-sandbox"

# 1. Create bridge and TAP interface
ip link add name br0 type bridge
ip addr add 10.10.10.1/24 dev br0
ip link set br0 up

ip tuntap add dev tap0 mode tap user "$VM_USER"
ip link set tap0 master br0
ip link set tap0 up

# 2. Enable IPv4 forwarding
sysctl -w net.ipv4.ip_forward=1 > /dev/null

# 3. Assign br0 to the 'block' zone (drops all VM -> Host traffic, allows Host -> VM replies)
firewall-cmd --zone=block --add-interface=br0

# 4. Create a firewalld forwarding policy for VM -> Internet (and block local LAN)
firewall-cmd --new-policy=vm-to-wan --permanent
firewall-cmd --policy=vm-to-wan --add-ingress-zone=block --permanent
firewall-cmd --policy=vm-to-wan --add-egress-zone=FedoraWorkstation --permanent # or 'public' if your WAN_IF is in public zone
firewall-cmd --policy=vm-to-wan --set-target=ACCEPT --permanent

# Block private LAN subnets from being reached via the WAN interface
firewall-cmd --policy=vm-to-wan --add-rich-rule='rule family="ipv4" destination address="10.0.0.0/8" drop' --permanent
firewall-cmd --policy=vm-to-wan --add-rich-rule='rule family="ipv4" destination address="172.16.0.0/12" drop' --permanent
firewall-cmd --policy=vm-to-wan --add-rich-rule='rule family="ipv4" destination address="192.168.0.0/16" drop' --permanent

# Enable NAT masquerading on your internet zone
firewall-cmd --zone=FedoraWorkstation --add-masquerade --permanent

# Apply changes
firewall-cmd --reload

echo "[+] Fedora isolated network ready (Host: 10.10.10.1 | VM: 10.10.10.2)"
