#!/bin/bash

# WireGuard VPN Setup Script
echo "🐲 WireGuard VPN Setup Script"

echo "⬇️ Installing WireGuard..."
# install WireGuard
sudo apt update
sudo apt install wireguard -y

# create dir
mkdir -p ./dist
cd ./dist

echo "🗝️ Generating keys..."
# generate new server keys
wg genkey | tee server_private.key | wg pubkey >server_public.key
# generate client keys
wg genkey | tee client_private.key | wg pubkey >client_public.key

# Determine the public IP of the VPS
PUBLIC_IP=$(hostname -I | cut -d' ' -f1)
echo "🖥️ Public IP: $PUBLIC_IP"

echo "📝 Creating server configuration..."
# Create the server configuration /etc/wireguard/wg0.conf
sudo mkdir -p /etc/wireguard
sudo tee /etc/wireguard/wg0.conf >/dev/null <<EOF
[Interface]
Address = 10.0.0.1/24
PrivateKey = $(cat server_private.key)
ListenPort = 51820
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
SaveConfig = true

[Peer]
PublicKey = $(cat client_public.key)
AllowedIPs = 10.0.0.2/32
EOF

echo "🔑 Create client configuration..."
# Create the ready-to-use client configuration client.conf
tee client.conf >/dev/null <<EOF
[Interface]
PrivateKey = $(cat client_private.key)
Address = 10.0.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = $(cat server_public.key)
Endpoint = ${PUBLIC_IP}:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF

echo "💼 Configs saved to ~/setup_wireguard/dist/client.conf"

echo "🔄 Configuring firewall..."
# Enable IP forwarding
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

echo "🔒 Starting WireGuard..."
# Start WireGuard
sudo wg-quick up wg0
sudo systemctl enable wg-quick@wg0

echo "📝 Client configuration:"
echo ""
# Display the client configuration
CONFIG=$(cat ~/setup_wireguard/dist/client.conf)
echo "client config:"
echo ""
echo "$CONFIG"
