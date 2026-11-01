# Aplica la version corregida sobre el proyecto (para generar el "DESPUES").
# Usalo SOLO despues de hacer el escaneo inicial y el commit "antes".
# Uso (en PowerShell, dentro de esta carpeta):
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#   .\aplicar_remediacion.ps1
# No lo abras con doble clic: la ventana se cierra y no se ve el error.
$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

$log = Join-Path $PSScriptRoot "evidencias\aplicar_remediacion.log"
New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null

function Write-Log([string]$msg) {
    Add-Content -Path $log -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $msg" -Encoding utf8
}

function Wait-IfStandalone {
    $fromExplorer = [Environment]::GetCommandLineArgs() | Where-Object { $_ -ieq "-File" -or $_ -ieq "/File" }
    if ($fromExplorer) {
        Write-Host ""
        Read-Host "Pulsa Enter para cerrar esta ventana"
    }
}

try {
    Write-Log "Inicio"
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
    Write-Log "OK"
    Wait-IfStandalone
} catch {
    $detalle = $_.Exception.Message
    Write-Host ""
    Write-Host "ERROR: $detalle" -ForegroundColor Red
    if ($_.ScriptStackTrace) {
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    }
    Write-Log "ERROR: $detalle"
    Write-Host ""
    Write-Host "Copia de este error: evidencias\aplicar_remediacion.log" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Pulsa Enter para cerrar"
    exit 1
}
