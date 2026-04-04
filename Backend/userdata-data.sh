#!/bin/bash
# ============================================================
# USER DATA — EC2 DATA (Subred Privada 10.0.2.0/24)
# Innovatech Chile — EP1 DevOps ISY1101
# ============================================================

exec > /var/log/userdata-data.log 2>&1
set -e

echo ">>> [1/6] Actualizaciones de seguridad..."
apt-get update -y
apt-get upgrade -y
apt-get install -y curl git ca-certificates gnupg

echo ">>> [2/6] Instalando Docker..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

echo ">>> [3/6] Instalando SSM Agent..."
snap install amazon-ssm-agent --classic
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service

echo ">>> [4/6] Creando volumen persistente y script de inicialización..."
mkdir -p /home/ubuntu/mysql-data
mkdir -p /home/ubuntu/mysql-init

cat > /home/ubuntu/mysql-init/01-init.sql <<EOF
-- Base de datos Innovatech Chile
CREATE DATABASE IF NOT EXISTS innovatech CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE innovatech;

-- Tabla de usuarios
CREATE TABLE IF NOT EXISTS usuarios (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  nombre      VARCHAR(100) NOT NULL,
  email       VARCHAR(100) NOT NULL UNIQUE,
  creado_en   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Datos de prueba
INSERT IGNORE INTO usuarios (nombre, email) VALUES
  ('Admin Innovatech', 'admin@innovatech.cl'),
  ('Usuario Test',     'test@innovatech.cl');

-- Usuario de aplicación con acceso solo a la BD innovatech
CREATE USER IF NOT EXISTS 'admin'@'%' IDENTIFIED BY 'password123';
GRANT ALL PRIVILEGES ON innovatech.* TO 'admin'@'%';
FLUSH PRIVILEGES;

SELECT 'Base de datos inicializada correctamente' AS status;
EOF

echo ">>> [5/6] Levantando MySQL en Docker con volumen persistente..."
docker run -d \
  --name mysql-data \
  --restart always \
  -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=rootpassword123 \
  -e MYSQL_DATABASE=innovatech \
  -e MYSQL_USER=admin \
  -e MYSQL_PASSWORD=password123 \
  -v /home/ubuntu/mysql-data:/var/lib/mysql \
  -v /home/ubuntu/mysql-init:/docker-entrypoint-initdb.d \
  mysql:8.0

echo ">>> [6/6] Esperando que MySQL inicie y verificando..."
sleep 20
docker exec mysql-data mysql -u admin -ppassword123 innovatech \
  -e "SELECT COUNT(*) as usuarios FROM usuarios;" 2>/dev/null \
  && echo "✅ MySQL listo con datos de prueba" \
  || echo "⚠️  MySQL aun inicializando, espera unos segundos mas"

docker --version
git --version

echo "=== DATA LISTO ==="
echo "MySQL corriendo en puerto 3306"
echo "Base de datos: innovatech"
echo "Usuario app: admin / password123"
echo "Datos en volumen: /home/ubuntu/mysql-data"
