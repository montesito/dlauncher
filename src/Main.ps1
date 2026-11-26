# DLauncher - Main Orchestrator
# Punto de entrada: estado de la aplicación, eventos y orquestación de la interfaz

# Codificación UTF-8 de la consola (si existe) para eñes y acentos
try {
    $OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {
    # Sin consola asociada (ejecutable compilado con -noConsole)
}

$Global:DLauncherFootnote = "2026. DLauncher. by @montesito"
$Global:DLauncherVersion = "1.5.1"
$Global:DLauncherTermsVersion = "2026-11-26"
$Global:DLauncherManyThreshold = 10

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Directorio del script
$ScriptDir = $null
if ($null -ne $MyInvocation.MyCommand -and $null -ne $MyInvocation.MyCommand.Path) {
    $ScriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Path
}
if ([string]::IsNullOrEmpty($ScriptDir)) { $ScriptDir = $PSScriptRoot }
if ([string]::IsNullOrEmpty($ScriptDir)) { $ScriptDir = Get-Location }

# Módulos (en el ejecutable van incluidos en el script consolidado)
. (Join-Path -Path $ScriptDir -ChildPath "Utils\Preferences.ps1")
. (Join-Path -Path $ScriptDir -ChildPath "Utils\Localization.ps1")
. (Join-Path -Path $ScriptDir -ChildPath "Utils\FileUtils.ps1")
. (Join-Path -Path $ScriptDir -ChildPath "Config\DLauncherConfig.ps1")
. (Join-Path -Path $ScriptDir -ChildPath "Core\BrowserEngine.ps1")
. (Join-Path -Path $ScriptDir -ChildPath "Core\IconService.ps1")
. (Join-Path -Path $ScriptDir -ChildPath "Core\LauncherEngine.ps1")
. (Join-Path -Path $ScriptDir -ChildPath "Core\SuggestionCatalog.ps1")
. (Join-Path -Path $ScriptDir -ChildPath "UI\DLauncherThemes.ps1")
. (Join-Path -Path $ScriptDir -ChildPath "UI\DLauncherStyles.ps1")
. (Join-Path -Path $ScriptDir -ChildPath "UI\DLauncherUI.ps1")

# ===================== INSTANCIA ÚNICA =====================
# Una segunda ejecución solo trae al frente la ventana ya abierta (por usuario y perfil)
$instanceName = "DLauncher." + (($env:LOCALAPPDATA -replace '[\\/:]', '_').ToLowerInvariant())
$createdNew = $false
$Global:DLauncherMutex = New-Object System.Threading.Mutex($true, "Local\$instanceName.Instance", [ref]$createdNew)
$Global:DLauncherActivateEvent = New-Object System.Threading.EventWaitHandle($false, [System.Threading.EventResetMode]::AutoReset, "Local\$instanceName.Activate")
if (-not $createdNew) {
    $null = $Global:DLauncherActivateEvent.Set()
    return
}

# ===================== CONFIGURACIÓN INICIAL =====================
if (Test-DLauncherHasConfigFolder) {
    Initialize-DLauncherConfig
    $config = Get-DLauncherConfig
    # Sin memoria de selección: cada inicio usa la selección por defecto (solo se escribe si cambia algo)
    if ($config.Settings.RememberCheckState -eq $false) {
        $changed = $false
        foreach ($p in $config.Platforms) {
            if ([bool]$p.IsChecked -ne [bool]$p.CheckedByDefault) {
                $p.IsChecked = [bool]$p.CheckedByDefault
                $changed = $true
            }
        }
        if ($changed) { $null = Save-DLauncherConfig -Config $config }
    }
} elseif (Test-DLauncherConfigFolderMissing) {
    # La carpeta elegida no está (movida o unidad no disponible): se avisa al abrir, sin crear nada
    Initialize-DLauncherConfig
    $Global:DLauncherFolderMissing = $true
    Add-DLauncherConfigNotice -Kind 'missing' -Detail (Get-DLauncherConfigPointer)
}

$Global:ui = New-DLauncherWindow

$Global:DLauncherState = @{
    EditingPlatformId      = $null
    EditingGroupId         = $null
    ActiveOkCallback       = $null
    ActiveCancelCallback   = $null
    ActiveView             = ""
    Groups                 = @()
    Rows                   = [System.Collections.ArrayList]::new()
    CursorId               = $null
    SuppressCheckEvents    = $false
    SuppressSettingsEvents = $false
    SuppressSetupEvents    = $false
    SelectingHelpPage      = $false
    Launching              = $false
    LaunchQueue            = $null
    LaunchTotal            = 0
    LaunchDone             = 0
    LaunchErrors           = $null
    PendingBatch           = $null
    FormTags               = $null
    SettingsPage           = 'general'
    HelpPage               = 'faq'
    PaletteItems           = [System.Collections.ArrayList]::new()
    PaletteIndex           = 0
    UndoJson               = $null
    ToastAction            = $null
}
$Global:DLauncherDrag = @{ Row = $null; StartIndex = -1; HoverTag = $null }
$Global:DLauncherNavParts = @{}
$Global:DLauncherShownNotices = New-Object 'System.Collections.Generic.HashSet[string]'
$Global:DLauncherThemeDict = $null
$Global:DLauncherThemeMode = 'dark'

$Global:K = [System.Windows.Input.Key]
$Global:DLauncherFetchFavicons = $true

# ===================== UTILIDADES VISUALES =====================

$Global:DLauncherBrushConverter = [System.Windows.Media.BrushConverter]::new()
function Global:New-DLauncherBrush {
    param ([string]$Hex)
    $brush = $Global:DLauncherBrushConverter.ConvertFromString($Hex)
    $brush.Freeze()
    return $brush
}

function Global:New-DLauncherThickness {
    param ([double[]]$V)
    if ($V.Count -eq 1) { return [System.Windows.Thickness]::new($V[0]) }
    if ($V.Count -eq 2) { return [System.Windows.Thickness]::new($V[0], $V[1], $V[0], $V[1]) }
    return [System.Windows.Thickness]::new($V[0], $V[1], $V[2], $V[3])
}

# Los popups y menús no heredan los recursos de la ventana: se les añaden el tema y los estilos
function Global:Add-DLauncherThemeResources {
    param ($Element)
    $Element.Resources.MergedDictionaries.Add($Global:DLauncherThemeDict)
    $Element.Resources.MergedDictionaries.Add($Global:DLauncherStylesDict)
}

function Global:New-DLauncherAnimation {
    param (
        [double]$From,
        [double]$To,
        [int]$Milliseconds,
        [int]$DelayMs = 0
    )
    $anim = [System.Windows.Media.Animation.DoubleAnimation]::new()
    $anim.From = $From
    $anim.To = $To
    $anim.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds($Milliseconds))
    $anim.BeginTime = [TimeSpan]::FromMilliseconds($DelayMs)
    $ease = [System.Windows.Media.Animation.CubicEase]::new()
    $ease.EasingMode = [System.Windows.Media.Animation.EasingMode]::EaseOut
    $anim.EasingFunction = $ease
    return $anim
}

# Texto con color del tema
function Global:New-DLauncherText {
    param (
        [string]$Text,
        [double]$Size = 12.5,
        [string]$Brush = 'Fg.2',
        [switch]$Bold,
        [double[]]$Margin = @(0),
        [bool]$Wrap = $true,
        [double]$LineHeight = 0
    )
    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.Text = $Text
    $tb.FontSize = $Size
    $tb.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, $Brush)
    if ($Bold) { $tb.FontWeight = [System.Windows.FontWeights]::SemiBold }
    $tb.Margin = New-DLauncherThickness $Margin
    if ($Wrap) { $tb.TextWrapping = 'Wrap' }
    if ($LineHeight -gt 0) { $tb.LineHeight = $LineHeight }
    return $tb
}

# Logo vectorial como elemento WPF
function Global:New-DLauncherLogo {
    param ([double]$Size = 40)
    $xaml = $Global:DLauncherLogoXaml.Replace('<Canvas ', '<Canvas xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" ')
    $vb = New-Object System.Windows.Controls.Viewbox
    $vb.Width = $Size
    $vb.Height = $Size
    $vb.Child = [Windows.Markup.XamlReader]::Parse($xaml)
    return $vb
}

# ===================== PANELES SUPERPUESTOS =====================

# Muestra un panel con fundido y ligero zoom de la tarjeta
function Global:Show-DLauncherOverlay {
    param ($Overlay)
    $Overlay.Visibility = [System.Windows.Visibility]::Visible
    $Overlay.BeginAnimation([System.Windows.UIElement]::OpacityProperty, (New-DLauncherAnimation -From 0 -To 1 -Milliseconds 150))
    $card = $null
    foreach ($child in $Overlay.Children) {
        if ($child -is [System.Windows.Controls.Grid] -or $child -is [System.Windows.Controls.Border]) { $card = $child }
    }
    if ($null -ne $card) {
        $scale = [System.Windows.Media.ScaleTransform]::new(0.97, 0.97)
        $card.RenderTransformOrigin = [System.Windows.Point]::new(0.5, 0.5)
        $card.RenderTransform = $scale
        $anim = New-DLauncherAnimation -From 0.97 -To 1 -Milliseconds 220
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $anim)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $anim)
    }
}

function Global:Hide-DLauncherOverlay {
    param ($Overlay)
    $Overlay.Visibility = [System.Windows.Visibility]::Collapsed
}

# Panel abierto de mayor prioridad (el que recibe Esc)
function Global:Get-DLauncherOpenOverlay {
    foreach ($o in $ui.ConfirmOverlay, $ui.HelpOverlay, $ui.PaletteOverlay, $ui.SettingsOverlay, $ui.SuggestionsOverlay,
                   $ui.GroupOverlay, $ui.FormOverlay, $ui.TermsOverlay, $ui.SetupOverlay) {
        if ($o.Visibility -eq [System.Windows.Visibility]::Visible) { return $o }
    }
    return $null
}

# ===================== AVISOS BREVES =====================

$Global:DLauncherToastTimer = New-Object System.Windows.Threading.DispatcherTimer
$Global:DLauncherToastTimer.Add_Tick({ Hide-DLauncherToast })

function Global:Show-DLauncherToast {
    param (
        [string]$Text,
        [string]$ActionText = "",
        [ScriptBlock]$Action = $null,
        [string]$Kind = 'success'
    )
    $ui.ToastText.Text = $Text
    $dotKey = switch ($Kind) { 'warning' { 'Warning' } 'info' { 'Accent' } default { 'Success' } }
    $ui.ToastDot.SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, $dotKey)
    $Global:DLauncherState.ToastAction = $Action
    $Global:DLauncherState.UndoJson = $null
    if ($null -ne $Action -and $ActionText -ne "") {
        $ui.ToastActionText.Text = $ActionText
        $ui.ToastAction.Visibility = [System.Windows.Visibility]::Visible
        $ui.Toast.IsHitTestVisible = $true
        $Global:DLauncherToastTimer.Interval = [TimeSpan]::FromSeconds(7)
    } else {
        $ui.ToastAction.Visibility = [System.Windows.Visibility]::Collapsed
        $ui.Toast.IsHitTestVisible = $false
        $Global:DLauncherToastTimer.Interval = [TimeSpan]::FromMilliseconds(2600)
    }
    $ui.Toast.BeginAnimation([System.Windows.UIElement]::OpacityProperty, (New-DLauncherAnimation -From $ui.Toast.Opacity -To 1 -Milliseconds 160))
    $Global:DLauncherToastTimer.Stop()
    $Global:DLauncherToastTimer.Start()
}

function Global:Hide-DLauncherToast {
    $Global:DLauncherToastTimer.Stop()
    $ui.Toast.BeginAnimation([System.Windows.UIElement]::OpacityProperty, (New-DLauncherAnimation -From $ui.Toast.Opacity -To 0 -Milliseconds 300))
    $ui.Toast.IsHitTestVisible = $false
    $Global:DLauncherState.ToastAction = $null
    $Global:DLauncherState.UndoJson = $null
}

$ui.ToastAction.Add_Click({
    $action = $Global:DLauncherState.ToastAction
    $json = $Global:DLauncherState.UndoJson
    Hide-DLauncherToast
    $Global:DLauncherState.UndoJson = $json
    if ($null -ne $action) { & $action }
})

# ===================== DESHACER =====================

function Global:Show-DLauncherUndoToast {
    param ([string]$Text, [string]$Snapshot)
    Show-DLauncherToast -Text $Text -ActionText (T "common.undo") -Action { Invoke-DLauncherUndo } -Kind 'info'
    $Global:DLauncherState.UndoJson = $Snapshot
}

function Global:Invoke-DLauncherUndo {
    $json = $Global:DLauncherState.UndoJson
    if ([string]::IsNullOrEmpty($json)) { return }
    $Global:DLauncherState.UndoJson = $null
    try {
        Restore-DLauncherConfigSnapshot -Json $json
        Update-UIList
        Show-DLauncherToast (T "toast.restored")
    } catch {
        Show-DLauncherMessageBox -Title (T "err.title") -Message $_.Exception.Message
    }
}

# ===================== DIÁLOGOS =====================

$ui.BtnConfirmOk.Add_Click({
    Hide-DLauncherOverlay $ui.ConfirmOverlay
    $cb = $Global:DLauncherState.ActiveOkCallback
    $Global:DLauncherState.ActiveOkCallback = $null
    if ($null -ne $cb) { & $cb }
    Show-DLauncherConfigNotices
})

$ui.BtnConfirmCancel.Add_Click({
    Hide-DLauncherOverlay $ui.ConfirmOverlay
    $cb = $Global:DLauncherState.ActiveCancelCallback
    $Global:DLauncherState.ActiveCancelCallback = $null
    if ($null -ne $cb) { & $cb }
})

function Global:Show-DLauncherMessageBox {
    param (
        [string]$Title,
        [string]$Message,
        [string]$OkText = $null,
        [string]$CancelText = $null,
        [ScriptBlock]$OnOk = $null,
        [ScriptBlock]$OnCancel = $null,
        [switch]$Danger
    )
    $ui.ConfirmTitleText.Text = $Title
    $ui.ConfirmMessageText.Text = $Message
    $ui.BtnConfirmOk.Content = if ([string]::IsNullOrEmpty($OkText)) { T "common.accept" } else { $OkText }
    $ui.BtnConfirmOk.SetResourceReference([System.Windows.FrameworkElement]::StyleProperty, $(if ($Danger) { 'DangerButton' } else { 'PrimaryButton' }))
    $Global:DLauncherState.ActiveOkCallback = $OnOk
    $Global:DLauncherState.ActiveCancelCallback = $OnCancel
    if ([string]::IsNullOrEmpty($CancelText)) {
        $ui.BtnConfirmCancel.Visibility = [System.Windows.Visibility]::Collapsed
    } else {
        $ui.BtnConfirmCancel.Content = $CancelText
        $ui.BtnConfirmCancel.Visibility = [System.Windows.Visibility]::Visible
    }
    Show-DLauncherOverlay $ui.ConfirmOverlay
}

# Avisos de configuración pendientes (archivo dañado, bloqueado, sin permisos...)
function Global:Show-DLauncherConfigNotices {
    if ($Global:DLauncherConfigNotices.Count -eq 0) { return }
    if ($ui.ConfirmOverlay.Visibility -eq [System.Windows.Visibility]::Visible) { return }
    $notice = $Global:DLauncherConfigNotices[0]
    $Global:DLauncherConfigNotices.Clear()
    if ($notice.Kind -eq 'missing') {
        # Aviso antiguo: la carpeta ya ha vuelto
        if (-not (Test-DLauncherConfigFolderMissing)) { Update-DLauncherStatusBar; return }
        # Carpeta no encontrada: una vez por episodio, con opción de elegir la nueva ubicación
        $Global:DLauncherFolderMissing = $true
        Update-DLauncherStatusBar
        if ($Global:DLauncherMissingShown) { return }
        $Global:DLauncherMissingShown = $true
        Show-DLauncherMessageBox -Title (T "notice.missing.title") -Message (T "notice.missing.body" $notice.Detail) `
            -OkText (T "missing.choose") -CancelText (T "missing.later") -OnOk { Invoke-DLauncherChooseConfigFolder }
        return
    }
    Update-DLauncherStatusBar
    # Los avisos repetibles (bloqueo, error al guardar) se muestran una vez por sesión
    if ($notice.Kind -in 'locked', 'saveFailed') {
        if (-not $Global:DLauncherShownNotices.Add($notice.Kind)) { return }
    }
    Show-DLauncherMessageBox -Title (T "notice.$($notice.Kind).title") -Message (T "notice.$($notice.Kind).body" $notice.Detail)
}

# ===================== DESPLEGABLES =====================

function Global:Set-DLauncherComboItems {
    param ($Combo, $Items, [string]$Selected)
    $Combo.Items.Clear()
    $selectedItem = $null
    foreach ($it in $Items) {
        $ci = [System.Windows.Controls.ComboBoxItem]::new()
        $ci.Content = $it.Text
        $ci.Tag = [string]$it.Value
        $null = $Combo.Items.Add($ci)
        if ([string]$it.Value -eq [string]$Selected) { $selectedItem = $ci }
    }
    if ($null -eq $selectedItem -and $Combo.Items.Count -gt 0) { $selectedItem = $Combo.Items[0] }
    $Combo.SelectedItem = $selectedItem
}

function Global:Get-DLauncherComboValue {
    param ($Combo)
    if ($null -ne $Combo.SelectedItem) { return [string]$Combo.SelectedItem.Tag }
    return ""
}

# ===================== TEMA =====================

function Global:Set-DLauncherTheme {
    param ([string]$Mode, [switch]$Persist)
    if (@('dark', 'light', 'system') -notcontains $Mode) { $Mode = 'dark' }
    $Global:DLauncherThemeMode = $Mode
    $effective = Get-DLauncherEffectiveTheme -Mode $Mode
    $Global:DLauncherThemeName = $effective

    $dict = New-DLauncherThemeDictionary -Name $effective
    $merged = $ui.Window.Resources.MergedDictionaries
    if ($null -ne $Global:DLauncherThemeDict) { $null = $merged.Remove($Global:DLauncherThemeDict) }
    $merged.Insert(0, $dict)
    $Global:DLauncherThemeDict = $dict

    try { $ui.ShadowBorder.Effect.Opacity = $(if ($effective -eq 'light') { 0.2 } else { 0.55 }) } catch { }
    # El icono muestra el tema al que se cambiará
    $iconName = if ($effective -eq 'dark') { 'sun' } else { 'moon' }
    $ui.ThemeIcon.Data = [System.Windows.Media.Geometry]::Parse($Global:DLauncherIcons[$iconName].D)
    $ui.StatusThemeText.Text = T "theme.$Mode"
    if ($Persist) { Set-DLauncherPref -Name 'Theme' -Value $Mode }
}

function Global:Switch-DLauncherThemeQuick {
    $next = if ($Global:DLauncherThemeName -eq 'dark') { 'light' } else { 'dark' }
    Set-DLauncherTheme -Mode $next -Persist
    Sync-DLauncherSetupChoices
}

# ===================== FECHA Y VENTANA =====================

function Global:Update-DLauncherDate {
    $lang = Get-DLauncherLanguageInfo
    $culture = [System.Globalization.CultureInfo]::GetCultureInfo($lang.Culture)
    $date = (Get-Date).ToString($lang.DateFormat, $culture)
    $ui.DateText.Text = $date.Substring(0, 1).ToUpper() + $date.Substring(1)
}

# Tamaño y posición: se recuerdan por equipo y se ajustan siempre a la pantalla disponible
function Global:Initialize-DLauncherWindowBounds {
    $wa = [System.Windows.SystemParameters]::WorkArea
    $ui.Window.MinHeight = [Math]::Min([double]540, [double]$wa.Height)
    $ui.Window.MinWidth = [Math]::Min([double]760, [double]$wa.Width)
    $w = [Math]::Min([double]1060, [double]$wa.Width)
    $h = [Math]::Min([double]740, [double]$wa.Height)
    $left = $wa.Left + ($wa.Width - $w) / 2
    $top = $wa.Top + ($wa.Height - $h) / 2

    $saved = Get-DLauncherPref -Name 'Window'
    if ($null -ne $saved) {
        try {
            $sw = [double]$saved.Width; $sh = [double]$saved.Height
            $sl = [double]$saved.Left; $st = [double]$saved.Top
            $vl = [System.Windows.SystemParameters]::VirtualScreenLeft
            $vt = [System.Windows.SystemParameters]::VirtualScreenTop
            $vw = [System.Windows.SystemParameters]::VirtualScreenWidth
            $vh = [System.Windows.SystemParameters]::VirtualScreenHeight
            $onScreen = ($sl -ge ($vl - 40)) -and ($st -ge ($vt - 10)) -and (($sl + 160) -le ($vl + $vw)) -and (($st + 80) -le ($vt + $vh))
            if ($onScreen -and $sw -ge $ui.Window.MinWidth -and $sh -ge $ui.Window.MinHeight) {
                $w = [Math]::Min([double]$sw, [double]$vw)
                $h = [Math]::Min([double]$sh, [double]$vh)
                $left = $sl
                $top = $st
            }
        } catch { }
    }
    $ui.Window.Width = $w
    $ui.Window.Height = $h
    $ui.Window.Left = $left
    $ui.Window.Top = $top
}

function Global:Update-DLauncherSidebarVisibility {
    $show = -not [bool](Get-DLauncherPref -Name 'SidebarHidden' -Default $false)
    $ui.SidebarColumn.Width = [System.Windows.GridLength]::new($(if ($show) { 236 } else { 0 }))
    $ui.Sidebar.Visibility = if ($show) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
    $ui.BtnAddHeader.Visibility = if ($show) { [System.Windows.Visibility]::Collapsed } else { [System.Windows.Visibility]::Visible }
}

function Global:Switch-DLauncherSidebar {
    $hidden = [bool](Get-DLauncherPref -Name 'SidebarHidden' -Default $false)
    Set-DLauncherPref -Name 'SidebarHidden' -Value (-not $hidden)
    Update-DLauncherSidebarVisibility
}

# ===================== ICONOS =====================

# Rellena un mosaico de icono: favicon, icono de la aplicación, carpeta o inicial con color
function Global:Set-DLauncherIconTile {
    param ($Tile, $Letter, $Image, $Glyph, [string]$Name, [string]$Url, $PendingHosts = $null, [double]$WebSize = 18, [double]$AppSize = 22)

    $info = Resolve-DLauncherTarget -Value $Url
    $source = $null
    $isFolder = $false
    $isWeb = $false

    if ($info.Kind -eq 'Url' -and -not [string]::IsNullOrEmpty($info.Host) -and $Global:DLauncherFetchFavicons) {
        $isWeb = $true
        $source = Get-DLauncherCachedFavicon -UrlHost $info.Host
        if ($null -eq $source -and $null -ne $PendingHosts -and (Test-DLauncherFaviconPending -UrlHost $info.Host)) {
            $null = $PendingHosts.Add($info.Host)
        }
    } elseif ($info.Kind -eq 'Path') {
        if (Test-DLauncherNetworkPath -Path $info.Target) {
            # Rutas de red: la interfaz no accede al disco (un recurso caído la bloquearía)
            $ext = ""
            try { $ext = [System.IO.Path]::GetExtension($info.Target) } catch { }
            $isFolder = [string]::IsNullOrEmpty($ext)
        } elseif (Test-Path -LiteralPath $info.Target -PathType Container -ErrorAction SilentlyContinue) {
            $isFolder = $true
        } else {
            $exe = Find-DLauncherExecutable -ExecutablePath $info.Target
            if ($null -ne $exe) { $source = Get-DLauncherFileIcon -Path $exe }
        }
    }

    $Glyph.Visibility = [System.Windows.Visibility]::Collapsed
    $Letter.Text = ""
    $Image.Source = $null

    if ($null -ne $source) {
        $Image.Source = $source
        if ($isWeb) {
            $Tile.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, 'Favicon.Bg')
            $Image.Width = $WebSize; $Image.Height = $WebSize
        } else {
            $Tile.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, 'Tile.Bg')
            $Image.Width = $AppSize; $Image.Height = $AppSize
        }
    } elseif ($isFolder) {
        $Tile.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, 'Accent.Soft')
        $Glyph.Visibility = [System.Windows.Visibility]::Visible
    } else {
        $n = ([string]$Name).Trim()
        $Letter.Text = if ($n.Length -gt 0) { $n.Substring(0, 1).ToUpper() } else { "?" }
        $Tile.Background = New-DLauncherBrush (Get-DLauncherAvatarColor -Seed $n)
    }
}

function Global:Set-DLauncherRowIcon {
    param ($Row, $PendingHosts)
    Set-DLauncherIconTile -Tile $Row.IconTile -Letter $Row.IconLetter -Image $Row.IconImage -Glyph $Row.IconGlyph `
        -Name $Row.Platform.Name -Url $Row.Platform.Url -PendingHosts $PendingHosts
}

# Al terminar la descarga de favicons, refrescar solo las filas afectadas
$Global:DLauncherFaviconOnComplete = {
    param ($Hosts)
    foreach ($r in $Global:DLauncherState.Rows) {
        $info = Resolve-DLauncherTarget -Value $r.Platform.Url
        if ($info.Kind -eq 'Url' -and $Hosts -contains $info.Host) {
            Set-DLauncherRowIcon -Row $r -PendingHosts $null
        }
    }
}

# ===================== ETIQUETAS =====================
# Internamente se almacenan como "Groups"; cada herramienta referencia sus etiquetas en "Tags"

function Global:Get-DLauncherTagColor {
    param ([string]$TagId)
    $g = $Global:DLauncherState.Groups | Where-Object { $_.Id -eq $TagId } | Select-Object -First 1
    if ($null -ne $g -and -not [string]::IsNullOrEmpty([string]$g.Color)) { return [string]$g.Color }
    return $Global:DLauncherTagPalette[0]
}

function Global:Get-DLauncherGroupName {
    param ([string]$GroupId)
    if ([string]::IsNullOrEmpty($GroupId)) { return "" }
    $g = $Global:DLauncherState.Groups | Where-Object { $_.Id -eq $GroupId } | Select-Object -First 1
    if ($null -ne $g) { return [string]$g.Name }
    return ""
}

function Global:Test-DLauncherTagView {
    param ([string]$View)
    return (-not [string]::IsNullOrEmpty($View) -and -not $View.StartsWith('::'))
}

# Pastilla de etiqueta en la fila: punto de color + nombre
function Global:New-DLauncherTagPill {
    param ([string]$TagId, [string]$Text)
    $pill = New-Object System.Windows.Controls.Border
    $pill.CornerRadius = [System.Windows.CornerRadius]::new(6)
    $pill.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, 'Subtle.Bg')
    $pill.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, 'Border')
    $pill.BorderThickness = [System.Windows.Thickness]::new(1)
    $pill.Padding = [System.Windows.Thickness]::new(6, 1, 7, 2)
    $pill.Margin = [System.Windows.Thickness]::new(6, 0, 0, 0)
    $pill.VerticalAlignment = 'Center'
    $pill.Tag = $TagId
    $panel = New-Object System.Windows.Controls.StackPanel
    $panel.Orientation = 'Horizontal'
    $dot = New-Object System.Windows.Shapes.Ellipse
    $dot.Width = 6; $dot.Height = 6
    $dot.Fill = New-DLauncherBrush (Get-DLauncherTagColor -TagId $TagId)
    $dot.VerticalAlignment = 'Center'
    $dot.Margin = [System.Windows.Thickness]::new(0, 0, 5, 0)
    $label = New-DLauncherText -Text $Text -Size 10.5 -Brush 'Fg.2' -Wrap $false
    $null = $panel.Children.Add($dot)
    $null = $panel.Children.Add($label)
    $pill.Child = $panel
    return $pill
}

# ===================== BARRA LATERAL =====================

function Global:New-DLauncherNavItem {
    param ([string]$Key, [string]$Text, [int]$Count = -1, [string]$Icon = "", [string]$Color = "")

    $item = New-Object System.Windows.Controls.Border
    $item.Tag = $Key
    $item.CornerRadius = [System.Windows.CornerRadius]::new(7)
    $item.Margin = [System.Windows.Thickness]::new(8, 1, 9, 1)
    $item.Padding = [System.Windows.Thickness]::new(10, 0, 5, 0)
    $item.Height = 32
    $item.Background = [System.Windows.Media.Brushes]::Transparent
    $item.BorderThickness = [System.Windows.Thickness]::new(1)
    $item.BorderBrush = [System.Windows.Media.Brushes]::Transparent
    $item.Cursor = [System.Windows.Input.Cursors]::Hand

    $grid = New-Object System.Windows.Controls.Grid
    foreach ($w in 'Auto', '*', 'Auto') {
        $cd = New-Object System.Windows.Controls.ColumnDefinition
        $cd.Width = [System.Windows.GridLengthConverter]::new().ConvertFromString($w)
        $null = $grid.ColumnDefinitions.Add($cd)
    }

    $iconEl = $null
    $iconFill = $false
    if ($Color -ne "") {
        $iconEl = New-Object System.Windows.Shapes.Ellipse
        $iconEl.Width = 8; $iconEl.Height = 8
        $iconEl.Fill = New-DLauncherBrush $Color
        $iconEl.Margin = [System.Windows.Thickness]::new(3, 0, 12, 0)
        $iconEl.VerticalAlignment = 'Center'
    } elseif ($Icon -ne "") {
        $iconEl = New-DLauncherIconPath -Name $Icon -Size 15 -BrushKey 'Fg.3'
        $iconEl.Margin = [System.Windows.Thickness]::new(0, 0, 10, 0)
        $iconFill = [bool]$Global:DLauncherIcons[$Icon].Fill
    }
    if ($null -ne $iconEl) { $null = $grid.Children.Add($iconEl) }

    $label = New-DLauncherText -Text $Text -Size 12.5 -Brush 'Fg.2' -Wrap $false
    $label.TextTrimming = 'CharacterEllipsis'
    $label.VerticalAlignment = 'Center'
    [System.Windows.Controls.Grid]::SetColumn($label, 1)
    $null = $grid.Children.Add($label)

    $countText = New-DLauncherText -Text $(if ($Count -ge 0) { [string]$Count } else { "" }) -Size 11 -Brush 'Fg.4' -Wrap $false -Margin @(6, 0, 5, 0)
    $countText.VerticalAlignment = 'Center'
    [System.Windows.Controls.Grid]::SetColumn($countText, 2)
    $null = $grid.Children.Add($countText)

    $actions = New-Object System.Windows.Controls.StackPanel
    $actions.Orientation = 'Horizontal'
    $actions.Visibility = [System.Windows.Visibility]::Collapsed
    [System.Windows.Controls.Grid]::SetColumn($actions, 2)
    $null = $grid.Children.Add($actions)

    $item.Child = $grid
    $Global:DLauncherNavParts[$Key] = @{
        Item = $item; Text = $label; Icon = $iconEl; IconFill = $iconFill; IsDot = ($Color -ne ""); Count = $countText; Actions = $actions
    }

    $item.Add_MouseEnter({
        param($s, $e)
        $p = $Global:DLauncherNavParts[[string]$s.Tag]
        if ($null -eq $p) { return }
        if ($p.Actions.Children.Count -gt 0) {
            $p.Actions.Visibility = [System.Windows.Visibility]::Visible
            $p.Count.Visibility = [System.Windows.Visibility]::Collapsed
        }
        if ([string]$s.Tag -ne $Global:DLauncherState.ActiveView -and $null -eq $Global:DLauncherDrag.Row) {
            $s.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, 'Hover.Bg')
        }
    })
    $item.Add_MouseLeave({
        param($s, $e)
        $p = $Global:DLauncherNavParts[[string]$s.Tag]
        if ($null -eq $p) { return }
        $p.Actions.Visibility = [System.Windows.Visibility]::Collapsed
        $p.Count.Visibility = [System.Windows.Visibility]::Visible
        if ($null -eq $Global:DLauncherDrag.Row) { Update-DLauncherNavStyles }
    })
    $item.Add_MouseLeftButtonUp({
        param($s, $e)
        Invoke-DLauncherNavItem -Key ([string]$s.Tag)
    })
    return $item
}

# Botón pequeño para las acciones de un elemento de la barra lateral
function Global:New-DLauncherNavAction {
    param ([string]$Icon, [string]$BrushKey, [string]$Tag, [string]$Tip, [double]$Size = 9)
    $btn = New-Object System.Windows.Controls.Button
    $btn.SetResourceReference([System.Windows.FrameworkElement]::StyleProperty, 'IconButton')
    $btn.Width = 22; $btn.Height = 22
    $btn.Tag = $Tag
    $btn.ToolTip = $Tip
    $btn.Content = New-DLauncherIconPath -Name $Icon -Size $Size -BrushKey $BrushKey -Thickness 1.7
    return $btn
}

function Global:Update-DLauncherNavStyles {
    foreach ($key in @($Global:DLauncherNavParts.Keys)) {
        $p = $Global:DLauncherNavParts[$key]
        $active = ([string]$key -eq [string]$Global:DLauncherState.ActiveView)
        if ($active) {
            $p.Item.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, 'Active.Bg')
            $p.Text.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, 'Fg.1')
            $p.Text.FontWeight = [System.Windows.FontWeights]::SemiBold
        } else {
            $p.Item.Background = [System.Windows.Media.Brushes]::Transparent
            $p.Text.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, 'Fg.2')
            $p.Text.FontWeight = [System.Windows.FontWeights]::Normal
        }
        $p.Item.BorderBrush = [System.Windows.Media.Brushes]::Transparent
        if ($null -ne $p.Icon -and -not $p.IsDot) {
            $prop = if ($p.IconFill) { [System.Windows.Shapes.Shape]::FillProperty } else { [System.Windows.Shapes.Shape]::StrokeProperty }
            $p.Icon.SetResourceReference($prop, $(if ($active) { 'Accent.Text' } else { 'Fg.3' }))
        }
    }
}

function Global:Update-DLauncherSidebar {
    param ($Config)
    $ui.LibraryList.Children.Clear()
    $ui.TagList.Children.Clear()
    $ui.UtilityList.Children.Clear()
    $Global:DLauncherNavParts = @{}

    $platforms = if ($null -ne $Config) { @($Config.Platforms) } else { @() }
    $checkedCount = @($platforms | Where-Object { [bool]$_.IsChecked }).Count

    $null = $ui.LibraryList.Children.Add((New-DLauncherNavItem -Key "" -Text (T "side.all") -Count $platforms.Count -Icon 'grid'))
    $null = $ui.LibraryList.Children.Add((New-DLauncherNavItem -Key "::selected" -Text (T "side.selected") -Count $checkedCount -Icon 'checked'))

    $groups = if ($null -ne $Config) { @($Config.Groups) } else { @() }
    foreach ($g in $groups) {
        $count = @($platforms | Where-Object { @($_.Tags) -contains $g.Id }).Count
        $item = New-DLauncherNavItem -Key $g.Id -Text $g.Name -Count $count -Color (Get-DLauncherTagColor -TagId $g.Id)
        $item.ToolTip = T "side.tag.tip"
        $parts = $Global:DLauncherNavParts[[string]$g.Id]

        $play = New-DLauncherNavAction -Icon 'play' -BrushKey 'Success' -Tag $g.Id -Tip (T "side.openTag.tip") -Size 8
        $play.Add_Click({ param($s, $e) Start-DLauncherTagLaunch -TagId ([string]$s.Tag) })
        $del = New-DLauncherNavAction -Icon 'close' -BrushKey 'Fg.3' -Tag $g.Id -Tip (T "group.delete") -Size 8
        $del.Add_Click({ param($s, $e) Request-DLauncherTagDelete -GroupId ([string]$s.Tag) })
        $null = $parts.Actions.Children.Add($play)
        $null = $parts.Actions.Children.Add($del)

        # Doble clic: renombrar
        $item.Add_MouseLeftButtonDown({
            param($s, $e)
            if ($e.ClickCount -eq 2) {
                Show-DLauncherGroupForm -GroupId ([string]$s.Tag)
                $e.Handled = $true
            }
        })
        $null = $ui.TagList.Children.Add($item)
    }
    $ui.TagsEmptyText.Visibility = if ($groups.Count -eq 0) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }

    $null = $ui.UtilityList.Children.Add((New-DLauncherNavItem -Key "::suggestions" -Text (T "side.suggestions") -Icon 'sparkle'))
    $null = $ui.UtilityList.Children.Add((New-DLauncherNavItem -Key "::help" -Text (T "side.help") -Icon 'help'))
    $null = $ui.UtilityList.Children.Add((New-DLauncherNavItem -Key "::settings" -Text (T "side.settings") -Icon 'sliders'))

    Update-DLauncherNavStyles
}

function Global:Invoke-DLauncherNavItem {
    param ([string]$Key)
    switch ($Key) {
        '::suggestions' { Show-DLauncherSuggestions }
        '::help'        { Show-DLauncherHelp }
        '::settings'    { Show-DLauncherSettings }
        default         { Select-DLauncherView -View $Key }
    }
}

function Global:Select-DLauncherView {
    param ([string]$View)
    if ($Global:DLauncherState.ActiveView -eq $View) { return }
    $Global:DLauncherState.ActiveView = $View
    if (Test-DLauncherHasConfigFolder) {
        Set-DLauncherSetting -Name "ActiveGroupId" -Value $View
    }
    Update-DLauncherNavStyles
    Update-DLauncherHeader
    Update-DLauncherFilter -Animate
}

function Global:Update-DLauncherHeader {
    $view = $Global:DLauncherState.ActiveView
    $ui.ViewDot.Visibility = [System.Windows.Visibility]::Collapsed
    if ($view -eq "") {
        $title = T "view.all"
    } elseif ($view -eq '::selected') {
        $title = T "view.selected"
    } else {
        $title = Get-DLauncherGroupName -GroupId $view
        $ui.ViewDot.Fill = New-DLauncherBrush (Get-DLauncherTagColor -TagId $view)
        $ui.ViewDot.Visibility = [System.Windows.Visibility]::Visible
    }
    $ui.ViewTitle.Text = $title
    $ui.ViewCrumbText.Text = "/   $title"
}

# ===================== LISTADO =====================

function Global:Get-DLauncherRow {
    param ([string]$Id)
    foreach ($r in $Global:DLauncherState.Rows) {
        if ($r.Platform.Id -eq $Id) { return $r }
    }
    return $null
}

# Redibuja la lista completa a partir de la configuración (tras cambios de datos)
function Global:Update-UIList {
    $ui.ListPanel.Children.Clear()
    $Global:DLauncherState.Rows.Clear()

    if (-not (Test-DLauncherHasConfigFolder)) {
        $Global:DLauncherState.Groups = @()
        Update-DLauncherSidebar -Config $null
        Update-DLauncherHeader
        Update-DLauncherFilter
        Update-DLauncherDelayText
        Update-DLauncherStatusBar
        return
    }

    $cfg = Get-DLauncherConfig
    $Global:DLauncherState.Groups = @($cfg.Groups)
    $Global:DLauncherFetchFavicons = [bool]$cfg.Settings.FetchFavicons

    # Validar que la vista activa sigue existiendo
    $active = [string]$cfg.Settings.ActiveGroupId
    if ((Test-DLauncherTagView -View $active) -and -not ($cfg.Groups | Where-Object { $_.Id -eq $active })) { $active = "" }
    if ($active.StartsWith('::') -and $active -ne '::selected') { $active = "" }
    $Global:DLauncherState.ActiveView = $active

    Update-DLauncherSidebar -Config $cfg
    Update-DLauncherHeader

    $pendingHosts = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($platform in @($cfg.Platforms)) {
        $row = New-DLauncherPlatformRow -Platform $platform
        if ($null -eq $row) { continue }

        Update-DLauncherLocalizedTree -Root $row.Element
        $row.SearchKey = ConvertTo-DLauncherSearchKey ("{0} {1}" -f $platform.Name, $platform.Url)

        foreach ($tagId in @($platform.Tags)) {
            $tagName = Get-DLauncherGroupName -GroupId $tagId
            if ($tagName -ne "") {
                $null = $row.TagPanel.Children.Add((New-DLauncherTagPill -TagId $tagId -Text $tagName))
            }
        }
        $browserLabel = Get-DLauncherBrowserLabel -Key $platform.Browser -ProfileId $platform.BrowserProfile
        if ($browserLabel -ne "") {
            $row.BrowserPillText.Text = $browserLabel
            $row.BrowserPill.Visibility = [System.Windows.Visibility]::Visible
        }

        Set-DLauncherRowIcon -Row $row -PendingHosts $pendingHosts

        # Eventos (sin closures: cada control lleva el Id de su herramienta en Tag)
        $row.ItemCheck.Add_Checked({ param($s, $e) Set-DLauncherRowChecked -Id ([string]$s.Tag) -IsChecked $true })
        $row.ItemCheck.Add_Unchecked({ param($s, $e) Set-DLauncherRowChecked -Id ([string]$s.Tag) -IsChecked $false })
        $row.BtnPlay.Add_Click({ param($s, $e) Start-DLauncherSingle -Id ([string]$s.Tag) })
        $row.BtnEdit.Add_Click({ param($s, $e) Show-DLauncherPlatformForm -PlatformId ([string]$s.Tag) })
        $row.BtnTag.Add_Click({ param($s, $e) Show-DLauncherTagPopup -PlatformId ([string]$s.Tag) -Target $s })
        $row.BtnMore.Add_Click({ param($s, $e) Show-DLauncherRowMenu -PlatformId ([string]$s.Tag) -Target $s })
        $row.DragHandle.Add_MouseLeftButtonDown({ param($s, $e) Start-DLauncherRowDrag -RowElement $s.Tag -MouseEvent $e })
        $row.Element.Add_MouseLeftButtonDown({
            param($s, $e)
            if ($e.ClickCount -eq 2) {
                Start-DLauncherSingle -Id ([string]$s.Tag)
                $e.Handled = $true
            } else {
                Set-DLauncherCursor -Id ([string]$s.Tag)
            }
        })
        $row.Element.Add_MouseRightButtonUp({
            param($s, $e)
            Show-DLauncherRowMenu -PlatformId ([string]$s.Tag) -Target $s -AtPointer
            $e.Handled = $true
        })

        $null = $Global:DLauncherState.Rows.Add($row)
        $null = $ui.ListPanel.Children.Add($row.Element)
    }

    if ($pendingHosts.Count -gt 0) {
        Start-DLauncherFaviconFetch -Hosts @($pendingHosts)
    }

    Update-DLauncherFilter
    Update-DLauncherDelayText
    Update-DLauncherStatusBar
    Show-DLauncherConfigNotices
}

function Global:Test-DLauncherInView {
    param ($Platform, [string]$View)
    if ($View -eq "") { return $true }
    if ($View -eq '::selected') { return [bool]$Platform.IsChecked }
    return (@($Platform.Tags) -contains $View)
}

# Aplica vista + búsqueda mostrando u ocultando filas (sin reconstruir)
function Global:Update-DLauncherFilter {
    param ([switch]$Animate)

    $query = ConvertTo-DLauncherSearchKey $ui.SearchBox.Text.Trim()
    $view = $Global:DLauncherState.ActiveView
    $first = $null
    $visibleIndex = 0
    $cursorVisible = $false

    foreach ($r in $Global:DLauncherState.Rows) {
        $show = (Test-DLauncherInView -Platform $r.Platform -View $view) -and ($query -eq "" -or $r.SearchKey.Contains($query))
        if ($show) {
            $r.Element.Visibility = [System.Windows.Visibility]::Visible
            if ($null -eq $first) { $first = $r }
            if ($r.Platform.Id -eq $Global:DLauncherState.CursorId) { $cursorVisible = $true }
            if ($Animate) {
                $shift = [System.Windows.Media.TranslateTransform]::new(0, 8)
                $r.Element.RenderTransform = $shift
                $delay = [Math]::Min($visibleIndex * 22, 300)
                $r.Element.BeginAnimation([System.Windows.UIElement]::OpacityProperty, (New-DLauncherAnimation -From 0 -To 1 -Milliseconds 260 -DelayMs $delay))
                $shift.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, (New-DLauncherAnimation -From 8 -To 0 -Milliseconds 300 -DelayMs $delay))
            }
            $visibleIndex++
        } else {
            $r.Element.Visibility = [System.Windows.Visibility]::Collapsed
        }
        # La etiqueta de la vista activa es redundante en la fila
        foreach ($pill in $r.TagPanel.Children) {
            $pill.Visibility = if ((Test-DLauncherTagView -View $view) -and [string]$pill.Tag -eq $view) { [System.Windows.Visibility]::Collapsed } else { [System.Windows.Visibility]::Visible }
        }
    }

    # Al buscar, el primer resultado queda preseleccionado (Enter lo abre)
    if ($query -ne "") {
        Set-DLauncherCursor -Id $(if ($null -ne $first) { $first.Platform.Id } else { $null })
    } elseif (-not $cursorVisible) {
        Set-DLauncherCursor -Id $null
    }

    $total = $Global:DLauncherState.Rows.Count
    $hasFolder = Test-DLauncherHasConfigFolder
    $ui.EmptyStatePanel.Visibility = if ($total -eq 0 -and $hasFolder) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
    if ($total -gt 0 -and $visibleIndex -eq 0) {
        $ui.NoResultsPanel.Visibility = [System.Windows.Visibility]::Visible
        if ($query -ne "") {
            $ui.NoResultsTitle.Text = T "noresults.title"
            $ui.NoResultsText.Text = T "noresults.body" $ui.SearchBox.Text.Trim()
        } elseif ($view -eq '::selected') {
            $ui.NoResultsTitle.Text = T "emptysel.title"
            $ui.NoResultsText.Text = T "emptysel.body"
        } else {
            $ui.NoResultsTitle.Text = T "emptygroup.title"
            $ui.NoResultsText.Text = T "emptygroup.body"
        }
    } else {
        $ui.NoResultsPanel.Visibility = [System.Windows.Visibility]::Collapsed
    }

    Update-DLauncherStatus
}

function Global:Get-DLauncherVisibleRows {
    return @($Global:DLauncherState.Rows | Where-Object { $_.Element.Visibility -eq [System.Windows.Visibility]::Visible })
}

# Contadores, cabecera y botón principal
function Global:Update-DLauncherStatus {
    $visible = @(Get-DLauncherVisibleRows)
    $checked = @($visible | Where-Object { $_.ItemCheck.IsChecked -eq $true }).Count
    $checkedAll = @($Global:DLauncherState.Rows | Where-Object { $_.ItemCheck.IsChecked -eq $true }).Count

    if ($visible.Count -eq 0) {
        $ui.StatusText.Text = ""
        $ui.BtnToggleAll.Visibility = [System.Windows.Visibility]::Collapsed
    } else {
        $ui.StatusText.Text = T "status.selected" $checked $visible.Count
        $ui.BtnToggleAll.Visibility = [System.Windows.Visibility]::Visible
        $ui.ToggleAllText.Text = if ($checked -eq $visible.Count) { T "toggle.clear" } else { T "toggle.select" }
    }
    $ui.ViewSubtitle.Text = if ($Global:DLauncherState.Rows.Count -eq 0) { "" } else { T "view.subtitle" $visible.Count $checked }

    $selParts = $Global:DLauncherNavParts['::selected']
    if ($null -ne $selParts) { $selParts.Count.Text = [string]$checkedAll }

    if (-not $Global:DLauncherState.Launching) {
        $view = $Global:DLauncherState.ActiveView
        $label = if (Test-DLauncherTagView -View $view) { T "open.group" (Get-DLauncherGroupName -GroupId $view) } else { T "open" }
        $ui.OpenAllText.Text = if ($checked -gt 0) { "$label  ($checked)" } else { $label }
        $ui.BtnOpenAll.IsEnabled = ($checked -gt 0)
    }
}

function Global:Update-DLauncherStatusBar {
    if ($Global:DLauncherState.Launching) { return }
    $hasFolder = Test-DLauncherHasConfigFolder
    if ($Global:DLauncherFolderMissing) {
        $ui.StatusDot.SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, 'Warning')
        $ui.StatusBarText.Text = T "statusbar.missing"
    } elseif ($Global:DLauncherConfigReadOnly) {
        $ui.StatusDot.SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, 'Warning')
        $ui.StatusBarText.Text = T "statusbar.readonly"
    } elseif (-not $hasFolder) {
        $ui.StatusDot.SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, 'Fg.4')
        $ui.StatusBarText.Text = T "statusbar.noFolder"
    } else {
        $ui.StatusDot.SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, 'Success')
        $ui.StatusBarText.Text = T "statusbar.ready" $Global:DLauncherState.Rows.Count
    }
    if ($hasFolder -and -not [string]::IsNullOrEmpty($Global:ConfigDir)) {
        $ui.StatusFolderText.Text = $Global:ConfigDir
        $ui.BtnStatusFolder.Visibility = [System.Windows.Visibility]::Visible
    } else {
        $ui.BtnStatusFolder.Visibility = [System.Windows.Visibility]::Collapsed
    }
    $ui.StatusLanguageText.Text = $Global:DLauncherLanguage.ToUpperInvariant()
    $ui.StatusVersionText.Text = "v$($Global:DLauncherVersion)"
    $ui.FooterText.Text = $Global:DLauncherFootnote
}

function Global:Update-DLauncherDelayText {
    $delay = 500
    if (Test-DLauncherHasConfigFolder) {
        try { $delay = [int](Get-DLauncherConfig).Settings.LaunchDelayMs } catch { }
    }
    $ui.DelayText.Text = T "delay.status" (Get-DLauncherDelayLabel -Value ([string]$delay))
}

function Global:Set-DLauncherRowChecked {
    param ([string]$Id, [bool]$IsChecked)
    $r = Get-DLauncherRow -Id $Id
    if ($null -ne $r) { $r.Platform.IsChecked = $IsChecked }
    if (-not $Global:DLauncherState.SuppressCheckEvents) {
        Set-DLauncherPlatformChecked -Ids @($Id) -IsChecked $IsChecked
        Update-DLauncherStatus
        Show-DLauncherConfigNotices
    }
}

# Marcar / desmarcar las visibles con una sola escritura en disco
function Global:Set-DLauncherVisibleChecked {
    param ([bool]$Target)
    $visible = @(Get-DLauncherVisibleRows)
    if ($visible.Count -eq 0) { return }
    $Global:DLauncherState.SuppressCheckEvents = $true
    try {
        foreach ($r in $visible) { $r.ItemCheck.IsChecked = $Target }
    } finally {
        $Global:DLauncherState.SuppressCheckEvents = $false
    }
    Set-DLauncherPlatformChecked -Ids @($visible | ForEach-Object { $_.Platform.Id }) -IsChecked $Target
    Update-DLauncherStatus
}

$ui.BtnToggleAll.Add_Click({
    $visible = @(Get-DLauncherVisibleRows)
    $target = (@($visible | Where-Object { $_.ItemCheck.IsChecked -eq $true }).Count -ne $visible.Count)
    Set-DLauncherVisibleChecked -Target $target
})

# ===================== CURSOR DE TECLADO =====================

function Global:Set-DLauncherCursor {
    param ([string]$Id, [switch]$Scroll)
    $target = $null
    foreach ($r in $Global:DLauncherState.Rows) {
        if (-not [string]::IsNullOrEmpty($Id) -and $r.Platform.Id -eq $Id) {
            $r.CursorBar.Visibility = [System.Windows.Visibility]::Visible
            $r.Element.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, 'Row.Cursor')
            $target = $r
        } elseif ($r.CursorBar.Visibility -eq [System.Windows.Visibility]::Visible) {
            $r.CursorBar.Visibility = [System.Windows.Visibility]::Collapsed
            $r.Element.ClearValue([System.Windows.Controls.Border]::BackgroundProperty)
        }
    }
    $Global:DLauncherState.CursorId = if ($null -ne $target) { $Id } else { $null }
    if ($Scroll -and $null -ne $target) { $target.Element.BringIntoView() }
}

function Global:Move-DLauncherCursor {
    param ([int]$Delta)
    $visible = @(Get-DLauncherVisibleRows)
    if ($visible.Count -eq 0) { return }
    $idx = -1
    for ($i = 0; $i -lt $visible.Count; $i++) {
        if ($visible[$i].Platform.Id -eq $Global:DLauncherState.CursorId) { $idx = $i; break }
    }
    if ($idx -lt 0) {
        $idx = if ($Delta -gt 0) { 0 } else { $visible.Count - 1 }
    } else {
        $idx = [Math]::Max(0, [Math]::Min($visible.Count - 1, $idx + $Delta))
    }
    Set-DLauncherCursor -Id $visible[$idx].Platform.Id -Scroll
}

# ===================== LANZAMIENTO =====================

function Global:Start-DLauncherSingle {
    param ([string]$Id)
    $r = Get-DLauncherRow -Id $Id
    if ($null -eq $r) { return }
    $res = Start-DLauncherItem -Platform $r.Platform
    if ($res.Ok) { Show-DLauncherToast (T "toast.opening" $r.Platform.Name) }
}

# Abre todas las herramientas de una etiqueta (sin tener en cuenta la selección)
function Global:Start-DLauncherTagLaunch {
    param ([string]$TagId)
    $items = @($Global:DLauncherState.Rows | Where-Object { @($_.Platform.Tags) -contains $TagId } | ForEach-Object { $_.Platform })
    if ($items.Count -eq 0) {
        Show-DLauncherToast (T "toast.tagEmpty") -Kind 'warning'
        return
    }
    Start-DLauncherBatch -Platforms $items
}

$Global:DLauncherLaunchTimer = New-Object System.Windows.Threading.DispatcherTimer
$Global:DLauncherLaunchTimer.Add_Tick({ Invoke-DLauncherBatchStep })

# Abre en secuencia, con el retardo configurado entre cada una y sin bloquear la interfaz
function Global:Start-DLauncherBatch {
    param ($Platforms = $null, [switch]$Confirmed)
    if ($Global:DLauncherState.Launching) { return }
    $items = if ($null -ne $Platforms) { @($Platforms) } else { @(Get-DLauncherVisibleRows | Where-Object { $_.ItemCheck.IsChecked -eq $true } | ForEach-Object { $_.Platform }) }
    if ($items.Count -eq 0) {
        Show-DLauncherToast (T "toast.noneSelected") -Kind 'warning'
        return
    }

    $delay = 500
    $confirm = $true
    try {
        $cfg = Get-DLauncherConfig
        $delay = [int]$cfg.Settings.LaunchDelayMs
        $confirm = [bool]$cfg.Settings.ConfirmManyLaunches
    } catch { }

    # Aviso antes de abrir muchas a la vez
    if (-not $Confirmed -and $confirm -and $items.Count -gt $Global:DLauncherManyThreshold) {
        $Global:DLauncherState.PendingBatch = $items
        Show-DLauncherMessageBox -Title (T "many.title") -Message (T "many.body" $items.Count) -OkText (T "many.ok" $items.Count) -CancelText (T "common.cancel") -OnOk {
            Start-DLauncherBatch -Platforms $Global:DLauncherState.PendingBatch -Confirmed
        }
        return
    }

    $Global:DLauncherState.Launching = $true
    $Global:DLauncherState.LaunchQueue = New-Object System.Collections.Queue
    foreach ($it in $items) { $Global:DLauncherState.LaunchQueue.Enqueue($it) }
    $Global:DLauncherState.LaunchTotal = $items.Count
    $Global:DLauncherState.LaunchDone = 0
    $Global:DLauncherState.LaunchErrors = [System.Collections.ArrayList]::new()
    $ui.BtnOpenAll.IsEnabled = $false
    $ui.LaunchProgress.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $null)
    $ui.LaunchProgress.Width = 0
    $ui.LaunchProgress.Opacity = 0.9
    $ui.StatusDot.SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, 'Accent')

    $Global:DLauncherLaunchTimer.Interval = [TimeSpan]::FromMilliseconds([Math]::Max($delay, 15))
    Invoke-DLauncherBatchStep
    if ($Global:DLauncherState.Launching) {
        $Global:DLauncherLaunchTimer.Start()
    }
}

function Global:Invoke-DLauncherBatchStep {
    $state = $Global:DLauncherState
    if ($state.LaunchQueue.Count -gt 0) {
        $p = $state.LaunchQueue.Dequeue()
        $res = Start-DLauncherItem -Platform $p -Quiet
        if (-not $res.Ok) { $null = $state.LaunchErrors.Add("• $($p.Name): $($res.Error)") }
        $state.LaunchDone++
        $ui.OpenAllText.Text = T "open.progress" $state.LaunchDone $state.LaunchTotal
        $ui.StatusBarText.Text = T "statusbar.launching" $state.LaunchDone $state.LaunchTotal $p.Name
        # Siempre en coma flotante: [Math]::Max(0, x) elegiría la versión Int32 y fallaría con valores no enteros o infinitos
        $total = [double][Math]::Max(1, [int]$state.LaunchTotal)
        $barWidth = [double]$ui.BtnOpenAll.ActualWidth - 16.0
        if ($barWidth -gt 0 -and -not [double]::IsInfinity($barWidth)) {
            $ui.LaunchProgress.Width = [Math]::Max([double]0, [Math]::Min($barWidth, $barWidth * [double]$state.LaunchDone / $total))
        }
    }

    if ($state.LaunchQueue.Count -eq 0) {
        $Global:DLauncherLaunchTimer.Stop()
        $state.Launching = $false
        $ui.LaunchProgress.BeginAnimation([System.Windows.UIElement]::OpacityProperty, (New-DLauncherAnimation -From 0.9 -To 0 -Milliseconds 500 -DelayMs 300))
        Update-DLauncherStatus
        Update-DLauncherStatusBar

        $ok = $state.LaunchDone - $state.LaunchErrors.Count
        if ($state.LaunchErrors.Count -gt 0) {
            Show-DLauncherMessageBox -Title (T "batch.errorsTitle") -Message ((T "batch.errorsBody" $ok $state.LaunchTotal) + "`n`n" + ($state.LaunchErrors -join "`n"))
        } else {
            Show-DLauncherToast $(if ($ok -eq 1) { T "toast.doneOne" } else { T "toast.doneMany" $ok })
        }
    }
}

$ui.BtnOpenAll.Add_Click({ Start-DLauncherBatch })
$ui.BtnDelay.Add_Click({ Show-DLauncherSettings -Page 'launch' })

# ===================== BÚSQUEDA Y TECLADO =====================

$ui.SearchBox.Add_TextChanged({
    $hasText = -not [string]::IsNullOrEmpty($ui.SearchBox.Text)
    $ui.SearchPlaceholder.Visibility = if ($hasText) { [System.Windows.Visibility]::Collapsed } else { [System.Windows.Visibility]::Visible }
    $ui.BtnClearSearch.Visibility = if ($hasText) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
    $ui.BtnPaletteHint.Visibility = if ($hasText) { [System.Windows.Visibility]::Collapsed } else { [System.Windows.Visibility]::Visible }
    Update-DLauncherFilter
})

$ui.BtnClearSearch.Add_Click({
    $ui.SearchBox.Text = ""
    $null = $ui.SearchBox.Focus()
})

$ui.BtnPaletteHint.Add_Click({ Show-DLauncherPalette })

# Clic en el borde de la búsqueda: enfocar el campo (y no arrastrar la ventana)
$ui.SearchBorder.Add_MouseLeftButtonDown({
    param($s, $e)
    $null = $ui.SearchBox.Focus()
    $e.Handled = $true
})

# Atajos globales
$ui.Window.Add_PreviewKeyDown({
    param($s, $e)
    $key = $e.Key
    $ctrl = ([System.Windows.Input.Keyboard]::Modifiers -band [System.Windows.Input.ModifierKeys]::Control) -ne 0
    $overlay = Get-DLauncherOpenOverlay

    if ($key -eq $K::Escape) {
        if ($null -ne $overlay) {
            if ($overlay -eq $ui.ConfirmOverlay) {
                $ui.BtnConfirmCancel.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent))
            } elseif ($overlay -ne $ui.SetupOverlay -and $overlay -ne $ui.TermsOverlay) {
                Hide-DLauncherOverlay $overlay
            }
        } elseif ($ui.SearchBox.Text -ne "") {
            $ui.SearchBox.Text = ""
        } elseif ($null -ne $Global:DLauncherState.CursorId) {
            Set-DLauncherCursor -Id $null
        }
        $e.Handled = $true
        return
    }

    if ($null -ne $overlay) {
        # Enter confirma en los diálogos sencillos
        if ($key -eq $K::Enter) {
            if ($overlay -eq $ui.ConfirmOverlay) {
                $ui.BtnConfirmOk.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent))
                $e.Handled = $true
            } elseif ($overlay -eq $ui.FormOverlay -and $ui.BtnSavePlatform.IsEnabled) {
                $ui.BtnSavePlatform.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent))
                $e.Handled = $true
            }
        }
        return
    }

    $focused = [System.Windows.Input.Keyboard]::FocusedElement
    $inSearch = ($focused -eq $ui.SearchBox)
    if ($focused -is [System.Windows.Controls.TextBox] -and -not $inSearch) { return }
    $searchEmpty = ($ui.SearchBox.Text -eq "")
    $cursor = $Global:DLauncherState.CursorId

    if ($ctrl) {
        if ($key -eq $K::K -or $key -eq $K::P) { Show-DLauncherPalette; $e.Handled = $true }
        elseif ($key -eq $K::F) { $null = $ui.SearchBox.Focus(); $ui.SearchBox.SelectAll(); $e.Handled = $true }
        elseif ($key -eq $K::Enter) { Start-DLauncherBatch; $e.Handled = $true }
        elseif ($key -eq $K::N) { Show-DLauncherPlatformForm; $e.Handled = $true }
        elseif ($key -eq $K::B) { Switch-DLauncherSidebar; $e.Handled = $true }
        elseif ($key -eq $K::OemComma) { Show-DLauncherSettings; $e.Handled = $true }
        elseif ($key -eq $K::D -and $null -ne $cursor) { Invoke-DLauncherRowAction -Action 'duplicate' -Id $cursor; $e.Handled = $true }
        elseif ($key -eq $K::Z -and $searchEmpty -and $null -ne $Global:DLauncherState.UndoJson) { Invoke-DLauncherUndo; $e.Handled = $true }
        return
    }

    if ($key -eq $K::F1) { Show-DLauncherHelp; $e.Handled = $true }
    elseif ($key -eq $K::Down) { Move-DLauncherCursor -Delta 1; $e.Handled = $true }
    elseif ($key -eq $K::Up) { Move-DLauncherCursor -Delta -1; $e.Handled = $true }
    elseif ($key -eq $K::Enter -and $null -ne $cursor) { Start-DLauncherSingle -Id $cursor; $e.Handled = $true }
    elseif ($key -eq $K::F2 -and $null -ne $cursor) { Show-DLauncherPlatformForm -PlatformId $cursor; $e.Handled = $true }
    elseif ($key -eq $K::Delete -and $null -ne $cursor -and $searchEmpty) { Remove-DLauncherToolWithUndo -Id $cursor; $e.Handled = $true }
    elseif ($key -eq $K::Space -and $null -ne $cursor -and -not $inSearch) {
        $r = Get-DLauncherRow -Id $cursor
        if ($null -ne $r) { $r.ItemCheck.IsChecked = -not [bool]$r.ItemCheck.IsChecked }
        $e.Handled = $true
    }
    elseif ($key -eq $K::Apps -and $null -ne $cursor) {
        $r = Get-DLauncherRow -Id $cursor
        if ($null -ne $r) { Show-DLauncherRowMenu -PlatformId $cursor -Target $r.BtnMore }
        $e.Handled = $true
    }
})

# Escribir en cualquier parte de la ventana empieza una búsqueda
$ui.Window.Add_PreviewTextInput({
    param($s, $e)
    if ($null -ne (Get-DLauncherOpenOverlay)) { return }
    if ([System.Windows.Input.Keyboard]::FocusedElement -is [System.Windows.Controls.TextBox]) { return }
    if ([string]::IsNullOrWhiteSpace($e.Text) -or [char]::IsControl($e.Text[0])) { return }
    $null = $ui.SearchBox.Focus()
    $ui.SearchBox.Text += $e.Text
    $ui.SearchBox.CaretIndex = $ui.SearchBox.Text.Length
    $e.Handled = $true
})

# ===================== MENÚ CONTEXTUAL DE FILA =====================

function Global:Show-DLauncherRowMenu {
    param ([string]$PlatformId, $Target, [switch]$AtPointer)
    $r = Get-DLauncherRow -Id $PlatformId
    if ($null -eq $r) { return }
    Set-DLauncherCursor -Id $PlatformId

    $menu = New-Object System.Windows.Controls.ContextMenu
    Add-DLauncherThemeResources -Element $menu
    $menu.Style = $Global:DLauncherStylesDict[[System.Windows.Controls.ContextMenu]]

    $info = Resolve-DLauncherTarget -Value $r.Platform.Url
    $entries = [System.Collections.ArrayList]::new()
    $null = $entries.Add(@('open', 'menu.open', 'Enter', 'play', 'Success'))
    $null = $entries.Add(@('edit', 'menu.edit', 'F2', 'edit', 'Fg.2'))
    $null = $entries.Add(@('tags', 'menu.tags', '', 'tag', 'Fg.2'))
    $null = $entries.Add(@('duplicate', 'menu.duplicate', 'Ctrl+D', 'copy', 'Fg.2'))
    $null = $entries.Add(@('copy', 'menu.copy', '', 'doc', 'Fg.2'))
    if ($info.Kind -eq 'Path' -and -not (Test-DLauncherNetworkPath -Path $info.Target) -and (Test-Path -LiteralPath $info.Target -ErrorAction SilentlyContinue)) {
        $null = $entries.Add(@('location', 'menu.location', '', 'location', 'Fg.2'))
    }
    $null = $entries.Add('-')
    $null = $entries.Add(@('delete', 'menu.delete', 'Del', 'trash', 'Danger'))

    foreach ($en in $entries) {
        if ($en -is [string]) {
            $sep = New-Object System.Windows.Controls.Separator
            $sep.Style = $Global:DLauncherStylesDict['MenuSeparator']
            $null = $menu.Items.Add($sep)
            continue
        }
        $mi = New-Object System.Windows.Controls.MenuItem
        $mi.Header = T $en[1]
        $mi.InputGestureText = $en[2]
        $mi.Icon = New-DLauncherIconPath -Name $en[3] -Size 13 -BrushKey $en[4]
        $mi.Tag = "$($en[0])|$PlatformId"
        if ($en[0] -eq 'delete') {
            $mi.SetResourceReference([System.Windows.Controls.Control]::ForegroundProperty, 'Danger')
        }
        $mi.Add_Click({
            param($s, $e)
            $parts = ([string]$s.Tag).Split('|')
            Invoke-DLauncherRowAction -Action $parts[0] -Id $parts[1]
        })
        $null = $menu.Items.Add($mi)
    }

    $menu.PlacementTarget = $Target
    $menu.Placement = if ($AtPointer) { [System.Windows.Controls.Primitives.PlacementMode]::MousePoint } else { [System.Windows.Controls.Primitives.PlacementMode]::Bottom }
    $menu.IsOpen = $true
}

function Global:Invoke-DLauncherRowAction {
    param ([string]$Action, [string]$Id)
    $r = Get-DLauncherRow -Id $Id
    if ($null -eq $r) { return }
    switch ($Action) {
        'open' { Start-DLauncherSingle -Id $Id }
        'edit' { Show-DLauncherPlatformForm -PlatformId $Id }
        'tags' { Show-DLauncherTagPopup -PlatformId $Id -Target $r.BtnTag }
        'duplicate' {
            $copy = Copy-DLauncherPlatform -Id $Id
            Update-UIList
            if ($null -ne $copy) {
                Set-DLauncherCursor -Id $copy.Id -Scroll
                Show-DLauncherToast (T "toast.duplicated" $copy.Name)
            }
        }
        'copy' {
            try {
                [System.Windows.Clipboard]::SetText([string]$r.Platform.Url)
                Show-DLauncherToast (T "toast.copied")
            } catch {
                Show-DLauncherToast (T "toast.copyFailed") -Kind 'warning'
            }
        }
        'location' {
            $target = (Resolve-DLauncherTarget -Value $r.Platform.Url).Target
            try { $null = [System.Diagnostics.Process]::Start('explorer.exe', "/select,`"$target`"") } catch { }
        }
        'delete' { Remove-DLauncherToolWithUndo -Id $Id }
    }
}

# Eliminar sin confirmación, con opción de deshacer
function Global:Remove-DLauncherToolWithUndo {
    param ([string]$Id)
    $r = Get-DLauncherRow -Id $Id
    if ($null -eq $r) { return }
    $name = $r.Platform.Name
    $snapshot = Get-DLauncherConfigSnapshot
    if (Remove-DLauncherPlatform -Id $Id) {
        Update-UIList
        Show-DLauncherUndoToast -Text (T "toast.deleted" $name) -Snapshot $snapshot
    }
}

# ===================== POPUP DE ETIQUETAS =====================

function Global:Show-DLauncherTagPopup {
    param ([string]$PlatformId, $Target)
    $r = Get-DLauncherRow -Id $PlatformId
    if ($null -eq $r) { return }

    $popup = New-Object System.Windows.Controls.Primitives.Popup
    $popup.StaysOpen = $false
    $popup.AllowsTransparency = $true
    $popup.PopupAnimation = [System.Windows.Controls.Primitives.PopupAnimation]::Fade
    $popup.Placement = [System.Windows.Controls.Primitives.PlacementMode]::Bottom
    $popup.VerticalOffset = 6
    $popup.PlacementTarget = $Target

    $card = New-Object System.Windows.Controls.Border
    Add-DLauncherThemeResources -Element $card
    $card.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, 'Panel.Bg')
    $card.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, 'Border.Strong')
    $card.BorderThickness = [System.Windows.Thickness]::new(1)
    $card.CornerRadius = [System.Windows.CornerRadius]::new(11)
    $card.Padding = [System.Windows.Thickness]::new(12, 10, 12, 12)
    $card.MinWidth = 230
    $card.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, 'Fg.1')

    $stack = New-Object System.Windows.Controls.StackPanel
    $title = New-DLauncherText -Text (T "tags.popupTitle" $r.Platform.Name) -Size 11 -Brush 'Fg.3' -Bold -Margin @(0, 0, 0, 8) -Wrap $false
    $list = New-Object System.Windows.Controls.StackPanel
    $empty = New-DLauncherText -Text (T "tags.none") -Size 11 -Brush 'Fg.3' -Margin @(0, 0, 0, 4)
    $empty.MaxWidth = 210
    $sep = New-Object System.Windows.Controls.Border
    $sep.Height = 1
    $sep.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, 'Divider')
    $sep.Margin = [System.Windows.Thickness]::new(0, 8, 0, 8)

    $newGrid = New-Object System.Windows.Controls.Grid
    $newHint = New-DLauncherText -Text (T "tags.newPlaceholder") -Size 11.5 -Brush 'Fg.3' -Margin @(10, 0, 0, 0) -Wrap $false
    $newHint.VerticalAlignment = 'Center'
    $newHint.IsHitTestVisible = $false
    $newBox = New-Object System.Windows.Controls.TextBox
    $newBox.Height = 30
    $newBox.FontSize = 11.5
    $newBox.Background = [System.Windows.Media.Brushes]::Transparent
    $null = $newGrid.Children.Add($newHint)
    $null = $newGrid.Children.Add($newBox)

    foreach ($el in $title, $list, $empty, $sep, $newGrid) { $null = $stack.Children.Add($el) }
    $card.Child = $stack
    $popup.Child = $card

    $selected = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($t in @($r.Platform.Tags)) { if ($t) { $null = $selected.Add([string]$t) } }
    $Global:DLauncherTagPopupParts = @{
        List = $list; Empty = $empty; Hint = $newHint; NewBox = $newBox
        PlatformId = $PlatformId; Selected = $selected; Dirty = $false
    }

    $newBox.Add_TextChanged({
        $p = $Global:DLauncherTagPopupParts
        $p.Hint.Visibility = if ($p.NewBox.Text -eq "") { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
    })
    $newBox.Add_KeyDown({
        param($s, $e)
        if ($e.Key -ne [System.Windows.Input.Key]::Enter) { return }
        $name = $s.Text.Trim()
        if ($name -eq "") { return }
        $existing = $Global:DLauncherState.Groups | Where-Object { $_.Name -eq $name } | Select-Object -First 1
        if ($null -eq $existing) {
            $existing = Add-DLauncherGroup -Name $name
            $Global:DLauncherState.Groups = @($Global:DLauncherState.Groups) + $existing
        }
        $null = $Global:DLauncherTagPopupParts.Selected.Add([string]$existing.Id)
        $Global:DLauncherTagPopupParts.Dirty = $true
        $s.Text = ""
        Update-DLauncherTagPopupList
        $e.Handled = $true
    })
    $popup.Add_Closed({
        $p = $Global:DLauncherTagPopupParts
        if ($p.Dirty) {
            Set-DLauncherPlatformTags -Id $p.PlatformId -Tags @($p.Selected)
            $p.Dirty = $false
            Update-UIList
        }
    })

    Update-DLauncherTagPopupList
    $popup.IsOpen = $true
    $null = $newBox.Focus()
}

function Global:Update-DLauncherTagPopupList {
    $parts = $Global:DLauncherTagPopupParts
    $parts.List.Children.Clear()
    foreach ($g in $Global:DLauncherState.Groups) {
        $cb = New-Object System.Windows.Controls.CheckBox
        $cb.Tag = [string]$g.Id
        $cb.Margin = [System.Windows.Thickness]::new(0, 3, 0, 3)
        $cb.IsChecked = $parts.Selected.Contains([string]$g.Id)
        $content = New-Object System.Windows.Controls.StackPanel
        $content.Orientation = 'Horizontal'
        $dot = New-Object System.Windows.Shapes.Ellipse
        $dot.Width = 7; $dot.Height = 7
        $dot.Fill = New-DLauncherBrush (Get-DLauncherTagColor -TagId $g.Id)
        $dot.VerticalAlignment = 'Center'
        $dot.Margin = [System.Windows.Thickness]::new(0, 0, 7, 0)
        $null = $content.Children.Add($dot)
        $null = $content.Children.Add((New-DLauncherText -Text $g.Name -Size 12 -Brush 'Fg.1' -Wrap $false))
        $cb.Content = $content
        $cb.Add_Checked({ param($s, $e) $null = $Global:DLauncherTagPopupParts.Selected.Add([string]$s.Tag); $Global:DLauncherTagPopupParts.Dirty = $true })
        $cb.Add_Unchecked({ param($s, $e) $null = $Global:DLauncherTagPopupParts.Selected.Remove([string]$s.Tag); $Global:DLauncherTagPopupParts.Dirty = $true })
        $null = $parts.List.Children.Add($cb)
    }
    $parts.Empty.Visibility = if (@($Global:DLauncherState.Groups).Count -eq 0) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
}

# ===================== REORDENACIÓN Y ETIQUETADO POR ARRASTRE =====================
# La captura del ratón se hace sobre ListPanel para no perderla al mover la fila de posición

function Global:Start-DLauncherRowDrag {
    param ($RowElement, $MouseEvent)
    if ($null -eq $RowElement) { return }
    $Global:DLauncherDrag.Row = $RowElement
    $Global:DLauncherDrag.StartIndex = $ui.ListPanel.Children.IndexOf($RowElement)
    $RowElement.Opacity = 0.92
    $RowElement.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, 'Accent')
    $RowElement.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, 'Panel.Bg')
    $null = $ui.ListPanel.CaptureMouse()
    $MouseEvent.Handled = $true
    if (@($Global:DLauncherState.Groups).Count -gt 0 -and $ui.Sidebar.Visibility -eq [System.Windows.Visibility]::Visible) {
        Show-DLauncherToast (T "drag.hint") -Kind 'info'
    }
}

# Etiqueta de la barra lateral bajo el puntero durante un arrastre (o $null)
function Global:Get-DLauncherTagUnderPointer {
    param ($MouseEvent)
    if ($ui.Sidebar.Visibility -ne [System.Windows.Visibility]::Visible) { return $null }
    foreach ($item in $ui.TagList.Children) {
        $pt = $MouseEvent.GetPosition($item)
        if ($pt.X -ge 0 -and $pt.Y -ge 0 -and $pt.X -le $item.ActualWidth -and $pt.Y -le $item.ActualHeight) {
            return $item
        }
    }
    return $null
}

function Global:Stop-DLauncherRowDrag {
    $row = $Global:DLauncherDrag.Row
    if ($null -eq $row) { return }
    $Global:DLauncherDrag.Row = $null

    $row.ClearValue([System.Windows.UIElement]::OpacityProperty)
    $row.ClearValue([System.Windows.Controls.Border]::BorderBrushProperty)
    $row.ClearValue([System.Windows.Controls.Border]::BackgroundProperty)
    if ($ui.ListPanel.IsMouseCaptured) { $ui.ListPanel.ReleaseMouseCapture() }

    # Soltada sobre una etiqueta: asignarla y devolver la fila a su sitio
    $hover = $Global:DLauncherDrag.HoverTag
    $Global:DLauncherDrag.HoverTag = $null
    Update-DLauncherNavStyles
    if ($null -ne $hover) {
        $currentIndex = $ui.ListPanel.Children.IndexOf($row)
        if ($currentIndex -ne $Global:DLauncherDrag.StartIndex) {
            $ui.ListPanel.Children.RemoveAt($currentIndex)
            $ui.ListPanel.Children.Insert($Global:DLauncherDrag.StartIndex, $row)
        }
        $tagId = [string]$hover.Tag
        $r = Get-DLauncherRow -Id ([string]$row.Tag)
        $changed = Add-DLauncherPlatformTag -Ids @([string]$row.Tag) -TagId $tagId
        Update-UIList
        if ($changed -gt 0) {
            Show-DLauncherToast (T "toast.tagged" $r.Platform.Name (Get-DLauncherGroupName -GroupId $tagId))
        } else {
            Show-DLauncherToast (T "toast.alreadyTagged" $r.Platform.Name) -Kind 'info'
        }
        return
    }

    # Persistir solo si el orden ha cambiado
    if ($ui.ListPanel.Children.IndexOf($row) -ne $Global:DLauncherDrag.StartIndex) {
        $orderedIds = @($ui.ListPanel.Children | ForEach-Object { [string]$_.Tag })
        Set-DLauncherPlatformOrder -OrderedIds $orderedIds
        $reordered = [System.Collections.ArrayList]::new()
        foreach ($id in $orderedIds) {
            $r = Get-DLauncherRow -Id $id
            if ($null -ne $r) { $null = $reordered.Add($r) }
        }
        $Global:DLauncherState.Rows = $reordered
        Update-DLauncherFilter
    }
    Set-DLauncherCursor -Id ([string]$row.Tag)
}

$ui.ListPanel.Add_MouseMove({
    param($sender, $e)
    $row = $Global:DLauncherDrag.Row
    if ($null -eq $row) { return }

    # ¿Sobre una etiqueta? Resaltarla y no reordenar mientras tanto
    $hover = Get-DLauncherTagUnderPointer -MouseEvent $e
    if ($hover -ne $Global:DLauncherDrag.HoverTag) {
        Update-DLauncherNavStyles
        if ($null -ne $hover) {
            $hover.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, 'Accent.Soft')
            $hover.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, 'Accent')
        }
        $Global:DLauncherDrag.HoverTag = $hover
    }
    if ($null -ne $hover) { return }

    $panel = $ui.ListPanel
    $y = $e.GetPosition($panel).Y
    $targetIndex = 0
    foreach ($child in $panel.Children) {
        if ($child -eq $row) { continue }
        $top = $child.TranslatePoint([System.Windows.Point]::new(0, 0), $panel).Y
        if ($child.Visibility -ne [System.Windows.Visibility]::Visible) {
            # Las filas ocultas (otra vista/búsqueda) conservan su posición relativa
            if ($y -gt $top) { $targetIndex++ }
            continue
        }
        if ($y -gt ($top + ($child.ActualHeight / 2))) { $targetIndex++ }
    }
    $currentIndex = $panel.Children.IndexOf($row)
    if ($targetIndex -ne $currentIndex) {
        $panel.Children.RemoveAt($currentIndex)
        $panel.Children.Insert($targetIndex, $row)
    }

    # Desplazamiento automático cerca de los bordes
    $scroll = $ui.ListScroll
    $sy = $e.GetPosition($scroll).Y
    if ($sy -lt 24) { $scroll.LineUp() } elseif ($sy -gt ($scroll.ActualHeight - 24)) { $scroll.LineDown() }
})

$ui.ListPanel.Add_MouseLeftButtonUp({ Stop-DLauncherRowDrag })
$ui.ListPanel.Add_LostMouseCapture({ Stop-DLauncherRowDrag })

# ===================== FORMULARIO DE HERRAMIENTA =====================

function Global:Update-DLauncherFormTags {
    $ui.FormTagPanel.Children.Clear()
    if (@($Global:DLauncherState.Groups).Count -eq 0) {
        $null = $ui.FormTagPanel.Children.Add((New-DLauncherText -Text (T "tags.noneForm") -Size 11.5 -Brush 'Fg.3'))
        return
    }
    foreach ($g in $Global:DLauncherState.Groups) {
        $selected = $Global:DLauncherState.FormTags.Contains([string]$g.Id)
        $chip = New-Object System.Windows.Controls.Border
        $chip.CornerRadius = [System.Windows.CornerRadius]::new(14)
        $chip.BorderThickness = [System.Windows.Thickness]::new(1)
        $chip.Padding = [System.Windows.Thickness]::new(10, 4, 12, 5)
        $chip.Margin = [System.Windows.Thickness]::new(0, 0, 6, 6)
        $chip.Cursor = [System.Windows.Input.Cursors]::Hand
        $chip.Tag = [string]$g.Id
        if ($selected) {
            $chip.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, 'Accent.Soft')
            $chip.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, 'Accent')
        } else {
            $chip.Background = [System.Windows.Media.Brushes]::Transparent
            $chip.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, 'Border.Strong')
        }
        $panel = New-Object System.Windows.Controls.StackPanel
        $panel.Orientation = 'Horizontal'
        $dot = New-Object System.Windows.Shapes.Ellipse
        $dot.Width = 7; $dot.Height = 7
        $dot.Fill = New-DLauncherBrush (Get-DLauncherTagColor -TagId $g.Id)
        $dot.VerticalAlignment = 'Center'
        $dot.Margin = [System.Windows.Thickness]::new(0, 0, 7, 0)
        $null = $panel.Children.Add($dot)
        $null = $panel.Children.Add((New-DLauncherText -Text $g.Name -Size 11.5 -Brush $(if ($selected) { 'Fg.1' } else { 'Fg.2' }) -Wrap $false))
        if ($selected) {
            $check = New-DLauncherIconPath -Name 'check' -Size 10 -BrushKey 'Accent.Text' -Thickness 2
            $check.Margin = [System.Windows.Thickness]::new(7, 0, 0, 0)
            $null = $panel.Children.Add($check)
        }
        $chip.Child = $panel
        $chip.Add_MouseLeftButtonUp({
            param($s, $e)
            $id = [string]$s.Tag
            if (-not $Global:DLauncherState.FormTags.Remove($id)) { $null = $Global:DLauncherState.FormTags.Add($id) }
            Update-DLauncherFormTags
        })
        $null = $ui.FormTagPanel.Children.Add($chip)
    }
}

function Global:Update-DLauncherSaveButtonState {
    $ui.BtnSavePlatform.IsEnabled = -not [string]::IsNullOrWhiteSpace($ui.TxtPlatformName.Text) -and -not [string]::IsNullOrWhiteSpace($ui.TxtPlatformUrl.Text)
}

# Tipo de destino detectado, navegador (solo webs) y avisos de seguridad
function Global:Update-DLauncherFormTargetState {
    $value = $ui.TxtPlatformUrl.Text
    $info = Resolve-DLauncherTarget -Value $value
    $ui.BrowserPanel.Visibility = if ($info.Kind -eq 'Url') { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }

    $dot = 'Fg.4'
    $text = ""
    $isNetwork = $false
    switch ($info.Kind) {
        'None' { $text = T "kind.none" }
        'Url'  { $text = T "kind.web" $info.Host; $dot = 'Accent.Text' }
        'Uri'  { $text = T "kind.protocol" (($info.Target -split ':')[0] + ':'); $dot = 'Orange.Text' }
        'Path' {
            if (Test-DLauncherNetworkPath -Path $info.Target) {
                $isNetwork = $true
                $text = T "kind.network"
                $dot = 'Accent.Text'
            } elseif (Test-Path -LiteralPath $info.Target -PathType Container -ErrorAction SilentlyContinue) {
                $text = T "kind.folder"
                $dot = 'Accent.Text'
            } else {
                $exe = Find-DLauncherExecutable -ExecutablePath $info.Target
                if ($null -ne $exe) {
                    $text = T "kind.app" $exe
                    $dot = 'Success'
                } elseif (Test-Path -LiteralPath $info.Target -PathType Leaf -ErrorAction SilentlyContinue) {
                    $text = T "kind.file"
                    $dot = 'Success'
                } else {
                    $text = T "kind.notFound"
                    $dot = 'Warning'
                }
            }
        }
    }
    $ui.FormKindText.Text = $text
    $ui.FormKindDot.SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, $dot)

    $warning = ""
    if (Test-DLauncherScriptTarget -Value $value) {
        $warning = T "warn.script"
    } elseif ($isNetwork -and (Test-DLauncherCodeTarget -Value $value)) {
        $warning = T "warn.network"
    }
    $ui.FormWarningText.Text = $warning
    $ui.FormWarning.Visibility = if ($warning -ne "") { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
}

function Global:Update-DLauncherProfileCombo {
    param ([string]$Selected = "")
    $key = Get-DLauncherComboValue $ui.CmbBrowser
    if ($key -eq "" -or $null -eq (Get-DLauncherBrowser -Key $key)) {
        $ui.ProfilePanel.Visibility = [System.Windows.Visibility]::Hidden
        Set-DLauncherComboItems $ui.CmbProfile @(@{ Text = (T "form.defaultProfile"); Value = "" }) ""
        return
    }
    $items = @(@{ Text = (T "form.defaultProfile"); Value = "" })
    foreach ($pr in (Get-DLauncherBrowserProfiles -Key $key)) {
        $items += @{ Text = $pr.Name; Value = $pr.Id }
    }
    Set-DLauncherComboItems $ui.CmbProfile $items $Selected
    $ui.ProfilePanel.Visibility = [System.Windows.Visibility]::Visible
}

function Global:Show-DLauncherPlatformForm {
    param ([string]$PlatformId = "", [string]$PresetUrl = "", [string]$PresetName = "")
    if (-not (Test-DLauncherHasConfigFolder)) { return }

    $p = $null
    if ($PlatformId -ne "") {
        $r = Get-DLauncherRow -Id $PlatformId
        if ($null -ne $r) { $p = $r.Platform }
    }
    $Global:DLauncherState.EditingPlatformId = if ($null -ne $p) { $p.Id } else { $null }

    $ui.FormTitleText.Text = if ($null -ne $p) { T "form.editTitle" } else { T "form.addTitle" }
    $ui.TxtPlatformName.Text = if ($null -ne $p) { $p.Name } else { $PresetName }
    $ui.TxtPlatformUrl.Text = if ($null -ne $p) { $p.Url } else { $PresetUrl }
    $ui.ChkDefaultChecked.IsChecked = if ($null -ne $p) { [bool]$p.CheckedByDefault } else { $true }

    # Etiquetas: las de la herramienta, o la de la vista activa si es nueva
    $Global:DLauncherState.FormTags = New-Object 'System.Collections.Generic.HashSet[string]'
    if ($null -ne $p) {
        foreach ($t in @($p.Tags)) { if ($t) { $null = $Global:DLauncherState.FormTags.Add([string]$t) } }
    } elseif (Test-DLauncherTagView -View $Global:DLauncherState.ActiveView) {
        $null = $Global:DLauncherState.FormTags.Add($Global:DLauncherState.ActiveView)
    }
    Update-DLauncherFormTags

    # Navegadores instalados (+ el configurado aunque no esté en este equipo)
    $browserItems = @(@{ Text = (T "form.defaultBrowser"); Value = "" })
    foreach ($b in (Get-DLauncherBrowsers)) { $browserItems += @{ Text = $b.Name; Value = $b.Key } }
    $selBrowser = if ($null -ne $p) { [string]$p.Browser } else { "" }
    if ($selBrowser -ne "" -and $null -eq (Get-DLauncherBrowser -Key $selBrowser)) {
        $browserItems += @{ Text = "$selBrowser ($(T 'browser.notInstalled'))"; Value = $selBrowser }
    }
    Set-DLauncherComboItems $ui.CmbBrowser $browserItems $selBrowser
    Update-DLauncherProfileCombo -Selected $(if ($null -ne $p) { [string]$p.BrowserProfile } else { "" })

    Update-DLauncherFormTargetState
    Update-DLauncherSaveButtonState
    Show-DLauncherOverlay $ui.FormOverlay
    if ($ui.TxtPlatformName.Text -eq "") { $null = $ui.TxtPlatformName.Focus() } else { $null = $ui.TxtPlatformUrl.Focus(); $ui.TxtPlatformUrl.CaretIndex = $ui.TxtPlatformUrl.Text.Length }
}

$ui.TxtPlatformName.Add_TextChanged({ Update-DLauncherSaveButtonState })
$ui.TxtPlatformUrl.Add_TextChanged({ Update-DLauncherSaveButtonState; Update-DLauncherFormTargetState })
$ui.CmbBrowser.Add_SelectionChanged({ Update-DLauncherProfileCombo })

$ui.BtnAddPlatform.Add_Click({ Show-DLauncherPlatformForm })
$ui.BtnAddHeader.Add_Click({ Show-DLauncherPlatformForm })
$ui.BtnCtaConfigure.Add_Click({ Show-DLauncherPlatformForm })
$ui.BtnCtaSuggestions.Add_Click({ Show-DLauncherSuggestions })
$ui.BtnCancelPlatform.Add_Click({ Hide-DLauncherOverlay $ui.FormOverlay })

$ui.BtnBrowseFile.Add_Click({
    $dialog = New-Object Microsoft.Win32.OpenFileDialog
    $dialog.Filter = "$(T 'browse.filterApps') (*.exe;*.lnk;*.bat;*.url)|*.exe;*.lnk;*.bat;*.url|$(T 'browse.filterAll') (*.*)|*.*"
    $dialog.Title = T "browse.title"
    if ($dialog.ShowDialog() -eq $true) {
        $path = $dialog.FileName
        if ([System.IO.Path]::GetExtension($path) -eq ".url") {
            $webUrl = Get-DLauncherShortcutUrl -Path $path
            if ($null -ne $webUrl) { $path = $webUrl }
        }
        $ui.TxtPlatformUrl.Text = $path
        if ([string]::IsNullOrWhiteSpace($ui.TxtPlatformName.Text)) {
            $ui.TxtPlatformName.Text = [System.IO.Path]::GetFileNameWithoutExtension($dialog.FileName)
        }
    }
})

$ui.BtnSavePlatform.Add_Click({
    $name = $ui.TxtPlatformName.Text.Trim()
    $url = $ui.TxtPlatformUrl.Text.Trim()
    if ([string]::IsNullOrEmpty($name) -or [string]::IsNullOrEmpty($url)) { return }
    $isCheckedByDefault = [bool]$ui.ChkDefaultChecked.IsChecked

    $tags = @($Global:DLauncherState.FormTags)
    $browser = ""
    $browserProfile = ""
    if ((Resolve-DLauncherTarget -Value $url).Kind -eq 'Url') {
        $browser = Get-DLauncherComboValue $ui.CmbBrowser
        if ($browser -ne "") { $browserProfile = Get-DLauncherComboValue $ui.CmbProfile }
    }

    $focusId = $null
    if ($null -eq $Global:DLauncherState.EditingPlatformId) {
        $new = Add-DLauncherPlatform -Name $name -Url $url -IsChecked $isCheckedByDefault -CheckedByDefault $isCheckedByDefault -Tags $tags -Browser $browser -BrowserProfile $browserProfile
        $focusId = $new.Id
        $toast = T "toast.added" $name
    } else {
        $r = Get-DLauncherRow -Id $Global:DLauncherState.EditingPlatformId
        $currentChecked = if ($null -ne $r) { [bool]$r.Platform.IsChecked } else { $isCheckedByDefault }
        $null = Update-DLauncherPlatform -Id $Global:DLauncherState.EditingPlatformId -Name $name -Url $url -IsChecked $currentChecked -CheckedByDefault $isCheckedByDefault -Tags $tags -Browser $browser -BrowserProfile $browserProfile
        $focusId = $Global:DLauncherState.EditingPlatformId
        $toast = T "toast.saved"
    }

    Hide-DLauncherOverlay $ui.FormOverlay
    Update-UIList
    if ($null -ne $focusId) { Set-DLauncherCursor -Id $focusId -Scroll }
    Show-DLauncherToast $toast
})

# ===================== FORMULARIO DE ETIQUETA =====================

function Global:Show-DLauncherGroupForm {
    param ([string]$GroupId = "")
    if (-not (Test-DLauncherHasConfigFolder)) { return }
    $Global:DLauncherState.EditingGroupId = if ($GroupId -ne "") { $GroupId } else { $null }
    if ($GroupId -ne "") {
        $ui.GroupFormTitle.Text = T "group.editTitle"
        $ui.TxtGroupName.Text = Get-DLauncherGroupName -GroupId $GroupId
        $ui.BtnDeleteGroup.Visibility = [System.Windows.Visibility]::Visible
    } else {
        $ui.GroupFormTitle.Text = T "group.newTitle"
        $ui.TxtGroupName.Text = ""
        $ui.BtnDeleteGroup.Visibility = [System.Windows.Visibility]::Collapsed
    }
    $ui.BtnSaveGroup.IsEnabled = -not [string]::IsNullOrWhiteSpace($ui.TxtGroupName.Text)
    Show-DLauncherOverlay $ui.GroupOverlay
    $null = $ui.TxtGroupName.Focus()
    $ui.TxtGroupName.SelectAll()
}

$ui.TxtGroupName.Add_TextChanged({
    $ui.BtnSaveGroup.IsEnabled = -not [string]::IsNullOrWhiteSpace($ui.TxtGroupName.Text)
})

$ui.TxtGroupName.Add_KeyDown({
    param($s, $e)
    if ($e.Key -eq [System.Windows.Input.Key]::Enter -and $ui.BtnSaveGroup.IsEnabled) {
        $ui.BtnSaveGroup.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent))
        $e.Handled = $true
    }
})

$ui.BtnSaveGroup.Add_Click({
    $name = $ui.TxtGroupName.Text.Trim()
    if ($name -eq "") { return }
    if ($null -eq $Global:DLauncherState.EditingGroupId) {
        $g = Add-DLauncherGroup -Name $name
        Set-DLauncherSetting -Name "ActiveGroupId" -Value $g.Id
        Show-DLauncherToast (T "group.created" $name)
    } else {
        Rename-DLauncherGroup -Id $Global:DLauncherState.EditingGroupId -Name $name
    }
    Hide-DLauncherOverlay $ui.GroupOverlay
    Update-UIList
    Update-DLauncherFilter -Animate
})

$ui.BtnCancelGroup.Add_Click({ Hide-DLauncherOverlay $ui.GroupOverlay })
$ui.BtnNewTag.Add_Click({ Show-DLauncherGroupForm })

# Eliminar una etiqueta (las herramientas se conservan), con opción de deshacer
function Global:Request-DLauncherTagDelete {
    param ([string]$GroupId)
    if ([string]::IsNullOrEmpty($GroupId)) { return }
    $name = Get-DLauncherGroupName -GroupId $GroupId
    $snapshot = Get-DLauncherConfigSnapshot
    Remove-DLauncherGroup -Id $GroupId
    Update-UIList
    Show-DLauncherUndoToast -Text (T "toast.tagDeleted" $name) -Snapshot $snapshot
}

$ui.BtnDeleteGroup.Add_Click({
    Hide-DLauncherOverlay $ui.GroupOverlay
    Request-DLauncherTagDelete -GroupId $Global:DLauncherState.EditingGroupId
})

# ===================== SOLTAR ARCHIVOS Y ENLACES =====================

function Global:Get-DLauncherDropItems {
    param ($Data)
    $items = [System.Collections.ArrayList]::new()

    if ($Data.GetDataPresent([System.Windows.DataFormats]::FileDrop)) {
        foreach ($path in $Data.GetData([System.Windows.DataFormats]::FileDrop)) {
            if ([System.IO.Path]::GetExtension($path) -eq ".url") {
                $webUrl = Get-DLauncherShortcutUrl -Path $path
                if ($null -ne $webUrl) {
                    $null = $items.Add(@{ Name = [System.IO.Path]::GetFileNameWithoutExtension($path); Url = $webUrl })
                    continue
                }
            }
            $name = if (Test-Path -LiteralPath $path -PathType Container) { Split-Path -Leaf $path } else { [System.IO.Path]::GetFileNameWithoutExtension($path) }
            $null = $items.Add(@{ Name = $name; Url = $path })
        }
        return $items
    }

    $text = $null
    foreach ($fmt in 'UniformResourceLocatorW', 'UnicodeText', 'Text') {
        if (-not $Data.GetDataPresent($fmt)) { continue }
        $raw = $Data.GetData($fmt)
        if ($raw -is [System.IO.MemoryStream]) {
            $text = [System.Text.Encoding]::Unicode.GetString($raw.ToArray())
        } elseif ($raw -is [string]) {
            $text = $raw
        }
        if (-not [string]::IsNullOrWhiteSpace($text)) { break }
    }
    if (-not [string]::IsNullOrWhiteSpace($text)) {
        $line = ($text -split "`r?`n")[0].Trim().Trim([char]0)
        $info = Resolve-DLauncherTarget -Value $line
        if ($info.Kind -eq 'Url' -and $info.Host -ne "") {
            $null = $items.Add(@{ Name = ($info.Host -replace '^www\.', ''); Url = $info.Target })
        }
    }
    return $items
}

function Global:Test-DLauncherDropAcceptable {
    param ($Data)
    if ($Data.GetDataPresent([System.Windows.DataFormats]::FileDrop)) { return $true }
    return (@(Get-DLauncherDropItems -Data $Data).Count -gt 0)
}

$ui.Window.Add_DragEnter({
    param($s, $e)
    if ($null -ne (Get-DLauncherOpenOverlay) -or -not (Test-DLauncherHasConfigFolder) -or -not (Test-DLauncherDropAcceptable -Data $e.Data)) {
        $e.Effects = [System.Windows.DragDropEffects]::None
        $e.Handled = $true
        return
    }
    if ($ui.DropOverlay.Visibility -ne [System.Windows.Visibility]::Visible) {
        $view = $Global:DLauncherState.ActiveView
        $ui.DropTargetText.Text = if (Test-DLauncherTagView -View $view) { T "drop.toGroup" (Get-DLauncherGroupName -GroupId $view) } else { T "drop.any" }
        Show-DLauncherOverlay $ui.DropOverlay
    }
    $e.Effects = [System.Windows.DragDropEffects]::Copy
    $e.Handled = $true
})

$ui.Window.Add_DragOver({
    param($s, $e)
    if ($ui.DropOverlay.Visibility -ne [System.Windows.Visibility]::Visible) {
        $e.Effects = [System.Windows.DragDropEffects]::None
        $e.Handled = $true
    }
})

$ui.DropOverlay.Add_DragOver({
    param($s, $e)
    $e.Effects = [System.Windows.DragDropEffects]::Copy
    $e.Handled = $true
})

$ui.DropOverlay.Add_DragLeave({
    param($s, $e)
    Hide-DLauncherOverlay $ui.DropOverlay
})

$ui.DropOverlay.Add_Drop({
    param($s, $e)
    Hide-DLauncherOverlay $ui.DropOverlay
    $e.Handled = $true
    $items = @(Get-DLauncherDropItems -Data $e.Data)
    if ($items.Count -eq 0) { return }

    $view = $Global:DLauncherState.ActiveView
    $tags = if (Test-DLauncherTagView -View $view) { @($view) } else { @() }
    $added = Add-DLauncherPlatformBatch -Items $items -Tags $tags
    Update-UIList
    $skipped = $items.Count - $added
    if ($added -eq 0) {
        Show-DLauncherToast (T "drop.exists") -Kind 'info'
    } elseif ($skipped -gt 0) {
        Show-DLauncherToast (T "drop.partial" $added $skipped)
    } else {
        Show-DLauncherToast $(if ($added -eq 1) { T "toast.added" $items[0].Name } else { T "drop.many" $added })
    }
})

# ===================== SUGERENCIAS =====================

function Global:Show-DLauncherSuggestions {
    if (-not (Test-DLauncherHasConfigFolder)) { return }
    Update-DLauncherSuggestions
    Show-DLauncherOverlay $ui.SuggestionsOverlay
}

function Global:New-DLauncherSuggestionCard {
    param ($Suggestion, [bool]$Added)
    $name = Get-DLauncherSuggestionName -Suggestion $Suggestion

    $card = New-Object System.Windows.Controls.Border
    $card.Width = 222
    $card.Margin = [System.Windows.Thickness]::new(0, 0, 8, 8)
    $card.Padding = [System.Windows.Thickness]::new(12, 11, 8, 8)
    $card.CornerRadius = [System.Windows.CornerRadius]::new(11)
    $card.BorderThickness = [System.Windows.Thickness]::new(1)
    $card.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, 'Border')
    $card.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, 'Subtle.Bg')
    $card.Add_MouseEnter({ param($s, $e) $s.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, 'Border.Strong') })
    $card.Add_MouseLeave({ param($s, $e) $s.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, 'Border') })

    $root = New-Object System.Windows.Controls.StackPanel

    $top = New-Object System.Windows.Controls.Grid
    foreach ($w in 'Auto', '*') {
        $cd = New-Object System.Windows.Controls.ColumnDefinition
        $cd.Width = [System.Windows.GridLengthConverter]::new().ConvertFromString($w)
        $null = $top.ColumnDefinitions.Add($cd)
    }
    $tile = New-Object System.Windows.Controls.Border
    $tile.Width = 32; $tile.Height = 32
    $tile.CornerRadius = [System.Windows.CornerRadius]::new(9)
    $tile.Margin = [System.Windows.Thickness]::new(0, 0, 11, 0)
    $tileGrid = New-Object System.Windows.Controls.Grid
    $letter = New-Object System.Windows.Controls.TextBlock
    $letter.Foreground = [System.Windows.Media.Brushes]::White
    $letter.FontSize = 13
    $letter.FontWeight = [System.Windows.FontWeights]::SemiBold
    $letter.HorizontalAlignment = 'Center'; $letter.VerticalAlignment = 'Center'
    $image = New-Object System.Windows.Controls.Image
    [System.Windows.Media.RenderOptions]::SetBitmapScalingMode($image, [System.Windows.Media.BitmapScalingMode]::HighQuality)
    $glyph = New-DLauncherIconPath -Name 'folder' -Size 15 -BrushKey 'Accent.Text'
    foreach ($el in $letter, $image, $glyph) { $null = $tileGrid.Children.Add($el) }
    $tile.Child = $tileGrid
    Set-DLauncherIconTile -Tile $tile -Letter $letter -Image $image -Glyph $glyph -Name $name -Url $Suggestion.Url -WebSize 17 -AppSize 20
    $null = $top.Children.Add($tile)

    $texts = New-Object System.Windows.Controls.StackPanel
    $texts.VerticalAlignment = 'Center'
    $title = New-DLauncherText -Text $name -Size 12.5 -Brush 'Fg.1' -Bold -Wrap $false
    $title.TextTrimming = 'CharacterEllipsis'
    $target = New-DLauncherText -Text $Suggestion.Url -Size 10.5 -Brush 'Fg.3' -Wrap $false -Margin @(0, 2, 0, 0)
    $target.FontFamily = $Global:DLauncherStylesDict['Font.Mono']
    $target.TextTrimming = 'CharacterEllipsis'
    $null = $texts.Children.Add($title)
    $null = $texts.Children.Add($target)
    [System.Windows.Controls.Grid]::SetColumn($texts, 1)
    $null = $top.Children.Add($texts)
    $null = $root.Children.Add($top)

    $bottom = New-Object System.Windows.Controls.Grid
    $bottom.Margin = [System.Windows.Thickness]::new(-4, 8, 0, 0)
    if ($Added) {
        $done = New-Object System.Windows.Controls.StackPanel
        $done.Orientation = 'Horizontal'
        $done.Margin = [System.Windows.Thickness]::new(6, 0, 0, 0)
        $done.VerticalAlignment = 'Center'
        $null = $done.Children.Add((New-DLauncherIconPath -Name 'check' -Size 11 -BrushKey 'Success' -Thickness 2))
        $null = $done.Children.Add((New-DLauncherText -Text (T "sugg.added") -Size 11.5 -Brush 'Success' -Wrap $false -Margin @(6, 0, 0, 0)))
        $null = $bottom.Children.Add($done)
    } else {
        $add = New-Object System.Windows.Controls.Button
        $add.SetResourceReference([System.Windows.FrameworkElement]::StyleProperty, 'GhostButton')
        $add.HorizontalAlignment = 'Left'
        $add.Tag = $Suggestion.Id
        $addContent = New-Object System.Windows.Controls.StackPanel
        $addContent.Orientation = 'Horizontal'
        $plus = New-DLauncherIconPath -Name 'plus' -Size 10 -BrushKey 'Accent.Text' -Thickness 2
        $plus.Margin = [System.Windows.Thickness]::new(0, 0, 6, 0)
        $null = $addContent.Children.Add($plus)
        $null = $addContent.Children.Add((New-DLauncherText -Text (T "sugg.add") -Size 12 -Brush 'Accent.Text' -Wrap $false))
        $add.Content = $addContent
        $add.Add_Click({ param($s, $e) Add-DLauncherSuggestion -Id ([string]$s.Tag) })
        $null = $bottom.Children.Add($add)
    }
    $right = New-Object System.Windows.Controls.StackPanel
    $right.Orientation = 'Horizontal'
    $right.HorizontalAlignment = 'Right'
    $custom = New-DLauncherNavAction -Icon 'edit' -BrushKey 'Fg.3' -Tag $Suggestion.Id -Tip (T "sugg.customize") -Size 10
    $custom.Width = 26; $custom.Height = 26
    $custom.Add_Click({ param($s, $e) Edit-DLauncherSuggestion -Id ([string]$s.Tag) })
    $hide = New-DLauncherNavAction -Icon 'hide' -BrushKey 'Fg.3' -Tag $Suggestion.Id -Tip (T "sugg.hide") -Size 13
    $hide.Width = 26; $hide.Height = 26
    $hide.Add_Click({ param($s, $e) Hide-DLauncherSuggestion -Id ([string]$s.Tag) })
    $null = $right.Children.Add($custom)
    $null = $right.Children.Add($hide)
    $null = $bottom.Children.Add($right)
    $null = $root.Children.Add($bottom)

    $card.Child = $root
    return $card
}

function Global:Update-DLauncherSuggestions {
    $panel = $ui.SuggestionsPanel
    $panel.Children.Clear()
    $cfg = Get-DLauncherConfig
    $hidden = @($cfg.Settings.HiddenSuggestions)
    $existing = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($p in $cfg.Platforms) { $null = $existing.Add((Get-DLauncherUrlKey $p.Url)) }
    $visible = @(Get-DLauncherSuggestions -Hidden $hidden)

    $first = $true
    foreach ($cat in $Global:DLauncherSuggestionCategories) {
        $items = @($visible | Where-Object { $_.Category -eq $cat })
        if ($items.Count -eq 0) { continue }
        $header = New-DLauncherText -Text (T "sugg.cat.$cat").ToUpperInvariant() -Size 10.5 -Brush 'Fg.3' -Bold -Margin @(0, $(if ($first) { 4 } else { 14 }), 0, 9)
        $null = $panel.Children.Add($header)
        $wrap = New-Object System.Windows.Controls.WrapPanel
        foreach ($s in $items) {
            $null = $wrap.Children.Add((New-DLauncherSuggestionCard -Suggestion $s -Added $existing.Contains((Get-DLauncherUrlKey $s.Url))))
        }
        $null = $panel.Children.Add($wrap)
        $first = $false
    }
    if ($visible.Count -eq 0) {
        $null = $panel.Children.Add((New-DLauncherText -Text (T "sugg.allHidden") -Size 12.5 -Brush 'Fg.3' -Margin @(0, 10, 0, 10)))
    }

    $ui.SuggestionsFooterText.Text = T "sugg.footer"
    $ui.RestoreSuggestionsText.Text = T "sugg.restore" $hidden.Count
    $ui.BtnRestoreSuggestions.Visibility = if ($hidden.Count -gt 0) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
}

function Global:Get-DLauncherSuggestionById {
    param ([string]$Id)
    return ($Global:DLauncherSuggestions | Where-Object { $_.Id -eq $Id } | Select-Object -First 1)
}

function Global:Add-DLauncherSuggestion {
    param ([string]$Id)
    $s = Get-DLauncherSuggestionById -Id $Id
    if ($null -eq $s) { return }
    $name = Get-DLauncherSuggestionName -Suggestion $s
    $view = $Global:DLauncherState.ActiveView
    $tags = if (Test-DLauncherTagView -View $view) { @($view) } else { @() }
    $added = Add-DLauncherPlatformBatch -Items @(@{ Name = $name; Url = $s.Url }) -Tags $tags
    Update-UIList
    Update-DLauncherSuggestions
    if ($added -gt 0) { Show-DLauncherToast (T "toast.added" $name) } else { Show-DLauncherToast (T "drop.exists") -Kind 'info' }
}

function Global:Edit-DLauncherSuggestion {
    param ([string]$Id)
    $s = Get-DLauncherSuggestionById -Id $Id
    if ($null -eq $s) { return }
    Hide-DLauncherOverlay $ui.SuggestionsOverlay
    Show-DLauncherPlatformForm -PresetName (Get-DLauncherSuggestionName -Suggestion $s) -PresetUrl $s.Url
}

function Global:Hide-DLauncherSuggestion {
    param ([string]$Id)
    $cfg = Get-DLauncherConfig
    $cfg.Settings.HiddenSuggestions = @(@($cfg.Settings.HiddenSuggestions) + $Id | Select-Object -Unique)
    $null = Save-DLauncherConfig -Config $cfg
    Update-DLauncherSuggestions
}

function Global:Restore-DLauncherSuggestions {
    Set-DLauncherSetting -Name 'HiddenSuggestions' -Value @()
    if ($ui.SuggestionsOverlay.Visibility -eq [System.Windows.Visibility]::Visible) { Update-DLauncherSuggestions }
    Show-DLauncherToast (T "sugg.restored")
}

$ui.BtnCloseSuggestions.Add_Click({ Hide-DLauncherOverlay $ui.SuggestionsOverlay })
$ui.BtnDoneSuggestions.Add_Click({ Hide-DLauncherOverlay $ui.SuggestionsOverlay })
$ui.BtnRestoreSuggestions.Add_Click({ Restore-DLauncherSuggestions })

# ===================== PALETA DE COMANDOS =====================

$Global:DLauncherCommands = @(
    @{ Id = 'openSelected';  Key = 'cmd.openSelected';  Hint = 'Ctrl+Enter'; Icon = 'play';     Action = { Start-DLauncherBatch } }
    @{ Id = 'add';           Key = 'cmd.add';           Hint = 'Ctrl+N';     Icon = 'plus';     Action = { Show-DLauncherPlatformForm } }
    @{ Id = 'suggestions';   Key = 'cmd.suggestions';   Hint = '';           Icon = 'sparkle';  Action = { Show-DLauncherSuggestions } }
    @{ Id = 'newTag';        Key = 'cmd.newTag';        Hint = '';           Icon = 'tag';      Action = { Show-DLauncherGroupForm } }
    @{ Id = 'viewAll';       Key = 'cmd.viewAll';       Hint = '';           Icon = 'grid';     Action = { Select-DLauncherView -View "" } }
    @{ Id = 'viewSelected';  Key = 'cmd.viewSelected';  Hint = '';           Icon = 'checked';  Action = { Select-DLauncherView -View '::selected' } }
    @{ Id = 'selectAll';     Key = 'cmd.selectAll';     Hint = '';           Icon = 'checked';  Action = { Set-DLauncherVisibleChecked -Target $true } }
    @{ Id = 'clearSel';      Key = 'cmd.clearSelection';Hint = '';           Icon = 'close';    Action = { Set-DLauncherVisibleChecked -Target $false } }
    @{ Id = 'theme';         Key = 'cmd.toggleTheme';   Hint = '';           Icon = 'sun';      Action = { Switch-DLauncherThemeQuick } }
    @{ Id = 'sidebar';       Key = 'cmd.toggleSidebar'; Hint = 'Ctrl+B';     Icon = 'sidebar';  Action = { Switch-DLauncherSidebar } }
    @{ Id = 'language';      Key = 'cmd.language';      Hint = '';           Icon = 'globe';    Action = { Switch-DLauncherLanguage -Code $(if ($Global:DLauncherLanguage -eq 'es') { 'en' } else { 'es' }) } }
    @{ Id = 'settings';      Key = 'cmd.settings';      Hint = 'Ctrl+,';     Icon = 'sliders';  Action = { Show-DLauncherSettings } }
    @{ Id = 'delay';         Key = 'cmd.delay';         Hint = '';           Icon = 'clock';    Action = { Show-DLauncherSettings -Page 'launch' } }
    @{ Id = 'help';          Key = 'cmd.help';          Hint = 'F1';         Icon = 'help';     Action = { Show-DLauncherHelp -Page 'faq' } }
    @{ Id = 'shortcuts';     Key = 'cmd.shortcuts';     Hint = '';           Icon = 'keyboard'; Action = { Show-DLauncherHelp -Page 'keys' } }
    @{ Id = 'privacy';       Key = 'cmd.privacy';       Hint = '';           Icon = 'shield';   Action = { Show-DLauncherHelp -Page 'privacy' } }
    @{ Id = 'terms';         Key = 'cmd.terms';         Hint = '';           Icon = 'doc';      Action = { Show-DLauncherHelp -Page 'terms' } }
    @{ Id = 'export';        Key = 'cmd.export';        Hint = '';           Icon = 'export';   Action = { Invoke-DLauncherExport } }
    @{ Id = 'import';        Key = 'cmd.import';        Hint = '';           Icon = 'import';   Action = { Invoke-DLauncherImport } }
    @{ Id = 'openFolder';    Key = 'cmd.openFolder';    Hint = '';           Icon = 'folder';   Action = { Open-DLauncherConfigFolder } }
)

function Global:Show-DLauncherPalette {
    if (-not (Test-DLauncherHasConfigFolder)) { return }
    $ui.PaletteBox.Text = ""
    Update-DLauncherPalette
    Show-DLauncherOverlay $ui.PaletteOverlay
    $null = $ui.PaletteBox.Focus()
}

function Global:Update-DLauncherPalette {
    $query = ConvertTo-DLauncherSearchKey $ui.PaletteBox.Text.Trim()
    $ui.PalettePlaceholder.Visibility = if ($ui.PaletteBox.Text -eq "") { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
    $results = [System.Collections.ArrayList]::new()

    # Herramientas (solo al escribir) y etiquetas
    if ($query -ne "") {
        foreach ($r in $Global:DLauncherState.Rows) {
            if ($r.SearchKey.Contains($query)) {
                $null = $results.Add(@{ Kind = 'tool'; Text = $r.Platform.Name; Hint = T "palette.openTool"; Icon = 'play'; Arg = $r.Platform.Id })
            }
        }
        foreach ($g in $Global:DLauncherState.Groups) {
            if ((ConvertTo-DLauncherSearchKey $g.Name).Contains($query)) {
                $null = $results.Add(@{ Kind = 'tag'; Text = T "palette.showTag" $g.Name; Hint = T "palette.tag"; Icon = 'tag'; Arg = $g.Id })
            }
        }
    }
    foreach ($c in $Global:DLauncherCommands) {
        $text = T $c.Key
        if ($query -eq "" -or (ConvertTo-DLauncherSearchKey $text).Contains($query)) {
            $null = $results.Add(@{ Kind = 'cmd'; Text = $text; Hint = $c.Hint; Icon = $c.Icon; Action = $c.Action })
        }
    }

    $Global:DLauncherState.PaletteItems = [System.Collections.ArrayList]::new()
    foreach ($item in ($results | Select-Object -First 9)) { $null = $Global:DLauncherState.PaletteItems.Add($item) }
    $Global:DLauncherState.PaletteIndex = 0
    Update-DLauncherPaletteList
}

function Global:Update-DLauncherPaletteList {
    $ui.PaletteList.Children.Clear()
    $items = $Global:DLauncherState.PaletteItems
    $ui.PaletteEmptyText.Visibility = if ($items.Count -eq 0) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
    for ($i = 0; $i -lt $items.Count; $i++) {
        $it = $items[$i]
        $row = New-Object System.Windows.Controls.Border
        $row.CornerRadius = [System.Windows.CornerRadius]::new(8)
        $row.Padding = [System.Windows.Thickness]::new(12, 0, 12, 0)
        $row.Height = 36
        $row.Cursor = [System.Windows.Input.Cursors]::Hand
        $row.Tag = $i
        if ($i -eq $Global:DLauncherState.PaletteIndex) {
            $row.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, 'Active.Bg')
        } else {
            $row.Background = [System.Windows.Media.Brushes]::Transparent
        }
        $grid = New-Object System.Windows.Controls.Grid
        foreach ($w in 'Auto', '*', 'Auto') {
            $cd = New-Object System.Windows.Controls.ColumnDefinition
            $cd.Width = [System.Windows.GridLengthConverter]::new().ConvertFromString($w)
            $null = $grid.ColumnDefinitions.Add($cd)
        }
        $brush = switch ($it.Kind) { 'tool' { 'Success' } 'tag' { 'Orange.Text' } default { 'Fg.2' } }
        $icon = New-DLauncherIconPath -Name $it.Icon -Size 13 -BrushKey $brush
        $icon.Margin = [System.Windows.Thickness]::new(0, 0, 12, 0)
        $null = $grid.Children.Add($icon)
        $label = New-DLauncherText -Text $it.Text -Size 13 -Brush 'Fg.1' -Wrap $false
        $label.VerticalAlignment = 'Center'
        $label.TextTrimming = 'CharacterEllipsis'
        [System.Windows.Controls.Grid]::SetColumn($label, 1)
        $null = $grid.Children.Add($label)
        if (-not [string]::IsNullOrEmpty($it.Hint)) {
            $hint = New-DLauncherText -Text $it.Hint -Size 11 -Brush 'Fg.3' -Wrap $false -Margin @(12, 0, 0, 0)
            $hint.VerticalAlignment = 'Center'
            [System.Windows.Controls.Grid]::SetColumn($hint, 2)
            $null = $grid.Children.Add($hint)
        }
        $row.Child = $grid
        $row.Add_MouseLeftButtonUp({ param($s, $e) Invoke-DLauncherPaletteItem -Index ([int]$s.Tag) })
        $row.Add_MouseEnter({
            param($s, $e)
            if ([int]$s.Tag -ne $Global:DLauncherState.PaletteIndex) { $s.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, 'Hover.Bg') }
        })
        $row.Add_MouseLeave({
            param($s, $e)
            if ([int]$s.Tag -ne $Global:DLauncherState.PaletteIndex) { $s.Background = [System.Windows.Media.Brushes]::Transparent }
        })
        $null = $ui.PaletteList.Children.Add($row)
    }
}

function Global:Invoke-DLauncherPaletteItem {
    param ([int]$Index)
    $items = $Global:DLauncherState.PaletteItems
    if ($Index -lt 0 -or $Index -ge $items.Count) { return }
    $it = $items[$Index]
    Hide-DLauncherOverlay $ui.PaletteOverlay
    switch ($it.Kind) {
        'tool' { Set-DLauncherCursor -Id $it.Arg -Scroll; Start-DLauncherSingle -Id $it.Arg }
        'tag'  { Select-DLauncherView -View $it.Arg }
        default { & $it.Action }
    }
}

$ui.PaletteBox.Add_TextChanged({ Update-DLauncherPalette })
$ui.PaletteBox.Add_PreviewKeyDown({
    param($s, $e)
    $count = $Global:DLauncherState.PaletteItems.Count
    if ($e.Key -eq [System.Windows.Input.Key]::Down -and $count -gt 0) {
        $Global:DLauncherState.PaletteIndex = ($Global:DLauncherState.PaletteIndex + 1) % $count
        Update-DLauncherPaletteList
        $e.Handled = $true
    } elseif ($e.Key -eq [System.Windows.Input.Key]::Up -and $count -gt 0) {
        $Global:DLauncherState.PaletteIndex = ($Global:DLauncherState.PaletteIndex - 1 + $count) % $count
        Update-DLauncherPaletteList
        $e.Handled = $true
    } elseif ($e.Key -eq [System.Windows.Input.Key]::Enter) {
        Invoke-DLauncherPaletteItem -Index $Global:DLauncherState.PaletteIndex
        $e.Handled = $true
    }
})
# Clic fuera de la tarjeta: cerrar
$ui.PaletteOverlay.Add_MouseLeftButtonDown({
    param($s, $e)
    if ($e.OriginalSource -eq $s) { Hide-DLauncherOverlay $ui.PaletteOverlay }
})

# ===================== AJUSTES =====================

function Global:Get-DLauncherDelayLabel {
    param ([string]$Value)
    $text = Get-DLauncherTextOrNull -Key "delay.$Value"
    if ($null -ne $text) { return $text }
    return "$Value ms"
}

function Global:Get-DLauncherDelayOptions {
    param ([string]$Current)
    $options = @(foreach ($v in "0", "250", "500", "1000", "2000", "3000", "5000") { @{ Text = (Get-DLauncherDelayLabel -Value $v); Value = $v } })
    if ($Current -ne "" -and -not ($options | Where-Object { $_.Value -eq $Current })) {
        $options += @{ Text = "$Current ms"; Value = $Current }
    }
    return $options
}

$Global:DLauncherSettingsPages = [ordered]@{
    general    = @('SetNavGeneral', 'SetPageGeneral')
    appearance = @('SetNavAppearance', 'SetPageAppearance')
    launch     = @('SetNavLaunch', 'SetPageLaunch')
    data       = @('SetNavData', 'SetPageData')
}

function Global:Select-DLauncherSettingsPage {
    param ([string]$Page)
    if (-not $Global:DLauncherSettingsPages.Contains($Page)) { $Page = 'general' }
    foreach ($key in $Global:DLauncherSettingsPages.Keys) {
        $names = $Global:DLauncherSettingsPages[$key]
        $ui[$names[1]].Visibility = if ($key -eq $Page) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
    }
    $radio = $ui[$Global:DLauncherSettingsPages[$Page][0]]
    if (-not $radio.IsChecked) { $radio.IsChecked = $true }
    $ui.SettingsPageTitle.Text = [string]$radio.Content
    $Global:DLauncherState.SettingsPage = $Page
}

# Carga los valores actuales en los controles (sin disparar sus eventos)
function Global:Update-DLauncherSettingsValues {
    $hasFolder = Test-DLauncherHasConfigFolder
    $Global:DLauncherState.SuppressSettingsEvents = $true
    try {
        $remember = $true; $favicons = $true; $confirm = $true; $delay = "500"; $hiddenCount = 0
        if ($hasFolder) {
            $cfg = Get-DLauncherConfig
            $remember = [bool]$cfg.Settings.RememberCheckState
            $favicons = [bool]$cfg.Settings.FetchFavicons
            $confirm = [bool]$cfg.Settings.ConfirmManyLaunches
            $delay = [string][int]$cfg.Settings.LaunchDelayMs
            $hiddenCount = @($cfg.Settings.HiddenSuggestions).Count
        }
        $ui.ChkRememberCheckState.IsChecked = $remember
        $ui.ChkFetchFavicons.IsChecked = $favicons
        $ui.ChkConfirmMany.IsChecked = $confirm
        $ui.ChkShowSidebar.IsChecked = -not [bool](Get-DLauncherPref -Name 'SidebarHidden' -Default $false)

        $exe = Get-DLauncherExePath
        $ui.ChkRunAtStartup.IsEnabled = ($null -ne $exe)
        $ui.ChkRunAtStartup.IsChecked = Test-DLauncherRunAtStartup
        $ui.StartupDescText.Text = if ($null -ne $exe) { T "settings.startup.desc" } else { T "startup.unavailable" }

        Set-DLauncherComboItems $ui.CmbLaunchDelay (Get-DLauncherDelayOptions -Current $delay) $delay
        Set-DLauncherComboItems $ui.CmbLanguage @(foreach ($l in $Global:DLauncherLanguages) { @{ Text = $l.Name; Value = $l.Code } }) $Global:DLauncherLanguage
        Set-DLauncherComboItems $ui.CmbTheme @(foreach ($m in 'system', 'dark', 'light') { @{ Text = (T "theme.$m"); Value = $m } }) $Global:DLauncherThemeMode

        $ui.SettingsFolderText.Text = if ($hasFolder) { $Global:ConfigDir } else { T "settings.noFolder" }
        $ui.RestoreSuggestionsSettingsText.Text = T "sugg.restore" $hiddenCount
        $ui.BtnRestoreSuggestionsSettings.IsEnabled = ($hiddenCount -gt 0)
        foreach ($c in $ui.ChkRememberCheckState, $ui.ChkFetchFavicons, $ui.ChkConfirmMany, $ui.CmbLaunchDelay,
                       $ui.BtnExportConfig, $ui.BtnImportConfig, $ui.BtnOpenConfigFolder, $ui.BtnClearAll) {
            $c.IsEnabled = $hasFolder
        }
    } finally {
        $Global:DLauncherState.SuppressSettingsEvents = $false
    }
}

function Global:Show-DLauncherSettings {
    param ([string]$Page = "")
    Update-DLauncherSettingsValues
    Select-DLauncherSettingsPage -Page $(if ($Page -ne "") { $Page } else { $Global:DLauncherState.SettingsPage })
    Show-DLauncherOverlay $ui.SettingsOverlay
}

$ui.SetNavGeneral.Add_Checked({ Select-DLauncherSettingsPage -Page 'general' })
$ui.SetNavAppearance.Add_Checked({ Select-DLauncherSettingsPage -Page 'appearance' })
$ui.SetNavLaunch.Add_Checked({ Select-DLauncherSettingsPage -Page 'launch' })
$ui.SetNavData.Add_Checked({ Select-DLauncherSettingsPage -Page 'data' })

$ui.BtnSettings.Add_Click({ Show-DLauncherSettings })
$ui.BtnSaveSettings.Add_Click({ Hide-DLauncherOverlay $ui.SettingsOverlay })
$ui.BtnCloseSettings.Add_Click({ Hide-DLauncherOverlay $ui.SettingsOverlay })

# Los ajustes se aplican y guardan al instante
$onRemember = {
    if ($Global:DLauncherState.SuppressSettingsEvents) { return }
    Set-DLauncherSetting -Name 'RememberCheckState' -Value ([bool]$ui.ChkRememberCheckState.IsChecked)
}
$ui.ChkRememberCheckState.Add_Checked($onRemember)
$ui.ChkRememberCheckState.Add_Unchecked($onRemember)

$onFavicons = {
    if ($Global:DLauncherState.SuppressSettingsEvents) { return }
    Set-DLauncherSetting -Name 'FetchFavicons' -Value ([bool]$ui.ChkFetchFavicons.IsChecked)
    Update-UIList
}
$ui.ChkFetchFavicons.Add_Checked($onFavicons)
$ui.ChkFetchFavicons.Add_Unchecked($onFavicons)

$onConfirmMany = {
    if ($Global:DLauncherState.SuppressSettingsEvents) { return }
    Set-DLauncherSetting -Name 'ConfirmManyLaunches' -Value ([bool]$ui.ChkConfirmMany.IsChecked)
}
$ui.ChkConfirmMany.Add_Checked($onConfirmMany)
$ui.ChkConfirmMany.Add_Unchecked($onConfirmMany)

$onSidebar = {
    if ($Global:DLauncherState.SuppressSettingsEvents) { return }
    Set-DLauncherPref -Name 'SidebarHidden' -Value (-not [bool]$ui.ChkShowSidebar.IsChecked)
    Update-DLauncherSidebarVisibility
}
$ui.ChkShowSidebar.Add_Checked($onSidebar)
$ui.ChkShowSidebar.Add_Unchecked($onSidebar)

$onStartup = {
    if ($Global:DLauncherState.SuppressSettingsEvents) { return }
    $enable = [bool]$ui.ChkRunAtStartup.IsChecked
    try {
        Set-DLauncherRunAtStartup -Enabled $enable
        Show-DLauncherToast $(if ($enable) { T "startup.on" } else { T "startup.off" })
    } catch {
        $Global:DLauncherState.SuppressSettingsEvents = $true
        $ui.ChkRunAtStartup.IsChecked = -not $enable
        $Global:DLauncherState.SuppressSettingsEvents = $false
        Show-DLauncherMessageBox -Title (T "err.title") -Message $_.Exception.Message
    }
}
$ui.ChkRunAtStartup.Add_Checked($onStartup)
$ui.ChkRunAtStartup.Add_Unchecked($onStartup)

$ui.CmbLaunchDelay.Add_SelectionChanged({
    if ($Global:DLauncherState.SuppressSettingsEvents) { return }
    $v = Get-DLauncherComboValue $ui.CmbLaunchDelay
    if ($v -ne "") {
        Set-DLauncherSetting -Name 'LaunchDelayMs' -Value ([int]$v)
        Update-DLauncherDelayText
    }
})

$ui.CmbLanguage.Add_SelectionChanged({
    if ($Global:DLauncherState.SuppressSettingsEvents) { return }
    $code = Get-DLauncherComboValue $ui.CmbLanguage
    if ($code -ne "") { Switch-DLauncherLanguage -Code $code }
})

$ui.CmbTheme.Add_SelectionChanged({
    if ($Global:DLauncherState.SuppressSettingsEvents) { return }
    $mode = Get-DLauncherComboValue $ui.CmbTheme
    if ($mode -ne "") {
        Set-DLauncherTheme -Mode $mode -Persist
        Sync-DLauncherSetupChoices
    }
})

function Global:Open-DLauncherConfigFolder {
    if (-not (Test-DLauncherHasConfigFolder)) { return }
    try { $null = [System.Diagnostics.Process]::Start('explorer.exe', "`"$($Global:ConfigDir)`"") } catch { }
}

function Global:Invoke-DLauncherExport {
    if (-not (Test-DLauncherHasConfigFolder)) { return }
    $dialog = New-Object Microsoft.Win32.SaveFileDialog
    $dialog.Title = T "export.title"
    $dialog.Filter = "$(T 'export.filter') (*.json)|*.json"
    $dialog.FileName = "DLauncher-config-$(Get-Date -Format 'yyyyMMdd').json"
    if ($dialog.ShowDialog() -eq $true) {
        try {
            Export-DLauncherConfig -Path $dialog.FileName
            Show-DLauncherToast (T "export.done")
        } catch {
            Show-DLauncherMessageBox -Title (T "export.errorTitle") -Message $_.Exception.Message
        }
    }
}

function Global:Invoke-DLauncherImport {
    if (-not (Test-DLauncherHasConfigFolder)) { return }
    $dialog = New-Object Microsoft.Win32.OpenFileDialog
    $dialog.Title = T "import.title"
    $dialog.Filter = "$(T 'export.filter') (*.json)|*.json|$(T 'browse.filterAll') (*.*)|*.*"
    if ($dialog.ShowDialog() -eq $true) {
        try {
            $snapshot = Get-DLauncherConfigSnapshot
            $res = Import-DLauncherConfig -Path $dialog.FileName
            Hide-DLauncherOverlay $ui.SettingsOverlay
            Update-UIList
            Update-DLauncherFilter -Animate
            $body = T "import.doneBody" $res.Added $res.Skipped $res.GroupsAdded
            if ($res.Added -gt 0) { $body += "`n`n" + (T "import.unselected") }
            if ($res.CodeTargets -gt 0) { $body += "`n`n" + (T "import.codeWarning" $res.CodeTargets) }
            Show-DLauncherMessageBox -Title (T "import.doneTitle") -Message $body
            if ($res.Added -gt 0) { Show-DLauncherUndoToast -Text (T "toast.imported" $res.Added) -Snapshot $snapshot }
        } catch {
            Show-DLauncherMessageBox -Title (T "import.errorTitle") -Message $_.Exception.Message
        }
    }
}

$ui.BtnExportConfig.Add_Click({ Invoke-DLauncherExport })
$ui.BtnImportConfig.Add_Click({ Invoke-DLauncherImport })
$ui.BtnOpenConfigFolder.Add_Click({ Open-DLauncherConfigFolder })
$ui.BtnStatusFolder.Add_Click({ Open-DLauncherConfigFolder })
$ui.BtnRestoreSuggestionsSettings.Add_Click({
    Restore-DLauncherSuggestions
    Update-DLauncherSettingsValues
})
$ui.BtnClearIconCache.Add_Click({
    Clear-DLauncherIconCache
    Update-UIList
    Show-DLauncherToast (T "toast.cacheCleared")
})

# Elegir (o cambiar) la carpeta de configuración. Devuelve $true si se eligió una
function Global:Invoke-DLauncherChooseConfigFolder {
    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderDialog.Description = T "folder.desc"
    $folderDialog.ShowNewFolderButton = $true
    if ($folderDialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK -or [string]::IsNullOrWhiteSpace($folderDialog.SelectedPath)) {
        return $false
    }
    $res = Set-DLauncherConfigFolder -FolderPath $folderDialog.SelectedPath
    Hide-DLauncherOverlay $ui.SettingsOverlay
    Update-UIList
    if ($res.AlreadyExisted) {
        Show-DLauncherMessageBox -Title (T "folder.loadedTitle") -Message (T "folder.loadedBody")
    } else {
        Show-DLauncherMessageBox -Title (T "folder.createdTitle") -Message (T "folder.createdBody")
    }
    return $true
}

$ui.BtnChangeConfigFolder.Add_Click({ $null = Invoke-DLauncherChooseConfigFolder })

# ===================== SINCRONIZACIÓN ENTRE EQUIPOS =====================
# Con la ventana activa se comprueba cada pocos segundos si config.json ha cambiado desde otro equipo
# (o si la carpeta ha desaparecido o vuelto), y la lista se actualiza sola sin perder la vista actual

function Global:Update-DLauncherFromDisk {
    $view = $Global:DLauncherState.ActiveView
    $offset = $ui.ListScroll.VerticalOffset
    Update-UIList
    # Mantener la vista local (la del otro equipo no debe cambiar lo que estás mirando)
    $stillValid = ($view -eq "" -or $view -eq '::selected' -or @($Global:DLauncherState.Groups | Where-Object { $_.Id -eq $view }).Count -gt 0)
    if ($stillValid -and $view -ne $Global:DLauncherState.ActiveView) {
        $Global:DLauncherState.ActiveView = $view
        Update-DLauncherNavStyles
        Update-DLauncherHeader
        Update-DLauncherFilter
    }
    $ui.ListScroll.ScrollToVerticalOffset($offset)
}

function Global:Invoke-DLauncherConfigWatch {
    if ([string]::IsNullOrWhiteSpace((Get-DLauncherConfigPointer))) { return }
    if ($Global:DLauncherState.Launching) { return }

    if (Test-DLauncherConfigFolderMissing) {
        if (-not $Global:DLauncherFolderMissing) {
            # Acaba de desaparecer: se conserva la lista en pantalla (solo lectura) y se avisa
            $Global:DLauncherFolderMissing = $true
            $Global:DLauncherConfigReadOnly = $true
            Add-DLauncherConfigNotice -Kind 'missing' -Detail (Get-DLauncherConfigPointer)
            Show-DLauncherConfigNotices
        }
        return
    }

    if ($Global:DLauncherFolderMissing) {
        # Ha vuelto (unidad reconectada, carpeta restaurada…)
        $Global:DLauncherFolderMissing = $false
        $Global:DLauncherMissingShown = $false
        $Global:DLauncherConfigNotices.Clear()
        if ($ui.ConfirmOverlay.Visibility -eq [System.Windows.Visibility]::Visible -and $ui.ConfirmTitleText.Text -eq (T "notice.missing.title")) {
            Hide-DLauncherOverlay $ui.ConfirmOverlay
            $Global:DLauncherState.ActiveOkCallback = $null
            $Global:DLauncherState.ActiveCancelCallback = $null
        }
        Initialize-DLauncherConfig
        Update-DLauncherFromDisk
        Show-DLauncherToast -Text (T "toast.folderBack") -Kind 'info'
        return
    }

    # No refrescar mientras se edita algo o se arrastra una fila
    if ($null -ne (Get-DLauncherOpenOverlay)) { return }
    if ([System.Windows.Input.Mouse]::LeftButton -eq [System.Windows.Input.MouseButtonState]::Pressed) { return }

    if (Test-DLauncherConfigChangedExternally) {
        Update-DLauncherFromDisk
        Show-DLauncherToast -Text (T "toast.reloaded") -Kind 'info'
    }
}

$Global:DLauncherWatchTimer = New-Object System.Windows.Threading.DispatcherTimer
$Global:DLauncherWatchTimer.Interval = [TimeSpan]::FromSeconds(3)
$Global:DLauncherWatchTimer.Add_Tick({
    if (-not $ui.Window.IsActive) { return }
    try { Invoke-DLauncherConfigWatch } catch { }
})
$ui.Window.Add_Activated({ try { Invoke-DLauncherConfigWatch } catch { } })

$ui.BtnClearAll.Add_Click({
    Show-DLauncherMessageBox -Title (T "clearAll.title") -Message (T "clearAll.body") -OkText (T "clearAll.ok") -CancelText (T "common.cancel") -Danger -OnOk {
        $snapshot = Get-DLauncherConfigSnapshot
        Clear-DLauncherPlatforms
        Hide-DLauncherOverlay $ui.SettingsOverlay
        Update-UIList
        Show-DLauncherUndoToast -Text (T "toast.clearedAll") -Snapshot $snapshot
    }
})

# ===================== AYUDA Y TEXTOS LEGALES =====================

$Global:DLauncherHelpPages = [ordered]@{
    faq        = 'HelpNavFaq'
    icons      = 'HelpNavIcons'
    keys       = 'HelpNavKeys'
    privacy    = 'HelpNavPrivacy'
    warnings   = 'HelpNavWarnings'
    terms      = 'HelpNavTerms'
    disclaimer = 'HelpNavDisclaimer'
    about      = 'HelpNavAbout'
}

function Global:Show-DLauncherHelp {
    param ([string]$Page = "")
    Select-DLauncherHelpPage -Page $(if ($Page -ne "") { $Page } else { $Global:DLauncherState.HelpPage })
    Show-DLauncherOverlay $ui.HelpOverlay
}

function Global:Select-DLauncherHelpPage {
    param ([string]$Page)
    if ($Global:DLauncherState.SelectingHelpPage) { return }
    if (-not $Global:DLauncherHelpPages.Contains($Page)) { $Page = 'faq' }
    $Global:DLauncherState.SelectingHelpPage = $true
    try {
        $radio = $ui[$Global:DLauncherHelpPages[$Page]]
        if (-not $radio.IsChecked) { $radio.IsChecked = $true }
        $Global:DLauncherState.HelpPage = $Page
        $ui.HelpPageTitle.Text = [string]$radio.Content
        Build-DLauncherHelpContent -Page $Page
        $ui.HelpScroll.ScrollToTop()
    } finally {
        $Global:DLauncherState.SelectingHelpPage = $false
    }
}

foreach ($entry in $Global:DLauncherHelpPages.GetEnumerator()) {
    $ui[$entry.Value].Tag = $entry.Key
    $ui[$entry.Value].Add_Checked({ param($s, $e) Select-DLauncherHelpPage -Page ([string]$s.Tag) })
}

# Texto con formato ligero: "## Título", párrafos separados por línea en blanco y viñetas "• "
function Global:Add-DLauncherRichText {
    param ($Panel, [string]$Text)
    $Text = $Text -replace "`r", ""
    foreach ($block in ($Text -split "`n`n")) {
        $lines = @($block -split "`n" | Where-Object { $_ -ne "" })
        if ($lines.Count -eq 0) { continue }
        $paragraph = [System.Collections.ArrayList]::new()
        foreach ($line in $lines) {
            if ($line.StartsWith('## ')) {
                $null = $Panel.Children.Add((New-DLauncherText -Text $line.Substring(3) -Size 13.5 -Brush 'Fg.1' -Bold -Margin @(0, 10, 0, 6)))
            } elseif ($line.StartsWith('• ')) {
                $grid = New-Object System.Windows.Controls.Grid
                $grid.Margin = [System.Windows.Thickness]::new(2, 0, 0, 6)
                foreach ($w in 'Auto', '*') {
                    $cd = New-Object System.Windows.Controls.ColumnDefinition
                    $cd.Width = [System.Windows.GridLengthConverter]::new().ConvertFromString($w)
                    $null = $grid.ColumnDefinitions.Add($cd)
                }
                $dot = New-Object System.Windows.Shapes.Ellipse
                $dot.Width = 4; $dot.Height = 4
                $dot.SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, 'Accent.Text')
                $dot.VerticalAlignment = 'Top'
                $dot.Margin = [System.Windows.Thickness]::new(0, 8, 11, 0)
                $null = $grid.Children.Add($dot)
                $tb = New-DLauncherText -Text $line.Substring(2) -Size 12.5 -Brush 'Fg.2' -LineHeight 19
                [System.Windows.Controls.Grid]::SetColumn($tb, 1)
                $null = $grid.Children.Add($tb)
                $null = $Panel.Children.Add($grid)
            } else {
                $null = $paragraph.Add($line)
            }
        }
        if ($paragraph.Count -gt 0) {
            $null = $Panel.Children.Add((New-DLauncherText -Text ($paragraph -join "`n") -Size 12.5 -Brush 'Fg.2' -LineHeight 20 -Margin @(0, 0, 0, 12)))
        } elseif ($Panel.Children.Count -gt 0) {
            $last = $Panel.Children[$Panel.Children.Count - 1]
            if ($last -is [System.Windows.Controls.Grid]) { $last.Margin = [System.Windows.Thickness]::new(2, 0, 0, 12) }
        }
    }
}

# Fila de leyenda: mosaico con icono + título y descripción
function Global:New-DLauncherLegendRow {
    param ($Visual, [string]$Title, [string]$Desc)
    $grid = New-Object System.Windows.Controls.Grid
    $grid.Margin = [System.Windows.Thickness]::new(0, 0, 0, 14)
    foreach ($w in 'Auto', '*') {
        $cd = New-Object System.Windows.Controls.ColumnDefinition
        $cd.Width = [System.Windows.GridLengthConverter]::new().ConvertFromString($w)
        $null = $grid.ColumnDefinitions.Add($cd)
    }
    $tile = New-Object System.Windows.Controls.Border
    $tile.Width = 36; $tile.Height = 36
    $tile.CornerRadius = [System.Windows.CornerRadius]::new(9)
    $tile.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, 'Subtle.Bg')
    $tile.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, 'Border')
    $tile.BorderThickness = [System.Windows.Thickness]::new(1)
    $tile.Margin = [System.Windows.Thickness]::new(0, 0, 14, 0)
    $tile.VerticalAlignment = 'Top'
    $tile.Child = $Visual
    $null = $grid.Children.Add($tile)
    $texts = New-Object System.Windows.Controls.StackPanel
    $texts.VerticalAlignment = 'Center'
    $null = $texts.Children.Add((New-DLauncherText -Text $Title -Size 13 -Brush 'Fg.1' -Bold))
    $null = $texts.Children.Add((New-DLauncherText -Text $Desc -Size 12 -Brush 'Fg.2' -Margin @(0, 2, 0, 0) -LineHeight 18))
    [System.Windows.Controls.Grid]::SetColumn($texts, 1)
    $null = $grid.Children.Add($texts)
    return $grid
}

function Global:New-DLauncherKbd {
    param ([string]$Text)
    $b = New-Object System.Windows.Controls.Border
    $b.CornerRadius = [System.Windows.CornerRadius]::new(5)
    $b.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, 'Kbd.Bg')
    $b.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, 'Border')
    $b.BorderThickness = [System.Windows.Thickness]::new(1)
    $b.Padding = [System.Windows.Thickness]::new(7, 2, 7, 3)
    $b.Margin = [System.Windows.Thickness]::new(0, 0, 5, 0)
    $tb = New-DLauncherText -Text $Text -Size 11 -Brush 'Fg.1' -Wrap $false
    $tb.FontFamily = $Global:DLauncherStylesDict['Font.Mono']
    $b.Child = $tb
    return $b
}

function Global:Build-DLauncherHelpContent {
    param ([string]$Page)
    $panel = $ui.HelpContent
    $panel.Children.Clear()

    switch ($Page) {
        'faq' {
            $null = $panel.Children.Add((New-DLauncherText -Text (T "faq.intro") -Size 12.5 -Brush 'Fg.3' -Margin @(0, 0, 0, 18) -LineHeight 19))
            for ($i = 1; $i -le 30; $i++) {
                $q = Get-DLauncherTextOrNull -Key "faq.q$i"
                if ($null -eq $q) { break }
                $item = New-Object System.Windows.Controls.Border
                $item.CornerRadius = [System.Windows.CornerRadius]::new(10)
                $item.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, 'Subtle.Bg')
                $item.Padding = [System.Windows.Thickness]::new(16, 12, 16, 13)
                $item.Margin = [System.Windows.Thickness]::new(0, 0, 0, 8)
                $stack = New-Object System.Windows.Controls.StackPanel
                $null = $stack.Children.Add((New-DLauncherText -Text $q -Size 13 -Brush 'Fg.1' -Bold))
                $null = $stack.Children.Add((New-DLauncherText -Text (T "faq.a$i") -Size 12.5 -Brush 'Fg.2' -Margin @(0, 5, 0, 0) -LineHeight 19))
                $item.Child = $stack
                $null = $panel.Children.Add($item)
            }
        }
        'icons' {
            $null = $panel.Children.Add((New-DLauncherText -Text (T "icons.intro") -Size 12.5 -Brush 'Fg.3' -Margin @(0, 0, 0, 18) -LineHeight 19))
            $legend = @(
                @{ Icon = 'play';     Brush = 'Success';     Key = 'icons.play' }
                @{ Icon = 'edit';     Brush = 'Fg.2';        Key = 'icons.edit' }
                @{ Icon = 'more';     Brush = 'Fg.2';        Key = 'icons.more' }
                @{ Icon = 'tag';      Brush = 'Fg.2';        Key = 'icons.tag' }
                @{ Icon = 'grip';     Brush = 'Fg.2';        Key = 'icons.grip' }
                @{ Icon = 'checked';  Brush = 'Accent.Text'; Key = 'icons.check' }
                @{ Special = 'letter';                       Key = 'icons.letter' }
                @{ Icon = 'globe';    Brush = 'Accent.Text'; Key = 'icons.favicon' }
                @{ Icon = 'folder';   Brush = 'Accent.Text'; Key = 'icons.folder' }
                @{ Special = 'browser';                      Key = 'icons.browser' }
                @{ Special = 'dot';                          Key = 'icons.tagdot' }
                @{ Icon = 'sparkle';  Brush = 'Accent.Text'; Key = 'icons.sparkle' }
                @{ Icon = 'clock';    Brush = 'Fg.2';        Key = 'icons.clock' }
                @{ Icon = 'command';  Brush = 'Accent.Text'; Key = 'icons.command' }
                @{ Icon = 'sun';      Brush = 'Fg.2';        Key = 'icons.theme' }
                @{ Icon = 'sidebar';  Brush = 'Fg.2';        Key = 'icons.sidebar' }
                @{ Icon = 'warning';  Brush = 'Warning';     Key = 'icons.warning' }
                @{ Special = 'status';                       Key = 'icons.status' }
            )
            foreach ($l in $legend) {
                if ($l.Special -eq 'letter') {
                    $visual = New-Object System.Windows.Controls.Border
                    $visual.Width = 24; $visual.Height = 24
                    $visual.CornerRadius = [System.Windows.CornerRadius]::new(6)
                    $visual.Background = New-DLauncherBrush '#0070F3'
                    $letter = New-Object System.Windows.Controls.TextBlock
                    $letter.Text = 'A'; $letter.Foreground = [System.Windows.Media.Brushes]::White
                    $letter.FontWeight = [System.Windows.FontWeights]::SemiBold
                    $letter.HorizontalAlignment = 'Center'; $letter.VerticalAlignment = 'Center'
                    $visual.Child = $letter
                } elseif ($l.Special -eq 'browser') {
                    $visual = New-Object System.Windows.Controls.Border
                    $visual.CornerRadius = [System.Windows.CornerRadius]::new(5)
                    $visual.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, 'Orange.Soft')
                    $visual.Padding = [System.Windows.Thickness]::new(4, 1, 4, 2)
                    $visual.VerticalAlignment = 'Center'; $visual.HorizontalAlignment = 'Center'
                    $visual.Child = (New-DLauncherText -Text 'Edge' -Size 9.5 -Brush 'Orange.Text' -Wrap $false)
                } elseif ($l.Special -eq 'dot') {
                    $visual = New-Object System.Windows.Shapes.Ellipse
                    $visual.Width = 9; $visual.Height = 9
                    $visual.Fill = New-DLauncherBrush '#FF7A33'
                } elseif ($l.Special -eq 'status') {
                    $visual = New-Object System.Windows.Shapes.Ellipse
                    $visual.Width = 8; $visual.Height = 8
                    $visual.SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, 'Success')
                } else {
                    $visual = New-DLauncherIconPath -Name $l.Icon -Size 15 -BrushKey $l.Brush
                    if ($l.Icon -eq 'grip') { $visual.Width = 8 }
                    if ($l.Icon -eq 'more') { $visual.Height = 4 }
                }
                $null = $panel.Children.Add((New-DLauncherLegendRow -Visual $visual -Title (T "$($l.Key).t") -Desc (T "$($l.Key).d")))
            }
        }
        'keys' {
            $null = $panel.Children.Add((New-DLauncherText -Text (T "keys.intro") -Size 12.5 -Brush 'Fg.3' -Margin @(0, 0, 0, 18) -LineHeight 19))
            $shortcuts = @(
                @(@('Ctrl', 'K'), 'keys.palette'), @(@('Ctrl', 'F'), 'keys.search'), @(@([string][char]0x2191, [string][char]0x2193), 'keys.move'),
                @(@('Enter'), 'keys.open'), @(@('Ctrl', 'Enter'), 'keys.openSel'), @(@('Space'), 'keys.toggle'),
                @(@('Ctrl', 'N'), 'keys.add'), @(@('F2'), 'keys.edit'), @(@('Ctrl', 'D'), 'keys.duplicate'),
                @(@('Del'), 'keys.delete'), @(@('Ctrl', 'Z'), 'keys.undo'), @(@('Ctrl', 'B'), 'keys.sidebar'),
                @(@('Ctrl', ','), 'keys.settings'), @(@('F1'), 'keys.help'), @(@('Esc'), 'keys.esc'),
                @(@((T "keys.dblclick.k")), 'keys.dblclick'), @(@((T "keys.rightclick.k")), 'keys.rightclick'), @(@((T "keys.typing.k")), 'keys.typing')
            )
            foreach ($sc in $shortcuts) {
                $grid = New-Object System.Windows.Controls.Grid
                $grid.Margin = [System.Windows.Thickness]::new(0, 0, 0, 4)
                $grid.MinHeight = 32
                foreach ($w in '170', '*') {
                    $cd = New-Object System.Windows.Controls.ColumnDefinition
                    $cd.Width = [System.Windows.GridLengthConverter]::new().ConvertFromString($w)
                    $null = $grid.ColumnDefinitions.Add($cd)
                }
                $keysPanel = New-Object System.Windows.Controls.StackPanel
                $keysPanel.Orientation = 'Horizontal'
                $keysPanel.VerticalAlignment = 'Center'
                foreach ($k in $sc[0]) { $null = $keysPanel.Children.Add((New-DLauncherKbd -Text $k)) }
                $null = $grid.Children.Add($keysPanel)
                $desc = New-DLauncherText -Text (T $sc[1]) -Size 12.5 -Brush 'Fg.2'
                $desc.VerticalAlignment = 'Center'
                [System.Windows.Controls.Grid]::SetColumn($desc, 1)
                $null = $grid.Children.Add($desc)
                $null = $panel.Children.Add($grid)
                $line = New-Object System.Windows.Controls.Border
                $line.Height = 1
                $line.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, 'Divider')
                $line.Margin = [System.Windows.Thickness]::new(0, 0, 0, 4)
                $null = $panel.Children.Add($line)
            }
        }
        'about' {
            $head = New-Object System.Windows.Controls.StackPanel
            $head.Orientation = 'Horizontal'
            $head.Margin = [System.Windows.Thickness]::new(0, 4, 0, 18)
            $logoTile = New-Object System.Windows.Controls.Border
            $logoTile.Width = 64; $logoTile.Height = 64
            $logoTile.CornerRadius = [System.Windows.CornerRadius]::new(16)
            $logoTile.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, 'Subtle.Bg')
            $logoTile.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, 'Border')
            $logoTile.BorderThickness = [System.Windows.Thickness]::new(1)
            $logoTile.Child = New-DLauncherLogo -Size 34
            $null = $head.Children.Add($logoTile)
            $titles = New-Object System.Windows.Controls.StackPanel
            $titles.VerticalAlignment = 'Center'
            $titles.Margin = [System.Windows.Thickness]::new(16, 0, 0, 0)
            $null = $titles.Children.Add((New-DLauncherText -Text 'DLauncher' -Size 20 -Brush 'Fg.1' -Bold))
            $null = $titles.Children.Add((New-DLauncherText -Text (T "info.version" $Global:DLauncherVersion) -Size 12 -Brush 'Fg.3' -Margin @(0, 3, 0, 0)))
            $null = $head.Children.Add($titles)
            $null = $panel.Children.Add($head)
            Add-DLauncherRichText -Panel $panel -Text (T "about.body")
            $null = $panel.Children.Add((New-DLauncherText -Text $Global:DLauncherFootnote -Size 11.5 -Brush 'Fg.3' -Margin @(0, 10, 0, 0)))
        }
        default {
            # Textos legales: privacidad, advertencias, términos y exención de responsabilidad
            $null = $panel.Children.Add((New-DLauncherText -Text (T "legal.updated") -Size 11.5 -Brush 'Fg.3' -Margin @(0, 0, 0, 14)))
            Add-DLauncherRichText -Panel $panel -Text (T "legal.$Page")
        }
    }
}

$ui.BtnHelp.Add_Click({ Show-DLauncherHelp })
$ui.BtnCloseHelp.Add_Click({ Hide-DLauncherOverlay $ui.HelpOverlay })

# ===================== BIENVENIDA Y TÉRMINOS =====================

# Refleja idioma y tema actuales en los selectores de la bienvenida
function Global:Sync-DLauncherSetupChoices {
    $Global:DLauncherState.SuppressSetupEvents = $true
    try {
        $ui.SetupLangEs.IsChecked = ($Global:DLauncherLanguage -eq 'es')
        $ui.SetupLangEn.IsChecked = ($Global:DLauncherLanguage -eq 'en')
        $ui.SetupThemeDark.IsChecked = ($Global:DLauncherThemeName -eq 'dark')
        $ui.SetupThemeLight.IsChecked = ($Global:DLauncherThemeName -eq 'light')
    } finally {
        $Global:DLauncherState.SuppressSetupEvents = $false
    }
}

$ui.SetupLangEs.Add_Checked({ if (-not $Global:DLauncherState.SuppressSetupEvents) { Switch-DLauncherLanguage -Code 'es' } })
$ui.SetupLangEn.Add_Checked({ if (-not $Global:DLauncherState.SuppressSetupEvents) { Switch-DLauncherLanguage -Code 'en' } })
$ui.SetupThemeDark.Add_Checked({ if (-not $Global:DLauncherState.SuppressSetupEvents) { Set-DLauncherTheme -Mode 'dark' -Persist } })
$ui.SetupThemeLight.Add_Checked({ if (-not $Global:DLauncherState.SuppressSetupEvents) { Set-DLauncherTheme -Mode 'light' -Persist } })

$onAccept = { $ui.BtnInitialSelectFolder.IsEnabled = [bool]$ui.ChkAcceptTerms.IsChecked }
$ui.ChkAcceptTerms.Add_Checked($onAccept)
$ui.ChkAcceptTerms.Add_Unchecked($onAccept)

foreach ($pair in @(@('BtnSetupTerms', 'terms'), @('BtnSetupPrivacy', 'privacy'), @('BtnSetupWarnings', 'warnings'),
                    @('BtnTermsRead', 'terms'), @('BtnTermsPrivacy', 'privacy'), @('BtnTermsWarnings', 'warnings'))) {
    $ui[$pair[0]].Tag = $pair[1]
    $ui[$pair[0]].Add_Click({ param($s, $e) Show-DLauncherHelp -Page ([string]$s.Tag) })
}

$ui.BtnInitialSelectFolder.Add_Click({
    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderDialog.Description = T "folder.desc"
    $folderDialog.ShowNewFolderButton = $true
    if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK -and -not [string]::IsNullOrWhiteSpace($folderDialog.SelectedPath)) {
        $res = Set-DLauncherConfigFolder -FolderPath $folderDialog.SelectedPath
        Set-DLauncherPref -Name 'TermsAccepted' -Value $Global:DLauncherTermsVersion
        Hide-DLauncherOverlay $ui.SetupOverlay
        Update-UIList
        Update-DLauncherFilter -Animate
        if ($res.AlreadyExisted) {
            Show-DLauncherMessageBox -Title (T "folder.loadedTitle") -Message (T "setup.loadedBody") -OkText (T "common.continue")
        } else {
            # Configuración nueva: proponer las sugerencias para empezar rápido
            Show-DLauncherSuggestions
        }
    }
})

$ui.BtnTermsAccept.Add_Click({
    Set-DLauncherPref -Name 'TermsAccepted' -Value $Global:DLauncherTermsVersion
    Hide-DLauncherOverlay $ui.TermsOverlay
})
$ui.BtnTermsExit.Add_Click({ $ui.Window.Close() })

# ===================== IDIOMA =====================

function Global:Switch-DLauncherLanguage {
    param ([string]$Code)
    if ($Code -eq $Global:DLauncherLanguage) { return }
    Set-DLauncherLanguagePreference -Code $Code
    Update-DLauncherLanguage
}

# Aplica el idioma activo a toda la interfaz (en caliente)
function Global:Update-DLauncherLanguage {
    Update-DLauncherLocalizedTree -Root $ui.Window
    Update-DLauncherDate
    $ui.StatusThemeText.Text = T "theme.$($Global:DLauncherThemeMode)"
    Update-UIList
    if ($ui.SettingsOverlay.Visibility -eq [System.Windows.Visibility]::Visible) {
        Update-DLauncherSettingsValues
        Select-DLauncherSettingsPage -Page $Global:DLauncherState.SettingsPage
    }
    if ($ui.HelpOverlay.Visibility -eq [System.Windows.Visibility]::Visible) {
        Select-DLauncherHelpPage -Page $Global:DLauncherState.HelpPage
    }
    if ($ui.SuggestionsOverlay.Visibility -eq [System.Windows.Visibility]::Visible) {
        Update-DLauncherSuggestions
    }
    if ($ui.FormOverlay.Visibility -eq [System.Windows.Visibility]::Visible) {
        Update-DLauncherFormTargetState
    }
    Sync-DLauncherSetupChoices
}

$ui.BtnStatusLanguage.Add_Click({ Switch-DLauncherLanguage -Code $(if ($Global:DLauncherLanguage -eq 'es') { 'en' } else { 'es' }) })
$ui.BtnStatusTheme.Add_Click({ Show-DLauncherSettings -Page 'appearance' })

# ===================== VENTANA =====================

$ui.TitleBar.Add_MouseLeftButtonDown({
    try { $ui.Window.DragMove() } catch { }
})
$ui.BtnMinimize.Add_Click({ $ui.Window.WindowState = [System.Windows.WindowState]::Minimized })
$ui.BtnClose.Add_Click({ $ui.Window.Close() })
$ui.BtnSidebar.Add_Click({ Switch-DLauncherSidebar })
$ui.BtnTheme.Add_Click({ Switch-DLauncherThemeQuick })

$ui.Window.Add_Closing({
    if ($ui.Window.WindowState -eq [System.Windows.WindowState]::Normal) {
        Set-DLauncherPref -Name 'Window' -Value ([ordered]@{
            Left = [Math]::Round($ui.Window.Left); Top = [Math]::Round($ui.Window.Top)
            Width = [Math]::Round($ui.Window.ActualWidth); Height = [Math]::Round($ui.Window.ActualHeight)
        })
    }
    foreach ($t in $Global:DLauncherDateTimer, $Global:DLauncherActivateTimer, $Global:DLauncherLaunchTimer, $Global:DLauncherToastTimer) {
        if ($null -ne $t) { $t.Stop() }
    }
})

# La fecha se actualiza sola (por ejemplo, si la ventana sigue abierta pasada la medianoche)
$Global:DLauncherDateTimer = New-Object System.Windows.Threading.DispatcherTimer
$Global:DLauncherDateTimer.Interval = [TimeSpan]::FromSeconds(30)
$Global:DLauncherDateTimer.Add_Tick({ Update-DLauncherDate })
$Global:DLauncherDateTimer.Start()

# Otra ejecución pidió traer esta ventana al frente
$Global:DLauncherActivateTimer = New-Object System.Windows.Threading.DispatcherTimer
$Global:DLauncherActivateTimer.Interval = [TimeSpan]::FromMilliseconds(400)
$Global:DLauncherActivateTimer.Add_Tick({
    if ($Global:DLauncherActivateEvent.WaitOne(0)) {
        if ($ui.Window.WindowState -eq [System.Windows.WindowState]::Minimized) {
            $ui.Window.WindowState = [System.Windows.WindowState]::Normal
        }
        $ui.Window.Topmost = $true
        $null = $ui.Window.Activate()
        $ui.Window.Topmost = $false
    }
})
$Global:DLauncherActivateTimer.Start()

# ===================== ARRANQUE =====================

Set-DLauncherTheme -Mode ([string](Get-DLauncherPref -Name 'Theme' -Default 'dark'))
Initialize-DLauncherWindowBounds
Update-DLauncherSidebarVisibility
Update-DLauncherLanguage

if (-not (Test-DLauncherHasConfigFolder) -and -not $Global:DLauncherFolderMissing) {
    # Primer inicio: bienvenida con términos, idioma, tema y carpeta de configuración
    $ui.SetupOverlay.Visibility = [System.Windows.Visibility]::Visible
} elseif ([string](Get-DLauncherPref -Name 'TermsAccepted' -Default '') -ne $Global:DLauncherTermsVersion) {
    # Usuarios de versiones anteriores: aceptar una vez los términos y la privacidad
    $ui.TermsOverlay.Visibility = [System.Windows.Visibility]::Visible
}

$ui.Window.Add_Loaded({
    Update-DLauncherFilter -Animate
    Show-DLauncherConfigNotices
    $Global:DLauncherWatchTimer.Start()
})

[void]$ui.Window.ShowDialog()

try {
    $Global:DLauncherMutex.ReleaseMutex()
    $Global:DLauncherMutex.Dispose()
    $Global:DLauncherActivateEvent.Dispose()
} catch { }
