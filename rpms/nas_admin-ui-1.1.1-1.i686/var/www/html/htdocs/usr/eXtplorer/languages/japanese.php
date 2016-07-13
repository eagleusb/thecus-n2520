<?php
// $Id: english.php 115 2009-01-10 11:18:58Z soeren $
// English Language Module for v2.3 (translated by the QuiX project)
global $_VERSION;

$GLOBALS["charset"] = "UTF-8";
$GLOBALS["text_dir"] = "ltr"; // ('ltr' for left to right, 'rtl' for right to left)
$GLOBALS["date_fmt"] = "Y/m/d H:i";
$GLOBALS["error_msg"] = array(
	// error
	"error"			=> "エラー",
	"message"			=> "メッセージ",
	"back"			=> "戻る",

	// root
	"home"			=> "ホームディレクトリが存在しません。設定を確認してください。",
	"abovehome"		=> "現在のディレクトリがホームディレクトリより上にないことが考えられます。",
	"targetabovehome"	=> "ターゲットディレクトリがホームディレクトリより上にないことが考えられます。",

	// exist
	"direxist"		=> "このディレクトリは存在しません。",
	"filedoesexist"	=> "このファイルはすでに存在します。",
	"fileexist"		=> "このファイルは存在しません。",
	"itemdoesexist"		=> "この項目はすでに存在します。",
	"itemexist"		=> "この項目は存在しません。",
	"targetexist"		=> "ターゲットディレクトリは存在しません。",
	"targetdoesexist"	=> "ターゲット項目はすでに存在します。",

	// open
	"opendir"		=> "ディレクトリを開くことができません。",
	"readdir"		=> "ディレクトリを読み取ることができません。",

	// access
	"accessdir"		=> "このディレクトリへのアクセスは許可されていません。",
	"accessfile"		=> "このファイルへのアクセスは許可されていません。",
	"accessitem"		=> "この項目へのアクセスは許可されていません。",
	"accessfunc"		=> "この機能の使用は許可されていません。",
	"accesstarget"		=> "ターゲットディレクトリへのアクセスは許可されていません。",

	// actions
	"permread"		=> "パーミッションの取得に失敗しました。",
	"permchange"		=> "CHMOD エラー（ファイルの所有権の問題が考えられます - HTTP ユーザー（'wwwrun' または 'nobody'）と FTP ユーザーが同じでない場合など）",
	"openfile"		=> "ファイルを開くことができませんでした。",
	"savefile"		=> "ファイルの保存に失敗しました。",
	"createfile"		=> "ファイルの作成に失敗しました。",
	"createdir"		=> "ディレクトリの作成に失敗しました。",
	"uploadfile"		=> "ファイルのアップロードに失敗しました。",
	"copyitem"		=> "コピーに失敗しました。",
	"moveitem"		=> "移動に失敗しました。",
	"delitem"		=> "削除に失敗しました。",
	"chpass"		=> "パスワードの変更に失敗しました。",
	"deluser"		=> "ユーザーの削除に失敗しました。",
	"adduser"		=> "ユーザーの追加に失敗しました。",
	"saveuser"		=> "ユーザーの保存に失敗しました。",
	"searchnothing"		=> "検索条件を入力してください。",

	// misc
	"miscnofunc"		=> "機能を使用できません。",
	"miscfilesize"		=> "ファイルが最大サイズを超えています。",
	"miscfilepart"		=> "ファイルは一部しかアップロードされませんでした。",
	"miscnoname"		=> "名前を入力してください。",
	"miscselitems"		=> "項目が選択されていません。",
	"miscdelitems"		=> "これら {0} 項目を削除してもよろしいですか?",
	"miscdeluser"		=> "ユーザー '{0}' を削除してもよろしいですか?",
	"miscnopassdiff"	=> "新しいパスワードが現在のパスワードと同じです。",
	"miscnopassmatch"	=> "パスワードが一致しません。",
	"miscfieldmissed"	=> "重要なフィールドが入力されていません。",
	"miscnouserpass"	=> "ユーザー名またはパスワードが正しくありません。",
	"miscselfremove"	=> "ご自分を削除することはできません。",
	"miscuserexist"		=> "ユーザーはすでに存在します。",
	"miscnofinduser"	=> "ユーザーを見つけることができません。",
	"extract_noarchive" => "ファイルは解凍可能なアーカイブではありません。",
	"extract_unknowntype" => "不明なアーカイブタイプです",
	
	'chmod_none_not_allowed' => 'パーミッションを <none> に変更することはできません',
	'archive_dir_notexists' => '指定した保存先ディレクトリは存在しません。',
	'archive_dir_unwritable' => 'アーカイブを保存する書き込み可能なディレクトリを指定してください。',
	'archive_creation_failed' => 'アーカイブファイルの保存に失敗しました'
	
);
$GLOBALS["messages"] = array(
	// links
	"permlink"		=> "パーミッションの変更",
	"editlink"		=> "編集",
	"downlink"		=> "ダウンロード",
	"uplink"		=> "アップ",
	"homelink"		=> "ホーム",
	"reloadlink"		=> "再読み込み",
	"copylink"		=> "コピー",
	"movelink"		=> "移動",
	"dellink"		=> "削除",
	"comprlink"		=> "アーカイブ",
	"adminlink"		=> "管理",
	"logoutlink"		=> "ログアウト",
	"uploadlink"		=> "アップロード",
	"searchlink"		=> "検索",
	"extractlink"	=> "アーカイブの解凍",
	'chmodlink'		=> '変更（chmod）する権利（フォルダ/ファイル）', // new mic
	'mossysinfolink'	=> 'eXtplorer システム情報（eXtplorer、サーバー、PHP、mySQL）', // new mic
	'logolink'		=> 'eXtplorer Web サイト（新しいウィンドウ）へ移動', // new mic

	// list
	"nameheader"		=> "名前",
	"sizeheader"		=> "サイズ",
	"typeheader"		=> "タイプ",
	"modifheader"		=> "変更済み",
	"permheader"		=> "パームズ",
	"actionheader"		=> "アクション",
	"pathheader"		=> "パス",

	// buttons
	"btncancel"		=> "キャンセル",
	"btnsave"		=> "保存",
	"btnchange"		=> "変更",
	"btnreset"		=> "リセット",
	"btnclose"		=> "閉じる",
	"btncreate"		=> "作成",
	"btnsearch"		=> "検索",
	"btnupload"		=> "アップロード",
	"btncopy"		=> "コピー",
	"btnmove"		=> "移動",
	"btnlogin"		=> "ログイン",
	"btnlogout"		=> "ログアウト",
	"btnadd"		=> "追加",
	"btnedit"		=> "編集",
	"btnremove"		=> "削除",
	
	// user messages, new in joomlaXplorer 1.3.0
	'renamelink'	=> '名前の変更',
	'confirm_delete_file' => 'このファイルを削除してもよろしいですか? <br />%s',
	'success_delete_file' => '項目は正常に削除されました。',
	'success_rename_file' => 'ディレクトリ/ファイル %s の名前は正常に %s に変更されました。',
	
	// actions
	"actdir"		=> "ディレクトリ",
	"actperms"		=> "パーミッションの変更",
	"actedit"		=> "ファイルの編集",
	"actsearchresults"	=> "検索結果",
	"actcopyitems"		=> "項目のコピー",
	"actcopyfrom"		=> "/%s から /%s へコピー ",
	"actmoveitems"		=> "項目の移動",
	"actmovefrom"		=> "/%s から /%s へ移動 ",
	"actlogin"		=> "ログイン",
	"actloginheader"	=> "eXtplorer を使用するためにログイン",
	"actadmin"		=> "管理",
	"actchpwd"		=> "パスワードの変更",
	"actusers"		=> "ユーザー",
	"actarchive"		=> "項目のアーカイブ",
	"actupload"		=> "ファイルのアップロード",

	// misc
	"miscitems"		=> "項目",
	"miscfree"		=> "空き",
	"miscusername"		=> "ユーザー名",
	"miscpassword"		=> "パスワード",
	"miscoldpass"		=> "古いパスワード",
	"miscnewpass"		=> "新しいパスワード",
	"miscconfpass"		=> "パスワードの確認",
	"miscconfnewpass"	=> "新しいパスワードの確認",
	"miscchpass"		=> "パスワードの変更",
	"mischomedir"		=> "ホームディレクトリ",
	"mischomeurl"		=> "ホーム URL",
	"miscshowhidden"	=> "非表示項目の表示",
	"mischidepattern"	=> "パターンの非表示",
	"miscperms"		=> "パーミッション",
	"miscuseritems"		=> "（名前、ホームディレクトリ、非表示項目の表示、パーミッション、アクティブ）",
	"miscadduser"		=> "ユーザーの追加",
	"miscedituser"		=> "ユーザー '%s' の編集",
	"miscactive"		=> "アクティブ",
	"misclang"		=> "言語",
	"miscnoresult"		=> "使用できる結果がありません。",
	"miscsubdirs"		=> "サブディレクトリの検索",
	"miscpermnames"		=> array("表示のみ","変更","パスワードの変更","変更とパスワードの変更",
					"管理者"),
	"miscyesno"		=> array("はい","いいえ","Y","N"),
	"miscchmod"		=> array("所有者", "グループ", "パブリック"),

	// from here all new by mic
	'miscowner'			=> '所有者',
	'miscownerdesc'		=> '<strong>説明:</strong><br />ユーザー（UID） /<br />グループ（GID）<br />現在の権利:<br /><strong> %s ( %s ) </strong>/<br /><strong> %s ( %s )</strong>',

	// sysinfo (new by mic)
	'simamsysinfo'		=> "eXtplorer システム情報",
	'sisysteminfo'		=> 'システム情報',
	'sibuilton'			=> 'オペレーティングシステム',
	'sidbversion'		=> 'データベースバージョン（MySQL）',
	'siphpversion'		=> 'PHP バージョン',
	'siphpupdate'		=> '情報: <span style="color: red;">お使いの PHP バージョンは <strong>古い</strong> バージョンです!</span><br />Mambo およびアドオンのすべての機能が正しく動作するためには、<br />最低 <strong>PHP.Version 4.3 が必要です</strong>!',
	'siwebserver'		=> 'Web サーバー',
	'siwebsphpif'		=> 'Web サーバー - PHP インターフェース',
	'simamboversion'	=> 'eXtplorer バージョン',
	'siuseragent'		=> 'ブラウザバージョン',
	'sirelevantsettings' => '重要な PHP 設定',
	'sisafemode'		=> 'セーフモード',
	'sibasedir'			=> 'ベースディレクトリを開く',
	'sidisplayerrors'	=> 'PHP エラー',
	'sishortopentags'	=> 'ショートオープンタグ',
	'sifileuploads'		=> 'ファイルアップロード',
	'simagicquotes'		=> 'マジッククオート',
	'siregglobals'		=> 'Globals の登録',
	'sioutputbuf'		=> '出力バッファ',
	'sisesssavepath'	=> 'セッションセーブパス',
	'sisessautostart'	=> 'セッション自動開始',
	'sixmlenabled'		=> 'XML 有効',
	'sizlibenabled'		=> 'ZLIB 有効',
	'sidisabledfuncs'	=> '無効な機能',
	'sieditor'			=> 'WYSIWYG エディタ',
	'siconfigfile'		=> '設定ファイル',
	'siphpinfo'			=> 'PHP 情報',
	'siphpinformation'	=> 'PHP 情報',
	'sipermissions'		=> 'パーミッション',
	'sidirperms'		=> 'ディレクトリパーミッション',
	'sidirpermsmess'	=> 'eXtplorer のすべての機能が正しく動作するためには、次のフォルダに書き込みパーミッション [chmod 0777] が必要です',
	'sionoff'			=> array( 'オン', 'オフ' ),
	
	'extract_warning' => "このファイルを解凍してもよろしいですか? ここですか?<br />これは注意して使用しないと、既存のファイルを上書きします!",
	'extract_success' => "正常に解凍しました",
	'extract_failure' => "解凍に失敗しました",
	
	'overwrite_files' => '既存のファイルを上書きしますか?',
	"viewlink"		=> "表示",
	"actview"		=> "ファイルのソースを表示します",
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_chmod.php file
	'recurse_subdirs'	=> 'サブディレクトリ内にリコースしますか?',
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to footer.php file
	'check_version'	=> '最新バージョンの確認',
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_rename.php file
	'rename_file'	=>	'ディレクトリまたはファイルの名前の変更...',
	'newname'		=>	'新しい名前',
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_edit.php file
	'returndir'	=>	'保存した後でディレクトリに戻りますか?',
	'line'		=> 	'行',
	'column'	=>	'列',
	'wordwrap'	=>	'ワードラップ: （IE のみ）',
	'copyfile'	=>	'ファイルをこのファイル名にコピーする',
	
	// Bookmarks
	'quick_jump' => 'クイックジャンプ先',
	'already_bookmarked' => 'このディレクトリはすでにブックマークされています',
	'bookmark_was_added' => 'このディレクトリはブックマーク一覧に追加されました。',
	'not_a_bookmark' => 'このディレクトリはブックマークではありません。',
	'bookmark_was_removed' => 'このディレクトリはブックマーク一覧から削除されました。',
	'bookmarkfile_not_writable' => "ブックマークの %s に失敗しました。\n ブックマークファイル '%s' \nには書き込みできません。",
	
	'lbl_add_bookmark' => 'このディレクトリをブックマークとして追加する',
	'lbl_remove_bookmark' => 'このディレクトリをブックマーク一覧から削除する',
	
	'enter_alias_name' => 'このブックマーク用のエイリアス名を入力してください',
	
	'normal_compression' => '通常圧縮',
	'good_compression' => '高圧縮',
	'best_compression' => '最高圧縮',
	'no_compression' => '圧縮なし',
	
	'creating_archive' => 'アーカイブファイルを作成しています...',
	'processed_x_files' => '%s ファイルの %s を処理しました',
	
	'ftp_header' => 'ローカル FTP 認証',
	'ftp_login_lbl' => 'FTP サーバー用のログインクレデンシャルを入力してください',
	'ftp_login_name' => 'FTP ユーザー名',
	'ftp_login_pass' => 'FTP パスワード',
	'ftp_hostname_port' => 'FTP サーバーホスト名とポート<br />（ポートはオプションです）',
	'ftp_login_check' => 'FTP 接続を確認しています...',
	'ftp_connection_failed' => "FTP サーバーに接触できませんでした。 \nFTP サーバーがお使いのサーバー上で実行していることを確認してください。",
	'ftp_login_failed' => "FTP ログインに失敗しました。 ユーザー名とパスワードを確認して、もう一度お試しください。",
		
	'switch_file_mode' => '現在のモード: <strong>%s</strong>。 %s モードに切り替えることができます。',
	'symlink_target' => 'シンボリックリンクのターゲット',
	
	"permchange"		=> "Chmod 成功:",
	"savefile"		=> "ファイルは保存されました。",
	"moveitem"		=> "正常に移動しました。",
	"copyitem"		=> "正常にコピーしました。",
	'archive_name' 	=> 'アーカイブファイルの名前',
	'archive_saveToDir' 	=> 'アーカイブをこのディレクトリに保存する',
	
	'editor_simple'	=> 'シンプルエディタモード',
	'editor_syntaxhighlight'	=> 'シンタックスハイライトモード',

	'newlink'	=> '新しいファイル/ディレクトリ',
	'show_directories' => 'ディレクトリの表示',
	'actlogin_success' => '正常にログインしました!',
	'actlogin_failure' => 'ログインに失敗しました。もう一度お試しください。',
	'directory_tree' => 'ディレクトリツリー',
	'browsing_directory' => 'ディレクトリを検索します',
	'filter_grid' => 'フィルタ',
	'paging_page' => '{0} の',
	'paging_of_X' => 'ページ',
	'paging_firstpage' => '最初のページ',
	'paging_lastpage' => '最後のページ',
	'paging_nextpage' => '次のページ',
	'paging_prevpage' => '前のページ',
	
	'paging_info' => '{2} の項目 {0} - {1} を表示します',
	'paging_noitems' => '表示する項目がありません',
	'aboutlink' => '情報...',
	'password_warning_title' => '重要 - パスワードの変更!',
	'password_warning_text' => 'ログインしたユーザーアカウント（ユーザー名、パスワードともに admin）はデフォルトの eXtplorer 特権アカウントと一致します。 eXtplorer インストールが侵入を許します。このセキュリティホールを直ちに修正してください!',
	'change_password_success' => 'あなたのパスワードは変更されました!',
	'success' => '成功',
	'failure' => '失敗',
	'dialog_title' => 'Web サイトダイアログ',
	'upload_processing' => 'アップロードを処理しています、お待ちください...',
	'upload_completed' => '正常にアップロードしました!',
	'acttransfer' => 'その他のサーバーから転送する',
	'transfer_processing' => 'サーバーからサーバーへの転送を処理しています、お待ちください...',
	'transfer_completed' => '転送が完了しました!',
	'max_file_size' => '最大ファイルサイズ',
	'max_post_size' => '最大アップロード制限',
	'done' => '完了。',
	'permissions_processing' => 'パーミッションを適用しています、お待ちください...',
	'archive_created' => 'アーカイブファイルは作成されました!',
	'save_processing' => 'ファイルを保存しています...',
	'current_user' => 'このスクリプトは現在次のユーザーのパーミッションで実行しています:',
	'your_version' => 'お使いのバージョン',
	'search_processing' => '検索しています、お待ちください...',
	'url_to_file' => 'ファイルの URL',
	'file' => 'ファイル',
	'create_title' => 'Create New Directory/File'
	
);
?>
