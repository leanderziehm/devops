#!/usr/bin/env bash
sudo ip link del tap0 2>/dev/null || true
sudo ip link del br0 2>/dev/null || true
sudo firewall-cmd --zone=block --remove-interface=br0 2>/dev/null || true
sudo firewall-cmd --delete-policy=vm-to-wan --permanent 2>/dev/null || true
sudo firewall-cmd --zone=FedoraWorkstation --remove-masquerade --permanent 2>/dev/null || true
sudo firewall-cmd --reload
