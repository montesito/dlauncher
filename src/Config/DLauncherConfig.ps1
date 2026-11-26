# DLauncher - Configuration Module
# Persistencia local en JSON con ubicación elegida por el usuario
# Esquema v2: Settings + Groups (etiquetas) + Platforms (herramientas)
#
# Protección de datos:
# - Cada guardado escribe en un archivo temporal y lo sustituye de forma atómica, conservando la versión anterior en config.json.bak
# - Si config.json está dañado, se aparta una copia (config.damaged-<fecha>.json) y se recupera desde config.json.bak
# - Si el archivo está bloqueado (ej. sincronización de OneDrive), no se escribe encima con datos vacíos

# Directorio base del sistema donde se almacena el puntero de configuración
$Global:ConfigBaseDir = Join-Path -Path $env:LOCALAPPDATA -ChildPath "DLauncher"
$Global:ConfigPointerFile = Join-Path -Path $Global:ConfigBaseDir -ChildPath "config_folder.txt"
$Global:ConfigSchemaVersion = 2

# Variables dinámicas de ubicación actual
$Global:ConfigDir = $null
$Global:ConfigPath = $null

# Estado de lectura/escritura
$Global:DLauncherLastGoodJson = $null
$Global:DLauncherConfigReadOnly = $false
$Global:DLauncherConfigNotices = [System.Collections.ArrayList]::new()
$Global:DLauncherFolderMissing = $false   # la carpeta elegida no está disponible ahora mismo
$Global:DLauncherMissingShown = $false    # el aviso ya se mostró en este episodio

# Avisos pendientes para la interfaz (sin ventanas emergentes desde este módulo)
function Add-DLauncherConfigNotice {
    param ([string]$Kind, [string]$Detail = "")
    foreach ($n in $Global:DLauncherConfigNotices) {
        if ($n.Kind -eq $Kind) { return }
    }
    $null = $Global:DLauncherConfigNotices.Add([PSCustomObject]@{ Kind = $Kind; Detail = $Detail })
}

# Recupera la carpeta actualmente configurada a través del archivo puntero
function Get-DLauncherConfigFolder {
    if (Test-Path -LiteralPath $Global:ConfigPointerFile) {
        try {
            $savedFolder = ([System.IO.File]::ReadAllText($Global:ConfigPointerFile, [System.Text.Encoding]::UTF8)).Trim()
            if (-not [string]::IsNullOrWhiteSpace($savedFolder) -and (Test-Path -LiteralPath $savedFolder)) {
                return $savedFolder
            }
        } catch {
            # Puntero ilegible: se pedirá de nuevo la carpeta
        }
    }
    return $null
}

# Comprueba si el usuario ya ha configurado una carpeta válida existente
function Test-DLauncherHasConfigFolder {
    return ($null -ne (Get-DLauncherConfigFolder))
}

# Ruta guardada en el puntero, exista o no (vacía si nunca se eligió carpeta)
function Get-DLauncherConfigPointer {
    if (-not (Test-Path -LiteralPath $Global:ConfigPointerFile)) { return "" }
    try {
        return ([System.IO.File]::ReadAllText($Global:ConfigPointerFile, [System.Text.Encoding]::UTF8)).Trim()
    } catch {
        return ""
    }
}

# Hay una carpeta elegida pero no se encuentra (movida, renombrada o unidad de red/nube no disponible).
# En ese caso NO se crea nada: se avisa al usuario y se espera a que vuelva o elija otra ubicación
function Test-DLauncherConfigFolderMissing {
    $pointer = Get-DLauncherConfigPointer
    if ([string]::IsNullOrWhiteSpace($pointer)) { return $false }
    return (-not (Test-Path -LiteralPath $pointer))
}

# Huella de config.json (fecha y tamaño) para detectar cambios hechos desde otro equipo
$Global:DLauncherConfigStamp = ""
function Get-DLauncherConfigFileStamp {
    try {
        if ([string]::IsNullOrEmpty($Global:ConfigPath)) { return "" }
        $fi = New-Object System.IO.FileInfo($Global:ConfigPath)
        if (-not $fi.Exists) { return "" }
        return "$($fi.LastWriteTimeUtc.Ticks)|$($fi.Length)"
    } catch {
        return ""
    }
}
function Update-DLauncherConfigStamp {
    $Global:DLauncherConfigStamp = Get-DLauncherConfigFileStamp
}

# ¿Ha cambiado config.json desde la última lectura o escritura de esta ventana?
# Solo cuenta como cambio si el contenido es distinto (las sincronizaciones a veces solo tocan la fecha)
function Test-DLauncherConfigChangedExternally {
    $stamp = Get-DLauncherConfigFileStamp
    if ($stamp -eq "" -or $stamp -eq $Global:DLauncherConfigStamp) { return $false }
    try {
        $json = Read-DLauncherTextWithRetry -Path $Global:ConfigPath
    } catch {
        return $false
    }
    $Global:DLauncherConfigStamp = $stamp
    return ($json -ne $Global:DLauncherLastGoodJson)
}

# Obtiene la ruta del archivo config.json activo
function Get-DLauncherConfigPath {
    if (-not [string]::IsNullOrEmpty($Global:ConfigPath)) {
        return $Global:ConfigPath
    }
    $folder = Get-DLauncherConfigFolder
    if ($null -ne $folder) {
        $Global:ConfigDir = $folder
        $Global:ConfigPath = Join-Path -Path $folder -ChildPath "config.json"
        return $Global:ConfigPath
    }
    return (Join-Path -Path $Global:ConfigBaseDir -ChildPath "config.json")
}

# Estructura de configuración por defecto (esquema v2)
function New-DLauncherDefaultConfig {
    return [PSCustomObject]@{
        Version   = $Global:ConfigSchemaVersion
        Settings  = [PSCustomObject]@{
            RememberCheckState  = $true
            LaunchDelayMs       = 500
            FetchFavicons       = $true
            ActiveGroupId       = ""
            ConfirmManyLaunches = $true
            HiddenSuggestions   = @()
        }
        Groups    = @()
        Platforms = @()
    }
}

# Añade una propiedad con valor por defecto si no existe (migración de esquemas antiguos)
function Set-DLauncherDefaultProperty {
    param ($Object, [string]$Name, $Value)
    if ($null -eq $Object.PSObject.Properties[$Name]) {
        $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    }
}

# Normaliza y migra una configuración leída de disco al esquema actual
function Repair-DLauncherConfig {
    param ($Config)

    Set-DLauncherDefaultProperty $Config 'Version' $Global:ConfigSchemaVersion
    Set-DLauncherDefaultProperty $Config 'Settings' $null
    if ($null -eq $Config.Settings) {
        $Config.Settings = [PSCustomObject]@{}
    }
    Set-DLauncherDefaultProperty $Config.Settings 'RememberCheckState' $true
    Set-DLauncherDefaultProperty $Config.Settings 'LaunchDelayMs' 500
    Set-DLauncherDefaultProperty $Config.Settings 'FetchFavicons' $true
    Set-DLauncherDefaultProperty $Config.Settings 'ActiveGroupId' ""
    Set-DLauncherDefaultProperty $Config.Settings 'ConfirmManyLaunches' $true
    Set-DLauncherDefaultProperty $Config.Settings 'HiddenSuggestions' @()
    $Config.Settings.HiddenSuggestions = @(@($Config.Settings.HiddenSuggestions) | Where-Object { -not [string]::IsNullOrEmpty($_) } | ForEach-Object { [string]$_ })

    Set-DLauncherDefaultProperty $Config 'Groups' @()
    Set-DLauncherDefaultProperty $Config 'Platforms' @()
    $Config.Groups = @($Config.Groups | Where-Object { $null -ne $_ })
    $Config.Platforms = @($Config.Platforms | Where-Object { $null -ne $_ })

    foreach ($g in $Config.Groups) {
        Set-DLauncherDefaultProperty $g 'Id' ([guid]::NewGuid().ToString())
        Set-DLauncherDefaultProperty $g 'Name' (T 'form.group')
        Set-DLauncherDefaultProperty $g 'Color' ""
    }
    # Asignar un color fijo a las etiquetas que aún no lo tienen (se guarda y no cambia nunca)
    foreach ($g in $Config.Groups) {
        if ([string]::IsNullOrEmpty($g.Color)) {
            $g.Color = Get-DLauncherNextTagColor -Groups $Config.Groups
        }
    }
    foreach ($p in $Config.Platforms) {
        Set-DLauncherDefaultProperty $p 'Id' ([guid]::NewGuid().ToString())
        Set-DLauncherDefaultProperty $p 'Name' ""
        Set-DLauncherDefaultProperty $p 'Url' ""
        Set-DLauncherDefaultProperty $p 'IsChecked' $true
        Set-DLauncherDefaultProperty $p 'CheckedByDefault' $true
        Set-DLauncherDefaultProperty $p 'Tags' @()
        Set-DLauncherDefaultProperty $p 'Browser' ""
        Set-DLauncherDefaultProperty $p 'BrowserProfile' ""

        # Migración: grupo único (GroupId) -> etiquetas múltiples (Tags)
        $legacy = $p.PSObject.Properties['GroupId']
        if ($null -ne $legacy) {
            if (-not [string]::IsNullOrEmpty([string]$legacy.Value)) {
                $p.Tags = @($p.Tags) + [string]$legacy.Value
            }
            $p.PSObject.Properties.Remove('GroupId')
        }
    }

    # Normalizar etiquetas: sin vacíos, sin duplicados y solo etiquetas existentes
    $validTags = @($Config.Groups | ForEach-Object { [string]$_.Id })
    foreach ($p in $Config.Platforms) {
        $p.Tags = @(@($p.Tags) | Where-Object { -not [string]::IsNullOrEmpty($_) -and $validTags -contains $_ } | Select-Object -Unique)
    }

    $Config.Version = $Global:ConfigSchemaVersion
    return $Config
}

# ===================== LECTURA Y ESCRITURA SEGURAS =====================

# Lee un archivo de texto reintentando si está bloqueado temporalmente
function Read-DLauncherTextWithRetry {
    param ([string]$Path)
    for ($i = 0; $i -lt 4; $i++) {
        try {
            return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
        } catch [System.IO.IOException] {
            if ($i -eq 3) { throw }
            Start-Sleep -Milliseconds 120
        }
    }
}

# Escribe texto JSON de forma atómica. Salvo -NoBackup, la versión anterior queda en "<archivo>.bak"
function Write-DLauncherJsonText {
    param ([string]$Path, [string]$Json, [switch]$NoBackup)
    $tmp = "$Path.tmp"
    [System.IO.File]::WriteAllText($tmp, $Json, (New-Object System.Text.UTF8Encoding($false)))
    $replaced = $false
    if ((Test-Path -LiteralPath $Path) -and -not $NoBackup) {
        try {
            [System.IO.File]::Replace($tmp, $Path, "$Path.bak", $true)
            $replaced = $true
        } catch {
            # Algunas unidades de red o carpetas sincronizadas no admiten Replace: copia manual
            try { Copy-Item -LiteralPath $Path -Destination "$Path.bak" -Force } catch { }
        }
    }
    if (-not $replaced) {
        Move-Item -LiteralPath $tmp -Destination $Path -Force
    }
    # Escritura propia: no debe contar como "cambio desde otro equipo"
    if ($Path -eq $Global:ConfigPath) { Update-DLauncherConfigStamp }
}

function Write-DLauncherJsonFile {
    param ([string]$Path, $Object, [switch]$NoBackup)
    $json = $Object | ConvertTo-Json -Depth 6
    Write-DLauncherJsonText -Path $Path -Json $json -NoBackup:$NoBackup
    return $json
}

function ConvertFrom-DLauncherConfigJson {
    param ([string]$Json)
    if ([string]::IsNullOrWhiteSpace($Json)) { throw "empty" }
    $obj = ConvertFrom-Json -InputObject $Json
    if ($null -eq $obj -or $obj -isnot [System.Management.Automation.PSCustomObject]) { throw "invalid" }
    return (Repair-DLauncherConfig -Config $obj)
}

# config.json dañado: apartar una copia, recuperar desde la copia de seguridad o empezar de cero (sin perder el original)
function Restore-DLauncherDamagedConfig {
    param ([string]$Path, [string]$Json)

    $preserved = ""
    if (-not [string]::IsNullOrWhiteSpace($Json)) {
        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $preserved = Join-Path -Path (Split-Path -Parent -Path $Path) -ChildPath "config.damaged-$stamp.json"
        try {
            [System.IO.File]::WriteAllText($preserved, $Json, (New-Object System.Text.UTF8Encoding($false)))
        } catch {
            $preserved = ""
        }
    }

    $bak = "$Path.bak"
    if (Test-Path -LiteralPath $bak) {
        try {
            $bakJson = Read-DLauncherTextWithRetry -Path $bak
            $config = ConvertFrom-DLauncherConfigJson -Json $bakJson
            Write-DLauncherJsonText -Path $Path -Json $bakJson -NoBackup
            $Global:DLauncherLastGoodJson = $bakJson
            Add-DLauncherConfigNotice -Kind 'restored' -Detail $preserved
            return $config
        } catch {
            # La copia de seguridad tampoco es válida
        }
    }

    $config = New-DLauncherDefaultConfig
    $Global:DLauncherLastGoodJson = Write-DLauncherJsonFile -Path $Path -Object $config -NoBackup
    if ($preserved -ne "") {
        Add-DLauncherConfigNotice -Kind 'reset' -Detail $preserved
    }
    return $config
}

# Establece una nueva carpeta de configuración elegida por el usuario
# - Guarda la ruta en el archivo puntero dentro de %LOCALAPPDATA%\DLauncher
# - Si config.json ya existe en esa carpeta: se carga y conserva
# - Si config.json NO existe: se crea un archivo nuevo con configuración por defecto
function Set-DLauncherConfigFolder {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FolderPath
    )

    if (-not (Test-Path -LiteralPath $FolderPath)) {
        $null = New-Item -ItemType Directory -Path $FolderPath -Force
    }
    if (-not (Test-Path -LiteralPath $Global:ConfigBaseDir)) {
        $null = New-Item -ItemType Directory -Path $Global:ConfigBaseDir -Force
    }

    [System.IO.File]::WriteAllText($Global:ConfigPointerFile, $FolderPath, (New-Object System.Text.UTF8Encoding($false)))

    $Global:ConfigDir = $FolderPath
    $Global:ConfigPath = Join-Path -Path $FolderPath -ChildPath "config.json"
    $Global:DLauncherLastGoodJson = $null
    $Global:DLauncherConfigReadOnly = $false
    $Global:DLauncherFolderMissing = $false
    $Global:DLauncherMissingShown = $false

    $alreadyExisted = Test-Path -LiteralPath $Global:ConfigPath
    if (-not $alreadyExisted) {
        $null = Write-DLauncherJsonFile -Path $Global:ConfigPath -Object (New-DLauncherDefaultConfig) -NoBackup
    }

    return [PSCustomObject]@{
        FolderPath     = $FolderPath
        ConfigPath     = $Global:ConfigPath
        AlreadyExisted = $alreadyExisted
    }
}

# Inicializa la estructura del directorio y el JSON de configuración si no existen
function Initialize-DLauncherConfig {
    if (Test-DLauncherConfigFolderMissing) {
        # Carpeta elegida pero no disponible: no crear nada (ni allí ni en otra ubicación)
        $Global:ConfigDir = Get-DLauncherConfigPointer
        $Global:ConfigPath = Join-Path -Path $Global:ConfigDir -ChildPath "config.json"
        return
    }
    try {
        $folder = Get-DLauncherConfigFolder
        if ($null -ne $folder) {
            $Global:ConfigDir = $folder
            $Global:ConfigPath = Join-Path -Path $folder -ChildPath "config.json"
        } else {
            $Global:ConfigDir = $Global:ConfigBaseDir
            $Global:ConfigPath = Join-Path -Path $Global:ConfigBaseDir -ChildPath "config.json"
        }
        if (-not (Test-Path -LiteralPath $Global:ConfigDir)) {
            $null = New-Item -ItemType Directory -Path $Global:ConfigDir -Force
        }
        if (-not (Test-Path -LiteralPath $Global:ConfigPath)) {
            $null = Write-DLauncherJsonFile -Path $Global:ConfigPath -Object (New-DLauncherDefaultConfig) -NoBackup
        }
    } catch {
        Add-DLauncherConfigNotice -Kind 'saveFailed' -Detail $_.Exception.Message
    }
}

# Recupera la configuración desde config.json (migrada al esquema actual)
function Get-DLauncherConfig {
    $activePath = Get-DLauncherConfigPath
    if (-not (Test-Path -LiteralPath $activePath)) {
        if (Test-DLauncherConfigFolderMissing) {
            # La carpeta ha desaparecido (movida o unidad desconectada): trabajar con lo último leído y no escribir
            $Global:DLauncherConfigReadOnly = $true
            Add-DLauncherConfigNotice -Kind 'missing' -Detail (Get-DLauncherConfigPointer)
            if ($null -ne $Global:DLauncherLastGoodJson) {
                return (ConvertFrom-DLauncherConfigJson -Json $Global:DLauncherLastGoodJson)
            }
            return New-DLauncherDefaultConfig
        }
        Initialize-DLauncherConfig
        $activePath = Get-DLauncherConfigPath
    }

    $json = $null
    try {
        $json = Read-DLauncherTextWithRetry -Path $activePath
    } catch {
        # Bloqueado o inaccesible: trabajar con la última copia válida y no escribir encima
        $Global:DLauncherConfigReadOnly = $true
        Add-DLauncherConfigNotice -Kind 'locked' -Detail $_.Exception.Message
        if ($null -ne $Global:DLauncherLastGoodJson) {
            return (ConvertFrom-DLauncherConfigJson -Json $Global:DLauncherLastGoodJson)
        }
        return New-DLauncherDefaultConfig
    }

    try {
        $config = ConvertFrom-DLauncherConfigJson -Json $json
        $Global:DLauncherLastGoodJson = $json
        $Global:DLauncherConfigReadOnly = $false
        Update-DLauncherConfigStamp
        return $config
    } catch {
        return (Restore-DLauncherDamagedConfig -Path $activePath -Json $json)
    }
}

# Serializa y almacena la configuración en disco. Devuelve $true si se guardó
function Save-DLauncherConfig {
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Config
    )
    if ($Global:DLauncherConfigReadOnly) {
        if (Test-DLauncherConfigFolderMissing) {
            Add-DLauncherConfigNotice -Kind 'missing' -Detail (Get-DLauncherConfigPointer)
        } else {
            Add-DLauncherConfigNotice -Kind 'locked'
        }
        return $false
    }
    try {
        $activePath = Get-DLauncherConfigPath
        $parentDir = Split-Path -Parent -Path $activePath
        if (-not (Test-Path -LiteralPath $parentDir)) {
            # Nunca recrear una carpeta de configuración que ha desaparecido: se perdería la pista de la real
            $Global:DLauncherConfigReadOnly = $true
            Add-DLauncherConfigNotice -Kind 'missing' -Detail $parentDir
            return $false
        }
        $Global:DLauncherLastGoodJson = Write-DLauncherJsonFile -Path $activePath -Object $Config
        return $true
    } catch {
        Add-DLauncherConfigNotice -Kind 'saveFailed' -Detail $_.Exception.Message
        return $false
    }
}

# Actualiza un ajuste global individual
function Set-DLauncherSetting {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Name,
        $Value
    )
    $config = Get-DLauncherConfig
    if ($null -eq $config.Settings.PSObject.Properties[$Name]) {
        $config.Settings | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    } else {
        $config.Settings.$Name = $Value
    }
    $null = Save-DLauncherConfig -Config $config
}

# Instantánea del archivo actual (para "Deshacer")
function Get-DLauncherConfigSnapshot {
    $null = Get-DLauncherConfig
    return $Global:DLauncherLastGoodJson
}

function Restore-DLauncherConfigSnapshot {
    param ([string]$Json)
    $null = ConvertFrom-DLauncherConfigJson -Json $Json
    Write-DLauncherJsonText -Path (Get-DLauncherConfigPath) -Json $Json
    $Global:DLauncherLastGoodJson = $Json
}

# ===================== HERRAMIENTAS =====================

function New-DLauncherPlatformObject {
    param ([string]$Name, [string]$Url, [bool]$IsChecked = $true, [bool]$CheckedByDefault = $true, [string[]]$Tags = @(), [string]$Browser = "", [string]$BrowserProfile = "")
    return [PSCustomObject]@{
        Id               = [guid]::NewGuid().ToString()
        Name             = $Name
        Url              = $Url
        IsChecked        = $IsChecked
        CheckedByDefault = $CheckedByDefault
        Tags             = @($Tags | Where-Object { -not [string]::IsNullOrEmpty($_) } | Select-Object -Unique)
        Browser          = $Browser
        BrowserProfile   = $BrowserProfile
    }
}

# Añade una nueva herramienta
function Add-DLauncherPlatform {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Name,
        [Parameter(Mandatory=$true)]
        [string]$Url,
        [bool]$IsChecked = $true,
        [bool]$CheckedByDefault = $true,
        [string[]]$Tags = @(),
        [string]$Browser = "",
        [string]$BrowserProfile = ""
    )
    $config = Get-DLauncherConfig
    $newPlatform = New-DLauncherPlatformObject -Name $Name -Url $Url -IsChecked $IsChecked -CheckedByDefault $CheckedByDefault -Tags $Tags -Browser $Browser -BrowserProfile $BrowserProfile
    $config.Platforms = @($config.Platforms) + $newPlatform
    $null = Save-DLauncherConfig -Config $config
    return $newPlatform
}

# Añade varias herramientas de una sola escritura, omitiendo las URL/rutas ya existentes
# Items: lista de @{ Name; Url }. Devuelve el número de herramientas añadidas
function Add-DLauncherPlatformBatch {
    param (
        $Items,
        [string[]]$Tags = @()
    )
    $config = Get-DLauncherConfig
    $existing = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($p in $config.Platforms) { $null = $existing.Add((Get-DLauncherUrlKey $p.Url)) }
    $list = [System.Collections.ArrayList]::new()
    foreach ($p in $config.Platforms) { $null = $list.Add($p) }
    $added = 0
    foreach ($it in @($Items)) {
        if ([string]::IsNullOrWhiteSpace($it.Url)) { continue }
        if (-not $existing.Add((Get-DLauncherUrlKey $it.Url))) { continue }
        $null = $list.Add((New-DLauncherPlatformObject -Name ([string]$it.Name) -Url ([string]$it.Url) -Tags $Tags))
        $added++
    }
    if ($added -gt 0) {
        $config.Platforms = @($list)
        $null = Save-DLauncherConfig -Config $config
    }
    return $added
}

# Modifica los datos de una herramienta existente
function Update-DLauncherPlatform {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Id,
        [Parameter(Mandatory=$true)]
        [string]$Name,
        [Parameter(Mandatory=$true)]
        [string]$Url,
        [bool]$IsChecked,
        [bool]$CheckedByDefault,
        [string[]]$Tags = @(),
        [string]$Browser = "",
        [string]$BrowserProfile = ""
    )
    $config = Get-DLauncherConfig
    $found = $false
    foreach ($p in $config.Platforms) {
        if ($p.Id -eq $Id) {
            $p.Name = $Name
            $p.Url = $Url
            $p.IsChecked = $IsChecked
            $p.CheckedByDefault = $CheckedByDefault
            $p.Tags = @($Tags | Where-Object { -not [string]::IsNullOrEmpty($_) } | Select-Object -Unique)
            $p.Browser = $Browser
            $p.BrowserProfile = $BrowserProfile
            $found = $true
            break
        }
    }
    if ($found) { $null = Save-DLauncherConfig -Config $config }
    return $found
}

# Duplica una herramienta y la coloca justo debajo de la original
function Copy-DLauncherPlatform {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Id
    )
    $config = Get-DLauncherConfig
    $list = [System.Collections.ArrayList]::new()
    $copy = $null
    foreach ($p in $config.Platforms) {
        $null = $list.Add($p)
        if ($p.Id -eq $Id) {
            $copy = New-DLauncherPlatformObject -Name (T 'copy.name' $p.Name) -Url $p.Url -IsChecked ([bool]$p.IsChecked) -CheckedByDefault ([bool]$p.CheckedByDefault) -Tags @($p.Tags) -Browser ([string]$p.Browser) -BrowserProfile ([string]$p.BrowserProfile)
            $null = $list.Add($copy)
        }
    }
    if ($null -ne $copy) {
        $config.Platforms = @($list)
        $null = Save-DLauncherConfig -Config $config
    }
    return $copy
}

# Reemplaza las etiquetas de una herramienta
function Set-DLauncherPlatformTags {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Id,
        [string[]]$Tags = @()
    )
    $config = Get-DLauncherConfig
    foreach ($p in $config.Platforms) {
        if ($p.Id -eq $Id) {
            $p.Tags = @($Tags | Where-Object { -not [string]::IsNullOrEmpty($_) } | Select-Object -Unique)
        }
    }
    $null = Save-DLauncherConfig -Config $config
}

# Añade una etiqueta a una o varias herramientas (sin duplicar)
function Add-DLauncherPlatformTag {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$Ids,
        [Parameter(Mandatory=$true)]
        [string]$TagId
    )
    $config = Get-DLauncherConfig
    $changed = 0
    foreach ($p in $config.Platforms) {
        if ($Ids -contains $p.Id -and -not (@($p.Tags) -contains $TagId)) {
            $p.Tags = @($p.Tags) + $TagId
            $changed++
        }
    }
    if ($changed -gt 0) { $null = Save-DLauncherConfig -Config $config }
    return $changed
}

# Marca o desmarca varias herramientas de una sola escritura
function Set-DLauncherPlatformChecked {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$Ids,
        [bool]$IsChecked
    )
    $config = Get-DLauncherConfig
    foreach ($p in $config.Platforms) {
        if ($Ids -contains $p.Id) {
            $p.IsChecked = $IsChecked
        }
    }
    $null = Save-DLauncherConfig -Config $config
}

# Elimina una herramienta identificada por su ID
function Remove-DLauncherPlatform {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Id
    )
    $config = Get-DLauncherConfig
    $before = @($config.Platforms).Count
    $config.Platforms = @($config.Platforms | Where-Object { $_.Id -ne $Id })
    $found = ($config.Platforms.Count -ne $before)
    if ($found) { $null = Save-DLauncherConfig -Config $config }
    return $found
}

# Reordena las herramientas según la lista de Ids recibida (orden visual tras arrastrar)
# Si la lista es un subconjunto (vista filtrada), los elementos se reordenan dentro de las
# posiciones que ya ocupaban, sin alterar la posición relativa del resto
function Set-DLauncherPlatformOrder {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$OrderedIds
    )
    $config = Get-DLauncherConfig
    $all = @($config.Platforms)

    $byId = @{}
    foreach ($p in $all) { $byId[$p.Id] = $p }

    $movingSet = New-Object 'System.Collections.Generic.HashSet[string]'
    $queue = New-Object 'System.Collections.Generic.Queue[object]'
    foreach ($id in $OrderedIds) {
        if ($byId.ContainsKey($id) -and $movingSet.Add($id)) {
            $queue.Enqueue($byId[$id])
        }
    }

    $result = [System.Collections.ArrayList]::new()
    foreach ($p in $all) {
        if ($movingSet.Contains($p.Id)) {
            $null = $result.Add($queue.Dequeue())
        } else {
            $null = $result.Add($p)
        }
    }

    $config.Platforms = @($result)
    $null = Save-DLauncherConfig -Config $config
}

# Elimina todas las herramientas configuradas (las etiquetas se conservan)
function Clear-DLauncherPlatforms {
    $config = Get-DLauncherConfig
    $config.Platforms = @()
    $null = Save-DLauncherConfig -Config $config
}

# Normaliza una URL o ruta para detectar duplicados
function Get-DLauncherUrlKey {
    param ([string]$Url)
    if ($null -eq $Url) { return "" }
    return $Url.Trim().TrimEnd('/', '\').ToLowerInvariant()
}

# ===================== ETIQUETAS =====================

# Paleta de colores de etiqueta (tonos claramente distintos entre sí, legibles en tema claro y oscuro)
$Global:DLauncherTagPalette = @('#3B9BFF', '#FF7A33', '#2FC25B', '#B45CF0', '#E5B800', '#F2557A', '#21B8D4', '#A2845E', '#7D7AFF', '#8E8E99')

# Primer color de la paleta que no usa ninguna etiqueta (si todos están usados, el menos repetido)
function Get-DLauncherNextTagColor {
    param ($Groups)
    $usage = @{}
    foreach ($c in $Global:DLauncherTagPalette) { $usage[$c] = 0 }
    foreach ($g in @($Groups)) {
        $c = [string]$g.Color
        if ($usage.ContainsKey($c)) { $usage[$c]++ }
    }
    foreach ($c in $Global:DLauncherTagPalette) {
        if ($usage[$c] -eq 0) { return $c }
    }
    return ($Global:DLauncherTagPalette | Sort-Object { $usage[$_] } | Select-Object -First 1)
}

# Crea una etiqueta
function Add-DLauncherGroup {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
    $config = Get-DLauncherConfig
    $group = [PSCustomObject]@{
        Id    = [guid]::NewGuid().ToString()
        Name  = $Name
        Color = Get-DLauncherNextTagColor -Groups $config.Groups
    }
    $config.Groups = @($config.Groups) + $group
    $null = Save-DLauncherConfig -Config $config
    return $group
}

# Cambia el nombre de una etiqueta
function Rename-DLauncherGroup {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Id,
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
    $config = Get-DLauncherConfig
    foreach ($g in $config.Groups) {
        if ($g.Id -eq $Id) { $g.Name = $Name }
    }
    $null = Save-DLauncherConfig -Config $config
}

# Elimina una etiqueta; sus herramientas NO se borran, solo pierden esa etiqueta
function Remove-DLauncherGroup {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Id
    )
    $config = Get-DLauncherConfig
    $config.Groups = @($config.Groups | Where-Object { $_.Id -ne $Id })
    foreach ($p in $config.Platforms) {
        $p.Tags = @(@($p.Tags) | Where-Object { $_ -ne $Id })
    }
    if ($config.Settings.ActiveGroupId -eq $Id) {
        $config.Settings.ActiveGroupId = ""
    }
    $null = Save-DLauncherConfig -Config $config
}

# ===================== EXPORTAR / IMPORTAR =====================

# Exporta etiquetas y herramientas a un archivo JSON portable para compartir con compañeros
function Export-DLauncherConfig {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    $config = Get-DLauncherConfig
    $export = [PSCustomObject]@{
        App        = "DLauncher"
        Version    = $Global:ConfigSchemaVersion
        ExportedAt = (Get-Date).ToString("s")
        Settings   = [PSCustomObject]@{ LaunchDelayMs = $config.Settings.LaunchDelayMs }
        Groups     = @($config.Groups | ForEach-Object { [PSCustomObject]@{ Id = $_.Id; Name = $_.Name; Color = $_.Color } })
        Platforms  = @($config.Platforms | ForEach-Object {
            [PSCustomObject]@{
                Id               = $_.Id
                Name             = $_.Name
                Url              = $_.Url
                CheckedByDefault = $_.CheckedByDefault
                Tags             = @($_.Tags)
                Browser          = $_.Browser
                BrowserProfile   = $_.BrowserProfile
            }
        })
    }
    $null = Write-DLauncherJsonFile -Path $Path -Object $export -NoBackup
}

# Importa (combina) un archivo exportado: etiquetas por nombre, herramientas sin duplicar URL.
# Por seguridad, lo importado llega SIN seleccionar y se descartan valores de navegador/perfil no válidos
function Import-DLauncherConfig {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    $info = Get-Item -LiteralPath $Path
    if ($info.Length -gt 5MB) { throw (T "import.invalid") }
    $raw = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    $data = $null
    try { $data = ConvertFrom-Json -InputObject $raw } catch { throw (T "import.invalid") }
    if ($null -eq $data -or $data -isnot [System.Management.Automation.PSCustomObject] -or $null -eq $data.PSObject.Properties['Platforms']) {
        throw (T "import.invalid")
    }
    $data = Repair-DLauncherConfig -Config $data

    $config = Get-DLauncherConfig
    $groups = [System.Collections.ArrayList]::new()
    foreach ($g in $config.Groups) { $null = $groups.Add($g) }
    $platforms = [System.Collections.ArrayList]::new()
    foreach ($p in $config.Platforms) { $null = $platforms.Add($p) }

    # Mapear etiquetas importadas a etiquetas existentes (por nombre) o crear nuevas
    $groupMap = @{}
    $groupsAdded = 0
    foreach ($g in $data.Groups) {
        $gName = ([string]$g.Name).Trim()
        if ($gName -eq "") { continue }
        if ($gName.Length -gt 60) { $gName = $gName.Substring(0, 60) }
        $existing = $groups | Where-Object { $_.Name -eq $gName } | Select-Object -First 1
        if ($null -eq $existing) {
            $existing = [PSCustomObject]@{ Id = [guid]::NewGuid().ToString(); Name = $gName; Color = (Get-DLauncherNextTagColor -Groups @($groups)) }
            $null = $groups.Add($existing)
            $groupsAdded++
        }
        $groupMap[[string]$g.Id] = $existing.Id
    }

    $existingUrls = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($p in $platforms) { $null = $existingUrls.Add((Get-DLauncherUrlKey $p.Url)) }

    $added = 0
    $skipped = 0
    $codeTargets = 0
    foreach ($p in $data.Platforms) {
        $url = ([string]$p.Url).Trim()
        if ([string]::IsNullOrWhiteSpace($url) -or $url.Length -gt 2048) { continue }
        if (-not $existingUrls.Add((Get-DLauncherUrlKey $url))) {
            $skipped++
            continue
        }
        $name = ([string]$p.Name).Trim()
        if ($name -eq "") { $name = $url }
        if ($name.Length -gt 120) { $name = $name.Substring(0, 120) }

        $browser = ([string]$p.Browser).ToLowerInvariant()
        if ($Global:DLauncherKnownBrowserKeys -notcontains $browser) { $browser = "" }
        $browserProfile = [string]$p.BrowserProfile
        if ($browser -eq "" -or -not (Test-DLauncherSafeProfileId -ProfileId $browserProfile)) { $browserProfile = "" }

        if (Test-DLauncherCodeTarget -Value $url) { $codeTargets++ }

        $mappedTags = @(@($p.Tags) | Where-Object { $groupMap.ContainsKey([string]$_) } | ForEach-Object { $groupMap[[string]$_] } | Select-Object -Unique)
        $null = $platforms.Add((New-DLauncherPlatformObject -Name $name -Url $url -IsChecked $false -CheckedByDefault $false -Tags $mappedTags -Browser $browser -BrowserProfile $browserProfile))
        $added++
    }

    $config.Groups = @($groups)
    $config.Platforms = @($platforms)
    $null = Save-DLauncherConfig -Config $config

    return [PSCustomObject]@{
        Added       = $added
        Skipped     = $skipped
        GroupsAdded = $groupsAdded
        CodeTargets = $codeTargets
    }
}
