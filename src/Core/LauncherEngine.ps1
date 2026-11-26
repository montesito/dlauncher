# DLauncher - Backend Launcher Core Engine
# Motor principal de ejecución y lanzamiento de aplicaciones y URLs

# Utilidad robusta para abrir una ruta o URL usando la API nativa de Windows
function Invoke-DLauncherSystemOpen {
    param (
        [string]$PathOrUrl,
        [string]$Arguments = ""
    )

    try {
        # 1. Intentar lanzar utilizando ProcessStartInfo y UseShellExecute en .NET nativo
        # Esto es mucho más estable y directo que Start-Process dentro de hilos WPF de PowerShell
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $PathOrUrl
        $psi.Arguments = $Arguments
        $psi.UseShellExecute = $true
        $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Normal
        if ($PathOrUrl -match '^[a-zA-Z]:[\\/]|^\\\\' -and (Test-Path -LiteralPath $PathOrUrl -PathType Leaf -ErrorAction SilentlyContinue)) {
            # Algunas aplicaciones necesitan arrancar desde su propia carpeta
            $psi.WorkingDirectory = Split-Path -Parent -Path $PathOrUrl
        }
        $null = [System.Diagnostics.Process]::Start($psi)
        return $true
    }
    catch {
        try {
            # 2. Fallback: Si el protocolo o registro de extensión falla, invocar el comando 'start' nativo de cmd.exe
            # 'start' es el resolvedor de shell más robusto disponible en Windows
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = "cmd.exe"
            $psi.Arguments = "/c start `"`" `"$PathOrUrl`" $Arguments"
            $psi.UseShellExecute = $false
            $psi.CreateNoWindow = $true
            $null = [System.Diagnostics.Process]::Start($psi)
            return $true
        }
        catch {
            # Propagar la excepción original si el fallback también falla
            throw $_
        }
    }
}

# Abre una sola plataforma o herramienta local
# Devuelve un objeto { Ok; Error }. Con -Quiet no muestra diálogos (modo lote)
function Start-DLauncherItem {
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Platform,
        [switch]$Quiet
    )

    $target = ""
    try {
        # Validar que la plataforma y la URL no sean nulos para evitar excepciones de referencia nula
        if ($null -eq $Platform -or [string]::IsNullOrWhiteSpace($Platform.Url)) {
            throw (T "err.noUrl")
        }

        $info = Resolve-DLauncherTarget -Value $Platform.Url
        $target = $info.Target

        switch ($info.Kind) {
            'Url' {
                # Navegador y perfil específicos, si están configurados e instalados
                $launch = $null
                if (-not [string]::IsNullOrEmpty($Platform.Browser)) {
                    $launch = Get-DLauncherBrowserLaunch -Key $Platform.Browser -ProfileId ([string]$Platform.BrowserProfile) -Url $target
                }
                if ($null -ne $launch) {
                    $null = Invoke-DLauncherSystemOpen -PathOrUrl $launch.File -Arguments $launch.Arguments
                } else {
                    $null = Invoke-DLauncherSystemOpen -PathOrUrl $target
                }
            }
            'Path' {
                # Intentar resolver ruta local con las utilidades de FileUtils.ps1
                $resolvedExe = Find-DLauncherExecutable -ExecutablePath $target
                if ($null -ne $resolvedExe) {
                    $null = Invoke-DLauncherSystemOpen -PathOrUrl $resolvedExe
                } elseif (Test-Path -LiteralPath $target -ErrorAction SilentlyContinue) {
                    # Carpetas y documentos
                    $null = Invoke-DLauncherSystemOpen -PathOrUrl $target
                } elseif ($target -notmatch '[\\/:]') {
                    # Nombre simple no encontrado (ej. alias de aplicación): dejar que Windows lo resuelva
                    $null = Invoke-DLauncherSystemOpen -PathOrUrl $target
                } else {
                    throw (T "err.notFound")
                }
            }
            default {
                # URI de protocolo personalizado (ej. ms-teams:, mailto:, shell:)
                $null = Invoke-DLauncherSystemOpen -PathOrUrl $target
            }
        }
        return [PSCustomObject]@{ Ok = $true; Error = $null }
    }
    catch {
        $errorMessage = $_.Exception.Message
        if (-not $Quiet) {
            Show-DLauncherMessageBox -Title (T "err.title") -Message (T "err.body" $Platform.Name $errorMessage $target) -OkText (T "common.accept")
        }
        return [PSCustomObject]@{ Ok = $false; Error = $errorMessage }
    }
}
