#!/bin/bash

echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

sudo wg-quick up wg0
sudo systemctl enable wg-quick@wg0