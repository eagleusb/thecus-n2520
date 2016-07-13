<?php
// Portuguese Translation by Paulino Michelazzo - paulino@michelazzo.com.br
// http://www.noritmodomambo.org
// Version: 1.0
// Date: Sep, 07 2006

global $_VERSION;

$GLOBALS["charset"] = "iso-8859-1";
$GLOBALS["text_dir"] = "ltr";
$GLOBALS["date_fmt"] = "d/m/Y H:i";
$GLOBALS["error_msg"] = array(
	// error
	"error"			=> "ERRO(S)",
	"back"			=> "Voltar",
	
	// root
	"home"			=> "O diret&oacute;rio HOME n&atilde;o existe. Verifique suas op&ccedil;&otilde;es",
	"abovehome"		=> "O diret&oacute;rio atual n&atilde;o pode estar acima do diret&oacute;rio home.",
	"targetabovehome"	=> "O diret&oacute;rio de destino n&atilde;o pode estar acima do diret&oacute;rio home.",
	
	// exist
	"direxist"		=> "Este diret&oacute;rio n&atilde;o existe",
	"fileexist"		=> "Este arquivo n&atilde;o existe",
    "filedoesexist" => "This file already exists.",
	"itemdoesexist"	=> "Este item j&aacute; existe",
	"itemexist"		=> "Este item n&atilde;o existe",
	"targetexist"	=> "O diret&oacute;rio de destino n&atilde;o existe",
	"targetdoesexist"	=> "O item de destino j&aacute; existe",
	
	// open
	"opendir"		=> "Imposs&iacute;vel abrir o diret&oacute;rio",
	"readdir"		=> "Imposs&iacute;vel ler o diret&oacute;rio",
	
	// access
	"accessdir"		=> "Voc&ecirc; n&atilde;o tem permiss&atilde;o para acessar este diret&oacute;rio",
	"accessfile"	=> "Voc&ecirc; n&atilde;o tem permiss&atilde;o para acessar este arquivo",
	"accessitem"	=> "Voc&ecirc; n&atilde;o tem permiss&atilde;o para acessar este item",
	"accessfunc"	=> "Voc&ecirc; n&atilde;o tem permiss&atilde;o para usar esta fun&ccedil;&atilde;o",
	"accesstarget"	=> "Voc&ecirc; n&atilde;o tem permiss&atilde;o para acessar o diret&oacute;rio de destino",
	
	// actions
	"permread"		=> "Falha ao buscar permiss&otilde;es",
	"permchange"	=> "Falha ao alterar permiss&otilde;es",
	"openfile"		=> "Falha ao abrir o arquivo",
	"savefile"		=> "Falha ao salvar o arquivo",
	"createfile"	=> "Falha ao criar o arquivo",
	"createdir"		=> "Falha ao criar o diret&oacute;rio",
	"uploadfile"	=> "Falha ao enviar o arquivo",
	"copyitem"		=> "Falha ao copiar",
	"moveitem"		=> "Falha ao mover",
	"delitem"		=> "Falha ao apagar",
	"chpass"		=> "Falha ao alterar a senha",
	"deluser"		=> "Falha ao remover usu&aacute;rio",
	"adduser"		=> "Falha ao adicionar usu&aacute;rio",
	"saveuser"		=> "Falha ao salvar usu&aacute;rio",
	"searchnothing"	=> "Voc&ecirc; deve informar o que buscar",
	
	// misc
	"miscnofunc"		=> "Fun&ccedil;&atilde;o n&atilde;o dispon�vel",
	"miscfilesize"		=> "O arquivo excede o tamanho m&aacute;ximo permitido",
	"miscfilepart"		=> "O arquivo foi enviado parcialmente",
	"miscnoname"		=> "Informe um nome",
	"miscselitems"		=> "Selecione pelo menos um item",
	"miscdelitems"		=> "Tem certeza que deseja apagar estes {0} item(s)?",
	"miscdeluser"		=> "Tem certeza que deseja apagar o usu&aacute;rio {0}?",
	"miscnopassdiff"	=> "A nova senha n&atilde;o &eacute; diferente da atual",
	"miscnopassmatch"	=> "As senhas n&atilde;o coincidem",
	"miscfieldmissed"	=> "Voc&ecirc; esqueceu um campo importante",
	"miscnouserpass"	=> "Nome de usu&aacute;rio ou senha incorretos",
	"miscselfremove"	=> "Voc&ecirc; n&atilde;o pode se auto-remover",
	"miscuserexist"		=> "Usu&aacute;rio j&aacute; existe",
	"miscnofinduser"	=> "Usu&aacute;rio n&atilde;o encontrado",
	"extract_noarchive" => "O arquivo n&atilde;o &eacute; um arquivo compactado",
	"extract_unknowntype" => "Tipo de Arquivo Desconhecido",
	
	'chmod_none_not_allowed' => 'Changing Permissions to <none> is not allowed',
	'archive_dir_notexists' => 'The Save-To Directory you have specified does not exist.',
	'archive_dir_unwritable' => 'Please specify a writable directory to save the archive to.',
	'archive_creation_failed' => 'Failed saving the Archive File'
);
$GLOBALS["messages"] = array(
	// links
	"permlink"		=> "ALTERAR PERMISS&Otilde;ES",
	"editlink"		=> "EDITAR",
	"downlink"		=> "DOWNLOAD",
	"uplink"		=> "SOBE",
	"homelink"		=> "HOME",
	"reloadlink"	=> "ATUALIZAR",
	"copylink"		=> "COPIAR",
	"movelink"		=> "MOVER",
	"dellink"		=> "APAGAR",
	"comprlink"		=> "ARQUIVO",
	"adminlink"		=> "ADMIN",
	"logoutlink"	=> "SAIR",
	"uploadlink"	=> "ENVIAR",
	"searchlink"	=> "BUSCAR",
	"extractlink"	=> "Extrair Arquivo",
	'chmodlink'		=> 'Alterar (chmod) Permiss&otilde;es (Pasta/Arquivo(s))',
	'mossysinfolink'	=> 'eXtplorer Informa&ccedil;&atilde;o do Sistema (eXtplorer, Servidor, PHP, MySQL)',
	'logolink'		=> 'Ir para o site do joomlaXplorer (nova janela)',
	
	// user messages, new in joomlaXplorer 1.3.0
	'renamelink'	=> 'RENOMEAR',
	'confirm_delete_file' => 'Voc&ecirc; tem certeza que deseja apagar este arquivo? \\n%s',
	'success_delete_file' => 'Item(s) apagado com sucesso',
	'success_rename_file' => 'O arquivo/diret&oacute;rio %s foi renomeado com sucesso para %s',
	
	// list
	"nameheader"		=> "Nome",
	"sizeheader"		=> "Tamanho",
	"typeheader"		=> "Tipo",
	"modifheader"		=> "Modificado",
	"permheader"		=> "Perm's",
	"actionheader"		=> "A&ccedil;&otilde;es",
	"pathheader"		=> "Caminho",
	
	// buttons
	"btncancel"		=> "Cancelar",
	"btnsave"		=> "Salvar",
	"btnchange"		=> "Alterar",
	"btnreset"		=> "Limpar",
	"btnclose"		=> "Fechar",
	"btncreate"		=> "Criar",
	"btnsearch"		=> "Buscar",
	"btnupload"		=> "Enviar",
	"btncopy"		=> "Copiar",
	"btnmove"		=> "Mover",
	"btnlogin"		=> "Login",
	"btnlogout"		=> "Sair",
	"btnadd"		=> "Adicionar",
	"btnedit"		=> "Editar",
	"btnremove"		=> "Remover",
	
	// actions
	"actdir"		=> "Diret&oacute;rio",
	"actperms"		=> "Alterar permiss&otilde;es",
	"actedit"		=> "Editar arquivo",
	"actsearchresults"	=> "Buscar resultados",
	"actcopyitems"	=> "Copiar item(s)",
	"actcopyfrom"	=> "Copiar de /%s para /%s ",
	"actmoveitems"	=> "Mover item(s)",
	"actmovefrom"	=> "Mover de /%s para /%s ",
	"actlogin"		=> "Login",
	"actloginheader" => "Login para usar QuiXplorer",
	"actadmin"		=> "Administra&ccedil;&atilde;o",
	"actchpwd"		=> "Alterar senha",
	"actusers"		=> "Usu&aacute;rios",
	"actarchive"	=> "Arquivar item(s)",
	"actupload"		=> "Enviar arquivo(s)",
	
	// misc
	"miscitems"		=> "Item(s)",
	"miscfree"		=> "Espa&ccedil;o Livre",
	"miscusername"	=> "Nome de usu&aacute;rio",
	"miscpassword"	=> "Senha",
	"miscoldpass"	=> "Senha antiga",
	"miscnewpass"	=> "Nova senha",
	"miscconfpass"	=> "Confirmar senha",
	"miscconfnewpass"	=> "Confirmar nova senha",
	"miscchpass"	=> "Alterar senha",
	"mischomedir"	=> "Diret&oacute;rio Home",
	"mischomeurl"	=> "Home URL",
	"miscshowhidden"	=> "Mostrar itens ocultos",
	"mischidepattern"	=> "Ocultar padr&atilde;o",
	"miscperms"		=> "Permiss&otilde;es",
	"miscuseritems"	=> "(nome, diret&oacute;rio home, mostrar itens ocultos, permiss&otilde;es, ativo)",
	"miscadduser"	=> "adicionar usu&aacute;rio",
	"miscedituser"	=> "editar usu&aacute;rio '%s'",
	"miscactive"	=> "Ativo",
	"misclang"		=> "Idioma",
	"miscnoresult"	=> "Sem resultados.",
	"miscsubdirs"	=> "Buscar subdiret&oacute;rios",
	"miscpermnames"	=> array("Somente ver","Modificar","Alterar senha","Modificar & Alterar senha","Administra&ccedil;&atilde;o"),
	"miscyesno"		=> array("Sim","N&atilde;o","S","N"),
	"miscchmod"		=> array("Dono", "Grupo", "P&uacute;blico"),

	// from here all new by mic
	'miscowner'			=> 'Propriet&aacute;rio',
	'miscownerdesc'		=> '<strong>Descri&ccedil;&atilde;o:</strong><br />Usu&aacute;rio (UID) /<br />Grupo (GID)<br />Permiss&otilde;es atuais:<br /><strong> %s ( %s ) </strong>/<br /><strong> %s ( %s )</strong>',

	// sysinfo (new by mic)
	'simamsysinfo'		=> 'eXtplorer Infos do Sistema',
	'sisysteminfo'		=> 'Sistema',
	'sibuilton'			=> 'Sistema Operacional',
	'sidbversion'		=> 'Vers&atilde;o do Banco de Dados MySQL',
	'siphpversion'		=> 'Vers&atilde;o do PHP',
	'siphpupdate'		=> 'INFORMA&Ccedil;&Atilde;O: <span style="color: red;">A vers&atilde;o do PHP instalada <strong>n&atilde;o &eacute;</strong> atual!</span><br />Para garantir todas as funcionalidades do eXtplorer e seus componentes adicionais,<br />voc&ecirc; deve usar pelo menos a vers&atilde;o <strong>4.3</strong>!',
	'siwebserver'		=> 'Servidor Web',
	'siwebsphpif'		=> 'Interface Servidor Web - PHP',
	'simamboversion'	=> 'Vers&atilde;o do '.$_VERSION->PRODUCT,
	'siuseragent'		=> 'Vers&atilde;o do Navegador',
	'sirelevantsettings' => 'Configura&ccedil;&otilde;es Importantes do PHP',
	'sisafemode'		=> 'Safe Mode',
	'sibasedir'			=> 'Open basedir',
	'sidisplayerrors'	=> 'PHP Errors',
	'sishortopentags'	=> 'Short Open Tags',
	'sifileuploads'		=> 'Datei Uploads',
	'simagicquotes'		=> 'Magic Quotes',
	'siregglobals'		=> 'Register Globals',
	'sioutputbuf'		=> 'Output Buffer',
	'sisesssavepath'	=> 'Session Savepath',
	'sisessautostart'	=> 'Session auto start',
	'sixmlenabled'		=> 'XML enabled',
	'sizlibenabled'		=> 'ZLIB enabled',
	'sidisabledfuncs'	=> 'Non enabled functions',
	'sieditor'			=> 'WYSIWYG Editor',
	'siconfigfile'		=> 'Arquivo de Configura&ccedil;&atilde;o',
	'siphpinfo'			=> 'Info PHP',
	'siphpinformation'	=> 'Informa&ccedil;&atilde;o do PHP',
	'sipermissions'		=> 'Permiss&otilde;es',
	'sidirperms'		=> 'Permiss&otilde;es de Diret&oacute;rios',
	'sidirpermsmess'	=> 'Tenha certeza que todas as fun&ccedil;&otilde;es e funcionalidades do eXtplorer est&atilde;o funcionando corretamente verificando se as pastas a seguir possuem permiss&atilde;o de escrita [chmod 0777]',
	'sionoff'			=> array( 'On', 'Off' ),
	
	'extract_warning' => "Voc&ecirc; tem certeza que deseja extrair este arquivo? Aqui?\\nEsta opera&ccedil;&atilde;o pode sobrescrever os arquivos existentes se n&atilde;o usada com cuidado!",
	'extract_success' => "Sucesso na Extra&ccedil;&atilde;o",
	'extract_failure' => "Falha na Extra&ccedil;&atilde;o",
	
	'overwrite_files' => 'Sobrescrever arquivos existentes?',
	"viewlink"		=> "VER",
	"actview"		=> "Mostrar fonte do arquivo",
	
	// added by Paulino Michelazzo to fun_chmod.php file
	'recurse_subdirs'	=> 'Recursivo nos Subdiret&oacute;rios?',
	
	// added by Paulino Michelazzo to footer.php file
	'check_version'	=> 'Verificar nova vers&atilde;o',
	
	// added by Paulino Michelazzo to fun_rename.php file
	'rename_file'	=>	'Renomear um diret&oacute;rio ou arquivo...',
	'newname'		=>	'Novo nome',
	
	// added by Paulino Michelazzo to fun_edit.php file
	'returndir'	=>	'Retornar ao diret&oacute;rio depois de salvar?',
	'line'		=> 	'Linha',
	'column'	=>	'Coluna',
	'wordwrap'	=>	'Quebrar Linhas (Somente no IE)',
	'copyfile'	=>	'Copiar o conte&uacute;do dentro do arquivo',
	
	// Bookmarks
	'quick_jump' => 'Acesso r&aacute;pido para',
	'already_bookmarked' => 'Este diret�rio j� foi adicionado',
	'bookmark_was_added' => 'Este diret�rio foi adicionado a lista de favoritos.',
	'not_a_bookmark' => 'Este diret�rio n�o � um favorito.',
	'bookmark_was_removed' => 'Este diret�rio foi removido da lista de favoritos.',
	'bookmarkfile_not_writable' => "Falha na inclus�o do diret�rio %s.\n O arquivo de favoritos '%s' \nn�o permite escrita.",
	
	'lbl_add_bookmark' => 'Adicionar este diret&oacute;rio como favorito',
	'lbl_remove_bookmark' => 'Remover este diret&oacute;rio dos favoritos',
	
	'enter_alias_name' => 'Digite um apelido para este favorito',
	
	'normal_compression' => 'compress&atilde;o normal',
	'good_compression' => 'boa compress&atilde;o',
	'best_compression' => '&oacute;tima compress&atilde;o',
	'no_compression' => 'sem compress&atilde;o',
	
	'creating_archive' => 'Criando arquivo...',
	'processed_x_files' => 'Processados %s de %s Arquivos',
	
	'ftp_login_lbl' => 'Digite os dados de login para o servidor de FTP',
	'ftp_login_name' => 'Usu&aacute;rio do FTP',
	'ftp_login_pass' => 'Senha do FTP',
	'ftp_hostname_port' => 'Nome do Host de FTP e porta <br />(A porta &eacute; opcional)',
	'ftp_login_check' => 'Verificando conex&atilde;o com servidor de FTP...',
	'ftp_connection_failed' => "O servidor de FTP n&atilde;o pode ser contatado. \nVerifique se ele est&aacute; funcionando em seu servidor.",
	'ftp_login_failed' => "O login do FTP falhou. Verifique o nome de usu&aacute;rio e senha e tente novamente.",
		
	'switch_file_mode' => 'Modo Atual: <strong>%s</strong>. Voc&ecirc; pode alterar para o modo %s.',
	'symlink_target' => 'Alvo para o link simb&oacute;lico',
	
	// added by Paulino Michelazzo to fun_ftpauthentication.php file
	'ftp_header' => 'Autentica��o Local do FTP',
	
	"permchange"		=> "CHMOD Success:",
	"savefile"		=> "The File was saved.",
	"moveitem"		=> "Moving succeeded.",
	"copyitem"		=> "Copying succeeded.",
	'archive_name' 	=> 'Name of the Archive File',
	'archive_saveToDir' 	=> 'Save the Archive in this directory',
	
	'editor_simple'	=> 'Simple Editor Mode',
	'editor_syntaxhighlight'	=> 'Syntax-Highlighted Mode',

	'newlink'	=> 'New File/Directory',
	'show_directories' => 'Show Directories',
	'actlogin_success' => 'Login successful!',
	'actlogin_failure' => 'Login failed, try again.',
	'directory_tree' => 'Directory Tree',
	'browsing_directory' => 'Browsing Directory',
	'filter_grid' => 'Filter',
	'paging_page' => 'Page',
	'paging_of_X' => 'of {0}',
	'paging_firstpage' => 'First Page',
	'paging_lastpage' => 'Last Page',
	'paging_nextpage' => 'Next Page',
	'paging_prevpage' => 'Previous Page',
	
	'paging_info' => 'Displaying Items {0} - {1} of {2}',
	'paging_noitems' => 'No items to display',
	'aboutlink' => 'About...',
	'password_warning_title' => 'Important - Change your Password!',
	'password_warning_text' => 'The user account you are logged in with (admin with password admin) corresponds to the default eXtplorer priviliged account. Your eXtplorer installation is open to intrusion and you should immediately fix this security hole!',
	'change_password_success' => 'Your Password has been changed!',
	'success' => 'Success',
	'failure' => 'Failure',
	'dialog_title' => 'Website Dialog',
	'upload_processing' => 'Processing Upload, please wait...',
	'upload_completed' => 'Upload successful!',
	'acttransfer' => 'Transfer from another Server',
	'transfer_processing' => 'Processing Server-to-Server Transfer, please wait...',
	'transfer_completed' => 'Transfer completed!',
	'max_file_size' => 'Maximum File Size',
	'max_post_size' => 'Maximum Upload Limit',
	'done' => 'Done.',
	'permissions_processing' => 'Applying Permissions, please wait...',
	'archive_created' => 'The Archive File has been created!',
	'save_processing' => 'Saving File...',
	'current_user' => 'This script currently runs with the permissions of the following user:',
	'your_version' => 'Your Version',
	'search_processing' => 'Searching, please wait...',
	'url_to_file' => 'URL of the File',
	'file' => 'File'
);
?>
