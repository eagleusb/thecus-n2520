<?php

// French Language Module for joomlaXplorer (translated by Olivier Pariseau and Alexandre PRIETO)

$GLOBALS["charset"] = "utf-8";
$GLOBALS["text_dir"] = "ltr"; // ('ltr' for left to right, 'rtl' for right to left)
$GLOBALS["date_fmt"] = "d/m/Y H:i";
$GLOBALS["error_msg"] = array(
	// error
	"error"			=> "Erreur(s)",
	"back"			=> "Page pr&eacute;c&eacute;dente",
	
	// root
	"home"				=> "Le r&eacute;pertoire home n'existe pas, v&eacute;rifiez vos pr&eacute;f&eacute;rences.",
	"abovehome"			=> "Le r&eacute;pertoire courant ne semble pas &ecirc;tre dans home.",
	"targetabovehome"	=> "Le r&eacute;pertoire cible ne semble pas &ecirc;tre dans home.",
	
	// exist
	"direxist"			=> "Ce r&eacute;pertoire est inexistant.",
	"filedoesexist"	=> "Ce fichier existe d&eacute;j&agrave;.",
	"fileexist"			=> "Ce fichier est inexistant.",
	"itemdoesexist"		=> "Cet &eacute;l&eacute;ment existe d&eacute;j&agrave;.",
	"itemexist"			=> "Cet &eacute;l&eacute;ment est inexistant.",
	"targetexist"		=> "Le r&eacute;pertoire cible est inexistant.",
	"targetdoesexist"	=> "Cet &eacute;l&eacute;ment cible existe d&eacute;j&agrave;.",
	
	// open
	"opendir"		=> "Ouverture du r&eacute;pertoire impossible.",
	"readdir"		=> "Lecture du r&eacute;pertoire impossible.",
	
	// access
	"accessdir"			=> "Vous ne poss&eacute;dez pas les droits pour acc&eacute;der &agrave; ce r&eacute;pertoire.",
	"accessfile"		=> "Vous ne poss&eacute;dez pas les droits pour acc&eacute;der &agrave; ce fichier.",
	"accessitem"		=> "Vous ne poss&eacute;dez pas les droits pour acc&eacute;der &agrave; cet &eacute;l&eacute;ment.",
	"accessfunc"		=> "Vous ne poss&eacute;dez pas les droits pour utiliser cette fonction.",
	"accesstarget"		=> "Vous ne poss&eacute;dez pas les droits pour acc&eacute;der au repertoire cible.",
	
	// actions
	"permread"		=> "Echec de la lecture des permissions.",
	"permchange"	=> "Echec du changement des permissions.",
	"openfile"		=> "Echec ouverture du fichier.",
	"savefile"		=> "Echec de la sauvegarde du fichier.",
	"createfile"	=> "Echec de la cr&eacute;ation du fichier.",
	"createdir"		=> "Echec de la cr&eacute;ation du r&eacute;pertoire.",
	"uploadfile"	=> "Echec envoi du fichier.",
	"copyitem"		=> "Echec de la copie.",
	"moveitem"		=> "Echec du d&eacute;placement.",
	"delitem"		=> "Echec de la suppression.",
	"chpass"		=> "Echec du changement de mot de passe.",
	"deluser"		=> "Echec de la suppression Usager.",
	"adduser"		=> "Echec ajout Usager.",
	"saveuser"		=> "Echec sauvegarde Usager.",
	"searchnothing"	=> "Vous devez entrez un &eacute;l&eacute;ment &agrave; chercher.",
	
	// misc
	"miscnofunc"		=> "Fonctionalit&eacute; non disponible.",
	"miscfilesize"		=> "La taille du fichier exc&egrave;de la taille maximale autoris&eacute;e.",
	"miscfilepart"		=> "Envoi du fichier non compl&eacute;t&eacute;.",
	"miscnoname"		=> "Vous devez entrer un nom.",
	"miscselitems"		=> "Aucun &eacute;l&eacute;ment s&eacute;lectionn&eacute;.",
	"miscdelitems"		=> "Etes-vous s&ucirc;r de vouloir supprimer : {0} &eacute;l&eacute;ment(s)?",
	"miscdeluser"		=> "Etes-vous s&ucirc;r de vouloir supprimer l'usager {0}?",
	"miscnopassdiff"	=> "Le nouveau mot de passe est indentique au pr&eacute;c&eacute;dent.",
	"miscnopassmatch"	=> "Les mots de passe diff&eacute;rent.",
	"miscfieldmissed"	=> "Un champs requis est vide.",
	"miscnouserpass"	=> "Nom ou mot de passe invalide.",
	"miscselfremove"	=> "Vous ne pouvez pas supprimer votre compte.",
	"miscuserexist"		=> "Ce nom existe d&eacute;j&agrave;.",
	"miscnofinduser"	=> "Usager non trouv&eacute;.",
	"extract_noarchive" => "Ce fichier ne correspond pas une archive extractible.",
	"extract_unknowntype" => "Type Archive inconnue",
	
	'chmod_none_not_allowed'	=> 'La suppression de tous les droits est impossible',
	'archive_dir_notexists'		=> 'Le r&eacute;pertoire sp&eacute;cifi&eacute; pour la sauvegarde est inexistant.',
	'archive_dir_unwritable'	=> 'Le r&eacute;pertoire sp&eacute;cifi&eacute; pour la sauvegarde doit &ecirc;tre en droit Ecriture.',
	'archive_creation_failed'	=> 'Echec de la cr&eacute;ation du fichier Archive'
);
$GLOBALS["messages"] = array(
	// links
	"permlink"		=> "Changer les permissions",
	"editlink"		=> "Editer",
	"downlink"		=> "T&eacute;l&eacute;charger",
	"uplink"		=> "Dossier parent",
	"homelink"		=> "Racine",
	"reloadlink"	=> "Rafra&icirc;chir",
	"copylink"		=> "Copier",
	"movelink"		=> "D&eacute;placer",
	"dellink"		=> "Supprimer",
	"comprlink"		=> "Archiver",
	"adminlink"		=> "Administration",
	"logoutlink"	=> "D&eacute;connecter",
	"uploadlink"	=> "Envoyer",
	"searchlink"	=> "Rechercher",
	"extractlink"	=> "Extraction Archive",
	'chmodlink'		=> 'Changer les droits (CHMOD) des R&eacute;pertoire/Fichiers', // new mic
	'mossysinfolink'	=> 'Informations Syst&egrave;me, Server, PHP, mySQL)', // new mic
	'logolink'		=> 'Visiter le site de eXtplorer (nouvelle fen&ecirc;tre)', // new mic
	
	// list
	"nameheader"		=> "Nom",
	"sizeheader"		=> "Taille",
	"typeheader"		=> "Type",
	"modifheader"		=> "Modifi&eacute;",
	"permheader"		=> "Permissions",
	"actionheader"		=> "Actions",
	"pathheader"		=> "Chemin",
	
	// buttons
	"btncancel"		=> "Annuler",
	"btnsave"		=> "Sauver",
	"btnchange"		=> "Changer",
	"btnreset"		=> "R&eacute;initialiser",
	"btnclose"		=> "Fermer",
	"btncreate"		=> "Cr&eacute;er",
	"btnsearch"		=> "Chercher",
	"btnupload"		=> "Envoyer",
	"btncopy"		=> "Copier",
	"btnmove"		=> "D&eacute;placer",
	"btnlogin"		=> "Connecter",
	"btnlogout"		=> "D&eacute;connecter",
	"btnadd"		=> "Ajouter",
	"btnedit"		=> "Editer",
	"btnremove"		=> "Supprimer",
	
	// user messages, new in joomlaXplorer 1.3.0
	'renamelink'			=> "Renommer",
	'confirm_delete_file' 	=> 'Etes-vous s&ucirc;r de vouloir supprimer le fichier %s',
	'success_delete_file'	=> 'Fichier supprim&eacute; avec succ&egrave;s.',
	'success_rename_file' 	=> 'Le r&eacute;pertoire/fichier %s a &eacute;t&eacute; renomm&eacute; %s.',
	
	
	// actions
	"actdir"			=> "R&eacute;pertoire",
	"actperms"			=> "Changer les permissions",
	"actedit"			=> "Editer le fichier",
	"actsearchresults"	=> "R&eacute;sultats de la recherche",
	"actcopyitems"		=> "Copier les &eacute;l&eacute;ments",
	"actcopyfrom"		=> "Copier de /%s &agrave; /%s ",
	"actmoveitems"		=> "D&eacute;placer les &eacute;l&eacute;ments",
	"actmovefrom"		=> "D&eacute;placer de /%s &agrave; /%s ",
	"actlogin"			=> "Connecter",
	"actloginheader"	=> "Connecter pour utiliser QuiXplorer",
	"actadmin"			=> "Administration",
	"actchpwd"			=> "Changer le mot de passe",
	"actusers"			=> "Usagers",
	"actarchive"		=> "Archiver les &eacute;l&eacute;ments",
	"actupload"			=> "Envoyer les fichiers",
	
	// misc
	"miscitems"				=> "El&eacute;ments",
	"miscfree"				=> "Disponible",
	"miscusername"			=> "Usager",
	"miscpassword"			=> "Mot de passe",
	"miscoldpass"			=> "Ancien mot de passe",
	"miscnewpass"			=> "Nouveau mot de passe",
	"miscconfpass"			=> "Confirmer le mot de passe",
	"miscconfnewpass"		=> "Confirmer le nouveau mot de passe",
	"miscchpass"			=> "Changer le mot de passe",
	"mischomedir"			=> "R&eacute;pertoire home",
	"mischomeurl"			=> "Chemin Racine",
	"miscshowhidden"		=> "Voir les &eacute;l&eacute;ments cach&eacute;s",
	"mischidepattern"		=> "Cacher pattern",
	"miscperms"				=> "Permissions",
	"miscuseritems"			=> "(nom, r&eacute;pertoire home, Voir les &eacute;l&eacute;ments cach&eacute;s, permissions, actif)",
	"miscadduser"			=> "Ajouter un usager",
	"miscedituser"			=> "Editer usager '%s'",
	"miscactive"			=> "Actif",
	"misclang"				=> "Langue",
	"miscnoresult"			=> "Aucun r&eacute;sultats.",
	"miscsubdirs"			=> "Rechercher dans les sous-r&eacute;pertoires",
	"miscpermnames"			=> array("Lecture seulement","Modifier","Changer le mot de passe","Modifier & Changer le mot de passe","Administrateur"),
	"miscyesno"			 	=> array("Oui","Non","O","N"),
	"miscchmod"				=> array("Propri&eacute;taire", "Groupe", "Publique"),
	// from here all new by mic
	'miscowner'			=> 'Propri&eacute;taire',
	'miscownerdesc'		=> '<strong>Description:</strong><br />Propri&eacute;taire (UID) /<br />Groupe (GID)<br />Droits actuels:<br /><strong> %s ( %s ) </strong>/<br /><strong> %s ( %s )</strong>',

	// sysinfo (new by mic)
	'simamsysinfo'		=> 'Informations Syst&egrave;me',
	'sisysteminfo'		=> 'Info Syst&egrave;me',
	'sibuilton'			=> 'OS',
	'sidbversion'		=> 'Version Base de Donn&eacute;es (MySQL)',
	'siphpversion'		=> 'Version PHP',
	'siphpupdate'		=> 'INFORMATION: <span style="color: red;">La version de PHP que vous utilisez n\'est <strong>plus</strong> d\'actualit&eacute;!</span><br />Afin de garantir un fonctionnement maximum de eXtplorer et addons,<br />Vous devez utiliser au minimum <strong>PHP.Version 4.3</strong>!',
	'siwebserver'		=> 'Webserver',
	'siwebsphpif'		=> 'WebServer - Interface PHP',
	'simamboversion'	=> 'Version eXtplorer',
	'siuseragent'		=> 'Version du Navigateur',
	'sirelevantsettings' => 'Param&egrave;tres PHP avanc&eacute;s',
	'sisafemode'		=> 'Mode s&eacute;curis&eacute;',
	'sibasedir'			=> 'Ouvrir r&eacute;pertoire de base',
	'sidisplayerrors'	=> 'Erreurs PHP',
	'sishortopentags'	=> 'Tags',
	'sifileuploads'		=> 'Date Envoi',
	'simagicquotes'		=> 'Magic Quotes',
	'siregglobals'		=> 'Register Globals',
	'sioutputbuf'		=> 'Buffer',
	'sisesssavepath'	=> 'Chemin de Sauvegarde Session',
	'sisessautostart'	=> 'Session Automatique',
	'sixmlenabled'		=> 'XML activ&eacute;',
	'sizlibenabled'		=> 'ZLIB activ&eacute;',
	'sidisabledfuncs'	=> 'Fonction non valid&eacute;es',
	'sieditor'			=> 'Editeur WYSIWYG',
	'siconfigfile'		=> 'Fichier de configuration',
	'siphpinfo'			=> 'Infos PHP',
	'siphpinformation'	=> 'Informations PHP',
	'sipermissions'		=> 'Permissions',
	'sidirperms'		=> 'Permissions R&eacute;pertoire',
	'sidirpermsmess'	=> 'Pour obtenir un fonctionnement total, assurez vous que vous poss&egrave;dez les droits en &eacute;criture sur les r&eacute;pertoires et fichiers (chmod). Vous pouvez vous connecter en FTP pour modifier ces droits',
	'sionoff'			=> array( 'Marche', 'Arrêt' ),
	
	'extract_warning' => "Voulez-vous r&eacute;ellement extraire ce fichier Ici? Ce fichier remplacera le fichier si existant!",
	'extract_success' => "Extraction r&eacute;ussie",
	'extract_failure' => "Extraction &eacute;chou&eacute;e",
	
	'overwrite_files'	=> 'Remplacer les fichiers?',
	"viewlink"			=> "Aper&ccedil;u",
	"actview"			=> "Aper&ccedil;u des sources du fichier",
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_chmod.php file
	'recurse_subdirs'	=> 'R&eacute;cursif dans les sous-r&eacute;pertoires',
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to footer.php file
	'check_version'	=> 'V&eacute;rifier si une version plus r&eacute;cente existe',
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_rename.php file
	'rename_file'	=>	'Renommer le r&eacute;pertoire ou fichier...',
	'newname'		=>	'Nouveau nom',
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_edit.php file
	'returndir'	=>	'Retourner au r&eacute;pertoire apr&egrave;s sauvegarde',
	'line'		=> 	'Ligne',
	'column'	=>	'Colonne',
	'wordwrap'	=>	'Wordwrap: (IE seulement)',
	'copyfile'	=>	'Copier le fichier avec ce nom de fichier',
	
	// Bookmarks
	'quick_jump' 			=> 'Saut rapide vers',
	'already_bookmarked' 	=> 'Ce r&eacute;pertoire existe d&eacute;j&agrave; dans le signet',
	'bookmark_was_added' 	=> 'R&eacute;pertoire ajout&eacute; &agrave; la liste des signets.',
	'not_a_bookmark' 		=> 'Ce r&eacute;pertoire ne correspond pas &agrave; un signet.',
	'bookmark_was_removed' 	=> 'Ce r&eacute;pertoire &agrave; &eacute;t&eacute; supprim&eacute; de la liste des signets.',
	'bookmarkfile_not_writable' => "Echec lors de %s dans le signet. Le fichier signet '%s' ne poss&egrave;de pas les droits Ecriture.",
	
	'lbl_add_bookmark' 		=> 'Ajouter ce r&eacute;pertoire au signet',
	'lbl_remove_bookmark' 	=> 'Supprimer ce r&eacute;pertoire de la liste des signets',
	
	'enter_alias_name' 		=> 'Veuillez entrez un alias pour ce signet',
	
	'normal_compression' 	=> 'Compression normal',
	'good_compression'		=> 'Compression &eacute;lev&eacute;e',
	'best_compression' 		=> 'Compression optimale',
	'no_compression' 		=> 'Aucune compression',
	
	'creating_archive' 		=> 'Cr&eacute;ation du Fichier Archive...',
	'processed_x_files' 	=> '%s de %s fichiers trait&eacute;s',
	
	'ftp_header' 			=> 'Authentification FTP Locale',
	'ftp_login_lbl' 		=> 'Veuillez entrez un login de connexion pour le serveur FTP',
	'ftp_login_name' 		=> "Nom d'utilisateur FTP",
	'ftp_login_pass' 		=> 'Mot de passe FTP',
	'ftp_hostname_port' 	=> 'Nom du serveur FTP et Port <br />(Le port est optionnel)',
	'ftp_login_check' 		=> 'Test connexion serveur FTP...',
	'ftp_connection_failed' => "Connexion au serveur FTP impossible. Veuillez v&eacute;rifiez que le service FTP soit activ&eacute; sur le serveur.",
	'ftp_login_failed' 		=> "Login FTP incorrect. Veuillez v&eacute;rifiez le nom et mot de passe utilisateur.",
		
	'switch_file_mode' 		=> 'Mode courant: %s. Vous pouvez passer en mode %s.',
	'symlink_target' 		=> 'Cible du lien symbolique',
	
	"permchange"			=> "Changement CHMOD r&eacute;ussi:",
	"savefile"				=> "Le fichier est sauvegard&eacute;.",
	"moveitem"				=> "D&eacute;placement r&eacute;ussi.",
	"copyitem"				=> "Copie r&eacute;ussie.",
	'archive_name' 			=> "Nom Archive",
	'archive_saveToDir' 	=> "Sauvegarder dans ce r&eacute;pertoire",
	
	'editor_simple'			=> 'Mode Editeur Simple',
	'editor_syntaxhighlight'	=> 'Coloration Syntaxique',

	'newlink'				=> 'Nouveau Fichier/Dossier',
	'show_directories' 		=> 'Voir les Dossiers',
	'actlogin_success' 		=> 'Connexion r&eacute;ussie!',
	'actlogin_failure' 		=> 'Connexion &eacute;chou&eacute;. Veuillez essayer &agrave; nouveau.',
	'directory_tree' 		=> 'Arborescense Dossier',
	'browsing_directory' 	=> 'Parcourir Dossier',
	'filter_grid' 			=> 'Filtre',
	'paging_page'			=> 'Page',
	'paging_of_X'			=> 'de {0}',
	'paging_firstpage' 		=> 'Premi&egrave;re page',
	'paging_lastpage' 		=> 'Derni&egrave;re page',
	'paging_nextpage' 		=> 'Page suivante',
	'paging_prevpage' 		=> 'Page pr&eacute;c&eacute;dente',
	
	'paging_info' 			=> 'Affiche El&eacute;ment {0} - {1} de {2}',
	'paging_noitems' 		=> 'Aucun &eacute;l&eacute;ment &agrave; afficher',
	'aboutlink' 			=> 'Au sujet de...',
	'password_warning_title' 	=> 'Important - Changer votre mot de passe!',
	'password_warning_text' 	=> 'Le compte usager pour votre acc&egrave;s (admin avec mot de passe admin) correspond au compte privil&eacute;gi&eacute; eXtplorer par defaut. Votre installation eXtplorer est sujette &agrave; intrusion et vous devez corriger cette faille de s&eacute;curit&eacute; imm&eacute;diatement!',
	'change_password_success' 	=> 'Votre mot de passe a &eacute;t&eacute; chang&eacute;!',
	'success' 				=> 'Succ&egrave;s',
	'failure' 				=> 'Echec',
	'dialog_title' 			=> 'Dialogue site',
	'upload_processing' 	=> 'Envoi...',
	'upload_completed' 		=> 'Envoi effectu&eacute;!',
	'acttransfer' 			=> 'Transfert depuis une URL',
	'transfer_processing' 	=> 'Transfert...',
	'transfer_completed' 	=> 'Transfert effectu&eacute;!',
	'max_file_size' 		=> 'Poids Maximum',
	'max_post_size' 		=> 'Limite Envoi',
	'done' 					=> 'Annuler.',
	'permissions_processing' => 'Application des Permissions...',
	'archive_created'		=> 'Le fichier Archives est cr&eacute;&eacute;!',
	'save_processing' 		=> 'Sauvegarde...',
	'current_user' 			=> 'Le script courant fonctionne avec les permissions utilisateur de:',
	'your_version' 			=> 'Votre Version',
	'search_processing' 	=> 'Recherche...',
	'url_to_file' 			=> 'URL du Fichier',
	'file' 					=> 'Fichier',
	'create_title' => 'Create New Directory/File'
);
?>
