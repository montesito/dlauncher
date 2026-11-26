# DLauncher - Script de Compilación / Bundler
# Une todos los módulos .ps1 de la estructura profesional en un único script autoejecutable y compila a .EXE

$ErrorActionPreference = "Stop"

# Configurar la codificación de la consola y salida a UTF-8 para soportar eñes y acentos en cualquier equipo
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8


# Directorios de origen y destino
$WorkspaceDir = $PSScriptRoot
if ([string]::IsNullOrEmpty($WorkspaceDir)) {
    $WorkspaceDir = Get-Location
}
$SrcDir = Join-Path -Path $WorkspaceDir -ChildPath "src"
$BinDir = Join-Path -Path $WorkspaceDir -ChildPath "bin"

# Crear directorio bin si no existe
if (-not (Test-Path -Path $BinDir)) {
    $null = New-Item -ItemType Directory -Path $BinDir -Force
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "          DLauncher Build System 2026" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Unir los archivos de código fuente respetando la nueva arquitectura
Write-Host "[1/3] Generando script consolidado de producción..." -ForegroundColor Yellow

# Módulos en orden de carga (dependencias primero). Main.ps1 siempre va al final
$moduleFiles = @(
    "Utils\Preferences.ps1",
    "Utils\Localization.ps1",
    "Utils\FileUtils.ps1",
    "Config\DLauncherConfig.ps1",
    "Core\BrowserEngine.ps1",
    "Core\IconService.ps1",
    "Core\LauncherEngine.ps1",
    "Core\SuggestionCatalog.ps1",
    "UI\DLauncherThemes.ps1",
    "UI\DLauncherStyles.ps1",
    "UI\DLauncherUI.ps1"
)
$mainFile = Join-Path -Path $SrcDir -ChildPath "Main.ps1"
$outputPs1 = Join-Path -Path $BinDir -ChildPath "DLauncher.ps1"

# Verificar existencia de archivos
$missingFiles = @()
foreach ($file in (@($moduleFiles | ForEach-Object { Join-Path -Path $SrcDir -ChildPath $_ }) + $mainFile)) {
    if (-not (Test-Path -Path $file)) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Error "Faltan los siguientes archivos en la arquitectura del proyecto:`n$( $missingFiles -join "`n" )"
}

# Leer contenidos de módulos garantizando UTF-8
$moduleSections = foreach ($rel in $moduleFiles) {
    $content = Get-Content -Path (Join-Path -Path $SrcDir -ChildPath $rel) -Raw -Encoding UTF8
    "# --- MÓDULO: $rel ---`r`n$content"
}
$mainContent = Get-Content -Path $mainFile -Raw -Encoding UTF8

# Versión única: se toma de Main.ps1 ($Global:DLauncherVersion)
$appVersion = "0.0.0"
if ($mainContent -match '\$Global:DLauncherVersion\s*=\s*"([0-9.]+)"') { $appVersion = $Matches[1] }
Write-Host "      Versión: $appVersion" -ForegroundColor Green

# Comentar la carga local de módulos (. (Join-Path ...)) en Main.ps1: ya van incluidos en el consolidado
$filteredMainContent = $mainContent -replace "(?m)^(\s*)\.\s*\(Join-Path.*\.ps1.*$", '$1# (Cargado en consolidado)'

# Construir el archivo consolidado
$mergedContent = @"
# ====================================================================
# DLauncher - Lanzador Diario de Herramientas y Aplicaciones
# Archivo Auto-contenido y Autoejecutable - Generado el $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")
# 2026. DLauncher. by @montesito
# ====================================================================

$($moduleSections -join "`r`n`r`n")

# --- PUNTO DE ENTRADA PRINCIPAL ---
$filteredMainContent
"@

# Escribir el archivo consolidado con codificación UTF-8 con BOM para máxima compatibilidad nativa en Windows PowerShell 5.1
[System.IO.File]::WriteAllText($outputPs1, $mergedContent, [System.Text.Encoding]::UTF8)
Write-Host "      Hecho: script de producción creado en '$outputPs1'" -ForegroundColor Green

# 2. Verificar e instalar ps2exe si no está disponible
Write-Host ""
Write-Host "[2/3] Comprobando entorno de compilación ps2exe..." -ForegroundColor Yellow

$localPs2exePath = Join-Path -Path (Join-Path -Path $WorkspaceDir -ChildPath "tools") -ChildPath "ps2exe.ps1"
if (Test-Path $localPs2exePath) {
    Write-Host "      Cargando ps2exe local desde '$localPs2exePath'..." -ForegroundColor Green
    try {
        . $localPs2exePath
        if (Get-Command Invoke-ps2exe -ErrorAction SilentlyContinue) {
            $hasPs2exe = $true
            $compileCommand = "Invoke-ps2exe"
        }
    } catch {
        Write-Warning "No se pudo cargar ps2exe local: $_"
    }
}

if (-not $hasPs2exe) {
    if (Get-Command ps2exe -ErrorAction SilentlyContinue) {
        $hasPs2exe = $true
        $compileCommand = "ps2exe"
    } elseif (Get-Module -ListAvailable -Name ps2exe) {
        $hasPs2exe = $true
        Import-Module ps2exe
        $compileCommand = "Invoke-ps2exe"
    } else {
        Write-Host "      ps2exe no encontrado. Instalando desde PSGallery..." -ForegroundColor Yellow
        try {
            Install-Module -Name ps2exe -Scope CurrentUser -Force -AllowClobber
            Import-Module ps2exe
            $hasPs2exe = $true
            $compileCommand = "Invoke-ps2exe"
            Write-Host "      ps2exe instalado correctamente." -ForegroundColor Green
        } catch {
            Write-Warning "No se pudo instalar ps2exe automáticamente: $_"
        }
    }
}

if ($hasPs2exe) {
    Write-Host "      ps2exe detectado correctamente en el sistema." -ForegroundColor Green
    
    # Ruta del icono de la aplicación
    $iconPath = Join-Path -Path $SrcDir -ChildPath "Assets\logo.ico"
    if (-not (Test-Path $iconPath)) {
        Write-Warning "No se encontró el icono en '$iconPath'. Compilando sin icono personalizado."
        $iconPath = $null
    } else {
        Write-Host "      Icono encontrado: $iconPath" -ForegroundColor Green
    }
    
    # 3. Compilar a EXE
    Write-Host ""
    Write-Host "[3/3] Compilando a ejecutable standalone (.EXE)..." -ForegroundColor Yellow
    $outputExe = Join-Path -Path $BinDir -ChildPath "DLauncher.exe"
    
    $compileParams = @{
        inputFile   = $outputPs1
        outputFile  = $outputExe
        title       = "DLauncher"
        description = "Lanzador de aplicaciones y herramientas de trabajo diario"
        company     = "montesito"
        product     = "DLauncher"
        copyright   = "2026. DLauncher. by @montesito"
        version     = $appVersion
        noConsole   = $true
        requireAdmin = $false
    }
    if ($null -ne $iconPath) {
        $compileParams["iconFile"] = $iconPath
    }
    
    try {
        if ($compileCommand -eq "ps2exe") {
            ps2exe @compileParams
        } else {
            Invoke-ps2exe @compileParams
        }
        Write-Host ""
        Write-Host "==================================================" -ForegroundColor Green
        Write-Host "  ¡Compilación completada con éxito!" -ForegroundColor Green
        Write-Host "  Ejecutable: $outputExe" -ForegroundColor Green
        Write-Host "  Icono integrado: $(if ($iconPath) { 'Sí - logo.ico' } else { 'No' })" -ForegroundColor Green
        Write-Host "==================================================" -ForegroundColor Green
    } catch {
        Write-Warning "Ocurrió un error al compilar con ps2exe: $_"
        Write-Host "Puedes compilar el archivo '$outputPs1' manualmente más tarde." -ForegroundColor Yellow
    }
} else {
    Write-Host "      ps2exe no disponible. Instálalo con:" -ForegroundColor Cyan
    Write-Host "      Install-Module -Name ps2exe -Scope CurrentUser -Force" -ForegroundColor White
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Yellow
    Write-Host "Script consolidado listo en: $outputPs1" -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor Yellow
}
