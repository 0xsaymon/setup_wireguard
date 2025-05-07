#!/bin/bash

# 1. create dir
mkdir -p ~/wireguard-setup
cd ~/wireguard-setup

# 2. generate new server keys
wg genkey | tee server_private.key | wg pubkey > server_public.key

# 3. generate client keys
wg genkey | tee client_private.key | wg pubkey > client_public.key

# 4. Determine the public IP of the VPS
PUBLIC_IP=$(curl -s ifconfig.me)

# 5. Create the server configuration /etc/wireguard/wg0.conf
sudo mkdir -p /etc/wireguard
sudo tee /etc/wireguard/wg0.conf > /dev/null <<EOF
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

# 6. Create the ready-to-use client configuration client.conf
tee client.conf > /dev/null <<EOF
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

echo "✅ Success! Configs saved у ~/wireguard-setup/"
echo "➡️ client.conf can be used with WireGuard."
echo "➡️ Now run VPN using: sudo wg-quick up wg0"