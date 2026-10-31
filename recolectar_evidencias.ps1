# Ejecuta los analisis de Snyk y guarda TODO en la carpeta evidencias\
# Uso (en PowerShell, dentro de la carpeta del proyecto):
#     .\recolectar_evidencias.ps1 antes
#     .\recolectar_evidencias.ps1 despues
param([string]$Etapa = "antes")

Set-Location -Path $PSScriptRoot
$Dir = Join-Path "evidencias" $Etapa
New-Item -ItemType Directory -Force -Path $Dir | Out-Null

function Guardar($nombre, [scriptblock]$comando) {
    # Muestra la salida en pantalla y la guarda en UTF-8
    & $comando 2>&1 | Tee-Object -Variable salida | Out-Host
    $salida | Out-File -FilePath (Join-Path $Dir $nombre) -Encoding utf8
}

Write-Host "== Entorno ==" -ForegroundColor Cyan
Guardar "00_entorno.txt" {
    try   { $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop; "Sistema:   " + $os.Caption + " " + $os.Version }
    catch { "Sistema:   " + [System.Environment]::OSVersion.VersionString }
    "PowerShell: " + $PSVersionTable.PSVersion
    "Node:      " + (node -v)
    "npm:       " + (npm -v)
    "Snyk CLI:  " + (snyk --version)
    "Fecha:     " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}

Write-Host "`n== SCA: snyk test ==" -ForegroundColor Cyan
Guardar "01_snyk_test.txt" { snyk test }
snyk test --json | Out-File -FilePath (Join-Path $Dir "01_snyk_test.json") -Encoding utf8

Write-Host "`n== SCA: snyk test --severity-threshold=high ==" -ForegroundColor Cyan
Guardar "02_snyk_test_high.txt" { snyk test --severity-threshold=high }

Write-Host "`n== SAST: snyk code test ==" -ForegroundColor Cyan
Guardar "03_snyk_code_test.txt" { snyk code test }
snyk code test --json | Out-File -FilePath (Join-Path $Dir "03_snyk_code_test.json") -Encoding utf8

Write-Host "`n== Arbol de dependencias (directa vs transitiva) ==" -ForegroundColor Cyan
npm ls --all 2>&1 | Out-File -FilePath (Join-Path $Dir "04_npm_ls.txt") -Encoding utf8
Guardar "04_npm_ls_resumen.txt" { npm ls lodash express }

Write-Host "`nEvidencias guardadas en $Dir" -ForegroundColor Green
Write-Host "Nota: snyk termina con codigo 1 cuando encuentra vulnerabilidades; eso es normal."
