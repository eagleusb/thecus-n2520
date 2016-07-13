<?php
// $Id: polish.php 86 2007-08-28 15:53:55Z soeren $
// Polish Language Module for v2.3 (translated by l0co@wp.pl)
global $_VERSION;

$GLOBALS["charset"] = "utf-8";
$GLOBALS["text_dir"] = "ltr"; // ('ltr' for left to right, 'rtl' for right to left)
$GLOBALS["date_fmt"] = "Y/m/d H:i";
$GLOBALS["error_msg"] = array(
	// error
	"error"			=> "B&#322;&#261;d",
	"message"	=> "Komunikat(y)",
	"back"			=> "Wr&#243;&#263;",

	// root
	"home"			=> "Katalog domowy nie istnieje. Sprawd&#378; swoje ustawienia.",
	"abovehome"		=> "Bie&#380;&#261;cy katalog nie mo&#380;e by&#263; powy&#380;ej katalogu domowego.",
	"targetabovehome"	=> "Docelowy katalog nie mo&#380;e by&#263; powy&#380;ej katalogu domowego.",

	// exist
	"direxist"		=> "Katalog nie istnieje.",
	"filedoesexist"	=> "This file already exists.",
	"fileexist"		=> "Plik nie istnieje.",
	"itemdoesexist"		=> "Element ju&#380; istnieje.",
	"itemexist"		=> "Element nie istnieje.",
	"targetexist"		=> "Katalog docelowy nie istnieje.",
	"targetdoesexist"	=> "Miejsce docelowe ju&#380; istnieje.",

	// open
	"opendir"		=> "Nie mo&#380;na otworzy&#263; katalogu.",
	"readdir"		=> "Nie mo&#380;na odczyta&#263; katalogu.",

	// access
	"accessdir"		=> "Nie masz prawa dost&#281;pu do tego katalogu.",
	"accessfile"		=> "Nie masz prawa dost&#281;pu do tego pliku.",
	"accessitem"		=> "Nie masz prawa dost&#281;pu do tego elementu.",
	"accessfunc"		=> "Nie masz prawa u&#380;y&#263; tej funkcji.",
	"accesstarget"		=> "Nie masz prawa dost&#281;pu do docelowego katalogu.",

	// actions
	"permread"		=> "Pobieranie uprawnie&#324; nie powiod&#322;o si&#281;.",
	"permchange"		=> "B&#322;&#261;d CHMOD (zazwyczaj spowodowane jest to problemem z ustawieniami w&#322;a&#347;ciciela pliku - np. je&#347;li u&#380;ytkownik HTTP ('www-data' lub 'nobody') i u&#380;ytkownik FTP nie s&#261; tymi samymi u&#380;ytkownikami)",
	"openfile"		=> "Otwarcie pliku nie powiod&#322;o si&#281;.",
	"savefile"		=> "Zapisanie pliku nie powiod&#322;o si&#281;.",
	"createfile"		=> "Utworzenie pliku nie powiod&#322;o si&#281;.",
	"createdir"		=> "Utworzenie katalogu nie powiod&#322;o si&#281;.",
	"uploadfile"		=> "Upload pliku nie powi&#243;d&#322; si&#281;.",
	"copyitem"		=> "Kopiowanie nie powiod&#322;o si&#281;.",
	"moveitem"		=> "Przenoszenie nie powiod&#322;o si&#281;.",
	"delitem"		=> "Usuwanie nie powiod&#322;o si&#281;.",
	"chpass"		=> "Zmiana nazwa nie powiod&#322;a si&#281;.",
	"deluser"		=> "Usuwanie u&#380;ytkownika nie powiod&#322;o si&#281;.",
	"adduser"		=> "Dodawanie u&#380;ytkownika nie powiod&#322;o si&#281;.",
	"saveuser"		=> "Zapisywanie u&#380;ytkownika nie powiod&#322;o si&#281;.",
	"searchnothing"		=> "Musisz wpisa&#263; fraz&#281; wyszukiwania.",

	// misc
	"miscnofunc"		=> "Funkcja nie jest dost&#281;pna.",
	"miscfilesize"		=> "Plik przekracza maksymaln&#261; wielko&#347;&#263;.",
	"miscfilepart"		=> "Plik zosta&#322; za&#322;adowany tylko cz&#281;&#347;ciowo.",
	"miscnoname"		=> "Musisz wpisa&#263; nazw&#281;.",
	"miscselitems"		=> "Nie wybra&#322;e&#347; &#380;adnych element&#243;w.",
	"miscdelitems"		=> "Na pewno chcesz usun&#261;&#263; {0} element(&#243;w)?",
	"miscdeluser"		=> "Na pewno chcesz usun&#261;&#263; u&#380;ytkownika '{0}'?",
	"miscnopassdiff"	=> "Nowe has&#322;o nie r&#243;&#380;ni si&#281; od bie&#380;&#261;cego.",
	"miscnopassmatch"	=> "Has&#322;o nie pasuje.",
	"miscfieldmissed"	=> "Nie wype&#322;ni&#322;e&#347; wa&#380;nego pola.",
	"miscnouserpass"	=> "Nieprawid&#322;owe has&#322;o lub nazwa u&#380;ytkownika.",
	"miscselfremove"	=> "Nie mo&#380;esz usun&#261;&#263; sam siebie.",
	"miscuserexist"		=> "U&#380;ytkownik ju&#380; istnieje.",
	"miscnofinduser"	=> "Nie znaleziono u&#380;ytkownika.",
	"extract_noarchive" => "Plik nie jest archiwum mo&#380;liwym do rozpakowania.",
	"extract_unknowntype" => "Nieznany typ archiwum",
	
	'chmod_none_not_allowed' => 'Zmiana uprawnie&#324; na <none> nie jest dopuszczalna',
	'archive_dir_notexists' => 'Docelowy katalog zapisu, kt&#243;ry wybra&#322;e&#347;, nie istnieje.',
	'archive_dir_unwritable' => 'Prosz&#281; wybra&#263; katalog z prawami do zapisu archiwum.',
	'archive_creation_failed' => 'Zapis archiwum nie powi&#243;d&#322; si&#281;'
	
);
$GLOBALS["messages"] = array(
	// links
	"permlink"		=> "Zmiana uprawnie&#324;",
	"editlink"		=> "Edycja",
	"downlink"		=> "Download",
	"uplink"		=> "W g&#243;r&#281;",
	"homelink"		=> "Katalog domowy",
	"reloadlink"		=> "Od&#347;wie&#380;",
	"copylink"		=> "Kopiuj",
	"movelink"		=> "Przenie&#347;",
	"dellink"		=> "Usu&#324;",
	"comprlink"		=> "Archiwum",
	"adminlink"		=> "Administrator",
	"logoutlink"		=> "Wyloguj",
	"uploadlink"		=> "Upload",
	"searchlink"		=> "Wyszukaj",
	"extractlink"	=> "Rozpakuj archiwum",
	'chmodlink'		=> 'Zmie&#324; uprawnienia (chmod)', // new mic
	'mossysinfolink'	=> 'Informacje o systemie', // new mic
	'logolink'		=> 'Skocz do strony joomlaXplorer (nowe okno)', // new mic

	// list
	"nameheader"		=> "Nazwa",
	"sizeheader"		=> "Rozmiar",
	"typeheader"		=> "Typ",
	"modifheader"		=> "Zmodyfikowano",
	"permheader"		=> "Prawa",
	"actionheader"		=> "Akcje",
	"pathheader"		=> "Ście&#380;ka",

	// buttons
	"btncancel"		=> "Anuluj",
	"btnsave"		=> "Zapisz",
	"btnchange"		=> "Zmie&#324;",
	"btnreset"		=> "Resetuj",
	"btnclose"		=> "Zamknij",
	"btncreate"		=> "Utw&#243;rz",
	"btnsearch"		=> "Szukaj",
	"btnupload"		=> "Upload",
	"btncopy"		=> "Kopiuj",
	"btnmove"		=> "Przenie&#347;",
	"btnlogin"		=> "Zaloguj",
	"btnlogout"		=> "Wyloguj",
	"btnadd"		=> "Dodaj",
	"btnedit"		=> "Edytuj",
	"btnremove"		=> "Usu&#324;",
	
	// user messages, new in joomlaXplorer 1.3.0
	'renamelink'	=> 'Zmie&#324; nazw&#281;',
	'confirm_delete_file' => 'Na pewno chcesz usun&#261;&#263; ten plik? <br />%s',
	'success_delete_file' => 'Element(y) zosta&#322;y poprawnie usuni&#281;te.',
	'success_rename_file' => 'Nazwa katalog/plik %s zosta&#322;a zmieniona na %s.',
	
	// actions
	"actdir"		=> "Katalog",
	"actperms"		=> "Zmiana praw",
	"actedit"		=> "Edycja pliku",
	"actsearchresults"	=> "Wyniki szukania",
	"actcopyitems"		=> "Kopiowanie element(&#243;w)",
	"actcopyfrom"		=> "Kopiowanie z /%s do /%s ",
	"actmoveitems"		=> "Przenoszenie element(&#243;w)",
	"actmovefrom"		=> "Przenoszenie z /%s do /%s ",
	"actlogin"		=> "Zaloguj",
	"actloginheader"	=> "Zaloguj si&#281; aby u&#380;ywa&#263; managera plik&#243;w",
	"actadmin"		=> "Administracja",
	"actchpwd"		=> "Zmiana has&#322;a",
	"actusers"		=> "U&#380;ytkownicy",
	"actarchive"		=> "Archiwizacja element(&#243;w)",
	"actupload"		=> "Upload plik(&#243;w)",

	// misc
	"miscitems"		=> "Element(y)",
	"miscfree"		=> "Wolny",
	"miscusername"		=> "Nazwa u&#380;ytkownika",
	"miscpassword"		=> "Has&#322;o",
	"miscoldpass"		=> "Poprzednie has&#322;o",
	"miscnewpass"		=> "Nowe has&#322;o",
	"miscconfpass"		=> "Potwierd&#378; has&#322;o",
	"miscconfnewpass"	=> "Potwierd&#378; nowe has&#322;o",
	"miscchpass"		=> "Zmie&#324; has&#322;o",
	"mischomedir"		=> "Katalog domowy",
	"mischomeurl"		=> "Domowy adres URL",
	"miscshowhidden"	=> "Pokazuj elementy ukryte",
	"mischidepattern"	=> "Maska element&#243;w ukrytych",
	"miscperms"		=> "Uprawnienia",
	"miscuseritems"		=> "(nazwa, katalog domowy, pokazywanie ukrytych element&#243;w, uprawnienia, aktywno&#347;&#263;)",
	"miscadduser"		=> "dodaj u&#380;ytkownika",
	"miscedituser"		=> "edycja u&#380;ytkownika '%s'",
	"miscactive"		=> "Aktywny",
	"misclang"		=> "J&#281;zyk",
	"miscnoresult"		=> "Brak rezultat&#243;w.",
	"miscsubdirs"		=> "Przeszukaj podkatalogi",
	"miscpermnames"		=> array("Tylko przegl&#261;daj","Modyfikuj","Zmie&#324; has&#322;o","Modyfikuj i zmie&#324; has&#322;o",
					"Administrator"),
	"miscyesno"		=> array("Tak","Nie","T","N"),
	"miscchmod"		=> array("W&#322;a&#347;ciciel", "Grupa", "Pozostali"),

	// from here all new by mic
	'miscowner'			=> 'W&#322;a&#347;ciciel',
	'miscownerdesc'		=> '<strong>Opis:</strong><br />U&#380;ytkownik (UID) /<br />Grupa (GID)<br />Prawa:<br /><strong> %s ( %s ) </strong>/<br /><strong> %s ( %s )</strong>',

	// sysinfo (new by mic)
	'simamsysinfo'		=> "Informacje o systemie",
	'sisysteminfo'		=> 'Informacja o systemie',
	'sibuilton'			=> 'System operacyjny',
	'sidbversion'		=> 'Wersja bazy danych',
	'siphpversion'		=> 'Wersja PHP',
	'siphpupdate'		=> 'INFORMACJA: <span style="color: red;">U&#380;ywana przez Ciebie wersja PHP <strong>nie</strong> jest aktualna!</span><br />Je&#347;li chcesz aby wszystkie funkcje i dodatki Mambo dzia&#322;a&#322;y poprawnie,<br />musisz u&#380;ywa&#263; minimum wersji <strong>PHP 4.3</strong>!',
	'siwebserver'		=> 'Serwer web',
	'siwebsphpif'		=> 'Serwer web - interfejs PHP',
	'simamboversion'	=> 'Wersja eXtplorer\'a',
	'siuseragent'		=> 'Wersja przegl&#261;darki',
	'sirelevantsettings' => 'Wa&#380;ne ustawienia PHP',
	'sisafemode'		=> 'Safe Mode',
	'sibasedir'			=> 'Open basedir',
	'sidisplayerrors'	=> 'PHP Errors',
	'sishortopentags'=> 'Short Open Tags',
	'sifileuploads'		=> 'File Uploads',
	'simagicquotes'	=> 'Magic Quotes',
	'siregglobals'		=> 'Register Globals',
	'sioutputbuf'		=> 'Output Buffer',
	'sisesssavepath'	=> 'Session Savepath',
	'sisessautostart'	=> 'Session auto start',
	'sixmlenabled'		=> 'XML enabled',
	'sizlibenabled'		=> 'ZLIB enabled',
	'sidisabledfuncs'	=> 'Niekatywne funkcje',
	'sieditor'				=> 'Edytor WYSIWYG',
	'siconfigfile'		=> 'Plik konfiguracyjny',
	'siphpinfo'			=> 'PHP Info',
	'siphpinformation'	=> 'Informacje o PHP',
	'sipermissions'		=> 'Prawa',
	'sidirperms'		=> 'Prawa katalogu',
	'sidirpermsmess'	=> 'Aby zapewni&#263; poprawne dzia&#322;anie wszystkich funkcji eXtplorer\'a, nast&#281;puj&#261;ce katalogi powinny mie&#263; ustawione prawa pisania [chmod 0777]',
	'sionoff'			=> array( 'W&#322;', 'Wy&#322;' ),
	
	'extract_warning' => "Czy na pewno chcesz rozpakowa&#263; ten plik tutaj?<br />Mo&#380;e to spowodowa&#263; nadpisanie istniej&#261;cych plik&#243;w!",
	'extract_success' => "Rozpakowanie powiod&#322;o si&#281;",
	'extract_failure' => "Rozpakowanie nie powiod&#322;o si&#281;",
	
	'overwrite_files' => 'Nadpisa&#263; istniej&#261;ce pliki?',
	"viewlink"		=> "Podgl&#261;d",
	"actview"		=> "Poka&#380; &#378;r&#243;d&#322;o pliku",
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_chmod.php file
	'recurse_subdirs'	=> 'Ustaw dla wszystkich podkatalog&#243;w?',
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to footer.php file
	'check_version'	=> 'Sprawd&#378; ostatni&#261; wersj&#281;',
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_rename.php file
	'rename_file'	=>	'Zmie&#324; nazw&#281; katalogu lub pliku...',
	'newname'		=>	'Nowa nazwa',
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_edit.php file
	'returndir'	=>	'Powr&#243;ci&#263; do katalogu po zapisaniu?',
	'line'		=> 	'Linia',
	'column'	=>	'Kolumna',
	'wordwrap'	=>	'Zawijanie wierszy: (tylko IE)',
	'copyfile'	=>	'Skopiuj plik pod t&#261; nazw&#261;',
	
	// Bookmarks
	'quick_jump' => 'Szybki skok do',
	'already_bookmarked' => 'Dla tego katalogu ju&#380; istnieje zak&#322;adka',
	'bookmark_was_added' => 'Katalog zosta&#322; dodany do zak&#322;adek.',
	'not_a_bookmark' => 'Katalog nie jest zak&#322;adk&#261;.',
	'bookmark_was_removed' => 'Katalog zosta&#322; usuni&#281;ty z zak&#322;adek.',
	'bookmarkfile_not_writable' => "Nie powiod&#322;o si&#281; dodanie do zak&#322;adek %s.\n Plik zak&#322;adek '%s' \nnie ma ustawionych praw do zapisu.",
	
	'lbl_add_bookmark' => 'Dodaj katalog jako zak&#322;adk&#281;',
	'lbl_remove_bookmark' => 'Usu&#324; katalog z listy zak&#322;adek',
	
	'enter_alias_name' => 'Wpisz alias dla zak&#322;adki',
	
	'normal_compression' => 'kompresja normalna (normal)',
	'good_compression' => 'kompresja dobra (good)',
	'best_compression' => 'kompresja najlepsza (best)',
	'no_compression' => 'brak kompresji',
	
	'creating_archive' => 'Tworzenie archiwum...',
	'processed_x_files' => 'Przetworzono %s z %s plik&#243;w',
	
	'ftp_header' => 'Lokalna autoryzacja FTP',
	'ftp_login_lbl' => 'Prosz&#281; poda&#263; dane dost&#281;powe do serwera FTP',
	'ftp_login_name' => 'Nazwa u&#380;ytkownika',
	'ftp_login_pass' => 'Has&#322;o',
	'ftp_hostname_port' => 'Serwer i port FTP <br />(port opcjonalnie)',
	'ftp_login_check' => 'Sprawdzanie po&#322;&#261;czenia FTP...',
	'ftp_connection_failed' => "Nie mo&#380;na po&#322;&#261;czy&#263; si&#281; z serwerem FTP. \nProsz&#281; sprawdzi&#263;, czy serwer FTP jest aktywny na podanym ho&#347;cie.",
	'ftp_login_failed' => "Nie mo&#380;na zalogowa&#263; si&#281; do serwera FTP. Prosz&#281; zweryfikowa&#263; poprawno&#347;&#263; nazwy u&#380;ytkownika i has&#322;a i spr&#243;bowa&#263; ponownie.",
		
	'switch_file_mode' => 'Aktualny tryb: <strong>%s</strong>. Mo&#380;esz prze&#322;&#261;czy&#263; si&#281; do trybu %s.',
	'symlink_target' => 'Punkt docelowy linku symbolicznego',
	
	"permchange"		=> "Zmiana uprawnie&#324; (chmod) powiod&#322;a si&#281;:",
	"savefile"		=> "Plik zosta&#322; zapisany.",
	"moveitem"		=> "Przenoszenie powiod&#322;o si&#281;.",
	"copyitem"		=> "Kopiowanie powiod&#322;o si&#281;.",
	'archive_name' 	=> 'Nazwa pliku archiwum',
	'archive_saveToDir' 	=> 'Zapisz archiwum do katalogu',
	
	'editor_simple'	=> 'Tryb edytora: prosty',
	'editor_syntaxhighlight'	=> 'Tryb edytora: wyr&#243;&#380;nianie sk&#322;adni',

	'newlink'	=> 'Nowy plik/katalog',
	'show_directories' => 'Poka&#380; katalogi',
	'actlogin_success' => 'U&#380;ytkownik zosta&#322; zalogowany!',
	'actlogin_failure' => 'Nieprawid&#322;owy login b&#261;d&#378; has&#322;o. Spr&#243;buj ponownie',
	'directory_tree' => 'Drzewko katalog&#243;w',
	'browsing_directory' => 'Przegl&#261;dany katalog',
	'filter_grid' => 'Filtr',
	'paging_page' => 'Strona',
	'paging_of_X' => 'z {0}',
	'paging_firstpage' => 'Pierwsza strona',
	'paging_lastpage' => 'Ostatnia strona',
	'paging_nextpage' => 'Nast&#281;pna strona',
	'paging_prevpage' => 'Poprzednia strona',
	
	'paging_info' => 'Wy&#347;wietlane elementy: {0} - {1} z {2}',
	'paging_noitems' => 'Brak element&#243;w do wy&#347;wietlenia',
	'aboutlink' => 'O...',
	'password_warning_title' => 'Wa&#380;ne - zmie&#324; swoje has&#322;o!',
	'password_warning_text' => 'Konto u&#380;ytkownika do kt&#243;rego w&#322;a&#347;nie si&#281; zalogowa&#322;e&#347; (admin z has&#322;em admin) odpowiada domy&#347;lnym ustawieniom przegl&#261;darki. To sprawia, &#380;e potencjalnie ka&#380;dy mo&#380;e zalogowa&#263; si&#281; do Twojego konta administratora. Aby naprawi&#263; ten problem, zmie&#324; has&#322;o administratora na swoje prywatne has&#322;o!',
	'change_password_success' => 'Has&#322;o zosta&#322;o zmienione.',
	'success' => 'Sukces',
	'failure' => 'B&#322;&#261;d',
	'dialog_title' => 'Onko dialogowe',
	'upload_processing' => 'Upload plik&#243;w, prosz&#281; czeka&#263;...',
	'upload_completed' => 'Upload plik&#243;w powi&#243;d&#322; si&#281;!',
	'acttransfer' => 'Transfer z innego serwera',
	'transfer_processing' => 'Transfer plik&#243;w serwer-do-serwera, prosz&#281; czeka&#263;...',
	'transfer_completed' => 'Zako&#324;czono transfer!',
	'max_file_size' => 'Maksymalny rozmiar pliku',
	'max_post_size' => 'Maksymalny limit uploadu',
	'done' => 'Zako&#324;czono.',
	'permissions_processing' => 'Trwa zastosowywanie uprawnie&#324;, prosz&#281; czeka&#263;...',
	'archive_created' => 'Plik archiwum zosta&#322; utworzony.',
	'save_processing' => 'Zapis pliku...',
	'current_user' => 'Skrypt aktualnie jest wykonywany z prawami nast&#281;puj&#261;cego u&#380;ytkownika:',
	'your_version' => 'Twoja wersja',
	'search_processing' => 'Wyszukiwanie, prosz&#281; czeka&#263;...',
	'url_to_file' => 'Adres URL pliku',
	'file' => 'Plik'
	
);
?>
