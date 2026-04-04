#!/bin/bash
# ============================================================
# USER DATA — EC2 FRONTEND (Subred Pública 10.0.1.0/24)
# Innovatech Chile — EP1 DevOps ISY1101
# ============================================================

exec > /var/log/userdata-frontend.log 2>&1
set -e

echo ">>> [1/7] Actualizaciones de seguridad..."
apt-get update -y
apt-get upgrade -y
apt-get install -y curl git unzip ca-certificates gnupg

echo ">>> [2/7] Instalando Docker..."
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

echo ">>> [3/7] Instalando Nginx..."
apt-get install -y nginx
systemctl enable nginx
systemctl start nginx

echo ">>> [4/7] Instalando SSM Agent..."
snap install amazon-ssm-agent --classic
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service

echo ">>> [5/7] Configurando Nginx como reverse proxy al Backend..."
# Reemplazar IP_PRIVADA_BACKEND con la IP real de tu EC2 Backend (ej: 10.0.2.10)
BACKEND_IP="10.0.2.10"

cat > /etc/nginx/sites-available/default <<EOF
server {
    listen 80;
    server_name _;

    # Página de bienvenida Frontend
    location / {
        root /var/www/html;
        index index.html;
    }

    # Proxy al Backend (solo rutas /api)
    location /api/ {
        proxy_pass http://${BACKEND_IP}:3000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

echo ">>> [6/7] Creando página HTML de prueba..."
cat > /var/www/html/index.html <<EOF
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

echo ">>> [7/7] Verificando instalaciones..."
docker --version
git --version
nginx -v

echo "=== FRONTEND LISTO ==="
echo "Nginx corriendo en puerto 80"
echo "Proxy configurado hacia Backend: ${BACKEND_IP}:3000"
