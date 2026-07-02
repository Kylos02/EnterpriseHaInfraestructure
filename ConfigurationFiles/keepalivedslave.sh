#!/bin/bash

# 1. Actualizar repositorios e instalar el servicio
echo "[1/4] Actualizando paquetes e instalando Keepalived..."
sudo apt update -y && sudo apt install keepalived -y

# 2. Inyectar la configuración limpia usando 'tee' para respetar permisos de sudo
cat <<EOF | sudo tee /etc/keepalived/keepalived.conf > /dev/null
vrrp_instance VI_1 {
    state BACKUP
    interface enp0s8
    virtual_router_id 51
    priority 90
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        192.168.12.250
    }
}
EOF

# 3. Habilitar el servicio para que inicie con el sistema y arrancarlo
sudo systemctl enable keepalived
sudo systemctl restart keepalived

# 4. Imprimir el estado final para confirmar que todo salió bien
sudo systemctl status keepalived --no-pager | head -n 10