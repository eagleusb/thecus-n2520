<?php

// Spanish Language Module for joomlaXplorer (translated by J. Pedro Flor P.)
global $_VERSION;

$GLOBALS["charset"] = "UTF-8";
$GLOBALS["text_dir"] = "ltr"; // ('ltr' for left to right, 'rtl' for right to left)
$GLOBALS["date_fmt"] = "Y/m/d H:i";
$GLOBALS["error_msg"] = array(
	// error
	"error"			=> "ERROR(ES)",
	"back"			=> "Ir Atr&aacute;s",
	
	// root
	"home"			=> "El directorio home no existe, revise su configuraci&oacute;n.",
	"abovehome"		=> "El directorio actual no puede estar arriba del directorio home.",
	"targetabovehome"	=> "El directorio objetivo no puede estar arriba del directorio home.",
	
	// exist
	"direxist"		=> "Este directorio no existe.",
	"filedoesexist"	=>  "Este archivo ya existe.",
	"fileexist"		=> "Este archivo no existe.",
	"itemdoesexist"		=> "Este artiacute;culo ya existe.",
	"itemexist"		=> "Este art&iacute;culo no existe.",
	"targetexist"		=> "El directorio objetivo no existe.",
	"targetdoesexist"	=> "El art&iacute;culo objetivo ya existe.",
	
	// open
	"opendir"		=> "Incapaz de abrir directorio.",
	"readdir"		=> "Incapaz de leer directorio.",
	
	// access
	"accessdir"		=> "Ud. no est&aacute; permitido accesar este directorio.",
	"accessfile"		=> "Ud. no est&aacute; permitido accesar a este archivo.",
	"accessitem"		=> "Ud. no est&aacute; permitido accesar a este art&iacute;culo.",
	"accessfunc"		=> "Ud. no est&aacute; permitido usar esta funcion.",
	"accesstarget"		=> "Ud. no est&aacute; permitido accesar al directorio objetivo.",
	
	// actions
	"permread"		=> "Fracaso reuniendo permisos.",
	"permchange"		=> "Fracaso en Cambio de permisos.",
	"openfile"		=> "Fracaso abriendo archivo.",
	"savefile"		=> "Fracaso guardando archivo.",
	"createfile"		=> "Fracaso creando archivo.",
	"createdir"		=> "Fracaso creando Directorio.",
	"uploadfile"		=> "Fracaso subiendo archivo.",
	"copyitem"		=> "Fracaso Copiando.",
	"moveitem"		=> "Fracaso Moviendo.",
	"delitem"		=> "Fracaso Borrando.",
	"chpass"		=> "Fracaso Cambiando password.",
	"deluser"		=> "Fracaso Removiendo usuario.",
	"adduser"		=> "Fracaso Agragando usuario.",
	"saveuser"		=> "Fracaso Guardadno usuario.",
	"searchnothing"		=> "Ud. debe suministrar algo para la busqueda.",
	
	// misc
	"miscnofunc"		=> "Funci&oacute;n no disponible.",
	"miscfilesize"		=> "Archivo excede maximo tama&ntilde;o.",
	"miscfilepart"		=> "Archivo fue parcialmente subido.",
	"miscnoname"		=> "Ud. debe suministrar un nombre.",
	"miscselitems"		=> "Ud. no tiene seleccionado(s) ningun art&iacute;culo.",
	"miscdelitems"		=> "Est&aacute; seguro de querer borrar este(os) {0} art&iacute;culo(s)?",
	"miscdeluser"		=> "Est&aacute; seguro de querer borrar usuario '{0}'?",
	"miscnopassdiff"	=> "Nuevo password no difiere del actual.",
	"miscnopassmatch"	=> "No coinciden los Passwords.",
	"miscfieldmissed"	=> "Ud. fall&oacute; en un importante campo.",
	"miscnouserpass"	=> "Usuario o password incorrecto.",
	"miscselfremove"	=> "Ud. no puede borrarse a si mismo.",
	"miscuserexist"		=> "Usuario ya existe.",
	"miscnofinduser"	=> "No se puede encontrar usuario.",
	"extract_noarchive" => "El archivo no es un archivo extraíble.",	"extract_unknowntype" => "Tipo de archivo desconocido",
	
	'chmod_none_not_allowed' => 'No se permite cambiar los permisos a <ninguno>',
	'archive_dir_notexists' => 'El directorio de almacenamiento no existe.',
	'archive_dir_unwritable' => 'Especifique un directorio en el que se pueda escribir para guardar el archivo en él.',
	'archive_creation_failed' => 'No se puede guardar el archivo de archivado'
);
$GLOBALS["messages"] = array(
	// links
	"permlink"		=> "PORMISOS CAMBIADOS",
	"editlink"		=> "EDITAR",
	"downlink"		=> "DESCARGAR",
	"uplink"		=> "ARRIBA",
	"homelink"		=> "HOME",
	"reloadlink"		=> "RECARGAR",
	"copylink"		=> "COPIAR",
	"movelink"		=> "MOVER",
	"dellink"		=> "BORRAR",
	"comprlink"		=> "ARCHIVAR",
	"adminlink"		=> "ADMINISTRAR",
	"logoutlink"		=> "SALIR",
	"uploadlink"		=> "SUBIR",
	"searchlink"		=> "B&Uacute;SQUEDA",
	"extractlink"	=> "Extraer archivo",
	'chmodlink'		=> 'Cambiar los derechos (chmod) (carpeta/archivos)', // new mic
	'mossysinfolink'	=> 'Información del sistema eXtplorer (eXtplorer, servidor, PHP, mySQL)', // new mic
	'logolink'		=> 'Ir al sitio Web de joomlaXplorer (nueva ventana)', // new mic
	
	// list
	"nameheader"		=> "Nombre",
	"sizeheader"		=> "Tama&ntilde;o",
	"typeheader"		=> "Tipo",
	"modifheader"		=> "Modificado",
	"permheader"		=> "Permisos",
	"actionheader"		=> "Acciones",
	"pathheader"		=> "Ruta",
	
	// buttons
	"btncancel"		=> "Cancelar",
	"btnsave"		=> "Grabar",
	"btnchange"		=> "Cambiar",
	"btnreset"		=> "Restablecer",
	"btnclose"		=> "Cerrar",
	"btncreate"		=> "Crear",
	"btnsearch"		=> "Buscar",
	"btnupload"		=> "Subir",
	"btncopy"		=> "Copiar",
	"btnmove"		=> "Mover",
	"btnlogin"		=> "Login",
	"btnlogout"		=> "Salir",
	"btnadd"		=> "A&ntilde;adir",
	"btnedit"		=> "Editar",
	"btnremove"		=> "Remover",
	
	// user messages, new in joomlaXplorer 1.3.0
	'renamelink'	=> 'CAMBIAR NOMBRE',
	'confirm_delete_file' => '¿Realmente desea eliminar este archivo? \\n%s',
	'success_delete_file' => 'Elementos eliminados correctamente.',
	'success_rename_file' => 'El nombre del directorio o archivo %s se cambió correctamente a %s.',
	
	
	// actions
	"actdir"		=> "Directorio",
	"actperms"		=> "Cambiar permisos",
	"actedit"		=> "Editar archivo",
	"actsearchresults"	=> "Resultado de busqueda.",
	"actcopyitems"		=> "Copiar art&iacute;culos(s)",
	"actcopyfrom"		=> "Copia de /%s a /%s ",
	"actmoveitems"		=> "Mover art&iacute;culo(s)",
	"actmovefrom"		=> "Mover de /%s a /%s ",
	"actlogin"		=> "Login",
	"actloginheader"	=> "Login para usar QuiXplorer",
	"actadmin"		=> "Administraci&oacute;n",
	"actchpwd"		=> "Cambiar password",
	"actusers"		=> "Usuarios",
	"actarchive"		=> "Archivar item(s)",
	"actupload"		=> "Subir Archivo(s)",
	
	// misc
	"miscitems"		=> "Art&iacute;culo(s)",
	"miscfree"		=> "Libre",
	"miscusername"		=> "Nombre de usuario",
	"miscpassword"		=> "Password",
	"miscoldpass"		=> "Password Antiguo",
	"miscnewpass"		=> "Password Nuevo",
	"miscconfpass"		=> "Confirmar password",
	"miscconfnewpass"	=> "Confirmar nuevo password",
	"miscchpass"		=> "Cambiar password",
	"mischomedir"		=> "Directorio Home",
	"mischomeurl"		=> "URL Home",
	"miscshowhidden"	=> "Mostrar art&iacute;culos ocultos",
	"mischidepattern"	=> "Ocultar patr&oacute;n",
	"miscperms"		=> "Permisos",
	"miscuseritems"		=> "(nombre, directorio home, mostrar art&iacute;culos ocultos, permisos, activar)",
	"miscadduser"		=> "a&ntilde;adir usuario",
	"miscedituser"		=> "editar usario '%s'",
	"miscactive"		=> "Activar",
	"misclang"		=> "Lenguaje",
	"miscnoresult"		=> "Resultado(s) no disponible(s).",
	"miscsubdirs"		=> "B&uacute;squeda de subdirectorios",
	"miscpermnames"		=> array("Solo ver","Modificar","Cambiar password","Modificar & Cambiar password", "Administrador"),
	"miscyesno"		=> array("Si","No","S","N"),
	"miscchmod"		=> array("Propietario", "Grupo", "P&uacute;blico"),
	// from here all new by mic
	'miscowner'			=> 'Propietario',
	'miscownerdesc'		=> '<strong>Descripción:</strong><br />Usuario (UID) /<br />Grupo (GID)<br />Derechos actuales:<br /><strong> %s ( %s ) </strong>/<br /><strong> %s ( %s )</strong>',

	// sysinfo (new by mic)
	'simamsysinfo'		=> 'Información del sistema eXtplorer',
	'sisysteminfo'		=> 'Información del sistema',
	'sibuilton'			=> 'Sistema operativo',
	'sidbversion'		=> 'Versión de la base de datos (MySQL)',
	'siphpversion'		=> 'Versión de PHP',
	'siphpupdate'		=> 'INFORMACIÓN: <span style="color: rojo;">¡La versión de PHP que utiliza <strong>no es</strong> real!</span><br />Para garantizar todas las funciones y características de eXtplorer y de los complementos,<br />debe utilizar al menos <strong>PHP Versión 4.3</strong>!',
	'siwebserver'		=> 'Servidor Web',
	'siwebsphpif'		=> 'Servidor Web - Interfaz de PHP',
	'simamboversion'	=> 'Versión de eXtplorer',
	'siuseragent'		=> 'Versión del explorador',
	'sirelevantsettings' => 'Configuración PHP importante',
	'sisafemode'		=> 'Modo seguro',
	'sibasedir'			=> 'Abrir directorio base',
	'sidisplayerrors'	=> 'Errores de PHP',
	'sishortopentags'	=> 'Etiquetas abiertas cortas',
	'sifileuploads'		=> 'Cargas de ficheros',
	'simagicquotes'		=> 'Cuotas mágicas',
	'siregglobals'		=> 'Register Globals',
	'sioutputbuf'		=> 'Búfer de salida',
	'sisesssavepath'	=> 'Ruta de acceso de almacenamiento de sesión',
	'sisessautostart'	=> 'Inicio automático de sesión',
	'sixmlenabled'		=> 'XML habilitado',
	'sizlibenabled'		=> 'ZLIB habilitado',
	'sidisabledfuncs'	=> 'Funciones no habilitadas',
	'sieditor'			=> 'Editor WYSIWYG',
	'siconfigfile'		=> 'Archivo de configuración',
	'siphpinfo'			=> 'Información de PHP',
	'siphpinformation'	=> 'Información de PHP',
	'sipermissions'		=> 'Permisos',
	'sidirperms'		=> 'Permisos del directorio',
	'sidirpermsmess'	=> 'Para asegurarse de que todas las funciones y características de eXtplorer funcionan correctamente, las siguientes carpetas deben tener permiso de escritura [chmod 0777]',
	'sionoff'			=> array( 'Activar', 'Desactivar' ),
	
	'extract_warning' => "¿Realmente desea extraer este archivo? ¿Aquí?\\n¡Esta operación sobrescribirá los archivos existentes cuando no se utilice con cuidado!",
	'extract_success' => "La extracción se realizó correctamente.",
	'extract_failure' => "Error de extracción.",
	
	'overwrite_files' => '¿Desea sobrescribir los archivos existentes?',
	"viewlink"		=> "VER",
	"actview"		=> "Se está mostrando el origen del archivo",
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_chmod.php file
	'recurse_subdirs'	=> '¿Recurso en subdirectorios?',
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to footer.php file
	'check_version'	=> 'Buscar la versión más reciente',
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_rename.php file
	'rename_file'	=>	'Cambiar el nombre de un directorio o archivo...',
	'newname'		=>	'Nuevo nombre',
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_edit.php file
	'returndir'	=>	'¿Desea volver al directorio después de guardar?',
	'line'		=> 	'Línea',
	'column'	=>	'Columna',
	'wordwrap'	=>	'Cortar palabras: (solamente en IE)',
	'copyfile'	=>	'Copiar archivo en este nombre de archivo',
	
	// Bookmarks
	'quick_jump' => 'Salto rápido a',
	'already_bookmarked' => 'Este directorio ya está marcado',
	'bookmark_was_added' => 'Este directorio se agregó a la lista de marcadores.',
	'not_a_bookmark' => 'Este directorio no es un marcador.',
	'bookmark_was_removed' => 'Este directorio se quitó de la lista de marcadores.',
	'bookmarkfile_not_writable' => "No se pudo %s el marcador.\n No se puede escribir en \nel archivo de marcador '%s'.",
	
	'lbl_add_bookmark' => 'Agregar este directorio como marcador',
	'lbl_remove_bookmark' => 'Quitar este directorio de la lista de marcadores',
	
	'enter_alias_name' => 'Escriba el nombre del alias de este marcador',
	
	'normal_compression' => 'compresión normal',
	'good_compression' => 'compresión buena',
	'best_compression' => 'compresión excelente',
	'no_compression' => 'sin compresión',
	
	'creating_archive' => 'Creando archivo de archivado...',
	'processed_x_files' => 'Procesados %s de %s archivos',
	
	'ftp_header' => 'Autenticación FTP local',
	'ftp_login_lbl' => 'Proporcione las credenciales de inicio de sesión para el servidor FTP.',
	'ftp_login_name' => 'Nombre de usuario FTP',
	'ftp_login_pass' => 'Contraseña FTP',
	'ftp_hostname_port' => 'Nombre de host y puerto del servidor FTP <br />(El puerto es opcional)',
	'ftp_login_check' => 'Comprobando la conexión FTP...',
	'ftp_connection_failed' => "No se pudo establecer contacto con el servidor FTP. \nCompruebe que el servidor FTP se está ejecutando en el servidor.",
	'ftp_login_failed' => "Error de inicio de sesión FTP. Compruebe el nombre de usuario y la contraseña e inténtelo de nuevo.",
		
	'switch_file_mode' => 'Modo actual: <strong>%s</strong>. Podría cambiar al modo %s.',
	'symlink_target' => 'Destino del vínculo simbólico',
	
	"permchange"		=> "Operación CHMOD correcta:",
	"savefile"		=> "El archivo se guardó.",
	"moveitem"		=> "La operación Mover se realizó correctamente.",
	"copyitem"		=> "La operación Copia se realizó correctamente.",
	'archive_name' 	=> 'Nombre del archivo de archivado',
	'archive_saveToDir' 	=> 'Guardar el archivo en este directorio',
	
	'editor_simple'	=> 'Modo de editor simple',
	'editor_syntaxhighlight'	=> 'Modo de resaltado de sintaxis',

	'newlink'	=> 'Nuevo archivo o directorio',
	'show_directories' => 'Mostrar directorios',
	'actlogin_success' => 'Inicio de sesión correcto.',
	'actlogin_failure' => 'Error de inicio de sesión. Inténtelo de nuevo.',
	'directory_tree' => 'Árbol de directorios',
	'browsing_directory' => 'Examinar directorio',
	'filter_grid' => 'Filtro',
	'paging_page' => 'Página',
	'paging_of_X' => 'de {0}',
	'paging_firstpage' => 'Primera página',
	'paging_lastpage' => 'Última página',
	'paging_nextpage' => 'Página siguiente',
	'paging_prevpage' => 'Página anterior',
	
	'paging_info' => 'Mostrando elementos {0} - {1} de {2}',
	'paging_noitems' => 'No hay elementos para mostrar',
	'aboutlink' => 'Acerca de...',
	'password_warning_title' => 'Importante - ¡Cambie la contraseña!',
	'password_warning_text' => 'La cuenta de usuario con la que ha iniciado sesión (admin con contraseña admin) corresponde a la cuenta con priviliegios de eXtplorer predeterminada. ¡La instalación de eXtplorer permite intrusiones y debería resolver este agujero de seguridad inmediatamente!',
	'change_password_success' => '¡Contraseña cambiada!',
	'success' => 'Operación correcta',
	'failure' => 'Error',
	'dialog_title' => 'Diálogo del sitio Web',
	'upload_processing' => 'Procesando carga. Espere...',
	'upload_completed' => '¡Carga correcta!',
	'acttransfer' => 'Transferir desde otro servidor',
	'transfer_processing' => 'Procesando la transferencia servidor a servidor. Espere...',
	'transfer_completed' => '¡Transferencia completada!',
	'max_file_size' => 'Tamaño de archivo máximo',
	'max_post_size' => 'Límite de carga máximo',
	'done' => 'Hecho.',
	'permissions_processing' => 'Aplicando permisos. Espere...',
	'archive_created' => '¡Archivo de archivado creado!',
	'save_processing' => 'Guardando archivo...',
	'current_user' => 'Este script actualmente se ejecuta con los permisos del siguiente usuario:',
	'your_version' => 'Su versión',
	'search_processing' => 'Buscando. Espere...',
	'url_to_file' => 'URL del archivo',
	'file' => 'Archivo',
	'create_title' => 'Create New Directory/File'
);
?>
