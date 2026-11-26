# DLauncher - Preferences Module
# Preferencias por usuario y equipo: idioma, tema, ventana, barra lateral y aceptación de los términos.
# Se guardan en %LOCALAPPDATA%\DLauncher\prefs.json, independientes de la carpeta de configuración
# (que puede estar sincronizada entre equipos).

$Global:DLauncherAppDataDir = Join-Path -Path $env:LOCALAPPDATA -ChildPath "DLauncher"
$Global:DLauncherPrefsFile = Join-Path -Path $Global:DLauncherAppDataDir -ChildPath "prefs.json"
$Global:DLauncherPrefs = @{}

function Global:Read-DLauncherPrefs {
    $prefs = @{}
    try {
        if (Test-Path -LiteralPath $Global:DLauncherPrefsFile) {
            $obj = ConvertFrom-Json -InputObject ([System.IO.File]::ReadAllText($Global:DLauncherPrefsFile))
            if ($null -ne $obj) {
                foreach ($p in $obj.PSObject.Properties) { $prefs[$p.Name] = $p.Value }
            }
        }
    } catch {
        # Preferencias ilegibles: se usan los valores por defecto
    }

    # Migración: versiones anteriores guardaban el idioma en language.txt
    if (-not $prefs.ContainsKey('Language')) {
        $legacy = Join-Path -Path $Global:DLauncherAppDataDir -ChildPath 'language.txt'
        try {
            if (Test-Path -LiteralPath $legacy) {
                $prefs['Language'] = ([System.IO.File]::ReadAllText($legacy)).Trim()
            }
        } catch { }
    }
    $Global:DLauncherPrefs = $prefs
}

function Global:Get-DLauncherPref {
    param ([string]$Name, $Default = $null)
    if ($Global:DLauncherPrefs.ContainsKey($Name) -and $null -ne $Global:DLauncherPrefs[$Name]) {
        return $Global:DLauncherPrefs[$Name]
    }
    return $Default
}

function Global:Set-DLauncherPref {
    param ([string]$Name, $Value)
    $Global:DLauncherPrefs[$Name] = $Value
    try {
        if (-not (Test-Path -LiteralPath $Global:DLauncherAppDataDir)) {
            $null = New-Item -ItemType Directory -Path $Global:DLauncherAppDataDir -Force
        }
        $json = [PSCustomObject]$Global:DLauncherPrefs | ConvertTo-Json -Depth 4
        [System.IO.File]::WriteAllText($Global:DLauncherPrefsFile, $json, (New-Object System.Text.UTF8Encoding($false)))
    } catch {
        # Sin permisos de escritura: el cambio se aplica solo a esta sesión
    }
}

Read-DLauncherPrefs
