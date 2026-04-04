#!/bin/bash
# ============================================================
# USER DATA — EC2 FRONTEND (Subred Pública 10.0.1.0/24)
# Innovatech Chile — EP1 DevOps ISY1101
# Amazon Linux 2023
# ============================================================

exec > /var/log/userdata-frontend.log 2>&1
set -e

echo ">>> [1/6] Actualizaciones de seguridad..."
yum update -y

echo ">>> [2/6] Instalando Docker y Git..."
yum install -y docker git
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

echo ">>> [3/6] Instalando Nginx..."
yum install -y nginx
systemctl enable nginx
systemctl start nginx

echo ">>> [4/6] Configurando Nginx como reverse proxy al Backend..."
BACKEND_IP="10.0.2.179"

cat > /etc/nginx/conf.d/innovatech.conf <<EOF
server {
    listen 80;
    server_name _;

    location / {
        root /usr/share/nginx/html;
        index index.html;
    }

    location /api/ {
        proxy_pass http://${BACKEND_IP}:3000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

echo ">>> [5/6] Creando página HTML de prueba..."
cat > /usr/share/nginx/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><title>Innovatech Chile - Frontend</title></head>
<body>
  <h1>Innovatech Chile</h1>
  <p>Capa Frontend — EC2 Subred Publica</p>
  <p>Arquitectura: Frontend → Backend → Data</p>
  <ul>
    <li><a href="/api/health">Health check Backend</a></li>
    <li><a href="/api/db-status">Estado base de datos</a></li>
    <li><a href="/api/usuarios">Listar usuarios</a></li>
  </ul>
</body>
</html>
EOF

nginx -t && systemctl reload nginx

echo ">>> [6/6] Verificando instalaciones..."
docker --version
git --version
nginx -v

echo "=== FRONTEND LISTO ==="
echo "Nginx corriendo en puerto 80"
echo "Proxy configurado hacia Backend: ${BACKEND_IP}:3000"
