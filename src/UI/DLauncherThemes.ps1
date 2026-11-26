# DLauncher - Themes
# Paletas de color de los temas oscuro y claro. Toda la interfaz usa estas claves mediante
# DynamicResource, de modo que cambiar de tema solo sustituye este diccionario (en caliente).
# Valores "radial:#AARRGGBB" generan un degradado radial hacia transparente (luz ambiental).

$Global:DLauncherThemePalettes = @{
    dark = [ordered]@{
        'App.Bg'           = '#2D2D30'
        'Chrome.Bg'        = '#333337'
        'Panel.Bg'         = '#38383C'
        'Input.Bg'         = '#3A3A3F'
        'Subtle.Bg'        = '#3D3D42'
        'Hover.Bg'         = '#46464C'
        'Active.Bg'        = '#4A4A50'
        'Row.Hover'        = '#36363A'
        'Row.Cursor'       = '#2E0070F3'
        'Scrim'            = '#99141416'
        'Border'           = '#48484E'
        'Border.Strong'    = '#5A5A61'
        'Divider'          = '#404045'
        'Fg.1'             = '#F0F0F3'
        'Fg.2'             = '#B4B4BC'
        'Fg.3'             = '#9C9CA4'
        'Fg.4'             = '#7C7C84'
        'OnAccent'         = '#FFFFFF'
        'Accent'           = '#0070F3'
        'Accent.Hover'     = '#1F84FF'
        'Accent.Soft'      = '#260070F3'
        'Accent.Text'      = '#5AA9FF'
        'Orange'           = '#FF5500'
        'Orange.Soft'      = '#1FFF5500'
        'Orange.Text'      = '#FF8A4C'
        'Danger'           = '#FF453A'
        'Danger.Soft'      = '#24FF453A'
        'Success'          = '#30D158'
        'Success.Soft'     = '#2430D158'
        'Warning'          = '#FFB020'
        'Warning.Soft'     = '#1CFFB020'
        'Scroll.Thumb'     = '#5A5A61'
        'Scroll.ThumbHover'= '#6E6E76'
        'Favicon.Bg'       = '#F2F2F5'
        'Tile.Bg'          = '#424247'
        'Kbd.Bg'           = '#47474D'
        'Toast.Bg'         = '#F5505057'
        'Toast.Fg'         = '#F2F2F7'
        'Glow.A'           = 'radial:#1C0070F3'
        'Glow.B'           = 'radial:#12FF5500'
    }
    light = [ordered]@{
        'App.Bg'           = '#FFFFFF'
        'Chrome.Bg'        = '#F5F5F7'
        'Panel.Bg'         = '#FFFFFF'
        'Input.Bg'         = '#FFFFFF'
        'Subtle.Bg'        = '#F1F1F4'
        'Hover.Bg'         = '#EBEBEF'
        'Active.Bg'        = '#E5E5EA'
        'Row.Hover'        = '#F5F5F8'
        'Row.Cursor'       = '#120070F3'
        'Scrim'            = '#52101016'
        'Border'           = '#E4E4E9'
        'Border.Strong'    = '#D3D3DA'
        'Divider'          = '#EAEAEE'
        'Fg.1'             = '#17171A'
        'Fg.2'             = '#52525B'
        'Fg.3'             = '#74747E'
        'Fg.4'             = '#A5A5AF'
        'OnAccent'         = '#FFFFFF'
        'Accent'           = '#0070F3'
        'Accent.Hover'     = '#005FD1'
        'Accent.Soft'      = '#170070F3'
        'Accent.Text'      = '#005FCC'
        'Orange'           = '#FF5500'
        'Orange.Soft'      = '#17FF5500'
        'Orange.Text'      = '#C94400'
        'Danger'           = '#E0352B'
        'Danger.Soft'      = '#17E0352B'
        'Success'          = '#1E9E48'
        'Success.Soft'     = '#171E9E48'
        'Warning'          = '#A86F00'
        'Warning.Soft'     = '#1AD08A00'
        'Scroll.Thumb'     = '#D2D2D9'
        'Scroll.ThumbHover'= '#B4B4BE'
        'Favicon.Bg'       = '#F3F3F6'
        'Tile.Bg'          = '#F1F1F4'
        'Kbd.Bg'           = '#EEEEF2'
        'Toast.Bg'         = '#F51E1E23'
        'Toast.Fg'         = '#FFFFFF'
        'Glow.A'           = 'radial:#140070F3'
        'Glow.B'           = 'radial:#10FF5500'
    }
}

# Tema efectivo: "system" sigue el modo de aplicaciones de Windows
function Get-DLauncherEffectiveTheme {
    param ([string]$Mode)
    if ($Mode -eq 'light' -or $Mode -eq 'dark') { return $Mode }
    try {
        $v = Get-ItemPropertyValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'AppsUseLightTheme' -ErrorAction Stop
        if ($v -eq 1) { return 'light' }
    } catch { }
    return 'dark'
}

# Construye el diccionario de recursos (pinceles congelados) de un tema
function New-DLauncherThemeDictionary {
    param ([string]$Name)
    $palette = $Global:DLauncherThemePalettes[$Name]
    if ($null -eq $palette) { $palette = $Global:DLauncherThemePalettes['dark'] }
    $dict = [System.Windows.ResourceDictionary]::new()
    foreach ($key in $palette.Keys) {
        $value = [string]$palette[$key]
        if ($value.StartsWith('radial:')) {
            $color = [System.Windows.Media.ColorConverter]::ConvertFromString($value.Substring(7))
            $clear = [System.Windows.Media.Color]::FromArgb(0, $color.R, $color.G, $color.B)
            $brush = [System.Windows.Media.RadialGradientBrush]::new($color, $clear)
        } else {
            $brush = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.ColorConverter]::ConvertFromString($value))
        }
        $brush.Freeze()
        $dict[$key] = $brush
    }
    return $dict
}
