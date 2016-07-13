<?php
// $Id: english.php 115 2009-01-10 11:18:58Z soeren $
// English Language Module for v2.3 (translated by the QuiX project)
global $_VERSION;

$GLOBALS["charset"] = "UTF-8";
$GLOBALS["text_dir"] = "ltr"; // ('ltr' for left to right, 'rtl' for right to left)
$GLOBALS["date_fmt"] = "Y/m/d H:i";
$GLOBALS["error_msg"] = array(
	// error
	"error"			=> "오류",
	"message"			=> "메시지",
	"back"			=> "돌아가기",

	// root
	"home"			=> "홈 디렉터리가 없습니다. 설정을 확인하십시오.",
	"abovehome"		=> "현재 디렉터리는 홈 디렉터리 위에 없을 수 있습니다.",
	"targetabovehome"	=> "대상 디렉터리는 홈 디렉터리 위에 없을 수 있습니다.",

	// exist
	"direxist"		=> "이 디렉터리는 없습니다.",
	"filedoesexist"	=> "이 파일이 이미 있습니다.",
	"fileexist"		=> "이 파일은 없습니다.",
	"itemdoesexist"		=> "이 항목이 이미 있습니다.",
	"itemexist"		=> "이 항목은 없습니다.",
	"targetexist"		=> "대상 디렉터리는 없습니다.",
	"targetdoesexist"	=> "대상 항목이 이미 있습니다.",

	// open
	"opendir"		=> "디렉터리를 열 수 없습니다.",
	"readdir"		=> "디렉터리를 읽을 수 없습니다.",

	// access
	"accessdir"		=> "이 디렉터리에 액세스할 수 없습니다.",
	"accessfile"		=> "이 파일에 액세스할 수 없습니다.",
	"accessitem"		=> "이 항목에 액세스할 수 없습니다.",
	"accessfunc"		=> "이 기능을 사용할 수 없습니다.",
	"accesstarget"		=> "대상 디렉터리에 액세스할 수 없습니다.",

	// actions
	"permread"		=> "사용 권한을 얻지 못했습니다.",
	"permchange"		=> "CHMOD 실패(대부분 이것은 파일 소유권 문제 때문에 발생합니다 – 예를 들어 HTTP 사용자('wwwrun' 또는 'nobody')와 FTP 사용자가 동일하지 않을 경우)",
	"openfile"		=> "파일을 열지 못했습니다.",
	"savefile"		=> "파일을 저장하지 못했습니다.",
	"createfile"		=> "파일을 작성하지 못했습니다.",
	"createdir"		=> "디렉터리를 작성하지 못했습니다.",
	"uploadfile"		=> "파일을 업로드하지 못했습니다.",
	"copyitem"		=> "복사하지 못했습니다.",
	"moveitem"		=> "이동하지 못했습니다.",
	"delitem"		=> "삭제하지 못했습니다.",
	"chpass"		=> "암호를 바꾸지 못했습니다.",
	"deluser"		=> "사용자를 제거하지 못했습니다.",
	"adduser"		=> "사용자를 추가하지 못했습니다.",
	"saveuser"		=> "사용자를 저장하지 못했습니다.",
	"searchnothing"		=> "검색어를 입력해야 합니다.",

	// misc
	"miscnofunc"		=> "기능을 이용할 수 없습니다.",
	"miscfilesize"		=> "파일이 최대 크기를 초과합니다.",
	"miscfilepart"		=> "파일이 일부만 업로드되었습니다.",
	"miscnoname"		=> "이름을 입력해야 합니다.",
	"miscselitems"		=> "어떤 항목도 선택하지 않았습니다.",
	"miscdelitems"		=> "이 {0}항목을 삭제하시겠습니까?",
	"miscdeluser"		=> "사용자 '{0}'을(를) 삭제하시겠습니까?",
	"miscnopassdiff"	=> "새 암호가 현재 암호와 다르지 않습니다.",
	"miscnopassmatch"	=> "암호가 일치하지 않습니다.",
	"miscfieldmissed"	=> "중요한 필드를 입력하지 않았습니다.",
	"miscnouserpass"	=> "사용자 이름 또는 암호가 올바르지 않습니다.",
	"miscselfremove"	=> "사용자 자신을 제거할 수 없습니다.",
	"miscuserexist"		=> "사용자가 이미 있습니다.",
	"miscnofinduser"	=> "사용자를 찾을 수 없습니다.",
	"extract_noarchive" => "이 파일은 추출할 수 없는 아카이브입니다.",
	"extract_unknowntype" => "알 수 없는 아카이브 유형",
	
	'chmod_none_not_allowed' => '사용 권한을 <없음>으로 변경할 수 없습니다.',
	'archive_dir_notexists' => '지정한 저장 디렉터리가 없습니다.',
	'archive_dir_unwritable' => '아카이브를 저장할 쓸 수 있는 디렉터리를 지정하십시오.',
	'archive_creation_failed' => '아카이브 파일 저장 실패'
	
);
$GLOBALS["messages"] = array(
	// links
	"permlink"		=> "사용권한 변경",
	"editlink"		=> "편집",
	"downlink"		=> "다운로드",
	"uplink"		=> "위",
	"homelink"		=> "홈",
	"reloadlink"		=> "다시 로드",
	"copylink"		=> "복사",
	"movelink"		=> "이동",
	"dellink"		=> "삭제",
	"comprlink"		=> "아카이브",
	"adminlink"		=> "관리자",
	"logoutlink"		=> "로그아웃",
	"uploadlink"		=> "업로드",
	"searchlink"		=> "검색",
	"extractlink"	=> "아카이브 추출",
	'chmodlink'		=> '(chmod) 권한(폴더/파일) 변경', // new mic
	'mossysinfolink'	=> 'eXtplorer 시스템 정보(eXtplorer, 서버, PHP, mySQL)', // new mic
	'logolink'		=> 'eXtplorer 웹사이트로 가기(새 창)', // new mic

	// list
	"nameheader"		=> "이름",
	"sizeheader"		=> "크기",
	"typeheader"		=> "유형",
	"modifheader"		=> "변경",
	"permheader"		=> "사용 권한",
	"actionheader"		=> "작업",
	"pathheader"		=> "경로",

	// buttons
	"btncancel"		=> "취소",
	"btnsave"		=> "저장",
	"btnchange"		=> "변경",
	"btnreset"		=> "초기화",
	"btnclose"		=> "닫기",
	"btncreate"		=> "작성",
	"btnsearch"		=> "검색",
	"btnupload"		=> "업로드",
	"btncopy"		=> "복사",
	"btnmove"		=> "이동",
	"btnlogin"		=> "로그인",
	"btnlogout"		=> "로그아웃",
	"btnadd"		=> "추가",
	"btnedit"		=> "편집",
	"btnremove"		=> "제거",
	
	// user messages, new in joomlaXplorer 1.3.0
	'renamelink'	=> '이름 바꾸기',
	'confirm_delete_file' => '이 파일을 삭제하시겠습니까? <br />%s',
	'success_delete_file' => '항목이 성공적으로 삭제되었습니다.',
	'success_rename_file' => '디렉터리/파일 %s의 이름을 %s(으)로 성공적으로 바꿨습니다.',
	
	// actions
	"actdir"		=> "디렉터리",
	"actperms"		=> "사용권한 변경",
	"actedit"		=> "파일 편집",
	"actsearchresults"	=> "결과 검색",
	"actcopyitems"		=> "항목 복사",
	"actcopyfrom"		=> "/%s에서 /%s(으)로 복사 ",
	"actmoveitems"		=> "항목 이동",
	"actmovefrom"		=> "/%s에서 /%s(으)로 이동 ",
	"actlogin"		=> "로그인",
	"actloginheader"	=> "로그인해서 eXtplorer를 사용",
	"actadmin"		=> "관리",
	"actchpwd"		=> "암호 변경",
	"actusers"		=> "사용자",
	"actarchive"		=> "항목 보관",
	"actupload"		=> "파일 업로드",

	// misc
	"miscitems"		=> "항목",
	"miscfree"		=> "자유",
	"miscusername"		=> "사용자 이름",
	"miscpassword"		=> "암호",
	"miscoldpass"		=> "이전 암호",
	"miscnewpass"		=> "새 암호",
	"miscconfpass"		=> "암호 확인",
	"miscconfnewpass"	=> "새 암호 확인",
	"miscchpass"		=> "암호 변경",
	"mischomedir"		=> "홈 디렉터리",
	"mischomeurl"		=> "홈 URL",
	"miscshowhidden"	=> "감춘 항목 표시",
	"mischidepattern"	=> "패턴 감춤",
	"miscperms"		=> "사용 권한",
	"miscuseritems"		=> "(이름, 홈 디렉터리, 감춘 항목 표시, 사용권한, 활성 상태)",
	"miscadduser"		=> "사용자 추가",
	"miscedituser"		=> "사용자 '%s' 편집",
	"miscactive"		=> "활성 상태",
	"misclang"		=> "언어",
	"miscnoresult"		=> "결과가 없습니다.",
	"miscsubdirs"		=> "하위 디렉터리 검색",
	"miscpermnames"		=> array("보기 전용","수정","암호 변경","수정 및 암호 변경",
					"관리자"),
	"miscyesno"		=> array("예","아니요","Y","N"),
	"miscchmod"		=> array("소유자", "그룹", "일반"),

	// from here all new by mic
	'miscowner'			=> '소유자',
	'miscownerdesc'		=> '<strong>설명:</strong><br />사용자(UID) /<br />그룹(GID)<br />현재의 권한:<br /><strong> %s ( %s ) </strong>/<br /><strong> %s ( %s )</strong>',

	// sysinfo (new by mic)
	'simamsysinfo'		=> "eXtplorer 시스템 정보",
	'sisysteminfo'		=> '시스템 정보',
	'sibuilton'			=> '운영체제',
	'sidbversion'		=> '데이터베이스 버전(MySQL)',
	'siphpversion'		=> 'PHP 버전',
	'siphpupdate'		=> '정보: <span style="color: red;">사용하는 PHP 버전은 <strong>실제</strong> 버전이 아닙니다!</span><br />Mambo와 추가 구성요소들의 모든 기능과 특징을<br />보장하려면, 최소한 <strong>PHP 버전 4.3을 사용해야 합니다</strong>!',
	'siwebserver'		=> '웹서버',
	'siwebsphpif'		=> '웹서버 - PHP 인터페이스',
	'simamboversion'	=> 'eXtplorer 버전',
	'siuseragent'		=> '브라우저 버전',
	'sirelevantsettings' => '중요 PHP 설정',
	'sisafemode'		=> '안전 모드',
	'sibasedir'			=> 'basedir 열기',
	'sidisplayerrors'	=> 'PHP 오류',
	'sishortopentags'	=> '짧은 열린 태그',
	'sifileuploads'		=> '파일 업로드',
	'simagicquotes'		=> '매직 쿼츠',
	'siregglobals'		=> '전역 변수 등록',
	'sioutputbuf'		=> '출력 버퍼',
	'sisesssavepath'	=> '세션 저장 경로',
	'sisessautostart'	=> '세션 자동 시작',
	'sixmlenabled'		=> 'XML 사용',
	'sizlibenabled'		=> 'ZLIB 사용',
	'sidisabledfuncs'	=> '사용 중지된 기능',
	'sieditor'			=> 'WYSIWYG 편집기',
	'siconfigfile'		=> '구성 파일',
	'siphpinfo'			=> 'PHP 정보',
	'siphpinformation'	=> 'PHP 정보',
	'sipermissions'		=> '사용 권한',
	'sidirperms'		=> '디렉터리 사용 권한',
	'sidirpermsmess'	=> 'eXtplorer의 모든 기능과 특징이 올바르게 작동하고 있는지 확인하려면 다음 폴더가 [chmod 0777] 쓰기 사용 권한을 갖고 있어야 합니다.',
	'sionoff'			=> array( '켬', '끔' ),
	
	'extract_warning' => "이 파일을 추출하시겠습니까? 여기에?<br />주의하여 사용하지 않을 경우 기존 파일을 덮어씁니다!",
	'extract_success' => "성공적으로 추출했습니다.",
	'extract_failure' => "추출하지 못했습니다.",
	
	'overwrite_files' => '기존 파일을 덮어쓰시겠습니까?',
	"viewlink"		=> "보기",
	"actview"		=> "파일 소스 표시",
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_chmod.php file
	'recurse_subdirs'	=> '하위 디렉터리로 재귀하시겠습니까?',
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to footer.php file
	'check_version'	=> '최신 버전 확인',
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_rename.php file
	'rename_file'	=>	'디렉터리 또는 파일 이름 바꾸기...',
	'newname'		=>	'새 이름',
	
	// added by Paulino Michelazzo (paulino@michelazzo.com.br) to fun_edit.php file
	'returndir'	=>	'저장 후 디렉터리로 돌아가시겠습니까?',
	'line'		=> 	'행',
	'column'	=>	'열',
	'wordwrap'	=>	'단어 잘림 방지: (IE만 해당)',
	'copyfile'	=>	'파일을 이 파일 이름으로 복사',
	
	// Bookmarks
	'quick_jump' => '빠른 이동',
	'already_bookmarked' => '이 디렉터리는 이미 즐겨찾기로 지정되었습니다.',
	'bookmark_was_added' => '이 디렉터리는 즐겨찾기 목록에 추가되었습니다.',
	'not_a_bookmark' => '이 디렉터리는 즐겨찾기가 아닙니다.',
	'bookmark_was_removed' => '이 디렉터리는 즐겨찾기 목록에서 제거되었습니다.',
	'bookmarkfile_not_writable' => "%s을(를) 즐겨찾기로 지정하지 못했습니다.\n 즐겨찾기 파일 '%s'은(는) \n쓸 수 없습니다.",
	
	'lbl_add_bookmark' => '이 디렉터리를 즐겨찾기로 추가',
	'lbl_remove_bookmark' => '이 디렉터리를 즐겨찾기 목록에서 제거',
	
	'enter_alias_name' => '이 즐겨찾기의 별칭을 입력하십시오.',
	
	'normal_compression' => '보통 압축',
	'good_compression' => '양호한 압축',
	'best_compression' => '최상의 압축',
	'no_compression' => '압축 안 함',
	
	'creating_archive' => '아카이브 파일 작성 중...',
	'processed_x_files' => '파일 %s / %s개를 처리했습니다.',
	
	'ftp_header' => '로컬 FTP 인증',
	'ftp_login_lbl' => 'FTP 서버의 로그인 자격 증명을 입력하십시오.',
	'ftp_login_name' => 'FTP 사용자 이름',
	'ftp_login_pass' => 'FTP 암호',
	'ftp_hostname_port' => 'FTP 서버 호스트 이름과 포트<br />(포트는 선택 사항)',
	'ftp_login_check' => 'FTP 연결 점검 중...',
	'ftp_connection_failed' => "FTP 서버에 연결할 수 없습니다. \nFTP 서버가 서버에서 동작하고 있는지 확인하십시오.",
	'ftp_login_failed' => "FTP 로그인을 하지 못했습니다. 사용자 이름과 암호를 확인하고 재시도하십시오.",
		
	'switch_file_mode' => '현재 모드: <strong>%s</strong>. %s 모드로 전환해야 합니다.',
	'symlink_target' => '기호화된 링크의 대상',
	
	"permchange"		=> "CHMOD 성공:",
	"savefile"		=> "파일이 저장되었습니다.",
	"moveitem"		=> "성공적으로 이동했습니다.",
	"copyitem"		=> "성공적으로 복사했습니다.",
	'archive_name' 	=> '아카이브 파일 이름',
	'archive_saveToDir' 	=> '아카이브를 이 디렉터리에 저장',
	
	'editor_simple'	=> '단순 편집기 모드',
	'editor_syntaxhighlight'	=> '구문 강조 표시 모드',

	'newlink'	=> '새 파일/디렉터리',
	'show_directories' => '디렉터리 표시',
	'actlogin_success' => '로그인에 성공했습니다!',
	'actlogin_failure' => '로그인하지 못했습니다. 재시도하십시오.',
	'directory_tree' => '디렉터리 트리',
	'browsing_directory' => '디렉터리 찾기',
	'filter_grid' => '필터',
	'paging_page' => '페이지',
	'paging_of_X' => '/ {0}',
	'paging_firstpage' => '첫 페이지',
	'paging_lastpage' => '끝 페이지',
	'paging_nextpage' => '다음 페이지',
	'paging_prevpage' => '이전 페이지',
	
	'paging_info' => '표시 항목 {0} - {1} / {2}',
	'paging_noitems' => '표시할 항목이 없습니다.',
	'aboutlink' => '정보...',
	'password_warning_title' => '중요 – 암호를 변경하십시오!',
	'password_warning_text' => '로그인한 사용자 계정(암호가 admin인 admin)은 eXtplorer의 기본 설정된 권한 계정입니다. eXtplorer 설치는 침입에 무방비 상태이므로 이 보안 결함을 즉시 수정해야 합니다!',
	'change_password_success' => '암호가 변경되었습니다!',
	'success' => '성공',
	'failure' => '실패',
	'dialog_title' => '웹사이트 대화',
	'upload_processing' => '업로드 처리 중. 기다리십시오...',
	'upload_completed' => '업로드 성공!',
	'acttransfer' => '다른 서버에서 전송',
	'transfer_processing' => '서버간 전송 처리 중. 기다리십시오...',
	'transfer_completed' => '전송 완료!',
	'max_file_size' => '최대 파일 크기',
	'max_post_size' => '최대 업로드 한계',
	'done' => '완료.',
	'permissions_processing' => '사용 권한 적용 중. 기다리십시오...',
	'archive_created' => '아카이브 파일이 작성되었습니다!',
	'save_processing' => '파일 저장 중...',
	'current_user' => '이 스크립트는 현재 다음 사용자의 사용 권한으로 실행됩니다:',
	'your_version' => '사용자 버전',
	'search_processing' => '검색 중. 기다리십시오...',
	'url_to_file' => '파일 URL',
	'file' => '파일',
	'create_title' => 'Create New Directory/File'
);
?>
