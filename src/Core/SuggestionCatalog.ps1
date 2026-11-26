# DLauncher - Suggestion Catalog
# Catálogo fijo de aplicaciones y webs habituales para añadir con un clic.
# No detecta ni inspecciona lo que hay instalado: son accesos predefinidos que el usuario
# puede añadir, editar o eliminar como cualquier otra herramienta, u ocultar del catálogo.
# Los nombres de productos son marcas de sus respectivos propietarios.

$Global:DLauncherSuggestionCategories = @('m365', 'google', 'comms', 'work', 'windows')

$Global:DLauncherSuggestions = @(
    # Microsoft 365
    @{ Id = 'm365.outlook';     Category = 'm365';    Url = 'outlook.exe';                          Name = 'Outlook' }
    @{ Id = 'm365.outlookweb';  Category = 'm365';    Url = 'https://outlook.office.com/mail/';     Name = @{ es = 'Outlook (web)'; en = 'Outlook (web)' } }
    @{ Id = 'm365.teams';       Category = 'm365';    Url = 'msteams:';                             Name = 'Microsoft Teams' }
    @{ Id = 'm365.teamsweb';    Category = 'm365';    Url = 'https://teams.microsoft.com/';         Name = @{ es = 'Teams (web)'; en = 'Teams (web)' } }
    @{ Id = 'm365.word';        Category = 'm365';    Url = 'winword.exe';                          Name = 'Word' }
    @{ Id = 'm365.excel';       Category = 'm365';    Url = 'excel.exe';                            Name = 'Excel' }
    @{ Id = 'm365.powerpoint';  Category = 'm365';    Url = 'powerpnt.exe';                         Name = 'PowerPoint' }
    @{ Id = 'm365.onenote';     Category = 'm365';    Url = 'onenote.exe';                          Name = 'OneNote' }
    @{ Id = 'm365.home';        Category = 'm365';    Url = 'https://www.microsoft365.com/';        Name = 'Microsoft 365' }

    # Google
    @{ Id = 'google.gmail';     Category = 'google';  Url = 'https://mail.google.com/';             Name = 'Gmail' }
    @{ Id = 'google.calendar';  Category = 'google';  Url = 'https://calendar.google.com/';         Name = @{ es = 'Google Calendar'; en = 'Google Calendar' } }
    @{ Id = 'google.drive';     Category = 'google';  Url = 'https://drive.google.com/';            Name = 'Google Drive' }
    @{ Id = 'google.meet';      Category = 'google';  Url = 'https://meet.google.com/';             Name = 'Google Meet' }

    # Comunicación
    @{ Id = 'comms.slack';      Category = 'comms';   Url = 'https://app.slack.com/client';         Name = 'Slack' }
    @{ Id = 'comms.zoom';       Category = 'comms';   Url = 'https://zoom.us/';                     Name = 'Zoom' }
    @{ Id = 'comms.whatsapp';   Category = 'comms';   Url = 'https://web.whatsapp.com/';            Name = 'WhatsApp Web' }

    # Trabajo y desarrollo
    @{ Id = 'work.github';      Category = 'work';    Url = 'https://github.com/';                  Name = 'GitHub' }
    @{ Id = 'work.notion';      Category = 'work';    Url = 'https://www.notion.so/';               Name = 'Notion' }
    @{ Id = 'work.claude';      Category = 'work';    Url = 'https://claude.ai/';                   Name = 'Claude' }
    @{ Id = 'work.chatgpt';     Category = 'work';    Url = 'https://chatgpt.com/';                 Name = 'ChatGPT' }

    # Windows
    @{ Id = 'win.explorer';     Category = 'windows'; Url = 'explorer.exe';                         Name = @{ es = 'Explorador de archivos'; en = 'File Explorer' } }
    @{ Id = 'win.downloads';    Category = 'windows'; Url = 'shell:Downloads';                      Name = @{ es = 'Descargas'; en = 'Downloads' } }
    @{ Id = 'win.documents';    Category = 'windows'; Url = 'shell:Personal';                       Name = @{ es = 'Documentos'; en = 'Documents' } }
    @{ Id = 'win.calc';         Category = 'windows'; Url = 'calc.exe';                             Name = @{ es = 'Calculadora'; en = 'Calculator' } }
    @{ Id = 'win.notepad';      Category = 'windows'; Url = 'notepad.exe';                          Name = @{ es = 'Bloc de notas'; en = 'Notepad' } }
    @{ Id = 'win.taskmgr';      Category = 'windows'; Url = 'taskmgr.exe';                          Name = @{ es = 'Administrador de tareas'; en = 'Task Manager' } }
    @{ Id = 'win.settings';     Category = 'windows'; Url = 'ms-settings:';                         Name = @{ es = 'Configuración de Windows'; en = 'Windows Settings' } }
    @{ Id = 'win.terminal';     Category = 'windows'; Url = 'wt.exe';                               Name = 'Windows Terminal' }
)

# Nombre visible de una sugerencia en el idioma activo
function Get-DLauncherSuggestionName {
    param ($Suggestion)
    $n = $Suggestion.Name
    if ($n -is [hashtable]) {
        if ($n.ContainsKey($Global:DLauncherLanguage)) { return [string]$n[$Global:DLauncherLanguage] }
        return [string]$n['en']
    }
    return [string]$n
}

# Sugerencias visibles (sin las ocultadas por el usuario), en el orden del catálogo
function Get-DLauncherSuggestions {
    param ([string[]]$Hidden = @())
    return @($Global:DLauncherSuggestions | Where-Object { $Hidden -notcontains $_.Id })
}
