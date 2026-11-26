# DLauncher - Utilities Module
# Resolución de rutas y destinos, búsqueda tolerante e integración con Windows (inicio automático)

$Global:DLauncherDriveTypeCache = @{}
$Global:DLauncherAppPathCache = @{}

# Expande variables de entorno en una ruta (ej. %windir%\notepad.exe -> C:\Windows\notepad.exe)
function Resolve-DLauncherPath {
    param ([string]$Path)
    if ($null -eq $Path) { return "" }
    if ($Path -like "*%*") {
        try {
            return [System.Environment]::ExpandEnvironmentVariables($Path)
        } catch {
            return $Path
        }
    }
    return $Path
}

# Indica si una ruta está en red (UNC o unidad asignada). La interfaz no toca esas rutas
# para no quedarse bloqueada si el recurso no responde
function Test-DLauncherNetworkPath {
    param ([string]$Path)
    if ([string]::IsNullOrEmpty($Path)) { return $false }
    if ($Path.StartsWith('\\') -or $Path.StartsWith('//')) { return $true }
    if ($Path -match '^([a-zA-Z]):') {
        $letter = $Matches[1].ToUpperInvariant()
        if (-not $Global:DLauncherDriveTypeCache.ContainsKey($letter)) {
            $type = 'Unknown'
            try { $type = [string]([System.IO.DriveInfo]::new("$letter`:\").DriveType) } catch { }
            $Global:DLauncherDriveTypeCache[$letter] = $type
        }
        return ($Global:DLauncherDriveTypeCache[$letter] -eq 'Network')
    }
    return $false
}

# Busca un ejecutable registrado en "App Paths" (ej. outlook.exe, winword.exe) y en ubicaciones alternativas
function Find-DLauncherAppPath {
    param (
        [string]$Exe,
        [string[]]$Fallbacks = @()
    )
    $subKeys = @(
        'SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths',
        'SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths'
    )
    foreach ($hive in [Microsoft.Win32.Registry]::CurrentUser, [Microsoft.Win32.Registry]::LocalMachine) {
        foreach ($sub in $subKeys) {
            try {
                $key = $hive.OpenSubKey("$sub\$Exe")
                if ($null -eq $key) { continue }
                try { $value = [string]$key.GetValue('') } finally { $key.Close() }
                if (-not [string]::IsNullOrWhiteSpace($value)) {
                    $value = [System.Environment]::ExpandEnvironmentVariables($value.Trim().Trim('"'))
                    if (Test-Path -LiteralPath $value -PathType Leaf) { return $value }
                }
            } catch {
                # Clave inaccesible: continuar con la siguiente
            }
        }
    }
    foreach ($f in $Fallbacks) {
        if (-not [string]::IsNullOrWhiteSpace($f) -and (Test-Path -LiteralPath $f -PathType Leaf)) {
            return $f
        }
    }
    return $null
}

# Devuelve la ruta absoluta de un ejecutable (ruta directa, PATH del sistema o App Paths), o $null
function Find-DLauncherExecutable {
    param ([string]$ExecutablePath)

    $resolved = Resolve-DLauncherPath -Path $ExecutablePath
    if ([string]::IsNullOrWhiteSpace($resolved)) { return $null }
    $resolved = $resolved.Trim().Trim('"')

    # 1. Ruta directa (LiteralPath: admite corchetes y otros caracteres especiales)
    if (Test-Path -LiteralPath $resolved -PathType Leaf -ErrorAction SilentlyContinue) {
        return $resolved
    }

    # 2. Nombre simple (ej. "notepad", "outlook.exe"): PATH del sistema y registro App Paths
    if ($resolved -notmatch '[\\/:]') {
        if ($Global:DLauncherAppPathCache.ContainsKey($resolved)) {
            return $Global:DLauncherAppPathCache[$resolved]
        }
        $found = $null
        try {
            $cmd = Get-Command -Name $resolved -CommandType Application -ErrorAction Ignore | Select-Object -First 1
            if ($null -ne $cmd -and $cmd.Source -and (Test-Path -LiteralPath $cmd.Source)) {
                $found = $cmd.Source
            }
        } catch { }
        if ($null -eq $found) {
            $exeName = if ($resolved -match '\.exe$') { $resolved } else { "$resolved.exe" }
            $found = Find-DLauncherAppPath -Exe $exeName
        }
        $Global:DLauncherAppPathCache[$resolved] = $found
        return $found
    }

    return $null
}

# Clasifica un destino configurado: Url (web), Path (archivo/carpeta/ejecutable) o Uri (protocolo, ej. ms-teams:)
# Devuelve el destino normalizado y el host en el caso de direcciones web
function Resolve-DLauncherTarget {
    param ([string]$Value)

    $result = [PSCustomObject]@{ Kind = 'None'; Target = ''; Host = '' }
    if ([string]::IsNullOrWhiteSpace($Value)) { return $result }

    $t = Resolve-DLauncherPath -Path $Value.Trim()
    $result.Target = $t

    if ($t -match '^(https?|ftp)://') {
        $result.Kind = 'Url'
    } elseif ($t -match '^www\.') {
        $result.Kind = 'Url'
        $result.Target = "https://$t"
    } elseif ($t -match '^[a-zA-Z]:[\\/]' -or $t -match '^\\\\' -or $t -match '\.(exe|bat|cmd|lnk|msc|ps1|com|cpl|url)$') {
        $result.Kind = 'Path'
    } elseif ($t -notmatch '[\\\s]' -and $t -match '^[a-zA-Z0-9\-]+(\.[a-zA-Z0-9\-]+)*\.[a-zA-Z]{2,}(:\d+)?([/?#].*)?$' -and -not (Test-Path -LiteralPath $t -ErrorAction SilentlyContinue)) {
        # Dominio sin esquema (ej. github.com/org)
        $result.Kind = 'Url'
        $result.Target = "https://$t"
    } elseif ($t -match '^[a-zA-Z][a-zA-Z0-9+\.\-]+:') {
        $result.Kind = 'Uri'
    } else {
        $result.Kind = 'Path'
    }

    if ($result.Kind -eq 'Url') {
        try {
            $result.Host = ([Uri]$result.Target).Host.ToLowerInvariant()
        } catch {
            $result.Host = ''
        }
    }
    return $result
}

# Extensiones que ejecutan código: se avisa al usuario antes de añadirlas o importarlas
$Global:DLauncherScriptExtensions = @('.bat', '.cmd', '.ps1', '.vbs', '.vbe', '.js', '.jse', '.wsf', '.wsh', '.hta', '.msi', '.scr', '.reg')
$Global:DLauncherCodeExtensions = $Global:DLauncherScriptExtensions + @('.exe', '.com', '.lnk', '.msc', '.cpl')

function Test-DLauncherScriptTarget {
    param ([string]$Value)
    $info = Resolve-DLauncherTarget -Value $Value
    if ($info.Kind -ne 'Path') { return $false }
    return ($Global:DLauncherScriptExtensions -contains ([System.IO.Path]::GetExtension($info.Target).ToLowerInvariant()))
}

function Test-DLauncherCodeTarget {
    param ([string]$Value)
    $info = Resolve-DLauncherTarget -Value $Value
    if ($info.Kind -ne 'Path') { return $false }
    $ext = ''
    try { $ext = [System.IO.Path]::GetExtension($info.Target).ToLowerInvariant() } catch { }
    return ($Global:DLauncherCodeExtensions -contains $ext)
}

# Extrae la URL de un acceso directo de Internet (.url)
function Get-DLauncherShortcutUrl {
    param ([string]$Path)
    try {
        $line = Get-Content -LiteralPath $Path -ErrorAction Stop | Where-Object { $_ -match '^\s*URL\s*=' } | Select-Object -First 1
        if ($line) {
            return ($line -replace '^\s*URL\s*=\s*', '').Trim()
        }
    } catch {
        # Archivo ilegible: se ignora
    }
    return $null
}

# Elimina acentos y pasa a minúsculas para búsquedas tolerantes (ej. "busqueda" encuentra "Búsqueda")
function ConvertTo-DLauncherSearchKey {
    param ([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return "" }
    $normalized = $Text.Normalize([System.Text.NormalizationForm]::FormD)
    $sb = New-Object System.Text.StringBuilder
    foreach ($ch in $normalized.ToCharArray()) {
        if ([System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch) -ne [System.Globalization.UnicodeCategory]::NonSpacingMark) {
            $null = $sb.Append($ch)
        }
    }
    return $sb.ToString().ToLowerInvariant()
}

# ===================== INICIO CON WINDOWS =====================

# Ruta del ejecutable compilado (DLauncher.exe), o $null si se ejecuta desde el código fuente
function Get-DLauncherExePath {
    try {
        $path = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        $name = [System.IO.Path]::GetFileName($path).ToLowerInvariant()
        if (@('powershell.exe', 'pwsh.exe', 'powershell_ise.exe') -contains $name) { return $null }
        return $path
    } catch {
        return $null
    }
}

$Global:DLauncherStartupLink = Join-Path -Path ([Environment]::GetFolderPath('Startup')) -ChildPath 'DLauncher.lnk'

function Test-DLauncherRunAtStartup {
    return (Test-Path -LiteralPath $Global:DLauncherStartupLink)
}

# Crea o elimina un acceso directo en la carpeta "Inicio" del usuario (sin tocar el registro)
function Set-DLauncherRunAtStartup {
    param ([bool]$Enabled)
    if ($Enabled) {
        $exe = Get-DLauncherExePath
        if ($null -eq $exe) { throw (T 'startup.unavailable') }
        $shell = New-Object -ComObject WScript.Shell
        try {
            $lnk = $shell.CreateShortcut($Global:DLauncherStartupLink)
            $lnk.TargetPath = $exe
            $lnk.WorkingDirectory = Split-Path -Parent -Path $exe
            $lnk.Description = 'DLauncher'
            $lnk.Save()
        } finally {
            [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($shell)
        }
    } elseif (Test-DLauncherRunAtStartup) {
        Remove-Item -LiteralPath $Global:DLauncherStartupLink -Force
    }
}
