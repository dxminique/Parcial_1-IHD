

exec > /var/log/userdata-backend.log 2>&1
set -e

echo ">>> [1/6] Actualizaciones de seguridad..."
apt-get update -y
apt-get upgrade -y
apt-get install -y curl git unzip ca-certificates gnupg

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

echo ">>> [4/6] Clonando repositorio del microservicio..."

REPO_URL="https://github.com/dxminique/Parcial_1-IHD.git"
DB_HOST="10.0.2.20"    
DB_PASSWORD="password123"

git clone ${REPO_URL} /home/ubuntu/backend
cd /home/ubuntu/backend

echo ">>> [5/6] Construyendo y levantando contenedor Docker..."
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

echo ">>> [6/6] Verificando servicio..."
sleep 5
curl -s http://localhost:3000/health && echo "" || echo "ADVERTENCIA: Backend aun iniciando"

docker --version
git --version

echo "=== BACKEND LISTO ==="
echo "Microservicio corriendo en puerto 3000"
echo "Conectado a DB en: ${DB_HOST}:3306"
