const express = require("express");
const mysql = require("mysql2");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());


const db = mysql.createConnection({
  host:     process.env.DB_HOST     || "10.0.2.20",
  port:     process.env.DB_PORT     || 3306,
  user:     process.env.DB_USER     || "admin",
  password: process.env.DB_PASSWORD || "password123",
  database: process.env.DB_NAME     || "innovatech",
});

db.connect((err) => {
  if (err) {
    console.error("❌ No se pudo conectar a la base de datos:", err.message);
  } else {
    console.log("✅ Conexión a MySQL establecida");
  }
});



app.get("/health", (req, res) => {
  res.json({
    status: "ok",
    servicio: "Backend Innovatech",
    timestamp: new Date().toISOString(),
  });
});


app.get("/", (req, res) => {
  res.json({
    mensaje: "🚀 Backend Innovatech corriendo",
    capa: "Backend",
    puerto: PORT,
    version: "1.0.0",
  });
});


app.get("/db-status", (req, res) => {
  db.ping((err) => {
    if (err) {
      return res.status(500).json({
        status: "error",
        mensaje: "No se puede alcanzar la base de datos",
        detalle: err.message,
      });
    }
    res.json({
      status: "ok",
      mensaje: "✅ Base de datos alcanzable desde Backend",
      host: process.env.DB_HOST || "10.0.2.20",
    });
  });
});


app.get("/usuarios", (req, res) => {
  const createTable = `
    CREATE TABLE IF NOT EXISTS usuarios (
      id INT AUTO_INCREMENT PRIMARY KEY,
      nombre VARCHAR(100) NOT NULL,
      email VARCHAR(100) NOT NULL,
      creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `;
  db.query(createTable, (err) => {
    if (err) return res.status(500).json({ error: err.message });

    db.query("SELECT * FROM usuarios", (err, results) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ total: results.length, usuarios: results });
    });
  });
});


app.post("/usuarios", (req, res) => {
  const { nombre, email } = req.body;
  if (!nombre || !email) {
    return res.status(400).json({ error: "nombre y email son requeridos" });
  }
  db.query(
    "INSERT INTO usuarios (nombre, email) VALUES (?, ?)",
    [nombre, email],
    (err, result) => {
      if (err) return res.status(500).json({ error: err.message });
      res.status(201).json({ mensaje: "Usuario creado", id: result.insertId });
    }
  );
});


app.listen(PORT, "0.0.0.0", () => {
  console.log(`🚀 Backend escuchando en http://0.0.0.0:${PORT}`);
});;