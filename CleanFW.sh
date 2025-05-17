#!/bin/bash

# CONFIGURATION
IFACE="wlan1"
DNSMASQ_CONF="/etc/dnsmasq.conf"
HOSTAPD_CONF="/etc/hostapd/hostapd.conf"

echo "[+] Stopping rogue AP and restoring system..."

echo "[+] Killing hostapd, dnsmasq, and PHP server..."
sudo pkill hostapd
sudo pkill dnsmasq
sudo pkill php

echo "[+] Flushing iptables rules..."
sudo iptables -t nat -F
sudo iptables -F

echo "[+] Disabling IP forwarding..."
sudo sysctl -w net.ipv4.ip_forward=0

echo "[+] Resetting interface $IFACE..."
sudo ip link set $IFACE down
sudo ip addr flush dev $IFACE
sudo ip link set $IFACE up

echo "[+] (Optional) Restarting NetworkManager..."
sudo systemctl start NetworkManager

echo "[+] Cleanup complete."

