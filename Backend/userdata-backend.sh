#!/bin/bash


exec > /var/log/userdata-backend.log 2>&1
set -e

echo ">>> [1/5] Actualizaciones de seguridad..."
yum update -y

echo ">>> [2/5] Instalando Docker y Git..."
yum install -y docker git
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

echo ">>> [3/5] Clonando repositorio del microservicio..."

REPO_URL="https://github.com/dxminique/Parcial_1-IHD.git"
DB_HOST="10.0.2.246"
DB_PASSWORD="password123"

git clone ${REPO_URL} /home/ec2-user/backend
cd /home/ec2-user/backend

echo ">>> [4/5] Construyendo y levantando contenedor Docker..."
docker build -t backend-innovatech .

docker run -d \
  --name backend \
  --restart always \
  -p 3000:3000 \
  -e DB_HOST=${DB_HOST} \
  -e DB_PORT=3306 \
  -e DB_USER=admin \
  -e DB_PASSWORD=${DB_PASSWORD} \
  -e DB_NAME=innovatech \
  backend-innovatech

echo ">>> [5/5] Verificando servicio..."
sleep 5
curl -s http://localhost:3000/health && echo "" || echo "ADVERTENCIA: Backend aun iniciando"

docker --version
git --version

echo "=== BACKEND LISTO ==="
echo "Microservicio corriendo en puerto 3000"
echo "Conectado a DB en: ${DB_HOST}:3306"
