<?php
// $Id: swedish.php 80 2007-07-27 10:57:13Z soeren $
// Swedish Language Module for v2.3 (translated by the Olle Zettergren)
global $_VERSION;

$GLOBALS["charset"] = "iso-8859-1";
$GLOBALS["text_dir"] = "ltr"; // ('ltr' for left to right, 'rtl' for right to left)
$GLOBALS["date_fmt"] = "Y-m-d H:i";
$GLOBALS["error_msg"] = array(
	// error
	"error"			=> "Fel",
	"message"		=> "Meddelande(n)",
	"back"			=> "Tillbaka",

	// root
	"home"			=> "Hemkatalogen finns inte, kontrollera dina inst&auml;llningar.",
	"abovehome"		=> "Den aktuella katalogen kan inte vara ovanf&ouml;r hemkatalogen.",
	"targetabovehome"	=> "M&aring;lkatalogen kan inte vara ovanf&ouml;r hemkatalogen.",

	// exist
	"direxist"		=> "Den h&auml;r katalogen finns inte.",
	"filedoesexist"	=> "This file already exists.",
	"fileexist"		=> "Den h&auml;r filen finns inte.",
	"itemdoesexist"		=> "Det h&auml;r objektet finns redan.",
	"itemexist"		=> "Det h&auml;r objektet finns inte.",
	"targetexist"		=> "M&aring;lkatalogen finns inte.",
	"targetdoesexist"	=> "M&aring;lobjektet finns redan.",

	// open
	"opendir"		=> "Det g&aring;r inte att &ouml;ppna katalogen.",
	"readdir"		=> "Det g&aring;r inte att l&auml;sa katalogen.",

	// access
	"accessdir"		=> "Du har inte tilltr&auml;de till den h&auml;r katalog.",
	"accessfile"	=> "Du har inte tilltr&auml;de till den h&auml;r filen.",
	"accessitem"	=> "Du har inte tilltr&auml;de till det h&auml;r objektet.",
	"accessfunc"	=> "Du har inte tilltr&auml;de till den h&auml;r funktionen.",
	"accesstarget"	=> "Du har inte tilltr&auml;de till m&aring;lkatalogen.",

	// actions
	"permread"		=> "Misslyckades med att l&auml;sa filtillst&aring;ndet.",
	"permchange"	=> "CHMOD-fel (Det h&auml;r beror oftast p&aring; ett problem med vem som &auml;ger filen - t.ex. att HTTP-anv&auml;ndaren &auml;r ('wwwrun' eller 'nobody') och FTP-anv&auml;ndaren inte &auml;r densamma.)",
	"openfile"		=> "Gick inte att &ouml;ppna filen.",
	"savefile"		=> "Gick inte att spara filen.",
	"createfile"	=> "Gick inte att skapa filen.",
	"createdir"		=> "Gick inte att skapa katalogen.",
	"uploadfile"	=> "Gick inte att ladda upp filen.",
	"copyitem"		=> "Gick inte ta kopiera.",
	"moveitem"		=> "Gick inte att flytta.",
	"delitem"		=> "Gick inte att ta bort.",
	"chpass"		=> "Gick inte att byta l&ouml;senord.",
	"deluser"		=> "Gick inte att ta bort anv&auml;ndare.",
	"adduser"		=> "Gick inte att l&auml;gga till anv&auml;ndare.",
	"saveuser"		=> "Gick inte att spara anv&auml;ndare.",
	"searchnothing"	=> "Du m&aring;ste ange n&aring;gon att s&ouml;ka efter.",

	// misc
	"miscnofunc"		=> "Funktionen otillg&auml;nglig.",
	"miscfilesize"		=> "Filen &ouml;verskrider maximalt till&aring;ten storlek.",
	"miscfilepart"		=> "Filen laddades bara upp delvis.",
	"miscnoname"		=> "Du m&aring;ste ange ett namn.",
	"miscselitems"		=> "Du har inte valt n&aring;got/n&aring;gra objekt.",
	"miscdelitems"		=> "&auml;r du s&auml;ker p&aring; att du vill ta bort dessa {0} objekt?",
	"miscdeluser"		=> "&auml;r du s&auml;ker p&aring; att du vill ta bort anv&auml;ndare '{0}'?",
	"miscnopassdiff"	=> "Det nya l&ouml;senordet skiljer sig inte fr&aring;n det aktuella.",
	"miscnopassmatch"	=> "L&ouml;senorden matchar inte.",
	"miscfieldmissed"	=> "Du missade ett viktigt f&auml;lt.",
	"miscnouserpass"	=> "Anv&auml;ndarnamn eller l&ouml;senord felaktiga.",
	"miscselfremove"	=> "Du kan inte ta bort dig sj&auml;lv.",
	"miscuserexist"		=> "Anv&auml;ndaren finns redan.",
	"miscnofinduser"	=> "Kan inte hitta anv&auml;ndaren.",
	"extract_noarchive" => "Den h&auml;r filen &auml;r inte en uppackningsbar arkivfil.",
	"extract_unknowntype" => "Ok&auml;nd akrivtyp",
	
	'chmod_none_not_allowed' => '&auml;ndra r&auml;ttigheter till <none> &auml;r inte till&aring;tet',
	'archive_dir_notexists' => 'Den katalog du har angivit att spara till finns inte.',
	'archive_dir_unwritable' => 'Ange en skrivbar katalog att spara arkivet till.',
	'archive_creation_failed' => 'Misslyckades att spara akrivfilen'
	
);
$GLOBALS["messages"] = array(
	// links
	"permlink"		=> "&auml;ndra r&auml;ttigheter",
	"editlink"		=> "Redigera",
	"downlink"		=> "Ladda ner",
	"uplink"		=> "Upp",
	"homelink"		=> "Hem",
	"reloadlink"	=> "Ladda om",
	"copylink"		=> "Kopiera",
	"movelink"		=> "Flytta",
	"dellink"		=> "Ta bort",
	"comprlink"		=> "Arkiv",
	"adminlink"		=> "Admin",
	"logoutlink"	=> "Logga ut",
	"uploadlink"	=> "Ladda upp",
	"searchlink"	=> "S&ouml;k",
	"extractlink"	=> "Packa upp akrivet",
	'chmodlink'		=> '&auml;ndra (chmod) r&auml;ttigheter (Mapp/Fil(er))', // new mic
	'mossysinfolink'	=> 'eXtplorer System Information (eXtplorer, Server, PHP, mySQL)', // new mic
	'logolink'		=> 'G&aring; till siten f&ouml;r joomlaXplorer (&ouml;ppnas i nytt f&ouml;nster)', // new mic

	// list
	"nameheader"		=> "Namn",
	"sizeheader"		=> "Storlek",
	"typeheader"		=> "Type",
	"modifheader"		=> "&auml;ndrad",
	"permheader"		=> "R&auml;ttigheter",
	"actionheader"		=> "H&auml;ndelser",
	"pathheader"		=> "S&ouml;kv&auml;g",

	// buttons
	"btncancel"		=> "Avbryt",
	"btnsave"		=> "Spara",
	"btnchange"		=> "&auml;ndra",
	"btnreset"		=> "&aring;terst&auml;ll",
	"btnclose"		=> "St&auml;ng",
	"btncreate"		=> "Skapa",
	"btnsearch"		=> "S&ouml;k",
	"btnupload"		=> "Ladda upp",
	"btncopy"		=> "Kopiera",
	"btnmove"		=> "Flytta",
	"btnlogin"		=> "Logga in",
	"btnlogout"		=> "Logga ut",
	"btnadd"		=> "L&auml;gg till",
	"btnedit"		=> "Redigera",
	"btnremove"		=> "Ta bort",
	
	// user messages, new in joomlaXplorer 1.3.0
	'renamelink'	=> 'Byt namn',
	'confirm_delete_file' => 'Are you sure you want to delete this file? <br />%s',
	'success_delete_file' => 'Item(s) successfully deleted.',
	'success_rename_file' => 'The directory/file %s was successfully renamed to %s.',
	
	// actions
	"actdir"			=> "Katalog",
	"actperms"			=> "&auml;ndra r&auml;ttigheter",
	"actedit"			=> "Redigera fil",
	"actsearchresults"	=> "S&ouml;kresultat",
	"actcopyitems"		=> "Kopiera objekt",
	"actcopyfrom"		=> "Kopiera fr&aring;n /%s till /%s ",
	"actmoveitems"		=> "Flytta objekt",
	"actmovefrom"		=> "Flytta fr&aring;n /%s till /%s ",
	"actlogin"			=> "Logga in",
	"actloginheader"	=> "Logga in f&ouml;r att anv&auml;nda eXtplorer",
	"actadmin"			=> "Administration",
	"actchpwd"			=> "&auml;ndra l&ouml;senord",
	"actusers"			=> "Anv&auml;ndare",
	"actarchive"		=> "Arkivera objekt",
	"actupload"			=> "Ladda upp fil(er)",

	// misc
	"miscitems"			=> "Objekt",
	"miscfree"			=> "Fri",
	"miscusername"		=> "Anv&auml;ndarnamn",
	"miscpassword"		=> "L&ouml;senord",
	"miscoldpass"		=> "Gammalt l&ouml;senord",
	"miscnewpass"		=> "Nytt l&ouml;senord",
	"miscconfpass"		=> "Bekr&auml;fta l&ouml;senord",
	"miscconfnewpass"	=> "Bekr&auml;fta nytt l&ouml;senord",
	"miscchpass"		=> "Byt l&ouml;senord",
	"mischomedir"		=> "Hemkatalog",
	"mischomeurl"		=> "Hem-URL",
	"miscshowhidden"	=> "Visa dolda objekt",
	"mischidepattern"	=> "Hide pattern",
	"miscperms"			=> "R&auml;ttigheter",
	"miscuseritems"		=> "(namn, hemkatalog, visa dolda objekt, r&auml;ttigheter, aktiv)",
	"miscadduser"		=> "l&auml;gg till anv&auml;ndare",
	"miscedituser"		=> "redigera anv&auml;ndare'%s'",
	"miscactive"		=> "Aktiv",
	"misclang"			=> "Spr&aring;k",
	"miscnoresult"		=> "Inga resultat till&auml;ngliga.",
	"miscsubdirs"		=> "S&ouml;k i underkataloger",
	"miscpermnames"		=> array("Visa bara","&auml;ndra","&auml;ndra l&ouml;senord","&auml;ndra & Byt l&ouml;senord",	"Administrat&ouml;r"),
	"miscyesno"			=> array("Ja","Nej","J","N"),
	"miscchmod"			=> array("&auml;gare", "Grupp", "Publik"),

	// from here all new by mic
	'miscowner'			=> '&auml;gare',
	'miscownerdesc'		=> '<strong>Beskrivning:</strong><br />Anv&auml;ndare (UID) /<br />Grupp (GID)<br />Aktuella r&auml;ttigheter:<br /><strong> %s ( %s ) </strong>/<br /><strong> %s ( %s )</strong>',

	// sysinfo (new by mic)
	'simamsysinfo'		=> "eXtplorer systeminfo",
	'sisysteminfo'		=> 'Systeminfo',
	'sibuilton'			=> 'Operativsystem',
	'sidbversion'		=> 'Databasversion (MySQL)',
	'siphpversion'		=> 'PHP-version',
	'siphpupdate'		=> 'INFORMATION: <span style="color: red;">PHP-version du anv&auml;nder &auml;r<strong>inte</strong> aktuell!</span><br />F&ouml;r att garantera att alla funktioner och m&ouml;jligheter ska fungera,<br />b&ouml;r du anv&auml;nda minst <strong>PHP-version 4.3</strong>!',
	'siwebserver'		=> 'Webbserver',
	'siwebsphpif'		=> 'Webberverns PHP-interface',
	'simamboversion'	=> 'eXtplorer-version',
	'siuseragent'		=> 'Browserversion',
	'sirelevantsettings' => 'Viktiga PHP-inst&auml;llningar',
	'sisafemode'		=> 'Safe Mode',
	'sibasedir'			=> 'Open basedir',
	'sidisplayerrors'	=> 'PHP Errors',
	'sishortopentags'	=> 'Short Open Tags',
	'sifileuploads'		=> 'File Uploads',
	'simagicquotes'		=> 'Magic Quotes',
	'siregglobals'		=> 'Register Globals',
	'sioutputbuf'		=> 'Output Buffer',
	'sisesssavepath'	=> 'Session Savepath',
	'sisessautostart'	=> 'Session auto start',
	'sixmlenabled'		=> 'XML enabled',
	'sizlibenabled'		=> 'ZLIB enabled',
	'sidisabledfuncs'	=> 'Disabled functions',
	'sieditor'			=> 'WYSIWYG-editor',
	'siconfigfile'		=> 'Configfil',
	'siphpinfo'			=> 'PHP-info',
	'siphpinformation'	=> 'PHP-information',
	'sipermissions'		=> 'R&auml;ttigheter',
	'sidirperms'		=> 'Katalogr&auml;ttigheter',
	'sidirpermsmess'	=> 'F&ouml;r att vara s&auml;ker att alla funktioner och m&ouml;jligheter i eXtplorer ska fungera korrekt, ska f&ouml;ljande kataloger ha skrivr&auml;ttigheter [chmod 0777]',
	'sionoff'			=> array( 'Av', 'P&aring;' ),
	
	'extract_warning' => "Vill du verkigen packa upp denna fil h&auml;r?<br />Detta kan komma att resultera i att befintliga filer skrivs &ouml;ver om du &auml;r of&ouml;rsiktig!",
	'extract_success' => "Uppackningen lyckades",
	'extract_failure' => "Uppackningen misslyckades",
	
	'overwrite_files' => 'Skriv &ouml;ver befintliga fil(er)?',
	"viewlink"		=> "Visa",
	"actview"		=> "Visa filen",
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_chmod.php file
	'recurse_subdirs'	=> 'Till&auml;mpa p&aring; underkataloger?',
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to footer.php file
	'check_version'	=> 'Kontrollera om det finns uppdateringar',
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_rename.php file
	'rename_file'	=>	'Byt namn p&aring; katalog eller fil...',
	'newname'		=>	'Nytt namn',
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_edit.php file
	'returndir'	=>	'&aring;terv&auml;nd till katalog efter spara?',
	'line'		=> 	'Linje',
	'column'	=>	'Kolumn',
	'wordwrap'	=>	'Radbrytning (endast IE)',
	'copyfile'	=>	'Kopiera fil in i detta filnamn',
	
	// Bookmarks
	'quick_jump' => 'Hoppa till',
	'already_bookmarked' => 'Denna katalog &auml;r redan bokm&auml;rkt',
	'bookmark_was_added' => 'Denna katalog lades till p&aring; bokm&auml;rkeslistan.',
	'not_a_bookmark' => 'Denna katalog &auml;r inte bokm&auml;rkt.',
	'bookmark_was_removed' => 'Denna katalog togs bort fr&aring;n bokm&auml;rkeslistan.',
	'bookmarkfile_not_writable' => "Det gick inte att bokm&auml;rka .\n Bokm&auml;rkesfilen '%s' &auml;r inte skrivbar \n.",
	
	'lbl_add_bookmark' => 'L&auml;gg till denna katalog som bokm&auml;rke',
	'lbl_remove_bookmark' => 'Ta bort denna katalog fr&aring;n bokm&auml;rkeslistan',
	
	'enter_alias_name' => 'Ange ett alias f&ouml;r detta bokm&auml;rke',
	
	'normal_compression' => 'normal komprimering',
	'good_compression' => 'god komprimering',
	'best_compression' => 'b&auml;sta komprimering',
	'no_compression' => 'inge komprimering',
	
	'creating_archive' => 'Skapa arkivfil...',
	'processed_x_files' => 'Prossessat %s av %s filer',
	
	'ftp_header' => 'Lokala FTP-inst&auml;llningar',
	'ftp_login_lbl' => 'Ange dina loginuppgifter f&ouml;r FTP-servern',
	'ftp_login_name' => 'FTP-anv&auml;ndarnamn ',
	'ftp_login_pass' => 'FTP-l&ouml;senord',
	'ftp_hostname_port' => 'FTP-host och port<br />(Port &auml;r en valfri uppgift)',
	'ftp_login_check' => 'Kontrollerar FTP-anslutning...',
	'ftp_connection_failed' => "Det gick inte att koppla upp mot FTP-servern. \nKontrollera att FTP-servern &auml;r ig&aring;ng p&aring; din server.",
	'ftp_login_failed' => "FTP-inloggningen misslyckades. Kontrollera anv&auml;ndarnamn och l&ouml;senord och f&ouml;rs&ouml;k igen.",
		
	'switch_file_mode' => 'Aktuellt l&auml;ge &auml;r [%s] <br /> &auml;ndra till [%s] l&auml;ge.',
	'symlink_target' => 'M&aring;l f&ouml;r Symbolic Link',
	
	"permchange"		=> "CHMOD lyckades:",
	"savefile"		=> "Filen sparades.",
	"moveitem"		=> "Flyttning lyckades.",
	"copyitem"		=> "Kopiering lyckades.",
	'archive_name' 	=> 'Namn p&aring; arkivfil',
	'archive_saveToDir' 	=> 'Spara arkivet i denna katalog',
	
	'editor_simple'	=> 'Editorl&auml;ge',
	'editor_syntaxhighlight'	=> 'L&auml;ge f&ouml;r kodmarkering',

	'newlink'	=> 'Ny Fil/Katalog',
	'show_directories' => 'Visa kataloger',
	'actlogin_success' => 'Inloggning lyckades!',
	'actlogin_failure' => 'Inloggning misslyckades, f&ouml;rs&ouml;k igen.',
	'directory_tree' => 'Katalogtr&auml;d',
	'browsing_directory' => 'Bl&auml;ddra i katalogerna',
	'filter_grid' => 'Filter',
	'paging_page' => 'Sida',
	'paging_of_X' => 'av {0}',
	'paging_firstpage' => 'F&ouml;rsta sidan',
	'paging_lastpage' => 'Sista sidan',
	'paging_nextpage' => 'N&auml;sta sidan',
	'paging_prevpage' => 'F&ouml;reg&aring;ende sidan',
	
	'paging_info' => 'Visa objekt {0} - {1} av {2}',
	'paging_noitems' => 'Inga objekt att visa',
	'aboutlink' => 'Om...',
	'password_warning_title' => 'Viktigt - &auml;ndra ditt l&ouml;senord!',
	'password_warning_text' => 'Anv&auml;ndarkontot du loggade in med (admin med l&ouml;senord admin) &auml;r standardkontot f&ouml;r administrat&ouml;rer i eXtplorer. Din eXtplorer-installation ligger &ouml;ppen f&ouml;r angrepp och du m&aring;ste omedelbart r&auml;tta till detta s&auml;kerhetsh&aring;l. Byt l&ouml;senord nu!',
	'change_password_success' => 'Ditt l&ouml;senord har &auml;ndrats!',
	'success' => 'Lyckades',
	'failure' => 'Misslyckades',
	'dialog_title' => 'Webbsitedialog',
	'upload_processing' => 'Processar uppladdning, v&auml;nta...',
	'upload_completed' => 'Uppladdning lyckades!',
	'acttransfer' => '&ouml;verf&ouml;r fr&aring;n en annan server',
	'transfer_processing' => 'Processar &ouml;verf&ouml;ring fr&aring;n Server-till-Server, v&auml;nta...',
	'transfer_completed' => '&ouml;verf&ouml;ring klar!',
	'max_file_size' => 'Maximal filstorlek',
	'max_post_size' => 'Maximal uppladdningsgr&auml;ns',
	'done' => 'Klart.',
	'permissions_processing' => 'Applicerar r&auml;ttigheter, v&auml;nta...',
	'archive_created' => 'Arkivfilen har skapats!',
	'save_processing' => 'Sparar fil...',
	'current_user' => 'Detta skript k&ouml;rs just nu med r&auml;ttigheter f&ouml;r f&ouml;ljande anv&auml;ndare:',
	'your_version' => 'Din version',
	'search_processing' => 'S&ouml;ker, v&auml;nta...',
	'url_to_file' => 'Filens URL',
	'file' => 'Fil'
	
);
?>
