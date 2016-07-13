<?php

// Italiano Language Module for v2.3 (translated by the TTi joomla.it)
global $_VERSION;

$GLOBALS["charset"] = "utf-8";
$GLOBALS["text_dir"] = "ltr"; // ('ltr' for left to right, 'rtl' for right to left)
$GLOBALS["date_fmt"] = "Y/m/d H:i";
$GLOBALS["error_msg"] = array(
	// error
	"error"			=> "ERRORE(I)",
	"back"			=> "Indietro",

	// root
	"home"			=> "La cartella principale non esiste, controllare la configurazione.",
	"abovehome"		=> "Questa cartella non pu&#242; essere fuori dalla cartella principale.",
	"targetabovehome"	=> "La cartella di destinazione non pu&#242; risiedere fuori dalla cartella principale.",

	// exist
	"direxist"		=> "Questa cartella non esiste.",
	"filedoesexist"	=> "Questo file esiste gi&#224;.",
	"fileexist"		=> "Questo file non esiste.",
	"itemdoesexist"		=> "Questo elemento esiste gi&#224;.",
	"itemexist"		=> "Questo elemento non esiste.",
	"targetexist"		=> "La cartella di destinazione non esiste.",
	"targetdoesexist"	=> "Elemento di destinazione esiste gi&#224;.",

	// open
	"opendir"		=> "Impossibile aprire la cartella.",
	"readdir"		=> "Impossibile leggere nella cartella.",

	// access
	"accessdir"		=> "Non sei autorizzato ad accedere a questa cartella.",
	"accessfile"		=> "Non sei autorizzato ad accedere a questo file.",
	"accessitem"		=> "Non sei autorizzato ad accedere a questo elemento.",
	"accessfunc"		=> "Non sei autorizzato ad utilizzare questa funzione.",
	"accesstarget"		=> "Non sei autorizzato ad accedere alla cartella di destinazione.",

	// actions
	"permread"		=> "Richiesta permessi fallita.",
	"permchange"		=> "Modifica permessi fallita.",
	"openfile"		=> "Apertura del file fallita.",
	"savefile"		=> "Salvataggio del file fallito.",
	"createfile"		=> "Creazione del file fallita.",
	"createdir"		=> "Creazione della cartella fallita.",
	"uploadfile"		=> "Caricamento del file fallito.",
	"copyitem"		=> "Copia fallita.",
	"moveitem"		=> "Spostamento fallito.",
	"delitem"		=> "Rimozione fallita.",
	"chpass"		=> "Modifica della password fallita.",
	"deluser"		=> "Rimozione dell&#180;utente fallita.",
	"adduser"		=> "Inserimento dell&#180;utente fallito.",
	"saveuser"		=> "Salvataggio dell&#180;utente fallito.",
	"searchnothing"		=> "&#200; necessario impostare un criterio di ricerca.",

	// misc
	"miscnofunc"		=> "Funzione non disponibile.",
	"miscfilesize"		=> "Il file supera le dimensioni massime.",
	"miscfilepart"		=> "File caricato solo parzialmente.",
	"miscnoname"		=> "Necessario inserire un nome.",
	"miscselitems"		=> "Non � stato selezionato un elemento(i).",
	"miscdelitems"		=> "Siamo sicuri di voler rimuovere questi {0} elemento(i)?",
	"miscdeluser"		=> "Siamo sicuri di voler rimuovere questo utente '{0}'?",
	"miscnopassdiff"	=> "Nuova password identica a quella in uso.",
	"miscnopassmatch"	=> "Le password non coincidono.",
	"miscfieldmissed"	=> "Non impostato un campo importante.",
	"miscnouserpass"	=> "Utente o password errati.",
	"miscselfremove"	=> "Impossibile rimuovere la propria utenza.",
	"miscuserexist"		=> "Utente gi� esistente.",
	"miscnofinduser"	=> "Impossibile trovare questo utente.",
	"extract_noarchive" => "Il file non � un file archivio estraibile.",
	"extract_unknowntype" => "Tipo archivio sconosciuto",
	
	'chmod_none_not_allowed' => 'Il cambio delle autorizzazione su <nessuna> non è permesso',
	'archive_dir_notexists' => 'La directory specificata per il salvataggio non esiste.',
	'archive_dir_unwritable' => 'Specificare una directory su cui poter scrivere per poter salvare l’archivio.',
	'archive_creation_failed' => 'Salvataggio del file archivio non riuscito'
);
$GLOBALS["messages"] = array(
	// links
	"permlink"		=> "Modifica dei permessi",
	"editlink"		=> "Modifica",
	"downlink"		=> "Scarica",
	"uplink"		=> "Precedente",
	"homelink"		=> "Pagina Principale",
	"reloadlink"		=> "Ricarica",
	"copylink"		=> "Copia",
	"movelink"		=> "Sposta",
	"dellink"		=> "Cancella",
	"comprlink"		=> "Archivia",
	"adminlink"		=> "Amministra",
	"logoutlink"		=> "Esci",
	"uploadlink"		=> "Carica",
	"searchlink"		=> "Cerca",
	"extractlink"	=> "Estrai archivio",
	'chmodlink'		=> 'Modifica (chmod) Diritti (Cartella/File)', // new mic
	'mossysinfolink'	=> 'eXtplorer Informazioni di sistema (eXtplorer, Server, PHP, mySQL)', // new mic
	'logolink'		=> 'Visita il sito web ufficiale joomlaXplorer (nuova finestra)', // new mic

	// list
	"nameheader"		=> "Nome",
	"sizeheader"		=> "Dimensione",
	"typeheader"		=> "Tipo",
	"modifheader"		=> "Modificato",
	"permheader"		=> "Permessi",
	"actionheader"		=> "Azioni",
	"pathheader"		=> "Percorso",

	// buttons
	"btncancel"		=> "Annulla",
	"btnsave"		=> "Salva",
	"btnchange"		=> "Modifica",
	"btnreset"		=> "Resetta",
	"btnclose"		=> "Chiudi",
	"btncreate"		=> "Crea",
	"btnsearch"		=> "Cerca",
	"btnupload"		=> "Carica",
	"btncopy"		=> "Copia",
	"btnmove"		=> "Sposta",
	"btnlogin"		=> "Entra",
	"btnlogout"		=> "Esci",
	"btnadd"		=> "Aggiungi",
	"btnedit"		=> "Modifica",
	"btnremove"		=> "Rimuovi",

	// user messages, new in joomlaXplorer 1.3.0
	'renamelink'	=> 'Rinomina',
	'confirm_delete_file' => 'Sei certo di voler cancellare questo file? \\n%s',
	'success_delete_file' => 'Elemento(i) correttamente cancellato.',
	'success_rename_file' => 'Cartella/file %s rinomina correttamente in %s.',

	// actions
	"actdir"		=> "Cartella",
	"actperms"		=> "Modifica permessi",
	"actedit"		=> "Modifica file",
	"actsearchresults"	=> "Risultati della ricerca",
	"actcopyitems"		=> "Copia elemento(i)",
	"actcopyfrom"		=> "Copia da /%s a /%s ",
	"actmoveitems"		=> "Sposta elemento(i)",
	"actmovefrom"		=> "Sposta da /%s a /%s ",
	"actlogin"		=> "Entra",
	"actloginheader"	=> "Entra per utilizzare QuiXplorer",
	"actadmin"		=> "Amministrazione",
	"actchpwd"		=> "Modifica password",
	"actusers"		=> "Utenti",
	"actarchive"		=> "Archivio elemento(i)",
	"actupload"		=> "Caricamento file(s)",

	// misc
	"miscitems"		=> "Elemento(i)",
	"miscfree"		=> "Disponibili",
	"miscusername"		=> "Utente",
	"miscpassword"		=> "Password",
	"miscoldpass"		=> "Vecchia password",
	"miscnewpass"		=> "Nuova password",
	"miscconfpass"		=> "Conferma password",
	"miscconfnewpass"	=> "Conferma nuova password",
	"miscchpass"		=> "Modifica password",
	"mischomedir"		=> "Cartella principale",
	"mischomeurl"		=> "URL Home",
	"miscshowhidden"	=> "Mostrare gli elementi nascosti",
	"mischidepattern"	=> "Nascondere il percorso",
	"miscperms"		=> "Permessi",
	"miscuseritems"		=> "(nome, cartella principale, mostrare gli elementi nascosti, permessi, attivo)",
	"miscadduser"		=> "aggiungi utente",
	"miscedituser"		=> "modifica utente '%s'",
	"miscactive"		=> "Attivo",
	"misclang"		=> "Lingua",
	"miscnoresult"		=> "Nessun risultato trovato.",
	"miscsubdirs"		=> "Ricerca sotto cartella",
	"miscpermnames"		=> array("Sola lettura","Modifica","Modifica password","Modifica e sostituzione password",
					"Amministratore"),
	"miscyesno"		=> array("Si","No","S","N"),
	"miscchmod"		=> array("Proprietario", "Gruppo", "Pubblico"),

	// from here all new by mic
	'miscowner'			=> 'Proprietario',
	'miscownerdesc'		=> '<strong>Descrizione:</strong><br />Utente (UID) /<br />Gruppo (GID)<br />Diritti correnti:<br /><strong> %s ( %s ) </strong>/<br /><strong> %s ( %s )</strong>',

	// sysinfo (new by mic)
	'simamsysinfo'		=> 'eXtplorer Info Sistema',
	'sisysteminfo'		=> 'Info Sistema',
	'sibuilton'			=> 'Sitema opertivo',
	'sidbversion'		=> 'Versione Database (MySQL)',
	'siphpversion'		=> 'Versione PHP',
	'siphpupdate'		=> 'INFORMAZIONI: <span style="color: red;">La versione PHP version utilizzata <strong>non &#232;</strong> acggiornata!</span><br />Per garantire il corretto funzionamento di tutte le funzioni di Joomla e degli addon,<br />dovete almeno possedere la versione <strong>PHP 4.3</strong>!',
	'siwebserver'		=> 'Server web',
	'siwebsphpif'		=> 'Server web - Interfaccia PHP',
	'simamboversion'	=> 'eXtplorer Versione',
	'siuseragent'		=> 'Versione Browser',
	'sirelevantsettings' => 'Importanti Settaggi PHP',
	'sisafemode'		=> 'Modalità sicura',
	'sibasedir'			=> 'Apri basedir (directory base)',
	'sidisplayerrors'	=> 'Errori PHP',
	'sishortopentags'	=> 'Abbrevia tag aperti',
	'sifileuploads'		=> 'Caricamenti file',
	'simagicquotes'		=> 'Quotazione Magic',
	'siregglobals'		=> 'Registra globali',
	'sioutputbuf'		=> 'Buffer di uscita',
	'sisesssavepath'	=> 'Sessione Salvapercorso',
	'sisessautostart'	=> 'Sessione avvio automatico',
	'sixmlenabled'		=> 'XML attivato',
	'sizlibenabled'		=> 'ZLIB attivato',
	'sidisabledfuncs'	=> 'Funzioni non abilitate',
	'sieditor'			=> 'Editor WYSIWYG',
	'siconfigfile'		=> 'File Config',
	'siphpinfo'			=> 'Info PHP',
	'siphpinformation'	=> 'Informazioni PHP',
	'sipermissions'		=> 'Permessi',
	'sidirperms'		=> 'Permessi cartella',
	'sidirpermsmess'	=> 'Per funzionare correttamente tutte le funzioni e le caratteristiche di eXtplorer devono ottenere i permessi di scrittura settati [chmod 0777] alle cartelle',
	'sionoff'			=> array( 'Attivo', 'Disattivato' ),

	'extract_warning' => "Voi estrarre questo file? Qui?\\nQuesta operazione sovrascrive i file esistenti e va usata con attenzione!",
	'extract_success' => "Estrazione eseguita correttamente",
	'extract_failure' => "Estrazione fallita",
	
	'overwrite_files' => 'Sovrascrive file esistente/i?',
	"viewlink"		=> "VISTA",
	"actview"		=> "Mostra origine file",
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_chmod.php file
	'recurse_subdirs'	=> 'Torna a directory secondarie?',
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to footer.php file
	'check_version'	=> 'Verifica la presenza dell’ultima versione?',
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_rename.php file
	'rename_file'	=>	'Rinomina directory o file...',
	'newname'		=>	'Nuovo nome',
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_edit.php file
	'returndir'	=>	'Torna alla directory dopo il salvataggio?',
	'line'		=> 	'Riga',
	'column'	=>	'Colonna',
	'wordwrap'	=>	'A capo automatico: (Solo per IE)',
	'copyfile'	=>	'Copia file su questo nome ',
	
	// Bookmarks
	'quick_jump' => 'Salta a ',
	'already_bookmarked' => 'Directory già inserita nei preferiti',
	'bookmark_was_added' => 'Questa directory è stata aggiunta all’elenco dei preferiti.',
	'not_a_bookmark' => 'Questa directory non è tra i preferiti.',
	'bookmark_was_removed' => 'Questa directory è stata tolta dell’elenco dei preferiti.',
	'bookmarkfile_not_writable' => "Impossibile %s nei preferiti.\n Il file dei preferiti '%s' \non è scrivibile.",
	
	'lbl_add_bookmark' => 'Aggiungere questa directory come preferiti',
	'lbl_remove_bookmark' => 'Rimuovere questa directory dall’elenco preferiti',
	
	'enter_alias_name' => 'Digitare l’alias per questo preferito',
	
	'normal_compression' => 'compressione normale',
	'good_compression' => 'compressione buona',
	'best_compression' => 'compressione migliore',
	'no_compression' => 'nessuna compressione',
	
	'creating_archive' => 'Creazione file archivio...',
	'processed_x_files' => 'Elaborati %s di %s file',
	
	'ftp_header' => 'Autenticazione FTP locale',
	'ftp_login_lbl' => 'Digitare le credenziali per l’accesso al server FTP',
	'ftp_login_name' => 'Nome utente FTP',
	'ftp_login_pass' => 'Password FTP',
	'ftp_hostname_port' => 'Nome host server FTP e porta <br />(La porta è opzionale)',
	'ftp_login_check' => 'Controllo connessione FTP…',
	'ftp_connection_failed' => "Impossibile contattare il server FTP \nVerificare che il server FTP sia in esecuzione sul server.",
	'ftp_login_failed' => "Accesso all’FTP non riuscito. Controllare nome utente e password e ritentare.",
		
	'switch_file_mode' => 'Modlaità corrente: <strong>%s</strong>. È possibile passare alla modalità %s.',
	'symlink_target' => 'Destinazione del collegamento Symbolic (simbolico)',
	
	"permchange"		=> "CHMOD OK:",
	"savefile"		=> "File salvato.",
	"moveitem"		=> "Spostamento effettuato.",
	"copyitem"		=> "Copia effettuata.",
	'archive_name' 	=> 'Nome del file archivio',
	'archive_saveToDir' 	=> 'Salva archivio in questa directory',
	
	'editor_simple'	=> 'Modalità editor semplice',
	'editor_syntaxhighlight'	=> 'Modalità evidenziazione sintassi',

	'newlink'	=> 'Nuovo file/directory',
	'show_directories' => 'Mostra directory',
	'actlogin_success' => 'Accesso effettuato con successo',
	'actlogin_failure' => 'Accesso non effettuato, ritenta.',
	'directory_tree' => 'Struttura directory',
	'browsing_directory' => 'Sfoglia directory',
	'filter_grid' => 'Filtro',
	'paging_page' => 'Pagina',
	'paging_of_X' => 'di {0}',
	'paging_firstpage' => 'Prima pagina',
	'paging_lastpage' => 'Ultima pagina',
	'paging_nextpage' => 'Pagina successiva',
	'paging_prevpage' => 'Pagina precedente',
	
	'paging_info' => 'Visualizza elementi {0} - {1} di {2}',
	'paging_noitems' => 'Nessun elemento da visualizzare',
	'aboutlink' => 'Informazioni su…',
	'password_warning_title' => 'Importante…Cambiare la password!',
	'password_warning_text' => 'L’account utente con il quale si è effettuato l’accesso (admin con password admin) corrisponde all’account privilegiato di eXtplorer. L’installazione di eXtplorer è aperta a intrusione, risolvere subito questo problema di protezione!',
	'change_password_success' => 'La password è stata cambiata!',
	'success' => 'OK',
	'failure' => 'Non riuscitp',
	'dialog_title' => 'Dialogo con sito Internet',
	'upload_processing' => 'Caricamento in corso, attendere…',
	'upload_completed' => 'Caricamento eseguito con successo!',
	'acttransfer' => 'Trasferimento da un altro server',
	'transfer_processing' => 'Elaborazione del trasferimento da server a server, attendere…',
	'transfer_completed' => 'Trasferimento completato!',
	'max_file_size' => 'Dimensione max file',
	'max_post_size' => 'Limite max caricamento',
	'done' => 'OK.',
	'permissions_processing' => 'Applicazione autorizzazioni, attendere...',
	'archive_created' => 'Il file archivio è stato creato!',
	'save_processing' => 'Salvataggio file in corso…',
	'current_user' => 'Lo script è attualmente in esecuzione con le autorizzazioni dei seguenti utenti:',
	'your_version' => 'La sua versione',
	'search_processing' => 'Ricerca in corso, attendere…',
	'url_to_file' => 'URL del file',
	'file' => 'File',
	'create_title' => 'Create New Directory/File'
);
?>
