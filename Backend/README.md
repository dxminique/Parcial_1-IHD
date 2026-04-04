# Scripts de Infraestructura — Innovatech Chile
## EP1 DevOps ISY1101 — Lift & Shift en AWS

---

## Archivos incluidos

| Archivo | Descripción |
|---|---|
| `userdata-frontend.sh` | User Data para EC2 Frontend (subred pública) |
| `userdata-backend.sh` | User Data para EC2 Backend (subred privada) |
| `userdata-data.sh` | User Data para EC2 Data con MySQL (subred privada) |
| `launch-templates.txt` | Configuración de los 3 Launch Templates |
| `verificar-conectividad.sh` | Script para demostrar Front→Back→Data en presentación |

---

## Orden de despliegue en AWS Academy

### Paso 1 — Red base
1. Crear VPC `10.0.0.0/16`
2. Crear subred pública `10.0.1.0/24`
3. Crear subred privada `10.0.2.0/24`
4. Crear Internet Gateway → asociar a la VPC
5. Crear NAT Gateway en la subred pública (requiere Elastic IP)
6. Crear tabla de rutas pública → `0.0.0.0/0` → Internet Gateway
7. Crear tabla de rutas privada → `0.0.0.0/0` → NAT Gateway

### Paso 2 — Security Groups
Crear 3 Security Groups según `launch-templates.txt`:
- `SG-Frontend` → puerto 80, 443, 22 desde Internet
- `SG-Backend`  → puerto 3000 solo desde SG-Frontend
- `SG-Data`     → puerto 3306 solo desde SG-Backend

### Paso 3 — Launch Templates
Crear los 3 Launch Templates según `launch-templates.txt`.
Pegar el User Data correspondiente en cada uno.

### Paso 4 — Lanzar instancias (en este orden)
1. **EC2 Data** primero (MySQL necesita estar listo antes que el Backend)
2. **EC2 Backend** segundo (necesita la IP de Data para conectarse)
3. **EC2 Frontend** último

> Anota las IPs privadas de Backend y Data antes de lanzar las otras instancias.
> Actualiza las variables `BACKEND_IP` y `DB_HOST` en los scripts si es necesario.

### Paso 5 — Verificar conectividad
```bash
# Conectarse al Frontend vía SSH o Session Manager
ssh -i tu-key.pem ubuntu@<IP-PUBLICA-FRONTEND>

# Descargar y ejecutar script de verificación
curl -O https://raw.githubusercontent.com/tu-usuario/backend-innovatech/main/scripts/verificar-conectividad.sh
chmod +x verificar-conectividad.sh
./verificar-conectividad.sh
```

---

## Comandos para la presentación

```bash
# Ver contenedores corriendo en cualquier instancia
docker ps

# Ver logs del Backend
docker logs backend

# Ver logs de MySQL
docker logs mysql-data

# Verificar que SSM Agent está activo
systemctl status snap.amazon-ssm-agent.amazon-ssm-agent.service

# Conectividad rápida Front→Back
curl http://10.0.2.10:3000/health

# Conectividad Back→Data
curl http://10.0.2.10:3000/db-status

# Flujo completo con dato en BD
curl http://10.0.2.10:3000/usuarios
```

---

## Arquitectura implementada

```
Internet
    │
    ▼
[Internet Gateway]
    │
    ▼  Subred pública 10.0.1.0/24
┌─────────────────────────────────────┐
│  EC2 Frontend (10.0.1.x)            │
│  Nginx :80 + Docker + SSM           │
│  SG: 80/443 desde Internet          │
└──────────────┬──────────────────────┘
               │ HTTP :3000
    ┌──────────▼──────────────────────┐  Subred privada 10.0.2.0/24
    │  EC2 Backend (10.0.2.10)        │
    │  Node.js/Express :3000 + Docker │
    │  SG: 3000 solo desde SG-Front   │
    └──────────┬──────────────────────┘
               │ MySQL :3306
    ┌──────────▼──────────────────────┐
    │  EC2 Data (10.0.2.20)           │
    │  MySQL 8.0 + Docker + volumen   │
    │  SG: 3306 solo desde SG-Back    │
    └─────────────────────────────────┘
```
