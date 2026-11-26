# DLauncher - UI Module
# Estructura visual (XAML) de DLauncher: ventana con barra de título, barra lateral, listado,
# barra de estado y paneles superpuestos. Los textos se traducen por x:Uid (ver Localization.ps1)
# y los colores se resuelven contra el tema activo (DynamicResource).

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# Iconos vectoriales (cuadrícula 24x24). Fill = relleno; si no, se dibujan con trazo
$Global:DLauncherIcons = @{
    search    = @{ Fill = $true;  D = 'M15.5,14h-0.79l-0.28-0.27C15.41,12.59,16,11.11,16,9.5C16,5.91,13.09,3,9.5,3S3,5.91,3,9.5S5.91,16,9.5,16c1.61,0,3.09-0.59,4.23-1.57l0.27,0.28v0.79l5,4.99L20.49,19L15.5,14z M9.5,14C7.01,14,5,11.99,5,9.5S7.01,5,9.5,5S14,7.01,14,9.5S11.99,14,9.5,14z' }
    plus      = @{ Fill = $false; D = 'M12,5 V19 M5,12 H19' }
    sidebar   = @{ Fill = $false; D = 'M3.5,4.5 H20.5 V19.5 H3.5 Z M9.5,4.5 V19.5' }
    help      = @{ Fill = $false; D = 'M12,21 A9,9 0 1 0 12,3 A9,9 0 1 0 12,21 Z M9.6,9.4 A2.5,2.5 0 1 1 13.4,11.5 C12.6,12 12,12.5 12,13.6 V14 M12,17.2 V17.4' }
    sliders   = @{ Fill = $false; D = 'M4,7 H13 M17,7 H20 M15,4.8 V9.2 M4,17 H7 M11,17 H20 M9,14.8 V19.2' }
    moon      = @{ Fill = $false; D = 'M20,14.5 A8,8 0 1 1 9.5,4 A6.5,6.5 0 0 0 20,14.5 Z' }
    sun       = @{ Fill = $false; D = 'M12,16 A4,4 0 1 0 12,8 A4,4 0 1 0 12,16 Z M12,2.5 V4.5 M12,19.5 V21.5 M2.5,12 H4.5 M19.5,12 H21.5 M5.3,5.3 L6.7,6.7 M17.3,17.3 L18.7,18.7 M5.3,18.7 L6.7,17.3 M17.3,6.7 L18.7,5.3' }
    grid      = @{ Fill = $false; D = 'M4.5,4.5 H10.5 V10.5 H4.5 Z M13.5,4.5 H19.5 V10.5 H13.5 Z M4.5,13.5 H10.5 V19.5 H4.5 Z M13.5,13.5 H19.5 V19.5 H13.5 Z' }
    checked   = @{ Fill = $false; D = 'M4.5,4.5 H19.5 V19.5 H4.5 Z M8.5,12.3 L11,14.8 L15.8,9.6' }
    sparkle   = @{ Fill = $false; D = 'M12,3.5 L13.7,9.3 L19.5,11 L13.7,12.7 L12,18.5 L10.3,12.7 L4.5,11 L10.3,9.3 Z M18.5,16 L19.1,17.9 L21,18.5 L19.1,19.1 L18.5,21 L17.9,19.1 L16,18.5 L17.9,17.9 Z' }
    tag       = @{ Fill = $true;  D = 'M21.41,11.58l-9-9C12.05,2.22,11.55,2,11,2H4C2.9,2,2,2.9,2,4v7c0,0.55,0.22,1.05,0.59,1.42l9,9C11.95,21.78,12.45,22,13,22s1.05-0.22,1.41-0.59l7-7C21.78,14.05,22,13.55,22,13S21.77,11.94,21.41,11.58z M5.5,7C4.67,7,4,6.33,4,5.5S4.67,4,5.5,4S7,4.67,7,5.5S6.33,7,5.5,7z' }
    play      = @{ Fill = $true;  D = 'M8,5 V19 L19,12 Z' }
    edit      = @{ Fill = $true;  D = 'M3,17.25V21h3.75L17.81,9.94l-3.75-3.75L3,17.25z M20.71,7.04c0.39-0.39,0.39-1.02,0-1.41l-2.34-2.34c-0.39-0.39-1.02-0.39-1.41,0l-1.83,1.83l3.75,3.75L20.71,7.04z' }
    more      = @{ Fill = $true;  D = 'M3.4,12 A1.6,1.6 0 1 0 6.6,12 A1.6,1.6 0 1 0 3.4,12 Z M10.4,12 A1.6,1.6 0 1 0 13.6,12 A1.6,1.6 0 1 0 10.4,12 Z M17.4,12 A1.6,1.6 0 1 0 20.6,12 A1.6,1.6 0 1 0 17.4,12 Z' }
    trash     = @{ Fill = $true;  D = 'M6,19c0,1.1,0.9,2,2,2h8c1.1,0,2-0.9,2-2V7H6V19z M19,4h-3.5l-1-1h-5l-1,1H5v2h14V4z' }
    folder    = @{ Fill = $true;  D = 'M20,6h-8l-2-2H4C2.9,4,2.01,4.9,2.01,6L2,18c0,1.1,0.9,2,2,2h16c1.1,0,2-0.9,2-2V8C22,6.9,21.1,6,20,6z' }
    clock     = @{ Fill = $false; D = 'M12,21 A9,9 0 1 0 12,3 A9,9 0 1 0 12,21 Z M12,7.5 V12 L15,14' }
    warning   = @{ Fill = $false; D = 'M12,3.5 L21.5,20 H2.5 Z M12,10 V14 M12,17 V17.2' }
    close     = @{ Fill = $false; D = 'M6,6 L18,18 M6,18 L18,6' }
    grip      = @{ Fill = $true;  D = 'M2,2 m-1.5,0 a1.5,1.5 0 1 0 3,0 a1.5,1.5 0 1 0 -3,0 M8,2 m-1.5,0 a1.5,1.5 0 1 0 3,0 a1.5,1.5 0 1 0 -3,0 M2,8 m-1.5,0 a1.5,1.5 0 1 0 3,0 a1.5,1.5 0 1 0 -3,0 M8,8 m-1.5,0 a1.5,1.5 0 1 0 3,0 a1.5,1.5 0 1 0 -3,0 M2,14 m-1.5,0 a1.5,1.5 0 1 0 3,0 a1.5,1.5 0 1 0 -3,0 M8,14 m-1.5,0 a1.5,1.5 0 1 0 3,0 a1.5,1.5 0 1 0 -3,0' }
    shield    = @{ Fill = $false; D = 'M12,3 L19,6 V11 C19,15.5 16,19 12,21 C8,19 5,15.5 5,11 V6 Z' }
    doc       = @{ Fill = $false; D = 'M6,3 H14 L19,8 V21 H6 Z M14,3 V8 H19 M9,13 H16 M9,17 H16' }
    info      = @{ Fill = $false; D = 'M12,21 A9,9 0 1 0 12,3 A9,9 0 1 0 12,21 Z M12,11 V16.5 M12,7.6 V7.8' }
    keyboard  = @{ Fill = $false; D = 'M3,6 H21 V18 H3 Z M7,10 H7.2 M11,10 H11.2 M15,10 H15.2 M8,14 H16' }
    command   = @{ Fill = $false; D = 'M5,7 L10,12 L5,17 M12,17 H19' }
    copy      = @{ Fill = $false; D = 'M9,9 H20 V20 H9 Z M5,15 H4 V4 H15 V5' }
    location  = @{ Fill = $false; D = 'M14,4 H20 V10 M20,4 L11,13 M18,14 V20 H4 V6 H10' }
    undo      = @{ Fill = $false; D = 'M9,14 L4,9 L9,4 M4,9 H14 A6,6 0 0 1 14,21 H11' }
    globe     = @{ Fill = $false; D = 'M12,21 A9,9 0 1 0 12,3 A9,9 0 1 0 12,21 Z M3,12 H21 M12,3 C9.5,6 9.5,18 12,21 M12,3 C14.5,6 14.5,18 12,21' }
    import    = @{ Fill = $false; D = 'M12,4 V15 M7,10 L12,15 L17,10 M5,20 H19' }
    export    = @{ Fill = $false; D = 'M12,15 V4 M7,9 L12,4 L17,9 M5,20 H19' }
    check     = @{ Fill = $false; D = 'M5,12.5 L10,17.5 L19,7' }
    hide      = @{ Fill = $false; D = 'M3,12 C5.5,7.5 8.5,5.5 12,5.5 C15.5,5.5 18.5,7.5 21,12 C18.5,16.5 15.5,18.5 12,18.5 C8.5,18.5 5.5,16.5 3,12 Z M4,20 L20,4' }
    logo      = @{ Fill = $true;  D = 'M 25,20 H 39 V 80 H 25 Z' }
}
$I = $Global:DLauncherIcons

# Logo vectorial reutilizable (barra azul + flecha naranja)
$Global:DLauncherLogoXaml = @"
<Canvas Width="100" Height="100">
    <Rectangle Canvas.Left="25" Canvas.Top="20" Width="14" Height="60" RadiusX="3" RadiusY="3" Fill="#0070F3"/>
    <Path Data="M 48,20 L 65,20 L 95,50 L 65,80 L 48,80 L 48,65 L 65,65 L 80,50 L 65,35 L 48,35 Z" Fill="#FF5500"/>
</Canvas>
"@
$L = $Global:DLauncherLogoXaml

$Global:MainWindowXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="DLauncher" Width="1060" Height="740" MinWidth="760" MinHeight="540"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent" ResizeMode="CanResize"
        WindowStartupLocation="Manual" AllowDrop="True" UseLayoutRounding="True"
        TextOptions.TextFormattingMode="Display" FontFamily="Segoe UI" FontSize="12.5"
        Foreground="{DynamicResource Fg.1}" x:Name="DLauncherWindow">

    <WindowChrome.WindowChrome>
        <WindowChrome CaptionHeight="0" ResizeBorderThickness="10" GlassFrameThickness="0" CornerRadius="0" UseAeroCaptionButtons="False"/>
    </WindowChrome.WindowChrome>

    <Grid>
        <!-- Sombra en capa propia (no se recalcula con el contenido) -->
        <Border x:Name="ShadowBorder" Margin="12" CornerRadius="12" Background="{DynamicResource App.Bg}" IsHitTestVisible="False">
            <Border.Effect>
                <DropShadowEffect BlurRadius="24" ShadowDepth="0" Opacity="0.55" Color="#000000"/>
            </Border.Effect>
        </Border>

        <Border x:Name="RootBorder" Margin="12" CornerRadius="12" BorderThickness="1" BorderBrush="{DynamicResource Border}" Background="{DynamicResource App.Bg}">
            <Grid x:Name="RootGrid">
                <Grid.RowDefinitions>
                    <RowDefinition Height="46"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="28"/>
                </Grid.RowDefinitions>

                <!-- ===================== BARRA DE TÍTULO ===================== -->
                <Grid x:Name="TitleBar" Grid.Row="0" Background="{DynamicResource Chrome.Bg}">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <Border Grid.ColumnSpan="3" Height="1" VerticalAlignment="Bottom" Background="{DynamicResource Divider}"/>

                    <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center" Margin="10,0,0,0">
                        <Button x:Name="BtnSidebar" x:Uid="hdr.sidebar" Style="{DynamicResource IconButton}">
                            <Path Data="$($I.sidebar.D)" Stroke="{DynamicResource Fg.2}" StrokeThickness="1.5" StrokeLineJoin="Round" Width="15" Height="14" Stretch="Fill"/>
                        </Button>
                        <Viewbox Width="28" Height="28" Margin="8,0,6,0">$L</Viewbox>
                        <TextBlock Text="DLauncher" FontSize="13" FontWeight="SemiBold" VerticalAlignment="Center"/>
                        <Border x:Name="ViewCrumb" Margin="10,0,0,0" VerticalAlignment="Center">
                            <TextBlock x:Name="ViewCrumbText" Text="" FontSize="12" Foreground="{DynamicResource Fg.3}"/>
                        </Border>
                    </StackPanel>

                    <!-- Búsqueda estilo "centro de comandos" -->
                    <Border Grid.Column="1" x:Name="SearchBorder" MaxWidth="460" MinWidth="200" Height="30" Margin="18,0" CornerRadius="8" BorderThickness="1" VerticalAlignment="Center">
                        <Border.Style>
                            <Style TargetType="Border">
                                <Setter Property="Background" Value="{DynamicResource Input.Bg}"/>
                                <Setter Property="BorderBrush" Value="{DynamicResource Border}"/>
                                <Style.Triggers>
                                    <Trigger Property="IsMouseOver" Value="True">
                                        <Setter Property="BorderBrush" Value="{DynamicResource Border.Strong}"/>
                                    </Trigger>
                                    <DataTrigger Binding="{Binding IsKeyboardFocused, ElementName=SearchBox}" Value="True">
                                        <Setter Property="BorderBrush" Value="{DynamicResource Accent}"/>
                                    </DataTrigger>
                                </Style.Triggers>
                            </Style>
                        </Border.Style>
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <Path Data="$($I.search.D)" Fill="{DynamicResource Fg.3}" Width="12" Height="12" Stretch="Uniform" Margin="11,0,7,0" VerticalAlignment="Center"/>
                            <TextBlock Grid.Column="1" x:Name="SearchPlaceholder" x:Uid="search.placeholder" Text="Search" Foreground="{DynamicResource Fg.3}" VerticalAlignment="Center" Margin="2,0,0,0" IsHitTestVisible="False" TextTrimming="CharacterEllipsis"/>
                            <TextBox Grid.Column="1" x:Name="SearchBox" Background="Transparent" BorderThickness="0" Padding="0" Height="28"/>
                            <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,5,0">
                                <Button x:Name="BtnClearSearch" x:Uid="search.clear" Style="{DynamicResource IconButton}" Width="22" Height="22" Visibility="Collapsed">
                                    <Path Data="$($I.close.D)" Stroke="{DynamicResource Fg.2}" StrokeThickness="1.6" Width="8" Height="8" Stretch="Fill"/>
                                </Button>
                                <Button x:Name="BtnPaletteHint" x:Uid="search.palette" Style="{DynamicResource IconButton}" Width="Auto" Height="22">
                                    <Border CornerRadius="4" Background="{DynamicResource Kbd.Bg}" Padding="6,1">
                                        <TextBlock Text="Ctrl K" FontSize="10.5" Foreground="{DynamicResource Fg.3}"/>
                                    </Border>
                                </Button>
                            </StackPanel>
                        </Grid>
                    </Border>

                    <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,7,0">
                        <Button x:Name="BtnTheme" x:Uid="hdr.theme" Style="{DynamicResource IconButton}">
                            <Path x:Name="ThemeIcon" Data="$($I.sun.D)" Stroke="{DynamicResource Fg.2}" StrokeThickness="1.5" StrokeLineJoin="Round" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Width="15" Height="15" Stretch="Uniform"/>
                        </Button>
                        <Button x:Name="BtnHelp" x:Uid="hdr.help" Style="{DynamicResource IconButton}">
                            <Path Data="$($I.help.D)" Stroke="{DynamicResource Fg.2}" StrokeThickness="1.5" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Width="15" Height="15" Stretch="Uniform"/>
                        </Button>
                        <Button x:Name="BtnSettings" x:Uid="hdr.settings" Style="{DynamicResource IconButton}">
                            <Path Data="$($I.sliders.D)" Stroke="{DynamicResource Fg.2}" StrokeThickness="1.5" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Width="15" Height="14" Stretch="Uniform"/>
                        </Button>
                        <Border Width="1" Height="16" Background="{DynamicResource Divider}" Margin="7,0"/>
                        <Button x:Name="BtnMinimize" x:Uid="hdr.min" Style="{DynamicResource WinButton}"/>
                        <Button x:Name="BtnClose" x:Uid="hdr.close" Style="{DynamicResource WinCloseButton}"/>
                    </StackPanel>
                </Grid>

                <!-- ===================== CUERPO ===================== -->
                <Grid Grid.Row="1">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition x:Name="SidebarColumn" Width="236"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>

                    <!-- Barra lateral -->
                    <Grid x:Name="Sidebar" Grid.Column="0" Background="{DynamicResource Chrome.Bg}">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>
                        <Border Grid.RowSpan="3" Width="1" HorizontalAlignment="Right" Background="{DynamicResource Divider}"/>

                        <Button Grid.Row="0" x:Name="BtnAddPlatform" x:Uid="add" Style="{DynamicResource PrimaryButton}" Margin="14,14,15,6" HorizontalAlignment="Stretch">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                <Path Data="$($I.plus.D)" Stroke="{DynamicResource OnAccent}" StrokeThickness="2" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Width="11" Height="11" Stretch="Fill" Margin="0,0,8,0" VerticalAlignment="Center"/>
                                <TextBlock Grid.Column="1" x:Uid="add.label" Text="Add tool" VerticalAlignment="Center"/>
                            </Grid>
                        </Button>

                        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" Margin="0,0,1,0">
                            <StackPanel Margin="0,8,0,10">
                                <TextBlock x:Uid="side.library" Text="LIBRARY" Style="{DynamicResource Text.Section}" Margin="22,6,0,6"/>
                                <StackPanel x:Name="LibraryList"/>
                                <Grid Margin="22,18,12,4">
                                    <TextBlock x:Uid="side.tags" Text="TAGS" Style="{DynamicResource Text.Section}" VerticalAlignment="Center"/>
                                    <Button x:Name="BtnNewTag" x:Uid="side.newTag" Style="{DynamicResource IconButton}" Width="22" Height="22" HorizontalAlignment="Right">
                                        <Path Data="$($I.plus.D)" Stroke="{DynamicResource Fg.2}" StrokeThickness="1.6" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Width="10" Height="10" Stretch="Fill"/>
                                    </Button>
                                </Grid>
                                <StackPanel x:Name="TagList"/>
                                <TextBlock x:Name="TagsEmptyText" x:Uid="side.tagsEmpty" Text="" FontSize="11" Foreground="{DynamicResource Fg.4}" TextWrapping="Wrap" Margin="22,4,16,0" LineHeight="16"/>
                            </StackPanel>
                        </ScrollViewer>

                        <StackPanel Grid.Row="2" Margin="0,0,1,10">
                            <Border Height="1" Background="{DynamicResource Divider}" Margin="14,0,14,8"/>
                            <StackPanel x:Name="UtilityList"/>
                        </StackPanel>
                    </Grid>

                    <!-- Área principal -->
                    <Grid Grid.Column="1" x:Name="MainArea" ClipToBounds="True">
                        <Ellipse Width="680" Height="680" Margin="0,-420,-280,0" HorizontalAlignment="Right" VerticalAlignment="Top" Fill="{DynamicResource Glow.A}" IsHitTestVisible="False"/>
                        <Ellipse Width="560" Height="560" Margin="-300,0,0,-340" HorizontalAlignment="Left" VerticalAlignment="Bottom" Fill="{DynamicResource Glow.B}" IsHitTestVisible="False"/>

                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                                <RowDefinition Height="Auto"/>
                            </Grid.RowDefinitions>

                            <!-- Cabecera de la vista -->
                            <Grid Grid.Row="0" Margin="34,26,30,10">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <TextBlock x:Name="DateText" Text="" FontSize="12" Foreground="{DynamicResource Fg.3}"/>
                                    <StackPanel Orientation="Horizontal" Margin="0,5,0,0">
                                        <Ellipse x:Name="ViewDot" Width="9" Height="9" Margin="1,4,11,0" VerticalAlignment="Center" Visibility="Collapsed"/>
                                        <TextBlock x:Name="ViewTitle" Text="" FontSize="24" FontWeight="SemiBold" TextTrimming="CharacterEllipsis"/>
                                    </StackPanel>
                                    <TextBlock x:Name="ViewSubtitle" Text="" FontSize="12" Foreground="{DynamicResource Fg.3}" Margin="0,5,0,0"/>
                                </StackPanel>
                                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Bottom">
                                    <Button x:Name="BtnAddHeader" x:Uid="add.header" Style="{DynamicResource SecondaryButton}" Height="30" Margin="0,0,6,0" Visibility="Collapsed">
                                        <StackPanel Orientation="Horizontal">
                                            <Path Data="$($I.plus.D)" Stroke="{DynamicResource Fg.1}" StrokeThickness="1.8" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Width="10" Height="10" Stretch="Fill" Margin="0,0,7,0" VerticalAlignment="Center"/>
                                            <TextBlock x:Uid="add.short" Text="Add" VerticalAlignment="Center"/>
                                        </StackPanel>
                                    </Button>
                                    <Button x:Name="BtnToggleAll" x:Uid="toggleAll" Style="{DynamicResource GhostButton}">
                                        <TextBlock x:Name="ToggleAllText" Text=""/>
                                    </Button>
                                </StackPanel>
                            </Grid>

                            <!-- Listado -->
                            <Grid Grid.Row="1" Margin="22,4,22,0">
                                <ScrollViewer x:Name="ListScroll" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                                    <StackPanel x:Name="ListPanel" Margin="0,0,6,10" Background="Transparent"/>
                                </ScrollViewer>

                                <StackPanel x:Name="NoResultsPanel" Visibility="Collapsed" VerticalAlignment="Center" HorizontalAlignment="Center" IsHitTestVisible="False" Margin="0,0,0,40">
                                    <Path Data="$($I.search.D)" Fill="{DynamicResource Fg.4}" Width="26" Height="26" Stretch="Uniform" Margin="0,0,0,14"/>
                                    <TextBlock x:Name="NoResultsTitle" Text="" FontSize="14" FontWeight="SemiBold" HorizontalAlignment="Center"/>
                                    <TextBlock x:Name="NoResultsText" Text="" Foreground="{DynamicResource Fg.3}" HorizontalAlignment="Center" TextAlignment="Center" TextWrapping="Wrap" MaxWidth="380" Margin="0,6,0,0"/>
                                </StackPanel>

                                <!-- Bienvenida / lista vacía -->
                                <StackPanel x:Name="EmptyStatePanel" Visibility="Collapsed" VerticalAlignment="Center" HorizontalAlignment="Center" Margin="20,0,20,40">
                                    <Border Width="68" Height="68" CornerRadius="18" Background="{DynamicResource Subtle.Bg}" BorderBrush="{DynamicResource Border}" BorderThickness="1" Margin="0,0,0,20">
                                        <Viewbox Width="32" Height="32">$L</Viewbox>
                                    </Border>
                                    <TextBlock x:Uid="empty.title" Text="Welcome" FontSize="19" FontWeight="SemiBold" HorizontalAlignment="Center"/>
                                    <TextBlock x:Uid="empty.body" Text="" Foreground="{DynamicResource Fg.2}" TextWrapping="Wrap" TextAlignment="Center" Margin="0,8,0,22" LineHeight="19" MaxWidth="420"/>
                                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                                        <Button x:Name="BtnCtaSuggestions" Style="{DynamicResource PrimaryButton}" Margin="0,0,8,0">
                                            <StackPanel Orientation="Horizontal">
                                                <Path Data="$($I.sparkle.D)" Stroke="{DynamicResource OnAccent}" StrokeThickness="1.5" StrokeLineJoin="Round" Width="13" Height="13" Stretch="Uniform" Margin="0,0,8,0" VerticalAlignment="Center"/>
                                                <TextBlock x:Uid="empty.ctaSuggestions" Text="Browse suggestions" VerticalAlignment="Center"/>
                                            </StackPanel>
                                        </Button>
                                        <Button x:Name="BtnCtaConfigure" x:Uid="empty.cta" Style="{DynamicResource SecondaryButton}" Content="Add tool"/>
                                    </StackPanel>
                                    <TextBlock x:Uid="empty.hint" Text="" FontSize="11" Foreground="{DynamicResource Fg.4}" HorizontalAlignment="Center" Margin="0,18,0,0"/>
                                </StackPanel>
                            </Grid>

                            <!-- Barra de acciones -->
                            <Grid Grid.Row="2" Margin="22,6,22,16">
                                <Border Background="{DynamicResource Panel.Bg}" BorderBrush="{DynamicResource Border}" BorderThickness="1" CornerRadius="12" Opacity="0.96"/>
                                <Grid Margin="16,9,9,9">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="Auto"/>
                                        <ColumnDefinition Width="Auto"/>
                                    </Grid.ColumnDefinitions>
                                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                                        <TextBlock x:Name="StatusText" Text="" Foreground="{DynamicResource Fg.2}" VerticalAlignment="Center"/>
                                    </StackPanel>
                                    <Button Grid.Column="1" x:Name="BtnDelay" x:Uid="delay.button" Style="{DynamicResource GhostButton}" Foreground="{DynamicResource Fg.3}" Margin="0,0,8,0">
                                        <StackPanel Orientation="Horizontal">
                                            <Path Data="$($I.clock.D)" Stroke="{DynamicResource Fg.3}" StrokeThickness="1.5" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Width="13" Height="13" Stretch="Uniform" Margin="0,0,7,0" VerticalAlignment="Center"/>
                                            <TextBlock x:Name="DelayText" Text="" VerticalAlignment="Center"/>
                                        </StackPanel>
                                    </Button>
                                    <Grid Grid.Column="2">
                                        <Button x:Name="BtnOpenAll" x:Uid="openAll" Style="{DynamicResource PrimaryButton}" MinWidth="168" Height="36">
                                            <StackPanel Orientation="Horizontal">
                                                <Path Data="$($I.play.D)" Fill="{DynamicResource OnAccent}" Width="9" Height="11" Stretch="Fill" Margin="0,0,9,0" VerticalAlignment="Center"/>
                                                <TextBlock x:Name="OpenAllText" Text="" VerticalAlignment="Center"/>
                                            </StackPanel>
                                        </Button>
                                        <Border x:Name="LaunchProgress" Height="2" CornerRadius="1" Background="{DynamicResource OnAccent}" Opacity="0" Width="0"
                                                HorizontalAlignment="Left" VerticalAlignment="Bottom" Margin="8,0,8,4" IsHitTestVisible="False"/>
                                    </Grid>
                                </Grid>
                            </Grid>
                        </Grid>
                    </Grid>
                </Grid>

                <!-- ===================== BARRA DE ESTADO ===================== -->
                <Grid x:Name="StatusBar" Grid.Row="2" Background="{DynamicResource Chrome.Bg}">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <Border Grid.ColumnSpan="2" Height="1" VerticalAlignment="Top" Background="{DynamicResource Divider}"/>
                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="12,0,0,0">
                        <Ellipse x:Name="StatusDot" Width="7" Height="7" Fill="{DynamicResource Success}" Margin="0,0,7,0" VerticalAlignment="Center"/>
                        <TextBlock x:Name="StatusBarText" Text="" FontSize="11" Foreground="{DynamicResource Fg.3}" VerticalAlignment="Center"/>
                        <Button x:Name="BtnStatusFolder" x:Uid="status.folder" Style="{DynamicResource StatusButton}" Margin="10,0,0,0">
                            <StackPanel Orientation="Horizontal">
                                <Path Data="$($I.folder.D)" Fill="{DynamicResource Fg.4}" Width="11" Height="9" Stretch="Fill" Margin="0,0,6,0" VerticalAlignment="Center"/>
                                <TextBlock x:Name="StatusFolderText" Text="" MaxWidth="340" TextTrimming="CharacterEllipsis" VerticalAlignment="Center"/>
                            </StackPanel>
                        </Button>
                    </StackPanel>
                    <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,10,0">
                        <Button x:Name="BtnStatusLanguage" x:Uid="status.language" Style="{DynamicResource StatusButton}">
                            <TextBlock x:Name="StatusLanguageText" Text="ES"/>
                        </Button>
                        <Button x:Name="BtnStatusTheme" x:Uid="status.theme" Style="{DynamicResource StatusButton}">
                            <TextBlock x:Name="StatusThemeText" Text=""/>
                        </Button>
                        <Border Width="1" Height="12" Background="{DynamicResource Divider}" Margin="6,0"/>
                        <TextBlock x:Name="FooterText" Text="" FontSize="11" Foreground="{DynamicResource Fg.4}" VerticalAlignment="Center" Margin="4,0,8,0"/>
                        <TextBlock x:Name="StatusVersionText" Text="" FontSize="11" Foreground="{DynamicResource Fg.4}" VerticalAlignment="Center"/>
                    </StackPanel>
                </Grid>

                <!-- ===================== PANELES SUPERPUESTOS ===================== -->
                <!-- Orden de apilado: los últimos quedan por encima -->

                <!-- Bienvenida (primer inicio): términos, idioma, tema y carpeta de configuración -->
                <Grid x:Name="SetupOverlay" Grid.Row="1" Grid.RowSpan="2" Visibility="Collapsed" Background="{DynamicResource App.Bg}">
                    <Ellipse Width="760" Height="760" Margin="0,-460,-300,0" HorizontalAlignment="Right" VerticalAlignment="Top" Fill="{DynamicResource Glow.A}" IsHitTestVisible="False"/>
                    <Ellipse Width="620" Height="620" Margin="-320,0,0,-380" HorizontalAlignment="Left" VerticalAlignment="Bottom" Fill="{DynamicResource Glow.B}" IsHitTestVisible="False"/>
                    <Grid Width="480" HorizontalAlignment="Center" VerticalAlignment="Center">
                        <Border Style="{DynamicResource CardShadow}"/>
                        <Border Style="{DynamicResource Card}" Padding="30,28">
                            <StackPanel>
                                <Viewbox Width="40" Height="40" HorizontalAlignment="Left" Margin="-4,0,0,14">$L</Viewbox>
                                <TextBlock x:Uid="setup.title" Text="Welcome" FontSize="21" FontWeight="SemiBold"/>
                                <TextBlock x:Uid="setup.body" Text="" Style="{DynamicResource Text.Desc}" FontSize="12.5" LineHeight="19" Foreground="{DynamicResource Fg.2}" Margin="0,8,0,20"/>

                                <Grid Margin="0,0,0,18">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="14"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <StackPanel>
                                        <TextBlock x:Uid="setup.language" Text="Language" Style="{DynamicResource Text.Label}"/>
                                        <Border CornerRadius="9" Background="{DynamicResource Subtle.Bg}" BorderBrush="{DynamicResource Border}" BorderThickness="1">
                                            <UniformGrid Columns="2">
                                                <RadioButton x:Name="SetupLangEs" GroupName="SetupLang" Style="{DynamicResource Segment}" Content="Español"/>
                                                <RadioButton x:Name="SetupLangEn" GroupName="SetupLang" Style="{DynamicResource Segment}" Content="English"/>
                                            </UniformGrid>
                                        </Border>
                                    </StackPanel>
                                    <StackPanel Grid.Column="2">
                                        <TextBlock x:Uid="setup.theme" Text="Theme" Style="{DynamicResource Text.Label}"/>
                                        <Border CornerRadius="9" Background="{DynamicResource Subtle.Bg}" BorderBrush="{DynamicResource Border}" BorderThickness="1">
                                            <UniformGrid Columns="2">
                                                <RadioButton x:Name="SetupThemeDark" x:Uid="theme.dark" GroupName="SetupTheme" Style="{DynamicResource Segment}" Content="Dark"/>
                                                <RadioButton x:Name="SetupThemeLight" x:Uid="theme.light" GroupName="SetupTheme" Style="{DynamicResource Segment}" Content="Light"/>
                                            </UniformGrid>
                                        </Border>
                                    </StackPanel>
                                </Grid>

                                <Border CornerRadius="10" Background="{DynamicResource Subtle.Bg}" Padding="14,12" Margin="0,0,0,16">
                                    <Grid>
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="Auto"/>
                                            <ColumnDefinition Width="*"/>
                                        </Grid.ColumnDefinitions>
                                        <Path Data="$($I.folder.D)" Fill="{DynamicResource Accent.Text}" Width="16" Height="13" Stretch="Fill" VerticalAlignment="Top" Margin="0,2,12,0"/>
                                        <TextBlock Grid.Column="1" x:Uid="setup.folderInfo" Text="" Style="{DynamicResource Text.Desc}" Foreground="{DynamicResource Fg.2}"/>
                                    </Grid>
                                </Border>

                                <CheckBox x:Name="ChkAcceptTerms">
                                    <TextBlock x:Uid="setup.accept" Text="" TextWrapping="Wrap" FontSize="12" Foreground="{DynamicResource Fg.2}"/>
                                </CheckBox>
                                <StackPanel Orientation="Horizontal" Margin="16,6,0,0">
                                    <Button x:Name="BtnSetupTerms" x:Uid="setup.readTerms" Style="{DynamicResource GhostButton}" Content="Terms of use"/>
                                    <Button x:Name="BtnSetupPrivacy" x:Uid="setup.readPrivacy" Style="{DynamicResource GhostButton}" Content="Privacy"/>
                                    <Button x:Name="BtnSetupWarnings" x:Uid="setup.readWarnings" Style="{DynamicResource GhostButton}" Content="Warnings"/>
                                </StackPanel>

                                <Button x:Name="BtnInitialSelectFolder" Style="{DynamicResource PrimaryButton}" Height="40" Margin="0,22,0,0" IsEnabled="False">
                                    <StackPanel Orientation="Horizontal">
                                        <Path Data="$($I.folder.D)" Fill="{DynamicResource OnAccent}" Width="14" Height="12" Stretch="Fill" Margin="0,0,9,0" VerticalAlignment="Center"/>
                                        <TextBlock x:Uid="setup.select" Text="Choose folder" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Button>
                            </StackPanel>
                        </Border>
                    </Grid>
                </Grid>

                <!-- Términos actualizados (usuarios de versiones anteriores) -->
                <Grid x:Name="TermsOverlay" Grid.Row="1" Grid.RowSpan="2" Visibility="Collapsed" Background="{DynamicResource Scrim}">
                    <Grid Width="460" HorizontalAlignment="Center" VerticalAlignment="Center">
                        <Border Style="{DynamicResource CardShadow}"/>
                        <Border Style="{DynamicResource Card}" Padding="26,24">
                            <StackPanel>
                                <Border Width="38" Height="38" CornerRadius="10" Background="{DynamicResource Accent.Soft}" HorizontalAlignment="Left" Margin="0,0,0,14">
                                    <Path Data="$($I.shield.D)" Stroke="{DynamicResource Accent.Text}" StrokeThickness="1.6" StrokeLineJoin="Round" Width="16" Height="17" Stretch="Uniform"/>
                                </Border>
                                <TextBlock x:Uid="terms.title" Text="" Style="{DynamicResource Text.Title}" FontSize="17"/>
                                <TextBlock x:Uid="terms.body" Text="" Style="{DynamicResource Text.Desc}" FontSize="12.5" LineHeight="19" Foreground="{DynamicResource Fg.2}" Margin="0,8,0,10"/>
                                <StackPanel Orientation="Horizontal" Margin="-10,0,0,0">
                                    <Button x:Name="BtnTermsRead" x:Uid="setup.readTerms" Style="{DynamicResource GhostButton}" Content="Terms"/>
                                    <Button x:Name="BtnTermsPrivacy" x:Uid="setup.readPrivacy" Style="{DynamicResource GhostButton}" Content="Privacy"/>
                                    <Button x:Name="BtnTermsWarnings" x:Uid="setup.readWarnings" Style="{DynamicResource GhostButton}" Content="Warnings"/>
                                </StackPanel>
                                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,22,0,0">
                                    <Button x:Name="BtnTermsExit" x:Uid="terms.exit" Style="{DynamicResource SecondaryButton}" MinWidth="96" Margin="0,0,8,0" Content="Exit"/>
                                    <Button x:Name="BtnTermsAccept" x:Uid="terms.accept" Style="{DynamicResource PrimaryButton}" MinWidth="120" Content="Accept"/>
                                </StackPanel>
                            </StackPanel>
                        </Border>
                    </Grid>
                </Grid>

                <!-- Agregar / editar herramienta -->
                <Grid x:Name="FormOverlay" Grid.Row="1" Grid.RowSpan="2" Visibility="Collapsed" Background="{DynamicResource Scrim}">
                    <Grid Width="500" HorizontalAlignment="Center" VerticalAlignment="Center">
                        <Border Style="{DynamicResource CardShadow}"/>
                        <Border Style="{DynamicResource Card}" Padding="24,22">
                            <StackPanel>
                                <TextBlock x:Name="FormTitleText" Text="" Style="{DynamicResource Text.Title}" Margin="0,0,0,18"/>

                                <TextBlock x:Uid="form.name" Text="Name" Style="{DynamicResource Text.Label}"/>
                                <TextBox x:Name="TxtPlatformName" Margin="0,0,0,14"/>

                                <TextBlock x:Uid="form.url" Text="Target" Style="{DynamicResource Text.Label}"/>
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="Auto"/>
                                    </Grid.ColumnDefinitions>
                                    <TextBox x:Name="TxtPlatformUrl" FontFamily="{DynamicResource Font.Mono}" FontSize="12"/>
                                    <Button Grid.Column="1" x:Name="BtnBrowseFile" x:Uid="form.browse" Style="{DynamicResource SecondaryButton}" Width="38" Padding="0" Margin="6,0,0,0">
                                        <Path Data="$($I.folder.D)" Fill="{DynamicResource Accent.Text}" Width="14" Height="12" Stretch="Fill"/>
                                    </Button>
                                </Grid>
                                <StackPanel Orientation="Horizontal" Margin="1,7,0,0">
                                    <Ellipse x:Name="FormKindDot" Width="6" Height="6" Margin="0,0,7,0" VerticalAlignment="Center" Fill="{DynamicResource Fg.4}"/>
                                    <TextBlock x:Name="FormKindText" Text="" FontSize="11" Foreground="{DynamicResource Fg.3}" TextTrimming="CharacterEllipsis" MaxWidth="430"/>
                                </StackPanel>

                                <Border x:Name="FormWarning" Visibility="Collapsed" CornerRadius="9" Background="{DynamicResource Warning.Soft}" Padding="12,9" Margin="0,12,0,0">
                                    <Grid>
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="Auto"/>
                                            <ColumnDefinition Width="*"/>
                                        </Grid.ColumnDefinitions>
                                        <Path Data="$($I.warning.D)" Stroke="{DynamicResource Warning}" StrokeThickness="1.6" StrokeLineJoin="Round" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Width="15" Height="14" Stretch="Uniform" VerticalAlignment="Top" Margin="0,1,10,0"/>
                                        <TextBlock Grid.Column="1" x:Name="FormWarningText" Text="" FontSize="11.5" TextWrapping="Wrap" Foreground="{DynamicResource Fg.1}" LineHeight="17"/>
                                    </Grid>
                                </Border>

                                <TextBlock x:Uid="form.tags" Text="Tags" Style="{DynamicResource Text.Label}" Margin="0,16,0,7"/>
                                <WrapPanel x:Name="FormTagPanel"/>

                                <Grid x:Name="BrowserPanel" Margin="0,10,0,0">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="12"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <StackPanel Grid.Column="0">
                                        <TextBlock x:Uid="form.browser" Text="Browser" Style="{DynamicResource Text.Label}"/>
                                        <ComboBox x:Name="CmbBrowser"/>
                                    </StackPanel>
                                    <StackPanel Grid.Column="2" x:Name="ProfilePanel">
                                        <TextBlock x:Uid="form.profile" Text="Profile" Style="{DynamicResource Text.Label}"/>
                                        <ComboBox x:Name="CmbProfile"/>
                                    </StackPanel>
                                </Grid>

                                <CheckBox x:Name="ChkDefaultChecked" x:Uid="form.defaultChecked" Content="" Margin="0,18,0,0"/>

                                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,24,0,0">
                                    <Button x:Name="BtnCancelPlatform" x:Uid="common.cancel" Style="{DynamicResource SecondaryButton}" MinWidth="96" Margin="0,0,8,0" Content="Cancel"/>
                                    <Button x:Name="BtnSavePlatform" x:Uid="common.save" Style="{DynamicResource PrimaryButton}" MinWidth="104" Content="Save"/>
                                </StackPanel>
                            </StackPanel>
                        </Border>
                    </Grid>
                </Grid>

                <!-- Crear / renombrar etiqueta -->
                <Grid x:Name="GroupOverlay" Grid.Row="1" Grid.RowSpan="2" Visibility="Collapsed" Background="{DynamicResource Scrim}">
                    <Grid Width="390" HorizontalAlignment="Center" VerticalAlignment="Center">
                        <Border Style="{DynamicResource CardShadow}"/>
                        <Border Style="{DynamicResource Card}" Padding="24,22">
                            <StackPanel>
                                <TextBlock x:Name="GroupFormTitle" Text="" Style="{DynamicResource Text.Title}"/>
                                <TextBlock x:Uid="group.desc" Text="" Style="{DynamicResource Text.Desc}" Margin="0,6,0,16"/>
                                <TextBlock x:Uid="group.name" Text="Name" Style="{DynamicResource Text.Label}"/>
                                <TextBox x:Name="TxtGroupName"/>
                                <Grid Margin="0,22,0,0">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="Auto"/>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="Auto"/>
                                    </Grid.ColumnDefinitions>
                                    <Button x:Name="BtnDeleteGroup" x:Uid="group.delete" Style="{DynamicResource DangerGhostButton}" Content="Delete" Margin="-10,0,0,0"/>
                                    <StackPanel Grid.Column="2" Orientation="Horizontal">
                                        <Button x:Name="BtnCancelGroup" x:Uid="common.cancel" Style="{DynamicResource SecondaryButton}" MinWidth="90" Margin="0,0,8,0" Content="Cancel"/>
                                        <Button x:Name="BtnSaveGroup" x:Uid="common.save" Style="{DynamicResource PrimaryButton}" MinWidth="90" Content="Save"/>
                                    </StackPanel>
                                </Grid>
                            </StackPanel>
                        </Border>
                    </Grid>
                </Grid>

                <!-- Sugerencias -->
                <Grid x:Name="SuggestionsOverlay" Grid.Row="1" Grid.RowSpan="2" Visibility="Collapsed" Background="{DynamicResource Scrim}">
                    <Grid MaxWidth="780" MaxHeight="600" Margin="24" VerticalAlignment="Center">
                        <Border Style="{DynamicResource CardShadow}"/>
                        <Border Style="{DynamicResource Card}">
                            <Grid>
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="*"/>
                                    <RowDefinition Height="Auto"/>
                                </Grid.RowDefinitions>
                                <Grid Margin="26,22,16,12">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="Auto"/>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="Auto"/>
                                    </Grid.ColumnDefinitions>
                                    <Border Width="38" Height="38" CornerRadius="10" Background="{DynamicResource Accent.Soft}" Margin="0,0,14,0" VerticalAlignment="Top">
                                        <Path Data="$($I.sparkle.D)" Stroke="{DynamicResource Accent.Text}" StrokeThickness="1.5" StrokeLineJoin="Round" Width="18" Height="18" Stretch="Uniform"/>
                                    </Border>
                                    <StackPanel Grid.Column="1">
                                        <TextBlock x:Uid="sugg.title" Text="Suggestions" Style="{DynamicResource Text.Title}" FontSize="17"/>
                                        <TextBlock x:Uid="sugg.desc" Text="" Style="{DynamicResource Text.Desc}" Margin="0,4,0,0"/>
                                    </StackPanel>
                                    <Button Grid.Column="2" x:Name="BtnCloseSuggestions" x:Uid="close" Style="{DynamicResource IconButton}" VerticalAlignment="Top">
                                        <Path Data="$($I.close.D)" Stroke="{DynamicResource Fg.2}" StrokeThickness="1.6" Width="10" Height="10" Stretch="Fill"/>
                                    </Button>
                                </Grid>
                                <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Margin="0,0,6,0">
                                    <StackPanel x:Name="SuggestionsPanel" Margin="26,0,18,10"/>
                                </ScrollViewer>
                                <Grid Grid.Row="2" Margin="26,10,22,18">
                                    <Border Height="1" VerticalAlignment="Top" Background="{DynamicResource Divider}" Margin="0,-10,0,0"/>
                                    <TextBlock x:Name="SuggestionsFooterText" Text="" Style="{DynamicResource Text.Desc}" VerticalAlignment="Center" Margin="0,0,200,0"/>
                                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                                        <Button x:Name="BtnRestoreSuggestions" Style="{DynamicResource GhostButton}" Margin="0,0,8,0">
                                            <TextBlock x:Name="RestoreSuggestionsText" Text=""/>
                                        </Button>
                                        <Button x:Name="BtnDoneSuggestions" x:Uid="common.done" Style="{DynamicResource PrimaryButton}" MinWidth="96" Content="Done"/>
                                    </StackPanel>
                                </Grid>
                            </Grid>
                        </Border>
                    </Grid>
                </Grid>

                <!-- Ajustes -->
                <Grid x:Name="SettingsOverlay" Grid.Row="1" Grid.RowSpan="2" Visibility="Collapsed" Background="{DynamicResource Scrim}">
                    <Grid MaxWidth="780" MaxHeight="540" Margin="24">
                        <Border Style="{DynamicResource CardShadow}"/>
                        <Border Style="{DynamicResource Card}">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="210"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                <Border Background="{DynamicResource Chrome.Bg}" CornerRadius="14,0,0,14" BorderBrush="{DynamicResource Divider}" BorderThickness="0,0,1,0">
                                    <StackPanel Margin="12,22,12,12">
                                        <TextBlock x:Uid="settings.title" Text="Settings" Style="{DynamicResource Text.Title}" Margin="12,0,0,16"/>
                                        <RadioButton x:Name="SetNavGeneral" x:Uid="settings.nav.general" GroupName="SetNav" Style="{DynamicResource NavItem}" Content="General"/>
                                        <RadioButton x:Name="SetNavAppearance" x:Uid="settings.nav.appearance" GroupName="SetNav" Style="{DynamicResource NavItem}" Content="Appearance"/>
                                        <RadioButton x:Name="SetNavLaunch" x:Uid="settings.nav.launch" GroupName="SetNav" Style="{DynamicResource NavItem}" Content="Launching"/>
                                        <RadioButton x:Name="SetNavData" x:Uid="settings.nav.data" GroupName="SetNav" Style="{DynamicResource NavItem}" Content="Data"/>
                                    </StackPanel>
                                </Border>
                                <Grid Grid.Column="1">
                                    <Grid.RowDefinitions>
                                        <RowDefinition Height="Auto"/>
                                        <RowDefinition Height="*"/>
                                        <RowDefinition Height="Auto"/>
                                    </Grid.RowDefinitions>
                                    <Grid Margin="28,22,16,6">
                                        <TextBlock x:Name="SettingsPageTitle" Text="" Style="{DynamicResource Text.Title}" VerticalAlignment="Center"/>
                                        <Button x:Name="BtnCloseSettings" x:Uid="close" Style="{DynamicResource IconButton}" HorizontalAlignment="Right">
                                            <Path Data="$($I.close.D)" Stroke="{DynamicResource Fg.2}" StrokeThickness="1.6" Width="10" Height="10" Stretch="Fill"/>
                                        </Button>
                                    </Grid>
                                    <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Margin="0,0,6,0">
                                        <Grid Margin="28,12,22,10">
                                            <!-- General -->
                                            <StackPanel x:Name="SetPageGeneral">
                                                <Grid Margin="0,0,0,22">
                                                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                                                    <StackPanel Margin="0,0,20,0">
                                                        <TextBlock x:Uid="settings.language" Text="Language" Style="{DynamicResource Text.Setting}"/>
                                                        <TextBlock x:Uid="settings.language.desc" Text="" Style="{DynamicResource Text.Desc}" Margin="0,3,0,0"/>
                                                    </StackPanel>
                                                    <ComboBox Grid.Column="1" x:Name="CmbLanguage" Width="170" VerticalAlignment="Center"/>
                                                </Grid>
                                                <Grid Margin="0,0,0,22">
                                                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                                                    <StackPanel Margin="0,0,20,0">
                                                        <TextBlock x:Uid="settings.remember" Text="" Style="{DynamicResource Text.Setting}"/>
                                                        <TextBlock x:Uid="settings.remember.desc" Text="" Style="{DynamicResource Text.Desc}" Margin="0,3,0,0"/>
                                                    </StackPanel>
                                                    <CheckBox Grid.Column="1" x:Name="ChkRememberCheckState" Style="{DynamicResource Switch}"/>
                                                </Grid>
                                                <Grid Margin="0,0,0,22">
                                                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                                                    <StackPanel Margin="0,0,20,0">
                                                        <TextBlock x:Uid="settings.startup" Text="" Style="{DynamicResource Text.Setting}"/>
                                                        <TextBlock x:Name="StartupDescText" x:Uid="settings.startup.desc" Text="" Style="{DynamicResource Text.Desc}" Margin="0,3,0,0"/>
                                                    </StackPanel>
                                                    <CheckBox Grid.Column="1" x:Name="ChkRunAtStartup" Style="{DynamicResource Switch}"/>
                                                </Grid>
                                            </StackPanel>

                                            <!-- Apariencia -->
                                            <StackPanel x:Name="SetPageAppearance" Visibility="Collapsed">
                                                <Grid Margin="0,0,0,22">
                                                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                                                    <StackPanel Margin="0,0,20,0">
                                                        <TextBlock x:Uid="settings.theme" Text="Theme" Style="{DynamicResource Text.Setting}"/>
                                                        <TextBlock x:Uid="settings.theme.desc" Text="" Style="{DynamicResource Text.Desc}" Margin="0,3,0,0"/>
                                                    </StackPanel>
                                                    <ComboBox Grid.Column="1" x:Name="CmbTheme" Width="170" VerticalAlignment="Center"/>
                                                </Grid>
                                                <Grid Margin="0,0,0,22">
                                                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                                                    <StackPanel Margin="0,0,20,0">
                                                        <TextBlock x:Uid="settings.favicons" Text="" Style="{DynamicResource Text.Setting}"/>
                                                        <TextBlock x:Uid="settings.favicons.desc" Text="" Style="{DynamicResource Text.Desc}" Margin="0,3,0,0"/>
                                                    </StackPanel>
                                                    <CheckBox Grid.Column="1" x:Name="ChkFetchFavicons" Style="{DynamicResource Switch}"/>
                                                </Grid>
                                                <Grid Margin="0,0,0,22">
                                                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                                                    <StackPanel Margin="0,0,20,0">
                                                        <TextBlock x:Uid="settings.sidebar" Text="" Style="{DynamicResource Text.Setting}"/>
                                                        <TextBlock x:Uid="settings.sidebar.desc" Text="" Style="{DynamicResource Text.Desc}" Margin="0,3,0,0"/>
                                                    </StackPanel>
                                                    <CheckBox Grid.Column="1" x:Name="ChkShowSidebar" Style="{DynamicResource Switch}"/>
                                                </Grid>
                                            </StackPanel>

                                            <!-- Apertura -->
                                            <StackPanel x:Name="SetPageLaunch" Visibility="Collapsed">
                                                <Grid Margin="0,0,0,22">
                                                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                                                    <StackPanel Margin="0,0,20,0">
                                                        <TextBlock x:Uid="settings.delay" Text="" Style="{DynamicResource Text.Setting}"/>
                                                        <TextBlock x:Uid="settings.delay.desc" Text="" Style="{DynamicResource Text.Desc}" Margin="0,3,0,0"/>
                                                    </StackPanel>
                                                    <ComboBox Grid.Column="1" x:Name="CmbLaunchDelay" Width="170" VerticalAlignment="Center"/>
                                                </Grid>
                                                <Grid Margin="0,0,0,22">
                                                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                                                    <StackPanel Margin="0,0,20,0">
                                                        <TextBlock x:Uid="settings.confirmMany" Text="" Style="{DynamicResource Text.Setting}"/>
                                                        <TextBlock x:Uid="settings.confirmMany.desc" Text="" Style="{DynamicResource Text.Desc}" Margin="0,3,0,0"/>
                                                    </StackPanel>
                                                    <CheckBox Grid.Column="1" x:Name="ChkConfirmMany" Style="{DynamicResource Switch}"/>
                                                </Grid>
                                                <Border CornerRadius="10" Background="{DynamicResource Subtle.Bg}" Padding="14,12">
                                                    <TextBlock x:Uid="settings.launch.note" Text="" Style="{DynamicResource Text.Desc}"/>
                                                </Border>
                                            </StackPanel>

                                            <!-- Datos -->
                                            <StackPanel x:Name="SetPageData" Visibility="Collapsed">
                                                <TextBlock x:Uid="settings.location" Text="" Style="{DynamicResource Text.Setting}"/>
                                                <TextBlock x:Uid="settings.location.desc" Text="" Style="{DynamicResource Text.Desc}" Margin="0,3,0,10"/>
                                                <Border CornerRadius="8" Background="{DynamicResource Subtle.Bg}" BorderBrush="{DynamicResource Border}" BorderThickness="1" Padding="11,8">
                                                    <TextBlock x:Name="SettingsFolderText" Text="" FontFamily="{DynamicResource Font.Mono}" FontSize="11.5" Foreground="{DynamicResource Fg.2}" TextTrimming="CharacterEllipsis"/>
                                                </Border>
                                                <StackPanel Orientation="Horizontal" Margin="0,10,0,24">
                                                    <Button x:Name="BtnOpenConfigFolder" Style="{DynamicResource SecondaryButton}" Height="32" Margin="0,0,8,0">
                                                        <StackPanel Orientation="Horizontal">
                                                            <Path Data="$($I.location.D)" Stroke="{DynamicResource Fg.2}" StrokeThickness="1.5" StrokeLineJoin="Round" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Width="12" Height="12" Stretch="Uniform" Margin="0,0,8,0" VerticalAlignment="Center"/>
                                                            <TextBlock x:Uid="settings.openFolder" Text="Open" VerticalAlignment="Center"/>
                                                        </StackPanel>
                                                    </Button>
                                                    <Button x:Name="BtnChangeConfigFolder" Style="{DynamicResource SecondaryButton}" Height="32">
                                                        <StackPanel Orientation="Horizontal">
                                                            <Path Data="$($I.folder.D)" Fill="{DynamicResource Accent.Text}" Width="13" Height="11" Stretch="Fill" Margin="0,0,8,0" VerticalAlignment="Center"/>
                                                            <TextBlock x:Uid="settings.changeFolder" Text="Change" VerticalAlignment="Center"/>
                                                        </StackPanel>
                                                    </Button>
                                                </StackPanel>

                                                <TextBlock x:Uid="settings.share" Text="" Style="{DynamicResource Text.Setting}"/>
                                                <TextBlock x:Uid="settings.share.desc" Text="" Style="{DynamicResource Text.Desc}" Margin="0,3,0,10"/>
                                                <StackPanel Orientation="Horizontal" Margin="0,0,0,24">
                                                    <Button x:Name="BtnExportConfig" x:Uid="settings.export" Style="{DynamicResource SecondaryButton}" Height="32" Margin="0,0,8,0">
                                                        <StackPanel Orientation="Horizontal">
                                                            <Path Data="$($I.export.D)" Stroke="{DynamicResource Accent.Text}" StrokeThickness="1.6" StrokeLineJoin="Round" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Width="12" Height="12" Stretch="Uniform" Margin="0,0,8,0" VerticalAlignment="Center"/>
                                                            <TextBlock x:Uid="settings.export.label" Text="Export" VerticalAlignment="Center"/>
                                                        </StackPanel>
                                                    </Button>
                                                    <Button x:Name="BtnImportConfig" x:Uid="settings.import" Style="{DynamicResource SecondaryButton}" Height="32">
                                                        <StackPanel Orientation="Horizontal">
                                                            <Path Data="$($I.import.D)" Stroke="{DynamicResource Accent.Text}" StrokeThickness="1.6" StrokeLineJoin="Round" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Width="12" Height="12" Stretch="Uniform" Margin="0,0,8,0" VerticalAlignment="Center"/>
                                                            <TextBlock x:Uid="settings.import.label" Text="Import" VerticalAlignment="Center"/>
                                                        </StackPanel>
                                                    </Button>
                                                </StackPanel>

                                                <TextBlock x:Uid="settings.maintenance" Text="" Style="{DynamicResource Text.Setting}" Margin="0,0,0,10"/>
                                                <StackPanel Orientation="Horizontal" Margin="0,0,0,24">
                                                    <Button x:Name="BtnRestoreSuggestionsSettings" Style="{DynamicResource SecondaryButton}" Height="32" Margin="0,0,8,0">
                                                        <TextBlock x:Name="RestoreSuggestionsSettingsText" Text=""/>
                                                    </Button>
                                                    <Button x:Name="BtnClearIconCache" x:Uid="settings.clearCache" Style="{DynamicResource SecondaryButton}" Height="32" Content="Clear icons"/>
                                                </StackPanel>

                                                <Border CornerRadius="10" BorderBrush="{DynamicResource Danger.Soft}" BorderThickness="1" Padding="14,12">
                                                    <Grid>
                                                        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                                                        <StackPanel Margin="0,0,14,0">
                                                            <TextBlock x:Uid="settings.danger" Text="" Style="{DynamicResource Text.Setting}" Foreground="{DynamicResource Danger}"/>
                                                            <TextBlock x:Uid="settings.danger.desc" Text="" Style="{DynamicResource Text.Desc}" Margin="0,3,0,0"/>
                                                        </StackPanel>
                                                        <Button Grid.Column="1" x:Name="BtnClearAll" x:Uid="clearAll.ok" Style="{DynamicResource DangerGhostButton}" Content="Delete all" VerticalAlignment="Center"/>
                                                    </Grid>
                                                </Border>
                                            </StackPanel>
                                        </Grid>
                                    </ScrollViewer>
                                    <Grid Grid.Row="2" Margin="28,8,20,18">
                                        <TextBlock x:Uid="settings.autosave" Text="" Style="{DynamicResource Text.Desc}" VerticalAlignment="Center"/>
                                        <Button x:Name="BtnSaveSettings" x:Uid="common.done" Style="{DynamicResource PrimaryButton}" MinWidth="100" HorizontalAlignment="Right" Content="Done"/>
                                    </Grid>
                                </Grid>
                            </Grid>
                        </Border>
                    </Grid>
                </Grid>

                <!-- Paleta de comandos -->
                <Grid x:Name="PaletteOverlay" Grid.Row="1" Grid.RowSpan="2" Visibility="Collapsed" Background="{DynamicResource Scrim}">
                    <Grid Width="580" HorizontalAlignment="Center" VerticalAlignment="Top" Margin="0,36,0,0">
                        <Border Style="{DynamicResource CardShadow}"/>
                        <Border Style="{DynamicResource Card}">
                            <StackPanel>
                                <Grid Margin="16,0,16,0">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="Auto"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <Path Data="$($I.command.D)" Stroke="{DynamicResource Accent.Text}" StrokeThickness="1.8" StrokeLineJoin="Round" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Width="14" Height="12" Stretch="Uniform" VerticalAlignment="Center" Margin="0,0,10,0"/>
                                    <TextBlock Grid.Column="1" x:Name="PalettePlaceholder" x:Uid="palette.placeholder" Text="" FontSize="14" Foreground="{DynamicResource Fg.3}" VerticalAlignment="Center" IsHitTestVisible="False" Margin="1,0,0,0"/>
                                    <TextBox Grid.Column="1" x:Name="PaletteBox" Background="Transparent" BorderThickness="0" Padding="0" Height="50" FontSize="14"/>
                                </Grid>
                                <Border Height="1" Background="{DynamicResource Divider}"/>
                                <StackPanel x:Name="PaletteList" Margin="6"/>
                                <TextBlock x:Name="PaletteEmptyText" x:Uid="palette.empty" Text="" Foreground="{DynamicResource Fg.3}" Margin="18,8,18,14" Visibility="Collapsed"/>
                                <Border Background="{DynamicResource Chrome.Bg}" CornerRadius="0,0,14,14" Padding="16,7" BorderBrush="{DynamicResource Divider}" BorderThickness="0,1,0,0">
                                    <TextBlock x:Uid="palette.footer" Text="" FontSize="11" Foreground="{DynamicResource Fg.3}"/>
                                </Border>
                            </StackPanel>
                        </Border>
                    </Grid>
                </Grid>

                <!-- Ayuda: preguntas, iconos, atajos y textos legales -->
                <Grid x:Name="HelpOverlay" Grid.Row="1" Grid.RowSpan="2" Visibility="Collapsed" Background="{DynamicResource Scrim}">
                    <Grid MaxWidth="820" MaxHeight="570" Margin="24">
                        <Border Style="{DynamicResource CardShadow}"/>
                        <Border Style="{DynamicResource Card}">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="214"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                <Border Background="{DynamicResource Chrome.Bg}" CornerRadius="14,0,0,14" BorderBrush="{DynamicResource Divider}" BorderThickness="0,0,1,0">
                                    <StackPanel Margin="12,22,12,12">
                                        <TextBlock x:Uid="help.title" Text="Help" Style="{DynamicResource Text.Title}" Margin="12,0,0,16"/>
                                        <RadioButton x:Name="HelpNavFaq" x:Uid="help.nav.faq" GroupName="HelpNav" Style="{DynamicResource NavItem}" Content="How to"/>
                                        <RadioButton x:Name="HelpNavIcons" x:Uid="help.nav.icons" GroupName="HelpNav" Style="{DynamicResource NavItem}" Content="Icons"/>
                                        <RadioButton x:Name="HelpNavKeys" x:Uid="help.nav.keys" GroupName="HelpNav" Style="{DynamicResource NavItem}" Content="Shortcuts"/>
                                        <TextBlock x:Uid="help.nav.legal" Text="LEGAL" Style="{DynamicResource Text.Section}" Margin="12,16,0,8"/>
                                        <RadioButton x:Name="HelpNavPrivacy" x:Uid="help.nav.privacy" GroupName="HelpNav" Style="{DynamicResource NavItem}" Content="Privacy"/>
                                        <RadioButton x:Name="HelpNavWarnings" x:Uid="help.nav.warnings" GroupName="HelpNav" Style="{DynamicResource NavItem}" Content="Warnings"/>
                                        <RadioButton x:Name="HelpNavTerms" x:Uid="help.nav.terms" GroupName="HelpNav" Style="{DynamicResource NavItem}" Content="Terms of use"/>
                                        <RadioButton x:Name="HelpNavDisclaimer" x:Uid="help.nav.disclaimer" GroupName="HelpNav" Style="{DynamicResource NavItem}" Content="Disclaimer"/>
                                        <TextBlock Text="" Margin="0,8,0,0"/>
                                        <RadioButton x:Name="HelpNavAbout" x:Uid="help.nav.about" GroupName="HelpNav" Style="{DynamicResource NavItem}" Content="About"/>
                                    </StackPanel>
                                </Border>
                                <Grid Grid.Column="1">
                                    <Grid.RowDefinitions>
                                        <RowDefinition Height="Auto"/>
                                        <RowDefinition Height="*"/>
                                    </Grid.RowDefinitions>
                                    <Grid Margin="30,22,16,8">
                                        <TextBlock x:Name="HelpPageTitle" Text="" Style="{DynamicResource Text.Title}" FontSize="18" VerticalAlignment="Center"/>
                                        <Button x:Name="BtnCloseHelp" x:Uid="close" Style="{DynamicResource IconButton}" HorizontalAlignment="Right">
                                            <Path Data="$($I.close.D)" Stroke="{DynamicResource Fg.2}" StrokeThickness="1.6" Width="10" Height="10" Stretch="Fill"/>
                                        </Button>
                                    </Grid>
                                    <ScrollViewer x:Name="HelpScroll" Grid.Row="1" VerticalScrollBarVisibility="Auto" Margin="0,0,6,12">
                                        <StackPanel x:Name="HelpContent" Margin="30,6,26,16"/>
                                    </ScrollViewer>
                                </Grid>
                            </Grid>
                        </Border>
                    </Grid>
                </Grid>

                <!-- Confirmaciones y mensajes -->
                <Grid x:Name="ConfirmOverlay" Grid.Row="1" Grid.RowSpan="2" Visibility="Collapsed" Background="{DynamicResource Scrim}">
                    <Grid Width="420" HorizontalAlignment="Center" VerticalAlignment="Center">
                        <Border Style="{DynamicResource CardShadow}"/>
                        <Border Style="{DynamicResource Card}" Padding="24,22">
                            <StackPanel>
                                <TextBlock x:Name="ConfirmTitleText" Text="" Style="{DynamicResource Text.Title}" Margin="0,0,0,10"/>
                                <TextBlock x:Name="ConfirmMessageText" Text="" Foreground="{DynamicResource Fg.2}" TextWrapping="Wrap" LineHeight="19"/>
                                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,22,0,0">
                                    <Button x:Name="BtnConfirmCancel" Style="{DynamicResource SecondaryButton}" MinWidth="92" Margin="0,0,8,0" Content="No"/>
                                    <Button x:Name="BtnConfirmOk" Style="{DynamicResource PrimaryButton}" MinWidth="92" Content="OK"/>
                                </StackPanel>
                            </StackPanel>
                        </Border>
                    </Grid>
                </Grid>

                <!-- Zona para soltar archivos y enlaces -->
                <Grid x:Name="DropOverlay" Grid.Row="0" Grid.RowSpan="3" Visibility="Collapsed" Background="{DynamicResource Scrim}" AllowDrop="True">
                    <Border CornerRadius="16" BorderBrush="{DynamicResource Accent}" BorderThickness="2" Margin="22" Background="{DynamicResource Accent.Soft}" IsHitTestVisible="False">
                        <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
                            <Border Width="64" Height="64" CornerRadius="32" Background="{DynamicResource Accent.Soft}" HorizontalAlignment="Center" Margin="0,0,0,16">
                                <Path Data="$($I.plus.D)" Stroke="{DynamicResource Accent.Text}" StrokeThickness="2.2" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Width="22" Height="22" Stretch="Fill"/>
                            </Border>
                            <TextBlock x:Uid="drop.title" Text="Drop to add" FontSize="18" FontWeight="SemiBold" HorizontalAlignment="Center"/>
                            <TextBlock x:Name="DropTargetText" Text="" Foreground="{DynamicResource Fg.2}" HorizontalAlignment="Center" Margin="0,6,0,0"/>
                        </StackPanel>
                    </Border>
                </Grid>

                <!-- Aviso breve (con acción opcional, ej. Deshacer) -->
                <Border x:Name="Toast" Grid.Row="1" VerticalAlignment="Bottom" HorizontalAlignment="Center" Margin="0,0,0,84"
                        CornerRadius="10" Background="{DynamicResource Toast.Bg}" Padding="14,8,8,8" Opacity="0" IsHitTestVisible="False">
                    <StackPanel Orientation="Horizontal">
                        <Ellipse x:Name="ToastDot" Width="7" Height="7" Fill="{DynamicResource Success}" VerticalAlignment="Center" Margin="0,0,9,0"/>
                        <TextBlock x:Name="ToastText" Text="" Foreground="{DynamicResource Toast.Fg}" VerticalAlignment="Center" Margin="0,0,6,0"/>
                        <Button x:Name="ToastAction" Style="{DynamicResource GhostButton}" Foreground="#5AA9FF" Height="24" Visibility="Collapsed">
                            <TextBlock x:Name="ToastActionText" Text="" FontWeight="SemiBold"/>
                        </Button>
                    </StackPanel>
                </Border>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

$Global:PlatformRowXamlTemplate = @"
<Border xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Margin="0,0,0,2" Padding="4,8,8,8" CornerRadius="10" BorderThickness="1" x:Name="RowBorder">
    <Border.Style>
        <Style TargetType="Border">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="BorderBrush" Value="Transparent"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="{DynamicResource Row.Hover}"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </Border.Style>
    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>

        <Rectangle x:Name="CursorBar" Grid.Column="0" Width="2.5" RadiusX="1.2" RadiusY="1.2" Margin="-4,6,0,6" HorizontalAlignment="Left"
                   Fill="{DynamicResource Accent}" Visibility="Collapsed"/>

        <!-- Asa para reordenar -->
        <Border Grid.Column="0" x:Name="DragHandle" x:Uid="row.drag" Background="Transparent" Cursor="SizeAll" Width="18" Margin="0,0,4,0">
            <Border.Style>
                <Style TargetType="Border">
                    <Setter Property="Opacity" Value="0"/>
                    <Style.Triggers>
                        <DataTrigger Binding="{Binding IsMouseOver, ElementName=RowBorder}" Value="True">
                            <Setter Property="Opacity" Value="0.55"/>
                        </DataTrigger>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter Property="Opacity" Value="1"/>
                        </Trigger>
                    </Style.Triggers>
                </Style>
            </Border.Style>
            <Path Data="$($I.grip.D)" Fill="{DynamicResource Fg.3}" HorizontalAlignment="Center" VerticalAlignment="Center"/>
        </Border>

        <CheckBox Grid.Column="1" x:Name="ItemCheck" Focusable="False" VerticalAlignment="Center" Margin="0,0,14,0"/>

        <!-- Icono automático (favicon, icono de aplicación, carpeta o inicial) -->
        <Border Grid.Column="2" x:Name="IconTile" Width="34" Height="34" CornerRadius="9" Margin="0,0,14,0" Background="{DynamicResource Tile.Bg}">
            <Grid>
                <TextBlock x:Name="IconLetter" Text="" Foreground="#FFFFFF" FontSize="14" FontWeight="SemiBold" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                <Image x:Name="IconImage" Width="18" Height="18" RenderOptions.BitmapScalingMode="HighQuality" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                <Path x:Name="IconGlyph" Width="16" Height="13" Stretch="Fill" Fill="{DynamicResource Accent.Text}" Visibility="Collapsed" HorizontalAlignment="Center" VerticalAlignment="Center"
                      Data="$($I.folder.D)"/>
            </Grid>
        </Border>

        <StackPanel Grid.Column="3" VerticalAlignment="Center" Margin="0,0,10,0">
            <StackPanel Orientation="Horizontal">
                <TextBlock x:Name="ItemName" Text="" FontSize="13.5" FontWeight="SemiBold" MaxWidth="340" TextTrimming="CharacterEllipsis" VerticalAlignment="Center"/>
                <Border x:Name="BrowserPill" Visibility="Collapsed" CornerRadius="6" Background="{DynamicResource Orange.Soft}" Padding="7,1,7,2" Margin="8,0,0,0" VerticalAlignment="Center">
                    <TextBlock x:Name="BrowserPillText" Text="" Foreground="{DynamicResource Orange.Text}" FontSize="10.5"/>
                </Border>
                <StackPanel x:Name="TagPanel" Orientation="Horizontal" VerticalAlignment="Center"/>
                <Button x:Name="BtnTagRow" x:Uid="row.tag" Cursor="Hand" Margin="6,0,0,0" VerticalAlignment="Center" Focusable="False">
                    <Button.Style>
                        <Style TargetType="Button">
                            <Setter Property="Opacity" Value="0"/>
                            <Style.Triggers>
                                <DataTrigger Binding="{Binding IsMouseOver, ElementName=RowBorder}" Value="True">
                                    <Setter Property="Opacity" Value="1"/>
                                </DataTrigger>
                            </Style.Triggers>
                        </Style>
                    </Button.Style>
                    <Button.Template>
                        <ControlTemplate TargetType="Button">
                            <Border x:Name="Bd" CornerRadius="6" BorderBrush="{DynamicResource Border.Strong}" BorderThickness="1" Padding="6,2,7,2" Background="Transparent">
                                <StackPanel Orientation="Horizontal">
                                    <Path Data="$($I.tag.D)" Fill="{DynamicResource Fg.3}" Width="9" Height="9" Stretch="Uniform" VerticalAlignment="Center" Margin="0,0,4,0"/>
                                    <TextBlock Text="+" Foreground="{DynamicResource Fg.2}" FontSize="10.5" VerticalAlignment="Center"/>
                                </StackPanel>
                            </Border>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter TargetName="Bd" Property="BorderBrush" Value="{DynamicResource Accent}"/>
                                    <Setter TargetName="Bd" Property="Background" Value="{DynamicResource Accent.Soft}"/>
                                </Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Button.Template>
                </Button>
            </StackPanel>
            <TextBlock x:Name="ItemUrl" Text="" FontFamily="{DynamicResource Font.Mono}" FontSize="11" Foreground="{DynamicResource Fg.3}" Margin="0,4,0,0" TextTrimming="CharacterEllipsis"/>
        </StackPanel>

        <!-- Acciones (aparecen al pasar el ratón) -->
        <StackPanel Grid.Column="4" Orientation="Horizontal" VerticalAlignment="Center">
            <StackPanel.Style>
                <Style TargetType="StackPanel">
                    <Setter Property="Opacity" Value="0"/>
                    <Style.Triggers>
                        <DataTrigger Binding="{Binding IsMouseOver, ElementName=RowBorder}" Value="True">
                            <Setter Property="Opacity" Value="1"/>
                        </DataTrigger>
                    </Style.Triggers>
                </Style>
            </StackPanel.Style>
            <Button x:Name="BtnPlayRow" x:Uid="row.play" Style="{DynamicResource IconButton}" Margin="0,0,2,0">
                <Path Data="$($I.play.D)" Fill="{DynamicResource Success}" Width="10" Height="12" Stretch="Fill" Margin="2,0,0,0"/>
            </Button>
            <Button x:Name="BtnEditRow" x:Uid="row.edit" Style="{DynamicResource IconButton}" Margin="0,0,2,0">
                <Path Data="$($I.edit.D)" Fill="{DynamicResource Fg.2}" Width="11" Height="11" Stretch="Fill"/>
            </Button>
            <Button x:Name="BtnMoreRow" x:Uid="row.more" Style="{DynamicResource IconButton}">
                <Path Data="$($I.more.D)" Fill="{DynamicResource Fg.2}" Width="14" Height="3.2" Stretch="Fill"/>
            </Button>
        </StackPanel>
    </Grid>
</Border>
"@

# Crea la ventana principal y devuelve una tabla con sus controles con nombre
function New-DLauncherWindow {
    [xml]$xml = $Global:MainWindowXaml
    $reader = New-Object System.Xml.XmlNodeReader $xml
    try {
        $window = [Windows.Markup.XamlReader]::Load($reader)
    } catch {
        Write-Error "Error al procesar XAML de la Ventana Principal: $_"
        throw
    }

    # Estilos compartidos (el diccionario del tema se inserta delante al aplicar el tema)
    $Global:DLauncherStylesDict = [Windows.Markup.XamlReader]::Parse($Global:DLauncherStylesXaml)
    $window.Resources.MergedDictionaries.Add($Global:DLauncherStylesDict)

    # Icono de la ventana desde Base64 (ejecutable autocontenido)
    try {
        $logoBytes = [System.Convert]::FromBase64String($Global:DLauncherLogoBase64.Trim())
        $window.Icon = [System.Windows.Media.Imaging.BitmapFrame]::Create([System.IO.MemoryStream]::new($logoBytes))
    } catch {
        # La aplicación funciona igual sin icono
    }

    $controls = @{ Window = $window }
    # Todos los elementos con x:Name del XAML
    foreach ($m in [regex]::Matches($Global:MainWindowXaml, 'x:Name="([^"]+)"')) {
        $n = $m.Groups[1].Value
        if (-not $controls.ContainsKey($n)) {
            $controls[$n] = $window.FindName($n)
        }
    }

    # Recortar el contenido a las esquinas redondeadas de la ventana
    $controls.RootGrid.Add_SizeChanged({
        param($sender, $e)
        $sender.Clip = [System.Windows.Media.RectangleGeometry]::new(
            [System.Windows.Rect]::new(0, 0, $sender.ActualWidth, $sender.ActualHeight), 11, 11)
    })

    return $controls
}

# Construye una fila del listado a partir de los datos de una herramienta
function New-DLauncherPlatformRow {
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Platform
    )
    [xml]$xml = $Global:PlatformRowXamlTemplate
    $reader = New-Object System.Xml.XmlNodeReader $xml
    try {
        $rowElement = [Windows.Markup.XamlReader]::Load($reader)
    } catch {
        return $null
    }

    $row = @{
        Element         = $rowElement
        Platform        = $Platform
        SearchKey       = ""
        ItemCheck       = $rowElement.FindName("ItemCheck")
        ItemName        = $rowElement.FindName("ItemName")
        ItemUrl         = $rowElement.FindName("ItemUrl")
        IconTile        = $rowElement.FindName("IconTile")
        IconLetter      = $rowElement.FindName("IconLetter")
        IconImage       = $rowElement.FindName("IconImage")
        IconGlyph       = $rowElement.FindName("IconGlyph")
        TagPanel        = $rowElement.FindName("TagPanel")
        BtnTag          = $rowElement.FindName("BtnTagRow")
        BrowserPill     = $rowElement.FindName("BrowserPill")
        BrowserPillText = $rowElement.FindName("BrowserPillText")
        BtnPlay         = $rowElement.FindName("BtnPlayRow")
        BtnEdit         = $rowElement.FindName("BtnEditRow")
        BtnMore         = $rowElement.FindName("BtnMoreRow")
        DragHandle      = $rowElement.FindName("DragHandle")
        CursorBar       = $rowElement.FindName("CursorBar")
    }

    $row.ItemName.Text = $Platform.Name
    $row.ItemUrl.Text = $Platform.Url
    $row.ItemCheck.IsChecked = [bool]$Platform.IsChecked

    # Cada control lleva el Id de su herramienta (los eventos lo leen del emisor, sin closures)
    $rowElement.Tag = $Platform.Id
    foreach ($ctl in $row.ItemCheck, $row.BtnPlay, $row.BtnEdit, $row.BtnMore, $row.BtnTag) {
        $ctl.Tag = $Platform.Id
    }
    $row.DragHandle.Tag = $rowElement
    return $row
}

# Crea un Path a partir de un icono del catálogo, con el color de una clave del tema
function New-DLauncherIconPath {
    param (
        [string]$Name,
        [double]$Size = 14,
        [string]$BrushKey = 'Fg.2',
        [double]$Thickness = 1.5
    )
    $icon = $Global:DLauncherIcons[$Name]
    $path = New-Object System.Windows.Shapes.Path
    $path.Data = [System.Windows.Media.Geometry]::Parse($icon.D)
    $path.Width = $Size
    $path.Height = $Size
    $path.Stretch = 'Uniform'
    $path.VerticalAlignment = 'Center'
    $path.HorizontalAlignment = 'Center'
    if ($icon.Fill) {
        $path.SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, $BrushKey)
    } else {
        $path.SetResourceReference([System.Windows.Shapes.Shape]::StrokeProperty, $BrushKey)
        $path.StrokeThickness = $Thickness
        $path.StrokeLineJoin = 'Round'
        $path.StrokeStartLineCap = 'Round'
        $path.StrokeEndLineCap = 'Round'
    }
    return $path
}

# Logo en Base64 (icono de ventana del ejecutable autocontenido)
$Global:DLauncherLogoBase64 = "iVBORw0KGgoAAAANSUhEUgAAAQAAAAEACAYAAABccqhmAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAZkSURBVHhe7dg/iNzHHcbhd9YqXEiWCzm4UCF37hKwixQBp4zBRQISRkUg7kJAttwnhUnpEMuV2hQBFVEXFekSERc22L06q0iRoCISisFgcZPiDKeb+7d399vb/c08T/mdLa6498PtJQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAsNFKexjeb/5zPude/GlK+VFKeSOpL7cfOZ3yOLV+lVI+z8Xzn+Wj8m37iVWo1/JqTe60941V86A8yo1yP8/aJ6YjAM97/8k7WZTbSbncPq3Iw9S8l08v/KN9mFp9N1eyla/b+yarNXfLo1wXgdVZtIdhffj0dhaLv57h+JPkSkr+nptPf98+kJSSq/WV3Klv5Vz7xjQEIEk+ePKr1Py6PZ+h3+b9J++0R0Rg1QTgxjeXUxaftOcztyi388F/J/5/Qx9EYHUEYPHsapINGF65nLrwV8ABRGA1BKC88EZ7WpvFBv0sG0gEpicAqW+2l7Wp9Sftid1EYFoCkLzeHtam5FJ7Yi8RmI4AMEsiMA0BYLZE4PQEgFkTgdMRAGZPBE5OAOiCCJyMANANETg+AaArInA8AkB3RGB5AkCXRGA5AkC3ROBoAkDXROBwAkD3ROBgAsAQRGB/AsAwRGAvAWAoIrCbADAcEdghAAxJBLYJAMMSAQFgcKNHQAAY3sgREAAYOAICAN8bMQICAM8ZLQICAI2RIiAAsI9RIiAAcIARIiAAcIjeIyAAcISeIyAAsIReI1Daw3BuPq3taY0e5taF19rjFOr1XKrf5eP2vsFeLyU/bo/rVmvulke5Xu7nWfs2RwIwSADmpr6Vc/WV3CklV9u3despAr4CsJHK/Twrj3K91txt39atp68DAsDGEoHVEwA2mgislgCw8URgdQSAWRCB1RAAZkMEpicAzIoITEsAmB0RmI4AMEsiMA0BYLZE4PQEgFkTgdMRAGZPBE5OAOiCCJyMANANETg+AaArInA8AkB3RGB5AkCXRGA5AkC3ROBoAkDXROBwAkD3ROBgAsAQRGB/AsAwRGAvAWAoIrCbADAcEdghAAxJBLYJAMMSAQFgcKNHQAAY3sgREAAYOAICAN8bMQICAM8ZLQICAI2RIiAAsI9RIiAAcIARIiAAcIjeIyAAcISeIyAAsIReIyAAsKRyP89S8q/2viFezQ/yYns8igDAkrau5ZOS3Gzv61ZrPislb5e/5H/t21EEAJbQ4/gjAHC0XscfAYDD9Tz+CAAcrPfxRwBgfyOMPwIAe40y/ggA7DbS+CMAsGO08UcAYNuI448AwLjjjwAwupHHHwFgZKOPPwLAqIx/mwAwHOPfIQAMxfh3EwCGYfx7CQBDMP79CQDdM/6DCQBdM/7DCQDdMv6jCQBdMv7lCADdMf7lCQBdMf7jEQC6YfzHJwB0wfhPRgCYPeM/OQFg1oz/dASA2TL+0xMAZsn4pyEAzI7xT0cAmBXjn5YAMBvGPz0BYBaMfzUEgI1n/KsjAGw0418tAWBjGf/qlfYwnJtPa3tao4e5deG19jiFej2X6nf5uL1vsFdLyc/a47r1NP4IwEABeDdXspWv2zvL62388RUAltPj+CMAcLRexx8BgMP1PP4IABys9/FHAGB/I4w/AgB7jTL+CADsNtL4IwCwY7TxRwBg24jjjwDAuOOPADC6kccfAWBko48/AsCojH+bADAc498hAAzF+HcTAIZh/HsJAEMw/v0JAN0z/oMJAF0z/sMJAN0y/qMJAF0y/uUIAN0x/uUJAF0x/uMRALph/McnAHTB+E9GAJg94z85AWDWjP90BIDZMv7TEwBmyfinIQDJw/awPvVxe2Ev45+OANR82Z7WppTP2xO7Gf+0BKBsfdGe1qbWr9oTO4x/egKwKPeS+m17XoPHObe41x7ZZvyrIQB/fOlBUn/Xns9c3fowfzj/7/aM8a+SACTJxZduJflbez475c/59OKf2ivGv2oCkCQflWe5deHtbOVGcqa/aI9Tt97LrfO/bB8w/rNQ2sPwbnxzOWXr5yn5YUp9Mykvtx85nfo4tXyZUr/IucW9s/qzf+sXuZwX8s/2vsEelJJrxg8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEP7PzTBEaS8MksDAAAAAElFTkSuQmCC"
