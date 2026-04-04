#!/bin/bash
# ============================================================
# USER DATA — EC2 DATA (Subred Privada 10.0.2.0/24)
# Innovatech Chile — EP1 DevOps ISY1101
# Amazon Linux 2023
# ============================================================

exec > /var/log/userdata-data.log 2>&1
set -e

echo ">>> [1/5] Actualizaciones de seguridad..."
yum update -y

echo ">>> [2/5] Instalando Docker y Git..."
yum install -y docker git
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

echo ">>> [3/5] Creando volumen persistente y script de inicialización..."
mkdir -p /home/ec2-user/mysql-data
mkdir -p /home/ec2-user/mysql-init

cat > /home/ec2-user/mysql-init/01-init.sql <<EOF
CREATE DATABASE IF NOT EXISTS innovatech CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE innovatech;

CREATE TABLE IF NOT EXISTS usuarios (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  nombre      VARCHAR(100) NOT NULL,
  email       VARCHAR(100) NOT NULL UNIQUE,
  creado_en   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT IGNORE INTO usuarios (nombre, email) VALUES
  ('Admin Innovatech', 'admin@innovatech.cl'),
  ('Usuario Test',     'test@innovatech.cl');

CREATE USER IF NOT EXISTS 'admin'@'%' IDENTIFIED BY 'password123';
GRANT ALL PRIVILEGES ON innovatech.* TO 'admin'@'%';
FLUSH PRIVILEGES;
EOF

echo ">>> [4/5] Levantando MySQL en Docker con volumen persistente..."
docker run -d \
  --name mysql-data \
  --restart always \
  -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=rootpassword123 \
  -e MYSQL_DATABASE=innovatech \
  -e MYSQL_USER=admin \
  -e MYSQL_PASSWORD=password123 \
  -v /home/ec2-user/mysql-data:/var/lib/mysql \
  -v /home/ec2-user/mysql-init:/docker-entrypoint-initdb.d \
  mysql:8.0

echo ">>> [5/5] Esperando que MySQL inicie..."
sleep 20
docker exec mysql-data mysql -u admin -ppassword123 innovatech \
  -e "SELECT COUNT(*) as usuarios FROM usuarios;" 2>/dev/null \
  && echo "✅ MySQL listo con datos de prueba" \
  || echo "⚠️  MySQL aun inicializando"

docker --version
git --version

echo "=== DATA LISTO ==="
echo "MySQL corriendo en puerto 3306"
echo "Base de datos: innovatech"
echo "Usuario: admin / password123"
