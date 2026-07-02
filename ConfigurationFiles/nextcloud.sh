echo "Desplegando el contenedor de PostgreSQL (Motor de Base de Datos)..."
docker run -d \
  --name base_datos_postgres \
  --network red_nextcloud \
  --restart always \
  -e POSTGRES_DB=arquitectura \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=root \
  postgres:15

echo "Esperando 5 segundos a que la base de datos esté lista..."
sleep 5

echo "Desplegando el contenedor de Nextcloud (Conectado a PostgreSQL)..."
docker run -d \
  -p 8080:80 \
  --name nube_arquitectura \
  --network red_nextcloud \
  --restart always \
  nextcloud

echo "Verificando puerto 8080 en el firewall del Slave..."
firewall-cmd --permanent --add-port=8080/tcp 2>/dev/null
firewall-cmd --reload 2>/dev/null
