#!/bin/bash

# --- VARIABLES ---
INTERFAZ="enp0s8"          
VIP="192.168.12.250"        
IP_NODO2="192.168.12.201"    

echo "Actualizando el sistema e instalando paquetes base..."
dnf update -y
dnf install -y keepalived haproxy nano

echo "Configurando Keepalived..."
cat <<EOF > /etc/keepalived/keepalived.conf
vrrp_instance VI_1 {
    state MASTER
    interface $INTERFAZ
    virtual_router_id 51
    priority 101
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        $VIP
    }
}
EOF

echo "Configurando HAProxy..."
# Se realiza un respaldo del archivo original por cualquier cosa
cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak

# Se configura HAProxy para que escuche en la VIP y mande el tráfico al Nodo 2
cat <<EOF > /etc/haproxy/haproxy.cfg
global
    log         127.0.0.1 local2
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon

defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m

frontend http_front
    bind *:80
    default_backend http_back

backend http_back
    balance roundrobin
    server nodo2_web $IP_NODO2:80 check
EOF

echo "Abriendo puertos en el Firewall (HTTP y VRRP para Keepalived)..."
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-protocol=vrrp
firewall-cmd --reload

echo "Habilitando e iniciando los servicios de manera limpia..."
systemctl enable keepalived
systemctl start keepalived
systemctl enable haproxy
systemctl start haproxy
