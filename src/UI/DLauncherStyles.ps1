# DLauncher - UI Styles Module
# Estilos y plantillas WPF. Todos los colores se resuelven con DynamicResource contra el tema activo
# (ver DLauncherThemes.ps1), por lo que el cambio claro/oscuro se aplica sin reconstruir la interfaz.

$Global:DLauncherStylesXaml = @"
<ResourceDictionary xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
                    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">

    <FontFamily x:Key="Font.Mono">Cascadia Mono, Consolas, Courier New</FontFamily>

    <!-- ============ Barra de desplazamiento fina ============ -->
    <ControlTemplate x:Key="ThumbTemplate" TargetType="Thumb">
        <Border x:Name="T" CornerRadius="3" Background="{DynamicResource Scroll.Thumb}"/>
        <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="T" Property="Background" Value="{DynamicResource Scroll.ThumbHover}"/>
            </Trigger>
            <Trigger Property="IsDragging" Value="True">
                <Setter TargetName="T" Property="Background" Value="{DynamicResource Scroll.ThumbHover}"/>
            </Trigger>
        </ControlTemplate.Triggers>
    </ControlTemplate>

    <Style TargetType="ScrollBar">
        <Setter Property="Background" Value="Transparent"/>
        <Setter Property="Width" Value="10"/>
        <Setter Property="MinWidth" Value="10"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="ScrollBar">
                    <Grid Background="Transparent">
                        <Track x:Name="PART_Track" IsDirectionReversed="True">
                            <Track.Thumb>
                                <Thumb Template="{StaticResource ThumbTemplate}" Margin="3,2"/>
                            </Track.Thumb>
                        </Track>
                    </Grid>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
        <Style.Triggers>
            <Trigger Property="Orientation" Value="Horizontal">
                <Setter Property="Width" Value="Auto"/>
                <Setter Property="MinWidth" Value="0"/>
                <Setter Property="Height" Value="10"/>
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="ScrollBar">
                            <Grid Background="Transparent">
                                <Track x:Name="PART_Track">
                                    <Track.Thumb>
                                        <Thumb Template="{StaticResource ThumbTemplate}" Margin="2,3"/>
                                    </Track.Thumb>
                                </Track>
                            </Grid>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Trigger>
        </Style.Triggers>
    </Style>

    <!-- ============ Casilla de verificación ============ -->
    <Style TargetType="CheckBox">
        <Setter Property="Foreground" Value="{DynamicResource Fg.1}"/>
        <Setter Property="FontSize" Value="12.5"/>
        <Setter Property="Cursor" Value="Hand"/>
        <Setter Property="FocusVisualStyle" Value="{x:Null}"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="CheckBox">
                    <Grid Background="Transparent">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="Auto"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <Border x:Name="Box" Width="16" Height="16" CornerRadius="4.5" BorderThickness="1.2"
                                BorderBrush="{DynamicResource Border.Strong}" Background="{DynamicResource Input.Bg}" VerticalAlignment="Center">
                            <Path x:Name="Mark" Data="M2.6,7 L5.4,9.8 L10.8,4.2" Stroke="{DynamicResource OnAccent}" StrokeThickness="1.8"
                                  StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round" Visibility="Collapsed"/>
                        </Border>
                        <ContentPresenter x:Name="CP" Grid.Column="1" Margin="9,0,0,0" VerticalAlignment="Center" RecognizesAccessKey="False"/>
                    </Grid>
                    <ControlTemplate.Triggers>
                        <Trigger Property="HasContent" Value="False">
                            <Setter TargetName="CP" Property="Margin" Value="0"/>
                        </Trigger>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="Box" Property="BorderBrush" Value="{DynamicResource Accent}"/>
                        </Trigger>
                        <Trigger Property="IsChecked" Value="True">
                            <Setter TargetName="Box" Property="Background" Value="{DynamicResource Accent}"/>
                            <Setter TargetName="Box" Property="BorderBrush" Value="{DynamicResource Accent}"/>
                            <Setter TargetName="Mark" Property="Visibility" Value="Visible"/>
                        </Trigger>
                        <Trigger Property="IsEnabled" Value="False">
                            <Setter Property="Opacity" Value="0.45"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>

    <!-- ============ Interruptor (ajustes) ============ -->
    <Style x:Key="Switch" TargetType="CheckBox">
        <Setter Property="Cursor" Value="Hand"/>
        <Setter Property="FocusVisualStyle" Value="{x:Null}"/>
        <Setter Property="VerticalAlignment" Value="Center"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="CheckBox">
                    <Border x:Name="Track" Width="36" Height="20" CornerRadius="10" BorderThickness="1"
                            Background="{DynamicResource Subtle.Bg}" BorderBrush="{DynamicResource Border.Strong}">
                        <Ellipse x:Name="Knob" Width="14" Height="14" Margin="2,0,0,0" HorizontalAlignment="Left" Fill="{DynamicResource Fg.3}"/>
                    </Border>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="Track" Property="BorderBrush" Value="{DynamicResource Accent}"/>
                        </Trigger>
                        <Trigger Property="IsChecked" Value="True">
                            <Setter TargetName="Track" Property="Background" Value="{DynamicResource Accent}"/>
                            <Setter TargetName="Track" Property="BorderBrush" Value="{DynamicResource Accent}"/>
                            <Setter TargetName="Knob" Property="HorizontalAlignment" Value="Right"/>
                            <Setter TargetName="Knob" Property="Margin" Value="0,0,2,0"/>
                            <Setter TargetName="Knob" Property="Fill" Value="{DynamicResource OnAccent}"/>
                        </Trigger>
                        <Trigger Property="IsEnabled" Value="False">
                            <Setter Property="Opacity" Value="0.4"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>

    <!-- ============ Botones ============ -->
    <Style x:Key="IconButton" TargetType="Button">
        <Setter Property="Background" Value="Transparent"/>
        <Setter Property="Foreground" Value="{DynamicResource Fg.2}"/>
        <Setter Property="Width" Value="30"/>
        <Setter Property="Height" Value="30"/>
        <Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Focusable" Value="False"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="Button">
                    <Border x:Name="Bd" CornerRadius="7" Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}">
                        <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="Bd" Property="Background" Value="{DynamicResource Hover.Bg}"/>
                        </Trigger>
                        <Trigger Property="IsPressed" Value="True">
                            <Setter TargetName="Bd" Property="Background" Value="{DynamicResource Active.Bg}"/>
                        </Trigger>
                        <Trigger Property="IsEnabled" Value="False">
                            <Setter Property="Opacity" Value="0.35"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>

    <Style x:Key="PrimaryButton" TargetType="Button">
        <Setter Property="Background" Value="{DynamicResource Accent}"/>
        <Setter Property="Foreground" Value="{DynamicResource OnAccent}"/>
        <Setter Property="FontSize" Value="12.5"/>
        <Setter Property="FontWeight" Value="SemiBold"/>
        <Setter Property="Height" Value="34"/>
        <Setter Property="Padding" Value="16,0"/>
        <Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Focusable" Value="False"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="Button">
                    <Border x:Name="Bd" CornerRadius="8" Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}">
                        <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="Bd" Property="Background" Value="{DynamicResource Accent.Hover}"/>
                        </Trigger>
                        <Trigger Property="IsEnabled" Value="False">
                            <Setter Property="Opacity" Value="0.45"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>

    <Style x:Key="SecondaryButton" TargetType="Button">
        <Setter Property="Background" Value="{DynamicResource Subtle.Bg}"/>
        <Setter Property="BorderBrush" Value="{DynamicResource Border}"/>
        <Setter Property="Foreground" Value="{DynamicResource Fg.1}"/>
        <Setter Property="FontSize" Value="12.5"/>
        <Setter Property="Height" Value="34"/>
        <Setter Property="Padding" Value="14,0"/>
        <Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Focusable" Value="False"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="Button">
                    <Border x:Name="Bd" CornerRadius="8" BorderThickness="1" Background="{TemplateBinding Background}"
                            BorderBrush="{TemplateBinding BorderBrush}" Padding="{TemplateBinding Padding}">
                        <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="Bd" Property="Background" Value="{DynamicResource Hover.Bg}"/>
                            <Setter TargetName="Bd" Property="BorderBrush" Value="{DynamicResource Border.Strong}"/>
                        </Trigger>
                        <Trigger Property="IsEnabled" Value="False">
                            <Setter Property="Opacity" Value="0.45"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>

    <Style x:Key="GhostButton" TargetType="Button">
        <Setter Property="Background" Value="Transparent"/>
        <Setter Property="Foreground" Value="{DynamicResource Accent.Text}"/>
        <Setter Property="FontSize" Value="12"/>
        <Setter Property="Height" Value="28"/>
        <Setter Property="Padding" Value="10,0"/>
        <Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Focusable" Value="False"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="Button">
                    <Border x:Name="Bd" CornerRadius="7" Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}">
                        <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="Bd" Property="Background" Value="{DynamicResource Accent.Soft}"/>
                        </Trigger>
                        <Trigger Property="IsEnabled" Value="False">
                            <Setter Property="Opacity" Value="0.4"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>

    <Style x:Key="DangerButton" TargetType="Button" BasedOn="{StaticResource PrimaryButton}">
        <Setter Property="Background" Value="{DynamicResource Danger}"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="Button">
                    <Border x:Name="Bd" CornerRadius="8" Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}">
                        <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="Bd" Property="Opacity" Value="0.88"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>

    <Style x:Key="DangerGhostButton" TargetType="Button" BasedOn="{StaticResource GhostButton}">
        <Setter Property="Foreground" Value="{DynamicResource Danger}"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="Button">
                    <Border x:Name="Bd" CornerRadius="7" Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}">
                        <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="Bd" Property="Background" Value="{DynamicResource Danger.Soft}"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>

    <!-- Botón compacto de la barra de estado -->
    <Style x:Key="StatusButton" TargetType="Button">
        <Setter Property="Background" Value="Transparent"/>
        <Setter Property="Foreground" Value="{DynamicResource Fg.3}"/>
        <Setter Property="FontSize" Value="11"/>
        <Setter Property="Height" Value="22"/>
        <Setter Property="Padding" Value="7,0"/>
        <Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Focusable" Value="False"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="Button">
                    <Border x:Name="Bd" CornerRadius="5" Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}">
                        <ContentPresenter VerticalAlignment="Center"/>
                    </Border>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="Bd" Property="Background" Value="{DynamicResource Hover.Bg}"/>
                            <Setter Property="Foreground" Value="{DynamicResource Fg.1}"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>

    <!-- Botones de ventana -->
    <Style x:Key="WinButton" TargetType="Button">
        <Setter Property="Width" Value="36"/>
        <Setter Property="Height" Value="30"/>
        <Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Focusable" Value="False"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="Button">
                    <Border x:Name="Bd" CornerRadius="7" Background="Transparent">
                        <Path Data="M0,0 H10" Stroke="{DynamicResource Fg.2}" StrokeThickness="1.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="Bd" Property="Background" Value="{DynamicResource Hover.Bg}"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>

    <Style x:Key="WinCloseButton" TargetType="Button">
        <Setter Property="Width" Value="36"/>
        <Setter Property="Height" Value="30"/>
        <Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Focusable" Value="False"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="Button">
                    <Border x:Name="Bd" CornerRadius="7" Background="Transparent">
                        <Path x:Name="X" Data="M0,0 L10,10 M0,10 L10,0" Stroke="{DynamicResource Fg.2}" StrokeThickness="1.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="Bd" Property="Background" Value="{DynamicResource Danger}"/>
                            <Setter TargetName="X" Property="Stroke" Value="#FFFFFF"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>

    <!-- Elemento de navegación de paneles (Ajustes / Ayuda) -->
    <Style x:Key="NavItem" TargetType="RadioButton">
        <Setter Property="Foreground" Value="{DynamicResource Fg.2}"/>
        <Setter Property="FontSize" Value="12.5"/>
        <Setter Property="Height" Value="32"/>
        <Setter Property="Margin" Value="0,0,0,2"/>
        <Setter Property="Cursor" Value="Hand"/>
        <Setter Property="FocusVisualStyle" Value="{x:Null}"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="RadioButton">
                    <Border x:Name="Bd" CornerRadius="7" Background="Transparent" Padding="12,0">
                        <Grid>
                            <Rectangle x:Name="Bar" Width="2" Height="14" RadiusX="1" RadiusY="1" Fill="{DynamicResource Accent}"
                                       HorizontalAlignment="Left" Margin="-12,0,0,0" Visibility="Collapsed"/>
                            <ContentPresenter VerticalAlignment="Center"/>
                        </Grid>
                    </Border>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="Bd" Property="Background" Value="{DynamicResource Hover.Bg}"/>
                        </Trigger>
                        <Trigger Property="IsChecked" Value="True">
                            <Setter TargetName="Bd" Property="Background" Value="{DynamicResource Active.Bg}"/>
                            <Setter TargetName="Bar" Property="Visibility" Value="Visible"/>
                            <Setter Property="Foreground" Value="{DynamicResource Fg.1}"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>

    <!-- Selector segmentado (bienvenida) -->
    <Style x:Key="Segment" TargetType="RadioButton">
        <Setter Property="Foreground" Value="{DynamicResource Fg.2}"/>
        <Setter Property="FontSize" Value="12"/>
        <Setter Property="Height" Value="30"/>
        <Setter Property="Cursor" Value="Hand"/>
        <Setter Property="FocusVisualStyle" Value="{x:Null}"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="RadioButton">
                    <Border x:Name="Bd" CornerRadius="7" Background="Transparent" Padding="12,0" Margin="2">
                        <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter Property="Foreground" Value="{DynamicResource Fg.1}"/>
                        </Trigger>
                        <Trigger Property="IsChecked" Value="True">
                            <Setter TargetName="Bd" Property="Background" Value="{DynamicResource Active.Bg}"/>
                            <Setter Property="Foreground" Value="{DynamicResource Fg.1}"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>

    <!-- ============ Campo de texto ============ -->
    <Style TargetType="TextBox">
        <Setter Property="Background" Value="{DynamicResource Input.Bg}"/>
        <Setter Property="Foreground" Value="{DynamicResource Fg.1}"/>
        <Setter Property="BorderBrush" Value="{DynamicResource Border}"/>
        <Setter Property="BorderThickness" Value="1"/>
        <Setter Property="CaretBrush" Value="{DynamicResource Fg.1}"/>
        <Setter Property="SelectionBrush" Value="{DynamicResource Accent}"/>
        <Setter Property="FontSize" Value="12.5"/>
        <Setter Property="Height" Value="34"/>
        <Setter Property="Padding" Value="9,0"/>
        <Setter Property="VerticalContentAlignment" Value="Center"/>
        <Setter Property="FocusVisualStyle" Value="{x:Null}"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="TextBox">
                    <Border x:Name="Bd" CornerRadius="8" Background="{TemplateBinding Background}"
                            BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}">
                        <ScrollViewer x:Name="PART_ContentHost" Margin="{TemplateBinding Padding}" Focusable="False"
                                      VerticalAlignment="{TemplateBinding VerticalContentAlignment}"
                                      HorizontalScrollBarVisibility="Hidden" VerticalScrollBarVisibility="Hidden"/>
                    </Border>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="Bd" Property="BorderBrush" Value="{DynamicResource Border.Strong}"/>
                        </Trigger>
                        <Trigger Property="IsKeyboardFocused" Value="True">
                            <Setter TargetName="Bd" Property="BorderBrush" Value="{DynamicResource Accent}"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>

    <!-- ============ Desplegable ============ -->
    <Style TargetType="ComboBox">
        <Setter Property="Foreground" Value="{DynamicResource Fg.1}"/>
        <Setter Property="FontSize" Value="12.5"/>
        <Setter Property="Height" Value="32"/>
        <Setter Property="Cursor" Value="Hand"/>
        <Setter Property="FocusVisualStyle" Value="{x:Null}"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="ComboBox">
                    <Grid>
                        <ToggleButton Focusable="False" ClickMode="Press"
                                      IsChecked="{Binding IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}">
                            <ToggleButton.Template>
                                <ControlTemplate TargetType="ToggleButton">
                                    <Border x:Name="Bd" CornerRadius="8" BorderThickness="1"
                                            Background="{DynamicResource Input.Bg}" BorderBrush="{DynamicResource Border}">
                                        <Path HorizontalAlignment="Right" VerticalAlignment="Center" Margin="0,0,12,0" Data="M0,0 L4,4 L8,0"
                                              Stroke="{DynamicResource Fg.3}" StrokeThickness="1.4"/>
                                    </Border>
                                    <ControlTemplate.Triggers>
                                        <Trigger Property="IsMouseOver" Value="True">
                                            <Setter TargetName="Bd" Property="BorderBrush" Value="{DynamicResource Border.Strong}"/>
                                        </Trigger>
                                        <Trigger Property="IsChecked" Value="True">
                                            <Setter TargetName="Bd" Property="BorderBrush" Value="{DynamicResource Accent}"/>
                                        </Trigger>
                                    </ControlTemplate.Triggers>
                                </ControlTemplate>
                            </ToggleButton.Template>
                        </ToggleButton>
                        <ContentPresenter IsHitTestVisible="False" Margin="11,0,30,0" VerticalAlignment="Center" HorizontalAlignment="Left"
                                          Content="{TemplateBinding SelectionBoxItem}" ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}"/>
                        <Popup x:Name="PART_Popup" Placement="Bottom" VerticalOffset="4" AllowsTransparency="True" Focusable="False"
                               PopupAnimation="Fade" IsOpen="{TemplateBinding IsDropDownOpen}">
                            <Border Background="{DynamicResource Panel.Bg}" BorderBrush="{DynamicResource Border.Strong}" BorderThickness="1"
                                    CornerRadius="9" Padding="4" MinWidth="{TemplateBinding ActualWidth}" MaxHeight="300">
                                <ScrollViewer VerticalScrollBarVisibility="Auto">
                                    <ItemsPresenter/>
                                </ScrollViewer>
                            </Border>
                        </Popup>
                    </Grid>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsEnabled" Value="False">
                            <Setter Property="Opacity" Value="0.45"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>

    <Style TargetType="ComboBoxItem">
        <Setter Property="Foreground" Value="{DynamicResource Fg.1}"/>
        <Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="ComboBoxItem">
                    <Border x:Name="Bd" CornerRadius="6" Padding="9,6" Background="Transparent">
                        <ContentPresenter/>
                    </Border>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsSelected" Value="True">
                            <Setter TargetName="Bd" Property="Background" Value="{DynamicResource Accent.Soft}"/>
                        </Trigger>
                        <Trigger Property="IsHighlighted" Value="True">
                            <Setter TargetName="Bd" Property="Background" Value="{DynamicResource Hover.Bg}"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>

    <!-- ============ Información emergente ============ -->
    <Style TargetType="ToolTip">
        <Setter Property="HasDropShadow" Value="False"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="ToolTip">
                    <Border Background="{DynamicResource Panel.Bg}" BorderBrush="{DynamicResource Border.Strong}" BorderThickness="1"
                            CornerRadius="7" Padding="9,6" MaxWidth="320">
                        <ContentPresenter TextElement.Foreground="{DynamicResource Fg.1}" TextElement.FontSize="11.5">
                            <ContentPresenter.Resources>
                                <Style TargetType="TextBlock">
                                    <Setter Property="TextWrapping" Value="Wrap"/>
                                </Style>
                            </ContentPresenter.Resources>
                        </ContentPresenter>
                    </Border>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>

    <!-- ============ Menú contextual ============ -->
    <Style TargetType="ContextMenu">
        <Setter Property="OverridesDefaultStyle" Value="True"/>
        <Setter Property="HasDropShadow" Value="False"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="ContextMenu">
                    <Border Background="{DynamicResource Panel.Bg}" BorderBrush="{DynamicResource Border.Strong}" BorderThickness="1"
                            CornerRadius="10" Padding="4" MinWidth="210">
                        <StackPanel IsItemsHost="True" KeyboardNavigation.DirectionalNavigation="Cycle"/>
                    </Border>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>

    <Style TargetType="MenuItem">
        <Setter Property="OverridesDefaultStyle" Value="True"/>
        <Setter Property="Foreground" Value="{DynamicResource Fg.1}"/>
        <Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="MenuItem">
                    <Border x:Name="Bd" CornerRadius="6" Padding="10,7" Background="Transparent">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="22"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <ContentPresenter ContentSource="Icon" VerticalAlignment="Center" HorizontalAlignment="Left"/>
                            <ContentPresenter Grid.Column="1" ContentSource="Header" VerticalAlignment="Center" TextElement.FontSize="12.5"/>
                            <TextBlock Grid.Column="2" Text="{TemplateBinding InputGestureText}" Foreground="{DynamicResource Fg.3}"
                                       FontSize="11" Margin="24,0,0,0" VerticalAlignment="Center"/>
                        </Grid>
                    </Border>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsHighlighted" Value="True">
                            <Setter TargetName="Bd" Property="Background" Value="{DynamicResource Hover.Bg}"/>
                        </Trigger>
                        <Trigger Property="IsEnabled" Value="False">
                            <Setter Property="Opacity" Value="0.4"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>

    <Style x:Key="MenuSeparator" TargetType="Separator">
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="Separator">
                    <Border Height="1" Margin="8,4" Background="{DynamicResource Divider}"/>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>

    <!-- ============ Tarjetas de diálogo ============ -->
    <!-- La sombra va en una capa propia para que el texto de la tarjeta conserve el suavizado ClearType -->
    <Style x:Key="CardShadow" TargetType="Border">
        <Setter Property="Background" Value="{DynamicResource Panel.Bg}"/>
        <Setter Property="CornerRadius" Value="14"/>
        <Setter Property="IsHitTestVisible" Value="False"/>
        <Setter Property="Effect">
            <Setter.Value>
                <DropShadowEffect BlurRadius="40" ShadowDepth="10" Direction="270" Opacity="0.35" Color="#000000"/>
            </Setter.Value>
        </Setter>
    </Style>

    <Style x:Key="Card" TargetType="Border">
        <Setter Property="Background" Value="{DynamicResource Panel.Bg}"/>
        <Setter Property="BorderBrush" Value="{DynamicResource Border.Strong}"/>
        <Setter Property="BorderThickness" Value="1"/>
        <Setter Property="CornerRadius" Value="14"/>
    </Style>

    <!-- ============ Textos ============ -->
    <Style x:Key="Text.Title" TargetType="TextBlock">
        <Setter Property="FontSize" Value="16"/>
        <Setter Property="FontWeight" Value="SemiBold"/>
        <Setter Property="Foreground" Value="{DynamicResource Fg.1}"/>
    </Style>
    <Style x:Key="Text.Label" TargetType="TextBlock">
        <Setter Property="FontSize" Value="11.5"/>
        <Setter Property="Foreground" Value="{DynamicResource Fg.2}"/>
        <Setter Property="Margin" Value="0,0,0,6"/>
    </Style>
    <Style x:Key="Text.Desc" TargetType="TextBlock">
        <Setter Property="FontSize" Value="11.5"/>
        <Setter Property="Foreground" Value="{DynamicResource Fg.3}"/>
        <Setter Property="TextWrapping" Value="Wrap"/>
        <Setter Property="LineHeight" Value="17"/>
    </Style>
    <Style x:Key="Text.Section" TargetType="TextBlock">
        <Setter Property="FontSize" Value="10.5"/>
        <Setter Property="FontWeight" Value="SemiBold"/>
        <Setter Property="Foreground" Value="{DynamicResource Fg.3}"/>
    </Style>
    <Style x:Key="Text.Setting" TargetType="TextBlock">
        <Setter Property="FontSize" Value="13"/>
        <Setter Property="Foreground" Value="{DynamicResource Fg.1}"/>
    </Style>
</ResourceDictionary>
"@
