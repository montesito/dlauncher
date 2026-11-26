# DLauncher - Browser Engine
# Detección de navegadores instalados y sus perfiles, y construcción de la línea de lanzamiento

$Global:DLauncherBrowserCache = $null
$Global:DLauncherProfileCache = @{}

# Navegadores compatibles (claves válidas en la configuración)
$Global:DLauncherKnownBrowserKeys = @('edge', 'chrome', 'brave', 'firefox')

# Un perfil solo se pasa al navegador si no puede inyectar argumentos (sin comillas, sin "-" inicial ni caracteres de control)
function Test-DLauncherSafeProfileId {
    param ([string]$ProfileId)
    if ([string]::IsNullOrEmpty($ProfileId)) { return $true }
    return ($ProfileId.Length -le 128 -and $ProfileId -notmatch '["\x00-\x1F]' -and -not $ProfileId.TrimStart().StartsWith('-'))
}

# Devuelve los navegadores compatibles instalados en el equipo (resultado cacheado)
function Get-DLauncherBrowsers {
    if ($null -ne $Global:DLauncherBrowserCache) {
        return $Global:DLauncherBrowserCache
    }

    $pf = $env:ProgramFiles
    $pf86 = ${env:ProgramFiles(x86)}
    $la = $env:LOCALAPPDATA

    $catalog = @(
        @{ Key = 'edge'; Name = 'Microsoft Edge'; Short = 'Edge'; Exe = 'msedge.exe'; Kind = 'chromium'
           UserData = (Join-Path $la 'Microsoft\Edge\User Data')
           Fallbacks = @("$pf86\Microsoft\Edge\Application\msedge.exe", "$pf\Microsoft\Edge\Application\msedge.exe") },
        @{ Key = 'chrome'; Name = 'Google Chrome'; Short = 'Chrome'; Exe = 'chrome.exe'; Kind = 'chromium'
           UserData = (Join-Path $la 'Google\Chrome\User Data')
           Fallbacks = @("$pf\Google\Chrome\Application\chrome.exe", "$pf86\Google\Chrome\Application\chrome.exe", "$la\Google\Chrome\Application\chrome.exe") },
        @{ Key = 'brave'; Name = 'Brave'; Short = 'Brave'; Exe = 'brave.exe'; Kind = 'chromium'
           UserData = (Join-Path $la 'BraveSoftware\Brave-Browser\User Data')
           Fallbacks = @("$pf\BraveSoftware\Brave-Browser\Application\brave.exe", "$la\BraveSoftware\Brave-Browser\Application\brave.exe") },
        @{ Key = 'firefox'; Name = 'Mozilla Firefox'; Short = 'Firefox'; Exe = 'firefox.exe'; Kind = 'firefox'
           UserData = (Join-Path $env:APPDATA 'Mozilla\Firefox')
           Fallbacks = @("$pf\Mozilla Firefox\firefox.exe", "$pf86\Mozilla Firefox\firefox.exe") }
    )

    $found = [System.Collections.ArrayList]::new()
    foreach ($c in $catalog) {
        $path = Find-DLauncherAppPath -Exe $c.Exe -Fallbacks $c.Fallbacks
        if ($null -ne $path) {
            $null = $found.Add([PSCustomObject]@{
                Key      = $c.Key
                Name     = $c.Name
                Short    = $c.Short
                Kind     = $c.Kind
                Path     = $path
                UserData = $c.UserData
            })
        }
    }

    $Global:DLauncherBrowserCache = @($found)
    return $Global:DLauncherBrowserCache
}

# Obtiene un navegador por su clave (edge, chrome, brave, firefox)
function Get-DLauncherBrowser {
    param ([string]$Key)
    if ([string]::IsNullOrEmpty($Key)) { return $null }
    return (Get-DLauncherBrowsers | Where-Object { $_.Key -eq $Key } | Select-Object -First 1)
}

# Lista los perfiles de usuario de un navegador: Id (carpeta/nombre interno) y Name (nombre visible)
function Get-DLauncherBrowserProfiles {
    param ([string]$Key)

    if ($Global:DLauncherProfileCache.ContainsKey($Key)) {
        return $Global:DLauncherProfileCache[$Key]
    }

    $browser = Get-DLauncherBrowser -Key $Key
    $profiles = [System.Collections.ArrayList]::new()

    if ($null -ne $browser) {
        if ($browser.Kind -eq 'chromium') {
            # Chromium guarda los perfiles en "Local State" -> profile.info_cache
            $localState = Join-Path $browser.UserData 'Local State'
            if (Test-Path -LiteralPath $localState) {
                try {
                    Add-Type -AssemblyName System.Web.Extensions
                    $serializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
                    $serializer.MaxJsonLength = [int]::MaxValue
                    $state = $serializer.DeserializeObject([System.IO.File]::ReadAllText($localState))
                    $cache = $state['profile']['info_cache']
                    foreach ($dir in $cache.Keys) {
                        $display = [string]$cache[$dir]['name']
                        if ([string]::IsNullOrWhiteSpace($display)) { $display = $dir }
                        $null = $profiles.Add([PSCustomObject]@{ Id = [string]$dir; Name = $display })
                    }
                } catch {
                    # Local State ilegible o bloqueado: sin perfiles detectados
                }
            }
        } elseif ($browser.Kind -eq 'firefox') {
            # Firefox declara los perfiles en profiles.ini
            $ini = Join-Path $browser.UserData 'profiles.ini'
            if (Test-Path -LiteralPath $ini) {
                foreach ($line in (Get-Content -LiteralPath $ini -ErrorAction SilentlyContinue)) {
                    if ($line -match '^\s*Name\s*=\s*(.+)$') {
                        $n = $Matches[1].Trim()
                        $null = $profiles.Add([PSCustomObject]@{ Id = $n; Name = $n })
                    }
                }
            }
        }
    }

    $result = @($profiles | Sort-Object Name)
    $Global:DLauncherProfileCache[$Key] = $result
    return $result
}

# Etiqueta legible "Chrome · Trabajo" para mostrar en el listado
function Get-DLauncherBrowserLabel {
    param (
        [string]$Key,
        [string]$ProfileId
    )
    if ([string]::IsNullOrEmpty($Key)) { return "" }
    $browser = Get-DLauncherBrowser -Key $Key
    $label = if ($null -ne $browser) { $browser.Short } else { "$Key ($(T 'browser.notInstalled'))" }
    if (-not [string]::IsNullOrEmpty($ProfileId)) {
        $profileName = $ProfileId
        if ($null -ne $browser) {
            $match = Get-DLauncherBrowserProfiles -Key $Key | Where-Object { $_.Id -eq $ProfileId } | Select-Object -First 1
            if ($null -ne $match) { $profileName = $match.Name }
        }
        $label = "$label · $profileName"
    }
    return $label
}

# Construye el ejecutable y argumentos para abrir una URL en un navegador y perfil concretos
# Devuelve $null si el navegador no está instalado (el llamador usará el navegador predeterminado)
function Get-DLauncherBrowserLaunch {
    param (
        [string]$Key,
        [string]$ProfileId,
        [string]$Url
    )
    $browser = Get-DLauncherBrowser -Key $Key
    if ($null -eq $browser) { return $null }
    if (-not (Test-DLauncherSafeProfileId -ProfileId $ProfileId)) { $ProfileId = "" }

    $safeUrl = $Url.Replace('"', '%22')
    $arguments = ""
    if ($browser.Kind -eq 'chromium') {
        if (-not [string]::IsNullOrEmpty($ProfileId)) {
            $arguments = "--profile-directory=""$ProfileId"" "
        }
        $arguments += """$safeUrl"""
    } else {
        if (-not [string]::IsNullOrEmpty($ProfileId)) {
            $arguments = "-P ""$ProfileId"" "
        }
        $arguments += "-new-tab ""$safeUrl"""
    }

    return [PSCustomObject]@{
        File      = $browser.Path
        Arguments = $arguments
    }
}
