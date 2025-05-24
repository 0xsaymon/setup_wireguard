#!/bin/bash
# Додаткове налаштування для mini-PC доступу

cd ~/setup_wireguard/dist

echo "🔑 Генерація ключів для вашого пристрою..."
wg genkey | tee your_device_private.key | wg pubkey > your_device_public.key

echo "📱 Створення конфігурації для вашого пристрою..."
PUBLIC_IP=$(hostname -I | cut -d' ' -f1)

# Конфігурація для повного VPN
tee your_device_full.conf >/dev/null <<EOF
[Interface]
PrivateKey = $(cat your_device_private.key)
Address = 10.0.0.3/32
DNS = 1.1.1.1

[Peer]
PublicKey = $(cat server_public.key)
Endpoint = ${PUBLIC_IP}:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF

# Конфігурація лише для доступу до mini-PC
tee your_device_minipc.conf >/dev/null <<EOF
[Interface]
PrivateKey = $(cat your_device_private.key)
Address = 10.0.0.3/32
DNS = 1.1.1.1

[Peer]
PublicKey = $(cat server_public.key)
Endpoint = ${PUBLIC_IP}:51820
AllowedIPs = 10.0.0.0/24
PersistentKeepalive = 25
EOF

echo "🔄 Додавання нового peer до серверної конфігурації..."
sudo wg-quick down wg0

# Додати новий peer
echo "" | sudo tee -a /etc/wireguard/wg0.conf
echo "[Peer]" | sudo tee -a /etc/wireguard/wg0.conf
echo "PublicKey = $(cat your_device_public.key)" | sudo tee -a /etc/wireguard/wg0.conf
echo "AllowedIPs = 10.0.0.3/32" | sudo tee -a /etc/wireguard/wg0.conf

sudo wg-quick up wg0

echo "✅ Готово! Конфігурації збережено:"
echo "📁 your_device_full.conf - повний VPN"
echo "📁 your_device_minipc.conf - лише доступ до mini-PC"
echo ""
echo "🖥️ Конфігурація для повного VPN:"
cat your_device_full.conf
