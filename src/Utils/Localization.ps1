# DLauncher - Localization Module
# Textos de la interfaz en Español (predeterminado) e Inglés.
# Los elementos XAML con x:Uid="clave" se traducen automáticamente (Text/Content y "clave.tip" para ToolTip).
# Los textos largos admiten "## Título", párrafos separados por línea en blanco y viñetas "• ".

$Global:DLauncherDefaultLanguage = "es"
$Global:DLauncherLanguages = @(
    @{ Code = "es"; Name = "Español"; Culture = "es-ES"; DateFormat = "dddd, d 'de' MMMM 'de' yyyy" },
    @{ Code = "en"; Name = "English"; Culture = "en-US"; DateFormat = "dddd, MMMM d, yyyy" }
)

$Global:DLauncherStrings = @{
    es = @{
        # --- Comunes ---
        'common.cancel'          = 'Cancelar'
        'common.save'            = 'Guardar'
        'common.accept'          = 'Aceptar'
        'common.continue'        = 'Continuar'
        'common.delete'          = 'Eliminar'
        'common.done'            = 'Listo'
        'common.undo'            = 'Deshacer'
        'close.tip'              = 'Cerrar (Esc)'

        # --- Barra de título ---
        'hdr.sidebar.tip'        = 'Mostrar u ocultar la barra lateral (Ctrl+B)'
        'hdr.theme.tip'          = 'Cambiar entre tema claro y oscuro'
        'hdr.help.tip'           = 'Ayuda, iconos, atajos y textos legales (F1)'
        'hdr.settings.tip'       = 'Ajustes (Ctrl+,)'
        'hdr.min.tip'            = 'Minimizar'
        'hdr.close.tip'          = 'Cerrar'
        'search.placeholder'     = 'Buscar herramientas, webs o archivos'
        'search.clear.tip'       = 'Limpiar (Esc)'
        'search.palette.tip'     = 'Paleta de comandos'

        # --- Barra lateral ---
        'add.tip'                = 'Agregar herramienta (Ctrl+N). También puedes arrastrar archivos o enlaces a la ventana'
        'add.label'              = 'Agregar herramienta'
        'add.header.tip'         = 'Agregar herramienta (Ctrl+N)'
        'add.short'              = 'Agregar'
        'side.library'           = 'BIBLIOTECA'
        'side.tags'              = 'ETIQUETAS'
        'side.newTag.tip'        = 'Nueva etiqueta'
        'side.tagsEmpty'         = 'Agrupa tus herramientas (Mañana, Soporte, Reuniones…) con el botón +.'
        'side.all'               = 'Todas'
        'side.selected'          = 'Seleccionadas'
        'side.suggestions'       = 'Sugerencias'
        'side.help'              = 'Ayuda'
        'side.settings'          = 'Ajustes'
        'side.tag.tip'           = 'Clic: filtrar · Doble clic: renombrar · Suelta aquí una herramienta para etiquetarla'
        'side.openTag.tip'       = 'Abrir todas las herramientas de esta etiqueta'

        # --- Vista ---
        'view.all'               = 'Todas las herramientas'
        'view.selected'          = 'Seleccionadas'
        'view.subtitle'          = '{0} herramientas · {1} seleccionadas'
        'toggleAll.tip'          = 'Marcar o desmarcar todas las visibles'
        'toggle.select'          = 'Marcar todas'
        'toggle.clear'           = 'Desmarcar todas'

        # --- Estados vacíos ---
        'empty.title'            = 'Tu lanzador diario está listo'
        'empty.body'             = 'Añade las aplicaciones, webs y archivos que usas cada día y ábrelos todos con un clic. Empieza con las sugerencias o arrastra elementos desde el Explorador o el navegador.'
        'empty.ctaSuggestions'   = 'Ver sugerencias'
        'empty.cta'              = 'Agregar herramienta'
        'empty.hint'             = 'Consejo: pulsa Ctrl+K para abrir la paleta de comandos'
        'noresults.title'        = 'Sin resultados'
        'noresults.body'         = 'No hay herramientas que coincidan con «{0}».'
        'emptygroup.title'       = 'Ninguna herramienta con esta etiqueta'
        'emptygroup.body'        = 'Arrastra una herramienta (por su asa ⋮⋮) sobre la etiqueta en la barra lateral, o usa el botón de etiqueta de cada fila.'
        'emptysel.title'         = 'Nada seleccionado'
        'emptysel.body'          = 'Marca las herramientas que quieras abrir juntas.'

        # --- Barra de acciones ---
        'status.selected'        = '{0} de {1} seleccionadas'
        'open'                   = 'Abrir'
        'open.group'             = 'Abrir {0}'
        'openAll.tip'            = 'Abrir las seleccionadas (Ctrl+Enter)'
        'open.progress'          = 'Abriendo {0}/{1}…'
        'delay.button.tip'       = 'Pausa entre cada apertura. Clic para cambiarla'
        'delay.status'           = '{0} entre aperturas'
        'delay.0'                = 'Sin pausa'
        'delay.250'              = '0,25 s'
        'delay.500'              = '0,5 s'
        'delay.1000'             = '1 s'
        'delay.2000'             = '2 s'
        'delay.3000'             = '3 s'
        'delay.5000'             = '5 s'

        # --- Barra de estado ---
        'statusbar.ready'        = 'Listo · {0} herramientas'
        'statusbar.noFolder'     = 'Sin carpeta de configuración'
        'statusbar.missing'      = 'No se encuentra la carpeta de configuración'
        'statusbar.readonly'     = 'Configuración en uso por otro programa: los cambios no se guardan'
        'statusbar.launching'    = 'Abriendo {0} de {1} · {2}'
        'status.folder.tip'      = 'Carpeta de configuración (clic para abrirla)'
        'status.language.tip'    = 'Cambiar idioma'
        'status.theme.tip'       = 'Tema (clic para ajustes de apariencia)'
        'theme.system'           = 'Sistema'
        'theme.dark'             = 'Oscuro'
        'theme.light'            = 'Claro'

        # --- Avisos breves ---
        'toast.opening'          = 'Abriendo {0}'
        'toast.noneSelected'     = 'No hay herramientas seleccionadas'
        'toast.tagEmpty'         = 'Esta etiqueta no tiene herramientas'
        'toast.doneOne'          = 'Listo: 1 herramienta abierta'
        'toast.doneMany'         = 'Listo: {0} herramientas abiertas'
        'toast.added'            = '«{0}» añadida'
        'toast.saved'            = 'Cambios guardados'
        'toast.deleted'          = '«{0}» eliminada'
        'toast.duplicated'       = '«{0}» creada'
        'toast.copied'           = 'Copiado al portapapeles'
        'toast.copyFailed'       = 'No se pudo usar el portapapeles'
        'toast.restored'         = 'Cambios deshechos'
        'toast.reloaded'         = 'Lista actualizada con cambios de otro equipo'
        'toast.folderBack'       = 'La carpeta de configuración vuelve a estar disponible'
        'toast.tagged'           = '«{0}» etiquetada como {1}'
        'toast.alreadyTagged'    = '«{0}» ya tenía esa etiqueta'
        'toast.tagDeleted'       = 'Etiqueta «{0}» eliminada'
        'toast.clearedAll'       = 'Se eliminaron todas las herramientas'
        'toast.imported'         = '{0} herramientas importadas'
        'toast.cacheCleared'     = 'Iconos borrados: se descargarán de nuevo'
        'drag.hint'              = 'Suelta sobre una etiqueta para asignarla, o en la lista para reordenar'
        'many.title'             = '¿Abrir muchas a la vez?'
        'many.body'              = 'Vas a abrir {0} herramientas. Se abrirán una a una con la pausa configurada, pero pueden consumir bastante memoria.'
        'many.ok'                = 'Abrir {0}'
        'batch.errorsTitle'      = 'Algunas no se pudieron abrir'
        'batch.errorsBody'       = 'Se abrieron {0} de {1}.'
        'err.title'              = 'No se pudo abrir'
        'err.body'               = "No se pudo abrir «{0}».`n`nDetalle: {1}`n`nDestino: {2}"
        'err.noUrl'              = 'La herramienta no tiene una URL o ruta configurada.'
        'err.notFound'           = 'No se encontró el archivo, la carpeta o la aplicación.'

        # --- Filas y menú ---
        'row.drag.tip'           = 'Arrastra para reordenar, o suelta sobre una etiqueta'
        'row.play.tip'           = 'Abrir ahora (Enter)'
        'row.edit.tip'           = 'Editar (F2)'
        'row.more.tip'           = 'Más acciones'
        'row.tag.tip'            = 'Etiquetar'
        'menu.open'              = 'Abrir'
        'menu.edit'              = 'Editar…'
        'menu.tags'              = 'Etiquetas…'
        'menu.duplicate'         = 'Duplicar'
        'menu.copy'              = 'Copiar ruta o URL'
        'menu.location'          = 'Mostrar en la carpeta'
        'menu.delete'            = 'Eliminar'
        'copy.name'              = '{0} (copia)'

        # --- Etiquetas ---
        'tags.newPlaceholder'    = 'Nueva etiqueta + Enter'
        'tags.noneForm'          = 'Aún no hay etiquetas. Créalas con el botón + de la barra lateral.'
        'tags.none'              = 'Aún no hay etiquetas. Escribe un nombre abajo para crear la primera.'
        'tags.popupTitle'        = 'Etiquetas de {0}'
        'group.newTitle'         = 'Nueva etiqueta'
        'group.editTitle'        = 'Editar etiqueta'
        'group.desc'             = 'Las etiquetas agrupan herramientas (ej. Mañana, Soporte, Reuniones). Una herramienta puede tener varias.'
        'group.name'             = 'Nombre'
        'group.delete'           = 'Eliminar etiqueta'
        'group.created'          = 'Etiqueta «{0}» creada'
        'form.group'             = 'Etiqueta'

        # --- Formulario ---
        'form.addTitle'          = 'Agregar herramienta'
        'form.editTitle'         = 'Editar herramienta'
        'form.name'              = 'Nombre'
        'form.url'               = 'Destino: web, aplicación, archivo, carpeta o protocolo'
        'form.browse.tip'        = 'Examinar archivos'
        'form.tags'              = 'Etiquetas'
        'form.browser'           = 'Navegador'
        'form.profile'           = 'Perfil'
        'form.defaultBrowser'    = 'Predeterminado del sistema'
        'form.defaultProfile'    = 'Perfil predeterminado'
        'form.defaultChecked'    = 'Seleccionada por defecto al iniciar'
        'browse.title'           = 'Seleccionar aplicación, acceso directo o archivo'
        'browse.filterApps'      = 'Aplicaciones y accesos directos'
        'browse.filterAll'       = 'Todos los archivos'
        'browser.notInstalled'   = 'no instalado'
        'kind.none'              = 'Escribe una dirección web, una ruta o un protocolo (ej. msteams:)'
        'kind.web'               = 'Sitio web · {0}'
        'kind.protocol'          = 'Protocolo de aplicación · {0}'
        'kind.network'           = 'Ruta de red · se comprobará al abrirla'
        'kind.folder'            = 'Carpeta'
        'kind.app'               = 'Aplicación · {0}'
        'kind.file'              = 'Archivo'
        'kind.notFound'          = 'No se encuentra en este equipo (se intentará abrir igualmente)'
        'warn.script'            = 'Este destino ejecuta un script con tus permisos. Añádelo solo si confías en su origen.'
        'warn.network'           = 'Este programa está en una ubicación de red. Asegúrate de que es de confianza antes de abrirlo.'

        # --- Soltar archivos ---
        'drop.title'             = 'Suelta para añadir'
        'drop.toGroup'           = 'Se añadirán con la etiqueta «{0}»'
        'drop.any'               = 'Archivos, carpetas, accesos directos o enlaces web'
        'drop.exists'            = 'Ya estaba en la lista'
        'drop.partial'           = '{0} añadida(s), {1} ya existían'
        'drop.many'              = '{0} herramientas añadidas'

        # --- Sugerencias ---
        'sugg.title'             = 'Sugerencias'
        'sugg.desc'              = 'Accesos predefinidos a aplicaciones habituales. Añádelos con un clic o personalízalos antes; después podrás editarlos o eliminarlos como cualquier herramienta.'
        'sugg.add'               = 'Añadir'
        'sugg.added'             = 'Añadida'
        'sugg.customize'         = 'Personalizar antes de añadir'
        'sugg.hide'              = 'Ocultar esta sugerencia'
        'sugg.cat.m365'          = 'Microsoft 365'
        'sugg.cat.google'        = 'Google'
        'sugg.cat.comms'         = 'Comunicación'
        'sugg.cat.work'          = 'Trabajo y desarrollo'
        'sugg.cat.windows'       = 'Windows'
        'sugg.allHidden'         = 'Has ocultado todas las sugerencias.'
        'sugg.footer'            = 'Las aplicaciones de escritorio solo se abrirán si están instaladas. Las marcas pertenecen a sus propietarios.'
        'sugg.restore'           = 'Restaurar ocultas ({0})'
        'sugg.restored'          = 'Sugerencias restauradas'

        # --- Paleta de comandos ---
        'palette.placeholder'    = 'Escribe un comando, una herramienta o una etiqueta…'
        'palette.empty'          = 'Sin coincidencias'
        'palette.footer'         = '↑↓ moverse   ·   Enter ejecutar   ·   Esc cerrar'
        'palette.openTool'       = 'Abrir'
        'palette.showTag'        = 'Ver etiqueta: {0}'
        'palette.tag'            = 'Etiqueta'
        'cmd.openSelected'       = 'Abrir las seleccionadas'
        'cmd.add'                = 'Agregar herramienta'
        'cmd.suggestions'        = 'Ver sugerencias'
        'cmd.newTag'             = 'Nueva etiqueta'
        'cmd.viewAll'            = 'Ver todas las herramientas'
        'cmd.viewSelected'       = 'Ver solo las seleccionadas'
        'cmd.selectAll'          = 'Marcar todas las visibles'
        'cmd.clearSelection'     = 'Desmarcar todas las visibles'
        'cmd.toggleTheme'        = 'Cambiar tema claro / oscuro'
        'cmd.toggleSidebar'      = 'Mostrar u ocultar la barra lateral'
        'cmd.language'           = 'Switch language to English'
        'cmd.settings'           = 'Abrir ajustes'
        'cmd.delay'              = 'Cambiar la pausa entre aperturas'
        'cmd.help'               = 'Ayuda: cómo se usa'
        'cmd.shortcuts'          = 'Ver atajos de teclado'
        'cmd.privacy'            = 'Ver privacidad'
        'cmd.terms'              = 'Ver términos de uso'
        'cmd.export'             = 'Exportar configuración…'
        'cmd.import'             = 'Importar configuración…'
        'cmd.openFolder'         = 'Abrir la carpeta de configuración'

        # --- Ajustes ---
        'settings.title'         = 'Ajustes'
        'settings.nav.general'   = 'General'
        'settings.nav.appearance'= 'Apariencia'
        'settings.nav.launch'    = 'Apertura'
        'settings.nav.data'      = 'Datos y copia'
        'settings.language'      = 'Idioma'
        'settings.language.desc' = 'Idioma de la interfaz en este equipo.'
        'settings.remember'      = 'Recordar la selección'
        'settings.remember.desc' = 'Si se desactiva, cada inicio usa la selección por defecto de cada herramienta.'
        'settings.startup'       = 'Iniciar con Windows'
        'settings.startup.desc'  = 'Crea un acceso directo en tu carpeta de Inicio. Al desactivarlo se elimina.'
        'startup.unavailable'    = 'Disponible solo en DLauncher.exe (no al ejecutar el código fuente).'
        'startup.on'             = 'DLauncher se abrirá al iniciar sesión'
        'startup.off'            = 'Inicio automático desactivado'
        'settings.theme'         = 'Tema'
        'settings.theme.desc'    = '«Sistema» sigue el modo de aplicaciones de Windows.'
        'settings.favicons'      = 'Iconos de sitios web'
        'settings.favicons.desc' = 'Descarga una vez el icono de cada web y lo guarda en caché. Es la única conexión de red de DLauncher.'
        'settings.sidebar'       = 'Barra lateral'
        'settings.sidebar.desc'  = 'Muestra la biblioteca y las etiquetas a la izquierda (Ctrl+B).'
        'settings.delay'         = 'Pausa entre aperturas'
        'settings.delay.desc'    = 'Breve espera entre cada herramienta al abrir varias, para no saturar el equipo.'
        'settings.confirmMany'   = 'Confirmar lotes grandes'
        'settings.confirmMany.desc' = 'Pregunta antes de abrir más de 10 herramientas a la vez.'
        'settings.launch.note'   = 'Las herramientas se abren en el orden de la lista. Arrastra las filas por su asa ⋮⋮ para cambiarlo.'
        'settings.location'      = 'Carpeta de configuración'
        'settings.location.desc' = 'Aquí están config.json y su copia de seguridad automática (config.json.bak).'
        'settings.noFolder'      = 'Aún no se ha elegido una carpeta'
        'settings.openFolder'    = 'Abrir carpeta'
        'settings.changeFolder'  = 'Cambiar…'
        'settings.share'         = 'Compartir configuración'
        'settings.share.desc'    = 'Exporta herramientas y etiquetas a un archivo, o importa el de un compañero. Lo importado llega sin seleccionar.'
        'settings.export.tip'    = 'Guardar etiquetas y herramientas en un archivo'
        'settings.export.label'  = 'Exportar…'
        'settings.import.tip'    = 'Añadir etiquetas y herramientas desde un archivo exportado'
        'settings.import.label'  = 'Importar…'
        'settings.maintenance'   = 'Mantenimiento'
        'settings.clearCache'    = 'Borrar iconos en caché'
        'settings.danger'        = 'Eliminar todas las herramientas'
        'settings.danger.desc'   = 'Las etiquetas se conservan. Podrás deshacerlo justo después.'
        'settings.autosave'      = 'Los cambios se guardan automáticamente.'

        # --- Exportar / importar / carpeta ---
        'export.title'           = 'Exportar configuración de DLauncher'
        'export.filter'          = 'Configuración de DLauncher'
        'export.done'            = 'Configuración exportada'
        'export.errorTitle'      = 'No se pudo exportar'
        'import.title'           = 'Importar configuración de DLauncher'
        'import.doneTitle'       = 'Importación completada'
        'import.doneBody'        = "Herramientas añadidas: {0}`nDuplicadas omitidas: {1}`nEtiquetas nuevas: {2}"
        'import.unselected'      = 'Las herramientas importadas llegan sin seleccionar: revísalas antes de abrirlas.'
        'import.codeWarning'     = 'Atención: {0} de ellas abren programas o scripts. Ábrelas solo si confías en quien te pasó el archivo.'
        'import.errorTitle'      = 'No se pudo importar'
        'import.invalid'         = 'El archivo no tiene un formato de configuración de DLauncher válido.'
        'folder.desc'            = 'Selecciona la carpeta donde guardar la configuración de DLauncher'
        'folder.loadedTitle'     = 'Configuración cargada'
        'folder.loadedBody'      = 'Se ha encontrado y cargado la configuración existente en la carpeta seleccionada.'
        'folder.createdTitle'    = 'Nueva configuración creada'
        'folder.createdBody'     = 'Se ha creado una configuración nueva en la carpeta seleccionada.'
        'clearAll.title'         = 'Eliminar todas las herramientas'
        'clearAll.body'          = 'Se eliminarán todas las herramientas de la lista. Las etiquetas se conservan y podrás deshacerlo desde el aviso que aparecerá.'
        'clearAll.ok'            = 'Eliminar todo'

        # --- Avisos de configuración ---
        'notice.restored.title'  = 'Configuración recuperada'
        'notice.restored.body'   = "config.json estaba dañado y se ha recuperado la última copia de seguridad.`n`nSe guardó una copia del archivo dañado por si la necesitas:`n{0}"
        'notice.reset.title'     = 'Configuración dañada'
        'notice.reset.body'      = "config.json estaba dañado y no había copia de seguridad válida, así que se ha empezado una configuración nueva.`n`nEl archivo original se conserva en:`n{0}"
        'notice.locked.title'    = 'Configuración en uso'
        'notice.locked.body'     = "No se pudo leer o guardar config.json (puede estar bloqueado por OneDrive u otro programa). Para no perder datos, DLauncher no escribirá en él hasta que vuelva a estar disponible.`n`nDetalle: {0}"
        'notice.saveFailed.title'= 'No se pudo guardar'
        'notice.saveFailed.body' = "No se pudieron guardar los cambios en la carpeta de configuración.`n`nDetalle: {0}"
        'notice.missing.title'   = 'No se encuentra tu carpeta de configuración'
        'notice.missing.body'    = "DLauncher no encuentra la carpeta donde se guarda tu lista:`n{0}`n`n• Si la has movido o renombrado, elige su nueva ubicación.`n• Si está en una unidad de red o en la nube, comprueba la conexión: DLauncher la cargará sola en cuanto vuelva a estar disponible.`n`nNo se ha borrado ni creado nada."
        'missing.choose'         = 'Elegir carpeta…'
        'missing.later'          = 'Ahora no'

        # --- Bienvenida y términos ---
        'setup.title'            = 'Te damos la bienvenida a DLauncher'
        'setup.body'             = 'Tu lanzador diario: abre las aplicaciones, webs y archivos que usas cada día, todos a la vez o uno a uno.'
        'setup.language'         = 'Idioma'
        'setup.theme'            = 'Tema'
        'setup.folderInfo'       = 'Elige una carpeta para guardar tu configuración (config.json). Si usas una carpeta sincronizada como OneDrive, la tendrás en todos tus equipos.'
        'setup.accept'           = 'He leído y acepto los Términos de uso y el Aviso de privacidad.'
        'setup.readTerms'        = 'Términos de uso'
        'setup.readPrivacy'      = 'Privacidad'
        'setup.readWarnings'     = 'Advertencias'
        'setup.select'           = 'Elegir carpeta de configuración'
        'setup.loadedBody'       = 'Se ha encontrado y cargado tu archivo de configuración existente.'
        'terms.title'            = 'Términos de uso y privacidad'
        'terms.body'             = 'Esta versión incorpora términos de uso, aviso de privacidad y advertencias. En resumen: DLauncher funciona en tu equipo, no recopila datos y tú decides qué se abre. Revísalos y acéptalos para continuar.'
        'terms.exit'             = 'Salir'
        'terms.accept'           = 'Aceptar y continuar'

        # --- Ayuda ---
        'help.title'             = 'Ayuda'
        'help.nav.faq'           = 'Cómo se usa'
        'help.nav.icons'         = 'Iconos'
        'help.nav.keys'          = 'Atajos de teclado'
        'help.nav.legal'         = 'LEGAL'
        'help.nav.privacy'       = 'Privacidad'
        'help.nav.warnings'      = 'Advertencias'
        'help.nav.terms'         = 'Términos de uso'
        'help.nav.disclaimer'    = 'Responsabilidad'
        'help.nav.about'         = 'Acerca de'
        'info.version'           = 'Versión {0}'

        'faq.intro'              = 'Respuestas rápidas a las dudas más habituales.'
        'faq.q1'                 = '¿Cómo añado una herramienta?'
        'faq.a1'                 = 'Pulsa «Agregar herramienta» (Ctrl+N), arrastra archivos, carpetas, accesos directos o enlaces del navegador a la ventana, o elige una en Sugerencias.'
        'faq.q2'                 = '¿Qué puedo abrir?'
        'faq.a2'                 = 'Webs (https://…), aplicaciones (.exe, .lnk), scripts (.bat, .cmd), archivos, carpetas, rutas de red (\\servidor\recurso) y protocolos como msteams:, mailto: o ms-settings:. Admite variables como %USERPROFILE%.'
        'faq.q3'                 = '¿Cómo abro varias a la vez?'
        'faq.a3'                 = 'Marca las que quieras y pulsa Abrir (Ctrl+Enter). Se abren una a una con la pausa que elijas en Ajustes → Apertura, para que el equipo no se sature.'
        'faq.q4'                 = '¿Para qué sirven las etiquetas?'
        'faq.a4'                 = 'Para agrupar herramientas (ej. Mañana, Soporte, Reuniones). Una herramienta puede tener varias. Elige una etiqueta en la barra lateral para ver solo sus herramientas; el botón ▶ junto a la etiqueta las abre todas.'
        'faq.q5'                 = '¿Cómo etiqueto una herramienta?'
        'faq.a5'                 = 'Con el botón de etiqueta de la fila, arrastrando la fila (asa ⋮⋮) sobre una etiqueta de la barra lateral, o eligiendo etiquetas en el formulario de edición.'
        'faq.q6'                 = '¿Puedo abrir una web en un navegador o perfil concreto?'
        'faq.a6'                 = 'Sí. Al editar una web, elige navegador y perfil (ej. Trabajo). Si ese navegador no está instalado en otro equipo, se usará el predeterminado.'
        'faq.q7'                 = '¿Cómo funcionan las sugerencias?'
        'faq.a7'                 = 'Son accesos predefinidos a aplicaciones habituales (Outlook, Teams, Gmail…). Añádelos con un clic o personalízalos antes. Una vez añadidos son herramientas normales: puedes editarlas o eliminarlas. Oculta las que no necesites; se restauran en Ajustes → Datos y copia.'
        'faq.q8'                 = 'He eliminado algo por error'
        'faq.a8'                 = 'Pulsa «Deshacer» en el aviso que aparece, o Ctrl+Z justo después. Además, DLauncher guarda una copia de seguridad automática (config.json.bak).'
        'faq.q9'                 = '¿Cómo uso DLauncher en varios equipos?'
        'faq.a9'                 = 'Elige una carpeta compartida entre tus equipos (tu unidad de red, OneDrive…) como carpeta de configuración, o usa Exportar/Importar. Si DLauncher está abierto en varios equipos, la lista se actualiza sola con los cambios de los demás. El idioma, el tema y el tamaño de la ventana se guardan en cada equipo.'
        'faq.q10'                = '¿Qué es la paleta de comandos?'
        'faq.a10'                = 'Pulsa Ctrl+K y escribe: ejecuta cualquier acción, abre una herramienta o salta a una etiqueta sin usar el ratón.'
        'faq.q11'                = '¿Puede iniciarse con Windows?'
        'faq.a11'                = 'Sí, en Ajustes → General (solo en DLauncher.exe). Crea un acceso directo en tu carpeta de Inicio; al desactivarlo se elimina.'
        'faq.q12'                = '¿Dónde están mis datos y cómo los borro?'
        'faq.a12'                = 'Consulta Privacidad. En resumen: tu carpeta de configuración y %LOCALAPPDATA%\DLauncher. No se instala nada más.'

        'icons.intro'            = 'Qué significa cada icono de DLauncher.'
        'icons.play.t'           = 'Abrir ahora'
        'icons.play.d'           = 'Abre esa herramienta al instante. También con doble clic en la fila o Enter.'
        'icons.edit.t'           = 'Editar'
        'icons.edit.d'           = 'Cambia nombre, destino, etiquetas, navegador o la selección por defecto.'
        'icons.more.t'           = 'Más acciones'
        'icons.more.d'           = 'Duplicar, copiar la ruta o URL, mostrar en la carpeta o eliminar. También con clic derecho en la fila.'
        'icons.tag.t'            = 'Etiquetar'
        'icons.tag.d'            = 'Asigna o crea etiquetas para la herramienta.'
        'icons.grip.t'           = 'Asa de arrastre'
        'icons.grip.d'           = 'Arrastra para reordenar, o suelta sobre una etiqueta de la barra lateral para etiquetar.'
        'icons.check.t'          = 'Selección'
        'icons.check.d'          = 'Las herramientas marcadas se abren juntas con Abrir (Ctrl+Enter).'
        'icons.letter.t'         = 'Inicial'
        'icons.letter.d'         = 'Se muestra cuando no hay icono disponible (protocolos, archivos que no se encuentran…).'
        'icons.favicon.t'        = 'Sitio web'
        'icons.favicon.d'        = 'Las webs muestran su propio icono, descargado una vez y guardado en caché.'
        'icons.folder.t'         = 'Carpeta'
        'icons.folder.d'         = 'Carpetas locales y ubicaciones de red.'
        'icons.browser.t'        = 'Navegador y perfil'
        'icons.browser.d'        = 'Indica el navegador (y perfil) con el que se abre esa web.'
        'icons.tagdot.t'         = 'Color de etiqueta'
        'icons.tagdot.d'         = 'Cada etiqueta conserva su color en toda la aplicación.'
        'icons.sparkle.t'        = 'Sugerencias'
        'icons.sparkle.d'        = 'Aplicaciones habituales predefinidas para añadir con un clic.'
        'icons.clock.t'          = 'Pausa entre aperturas'
        'icons.clock.d'          = 'Espera entre cada herramienta al abrir varias. Haz clic para cambiarla.'
        'icons.command.t'        = 'Paleta de comandos'
        'icons.command.d'        = 'Ctrl+K: acciones, herramientas y etiquetas escribiendo.'
        'icons.theme.t'          = 'Tema'
        'icons.theme.d'          = 'Cambia entre claro y oscuro.'
        'icons.sidebar.t'        = 'Barra lateral'
        'icons.sidebar.d'        = 'Muestra u oculta la barra lateral (Ctrl+B).'
        'icons.warning.t'        = 'Advertencia'
        'icons.warning.d'        = 'Aparece cuando un destino ejecuta un script o un programa desde la red.'
        'icons.status.t'         = 'Estado'
        'icons.status.d'         = 'Verde: listo · Azul: abriendo · Amarillo: configuración en uso o de solo lectura.'

        'keys.intro'             = 'Todo DLauncher se puede usar con el teclado.'
        'keys.palette'           = 'Paleta de comandos'
        'keys.search'            = 'Buscar (o simplemente empieza a escribir)'
        'keys.move'              = 'Moverse por la lista'
        'keys.open'              = 'Abrir la herramienta resaltada'
        'keys.openSel'           = 'Abrir las seleccionadas'
        'keys.toggle'            = 'Marcar / desmarcar la herramienta resaltada'
        'keys.add'               = 'Agregar herramienta'
        'keys.edit'              = 'Editar la herramienta resaltada'
        'keys.duplicate'         = 'Duplicar la herramienta resaltada'
        'keys.delete'            = 'Eliminar la herramienta resaltada (se puede deshacer)'
        'keys.undo'              = 'Deshacer la última eliminación'
        'keys.sidebar'           = 'Mostrar / ocultar la barra lateral'
        'keys.settings'          = 'Ajustes'
        'keys.help'              = 'Ayuda'
        'keys.esc'               = 'Limpiar la búsqueda / cerrar paneles'
        'keys.dblclick.k'        = 'Doble clic'
        'keys.dblclick'          = 'Abrir una herramienta · renombrar una etiqueta'
        'keys.rightclick.k'      = 'Clic derecho'
        'keys.rightclick'        = 'Menú de la herramienta'
        'keys.typing.k'          = 'Escribir'
        'keys.typing'            = 'Empezar a buscar desde cualquier parte'

        'about.body'             = @'
Un lanzador diario para tus aplicaciones, webs y archivos de trabajo: anota lo que usas cada día, organízalo con etiquetas y ábrelo todo con un clic.

• Sin instalación ni dependencias: un único .exe para Windows 10 y 11.
• Hecho con PowerShell, WPF y .NET Framework, incluidos en Windows.
• Tus datos se quedan en tu equipo.
• Gratuito y de código abierto, con licencia MIT: github.com/montesito/dlauncher
'@

        'legal.updated'          = 'Última actualización: 26 de noviembre de 2026'

        'legal.privacy'          = @'
## Resumen
DLauncher funciona por completo en tu equipo. No tiene cuentas, analíticas, publicidad ni telemetría. El desarrollador no recibe ninguno de tus datos.

## Qué se guarda y dónde
• Tus herramientas, etiquetas y ajustes: config.json en la carpeta que elegiste, junto con una copia de seguridad automática (config.json.bak).
• Preferencias de este equipo (idioma, tema, tamaño de ventana y aceptación de los términos): %LOCALAPPDATA%\DLauncher\prefs.json.
• Iconos de sitios web: %LOCALAPPDATA%\DLauncher\IconCache.
• Solo si lo activas: un acceso directo en tu carpeta de Inicio de Windows.

## Conexiones de red
DLauncher solo se conecta a Internet para descargar los iconos de las webs: una vez por cada web de tu lista, solicita su página principal y su icono, como haría un navegador. Las peticiones van directamente a esa web, sin intermediarios. Puedes desactivarlo en Ajustes → Apariencia → Iconos de sitios web.
Al abrir una web, lo hace tu navegador, con su propia política de privacidad.

## Compartir
Al exportar se crea un archivo que tú decides con quién compartir. Si tu carpeta de configuración está en una ubicación sincronizada (OneDrive, una unidad de red…), se rige por las condiciones de ese servicio.

## Borrar tus datos
Elimina tu carpeta de configuración y %LOCALAPPDATA%\DLauncher. DLauncher no instala nada más en tu equipo.
'@

        'legal.warnings'         = @'
## Antes de usarlo
• DLauncher abre lo que configuras con tus propios permisos de usuario. Los programas y scripts (.exe, .bat, .cmd, .ps1, .vbs…) se ejecutan igual que si hicieras doble clic en ellos: añade solo los que sean de confianza.
• Importa archivos de configuración solo de personas y fuentes de confianza. Lo importado llega sin seleccionar para que puedas revisarlo antes de abrirlo.
• Abrir muchas herramientas a la vez consume memoria y procesador. Usa la pausa entre aperturas (Ajustes → Apertura) y la confirmación de lotes grandes.
• Respeta las políticas de tu organización: algunas empresas restringen la ejecución de programas o scripts no firmados.
• El ejecutable no está firmado digitalmente, por lo que Windows SmartScreen puede mostrar un aviso la primera vez. También puedes compilarlo tú desde el código fuente.
• Las rutas de red no se comprueban mientras navegas por la lista, para que la aplicación no se bloquee; si un recurso de red no está disponible, el error aparecerá al abrirlo.
• Guarda una copia de tu configuración (Ajustes → Datos y copia → Exportar) si es importante para ti.
'@

        'legal.terms'            = @'
## 1. Aceptación
Al usar DLauncher aceptas estos términos. Si no estás de acuerdo, no uses la aplicación.

## 2. Qué es DLauncher
Una utilidad personal de productividad que abre las aplicaciones, webs, archivos, carpetas y protocolos que tú configuras. Se ofrece de forma gratuita.

## 3. Tu responsabilidad
• Tú decides qué añadir y qué abrir, y eres responsable de ese uso y de sus consecuencias.
• Debes tener derecho a usar el software y los servicios que abres, y cumplir sus licencias y condiciones.
• Debes respetar las normas de tu organización y la legislación aplicable.

## 4. Marcas de terceros
Nombres como Outlook, Teams, Word, Excel, Gmail, Slack o GitHub son marcas de sus respectivos propietarios. Aparecen solo como accesos sugeridos; DLauncher no está afiliado a ellos ni cuenta con su respaldo. Los iconos de las webs pertenecen a cada sitio.

## 5. Sin garantía
DLauncher se proporciona «tal cual», sin garantías de ningún tipo, expresas ni implícitas, incluidas la idoneidad para un fin concreto, la disponibilidad o la ausencia de errores.

## 6. Cambios
Estos términos pueden actualizarse en versiones futuras. Si cambian, la aplicación te pedirá que vuelvas a aceptarlos.
'@

        'legal.disclaimer'       = @'
## Limitación de responsabilidad
En la medida máxima permitida por la ley, el desarrollador no se hace responsable de ninguna pérdida de datos, configuración, tiempo o ingresos, ni de ningún otro daño directo o indirecto derivado del uso o de la imposibilidad de usar DLauncher, ni de los programas, scripts o webs que se abran con él.

## No intrusivo por diseño
DLauncher no instala controladores ni servicios, no modifica la configuración del sistema, no se queda en segundo plano al cerrarlo y no necesita permisos de administrador. Solo escribe sus propios archivos (configuración, copia de seguridad, preferencias y caché de iconos) y, si lo activas, un acceso directo de inicio. Al borrar esos archivos, tu equipo queda como estaba.

## Recomendaciones
• Exporta tu configuración de vez en cuando.
• Usa Deshacer (Ctrl+Z) justo después de eliminar algo por error.
• Si config.json se daña, DLauncher conserva una copia del archivo y recupera automáticamente la última copia de seguridad.

Nada de lo anterior limita los derechos que la legislación aplicable no permita excluir.
'@
    }

    en = @{
        # --- Common ---
        'common.cancel'          = 'Cancel'
        'common.save'            = 'Save'
        'common.accept'          = 'OK'
        'common.continue'        = 'Continue'
        'common.delete'          = 'Delete'
        'common.done'            = 'Done'
        'common.undo'            = 'Undo'
        'close.tip'              = 'Close (Esc)'

        # --- Title bar ---
        'hdr.sidebar.tip'        = 'Show or hide the sidebar (Ctrl+B)'
        'hdr.theme.tip'          = 'Switch between light and dark theme'
        'hdr.help.tip'           = 'Help, icons, shortcuts and legal (F1)'
        'hdr.settings.tip'       = 'Settings (Ctrl+,)'
        'hdr.min.tip'            = 'Minimize'
        'hdr.close.tip'          = 'Close'
        'search.placeholder'     = 'Search tools, websites or files'
        'search.clear.tip'       = 'Clear (Esc)'
        'search.palette.tip'     = 'Command palette'

        # --- Sidebar ---
        'add.tip'                = 'Add tool (Ctrl+N). You can also drop files or links onto the window'
        'add.label'              = 'Add tool'
        'add.header.tip'         = 'Add tool (Ctrl+N)'
        'add.short'              = 'Add'
        'side.library'           = 'LIBRARY'
        'side.tags'              = 'TAGS'
        'side.newTag.tip'        = 'New tag'
        'side.tagsEmpty'         = 'Group your tools (Morning, Support, Meetings…) with the + button.'
        'side.all'               = 'All'
        'side.selected'          = 'Selected'
        'side.suggestions'       = 'Suggestions'
        'side.help'              = 'Help'
        'side.settings'          = 'Settings'
        'side.tag.tip'           = 'Click: filter · Double-click: rename · Drop a tool here to tag it'
        'side.openTag.tip'       = 'Open every tool with this tag'

        # --- View ---
        'view.all'               = 'All tools'
        'view.selected'          = 'Selected'
        'view.subtitle'          = '{0} tools · {1} selected'
        'toggleAll.tip'          = 'Select or deselect all visible tools'
        'toggle.select'          = 'Select all'
        'toggle.clear'           = 'Deselect all'

        # --- Empty states ---
        'empty.title'            = 'Your daily launcher is ready'
        'empty.body'             = 'Add the apps, websites and files you use every day and open them all with one click. Start with the suggestions, or drop items from File Explorer or your browser.'
        'empty.ctaSuggestions'   = 'Browse suggestions'
        'empty.cta'              = 'Add tool'
        'empty.hint'             = 'Tip: press Ctrl+K to open the command palette'
        'noresults.title'        = 'No results'
        'noresults.body'         = 'No tools match "{0}".'
        'emptygroup.title'       = 'No tools with this tag'
        'emptygroup.body'        = 'Drag a tool (by its ⋮⋮ handle) onto the tag in the sidebar, or use the tag button on each row.'
        'emptysel.title'         = 'Nothing selected'
        'emptysel.body'          = 'Tick the tools you want to open together.'

        # --- Action bar ---
        'status.selected'        = '{0} of {1} selected'
        'open'                   = 'Open'
        'open.group'             = 'Open {0}'
        'openAll.tip'            = 'Open the selected tools (Ctrl+Enter)'
        'open.progress'          = 'Opening {0}/{1}…'
        'delay.button.tip'       = 'Pause between each launch. Click to change it'
        'delay.status'           = '{0} between launches'
        'delay.0'                = 'No pause'
        'delay.250'              = '0.25 s'
        'delay.500'              = '0.5 s'
        'delay.1000'             = '1 s'
        'delay.2000'             = '2 s'
        'delay.3000'             = '3 s'
        'delay.5000'             = '5 s'

        # --- Status bar ---
        'statusbar.ready'        = 'Ready · {0} tools'
        'statusbar.noFolder'     = 'No configuration folder'
        'statusbar.missing'      = 'Configuration folder not found'
        'statusbar.readonly'     = 'Configuration in use by another program: changes are not saved'
        'statusbar.launching'    = 'Opening {0} of {1} · {2}'
        'status.folder.tip'      = 'Configuration folder (click to open it)'
        'status.language.tip'    = 'Change language'
        'status.theme.tip'       = 'Theme (click for appearance settings)'
        'theme.system'           = 'System'
        'theme.dark'             = 'Dark'
        'theme.light'            = 'Light'

        # --- Toasts ---
        'toast.opening'          = 'Opening {0}'
        'toast.noneSelected'     = 'No tools selected'
        'toast.tagEmpty'         = 'This tag has no tools'
        'toast.doneOne'          = 'Done: 1 tool opened'
        'toast.doneMany'         = 'Done: {0} tools opened'
        'toast.added'            = '"{0}" added'
        'toast.saved'            = 'Changes saved'
        'toast.deleted'          = '"{0}" deleted'
        'toast.duplicated'       = '"{0}" created'
        'toast.copied'           = 'Copied to clipboard'
        'toast.copyFailed'       = 'Could not use the clipboard'
        'toast.restored'         = 'Changes undone'
        'toast.reloaded'         = 'List updated with changes from another PC'
        'toast.folderBack'       = 'The configuration folder is available again'
        'toast.tagged'           = '"{0}" tagged as {1}'
        'toast.alreadyTagged'    = '"{0}" already had that tag'
        'toast.tagDeleted'       = 'Tag "{0}" deleted'
        'toast.clearedAll'       = 'All tools were deleted'
        'toast.imported'         = '{0} tools imported'
        'toast.cacheCleared'     = 'Icons cleared: they will be downloaded again'
        'drag.hint'              = 'Drop on a tag to assign it, or in the list to reorder'
        'many.title'             = 'Open many at once?'
        'many.body'              = 'You are about to open {0} tools. They open one by one with the configured pause, but they may use a lot of memory.'
        'many.ok'                = 'Open {0}'
        'batch.errorsTitle'      = 'Some could not be opened'
        'batch.errorsBody'       = '{0} of {1} were opened.'
        'err.title'              = 'Could not open'
        'err.body'               = "Could not open ""{0}"".`n`nDetails: {1}`n`nTarget: {2}"
        'err.noUrl'              = 'This tool has no URL or path configured.'
        'err.notFound'           = 'The file, folder or application was not found.'

        # --- Rows and menu ---
        'row.drag.tip'           = 'Drag to reorder, or drop onto a tag'
        'row.play.tip'           = 'Open now (Enter)'
        'row.edit.tip'           = 'Edit (F2)'
        'row.more.tip'           = 'More actions'
        'row.tag.tip'            = 'Tag'
        'menu.open'              = 'Open'
        'menu.edit'              = 'Edit…'
        'menu.tags'              = 'Tags…'
        'menu.duplicate'         = 'Duplicate'
        'menu.copy'              = 'Copy path or URL'
        'menu.location'          = 'Show in folder'
        'menu.delete'            = 'Delete'
        'copy.name'              = '{0} (copy)'

        # --- Tags ---
        'tags.newPlaceholder'    = 'New tag + Enter'
        'tags.noneForm'          = 'No tags yet. Create them with the + button in the sidebar.'
        'tags.none'              = 'No tags yet. Type a name below to create the first one.'
        'tags.popupTitle'        = 'Tags for {0}'
        'group.newTitle'         = 'New tag'
        'group.editTitle'        = 'Edit tag'
        'group.desc'             = 'Tags group your tools (e.g. Morning, Support, Meetings). A tool can have several.'
        'group.name'             = 'Name'
        'group.delete'           = 'Delete tag'
        'group.created'          = 'Tag "{0}" created'
        'form.group'             = 'Tag'

        # --- Form ---
        'form.addTitle'          = 'Add tool'
        'form.editTitle'         = 'Edit tool'
        'form.name'              = 'Name'
        'form.url'               = 'Target: website, app, file, folder or protocol'
        'form.browse.tip'        = 'Browse files'
        'form.tags'              = 'Tags'
        'form.browser'           = 'Browser'
        'form.profile'           = 'Profile'
        'form.defaultBrowser'    = 'System default'
        'form.defaultProfile'    = 'Default profile'
        'form.defaultChecked'    = 'Selected by default on startup'
        'browse.title'           = 'Select an application, shortcut or file'
        'browse.filterApps'      = 'Applications and shortcuts'
        'browse.filterAll'       = 'All files'
        'browser.notInstalled'   = 'not installed'
        'kind.none'              = 'Type a web address, a path or a protocol (e.g. msteams:)'
        'kind.web'               = 'Website · {0}'
        'kind.protocol'          = 'App protocol · {0}'
        'kind.network'           = 'Network path · checked when opened'
        'kind.folder'            = 'Folder'
        'kind.app'               = 'Application · {0}'
        'kind.file'              = 'File'
        'kind.notFound'          = 'Not found on this PC (it will still try to open it)'
        'warn.script'            = 'This target runs a script with your permissions. Only add it if you trust where it came from.'
        'warn.network'           = 'This program is on a network location. Make sure it is trustworthy before opening it.'

        # --- Drop ---
        'drop.title'             = 'Drop to add'
        'drop.toGroup'           = 'They will be added with the tag "{0}"'
        'drop.any'               = 'Files, folders, shortcuts or web links'
        'drop.exists'            = 'Already in the list'
        'drop.partial'           = '{0} added, {1} already existed'
        'drop.many'              = '{0} tools added'

        # --- Suggestions ---
        'sugg.title'             = 'Suggestions'
        'sugg.desc'              = 'Predefined shortcuts to common apps. Add them in one click or customize them first; afterwards you can edit or delete them like any other tool.'
        'sugg.add'               = 'Add'
        'sugg.added'             = 'Added'
        'sugg.customize'         = 'Customize before adding'
        'sugg.hide'              = 'Hide this suggestion'
        'sugg.cat.m365'          = 'Microsoft 365'
        'sugg.cat.google'        = 'Google'
        'sugg.cat.comms'         = 'Communication'
        'sugg.cat.work'          = 'Work and development'
        'sugg.cat.windows'       = 'Windows'
        'sugg.allHidden'         = 'You have hidden every suggestion.'
        'sugg.footer'            = 'Desktop apps only open if they are installed. Trademarks belong to their owners.'
        'sugg.restore'           = 'Restore hidden ({0})'
        'sugg.restored'          = 'Suggestions restored'

        # --- Command palette ---
        'palette.placeholder'    = 'Type a command, a tool or a tag…'
        'palette.empty'          = 'No matches'
        'palette.footer'         = '↑↓ navigate   ·   Enter run   ·   Esc close'
        'palette.openTool'       = 'Open'
        'palette.showTag'        = 'Show tag: {0}'
        'palette.tag'            = 'Tag'
        'cmd.openSelected'       = 'Open selected tools'
        'cmd.add'                = 'Add tool'
        'cmd.suggestions'        = 'Browse suggestions'
        'cmd.newTag'             = 'New tag'
        'cmd.viewAll'            = 'Show all tools'
        'cmd.viewSelected'       = 'Show only selected tools'
        'cmd.selectAll'          = 'Select all visible tools'
        'cmd.clearSelection'     = 'Deselect all visible tools'
        'cmd.toggleTheme'        = 'Toggle light / dark theme'
        'cmd.toggleSidebar'      = 'Show or hide the sidebar'
        'cmd.language'           = 'Cambiar idioma a español'
        'cmd.settings'           = 'Open settings'
        'cmd.delay'              = 'Change the pause between launches'
        'cmd.help'               = 'Help: how to use it'
        'cmd.shortcuts'          = 'Show keyboard shortcuts'
        'cmd.privacy'            = 'Show privacy notice'
        'cmd.terms'              = 'Show terms of use'
        'cmd.export'             = 'Export configuration…'
        'cmd.import'             = 'Import configuration…'
        'cmd.openFolder'         = 'Open the configuration folder'

        # --- Settings ---
        'settings.title'         = 'Settings'
        'settings.nav.general'   = 'General'
        'settings.nav.appearance'= 'Appearance'
        'settings.nav.launch'    = 'Launching'
        'settings.nav.data'      = 'Data & backup'
        'settings.language'      = 'Language'
        'settings.language.desc' = 'Interface language on this computer.'
        'settings.remember'      = 'Remember selection'
        'settings.remember.desc' = 'When off, every start uses each tool''s default selection.'
        'settings.startup'       = 'Start with Windows'
        'settings.startup.desc'  = 'Creates a shortcut in your Startup folder. Turning it off removes it.'
        'startup.unavailable'    = 'Only available in DLauncher.exe (not when running from source).'
        'startup.on'             = 'DLauncher will open when you sign in'
        'startup.off'            = 'Start with Windows turned off'
        'settings.theme'         = 'Theme'
        'settings.theme.desc'    = '"System" follows the Windows app mode.'
        'settings.favicons'      = 'Website icons'
        'settings.favicons.desc' = 'Downloads each website''s icon once and caches it. This is DLauncher''s only network connection.'
        'settings.sidebar'       = 'Sidebar'
        'settings.sidebar.desc'  = 'Shows the library and tags on the left (Ctrl+B).'
        'settings.delay'         = 'Pause between launches'
        'settings.delay.desc'    = 'A brief wait between each tool when opening several, so your PC is not overloaded.'
        'settings.confirmMany'   = 'Confirm large batches'
        'settings.confirmMany.desc' = 'Asks before opening more than 10 tools at once.'
        'settings.launch.note'   = 'Tools open in list order. Drag rows by their ⋮⋮ handle to change it.'
        'settings.location'      = 'Configuration folder'
        'settings.location.desc' = 'Holds config.json and its automatic backup (config.json.bak).'
        'settings.noFolder'      = 'No folder chosen yet'
        'settings.openFolder'    = 'Open folder'
        'settings.changeFolder'  = 'Change…'
        'settings.share'         = 'Share configuration'
        'settings.share.desc'    = 'Export tools and tags to a file, or import a teammate''s. Imported tools arrive unselected.'
        'settings.export.tip'    = 'Save tags and tools to a file'
        'settings.export.label'  = 'Export…'
        'settings.import.tip'    = 'Add tags and tools from an exported file'
        'settings.import.label'  = 'Import…'
        'settings.maintenance'   = 'Maintenance'
        'settings.clearCache'    = 'Clear cached icons'
        'settings.danger'        = 'Delete all tools'
        'settings.danger.desc'   = 'Tags are kept. You can undo it right afterwards.'
        'settings.autosave'      = 'Changes are saved automatically.'

        # --- Export / import / folder ---
        'export.title'           = 'Export DLauncher configuration'
        'export.filter'          = 'DLauncher configuration'
        'export.done'            = 'Configuration exported'
        'export.errorTitle'      = 'Export failed'
        'import.title'           = 'Import DLauncher configuration'
        'import.doneTitle'       = 'Import complete'
        'import.doneBody'        = "Tools added: {0}`nDuplicates skipped: {1}`nNew tags: {2}"
        'import.unselected'      = 'Imported tools arrive unselected: review them before opening.'
        'import.codeWarning'     = 'Heads up: {0} of them open programs or scripts. Only open them if you trust whoever gave you the file.'
        'import.errorTitle'      = 'Import failed'
        'import.invalid'         = 'The file is not a valid DLauncher configuration.'
        'folder.desc'            = 'Select the folder where DLauncher will store its configuration'
        'folder.loadedTitle'     = 'Configuration loaded'
        'folder.loadedBody'      = 'An existing configuration was found and loaded from the selected folder.'
        'folder.createdTitle'    = 'New configuration created'
        'folder.createdBody'     = 'A new configuration was created in the selected folder.'
        'clearAll.title'         = 'Delete all tools'
        'clearAll.body'          = 'Every tool in the list will be deleted. Tags are kept, and you can undo it from the notification that appears.'
        'clearAll.ok'            = 'Delete all'

        # --- Configuration notices ---
        'notice.restored.title'  = 'Configuration recovered'
        'notice.restored.body'   = "config.json was damaged and the latest backup has been restored.`n`nA copy of the damaged file was kept in case you need it:`n{0}"
        'notice.reset.title'     = 'Configuration damaged'
        'notice.reset.body'      = "config.json was damaged and there was no valid backup, so a new configuration was started.`n`nThe original file is kept at:`n{0}"
        'notice.locked.title'    = 'Configuration in use'
        'notice.locked.body'     = "config.json could not be read or saved (it may be locked by OneDrive or another program). To avoid data loss, DLauncher won't write to it until it is available again.`n`nDetails: {0}"
        'notice.saveFailed.title'= 'Could not save'
        'notice.saveFailed.body' = "Changes could not be saved to the configuration folder.`n`nDetails: {0}"
        'notice.missing.title'   = 'Your configuration folder cannot be found'
        'notice.missing.body'    = "DLauncher cannot find the folder where your list is saved:`n{0}`n`n• If you moved or renamed it, choose its new location.`n• If it is on a network drive or in the cloud, check your connection: DLauncher will load it automatically as soon as it is available again.`n`nNothing has been deleted or created."
        'missing.choose'         = 'Choose folder…'
        'missing.later'          = 'Not now'

        # --- Welcome and terms ---
        'setup.title'            = 'Welcome to DLauncher'
        'setup.body'             = 'Your daily launcher: open the apps, websites and files you use every day, all at once or one by one.'
        'setup.language'         = 'Language'
        'setup.theme'            = 'Theme'
        'setup.folderInfo'       = 'Choose a folder to store your configuration (config.json). A synced folder such as OneDrive keeps it on all your computers.'
        'setup.accept'           = 'I have read and accept the Terms of use and the Privacy notice.'
        'setup.readTerms'        = 'Terms of use'
        'setup.readPrivacy'      = 'Privacy'
        'setup.readWarnings'     = 'Warnings'
        'setup.select'           = 'Choose configuration folder'
        'setup.loadedBody'       = 'Your existing configuration file was found and loaded.'
        'terms.title'            = 'Terms of use and privacy'
        'terms.body'             = 'This version adds terms of use, a privacy notice and warnings. In short: DLauncher works on your computer, collects no data, and you decide what it opens. Please review and accept them to continue.'
        'terms.exit'             = 'Exit'
        'terms.accept'           = 'Accept and continue'

        # --- Help ---
        'help.title'             = 'Help'
        'help.nav.faq'           = 'How to'
        'help.nav.icons'         = 'Icons'
        'help.nav.keys'          = 'Keyboard shortcuts'
        'help.nav.legal'         = 'LEGAL'
        'help.nav.privacy'       = 'Privacy'
        'help.nav.warnings'      = 'Warnings'
        'help.nav.terms'         = 'Terms of use'
        'help.nav.disclaimer'    = 'Disclaimer'
        'help.nav.about'         = 'About'
        'info.version'           = 'Version {0}'

        'faq.intro'              = 'Quick answers to the most common questions.'
        'faq.q1'                 = 'How do I add a tool?'
        'faq.a1'                 = 'Click "Add tool" (Ctrl+N), drop files, folders, shortcuts or browser links onto the window, or pick one from Suggestions.'
        'faq.q2'                 = 'What can I open?'
        'faq.a2'                 = 'Websites (https://…), applications (.exe, .lnk), scripts (.bat, .cmd), files, folders, network paths (\\server\share) and protocols such as msteams:, mailto: or ms-settings:. Variables like %USERPROFILE% are supported.'
        'faq.q3'                 = 'How do I open several at once?'
        'faq.a3'                 = 'Tick the ones you want and press Open (Ctrl+Enter). They open one by one with the pause you choose in Settings → Launching, so your PC is not overloaded.'
        'faq.q4'                 = 'What are tags for?'
        'faq.a4'                 = 'To group tools (e.g. Morning, Support, Meetings). A tool can have several. Pick a tag in the sidebar to see only its tools; the ▶ button next to the tag opens all of them.'
        'faq.q5'                 = 'How do I tag a tool?'
        'faq.a5'                 = 'With the tag button on the row, by dragging the row (⋮⋮ handle) onto a tag in the sidebar, or by choosing tags in the edit form.'
        'faq.q6'                 = 'Can I open a website in a specific browser or profile?'
        'faq.a6'                 = 'Yes. When editing a website, choose the browser and profile (e.g. Work). If that browser is not installed on another PC, the default browser is used.'
        'faq.q7'                 = 'How do suggestions work?'
        'faq.a7'                 = 'They are predefined shortcuts to common apps (Outlook, Teams, Gmail…). Add them in one click or customize them first. Once added, they are regular tools: edit or delete them as you like. Hide the ones you do not need; restore them in Settings → Data & backup.'
        'faq.q8'                 = 'I deleted something by mistake'
        'faq.a8'                 = 'Press "Undo" in the notification, or Ctrl+Z right away. DLauncher also keeps an automatic backup (config.json.bak).'
        'faq.q9'                 = 'How do I use DLauncher on several computers?'
        'faq.a9'                 = 'Choose a folder shared between your PCs (your network drive, OneDrive…) as the configuration folder, or use Export/Import. If DLauncher is open on several PCs, the list updates itself with changes made on the others. Language, theme and window size are kept per computer.'
        'faq.q10'                = 'What is the command palette?'
        'faq.a10'                = 'Press Ctrl+K and type: run any action, open a tool or jump to a tag without using the mouse.'
        'faq.q11'                = 'Can it start with Windows?'
        'faq.a11'                = 'Yes, in Settings → General (DLauncher.exe only). It creates a shortcut in your Startup folder; turning it off removes it.'
        'faq.q12'                = 'Where is my data and how do I delete it?'
        'faq.a12'                = 'See Privacy. In short: your configuration folder and %LOCALAPPDATA%\DLauncher. Nothing else is installed.'

        'icons.intro'            = 'What each DLauncher icon means.'
        'icons.play.t'           = 'Open now'
        'icons.play.d'           = 'Opens that tool immediately. Also double-click the row or press Enter.'
        'icons.edit.t'           = 'Edit'
        'icons.edit.d'           = 'Change name, target, tags, browser or default selection.'
        'icons.more.t'           = 'More actions'
        'icons.more.d'           = 'Duplicate, copy the path or URL, show in folder or delete. Also right-click the row.'
        'icons.tag.t'            = 'Tag'
        'icons.tag.d'            = 'Assigns or creates tags for the tool.'
        'icons.grip.t'           = 'Drag handle'
        'icons.grip.d'           = 'Drag to reorder, or drop onto a tag in the sidebar to tag it.'
        'icons.check.t'          = 'Selection'
        'icons.check.d'          = 'Ticked tools open together with Open (Ctrl+Enter).'
        'icons.letter.t'         = 'Initial'
        'icons.letter.d'         = 'Shown when no icon is available (protocols, missing files…).'
        'icons.favicon.t'        = 'Website'
        'icons.favicon.d'        = 'Websites show their own icon, downloaded once and cached.'
        'icons.folder.t'         = 'Folder'
        'icons.folder.d'         = 'Local folders and network locations.'
        'icons.browser.t'        = 'Browser and profile'
        'icons.browser.d'        = 'Shows the browser (and profile) used for that website.'
        'icons.tagdot.t'         = 'Tag color'
        'icons.tagdot.d'         = 'Each tag keeps its own color across the app.'
        'icons.sparkle.t'        = 'Suggestions'
        'icons.sparkle.d'        = 'Predefined common apps to add with one click.'
        'icons.clock.t'          = 'Pause between launches'
        'icons.clock.d'          = 'Wait between each tool when opening several. Click to change it.'
        'icons.command.t'        = 'Command palette'
        'icons.command.d'        = 'Ctrl+K: actions, tools and tags by typing.'
        'icons.theme.t'          = 'Theme'
        'icons.theme.d'          = 'Switch between light and dark.'
        'icons.sidebar.t'        = 'Sidebar'
        'icons.sidebar.d'        = 'Show or hide the sidebar (Ctrl+B).'
        'icons.warning.t'        = 'Warning'
        'icons.warning.d'        = 'Appears when a target runs a script or a program from the network.'
        'icons.status.t'         = 'Status'
        'icons.status.d'         = 'Green: ready · Blue: opening · Yellow: configuration in use or read-only.'

        'keys.intro'             = 'Everything in DLauncher works from the keyboard.'
        'keys.palette'           = 'Command palette'
        'keys.search'            = 'Search (or just start typing)'
        'keys.move'              = 'Move through the list'
        'keys.open'              = 'Open the highlighted tool'
        'keys.openSel'           = 'Open the selected tools'
        'keys.toggle'            = 'Select / deselect the highlighted tool'
        'keys.add'               = 'Add tool'
        'keys.edit'              = 'Edit the highlighted tool'
        'keys.duplicate'         = 'Duplicate the highlighted tool'
        'keys.delete'            = 'Delete the highlighted tool (can be undone)'
        'keys.undo'              = 'Undo the last deletion'
        'keys.sidebar'           = 'Show / hide the sidebar'
        'keys.settings'          = 'Settings'
        'keys.help'              = 'Help'
        'keys.esc'               = 'Clear search / close panels'
        'keys.dblclick.k'        = 'Double-click'
        'keys.dblclick'          = 'Open a tool · rename a tag'
        'keys.rightclick.k'      = 'Right-click'
        'keys.rightclick'        = 'Tool menu'
        'keys.typing.k'          = 'Type'
        'keys.typing'            = 'Start searching from anywhere'

        'about.body'             = @'
A daily launcher for your work apps, websites and files: list what you use every day, organize it with tags and open everything with one click.

• No installation, no dependencies: a single .exe for Windows 10 and 11.
• Built with PowerShell, WPF and .NET Framework, all included in Windows.
• Your data stays on your computer.
• Free and open source under the MIT License: github.com/montesito/dlauncher
'@

        'legal.updated'          = 'Last updated: November 26, 2026'

        'legal.privacy'          = @'
## Summary
DLauncher runs entirely on your computer. It has no accounts, analytics, advertising or telemetry. The developer receives none of your data.

## What is stored and where
• Your tools, tags and settings: config.json in the folder you chose, plus an automatic backup (config.json.bak).
• Preferences for this computer (language, theme, window size and terms acceptance): %LOCALAPPDATA%\DLauncher\prefs.json.
• Website icons: %LOCALAPPDATA%\DLauncher\IconCache.
• Only if you enable it: a shortcut in your Windows Startup folder.

## Network connections
DLauncher only connects to the internet to download website icons: once per website in your list, it requests that site's home page and icon, as a browser would. Requests go directly to that website, with no intermediary. You can turn this off in Settings → Appearance → Website icons.
When you open a website, your browser does it, under its own privacy policy.

## Sharing
Exporting creates a file that you decide who to share with. If your configuration folder is in a synced location (OneDrive, a network drive…), that service's terms apply.

## Deleting your data
Delete your configuration folder and %LOCALAPPDATA%\DLauncher. DLauncher installs nothing else on your computer.
'@

        'legal.warnings'         = @'
## Before you use it
• DLauncher opens what you configure with your own user permissions. Programs and scripts (.exe, .bat, .cmd, .ps1, .vbs…) run just as if you double-clicked them: only add those you trust.
• Only import configuration files from people and sources you trust. Imported tools arrive unselected so you can review them before opening.
• Opening many tools at once uses memory and CPU. Use the pause between launches (Settings → Launching) and the confirmation for large batches.
• Follow your organization's policies: some companies restrict running unsigned programs or scripts.
• The executable is not digitally signed, so Windows SmartScreen may show a warning the first time. You can also build it yourself from the source code.
• Network paths are not checked while you browse the list, so the app never freezes; if a network resource is unavailable, the error appears when you open it.
• Keep a copy of your configuration (Settings → Data & backup → Export) if it matters to you.
'@

        'legal.terms'            = @'
## 1. Acceptance
By using DLauncher you accept these terms. If you do not agree, do not use the application.

## 2. What DLauncher is
A personal productivity utility that opens the applications, websites, files, folders and protocols you configure. It is provided free of charge.

## 3. Your responsibility
• You decide what to add and open, and you are responsible for that use and its consequences.
• You must have the right to use the software and services you open, and comply with their licenses and terms.
• You must respect your organization's rules and applicable law.

## 4. Third-party trademarks
Names such as Outlook, Teams, Word, Excel, Gmail, Slack or GitHub are trademarks of their respective owners. They appear only as suggested shortcuts; DLauncher is not affiliated with or endorsed by them. Website icons belong to each site.

## 5. No warranty
DLauncher is provided "as is", without warranties of any kind, express or implied, including fitness for a particular purpose, availability or freedom from errors.

## 6. Changes
These terms may be updated in future versions. If they change, the app will ask you to accept them again.
'@

        'legal.disclaimer'       = @'
## Limitation of liability
To the maximum extent permitted by law, the developer is not responsible for any loss of data, configuration, time or income, or for any other direct or indirect damage arising from the use of, or inability to use, DLauncher, or from the programs, scripts or websites opened with it.

## Non-intrusive by design
DLauncher installs no drivers or services, does not change system settings, does not keep running in the background once closed and does not need administrator rights. It only writes its own files (configuration, backup, preferences and icon cache) and, if you enable it, a startup shortcut. Deleting those files leaves your computer as it was.

## Recommendations
• Export your configuration from time to time.
• Use Undo (Ctrl+Z) right after deleting something by mistake.
• If config.json gets damaged, DLauncher keeps a copy of the file and automatically restores the latest backup.

Nothing above limits rights that cannot be excluded under applicable law.
'@
    }
}

# Idioma activo: preferencia del usuario en este equipo, o Español por defecto
$Global:DLauncherLanguage = $Global:DLauncherDefaultLanguage
$savedLanguage = [string](Get-DLauncherPref -Name 'Language' -Default '')
if ($Global:DLauncherStrings.ContainsKey($savedLanguage)) {
    $Global:DLauncherLanguage = $savedLanguage
}

# Devuelve el texto traducido de una clave, con formato opcional ({0}, {1}...)
function Global:T {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Key,
        [Parameter(ValueFromRemainingArguments=$true)]
        [object[]]$Values
    )
    $text = Get-DLauncherTextOrNull -Key $Key
    if ($null -eq $text) { $text = $Key }
    if ($null -ne $Values -and $Values.Count -gt 0) {
        return [string]::Format($text, $Values)
    }
    return $text
}

function Global:Get-DLauncherTextOrNull {
    param ([string]$Key)
    $text = $Global:DLauncherStrings[$Global:DLauncherLanguage][$Key]
    if ($null -eq $text) { $text = $Global:DLauncherStrings[$Global:DLauncherDefaultLanguage][$Key] }
    return $text
}

# Datos del idioma activo (cultura y formato de fecha)
function Global:Get-DLauncherLanguageInfo {
    $info = $Global:DLauncherLanguages | Where-Object { $_.Code -eq $Global:DLauncherLanguage } | Select-Object -First 1
    if ($null -eq $info) { $info = $Global:DLauncherLanguages[0] }
    return $info
}

# Cambia y guarda el idioma (preferencia por usuario y equipo, independiente de la carpeta de configuración)
function Global:Set-DLauncherLanguagePreference {
    param ([string]$Code)
    if (-not $Global:DLauncherStrings.ContainsKey($Code)) { return }
    $Global:DLauncherLanguage = $Code
    Set-DLauncherPref -Name 'Language' -Value $Code
}

# Traduce un árbol de elementos WPF: x:Uid -> Text (TextBlock) o Content (botones, casillas) y "clave.tip" -> ToolTip
function Global:Update-DLauncherLocalizedTree {
    param ($Root)
    if ($null -eq $Root) { return }
    if ($Root -is [System.Windows.FrameworkElement] -and -not [string]::IsNullOrEmpty($Root.Uid)) {
        $text = Get-DLauncherTextOrNull -Key $Root.Uid
        if ($null -ne $text) {
            if ($Root -is [System.Windows.Controls.TextBlock]) {
                $Root.Text = $text
            } elseif ($Root -is [System.Windows.Controls.ContentControl]) {
                $Root.Content = $text
            }
        }
        $tip = Get-DLauncherTextOrNull -Key "$($Root.Uid).tip"
        if ($null -ne $tip) { $Root.ToolTip = $tip }
    }
    foreach ($child in [System.Windows.LogicalTreeHelper]::GetChildren($Root)) {
        if ($child -is [System.Windows.DependencyObject]) {
            Update-DLauncherLocalizedTree -Root $child
        }
    }
}
