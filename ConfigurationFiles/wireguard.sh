#!/bin/bash

echo "Instalando Docker en el Master..."
dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo

dnf install -y docker-ce docker-ce-cli containerd.io --nogpgcheck

echo "Iniciando y habilitando el demonio de Docker..."
systemctl enable --now docker

echo "Desplegando la VPN (wg-easy) con interfaz gráfica..."

docker rm -f vpn_arquitectura 2>/dev/null

docker run -d \
  --name vpn_arquitectura \
  -e WG_HOST=192.168.12.200 \
  -e PASSWORD=root \
  -v ~/.wg-easy:/etc/wireguard:Z \
  -p 51820:51820/udp \
  -p 51821:51821/tcp \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  --sysctl="net.ipv4.conf.all.src_valid_mark=1" \
  --sysctl="net.ipv4.ip_forward=1" \
  --restart always \
  weejewel/wg-easy

echo "Abriendo puertos en el firewall (51820 UDP para VPN, 51821 TCP para la Web)..."
firewall-cmd --permanent --add-port=51820/udp
firewall-cmd --permanent --add-port=51821/tcp
firewall-cmd --reload
