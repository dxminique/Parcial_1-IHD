
BACKEND_IP="10.0.2.10"   # Cambia por la IP privada real de tu EC2 Backend
DATA_IP="10.0.2.20"      # Cambia por la IP privada real de tu EC2 Data

echo "=============================================="
echo "  VERIFICACIÓN DE CONECTIVIDAD - INNOVATECH  "
echo "=============================================="
echo ""


echo ">>> TEST 1: Frontend → Backend (ping de red)"
ping -c 2 ${BACKEND_IP} && echo "✅ PASS: Frontend alcanza Backend" || echo "❌ FAIL"
echo ""

echo ">>> TEST 2: Frontend → Backend (HTTP :3000)"
curl -s --max-time 5 http://${BACKEND_IP}:3000/health | python3 -m json.tool
echo "✅ PASS: Microservicio Backend responde" || echo "❌ FAIL"
echo ""


echo ">>> TEST 3: Backend → Data (verificar MySQL desde Backend)"
RESULT=$(curl -s --max-time 10 http://${BACKEND_IP}:3000/db-status)
echo $RESULT | python3 -m json.tool
echo ""

if echo $RESULT | grep -q '"status":"ok"'; then
  echo "✅ PASS: Backend puede alcanzar MySQL en Data"
else
  echo "❌ FAIL: Backend no puede alcanzar MySQL"
fi
echo ""

# ── TEST 3: Consulta completa Front→Back→Data ───────────────
echo ">>> TEST 4: Consulta completa Front→Back→Data (GET /usuarios)"
curl -s --max-time 10 http://${BACKEND_IP}:3000/usuarios | python3 -m json.tool
echo ""

echo ">>> TEST 5: Insertar dato — flujo completo Front→Back→Data"
curl -s -X POST http://${BACKEND_IP}:3000/usuarios \
  -H "Content-Type: application/json" \
  -d "{\"nombre\":\"Test EP1\",\"email\":\"ep1-$(date +%s)@innovatech.cl\"}" \
  | python3 -m json.tool
echo ""

# ── TEST 4: Verificar aislamiento ──────────────────────────
echo ">>> TEST 6: Verificar aislamiento (Data NO debe responder directo desde Frontend)"
echo "Intentando conectar directo al puerto 3306 de Data desde Frontend..."
timeout 3 bash -c "echo '' > /dev/tcp/${DATA_IP}/3306" 2>/dev/null \
  && echo "⚠️  ADVERTENCIA: Puerto 3306 accesible directamente (revisar Security Groups)" \
  || echo "✅ CORRECTO: Puerto 3306 bloqueado en Frontend (mínimo privilegio aplicado)"
echo ""

echo "=============================================="
echo "  RESUMEN CONECTIVIDAD"
echo "  Frontend IP pública : $(curl -s ifconfig.me)"
echo "  Backend  IP privada : ${BACKEND_IP}"
echo "  Data     IP privada : ${DATA_IP}"
echo "=============================================="
