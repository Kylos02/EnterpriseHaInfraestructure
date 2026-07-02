#!/bin/bash

echo "Instalando Nginx y utilidades de contraseñas..."
dnf update -y
dnf install -y nginx httpd-tools

echo "Creando el directorio de la Intranet y la página de cronogramas..."
mkdir -p /usr/share/nginx/html/intranet
cat <<EOF > /usr/share/nginx/html/intranet/index.html
<html>
<head><title>Intranet - Firma de Arquitectura</title></head>
<body>
<h1>Cronogramas de Avance</h1>
<p>Acceso concedido. Bienvenido a la vista de direcciones de obra.</p>
</body>
</html>
EOF

echo "Configurando acceso restringido (htpasswd)..."
# Se crea el archivo de contraseñas con el usuario 'director' y contraseña 'root'
htpasswd -bc /etc/nginx/.htpasswd director root

echo "Configurando el Virtual Host de Nginx para la Intranet..."
# Se renombra la config por defecto para que no estorbe
mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.bak 2>/dev/null

cat <<EOF > /etc/nginx/conf.d/intranet.conf
server {
    listen 80;
    server_name localhost;

    location / {
        root /usr/share/nginx/html/intranet;
        index index.html;
        auth_basic "Acceso Restringido - Direccion";
        auth_basic_user_file /etc/nginx/.htpasswd;
    }
}
EOF

echo "Abriendo puerto en el firewall..."
firewall-cmd --permanent --add-service=http
firewall-cmd --reload

echo "Iniciando y habilitando Nginx..."
systemctl enable nginx
systemctl start nginx
