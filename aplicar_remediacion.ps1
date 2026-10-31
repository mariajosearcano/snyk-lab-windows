# Aplica la version corregida sobre el proyecto (para generar el "DESPUES").
# Usalo SOLO despues de hacer el escaneo inicial y el commit "antes".
# Uso:  .\aplicar_remediacion.ps1
$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

Write-Host "[1/4] Copiando codigo corregido..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path "lib" | Out-Null
Copy-Item "remediacion\lib\seguridad.js" "lib\seguridad.js" -Force
Copy-Item "remediacion\app.js" "app.js" -Force
Copy-Item "remediacion\package.json" "package.json" -Force

Write-Host "[2/4] Reinstalando dependencias con versiones seguras..." -ForegroundColor Cyan
if (Test-Path "node_modules")      { Remove-Item "node_modules" -Recurse -Force }
if (Test-Path "package-lock.json") { Remove-Item "package-lock.json" -Force }
npm install
if ($LASTEXITCODE -ne 0) { throw "npm install fallo" }

Write-Host "[3/4] Pruebas funcionales y de seguridad..." -ForegroundColor Cyan
npm test
if ($LASTEXITCODE -ne 0) { throw "Alguna prueba fallo. Revisa la salida." }

Write-Host "[4/4] Listo. Ahora ejecuta:  git diff   |   .\recolectar_evidencias.ps1 despues" -ForegroundColor Green
