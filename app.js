// =====================================================================
//  APLICACIÓN DE LABORATORIO - INTENCIONALMENTE VULNERABLE (ANTES)
//  Práctica 5: Implementación Práctica Snyk CLI - versión Windows
//  NO desplegar en internet. Ejecutar solo en localhost.
// =====================================================================
const express = require("express");
const { DatabaseSync } = require("node:sqlite"); // SQLite incluido en Node 22 (no hay que compilar nada)
const { exec } = require("child_process");
const crypto = require("crypto");
const _ = require("lodash");

const app = express();
app.use(express.json());

// ---------------------------------------------------------------------
// [VULN 4 - SAST] Secreto quemado en el código (CWE-798)
// ---------------------------------------------------------------------
const TOKEN_SECRET = "clave-super-secreta-123";

// Base de datos en memoria con datos de prueba (ficticios)
const db = new DatabaseSync(":memory:");
db.exec(`
  CREATE TABLE users (id INTEGER PRIMARY KEY, username TEXT, password TEXT, role TEXT);
  INSERT INTO users (username, password, role) VALUES ('admin', 'Adm1n#Lab', 'admin');
  INSERT INTO users (username, password, role) VALUES ('ana', 'Ana#2026', 'user');
  INSERT INTO users (username, password, role) VALUES ('luis', 'Luis#2026', 'user');
`);

function firmarToken(username) {
  return crypto.createHmac("sha256", TOKEN_SECRET).update(username).digest("hex");
}

app.get("/", (req, res) => {
  res.send("Snyk Lab funcionando. Rutas: POST /login, GET /users?name=, GET /search?q=, GET /ping?host=");
});

// ---------------------------------------------------------------------
// [VULN 1 - SAST] Inyección SQL (CWE-89) -> OWASP A05:2025 Injection
// La entrada del usuario se concatena directamente en la consulta.
// Payload de prueba: {"username":"admin'--","password":"x"}
// ---------------------------------------------------------------------
app.post("/login", (req, res) => {
  const { username, password } = req.body;
  const query =
    "SELECT id, username, role FROM users WHERE username = '" +
    username +
    "' AND password = '" +
    password +
    "'";
  try {
    const row = db.prepare(query).get();
    if (!row) return res.status(401).json({ ok: false, mensaje: "Credenciales inválidas" });
    res.json({ ok: true, usuario: row.username, rol: row.role, token: firmarToken(row.username) });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Misma debilidad en una consulta de búsqueda.
// Payload de prueba: /users?name=' OR '1'='1
// Además usa _.trim de lodash 4.17.20 sobre entrada del usuario
// (función afectada por CVE-2020-28500, ReDoS) -> la dependencia es "reachable".
app.get("/users", (req, res) => {
  const name = _.trim(req.query.name || "");
  const query = "SELECT id, username, role FROM users WHERE username = '" + name + "'";
  try {
    res.json(db.prepare(query).all());
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ---------------------------------------------------------------------
// [VULN 2 - SAST] XSS reflejado (CWE-79) -> OWASP A05:2025 Injection
// Payload de prueba: /search?q=<script>alert('XSS')</script>
// ---------------------------------------------------------------------
app.get("/search", (req, res) => {
  const q = req.query.q || "";
  res.send("<h1>Resultados para: " + q + "</h1><p>No se encontraron productos.</p>");
});

// ---------------------------------------------------------------------
// [VULN 3 - SAST] Inyección de comandos del SO (CWE-78)
// En Windows exec() usa cmd.exe, donde "&" y "|" encadenan comandos.
// Payload de prueba (solo local): /ping?host=127.0.0.1 %26 whoami
// ---------------------------------------------------------------------
const PING_COUNT = process.platform === "win32" ? "-n" : "-c";
app.get("/ping", (req, res) => {
  const host = req.query.host || "127.0.0.1";
  exec("ping " + PING_COUNT + " 1 " + host, (err, stdout, stderr) => {
    res.type("text/plain").send(stdout || stderr || (err && err.message));
  });
});

const PORT = process.env.PORT || 3000;
if (require.main === module) {
  // Se escucha SOLO en localhost para no exponer el laboratorio a la red.
  app.listen(PORT, "127.0.0.1", () => console.log(`Snyk Lab (VULNERABLE) en http://127.0.0.1:${PORT}`));
}

module.exports = app;
