<?php

$GLOBALS["charset"] = "utf-8";
$GLOBALS["text_dir"] = "ltr"; // ('ltr' for left to right, 'rtl' for right to left)
$GLOBALS["date_fmt"] = "Y/m/d H:i";
$GLOBALS["error_msg"] = array(
	// error
	"error"			=> "错误",
	"back"			=> "回上页",
	
	// root
	"home"			=> "主目录并不存在, 请检查设定.",
	"abovehome"		=> "目前的目录可能没有在主目录上.",
	"targetabovehome"	=> "目标的目录可能没有在主目录上.",
	
	// exist
	"direxist"		=> "此目录不存在.",
	"filedoesexist"	=> "此档案已存在.",
	"fileexist"		=> "此档案不存在.",
	"itemdoesexist"		=> "此项目已存在.",
	"itemexist"		=> "此项目不存在.",
	"targetexist"		=> "这目标目录不存在.",
	"targetdoesexist"	=> "这目标项目已存在.",
	
	// open
	"opendir"		=> "无法打开目录.",
	"readdir"		=> "无法读取目录.",
	
	// access
	"accessdir"		=> "您不允许存取这个目录.",
	"accessfile"		=> "您不允许存取这个档案.",
	"accessitem"		=> "您不允许存取这个项目.",
	"accessfunc"		=> "您不允许使用这个功能.",
	"accesstarget"		=> "您不允许存取这个目标目录.",
	
	// actions
	"permread"		=> "取得权限失败.",
	"permchange"		=> "权限更改失败.",
	"openfile"		=> "打开档案失败.",
	"savefile"		=> "档案储存失败.",
	"createfile"		=> "新增档案失败.",
	"createdir"		=> "新增目录失败.",
	"uploadfile"		=> "档案上传失败.",
	"copyitem"		=> "复制失败.",
	"moveitem"		=> "移动失败.",
	"delitem"		=> "删除失败.",
	"chpass"		=> "更改密码失败.",
	"deluser"		=> "移除使用者失败.",
	"adduser"		=> "加入使用者失败.",
	"saveuser"		=> "储存使用者失败.",
	"searchnothing"		=> "您必须输入些什么来搜寻.",
	
	// misc
	"miscnofunc"		=> "功能无效.",
	"miscfilesize"		=> "档案大小已达到最大.",
	"miscfilepart"		=> "档案只有一部分上传.",
	"miscnoname"		=> "您必须输入名称.",
	"miscselitems"		=> "您还未选择任何项目.",
	"miscdelitems"		=> "您确定要删除这些 {0} 项目?",
	"miscdeluser"		=> "您确定要删除使用者 '{0}'?",
	"miscnopassdiff"	=> "新密码跟旧密码相同.",
	"miscnopassmatch"	=> "密码不符.",
	"miscfieldmissed"	=> "您遗漏一个重要字段.",
	"miscnouserpass"	=> "使用者名称或密码错误.",
	"miscselfremove"	=> "您无法移除您自己.",
	"miscuserexist"		=> "使用者已存在.",
	"miscnofinduser"	=> "无法找到使用者.",
	"extract_noarchive" => "此档案无法执行压缩.",
	"extract_unknowntype" => "未知的压缩类型"	,
	
	"chmod_none_not_allowed" => "不允许将权限变更为<none> ",
	"archive_dir_notexists" => "您指定的储存至目录不存在。",
	"archive_dir_unwritable" => "请指定可写入的目录，储存封存盘案。",
	"archive_creation_failed" => "无法储存封存档案"
);

$GLOBALS["messages"] = array(
	// links
	"permlink"		=> "更改权限",
	"editlink"		=> "编辑",
	"downlink"		=> "下载",
	"uplink"		=> "上一层",
	"homelink"		=> "主页",
	"reloadlink"		=> "重新加载",
	"copylink"		=> "复制",
	"movelink"		=> "移动",
	"dellink"		=> "删除",
	"comprlink"		=> "压缩",
	"adminlink"		=> "管理员",
	"logoutlink"		=> "注销",
	"uploadlink"		=> "上传",
	"searchlink"		=> "搜寻",
	"extractlink"	=> "解开压缩档",
	"chmodlink"		=> "更改 (chmod) 权限 (Folder/File(s))", // new mic
	"mossysinfolink"	=> "eXtplorer 系统信息 (eXtplorer, Server, PHP, mySQL)", // new mic
	"logolink"		=> "前往 joomlaXplorer 网站 (另开窗口)", // new mic
	
	// list
	"nameheader"		=> "名称",
	"sizeheader"		=> "大小",
	"typeheader"		=> "类型",
	"modifheader"		=> "最后更新",
	"permheader"		=> "权限",
	"actionheader"		=> "动作",
	"pathheader"		=> "路径",
	
	// buttons
	"btncancel"		=> "取消",
	"btnsave"		=> "储存",
	"btnchange"		=> "更改",
	"btnreset"		=> "重设",
	"btnclose"		=> "关闭",
	"btncreate"		=> "新增",
	"btnsearch"		=> "搜寻",
	"btnupload"		=> "上传",
	"btncopy"		=> "复制",
	"btnmove"		=> "移动",
	"btnlogin"		=> "登入",
	"btnlogout"		=> "注销",
	"btnadd"		=> "增加",
	"btnedit"		=> "编辑",
	"btnremove"		=> "移除",
	
		// user messages, new in joomlaXplorer 1.3.0
	"renamelink"	=> "重新命名",
	"confirm_delete_file" => "您确定要删除这个档案? \\n%s",
	"success_delete_file" => "对象成功删除.",
	"success_rename_file" => "此目录/档案 %s 已成功重新命名为 %s.",
	
// actions
	"actdir"		=> "目录",
	"actperms"		=> "更改权限",
	"actedit"		=> "编辑档案",
	"actsearchresults"	=> "搜寻结果",
	"actcopyitems"		=> "复制项目",
	"actcopyfrom"		=> "从 /%s 复制到 /%s ",
	"actmoveitems"		=> "移动项目",
	"actmovefrom"		=> "从 /%s 移动到 /%s ",
	"actlogin"		=> "登入",
	"actloginheader"	=> "登入以使用 QuiXplorer",
	"actadmin"		=> "管理选单",
	"actchpwd"		=> "更改密码",
	"actusers"		=> "使用者",
	"actarchive"		=> "压缩项目",
	"actupload"		=> "上传档案",
	
	// misc
	"miscitems"		=> "项目",
	"miscfree"		=> "可用",
	"miscusername"		=> "使用者名称",
	"miscpassword"		=> "密码",
	"miscoldpass"		=> "旧密码",
	"miscnewpass"		=> "新密码",
	"miscconfpass"		=> "确认密码",
	"miscconfnewpass"	=> "确认新密码",
	"miscchpass"		=> "更改密码",
	"mischomedir"		=> "主页目录",
	"mischomeurl"		=> "主页 URL",
	"miscshowhidden"	=> "显示隐藏项目",
	"mischidepattern"	=> "隐藏样式",
	"miscperms"		=> "权限",
	"miscuseritems"		=> "(名称, 主页目录, 显示隐藏项目, 权限, 启用)",
	"miscadduser"		=> "增加使用者",
	"miscedituser"		=> "编辑使用者 '%s'",
	"miscactive"		=> "启用",
	"misclang"		=> "语言",
	"miscnoresult"		=> "无结果可用.",
	"miscsubdirs"		=> "搜寻子目录",
	"miscpermnames"		=> array("只能浏览","修改","更改密码","修改及更改密码","管理员"),
	"miscyesno"		=> array("是的","否","Y","N"),
	"miscchmod"		=> array("拥有者", "群组", "公开的"),
	
	// from here all new by mic
	"miscowner"			=> "拥有者",
	"miscownerdesc"		=> "<strong>描述:</strong><br />使用者 (UID) /<br />群组 (GID)<br />目前权限:<br /><strong> %s ( %s ) </strong>/<br /><strong> %s ( %s )</strong>",

	// sysinfo (new by mic)
	"simamsysinfo"		=> "eXtplorer 系统信息",
	"sisysteminfo"		=> "系统信息",
	"sibuilton"			=> "运行系统",
	"sidbversion"		=> "数据库版本 (MySQL)",

	"siphpversion"		=> "PHP 版本",
	"siphpupdate"		=> "信息： 您使用的PHP版本<strong>并非</strong>正版！<br />为保证所有Mambo 与附加功能均能正常使用，<br />您至少应使用<strong>PHP.Version 4.3</strong>!",
	"siwebserver"		=> "网页服务器",
	"siwebsphpif"		=> "网页服务器 - PHP 接口",
	"simamboversion"	=> "eXtplorer 版本",
	"siuseragent"		=> "浏览器版本",
	"sirelevantsettings" => "重要的 PHP 设定",
	"sisafemode"		=> "安全模式",
	"sibasedir"			=> "开启basedir",
	"sidisplayerrors"	=> "_PHP错误",
	"sishortopentags"	=> "短开放式标记",
	"sifileuploads"		=> "档案上传",
	"simagicquotes"		=> "Magic Quotes",
	"siregglobals"		=> "全域登录",
	"sioutputbuf"		=> "输出缓冲区",
	"sisesssavepath"	=> "工作阶段储存路径",
	"sisessautostart"	=> "工作阶段自动启动",
	"sixmlenabled"		=> "XML 已启动",
	"sizlibenabled"		=> "ZLIB 已启动",
	"sidisabledfuncs"	=> "未启用的函式",
	"sieditor"			=> "WYSIWYG 编辑器",
	"siconfigfile"		=> "设定档",
	"siphpinfo"			=> "PHP 信息",
	"siphpinformation"	=> "PHP 信息",
	"sipermissions"		=> "权限",
	"sidirperms"		=> "目录权限",
	"sidirpermsmess"	=> "为确定所有eXtplorer的功能均正确运作，下列数据夹应有写入[chmod 0777]的权限",
	"sionoff"			=> array( "开", "关" ),
	
	"extract_warning" => "您确定要在此处解压档案?\\n如果不小心使用这将会覆盖已经存在的档案!",
	"extract_success" => "解压缩成功 ",
	"extract_failure" => "解压缩失败",	
	
	"overwrite_files" => "复盖已存在的档案?",
	"viewlink"		=> "检视",
	"actview"		=> "显示档案来源",
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_chmod.php file
	"recurse_subdirs"	=> "是否递回子目录？",
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to footer.php file
	"check_version"	=> "检查最新版本",
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_rename.php file
	"rename_file"	=>	"重新命名目录或档案",
	"newname"		=>	"新名称",
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_edit.php file
	"returndir"	=>	"是否在储存后回到目录？",
	"line"		=> 	"行",
	"column"	=>	"栏",
	"wordwrap"	=>	"自动换行： (仅IE)",
	"copyfile"	=>	"复制档案至此档名",
	
	// Bookmarks
	"quick_jump" => "快速跳至",
	"already_bookmarked" => "此目录已标记书签",
	"bookmark_was_added" => "此目录已加入书签清单。",
	"not_a_bookmark" => "此目录不是书签。",
	"bookmark_was_removed" => "此目录已从书签清单移除。",
	"bookmarkfile_not_writable" => "无法%s书签。\n书签文件'%s' \n无法写入。",
	
	"lbl_add_bookmark" => "将此目录作为书签加入",
	"lbl_remove_bookmark" => "从书签清单移除此目录",
	
	"enter_alias_name" => "请输入此标签的别名",
	
	"normal_compression" => "一般压缩",
	"good_compression" => "较佳压缩",
	"best_compression" => "最佳压缩",
	"no_compression" => "未压缩",
	
	"creating_archive" => "正在建立封存档案…",
	"processed_x_files" => "%s档案的 %s已完成处理",
	
	"ftp_header" => "本机FTP验证",
	"ftp_login_lbl" => "请输入FTP服务器的登入认证",
	"ftp_login_name" => "FTP使用者名称",
	"ftp_login_pass" => "FTP密码",
	"ftp_hostname_port" => "FTP服务器主机名称与连接端口 <br /> (连接埠为选用)",
	"ftp_login_check" => "正在检查FTP联机…",
	"ftp_connection_failed" => "无法联络到FTP服务器。 \n请检查FTP服务器是否正在您的服务器上执行。",
	"ftp_login_failed" => "FTP登入失败。 请检查使用者名称与密码，然后重试一次。",
		
	"switch_file_mode" => "目前模式： <strong>%s</strong>。 您无法切换至%s模式。",
	"symlink_target" => "符号连结的目标",
	
	"permchange"		=> "CHMOD 成功：",
	"savefile"		=> "已储存档案。",
	"moveitem"		=> "成功移动。",
	"copyitem"		=> "成功复制。",
	"archive_name" 	=> "封存档案的名称",
	"archive_saveToDir" 	=> "将封存盘案储存于此目录下",
	
	"editor_simple"	=> "简易编辑器模式",
	"editor_syntaxhighlight"	=> "语法醒目显示模式",

	"newlink"	=> "新档案／目录",
	"show_directories" => "显示目录",
	"actlogin_success" => "登入成功！",
	"actlogin_failure" => "登入失败，请重试一次。",
	"directory_tree" => "树状目录",
	"browsing_directory" => "浏览目录",
	"filter_grid" => "筛选",
	"paging_page" => "页",
	"paging_of_X" => "{0} 的",
	"paging_firstpage" => "第一页",
	"paging_lastpage" => "最后一页",
	"paging_nextpage" => "下一页",
	"paging_prevpage" => "上一页",
	
	"paging_info" => "显示项目{0}-{2}的{1}",
	"paging_noitems" => "无项目显示",
	"aboutlink" => "关于…",
	"password_warning_title" => "重要 – 变更您的密码！",
	"password_warning_text" => "您登入的使用者账户(管理员及密码管理员) 对应到预设的eXtplorer权限账户。 您的eXtplorer安装出现漏洞，容易被入侵，应立即修复此安全性漏洞！",
	"change_password_success" => "您的密码已经变更！",
	"success" => "成功",
	"failure" => "失败",
	"dialog_title" => "网站对话框",
	"upload_processing" => "正在处理上传，请稍候…",
	"upload_completed" => "上传成功！",
	"acttransfer" => "从另一部服务器传输",
	"transfer_processing" => "正在处理服务器间的传输，请稍候…",
	"transfer_completed" => "传输完成！",
	"max_file_size" => "最大档案大小",
	"max_post_size" => "最大上传限制",
	"done" => "完成。",
	"permissions_processing" => "正在套用权限，请稍候…",
	"archive_created" => "已建立封存档案！",
	"save_processing" => "正在储存档案…",
	"current_user" => "此指令码目前以下列使用者的权限执行：",
	"your_version" => "您的版本",
	"search_processing" => "搜寻中，请稍候…",
	"url_to_file" => "档案的URL",
	"file" => "档案",
	"create_title" => "Create New Directory/File"
);
?>
