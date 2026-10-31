# Guía paso a paso — Práctica 5: Snyk CLI (WINDOWS)

> ⚠️ Esta app es **intencionalmente vulnerable**. Ejecútala solo en tu PC, en `127.0.0.1`.
> Si el docente te entregó su propio proyecto de laboratorio, úsalo a él como objetivo y usa
> este como guía de qué hacer en cada fase.

Todo se hace en **PowerShell** (botón Inicio → escribe *PowerShell* → Enter).
📸 = toma una captura de pantalla (tecla `Windows + Shift + S`).

## Qué hay en la carpeta

| Archivo | Para qué sirve |
|---|---|
| `app.js` | La app vulnerable (ANTES): SQLi, XSS, inyección de comandos y secreto quemado. |
| `package.json` | Dependencias vulnerables: `lodash 4.17.20` y `express 4.17.1`. |
| `remediacion\` | La versión corregida (DESPUÉS). |
| `test\` | Pruebas: funcionales (deben pasar siempre) y de seguridad (fallan ANTES, pasan DESPUÉS). |
| `demo_ataques.js` | Lanza los ataques contra tu app local y muestra el resultado (`npm run ataques`). |
| `recolectar_evidencias.ps1` | Corre todos los comandos Snyk y guarda las salidas en `evidencias\`. |
| `aplicar_remediacion.ps1` | Copia la versión corregida, reinstala dependencias y corre las pruebas. |
| `.githooks\`, `.semgrep.yml`, `eslint.config.js`, `.cursorrules`, `.github\` | Controles Shift-Left. |
| `SECURITY_LAB_REPORT.md` | Plantilla del entregable con el análisis técnico ya escrito. |

---

## Fase 0 — Instalar lo necesario (una sola vez)

En PowerShell:

```powershell
winget install --id OpenJS.NodeJS.LTS -e
winget install --id Git.Git -e
```

**Cierra PowerShell y ábrelo de nuevo** (para que reconozca `node`, `npm` y `git`). Comprueba:

```powershell
node -v      # debe ser 22.13 o mayor
npm -v
git --version
```

> Si `winget` no existe, descarga los instaladores de nodejs.org (versión LTS) y git-scm.com.

Configura tu nombre en Git (solo la primera vez):

```powershell
git config --global user.name "María José Arcila Cano"
git config --global user.email "tu-correo@ejemplo.com"
```

**Permite ejecutar los scripts `.ps1`** (solo en esta ventana; no cambia nada permanente):

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

> Tendrás que repetir esta línea cada vez que abras una ventana nueva de PowerShell.

## Fase 1 — Instalar y autenticar Snyk

```powershell
npm install -g snyk
snyk --version                    # 📸
snyk auth                         # se abre el navegador → inicia sesión → "Authenticate"
snyk whoami --experimental        # 📸 (TAPA tu correo/usuario antes de entregar)
```

> En las versiones actuales del CLI, `whoami` exige `--experimental`.
> Si el docente pidió usar token: `$env:SNYK_TOKEN = "xxxx"` (solo vive en esa ventana; nunca lo
> escribas en archivos del proyecto).

**Activa Snyk Code** (si no, `snyk code test` falla): en app.snyk.io →
**Settings → Snyk Code → Enable Snyk Code → Save changes**.

## Fase 2 — Preparar el proyecto y guardar el "ANTES"

1. Descomprime `snyk-lab-windows.zip` en, por ejemplo, `Documentos`.
2. En PowerShell:

```powershell
cd $HOME\Documents\snyk-lab-windows
npm install
git init
git add .
git commit -m "Estado inicial vulnerable (ANTES)"
```

> Al instalar verás avisos `npm warn deprecated` y "X vulnerabilities". Es **normal**: la app es
> vulnerable a propósito. **No** ejecutes `npm audit fix`, porque arreglaría lo que debes analizar.

## Fase 3 — Probar la app y la explotación controlada (solo localhost)

**Ventana 1** de PowerShell:

```powershell
cd $HOME\Documents\snyk-lab-windows
npm start
```

Verás `Snyk Lab (VULNERABLE) en http://127.0.0.1:3000`. Puede aparecer un aviso
`ExperimentalWarning: SQLite is an experimental feature`: es normal (es el SQLite que trae Node).

**Ventana 2** de PowerShell:

```powershell
cd $HOME\Documents\snyk-lab-windows
npm run ataques           # 📸
```

Qué debes ver (eso prueba que la app es vulnerable):

| Ataque | Resultado ANTES |
|---|---|
| 1) SQLi `admin'--` | `200` y `"usuario":"admin"` → entró **sin contraseña** |
| 1b) SQLi `' OR '1'='1` | devuelve **los 3 usuarios** |
| 2) XSS | la respuesta contiene `<script>` sin codificar |
| 3) Inyección de comandos | al final aparece tu usuario de Windows (`tu-pc\tu-usuario`): se ejecutó `whoami` |

**XSS en el navegador** (📸): abre en Edge o Chrome
`http://127.0.0.1:3000/search?q=<script>alert('XSS')</script>` → sale una ventana de alerta.

Vuelve a la **Ventana 1**, detén la app con `Ctrl + C` y corre las pruebas:

```powershell
npm test     # 📸 Esperado: pass 5 / fail 4 → las vulnerabilidades existen
```

## Fase 4 — Escaneos Snyk (ANTES)

```powershell
.\recolectar_evidencias.ps1 antes
```

Ejecuta `snyk test`, `snyk test --severity-threshold=high`, `snyk code test` y `npm ls`, y guarda todo
en `evidencias\antes\`. 📸 Captura cada escaneo en pantalla.

> `snyk monitor` solo si el docente lo pide: sube un "snapshot" del proyecto a tu cuenta Snyk.

## Fase 5 — Elegir las 3 vulnerabilidades (sugerencia)

| # | Hallazgo | Tipo | Dónde |
|---|---|---|---|
| 1 | Inyección SQL | SAST | `app.js` líneas 44–51 y 64–67 |
| 2 | lodash 4.17.20 (CVE-2021-23337 y otros) | SCA | `package.json` (dependencia directa) |
| 3 | Inyección de comandos | SAST | `app.js` línea 90 |

Alternativas si Snyk no reporta alguna: XSS (`app.js` línea 79), secreto quemado (línea 18) o una
dependencia **transitiva** de express 4.17.1 (por ejemplo `qs`, `path-to-regexp`, `body-parser`).
Usa SIEMPRE los datos exactos que te muestre Snyk (severidad, línea, CVE, versión de arreglo).

## Fase 6 — Remediar

```powershell
.\aplicar_remediacion.ps1        # 📸 al final: pass 9 / fail 0
git diff --stat                  # 📸
git diff | Out-File evidencias\diff_remediacion.txt -Encoding utf8
git add .
git commit -m "Remediacion: SQLi, XSS, command injection, secreto y dependencias"
```

Vuelve a probar los ataques (📸): **Ventana 1** `npm start` → **Ventana 2** `npm run ataques`.
Ahora deben salir `400 Entrada inválida`, `400 Nombre inválido`, el `<script>` como
`&lt;script&gt;` y `400 Host inválido`.

## Fase 7 — Verificar (reescaneo obligatorio)

```powershell
.\recolectar_evidencias.ps1 despues
```

Compara `evidencias\antes\` con `evidencias\despues\`. Si queda algún hallazgo, **no lo ocultes**:
explica en el informe por qué permanece y qué mitigación hay.

## Fase 8 — Shift-Left (prevención)

```powershell
git config core.hooksPath .githooks     # activa el hook pre-commit
npm run lint                            # 📸 ESLint + plugin de seguridad
```

> El hook es un script bash: Git para Windows lo ejecuta solo con su propio bash, no tienes que hacer nada más.

**Semgrep (opcional)**: ya funciona nativo en Windows. Si tienes Python:

```powershell
pip install semgrep
semgrep --config .semgrep.yml .         # 📸 sobre el código corregido no debe reportar errores
```

**Demostración del bloqueo** (📸): mete a propósito un secreto y trata de hacer commit:

```powershell
Add-Content app.js 'const API_TOKEN = "abc123456789";'
git add app.js
git commit -m "prueba"          # el hook debe BLOQUEAR el commit
git checkout app.js             # deshace el cambio
```

**Quality Gate en CI/CD** (opcional pero suma): sube el repo a GitHub, crea el secreto `SNYK_TOKEN`
(Settings → Secrets and variables → Actions) y `.github\workflows\security.yml` correrá en cada
Pull Request. Para **bloquear PRs**: Settings → Branches → regla para `main` →
"Require status checks to pass" → marca los jobs del workflow.

## Fase 9 — Informe

Completa `SECURITY_LAB_REPORT.md` (puedes abrirlo con VS Code o el Bloc de notas): reemplaza cada
`[PEGAR ...]` con tus salidas y capturas, y revisa que severidad, CVSS y líneas coincidan con lo que
**tu** Snyk reportó.

## Problemas comunes

| Problema | Solución |
|---|---|
| `no se puede cargar ... porque la ejecución de scripts está deshabilitada` | `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` |
| `node` / `snyk` no se reconoce | Cierra y abre PowerShell. Si sigue, reinstala Node LTS. |
| `No such built-in module: node:sqlite` | Tu Node es viejo: instala la versión LTS actual (22.13 o mayor). |
| `EADDRINUSE :3000` | Ya hay una app abierta: ciérrala con `Ctrl + C` o usa `$env:PORT=3001; npm start`. |
| `snyk code test` dice que no está habilitado | Activa Snyk Code en Settings de app.snyk.io. |
| `snyk auth` no abre el navegador | Copia el enlace que muestra la terminal y pégalo en el navegador. |
