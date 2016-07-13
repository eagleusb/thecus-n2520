<?php
// $Id: english.php 115 2009-01-10 11:18:58Z soeren $
// English Language Module for v2.3 (translated by the QuiX project)
global $_VERSION;

$GLOBALS["charset"] = "UTF-8";
$GLOBALS["text_dir"] = "ltr"; // ('ltr' for left to right, 'rtl' for right to left)
$GLOBALS["date_fmt"] = "Y/m/d H:i";
$GLOBALS["error_msg"] = array(
	// error
	"error"			=> "Ошибка(и)",
	"message"		=> "Сообщение(я)",
	"back"			=> "Вернуться назад",

	// root
	"home"		=> "Корневая директория не существует, проверьте ваши настройки.",
	"abovehome"		=> "Текущая директория может находиться только в корневом каталоге.",
	"targetabovehome"	=> " Выбранная директория может находиться только в корневом каталоге.",

	// exist
	"direxist"		=> "Директория не существует.",
	"filedoesexist"	=> "Файл уже существует.",
	"fileexist"		=> "Файл не существует.",
	"itemdoesexist"	=> "Данный элемент уже существует.",
	"itemexist"		=> "Данный элемент не существует.",
	"targetexist"		=> "Выбранная директория не существует.",
	"targetdoesexist"	=> "Выбранный элемент уже существует.",

	// open
	"opendir"		=> "Невозможно открыть директорию.",
	"readdir"		=> "Невозможно прочитать директорию.",

	// access
	"accessdir"		=> "У Вас нет прав доступа к данной директории.",
	"accessfile"		=> "У Вас нет прав доступа к данному файлу.",
	"accessitem"		=> " У Вас нет прав доступа к данному элементу.",
	"accessfunc"		=> " У Вас нет прав доступа к использованию данной функции.",
	"accesstarget"		=> " У Вас нет прав доступа к выбранной директории.",

	// actions
	"permread"		=> "Не удалось получить разрешение.",
	"permchange"		=> "Ошибка CHMOD (в большинстве случаев это связано с правами доступа к файлу - если HTTP пользователь ('wwwrun' или 'nobody') и FTP пользователь не одинаковые)",
	"openfile"		=> "Ошибка открытия файла.",
	"savefile"		=> "Ошибка сохранения файла.",
	"createfile"		=> "Ошибка создания файла.",
	"createdir"		=> "Ошибка создания директории.",
	"uploadfile"		=> "Ошибка закачки файла.",
	"copyitem"		=> "Ошибка копирования.",
	"moveitem"		=> "Ошибка перемещения.",
	"delitem"		=> "Ошибка удаления.",
	"chpass"		=> "Ошибка смены пароля.",
	"deluser"		=> "Ошибка удаления пользователя.",
	"adduser"		=> "Ошибка добавления пользователя.",
	"saveuser"		=> "Ошибка сохранения пользователя.",
	"searchnothing"	=> "Необходимо ввести что-нибудь чтобы начать поиск.",

	// misc
	"miscnofunc"		=> "Функция недоступна.",
	"miscfilesize"		=> "Файл превышает максимально допустимый размер.",
	"miscfilepart"		=> "Файл закачен частично.",
	"miscnoname"		=> "Необходимо ввести имя.",
	"miscselitems"	=> "Не выбрано ни одного элемента.",
	"miscdelitems"	=> "Вы уверены, что хотите удалить этот(эти) {0} элемент(ы)?",
	"miscdeluser"		=> "Вы уверены, что хотите удалить пользователя '{0}'?",
	"miscnopassdiff"	=> "Новый пароль не отличается от текущего.",
	"miscnopassmatch"	=> "Пароли не совпадают.",
	"miscfieldmissed"	=> "Вы пропустили важное для заполнения поле.",
	"miscnouserpass"	=> "Имя пользователя или пароль неверны.",
	"miscselfremove"	=> "Вы не можете удалить самого себя.",
	"miscuserexist"	=> "Пользователь уже существует.",
	"miscnofinduser"	=> "Невозможно найти пользователя.",
	"extract_noarchive" 	=> "Файл является не извлекаемым архивом.",
	"extract_unknowntype" => "Неизвестный тип архива",

	'chmod_none_not_allowed' => 'Значение  <none> недоступно',
	'archive_dir_notexists' => 'Директория, в которую вы пытаетесь сохранить не существует.',
	'archive_dir_unwritable' => 'Укажите директорию для сохранения архива.',
	'archive_creation_failed' => 'Ошибка сохранения архива'

);
$GLOBALS["messages"] = array(
	// links
	"permlink"		=> "Смена прав доступа",
	"editlink"		=> "Редактирование",
	"downlink"		=> "Скачивание",
	"uplink"		=> "Наверх",
	"homelink"		=> "Домой",
	"reloadlink"		=> "Перезагрузка",
	"copylink"		=> "Копирование",
	"movelink"		=> "Перемещение",
	"dellink"		=> "Удаление",
	"comprlink"		=> "Архив",
	"adminlink"		=> "Администрирование",
	"logoutlink"		=> "Выход",
	"uploadlink"		=> "Закачка",
	"searchlink"		=> "Поиск",
	"extractlink"		=> "Извлечение архива",
	'chmodlink'		=> 'Смена режима доступа к (Папке/Файлу(ам))', // new mic
	'mossysinfolink'	=> 'Системная информация eXtplorer (eXtplorer, Server, PHP, mySQL)', // new mic
	'logolink'		=> 'Перейти на сайт eXtplorer (в новом окне)', // new mic

	// list
	"nameheader"		=> "Имя",
	"sizeheader"		=> "Размер",
	"typeheader"		=> "Тип",
	"modifheader"		=> "Модификация",
	"permheader"		=> "Perms",
	"actionheader"	=> "Действие",
	"pathheader"		=> "Путь",

	// buttons
	"btncancel"		=> "Отмена",
	"btnsave"		=> "Сохранение",
	"btnchange"		=> "Изменение",
	"btnreset"		=> "Сброс",
	"btnclose"		=> "Закрыть",
	"btncreate"		=> "Создать",
	"btnsearch"		=> "Поиск",
	"btnupload"		=> "Закачать",
	"btncopy"		=> "Копировать",
	"btnmove"		=> "Переместить",
	"btnlogin"		=> "Войти",
	"btnlogout"		=> "Выйти",
	"btnadd"		=> "Добавить",
	"btnedit"		=> "Редактирование",
	"btnremove"		=> "Удаление",

	// user messages, new in joomlaXplorer 1.3.0
	'renamelink'	=> 'Переименовать',
	'confirm_delete_file' => 'Вы уверены что хотите удалить этот файл? <br />%s',
	'success_delete_file' => 'Объект(ы) успешно удален(ы).',
	'success_rename_file' => 'Директория/файл %s был(а) успешно переименован(а) в %s.',

	// actions
	"actdir"		=> "Директория",
	"actperms"		=> "Смена прав доступа",
	"actedit"		=> "Редактирование файла",
	"actsearchresults"	=> "Результаты поиска",
	"actcopyitems"	=> "Копирование объекта(ов)",
	"actcopyfrom"		=> "Копирование из /%s в /%s ",
	"actmoveitems"	=> "Перемещение объекта(ов)",
	"actmovefrom"	=> "Перемещение из /%s в /%s ",
	"actlogin"		=> "Вход",
	"actloginheader"	=> "Вход для использования eXtplorer",
	"actadmin"		=> "Администратор",
	"actchpwd"		=> "Смена пароля",
	"actusers"		=> "Пользователи",
	"actarchive"		=> "Архивный(ые) элемент(ы)",
	"actupload"		=> "Закачать файл(ы)",

	// misc
	"miscitems"		=> "Объект(ы)",
	"miscfree"		=> "Свободный доступ",
	"miscusername"	=> "Имя пользователя",
	"miscpassword"	=> "Пароль",
	"miscoldpass"		=> "Старый пароль",
	"miscnewpass"	=> "Новый пароль",
	"miscconfpass"	=> "Подтверждение пароля",
	"miscconfnewpass"	=> "Подтверждение нового пароля",
	"miscchpass"		=> "Смена пароля",
	"mischomedir"	=> "Корневая директория",
	"mischomeurl"	=> "Начальная страница",
	"miscshowhidden"	=> "Показывать скрытые элементы",
	"mischidepattern"	=> "Скрыть образец",
	"miscperms"		=> "Права доступа",
	"miscuseritems"	=> "(имя, корневая директория, показать скрытые объекты, разрешения, активный)",
	"miscadduser"		=> "Добавить пользователя",
	"miscedituser"		=> "Редактировать пользователя '%s'",
	"miscactive"		=> "Активный",
	"misclang"		=> "Язык",
	"miscnoresult"	=> "Нет доступных результатов.",
	"miscsubdirs"		=> "Поиск в поддиректориях",
	"miscpermnames"	=> array("Только просмотр","Изменение","Смена пароля","Изменение & Смена пароля", "Администратор"),
	"miscyesno"		=> array("Да","Нет","Д","Н"),
	"miscchmod"		=> array("Владелец", "Группа", "Публичная"),

	// from here all new by mic
	'miscowner'		=> 'Владелец',
	'miscownerdesc'	=> '<strong>Описание:</strong><br />Пользователь (UID) /<br />Группа (GID)<br />Текущие права:<br /><strong> %s ( %s ) </strong>/<br /><strong> %s ( %s )</strong>',

	// sysinfo (new by mic)
	'simamsysinfo'	=> "Системная информация eXtplorer ",
	'sisysteminfo'		=> ' Системная информация',
	'sibuilton'		=> 'Операционная система',
	'sidbversion'		=> 'Версия базы данных (MySQL)',
	'siphpversion'		=> 'Версия PHP',
	'siphpupdate'		=> 'ИНФОРМАЦИЯ: <span style="color: red;">Версия PHP, используемая вами <strong>НЕ</strong> актуальна!</span><br />Для того чтобы гарантировать все функции и возможности Mambo и дополнений,<br />вы должны использовать минимум <strong>PHP версии 4.3</strong>!',
	'siwebserver'		=> 'Вебсервер',
	'siwebsphpif'		=> 'Вебсервер - PHP интерфейс',
	'simamboversion'	=> 'Версия eXtplorer',
	'siuseragent'		=> 'Версия Браузера',
	'sirelevantsettings' => 'Важные настройки PHP',
	'sisafemode'		=> 'Безопасный режим',
	'sibasedir'		=> 'Открыть базовую директорию',
	'sidisplayerrors'	=> 'Ошибки PHP',
	'sishortopentags'	=> 'Короткие открытые тэги',
	'sifileuploads'		=> 'Закачки файлов',
	'simagicquotes'	=> 'Магические кавычки (Magic Quotes)',
	'siregglobals'		=> 'Register Globals',
	'sioutputbuf'		=> 'Исходящий буффер',
	'sisesssavepath'	=> 'Session Savepath',
	'sisessautostart'	=> 'Автостарт сессии',
	'sixmlenabled'		=> 'XML включено',
	'sizlibenabled'		=> 'ZLIB включено',
	'sidisabledfuncs'	=> 'Отключенные функции',
	'sieditor'		=> 'Редактор WYSIWYG',
	'siconfigfile'		=> 'Файл конфигурации',
	'siphpinfo'		=> 'о PHP',
	'siphpinformation'	=> 'Информация PHP',
	'sipermissions'		=> 'Разрешения',
	'sidirperms'		=> 'Разрешения на директории',
	'sidirpermsmess'	=> 'Для уверенности в том, что все функции и возможности eXtplorer работают корректно, следующие папки должны иметь права на запись [chmod 0777]',
	'sionoff'		=> array( 'Вкл', 'Выкл' ),

	'extract_warning' => "Вы действительно хотите извлечь этот файл сюда?<br />При не внимательном обращении это приведет к перезаписи исходного файла!",
	'extract_success' => "Извлечение прошло удачно",
	'extract_failure' => "Ошибка извлечения",

	'overwrite_files' => 'Перезаписать существующий файл(ы)?',
	"viewlink"		=> "Просмотр",
	"actview"		=> "Показать источник файла",

	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_chmod.php file
	'recurse_subdirs'	=> ' recursive рекурсивно в подкаталоги?',

	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to footer.php file
	'check_version'	=> 'Проверить последнюю версию',

	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_rename.php file
	'rename_file'		=>	'Переименовать директорию или файл...',
	'newname'		=>	'Новое имя',

	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_edit.php file
	'returndir'	=>	'Возвратиться в директорию после сохранения?',
	'line'		=> 	'Линия',
	'column'	=>	'Колонка',
	'wordwrap'	=>	'Автоматический перенос слова: (IE только)',
	'copyfile'	=>	'Copy file into this filename',

	// Bookmarks
	'quick_jump' => 'Быстрый переход к',
	'already_bookmarked' => 'Эта директория уже отмечена',
	'bookmark_was_added' => 'Директория добавлена в перечень закладок.',
	'not_a_bookmark' => 'Эта директория не отмечена.',
	'bookmark_was_removed' => 'Эта директория была удалена из перечня закладок.',
	'bookmarkfile_not_writable' => "Ошибка  %s закладки.\n Отмеченный файл '%s' \n не записываемый.",

	'lbl_add_bookmark' => 'Добавить директорию как закладку',
	'lbl_remove_bookmark' => 'Удалить директорию из перечня закладок',

	'enter_alias_name' => 'Введите имя-псевдоним для этой закладки',

	'normal_compression' => 'Нормальная компрессия',
	'good_compression' => 'Хорошая компрессия',
	'best_compression' => 'Наилучшая компрессия',
	'no_compression' => 'Без компрессии',

	'creating_archive' => 'Создание архива...',
	'processed_x_files' => 'Выполнено %s из %s файлов',

	'ftp_header' => 'Локальная FTP Аутентификация',
	'ftp_login_lbl' => 'Please enter the login credentials for the FTP server',
	'ftp_login_name' => 'FTP Имя пользователя',
	'ftp_login_pass' => 'FTP Пароль',
	'ftp_hostname_port' => 'FTP сервер имя хоста и порт <br />(Порт опционально)',
	'ftp_login_check' => 'Проверка соединения FTP...',
	'ftp_connection_failed' => "Сервер FTP не доступен. \n Пожалуйста, проверьте, что FTP сервер запущен у вас на сервере.",
	'ftp_login_failed' => "Ошибка логина FTP. Пожалуйста проверьте имя пользователя и пароль и попробуйте снова.",

	'switch_file_mode' => 'Текущий режим: <strong>%s</strong>. Вы можете переключить в режим %s .',
	'symlink_target' => 'Объект символьной ссылки',

	"permchange"		=> "CHMOD удачно:",
	"savefile"		=> "Файл сохранен.",
	"moveitem"		=> "Перемещение завершено.",
	"copyitem"		=> "Копирование завершено.",
	'archive_name' 	=> 'Имя архива',
	'archive_saveToDir' 	=> 'Сохранить архив в директории',

	'editor_simple'	=> 'Простейший режим редактора',
	'editor_syntaxhighlight'	=> 'Режим Syntax-Highlighted',

	'newlink'	=> 'Новый файл/Директория',
	'show_directories' => 'Показать директории',
	'actlogin_success' => 'Вы успешно вошли!',
	'actlogin_failure' => 'Ошибка входа, попробуйте еще раз.',
	'directory_tree' => 'Дерево каталогов',
	'browsing_directory' => 'Просмотр директории',
	'filter_grid' => 'Фильтр',
	'paging_page' => 'Страница',
	'paging_of_X' => 'из {0}',
	'paging_firstpage' => 'Первая страница',
	'paging_lastpage' => 'Последняя страница',
	'paging_nextpage' => 'Следующая страница',
	'paging_prevpage' => 'Предыдущая страница',

	'paging_info' => 'Отображаемые объекты {0} - {1} of {2}',
	'paging_noitems' => 'Нет объектов для отображения',
	'aboutlink' => 'информация...',
	'password_warning_title' => 'Необходимо сменить ваш пароль!',
	'password_warning_text' => 'Аккаунт пользователя, под которым вы зашли (admin с паролем admin) соответствует привилегированному аккаунту по умолчанию eXtplorer’а. Ваша установка eXtplorer’а открыта к вторжению и вам следует немедленно устранить дыру в безопасности!',
	'change_password_success' => 'Ваш пароль был изменен!',
	'success' => 'Удачно',
	'failure' => 'Ошибка',
	'dialog_title' => 'Веб-диалог',
	'upload_processing' => 'Идет закачка, пожалуйста, подождите...',
	'upload_completed' => 'Закачка завершена!',
	'acttransfer' => 'Передача с другого сервера',
	'transfer_processing' => 'Передача с сервера на сервер, пожалуйста, подождите...',
	'transfer_completed' => 'Передача завершена!',
	'max_file_size' => 'Максимальный размер файла',
	'max_post_size' => 'Максимальный лимит закачки',
	'done' => 'Готово.',
	'permissions_processing' => 'Изменение прав, пожалуйста подождите...',
	'archive_created' => 'The Archive File has been created!',
	'save_processing' => 'Сохранение файла...',
	'current_user' => 'Этот скрипт запущен с правами следующего пользователя:',
	'your_version' => 'Ваше версия',
	'search_processing' => 'Поиск, пожалуйста подождите...',
	'url_to_file' => 'Ссылка на файл',
	'file' => 'Файл'

);
?>
