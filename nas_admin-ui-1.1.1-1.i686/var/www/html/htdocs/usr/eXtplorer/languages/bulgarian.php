<?php

// Bulgarian Language Module for v2.3 (translated by the Ivo Apostolov)
global $_VERSION;

$GLOBALS["charset"] = "windows-1251";
$GLOBALS["text_dir"] = "ltr"; // ('ltr' for left to right, 'rtl' for right to left)
$GLOBALS["date_fmt"] = "Y/m/d H:i";
$GLOBALS["error_msg"] = array(
	// error
	"error"			=> "������",
	"back"			=> "�����",

	// root
	"home"			=> "���� ������ ����������.",
	"abovehome"		=> "���������� ���������� �� ���� �� ���� ��� ���������.",
	"targetabovehome"	=> "��������� ���������� �� ���� �� ���� ��� ���������.",

	// exist
	"direxist"		=> "������������ �� ����������.",
	"filedoesexist"	=> "This file already exists.",
	"fileexist"		=> "����� �� ����������.",
	"itemdoesexist"		=> "���� ��� ����� �����.",
	"itemexist"		=> "������ �� ����������.",
	"targetexist"		=> "������������ �� ����������.",
	"targetdoesexist"	=> "�������� ����� ���� ����������.",

	// open
	"opendir"		=> "�� � �������� �� ���� �������� ������������.",
	"readdir"		=> "�� � �������� �� ���� ��������� ������������.",

	// access
	"accessdir"		=> "������ ������ �� ���� ����������.",
	"accessfile"		=> "������ ������ �� ���� ����.",
	"accessitem"		=> "������ ������ �� ���� �����.",
	"accessfunc"		=> "������ ������ �� ���������� ���� �������.",
	"accesstarget"		=> "������ ������ �� ��������� ����������.",

	// actions
	"permread"		=> "������ ��� ������� �� �������.",
	"permchange"	=> "������ ��� ����� �� �������.",
	"openfile"		=> "������ ��� ���������� �� �����.",
	"savefile"		=> "������ ��� ������ �� �����.",
	"createfile"	=> "������ ��� ����������� �� ����.",
	"createdir"		=> "������ ��� ����������� �� ����������.",
	"uploadfile"	=> "������ ��� ��������� �� ����.",
	"copyitem"		=> "������ ��� ��������.",
	"moveitem"		=> "������ ��� �����������.",
	"delitem"		=> "������ ��� ���������.",
	"chpass"		=> "������ ��� ����� �� ������.",
	"deluser"		=> "������ ��� ��������� �� ����������.",
	"adduser"		=> "������ ��� �������� �� ����������.",
	"saveuser"		=> "������ ��� ������ �� ����������.",
	"searchnothing"	=> "�������� �������� �� �������.",

	// misc
	"miscnofunc"		=> "��������� �� � �������.",
	"miscfilesize"		=> "������ � ��� ����������� ����.",
	"miscfilepart"		=> "������ �� ����� ��������.",
	"miscnoname"		=> "������ �� �������� ���.",
	"miscselitems"		=> "�� ��� ������� ����.",
	"miscdelitems"		=> "������� �� ��� � ����������� �� ���� {0} ������?",
	"miscdeluser"		=> "������� �� ��� � ����������� �� ����������� {0}?",
	"miscnopassdiff"	=> "������ ������ �� �� ��������� �� �������.",
	"miscnopassmatch"	=> "�������� �� ��������.",
	"miscfieldmissed"	=> "���������� ��� ������������ ����.",
	"miscnouserpass"	=> "��������������� ��� ��� �������� �� ������.",
	"miscselfremove"	=> "�� ������ �� �������� ���� ��.",
	"miscuserexist"		=> "���� ��� ����� ����������.",
	"miscnofinduser"	=> "�� ���� �� ���� ������ ����������.",
	"extract_noarchive" => "������ �� ���� �� ���� ������������.",
	"extract_unknowntype" => "���������� ��� �� ������",
	
	'chmod_none_not_allowed' => 'Changing Permissions to <none> is not allowed',
	'archive_dir_notexists' => 'The Save-To Directory you have specified does not exist.',
	'archive_dir_unwritable' => 'Please specify a writable directory to save the archive to.',
	'archive_creation_failed' => 'Failed saving the Archive File'
);
$GLOBALS["messages"] = array(
	// links
	"permlink"		=> "����� �� �����",
	"editlink"		=> "��������",
	"downlink"		=> "�������",
	"uplink"		=> "������",
	"homelink"		=> "������",
	"reloadlink"		=> "������������",
	"copylink"		=> "��������",
	"movelink"		=> "�����������",
	"dellink"		=> "���������",
	"comprlink"		=> "����������",
	"adminlink"		=> "��������������",
	"logoutlink"		=> "�����",
	"uploadlink"		=> "�������",
	"searchlink"		=> "�������",
	"extractlink"	=> "�������������",
	'chmodlink'		=> '����� �� �������', // new mic
	'mossysinfolink'	=> 'eXtplorer �������� ���������� (eXtplorer, ������, PHP, MySQL)', // new mic
	'logolink'		=> '������� � ����� �� joomlaXplorer', // new mic

	// list
	"nameheader"		=> "���",
	"sizeheader"		=> "������",
	"typeheader"		=> "���",
	"modifheader"		=> "�����������",
	"permheader"		=> "�����",
	"actionheader"		=> "��������",
	"pathheader"		=> "���",

	// buttons
	"btncancel"		=> "�����",
	"btnsave"		=> "�����",
	"btnchange"		=> "�������",
	"btnreset"		=> "�������",
	"btnclose"		=> "�������",
	"btncreate"		=> "������",
	"btnsearch"		=> "�����",
	"btnupload"		=> "����",
	"btncopy"		=> "�������",
	"btnmove"		=> "��������",
	"btnlogin"		=> "����",
	"btnlogout"		=> "�����",
	"btnadd"		=> "������",
	"btnedit"		=> "����������",
	"btnremove"		=> "������",
	
	// user messages, new in joomlaXplorer 1.3.0
	'renamelink'	=> '�����������',
	'confirm_delete_file' => '������� �� ��� � ����������� �� ���� ����? \\n%s',
	'success_delete_file' => '������ �� ������� �������.',
	'success_rename_file' => '������������/����� %s �� ������������ �� %s.',
	
	// actions
	"actdir"		=> "����������",
	"actperms"		=> "����� �� �������",
	"actedit"		=> "�������� �� ����",
	"actsearchresults"	=> "��������� �� �������",
	"actcopyitems"		=> "�������� �� ������",
	"actcopyfrom"		=> "������� �� /%s � /%s ",
	"actmoveitems"		=> "����������� �� ������",
	"actmovefrom"		=> "�������� �� /%s � /%s ",
	"actlogin"		=> "����",
	"actloginheader"	=> "���� �� ���������� �� �������� �������",
	"actadmin"		=> "�������������",
	"actchpwd"		=> "����� �� ������",
	"actusers"		=> "�����������",
	"actarchive"		=> "���������� �� ��������",
	"actupload"		=> "������� �� �������",

	// misc
	"miscitems"		=> "������",
	"miscfree"		=> "��������",
	"miscusername"		=> "����������",
	"miscpassword"		=> "������",
	"miscoldpass"		=> "����� ������",
	"miscnewpass"		=> "���� ������",
	"miscconfpass"		=> "�������� ������",
	"miscconfnewpass"	=> "�������� ������ ������",
	"miscchpass"		=> "����� ������",
	"mischomedir"		=> "������� ����������",
	"mischomeurl"		=> "������� �����",
	"miscshowhidden"	=> "������ �������� ������",
	"mischidepattern"	=> "����� ���������",
	"miscperms"		=> "�����",
	"miscuseritems"		=> "(���, ������� ����������, ������ �������� ������, �����, ��������)",
	"miscadduser"		=> "������ ����������",
	"miscedituser"		=> "���������� ����������� '%s'",
	"miscactive"		=> "���������",
	"misclang"		=> "����",
	"miscnoresult"		=> "���� ���������.",
	"miscsubdirs"		=> "������� � ���������������",
	"miscpermnames"		=> array("���� �������","������������","����� �� ������","������������ & ����� �� ������",
					"�������������"),
	"miscyesno"		=> array("��","��","�","�"),
	"miscchmod"		=> array("����������", "�����", "����������"),

	// from here all new by mic
	'miscowner'			=> '����������',
	'miscownerdesc'		=> '<strong>��������:</strong><br />��������� (UID) /<br />����� (GID)<br />�������� �����:<br /><strong> %s ( %s ) </strong>/<br /><strong> %s ( %s )</strong>',

	// sysinfo (new by mic)
	'simamsysinfo'		=> 'eXtplorer ������� ����������',
	'sisysteminfo'		=> '�������� ����������',
	'sibuilton'			=> '����������� �������',
	'sidbversion'		=> '������ �� MySQL',
	'siphpversion'		=> '������ �� PHP',
	'siphpupdate'		=> '����������: <span style="color: red;">�������� �� PHP ����� �������� <strong>�� �</strong> ��������!</span><br />�� �� ����������� ������ �������������� �� Joomla! ������ �� ��������,<br /> ������� <strong>������ �� PHP 4.3</strong>!',
	'siwebserver'		=> '��� ������',
	'siwebsphpif'		=> '��� ������ - PHP ���������',
	'simamboversion'	=> 'eXtplorer ������',
	'siuseragent'		=> '������ �� ��������',
	'sirelevantsettings' => '����� PHP ���������',
	'sisafemode'		=> '������� �����',
	'sibasedir'			=> '�������� ������� ����������',
	'sidisplayerrors'	=> 'PHP ������',
	'sishortopentags'	=> '���� �������� �������',
	'sifileuploads'		=> '������� �� �������',
	'simagicquotes'		=> '��������� ������',
	'siregglobals'		=> '������������ �� ��������',
	'sioutputbuf'		=> '������� �����',
	'sisesssavepath'	=> '����� �� ���� �� �������',
	'sisessautostart'	=> '����������� ��������� �� �������',
	'sixmlenabled'		=> '��������� �� XML',
	'sizlibenabled'		=> '��������� �� ZLIB',
	'sidisabledfuncs'	=> '��������� �������',
	'sieditor'			=> 'WYSIWYG ��������',
	'siconfigfile'		=> '���� � ���������',
	'siphpinfo'			=> 'PHP ����������',
	'siphpinformation'	=> 'PHP ����������',
	'sipermissions'		=> '�����',
	'sidirperms'		=> '����� ����� ����������',
	'sidirpermsmess'	=> '�� �� ��� �������, �� ������ ������� �� eXtplorer ������� ��������, �������� ���������� ������ �� �� � ����� [chmod 0777]',
	'sionoff'			=> array( '�������', '��������' ),
	
	'extract_warning' => "������� �� ��� � ��������������� �� ���� ����? ���?\\n���������� �� ����������� ���� ������� ����� ���������, ��� ������� �� ��������!",
	'extract_success' => "�������������� � �������",
	'extract_failure' => "������ ��� ���������������",
	
	'overwrite_files' => 'Overwrite existing file(s)?',
	"viewlink"		=> "VIEW",
	"actview"		=> "Showing source of file",
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_chmod.php file
	'recurse_subdirs'	=> 'Recurse into subdirectories?',
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to footer.php file
	'check_version'	=> 'Check for latest version',
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_rename.php file
	'rename_file'	=>	'Rename a directory or file...',
	'newname'		=>	'New Name',
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_edit.php file
	'returndir'	=>	'Return to directory after saving?',
	'line'		=> 	'Line',
	'column'	=>	'Column',
	'wordwrap'	=>	'Wordwrap: (IE only)',
	'copyfile'	=>	'Copy file into this filename',
	
	// Bookmarks
	'quick_jump' => 'Quick Jump To',
	'already_bookmarked' => 'This directory is already bookmarked',
	'bookmark_was_added' => 'This directory was added to the bookmark list.',
	'not_a_bookmark' => 'This directory is not a bookmark.',
	'bookmark_was_removed' => 'This directory was removed from the bookmark list.',
	'bookmarkfile_not_writable' => "Failed to %s the bookmark.\n The Bookmark File '%s' \nis not writable.",
	
	'lbl_add_bookmark' => 'Add this Directory as Bookmark',
	'lbl_remove_bookmark' => 'Remove this Directory from the Bookmark List',
	
	'enter_alias_name' => 'Please enter the alias name for this bookmark',
	
	'normal_compression' => 'normal compression',
	'good_compression' => 'good compression',
	'best_compression' => 'best compression',
	'no_compression' => 'no compression',
	
	'creating_archive' => 'Creating Archive File...',
	'processed_x_files' => 'Processed %s of %s Files',
	
	'ftp_header' => 'Local FTP Authentication',
	'ftp_login_lbl' => 'Please enter the login credentials for the FTP server',
	'ftp_login_name' => 'FTP User Name',
	'ftp_login_pass' => 'FTP Password',
	'ftp_hostname_port' => 'FTP Server Hostname and Port <br />(Port is optional)',
	'ftp_login_check' => 'Checking FTP connection...',
	'ftp_connection_failed' => "The FTP server could not be contacted. \nPlease check that the FTP server is running on your server.",
	'ftp_login_failed' => "The FTP login failed. Please check the username and password and try again.",
		
	'switch_file_mode' => 'Current mode: <strong>%s</strong>. You could switch to %s mode.',
	'symlink_target' => 'Target of the Symbolic Link',
	
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
