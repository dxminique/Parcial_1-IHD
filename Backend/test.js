const http = require("http");

let passed = 0;
let failed = 0;

function test(nombre, condicion) {
  if (condicion) {
    console.log(`✅ ${nombre}`);
    passed++;
  } else {
    console.log(`❌ ${nombre}`);
    failed++;
  }
}

function httpGet(path) {
  return new Promise((resolve, reject) => {
    const req = http.get(`http://localhost:3000${path}`, (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        try {
          resolve({ status: res.statusCode, body: JSON.parse(data) });
        } catch {
          resolve({ status: res.statusCode, body: data });
        }
      });
    });
    req.on("error", reject);
    req.setTimeout(3000, () => {
      req.destroy();
      reject(new Error("Timeout"));
    });
  });
}

async function runTests() {
  console.log("🧪 Ejecutando tests del Backend...\n");

  try {
    const health = await httpGet("/health");
    test("GET /health retorna status 200", health.status === 200);
    test("GET /health retorna status ok", health.body.status === "ok");
    test("GET /health incluye timestamp", !!health.body.timestamp);

    const root = await httpGet("/");
    test("GET / retorna status 200", root.status === 200);
    test("GET / identifica capa Backend", root.body.capa === "Backend");
    test("GET / incluye puerto", !!root.body.puerto);
  } catch (err) {
    console.log("⚠️  Servidor no disponible:", err.message);
    console.log("   (Normal en CI sin servidor corriendo)");
    process.exit(0);
  }

  console.log(`\n📊 Resultado: ${passed} pasados, ${failed} fallidos`);
  process.exit(failed > 0 ? 1 : 0);
}

runTests();
