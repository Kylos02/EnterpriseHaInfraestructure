#!/bin/bash

echo "Instalando Docker y clientes LDAP..."
dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y docker-ce docker-ce-cli containerd.io openldap-clients


dnf install -y docker-ce docker-ce-cli containerd.io openldap-clients --nogpgcheck 

echo "Iniciando el demonio de Docker..."
systemctl enable --now docker

echo "Desplegando el contenedor de OpenLDAP..."
# Limpiamos por si había un contenedor previo
docker rm -f servidor_ldap 2>/dev/null

docker run -d \
  -p 389:389 -p 636:636 \
  --name servidor_ldap \
  --restart always \
  -e LDAP_ORGANISATION="Firma Arquitectura" \
  -e LDAP_DOMAIN="arquitectura.local" \
  -e LDAP_ADMIN_PASSWORD="admin123" \
  osixia/openldap:1.5.0

echo "Esperando 15 segundos a que el contenedor inicialice la base de datos..."
sleep 15

echo "Creando archivo de Unidades Organizativas (OUs)..."
cat <<EOF > ous.ldif
dn: ou=contratistas,dc=arquitectura,dc=local
objectClass: organizationalUnit
ou: contratistas

dn: ou=directores,dc=arquitectura,dc=local
objectClass: organizationalUnit
ou: directores

dn: ou=residentes,dc=arquitectura,dc=local
objectClass: organizationalUnit
ou: residentes
EOF

echo "Inyectando la jerarquía en el contenedor..."
# En la imagen osixia, el usuario administrador por defecto es 'admin', no 'Manager'
ldapadd -x -H ldap://localhost:389 -D "cn=admin,dc=arquitectura,dc=local" -w admin123 -f ous.ldif

echo "Abriendo puerto LDAP en el firewall..."
firewall-cmd --permanent --add-service=ldap
firewall-cmd --reload
