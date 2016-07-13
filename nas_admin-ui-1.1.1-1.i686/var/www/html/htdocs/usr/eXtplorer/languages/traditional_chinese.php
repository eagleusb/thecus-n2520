<?php

$GLOBALS["charset"] = "utf-8";
$GLOBALS["text_dir"] = "ltr"; // ('ltr' for left to right, 'rtl' for right to left)
$GLOBALS["date_fmt"] = "Y/m/d H:i";
$GLOBALS["error_msg"] = array(
	// error
	"error"			=> "錯誤",
	"back"			=> "回上頁",
	
	// root
	"home"			=> "主目錄並不存在, 請檢查設定.",
	"abovehome"		=> "目前的目錄可能沒有在主目錄上.",
	"targetabovehome"	=> "目標的目錄可能沒有在主目錄上.",
	
	// exist
	"direxist"		=> "此目錄不存在.",
	"filedoesexist"	=> "此檔案已存在.",
	"fileexist"		=> "此檔案不存在.",
	"itemdoesexist"		=> "此項目已存在.",
	"itemexist"		=> "此項目不存在.",
	"targetexist"		=> "這目標目錄不存在.",
	"targetdoesexist"	=> "這目標項目已存在.",
	
	// open
	"opendir"		=> "無法打開目錄.",
	"readdir"		=> "無法讀取目錄.",
	
	// access
	"accessdir"		=> "您不允許存取這個目錄.",
	"accessfile"		=> "您不允許存取這個檔案.",
	"accessitem"		=> "您不允許存取這個項目.",
	"accessfunc"		=> "您不允許使用這個功能.",
	"accesstarget"		=> "您不允許存取這個目標目錄.",
	
	// actions
	"permread"		=> "取得權限失敗.",
	"permchange"		=> "權限更改失敗.",
	"openfile"		=> "打開檔案失敗.",
	"savefile"		=> "檔案儲存失敗.",
	"createfile"		=> "新增檔案失敗.",
	"createdir"		=> "新增目錄失敗.",
	"uploadfile"		=> "檔案上傳失敗.",
	"copyitem"		=> "複製失敗.",
	"moveitem"		=> "移動失敗.",
	"delitem"		=> "刪除失敗.",
	"chpass"		=> "更改密碼失敗.",
	"deluser"		=> "移除使用者失敗.",
	"adduser"		=> "加入使用者失敗.",
	"saveuser"		=> "儲存使用者失敗.",
	"searchnothing"		=> "您必須輸入些什麼來搜尋.",
	
	// misc
	"miscnofunc"		=> "功能無效.",
	"miscfilesize"		=> "檔案大小已達到最大.",
	"miscfilepart"		=> "檔案只有一部分上傳.",
	"miscnoname"		=> "您必須輸入名稱.",
	"miscselitems"		=> "您還未選擇任何項目.",
	"miscdelitems"		=> "您確定要刪除這些 {0} 項目?",
	"miscdeluser"		=> "您確定要刪除使用者 '{0}'?",
	"miscnopassdiff"	=> "新密碼跟舊密碼相同.",
	"miscnopassmatch"	=> "密碼不符.",
	"miscfieldmissed"	=> "您遺漏一個重要欄位.",
	"miscnouserpass"	=> "使用者名稱或密碼錯誤.",
	"miscselfremove"	=> "您無法移除您自己.",
	"miscuserexist"		=> "使用者已存在.",
	"miscnofinduser"	=> "無法找到使用者.",
	"extract_noarchive" => "此檔案無法執行壓縮.",
	"extract_unknowntype" => "未知的壓縮類型"	,
	
	"chmod_none_not_allowed" => "不允許將權限變更為<none> ",
	"archive_dir_notexists" => "您指定的儲存至目錄不存在。",
	"archive_dir_unwritable" => "請指定可寫入的目錄，儲存封存檔案。",
	"archive_creation_failed" => "無法儲存封存檔案"
);

$GLOBALS["messages"] = array(
	// links
	"permlink"		=> "更改權限",
	"editlink"		=> "編輯",
	"downlink"		=> "下載",
	"uplink"		=> "上一層",
	"homelink"		=> "主頁",
	"reloadlink"		=> "重新載入",
	"copylink"		=> "複製",
	"movelink"		=> "移動",
	"dellink"		=> "刪除",
	"comprlink"		=> "壓縮",
	"adminlink"		=> "管理員",
	"logoutlink"		=> "登出",
	"uploadlink"		=> "上傳",
	"searchlink"		=> "搜尋",
	"extractlink"	=> "解開壓縮檔",
	"chmodlink"		=> "更改 (chmod) 權限 (Folder/File(s))", // new mic
	"mossysinfolink"	=> "eXtplorer 系統資訊 (eXtplorer, Server, PHP, mySQL)", // new mic
	"logolink"		=> "前往 joomlaXplorer 網站 (另開視窗)", // new mic
	
	// list
	"nameheader"		=> "名稱",
	"sizeheader"		=> "大小",
	"typeheader"		=> "類型",
	"modifheader"		=> "最後更新",
	"permheader"		=> "權限",
	"actionheader"		=> "動作",
	"pathheader"		=> "路徑",
	
	// buttons
	"btncancel"		=> "取消",
	"btnsave"		=> "儲存",
	"btnchange"		=> "更改",
	"btnreset"		=> "重設",
	"btnclose"		=> "關閉",
	"btncreate"		=> "新增",
	"btnsearch"		=> "搜尋",
	"btnupload"		=> "上傳",
	"btncopy"		=> "複製",
	"btnmove"		=> "移動",
	"btnlogin"		=> "登入",
	"btnlogout"		=> "登出",
	"btnadd"		=> "增加",
	"btnedit"		=> "編輯",
	"btnremove"		=> "移除",
	
		// user messages, new in joomlaXplorer 1.3.0
	"renamelink"	=> "重新命名",
	"confirm_delete_file" => "您確定要刪除這個檔案? \\n%s",
	"success_delete_file" => "物件成功刪除.",
	"success_rename_file" => "此目錄/檔案 %s 已成功重新命名為 %s.",
	
// actions
	"actdir"		=> "目錄",
	"actperms"		=> "更改權限",
	"actedit"		=> "編輯檔案",
	"actsearchresults"	=> "搜尋結果",
	"actcopyitems"		=> "複製項目",
	"actcopyfrom"		=> "從 /%s 複製到 /%s ",
	"actmoveitems"		=> "移動項目",
	"actmovefrom"		=> "從 /%s 移動到 /%s ",
	"actlogin"		=> "登入",
	"actloginheader"	=> "登入以使用 QuiXplorer",
	"actadmin"		=> "管理選單",
	"actchpwd"		=> "更改密碼",
	"actusers"		=> "使用者",
	"actarchive"		=> "壓縮項目",
	"actupload"		=> "上傳檔案",
	
	// misc
	"miscitems"		=> "項目",
	"miscfree"		=> "可用",
	"miscusername"		=> "使用者名稱",
	"miscpassword"		=> "密碼",
	"miscoldpass"		=> "舊密碼",
	"miscnewpass"		=> "新密碼",
	"miscconfpass"		=> "確認密碼",
	"miscconfnewpass"	=> "確認新密碼",
	"miscchpass"		=> "更改密碼",
	"mischomedir"		=> "主頁目錄",
	"mischomeurl"		=> "主頁 URL",
	"miscshowhidden"	=> "顯示隱藏項目",
	"mischidepattern"	=> "隱藏樣式",
	"miscperms"		=> "權限",
	"miscuseritems"		=> "(名稱, 主頁目錄, 顯示隱藏項目, 權限, 啟用)",
	"miscadduser"		=> "增加使用者",
	"miscedituser"		=> "編輯使用者 '%s'",
	"miscactive"		=> "啟用",
	"misclang"		=> "語言",
	"miscnoresult"		=> "無結果可用.",
	"miscsubdirs"		=> "搜尋子目錄",
	"miscpermnames"		=> array("只能瀏覽","修改","更改密碼","修改及更改密碼","管理員"),
	"miscyesno"		=> array("是的","否","Y","N"),
	"miscchmod"		=> array("擁有者", "群組", "公開的"),
	
	// from here all new by mic
	"miscowner"			=> "擁有者",
	"miscownerdesc"		=> "<strong>描述:</strong><br />使用者 (UID) /<br />群組 (GID)<br />目前權限:<br /><strong> %s ( %s ) </strong>/<br /><strong> %s ( %s )</strong>",

	// sysinfo (new by mic)
	"simamsysinfo"		=> "eXtplorer 系統資訊",
	"sisysteminfo"		=> "系統資訊",
	"sibuilton"			=> "運行系統",
	"sidbversion"		=> "資料庫版本 (MySQL)",

	"siphpversion"		=> "PHP 版本",
	"siphpupdate"		=> "資訊： 您使用的PHP版本<strong>並非</strong>正版！<br />為保證所有Mambo 與附加功能均能正常使用，<br />您至少應使用<strong>PHP.Version 4.3</strong>!",
	"siwebserver"		=> "網頁伺服器",
	"siwebsphpif"		=> "網頁伺服器 - PHP 介面",
	"simamboversion"	=> "eXtplorer 版本",
	"siuseragent"		=> "瀏覽器版本",
	"sirelevantsettings" => "重要的 PHP 設定",
	"sisafemode"		=> "安全模式",
	"sibasedir"			=> "開啟basedir",
	"sidisplayerrors"	=> "_PHP錯誤",
	"sishortopentags"	=> "短開放式標記",
	"sifileuploads"		=> "檔案上傳",
	"simagicquotes"		=> "Magic Quotes",
	"siregglobals"		=> "全域登錄",
	"sioutputbuf"		=> "輸出緩衝區",
	"sisesssavepath"	=> "工作階段儲存路徑",
	"sisessautostart"	=> "工作階段自動啟動",
	"sixmlenabled"		=> "XML 已啟動",
	"sizlibenabled"		=> "ZLIB 已啟動",
	"sidisabledfuncs"	=> "未啟用的函式",
	"sieditor"			=> "WYSIWYG 編輯器",
	"siconfigfile"		=> "設定檔",
	"siphpinfo"			=> "PHP 資訊",
	"siphpinformation"	=> "PHP 資訊",
	"sipermissions"		=> "權限",
	"sidirperms"		=> "目錄權限",
	"sidirpermsmess"	=> "為確定所有eXtplorer的功能均正確運作，下列資料夾應有寫入[chmod 0777]的權限",
	"sionoff"			=> array( "開", "關" ),
	
	"extract_warning" => "您確定要在此處解壓檔案?\\n如果不小心使用這將會覆蓋已經存在的檔案!",
	"extract_success" => "解壓縮成功 ",
	"extract_failure" => "解壓縮失敗",	
	
	"overwrite_files" => "複蓋已存在的檔案?",
	"viewlink"		=> "檢視",
	"actview"		=> "顯示檔案來源",
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_chmod.php file
	"recurse_subdirs"	=> "是否遞回子目錄？",
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to footer.php file
	"check_version"	=> "檢查最新版本",
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_rename.php file
	"rename_file"	=>	"重新命名目錄或檔案",
	"newname"		=>	"新名稱",
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_edit.php file
	"returndir"	=>	"是否在儲存後回到目錄？",
	"line"		=> 	"行",
	"column"	=>	"欄",
	"wordwrap"	=>	"自動換行： (僅IE)",
	"copyfile"	=>	"複製檔案至此檔名",
	
	// Bookmarks
	"quick_jump" => "快速跳至",
	"already_bookmarked" => "此目錄已標記書籤",
	"bookmark_was_added" => "此目錄已加入書籤清單。",
	"not_a_bookmark" => "此目錄不是書籤。",
	"bookmark_was_removed" => "此目錄已從書籤清單移除。",
	"bookmarkfile_not_writable" => "無法%s書籤。\n書籤檔'%s' \n無法寫入。",
	
	"lbl_add_bookmark" => "將此目錄作為書籤加入",
	"lbl_remove_bookmark" => "從書籤清單移除此目錄",
	
	"enter_alias_name" => "請輸入此標籤的別名",
	
	"normal_compression" => "一般壓縮",
	"good_compression" => "較佳壓縮",
	"best_compression" => "最佳壓縮",
	"no_compression" => "未壓縮",
	
	"creating_archive" => "正在建立封存檔案…",
	"processed_x_files" => "%s檔案的 %s已完成處理",
	
	"ftp_header" => "本機FTP驗證",
	"ftp_login_lbl" => "請輸入FTP伺服器的登入認證",
	"ftp_login_name" => "FTP使用者名稱",
	"ftp_login_pass" => "FTP密碼",
	"ftp_hostname_port" => "FTP伺服器主機名稱與連接埠 <br /> (連接埠為選用)",
	"ftp_login_check" => "正在檢查FTP連線…",
	"ftp_connection_failed" => "無法聯絡到FTP伺服器。 \n請檢查FTP伺服器是否正在您的伺服器上執行。",
	"ftp_login_failed" => "FTP登入失敗。 請檢查使用者名稱與密碼，然後重試一次。",
		
	"switch_file_mode" => "目前模式： <strong>%s</strong>。 您無法切換至%s模式。",
	"symlink_target" => "符號連結的目標",
	
	"permchange"		=> "CHMOD 成功：",
	"savefile"		=> "已儲存檔案。",
	"moveitem"		=> "成功移動。",
	"copyitem"		=> "成功複製。",
	"archive_name" 	=> "封存檔案的名稱",
	"archive_saveToDir" 	=> "將封存檔案儲存於此目錄下",
	
	"editor_simple"	=> "簡易編輯器模式",
	"editor_syntaxhighlight"	=> "語法醒目顯示模式",

	"newlink"	=> "新檔案／目錄",
	"show_directories" => "顯示目錄",
	"actlogin_success" => "登入成功！",
	"actlogin_failure" => "登入失敗，請重試一次。",
	"directory_tree" => "樹狀目錄",
	"browsing_directory" => "瀏覽目錄",
	"filter_grid" => "篩選",
	"paging_page" => "頁",
	"paging_of_X" => "{0} 的",
	"paging_firstpage" => "第一頁",
	"paging_lastpage" => "最後一頁",
	"paging_nextpage" => "下一頁",
	"paging_prevpage" => "上一頁",
	
	"paging_info" => "顯示項目{0}-{2}的{1}",
	"paging_noitems" => "無項目顯示",
	"aboutlink" => "關於…",
	"password_warning_title" => "重要 – 變更您的密碼！",
	"password_warning_text" => "您登入的使用者帳戶(管理員及密碼管理員) 對應到預設的eXtplorer權限帳戶。 您的eXtplorer安裝出現漏洞，容易被入侵，應立即修復此安全性漏洞！",
	"change_password_success" => "您的密碼已經變更！",
	"success" => "成功",
	"failure" => "失敗",
	"dialog_title" => "網站對話方塊",
	"upload_processing" => "正在處理上傳，請稍候…",
	"upload_completed" => "上傳成功！",
	"acttransfer" => "從另一部伺服器傳輸",
	"transfer_processing" => "正在處理伺服器間的傳輸，請稍候…",
	"transfer_completed" => "傳輸完成！",
	"max_file_size" => "最大檔案大小",
	"max_post_size" => "最大上傳限制",
	"done" => "完成。",
	"permissions_processing" => "正在套用權限，請稍候…",
	"archive_created" => "已建立封存檔案！",
	"save_processing" => "正在儲存檔案…",
	"current_user" => "此指令碼目前以下列使用者的權限執行：",
	"your_version" => "您的版本",
	"search_processing" => "搜尋中，請稍候…",
	"url_to_file" => "檔案的URL",
	"file" => "檔案",
	"create_title" => "Create New Directory/File"
);
?>
