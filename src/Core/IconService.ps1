# DLauncher - Icon Service
# Iconos automáticos: favicons de sitios web (descarga en segundo plano + caché local)
# e iconos nativos de ejecutables y accesos directos

Add-Type -AssemblyName System.Drawing

$Global:DLauncherIconCacheDir = Join-Path -Path $env:LOCALAPPDATA -ChildPath "DLauncher\IconCache"
$Global:DLauncherIconMemory = @{}
$Global:DLauncherFaviconJob = $null
$Global:DLauncherFaviconQueue = New-Object 'System.Collections.Generic.HashSet[string]'
$Global:DLauncherFaviconTimer = $null
$Global:DLauncherFaviconOnComplete = $null
$Global:DLauncherFaviconRetryDays = 3

# Paleta para avatares con inicial (coherente con la identidad Tech Azure / Solar Orange)
$Global:DLauncherAvatarPalette = @('#0070F3', '#FF5500', '#30D158', '#BF5AF2', '#FF375F', '#40C8E0', '#5E5CE6', '#FF9F0A', '#64D2FF', '#AC8E68')

# Color determinista a partir de un texto (el mismo nombre siempre tiene el mismo color)
function Get-DLauncherAvatarColor {
    param ([string]$Seed)
    $hash = 0
    foreach ($ch in ([string]$Seed).ToCharArray()) {
        $hash = ($hash * 31 + [int]$ch) % 1000003
    }
    return $Global:DLauncherAvatarPalette[$hash % $Global:DLauncherAvatarPalette.Count]
}

# Decodifica bytes de imagen (ICO, PNG, GIF, JPEG, BMP) eligiendo el fotograma de mayor resolución
function ConvertTo-DLauncherImageSource {
    param ([byte[]]$Bytes)
    try {
        $ms = [System.IO.MemoryStream]::new($Bytes)
        $decoder = [System.Windows.Media.Imaging.BitmapDecoder]::Create(
            $ms,
            [System.Windows.Media.Imaging.BitmapCreateOptions]::None,
            [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad)
        $best = $null
        foreach ($frame in $decoder.Frames) {
            if ($null -eq $best -or $frame.PixelWidth -gt $best.PixelWidth) {
                $best = $frame
            }
        }
        if ($null -ne $best -and $best.CanFreeze) { $best.Freeze() }
        return $best
    } catch {
        return $null
    }
}

# Icono nativo de un archivo (exe, lnk, bat, documentos...) a través de la shell de Windows
function Get-DLauncherFileIcon {
    param ([string]$Path)
    $key = "file:$Path"
    if ($Global:DLauncherIconMemory.ContainsKey($key)) {
        return $Global:DLauncherIconMemory[$key]
    }
    $source = $null
    try {
        $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($Path)
        if ($null -ne $icon) {
            $source = [System.Windows.Interop.Imaging]::CreateBitmapSourceFromHIcon(
                $icon.Handle,
                [System.Windows.Int32Rect]::Empty,
                [System.Windows.Media.Imaging.BitmapSizeOptions]::FromEmptyOptions())
            $source.Freeze()
            $icon.Dispose()
        }
    } catch {
        $source = $null
    }
    $Global:DLauncherIconMemory[$key] = $source
    return $source
}

# Nombre de archivo seguro para la caché a partir de un host
function Get-DLauncherFaviconKey {
    param ([string]$UrlHost)
    return ($UrlHost.ToLowerInvariant() -replace '[^a-z0-9\.\-]', '_')
}

# Devuelve el favicon cacheado de un host, o $null si aún no se ha descargado
function Get-DLauncherCachedFavicon {
    param ([string]$UrlHost)
    $memKey = "web:$UrlHost"
    if ($Global:DLauncherIconMemory.ContainsKey($memKey)) {
        return $Global:DLauncherIconMemory[$memKey]
    }
    $file = Join-Path $Global:DLauncherIconCacheDir ((Get-DLauncherFaviconKey $UrlHost) + ".img")
    if (Test-Path -LiteralPath $file) {
        $source = ConvertTo-DLauncherImageSource -Bytes ([System.IO.File]::ReadAllBytes($file))
        if ($null -ne $source) {
            $Global:DLauncherIconMemory[$memKey] = $source
            return $source
        }
        # Imagen corrupta o no soportada: descartar y marcar como no disponible
        Remove-Item -LiteralPath $file -Force -ErrorAction SilentlyContinue
        Set-Content -LiteralPath ($file -replace '\.img$', '.none') -Value "" -ErrorAction SilentlyContinue
    }
    return $null
}

# Indica si merece la pena (re)intentar descargar el favicon de un host
function Test-DLauncherFaviconPending {
    param ([string]$UrlHost)
    $base = Join-Path $Global:DLauncherIconCacheDir (Get-DLauncherFaviconKey $UrlHost)
    if (Test-Path -LiteralPath "$base.img") { return $false }
    if (Test-Path -LiteralPath "$base.none") {
        $age = (Get-Date) - (Get-Item -LiteralPath "$base.none").LastWriteTime
        return ($age.TotalDays -ge $Global:DLauncherFaviconRetryDays)
    }
    return $true
}

# Script del trabajador en segundo plano (runspace independiente, no bloquea la interfaz)
$Global:DLauncherFaviconWorker = @'
param([string[]]$Hosts, [string]$CacheDir)

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
} catch { }

# Descarga con límite de tamaño: las páginas se truncan (solo interesa la cabecera <head>)
# y las imágenes demasiado grandes se descartan sin leerlas enteras
function Get-Remote([string]$Url, [int]$MaxBytes, [bool]$Truncate) {
    $req = [Net.HttpWebRequest]::Create($Url)
    $req.Timeout = 6000
    $req.ReadWriteTimeout = 6000
    $req.UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) DLauncher'
    $req.AllowAutoRedirect = $true
    $req.MaximumAutomaticRedirections = 5
    if ($null -ne $req.Proxy) { $req.Proxy.Credentials = [Net.CredentialCache]::DefaultCredentials }
    $resp = $req.GetResponse()
    try {
        if (-not $Truncate -and $resp.ContentLength -gt $MaxBytes) { return $null }
        $stream = $resp.GetResponseStream()
        $ms = New-Object IO.MemoryStream
        $buffer = New-Object byte[] 16384
        while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $ms.Write($buffer, 0, $read)
            if ($ms.Length -ge $MaxBytes) {
                if ($Truncate) { break }
                return $null
            }
        }
        return @{ Bytes = $ms.ToArray(); Uri = $resp.ResponseUri }
    } finally {
        $resp.Close()
    }
}

function Test-Image([byte[]]$b) {
    if ($null -eq $b -or $b.Length -lt 8 -or $b.Length -gt 1048576) { return $false }
    if ($b[0] -eq 0 -and $b[1] -eq 0 -and $b[2] -eq 1 -and $b[3] -eq 0) { return $true }        # ICO
    if ($b[0] -eq 0x89 -and $b[1] -eq 0x50 -and $b[2] -eq 0x4E -and $b[3] -eq 0x47) { return $true } # PNG
    if ($b[0] -eq 0x47 -and $b[1] -eq 0x49 -and $b[2] -eq 0x46) { return $true }                # GIF
    if ($b[0] -eq 0xFF -and $b[1] -eq 0xD8) { return $true }                                     # JPEG
    if ($b[0] -eq 0x42 -and $b[1] -eq 0x4D) { return $true }                                     # BMP
    return $false
}

foreach ($h in $Hosts) {
    $key = ($h.ToLowerInvariant() -replace '[^a-z0-9\.\-]', '_')
    $imgPath = Join-Path $CacheDir "$key.img"
    $nonePath = Join-Path $CacheDir "$key.none"
    $bytes = $null
    $candidates = New-Object System.Collections.ArrayList

    # 1. Iconos declarados en la página principal (<link rel="icon">), si no redirige a otro dominio (ej. SSO)
    try {
        $page = Get-Remote "https://$h/" 262144 $true
        $finalHost = $page.Uri.Host.ToLowerInvariant()
        if ($finalHost -eq $h -or $finalHost.EndsWith(".$h") -or $h.EndsWith(".$finalHost")) {
            $html = [Text.Encoding]::UTF8.GetString($page.Bytes)
            foreach ($m in [regex]::Matches($html, '<link\b[^>]*>', 'IgnoreCase')) {
                $tag = $m.Value
                if ($tag -notmatch 'rel\s*=\s*["'']?([^"''>]*icon[^"''>]*)') { continue }
                $rel = $Matches[1].ToLowerInvariant()
                if ($tag -notmatch 'href\s*=\s*["'']([^"'']+)["'']') { continue }
                $href = [Net.WebUtility]::HtmlDecode($Matches[1])
                if ($href -match '\.svg([?#]|$)' -or $href -match '^data:') { continue }
                $score = 2
                if ($rel -match 'apple-touch') { $score = 3 }
                if ($tag -match 'sizes\s*=\s*["'']?(\d+)') {
                    $size = [int]$Matches[1]
                    if ($size -ge 32 -and $size -le 256) { $score = 4 }
                }
                try {
                    $abs = (New-Object Uri($page.Uri, $href)).AbsoluteUri
                    $null = $candidates.Add([PSCustomObject]@{ Url = $abs; Score = $score })
                } catch { }
            }
        }
    } catch { }

    # 2. Ubicación clásica /favicon.ico como último recurso
    $null = $candidates.Add([PSCustomObject]@{ Url = "https://$h/favicon.ico"; Score = 0 })

    foreach ($c in ($candidates | Sort-Object Score -Descending)) {
        try {
            $res = Get-Remote $c.Url 1048576 $false
            if ($null -ne $res -and (Test-Image $res.Bytes)) {
                $bytes = $res.Bytes
                break
            }
        } catch { }
    }

    try {
        if ($null -ne $bytes) {
            [IO.File]::WriteAllBytes($imgPath, $bytes)
            if (Test-Path -LiteralPath $nonePath) { Remove-Item -LiteralPath $nonePath -Force }
        } else {
            [IO.File]::WriteAllText($nonePath, "")
        }
    } catch { }
}
'@

# Lanza la descarga de favicons en segundo plano; al terminar invoca $Global:DLauncherFaviconOnComplete
function Start-DLauncherFaviconFetch {
    param ([string[]]$Hosts)

    $Hosts = @($Hosts | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
    if ($Hosts.Count -eq 0) { return }

    # Si ya hay una descarga en curso, encolar para la siguiente tanda
    if ($null -ne $Global:DLauncherFaviconJob) {
        foreach ($h in $Hosts) { $null = $Global:DLauncherFaviconQueue.Add($h) }
        return
    }

    if (-not (Test-Path -LiteralPath $Global:DLauncherIconCacheDir)) {
        $null = New-Item -ItemType Directory -Path $Global:DLauncherIconCacheDir -Force
    }

    $ps = [powershell]::Create()
    $null = $ps.AddScript($Global:DLauncherFaviconWorker).AddArgument($Hosts).AddArgument($Global:DLauncherIconCacheDir)
    $Global:DLauncherFaviconJob = @{
        PS     = $ps
        Handle = $ps.BeginInvoke()
        Hosts  = $Hosts
    }

    # Sondeo ligero desde el hilo de la interfaz para detectar la finalización
    if ($null -eq $Global:DLauncherFaviconTimer) {
        $Global:DLauncherFaviconTimer = New-Object System.Windows.Threading.DispatcherTimer
        $Global:DLauncherFaviconTimer.Interval = [TimeSpan]::FromMilliseconds(500)
        $Global:DLauncherFaviconTimer.Add_Tick({
            $job = $Global:DLauncherFaviconJob
            if ($null -eq $job -or -not $job.Handle.IsCompleted) { return }
            try { $null = $job.PS.EndInvoke($job.Handle) } catch { }
            $job.PS.Dispose()
            $Global:DLauncherFaviconJob = $null

            if ($null -ne $Global:DLauncherFaviconOnComplete) {
                try { & $Global:DLauncherFaviconOnComplete $job.Hosts } catch { }
            }

            if ($Global:DLauncherFaviconQueue.Count -gt 0) {
                $next = @($Global:DLauncherFaviconQueue)
                $Global:DLauncherFaviconQueue.Clear()
                Start-DLauncherFaviconFetch -Hosts $next
            } else {
                $Global:DLauncherFaviconTimer.Stop()
            }
        })
    }
    $Global:DLauncherFaviconTimer.Start()
}

# Vacía la caché de favicons (disco y memoria). Se volverán a descargar al mostrarse
function Clear-DLauncherIconCache {
    $Global:DLauncherIconMemory = @{}
    if (Test-Path -LiteralPath $Global:DLauncherIconCacheDir) {
        Get-ChildItem -LiteralPath $Global:DLauncherIconCacheDir -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -in '.img', '.none' } |
            Remove-Item -Force -ErrorAction SilentlyContinue
    }
}
