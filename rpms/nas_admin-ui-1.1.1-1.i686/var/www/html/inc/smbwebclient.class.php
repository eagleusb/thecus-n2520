<?
require_once('sqlitedb.class.php');
require_once('smbconf.class.php');
$SMBWEBCLIENT_VERSION = '2.0.14';

class smbwebclient extends samba{

	var $cfgAnonymous = 'off';
	var $cfgCachePath = '';
	var $cfgDefaultLanguage = 'en';
	var $cfgDefaultCharset = 'UTF-8';
	var $cfgDefaultServer = '127.0.0.1';
	var $cfgSmbClient = '/usr/bin/smbclient';
	var $cfgWbInfo = '/usr/bin/wbinfo';
	var $cfgAuthMode = 'SMB_AUTH_ENV';
	var $cfgBaseUrl = '';
	var $cfgHideDotFiles = 'on';
	var $cfgHideSystemShares = 'on';
	var $cfgInlineFiles = 'off';
	var $macros = array();
	var $sid;
	var $strings = array();
	var $local_special_user = array('root','admin','sshd','ftp','nobody');
    var $warning_num = 0; //enian 2008 12 30 check warning_num show one time 
	# Available 36 languages at
	# http://wwww.nivel0.net/SmbWebClientTranslation
	# Files are included using base64_encode PHP function

	var $inlineFiles = array (
		'data/languages.csv' => 1,
		'data/mime.types' => 1,
		'style/disk.png' => 1,
		'style/dotdot.png' => 1,
		'style/favicon.ico' => 1,
		'style/file.png' => 1,
		'style/folder.png' => 1,
		'style/logout.png' => 1,
		'style/page.thtml' => 1,
		'style/printer.png' => 1,
		'style/server.png' => 1,
		'style/view.thtml' => 1,
		'style/workgroup.png' => 1,
		'style/up.png' => 1,
		'style/down.png' => 1,
		'style/usrchpw.png' => 1,
	);
	
	var $nodie=0;
	
	function SDebug($val){
		if(file_exists("/tmp/abcd")){
			echo "Debug = ${val}<br>";
			exit;
		}
	}

	function check_username(){
		$check_name=($_SESSION["username"]!="")?trim($_SESSION["username"]):stripslashes(trim($_POST["username"]));
		$string_len=strlen($check_name);
		$Client_IP = $_SERVER['REMOTE_ADDR'];
		$error_username="0";
		if($string_len=="0"){
			$error_username="1";
		}else{
			for($c=0;$c<$string_len;$c++){
				$char=substr($check_name,$c,1);
				if(ord($char)==32 || ord($char)==47){
					$error_username="1";
					break;
				}
				if(ord($char)>=58 && ord($char)<=64){
					$error_username="1";
					break;
				}
				if(ord($char)>=91 && ord($char)<=93){
					$error_username="1";
					break;
				}
				if(ord($char)>=42 && ord($char)<=44){
					$error_username="1";
					break;
				}
			}
		}
		if($error_username=="1"){
			shell_exec("/img/bin/logevent/event 305 admin {$Client_IP} &");
			 $this->ReturnStatus(false,$this->strings['username_error']);   
		}
	}
	  

	function getWritePermission($username,$sharename,$raidname){
		system('grep \'^'.$username.':\' /etc/passwd > /dev/null 2>&1',$is_local);

		$user_info=posix_getpwnam($username);
		
		$grouplist=explode("\n",trim(shell_exec("/usr/bin/getent group|awk '/:".preg_quote($username)."/||/,".preg_quote($username)."/'")));
		$permission_pattern = '/(user:'.$username.':.w.)|(other::.w.)';
		foreach ($grouplist as $thegroup) {
			$groupinfo=explode(":",$thegroup);
			$groupuser=explode(",",$groupinfo[3]);
			//print_r($groupinfo);
			if (in_array($username, $groupuser)) {
				if(($user_info['uid'] >= 20000 && $groupinfo[2] >= 20000) ||
					($user_info['uid'] <= 19999 && $groupinfo[2] <= 19999))
					$permission_pattern .= '|(group:'.trim($groupinfo[0]).':.w.)';
			}
			//print_r($groupuser);
		}

		//Local User/Group有區分大小寫
		$permission_pattern .= ($is_local != 0) ? '/i':'/';
		//echo "permission_pattern=[".$permission_pattern."]-".$raidname."-".$sharename."<br>";
		$strExec="cat /etc/samba/smb.conf | awk '/path =/&&/\/${sharename}\/data/{print $3}'";
		$share_path=trim(shell_exec($strExec));
		//echo "share path = ${share_path}<br>";
		if($share_path==""){
			$strExec="cat /etc/samba/smb.conf | awk '/path =/&&/data\/${sharename}$/{print $3}'";
			$share_path=trim(shell_exec($strExec));
		}
		//$share_path="/${raidname}/data/${sharename}";
		//echo "share path = ${share_path}<br>";
		$strGetfacl="getfacl ".escapeshellarg($share_path)." 2>/dev/null | grep -v \"^default:\"";
		//echo "strGetfacl=[$strGetfacl]<br>";
		$_SESSION['permission'] = preg_match($permission_pattern,shell_exec($strGetfacl));
	}

	# constructor
	function smbwebclient ($nodie=0)
	{
	   global $session;
		// echo login.php
		$this->cfgBaseUrl=basename($_SERVER['SCRIPT_NAME']);
		if (isset($_GET['debug'])) {
			$_SESSION['DebugLevel'] = $_GET['debug'];
			unset($_GET['debug']);
		}
		if (isset($_GET['O'])) {
			$_SESSION['Order'] = $_GET['O'];
			unset($_GET['O']);
		}
		$this->debug = @$_SESSION['DebugLevel'];
		$this->order = @$_SESSION['Order'];
		$this->nodie = $nodie;

		# load MIME types
		/*
		foreach (explode("\n",$this->GetInlineFile('data/mime.types')) as $line) {
			$a = explode(" ", $line);
			$this->mimeTypes[$a[0]] = $a[1];
		}
		*/

		# your base URL ends with '/' ? I think you are using mod_rewrite
		$this->cfgModRewrite = $this->cfgBaseUrl[strlen($this->cfgBaseUrl)-1] == '/' ? 'on' : 'off';

		$this->strings = $session->PageCode("index");
		//$this->lang = $_SESSION['lang'];
	}

	function GetNetbiosName ()
	{
		//$host = shell_exec("wbinfo -I 127.0.0.1");
		$cmd=$this->cfgWbInfo." -I ".$this->cfgDefaultServer;
		$host = shell_exec($cmd);
		$host = preg_replace('/^[^\s]+\s+/','',trim($host));
		$host = trim($host);
		return $host;
	}

	function SetSingleAdmin($Client_IP){
		if($fp=fopen("/tmp/admin","w"))
			fputs($fp,$Client_IP);
		fclose($fp);
	}

	function GetSingleAdmin(){
		if($fp=fopen("/tmp/admin","r"))
			$current_admin=fgets($fp,20);
		fclose($fp);
		return $current_admin;
	}
	
	function getRaidName($path=''){
	  $tmp=$path;
          $tmp_array=explode("/",trim($tmp));
          $folder=$tmp_array[0];
          $smbconf=new SmbConf();
          $smbconf->setShare($folder);
          $full_path=$smbconf->getPath();
          $path_array=explode("/",trim($full_path));
          $raid_name=$path_array[1];
          return $raid_name;
	}
	
	function ReturnStatus($status=true,$errormsg=''){
	  if($status){
  	  $_SESSION['loginid'] = $session->loginid = $_POST['username'];  
  	  //$_SESSION['admin_auth'] = $session->admin_auth;  
  		$session->logged_in = 1;
  		//$session->setLogin(); 
  	}else{
  		unset($_SESSION["username"]);
  		unset($_SESSION["pwd"]);
 		//session_destroy(); 
  	} 
  	$msg = array('title'=>$this->strings['authError_title'],'msg'=>$errormsg);
  	
  	if ($this->nodie==1) {
			return $status;
	  } else {
			die(json_encode(array('success'=>$status,'errormsg'=>$msg)));
	  }
	}

	function Run ($path='')
	{ 
	   
	 $this->check_username();
		
	//echo "path = ${path}<br>";
	//===================================
	//	Find raid name
	//===================================
	$raid_name=$this->getRaidName($path);
	
		$this->where = $path = stripslashes($path);	
		$this->Go(ereg_replace('/$','',ereg_replace('^/','',$this->cfgDefaultServer.'/'.$path)));
		$this->GetCachedAuth($this->PrintablePath());
		if (isset($_REQUEST['action_method']) && method_exists($this, $_REQUEST['action_method'])) {
			$action = $_REQUEST['action_method'];
			//$this->$action ();
		}
		$this->Debug($path.' ('.$this->user.')',0);
 
		//Leon 2005/03/10
		$Client_IP = $_SERVER['REMOTE_ADDR'];
		
		//$_POST['username']='admin';
		//$_POST['pwd']='admin';
		if($_POST['username'] == 'admin'){
			$ret=trim(shell_exec('/usr/bin/auth root '.escapeshellarg($this->pw)));
		
			if($ret == 'AUTH: OK'){
			
			  $session->admin_pwd = $this->pw;
			  $session->admin_auth = 1;
/*
				//==================//
				//Single admin Login//
				//==================// 
			    if(file_exists("/tmp/admin")){
			        $expired =((time()-filectime("/tmp/admin"))>10*60)?true:false;
			        if(!$expired){//=======add by kido if not expired check admin
		                   $current_admin=$this->GetSingleAdmin();
    			    		if($current_admin!=$Client_IP){//===========admin not current user ==eject
    			    		    //error ::: Admin has already logged in
          						 $_SESSION['is_second_admin']=1;
          						shell_exec("/img/bin/logevent/event 001 {$Client_IP} &");
          						if ($this->nodie)
          							return $this->ReturnStatus(false,$this->strings['adminError_msg']);  
          						else
          							$this->ReturnStatus(false,$this->strings['adminError_msg']);  
        					}else{//=========admin is current user update admin
            						$this->SetSingleAdmin($Client_IP);
            						shell_exec("/img/bin/logevent/event 110 admin {$Client_IP} &");
        					} 
                                        }else{//==========expired so that update admin
          				$this->SetSingleAdmin($Client_IP);
          				shell_exec("/img/bin/logevent/event 110 admin {$Client_IP} &");
          	             	}
   			   }else{//===========first user login new admin info
        				$this->SetSingleAdmin($Client_IP);
        				shell_exec("/img/bin/logevent/event 110 admin {$Client_IP} &");
			     }
*/
        				$this->SetSingleAdmin($Client_IP);
        				shell_exec("/img/bin/logevent/event 110 admin {$Client_IP} &");
			     if ($this->nodie)
			    		return $this->ReturnStatus(true);
			     else
			     		$this->ReturnStatus(true);
			  }else{
			      //error ::: Invalid Password
                              shell_exec("/img/bin/logevent/event 305 admin {$Client_IP} &"); 
                              if ($this->nodie)
                              	return $this->ReturnStatus(false,$this->strings['authError_msg']);  
                              else
                              	$this->ReturnStatus(false,$this->strings['authError_msg']);  
			  }
			exit;
		} 
		  
		
		switch ($this->Browse()) {
			case '':
			//Leon 2005/02/22
			//Login Success
				$user_check = shell_exec("/usr/bin/getent passwd|grep '^{$_SESSION['username']}:' 2>&1");
				if($user_check == "" || trim($_SESSION['pwd']) == "" || in_array($_SESSION['username'],$this->local_special_user)){
					$this->CleanCachedAuth();
				 	shell_exec("/img/bin/logevent/event 305 ".escapeshellarg(stripslashes($_SESSION['username']))." {$Client_IP} &");
					if ($this->nodie)
				 		return $this->ReturnStatus(false,$this->strings['authError_msg']);  
				 	else
				 		$this->ReturnStatus(false,$this->strings['authError_msg']);  
				}
				$this->getWritePermission($this->user,$this->share,$raid_name);	
				shell_exec("/img/bin/logevent/event 110 ".escapeshellarg(stripslashes($_SESSION['username']))." {$Client_IP} &");
				break;
			case 'ACCESS_DENIED':
				$this->ErrorMessage($this->status);
				if ($this->nodie)
					return $this->ReturnStatus(false,$this->strings['authError_msg']);   
			 	else
					$this->ReturnStatus(false,$this->strings['authError_msg']);   
			case 'LOGON_FAILURE':
			//Leon 2005/02/22
			//if username,password not valid user, relogin (Authentication)
				$this->CleanCachedAuth();
				//shell_exec("/img/bin/logevent/event 305 ".escapeshellarg(stripslashes($_SESSION['username']))." {$Client_IP} &");
				$strExec="/img/bin/logevent/event 305 ".escapeshellarg(stripslashes($_SESSION['username']))." {$Client_IP} &";
				shell_exec($strExec);
				if ($this->nodie)
					return $this->ReturnStatus(false,$this->strings['authError_msg']);   
				else
					$this->ReturnStatus(false,$this->strings['authError_msg']);   
			default:
				$this->ErrorMessage($this->status);
				if ($this->nodie)
					return $this->ReturnStatus(false,$this->strings['authError_msg']);    
				else
					$this->ReturnStatus(false,$this->strings['authError_msg']);    
		} 
		if ($this->nodie)
			return $this->ReturnStatus(true);
		else 
			$this->ReturnStatus(true);
		/*
		if($this->site=="web_disk"){
			return $this->View ();
		}elseif($this->site=="photo_server"){
			//$photo_path="/usr/usrgetform.html?contant=/gallery/iframe_gallery.html";
			//$photo_path="/gallery/iframe_gallery.html";
			$photo_path="/gallery/index.html?contant=/gallery/iframe_gallery.html";
			header('Location: ' . $photo_path);
			exit;
			//echo "<pre>";
			//print_r($_REQUEST);
			//print_r($_SESSION);
			//exit;
		}*/
	}

	function DumpFile($file='', $name='', $isAttachment=0)
	{
		ob_end_clean();
		ob_implicit_flush(true);
		$name = rawurldecode($name);
		if ($name == '') $name = preg_replace("@^.*/@","",$file);
		$pi = pathinfo(strtolower($name));
		if (ereg('Opera(/| )([0-9].[0-9]{1,2})', $_SERVER['HTTP_USER_AGENT'])){
			$UserBrowser = "Opera";
			$name =  urlencode($name);
		}elseif(ereg('MSIE ([0-9].[0-9]{1,2})', $_SERVER['HTTP_USER_AGENT'])){
			$UserBrowser = "IE";
			$name =  urlencode($name);
			$name = str_replace("+", "%20", $name);
		}else{
			$UserBrowser = '';
		}
		$mimeType = ($UserBrowser == 'IE' || $UserBrowser == 'Opera') ? 'application/octetstream' : 'application/octet-stream';	
		
		header('Content-Type: ' . $mimeType);
		header('Content-Disposition: attachment; filename="'.$name.'"');
		header("Content-length: " . filesize($file));
		header('Accept-Ranges: bytes');
		header("Cache-control: private");
		header('Pragma: private');
		
		if ($isAttachment)
			header("Content-Disposition: attachment; filename=\"".$name."\"");
		else
			header("Content-Disposition: filename=\"".$name."\"");

		if ($file <> '' AND is_readable($file)) {
			set_time_limit(0);
			$fp = fopen($file, "r");
			while (! feof($fp)) {
				print fread($fp,40960);
			}
			fclose($fp);
		}
		ob_implicit_flush(false);
	}

	function GetInlineFile ($file)
	{
		$f = fopen($file, 'r');
		$data = fread ($f, filesize($file));
		fclose ($f);
//enian 2008 12 30 migrate exception		

		$check_raid_flag = check_raid_lock();
   	
   		if($check_raid_flag == 0 && $this->warning_num ==1)
   		{
   			$raid_data="
   									</div>\n
								</td>\n
							</tr>\n
							<tr> \n
   								<td hdight =\"17\" class =\"migrate_note\" style=\" text-align:center;\"> \n
   									<font class=\"migrate_note1\">".$this->strings["raid_migrate_message"]."</font>
   					    		</td>	\n
   							</tr> \n
   					  		<tr> \n
   					    		<td valign=\"top\"> \n
                				<div class=\"block_06\"> \n
    						";    	
   		}			
   		$this->warning_num ++;
	  	$data = $raid_data . $data;
//end enian 2008 12 30	  
		return $data;
	}

	# debugging messages
	function Debug ($message, $level=1)
	{
		if ($level <= $this->debug) {
			foreach (explode("\n",$message) as $line) syslog(LOG_INFO, $line);
		}
	}

	# HTML page
	function Page ($title='', $content='')
	{
		if (@$_SESSION['ErrorMessage'] <> '') {
			$content .= "\n<script language=\"Javascript\">alert(\"{$_SESSION['ErrorMessage']}\")</script>\n";
			$_SESSION['ErrorMessage'] = '';
		}
		return $this->Template('style/page.thtml', array('{title}' => $title,'{content}' => $content,'{style}' => $this->GetUrl('style/'),'{favicon}' => $this->GetUrl('style/favicon.ico')));
	}

	# loads an HTML template
	function Template ($file, $vars=array())
	{
		return str_replace(array_keys($vars), array_values($vars), $this->GetInlineFile($file));
	}

	# HTML a href
	function Link ($title, $url='', $name='')
	{
		if ($name <> '') $name = "name = \"{$name}\"";
		return ($url == '') ? $title : "<a href=\"{$url}\" {$name}>{$title}</a>";
	}

	# HTML img
	function Image ($url, $alt='', $extra='')
	{
		return ($url == '') ? $title : "<img src=\"{$url}\" alt=\"{$alt}\" border=\"0\" {$extra}>";
	}

	# HTML select (combo)
	function Select ($name, $value, $options)
	{
		$html = "<select name=\"{$name}\">\n";
		foreach ($options as $key => $description) {
			$selected = ($key == $value) ? "selected" : "";
			$html .= "<option value=\"{$key}\" $selected>{$description}</option>\n";
		}
		$html .= "</select>\n";
		return $html;
	}

	# HTML cross buttons
	function CrossButtons ($buttons)
	{
		$html = "";
		foreach ($buttons as $onclick => $desc) {
			$button = "<input type=\"button\" value=\"{$desc}\" id =\"{$desc}\" onClick=\"javascript:set_action('{$onclick}');this.form.submit();\">\n";
			$html .= $button;			
		}
		$html .= "<input type=\"hidden\" name=\"action_method\" value=\"\">\n";
//enian 2008 12 30 migrate exception		
		$migrate_check = check_raid_lock();
		if($migrate_check == 0)
		{
			$html .= "<script language=\"javascript\">";
			foreach ($buttons as $onclick => $desc) {
				if($desc != "Up")
				{
					$button_script = "document.getElementById('".$desc."').disabled = true;\n";
					$html .= $button_script;								
				}
		  	}		      
      		$html .="</script>";
		}
		
		return $html;
	}

	# HTML check box
	function CheckBox ($name, $value, $checked = false)
	{
		return $this->Input($name, $value, 'checkbox', $checked ? "checked" : "");
	}

	function Input ($name, $value, $type = 'text', $extra='')
	{
		return "<input type=\"{$type}\" id=\"{$name}\" name=\"{$name}\" value=\"".htmlentities($value, ENT_COMPAT,$this->cfgDefaultCharset)."\" {$extra}>\n";
	}

	# basic auth
	function GetAuth ($path="")
	{
		//Leon 2005/03/10
		if(!isset($_SESSION['username']) || (isset($_SESSION['username']) && isset($_POST['username']))){
			$_SESSION['username'] = $_POST['username'];
			$passwd = $_POST['pwd'];
			$passwd = str_replace("\\\\","\t",$passwd);
        		$passwd = str_replace("\\","",$passwd);
        		$passwd = str_replace("\t","\\",$passwd);
			$_SESSION['pwd'] = $passwd;
			$_SESSION['site'] = $_POST['site'];
		}

		$this->user = stripslashes($_SESSION['username']) ;
		$this->pw = $_SESSION['pwd'];
		$this->site = $_SESSION['site'];
	}

	# return an URL (adding a param)
	function GetUrl ($path='', $arg='', $val='')
	{
		$get = $_GET;
		$get['path'] = $path;

		# delete switches from URL
		$get['debug'] = $get['lang'] = $get['auth'] = '';

		if ($arg <> '') {
			if (! is_array($arg)) $get[$arg] = $val;
			else foreach ($arg as $key=>$value) $get[$key] = $value;
		}

		# build query string
		$query = array();
		foreach ($get as $key=>$value) if ($value <> '') {
			if ($this->cfgModRewrite <> 'on' OR $key <> 'path')
				$query[] = urlencode($key).'='.urlencode($value);
		}
		if (($query = join('&',$query)) <> '') $query = '?'.$query;

		$paste = ($this->cfgModRewrite == 'on') ? str_replace('%2F','/',urlencode($get['path'])) : '';
		return $this->cfgBaseUrl.$paste.$query;
	}

	function ErrorMessage ($msg)
	{
		$_SESSION['ErrorMessage'] = @$_SESSION['ErrorMessage'] . $msg;
	}

	function CleanCachedAuth ()
	{
		$mode = $this->type;
		@$_SESSION['CachedAuth'][$mode][$this->$mode] = '';
	}

	////NETWORK/WORKGROUP/SERVER/SHARE
	function GetCachedAuth ($path)
	{
	
		$this->user = $this->pw = '';
		$nextLevel = array('network'=>'','server'=>'network','share'=>'server');
		if (@$_SESSION['AuthSubmit'] == 'yes') {
			# store auth in cache
			$_SESSION['AuthSubmit'] = 'no';
			$mode = $this->type;
			$this->user = stripslashes($_SESSION['username']);
			$this->pw = stripslashes($_SESSION['pwd']);
			$_SESSION['CachedAuth'][$mode][$this->$mode]['User'] = $this->user;
			$_SESSION['CachedAuth'][$mode][$this->$mode]['Password'] = $this->pw;
			for ($mode = $nextLevel[$mode]; $mode <> ''; $mode = $nextLevel[$mode]) {
				if (! isset($_SESSION['CachedAuth'][$mode][$this->$mode])) {
					$_SESSION['CachedAuth'][$mode][$this->$mode]['User'] = $this->user;
					$_SESSION['CachedAuth'][$mode][$this->$mode]['Password'] = $this->pw;
				}
			}
		} elseif (@$_GET['auth'] <> 1) {
			# get auth from cache
			for ($mode = $this->type; $mode <> ''; $mode = $nextLevel[$mode]) {
				if (isset($_SESSION['CachedAuth'][$mode][$this->$mode])) {
					$this->user = $_SESSION['CachedAuth'][$mode][$this->$mode]['User'];
					$this->pw = $_SESSION['CachedAuth'][$mode][$this->$mode]['Password'];
					break;
				}
			}
			if ($this->user == '') $this->GetAuth($path);
		} else $this->GetAuth($path);
	}

	function View ()
	{
		global $macros;
		$selected = (is_array(@$_POST['selected'])) ? $_POST['selected'] : array();
		switch ($this->type) {
			case 'file':
				$localf=$this->getLocalShare ($this->where);
				$this->DumpFile ($localf);
				exit;
			case 'network':
			case 'workgroup':
			case 'server':
				$headers = array ('name_title' => 'N', 'comment_title' => 'C');
				break;
			case 'printer':
				$headers = array ('name_title' => 'N', 'size_title' => 'S');
				break;
			default:
				$headers = ($_SESSION['isadmin']==1)? array ('name_title' => 'N', 'size_title' => 'S', 'acl' => 'A', 'type_title' => 'T', 'modify_title' => 'D'):array ('name_title' => 'N', 'size_title' => 'S', 'type_title' => 'T', 'modify_title' => 'D');
		}

		$header = '<tr><th style="border: 1/2px inset;" class="checkbox"><input type="checkbox" name="chkall" onclick="javascript:sel_all(this)"></th>';
		$icons = array ('A' => 'up', 'D' => 'down');
		foreach ($headers as $title => $order) {
			if ($this->order[0] == $order) {
				$ad = ($this->order[1] == 'A') ? 'D' : 'A';
				$icon = $this->Icon($icons[$ad]);
				$style[$title] = 'class="order-by"';
			} else {
				$ad = 'A';
				$icon = '';
				$style[$title] = '';
			}
			$url = $this->GetUrl($this->where, 'O', $order.$ad);
			$header .= "<th style='border: 1/2px inset;text-align:center;' class='toolbar'>".$this->Link($this->strings[$title],$url).' '.$icon."</th>";
		}
		$lang = "<a href='/usr/usrgetform.html?name=lang'>".strtoupper($this->lang)."</a>";
		$time = date("H:i");
		$usrchpw = $this->Icon('usrchpw','/usr/usrgetform.html?name=usrchpw');
		$logout = $this->Icon('logout',
			  "javascript:if(confirm('".$this->strings["logout_confirm"]."')) window.open('/usr/logout.html','_top')");
		//Leon 2005/5/9
		if(!isset($_SESSION['uid'])){
			$user_info = posix_getpwnam($this->user);
			$_SESSION['uid'] = $user_info['uid'];
		}
		$this->uid = $_SESSION['uid'];
		$header .= $this->uid >= 20000 ? "":"<th style=\"border: 1/2px inset;\" class=\"toolbar\"><nobr>{$usrchpw}</nobr></th>";
		$header .= "<th style='border: 1/2px inset;' class=\"toolbar\"><nobr>{$logout}</nobr></th></tr>";

		$lines = $this->ViewForm ($this->type, $style, $headers);
		foreach ($this->results as $file => $data) {
			if ($this->cfgHideDotFiles == 'on' AND $file[0] == '.') continue;
			if ($data['type']=='file' OR $data['type']=='printjob') {
				$size = $this->PrintableBytes($data['size']);
				$pi = pathinfo(strtolower($file));
				$mimeType = @$this->mimeTypes[@$pi['extension']];
				if ($mimeType == '') $mimeType = 'application/octet-stream';
				$type = sprintf($this->strings["file_format"], strtoupper($pi['extension']));
			} else {
				$size = '';
				$type = $this->strings["mkdir_prompt"];
			}
			$modified = date("m/d/Y H:i", @$data['time']);
			$check = $this->CheckBox("selected[]", ($data['type'] <> 'printjob') ? $file : $data['id'], in_array($file, $selected));
			$icon = $this->Icon($data['type']);
			$comment = @$data['comment'];

			//For ACL==start==!!
			if($_SESSION['isadmin']==1) {
					$aclPath=$this->FromPath($file);
					$apattern=$this->cfgBaseUrl."?path=";
					$aclPath=str_replace($apattern,'',$aclPath);
					$aclPath=urldecode($aclPath);
					preg_match('@^([^/]*)(.*)$@',$aclPath,$aclMatch);
					$iapShare=urlencode($aclMatch[1]);
					$iapPath=urlencode(substr($aclMatch[2],1));
			}
			//For ACL==end==!!


			if ($data['type'] <> 'printjob') {
			$file_name=mb_abbreviation(htmlentities($file, ENT_COMPAT,$this->cfgDefaultCharset),20,1,7);
			$file = $this->Link("<span name='filename' id='filename' icon='{$icon}'>".$file_name."</span>", $this->FromPath($file));
			}
			$lines .= "<tr>".
				"<td class=\"checkbox\" style=\"border: 1/2px inset;\">{$check}</td>".
				"<td style=\"border: 1/2px inset;\" {$style['name_title']}><nobr>{$icon} {$file}</nobr></td>".
				(isset($headers['size_title']) ? "<td style=\"border: 1/2px inset;\" {$style['size_title']} align=\"right\"><nobr>&nbsp;{$size}</nobr></td>" : "").
				((isset($headers['acl']) && $_SESSION['isadmin']==1) ? "<td style=\"border: 1/2px inset;\" {$style['acl']}>&nbsp;<input type='button' value='ACL' onClick='javascript:window.open(\"/adm/acl.htm?share=$iapShare&path=$iapPath\",\"ACL\",\"width=640,height=480,left=325,top=300,toolbar=no,location=no,status=no,menubar=no,scrollbars=yes,resizable=yes\")'></td>" : "").////hubert_huang@thecus.com///////
				(isset($headers['type_title']) ? "<td style=\"border: 1/2px inset;\" {$style['type_title']} align=\"right\"><nobr>&nbsp;{$type}</nobr></td>" : "").
				(isset($headers['comment_title']) ? "<td style=\"border: 1/2px inset;\" {$style['comment_title']} align=\"right\"><nobr>&nbsp;{$comment}</nobr></td>" : "").
				(isset($headers['modify_title']) ? "<td style=\"border: 1/2px inset;\" {$style['modify_title']}><nobr>{$modified}</nobr></td>" : "").
				"<td style=\"border: 1/2px inset;\" width=\"100%\" colspan=\"3\">&nbsp;</td>".
				"</tr>\n";
		}

		$macros['{action}'] = $this->GetUrl($this->where);
		$macros['{ok}'] = $this->strings["ok"];
		$macros['{header}'] = $header;
		$macros['{lines}'] = $lines;
		$macros['{file_error}'] = $this->strings["file_name_error"];
		$macros['{folder_error}'] = $this->strings["folder_name_error"];
		$macros['{duplicate_name}'] = $this->strings["duplicate_name"];
		$macros['{folder_exist}'] = $this->strings["folder_exist"];
		$macros['{file_exist}'] = $this->strings["file_exist"];

		//print $this->Page($this->name, $this->Template("style/view.thtml", $macros));
		return $this->Page($this->name, $this->Template("style/view.thtml", $macros));
	}

	//Hubert and below
	function relativeRoot ()
	{
		$str=trim($_SERVER['SCRIPT_FILENAME']);
		$rp=count(explode('/',$str))-1;
		$strr="";
		for($i=0;$i<$rp;$i++) {
			$strr.="../";
		}
		$strr=rtrim($strr,'/');
		return $strr;
	}

	function getLocalShare ($path)
	{
		//print $path;print "\n<br>\n";
		preg_match('@(^[^/]+)/(.*)$@',$path,$matches);
		$a=array();
		$share=$matches[1];
		$SmbConf=new SmbConf();
		$SmbConf->setShare($share);
		$a=$SmbConf->getPath()."/".$matches[2];
		return $a;
	}
	//Hubert and above

	function ViewForm ($type, $style, $headers)
	{
		$icon = $this->Icon('dotdot');
		$amenu = array();
		$html = $widget = '';
		if ($this->where <> '') $amenu['UpAction'] = $this->strings["up"];
		switch ($type) {
			case 'network':
			case 'server':
				break;
			case 'printer':
				switch (@$_REQUEST['action_method']) {
					case 'PrintFileInput':
						$amenu = array();
						$icon = $this->Icon('file');
						$widget = $this->Input("action_method", "PrintFileAction", "hidden").
								      $this->Input("file","", "file").
								      $this->Input('ok', $this->strings["ok"], 'submit');
						break;
					default:
						$amenu['PrintFileInput'] = $this->strings["print_title"];
						$amenu['CancelSelectedAction'] = $this->strings["cancel_job"];
				}
				break;
			case 'share':
				if($_SESSION['permission']){
					switch (@$_REQUEST['action_method']) {
						case 'NewFolderInput':
							$amenu = array();
							$icon = $this->Icon('folder');
							$widget = $this->Input("action_method", "NewFolderAction", "hidden").
							$this->Input("up",$this->strings["up"],"button","onclick=\"location.href='".$this->GetUrl($this->where)."'\"").
						      	$this->Input("folder","","maxLength=\"255\"").
						      	$this->Input('ok', $this->strings["ok"], 'button','onClick="checkFolder()"');
							break;
						case 'NewFileInput':
							global $sid;
							list($usec, $sec) = explode(' ', microtime());
							srand((float) $sec + ((float) $usec * 100000));
							$sid = urlencode(uniqid(rand()));
							$amenu = array();
							$icon = $this->Icon('file');
							$widget = $this->Input("action_method", "NewFileAction", "hidden").
							$this->Input("sessionid",$sid, "hidden").
							$this->Input("file_name","", "hidden").
							$this->Input("path_name",$_REQUEST['path'], "hidden").
							$this->Input("up",$this->strings["up"],"button","onclick=\"location.href='".$this->GetUrl($this->where)."'\"").
							//$this->Input("file","", "file","onkeypress=\"return goback(event);\"").
							$this->Input("file","", "file").
							//$this->Input('ok', $this->strings["ok"],'button',"onclick=\"upload();\"");
							$this->Input('ok', $this->strings["ok"],'submit');
							$widget .= "<font color='#FF0000'>&nbsp;(".$this->strings["file_size_limit"].")</font>";
							break;
						default:
							$amenu['NewFolderInput'] = $this->strings["mkdir_title"];
							$amenu['NewFileInput'] = $this->strings["upload_title"];
							$amenu['DeleteSelectedAction'] = $this->strings["delete_prompt"];
					}
				}
				break;

			default: print $type;
		}
		if (count($amenu)) {
			$widget = $this->CrossButtons($amenu);
		}

		if ($widget <> '') {
			$html .= "<tr>".
			"<td style=\"border: 1/2px inset;\">&nbsp;</td>".
			"<td style=\"border: 1/2px inset;\" colspan='6' {$style['name_title']}><nobr>{$icon} {$widget}</nobr></td>".
			"</tr>\n";
		}
		return $html;
	}

	function UpAction ()
	{
		header('Location: '.$this->FromPath('..'));
		exit;
	}

	function SendMessageAction ()
	{
		if (trim($_POST['message']) <> '' AND is_array($_POST['selected'])) {
			foreach ($_POST['selected'] as $server) {
				$this->SendMessage($server, $_POST['message']);
				$this->Debug('message to "'.$server.'" ('.$this->user.')',0);
			}
		}
		if ($this->status <> '') $this->ErrorMessage($this->status);
		header('Location: '.$this->FromPath('.'));
		exit;
	}

	function NewFolderAction ()
	{
		umask(0);
		$user_info=posix_getpwnam($this->user);
		$raidname=$this->getRaidName($this->share);
		
		$strExec="cat /etc/samba/smb.conf | awk '/path =/&&/\/{$this->share}\/data/{print $3}'";
		$file_path=trim(shell_exec($strExec));
		if($file_path==""){
			$strExec="cat /etc/samba/smb.conf | awk '/path =/&&/data\/{$this->share}/{print $3}'";
			$file_path=trim(shell_exec($strExec));
		}
		
		//$file_path = "/$raidname/data/{$this->share}/".(trim($this->path)=="" ? "":"{$this->path}/");
		$file_path = "${file_path}/".(trim($this->path)=="" ? "":"{$this->path}/");
		echo "file path = ${file_path}<br>";
		$flag = false;
		$strExec='ls '.escapeshellarg($file_path);
		$folder = explode("\n",shell_exec($strExec));
		for($i=0;$i<count($folder);$i++){
			if(eregi("^(". preg_quote($_POST['folder'],'/') .")$",$folder[$i])){
				$flag = true;
				break;
			}
		}
		if(!$flag){
			if($_SESSION['permission']){
				$folder_path=$file_path.$_POST['folder'];
				$strExec="mkdir ".escapeshellarg($folder_path);
				shell_exec($strExec);
				$strExec="chown {$this->user}:".$user_info['gid']." ".escapeshellarg(${folder_path});
				shell_exec($strExec);
			}
		}
		header('Location: '.$this->FromPath('.'));
		exit;
	}

	function DeleteSelectedAction ()
	{
	$raidname=$this->getRaidName($this->share);
	$strExec="cat /etc/samba/smb.conf | awk '/path =/&&/\/{$this->share}\/data/{print $3}'";
	$file_path=trim(shell_exec($strExec));
	if($file_path==""){
		$strExec="cat /etc/samba/smb.conf | awk '/path =/&&/data\/{$this->share}/{print $3}'";
		$file_path=trim(shell_exec($strExec));
	}
        //$file_path = "/$raidname/data/{$this->share}/".(trim($this->path)=="" ? "":"{$this->path}/");
        $file_path = "${file_path}/".(trim($this->path)=="" ? "":"{$this->path}/");
		if (is_array(@$_POST['selected']) && $_SESSION['permission']) {
			foreach ($_POST['selected'] as $file) {
				$file_name = $file_path.str_replace("\\","",$file);
				shell_exec("rm -rf ".escapeshellarg($file_name));
			}
		}
		header('Location: '.$this->FromPath('.'));
		exit;
	}

	function PrintFileAction ()
	{
		if ($_FILES['file']['tmp_name'] <> '') {
			$this->PrintFile($_FILES['file']['tmp_name']);
			$this->Debug('print ('.$this->user.')',0);
		}
		if ($this->status <> '') $this->ErrorMessage($this->status);
		header('Location: '.$this->FromPath('.'));
		exit;
	}

	function CancelSelectedAction ()
	{
		$status = '';
		if (is_array($_POST['selected'])) {
			foreach ($_POST['selected'] as $job) {
				$this->CancelPrintJob($job);
				$this->Debug('cancel print job #'.$job.' ('.$this->user.')',0);
				if ($this->status <> '') $status = $this->status;
			}
		}
		if ($status <> '') $this->ErrorMessage($status);
		header('Location: '.$this->FromPath('.'));
		exit;
	}

	# print KB
	function PrintableBytes ($bytes)
	{
		if ($bytes < 1024)
			return "0 KB";
		elseif ($bytes < 10*1024*1024)
			return number_format($bytes / 1024,0) . " KB";
		elseif ($bytes < 1024*1024*1024)
			return number_format($bytes / (1024 * 1024),0) . " MB";
		else
			return number_format($bytes / (1024*1024*1024),0) . " GB";
	}

	function PrintablePath ()
	{
		switch ($this->type) {
			case 'network':    return $this->strings["windows_network"];
			case 'workgroup':  return $this->workgroup;
			case 'server':     return '\\\\'.$this->server;
			case 'share':
				$pp = '\\\\'.$this->server.'\\'.$this->share;
				if ($this->where <> '') {
					$pp .= '\\'.str_replace('/','\\',$this->where);
				}
				return $pp;
		}
	}

	function Icon ($icon, $url='')
	{
		$image = $this->Image("style/{$icon}.png",'','align="absmiddle"');
		return ($url <> '') ? $this->Link($image, $url) : $image;
	}

	# builds a new path from current and a relative path
	function FromPath ($relative='')
	{
		switch ($relative) {
			case '.':
			case '':    $path = $this->where; break;
			case '..':  $path = $this->_DirectoryName($this->where); break;
			default:    $path = ereg_replace('^/', '', $this->where.'/'.$relative);
		}
		return $this->GetUrl($path);
	}
}

###################################################################
# SAMBA CLASS - calling smbclient
###################################################################

class samba {

	var $cfgSmbClient = '/usr/bin/smbclient';
	var $user='', $pw='', $cfgAuthMode='';
	var $cfgDefaultServer='127.0.0.1', $cfgDefaultUser='', $cfgDefaultPassword='';
	var $types = array ('network', 'server', 'share');
	var $type = 'network';
	var $network = 'Windows Network';
	var $workgroup='', $server='', $share='', $path='';
	var $name = '';
	var $workgroups=array(), $servers=array(), $shares=array(), $files=array();
	var $cfgCachePath = '';
	var $cached = false;
	var $tempFile = '';
	var $debug = false;
	var $socketOptions = 'TCP_NODELAY IPTOS_LOWDELAY SO_KEEPALIVE SO_RCVBUF=8192 SO_SNDBUF=8192';
	var $blockSize = 1200;
	var $order = 'NA';
	var $status = '';
	var $parser = array(
	"^added interface ip=([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}) bcast=([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}) nmask=([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})\$" => 'SKIP',
	"Anonymous login successful" => 'SKIP',
	"^Domain=\[(.*)\] OS=\[(.*)\] Server=\[(.*)\]\$" => 'SKIP',
	"^\tSharename[ ]+Type[ ]+Comment\$" => 'SHARES_MODE',
	"^\t---------[ ]+----[ ]+-------\$" => 'SKIP',
	"^\tServer   [ ]+Comment\$" => 'SERVERS_MODE',
	"^\t---------[ ]+-------\$" => 'SKIP',
	"^\tWorkgroup[ ]+Master\$" => 'WORKGROUPS_MODE',
	"^\t(.*)[ ]+(Disk|IPC)[ ]+IPC.*\$" => 'SKIP',
	"^\tIPC\\\$(.*)[ ]+IPC" => 'SKIP',
	"^\t(.*)[ ]+(Disk|Printer)[ ]+(.*)\$" => 'SHARES',
	'([0-9]+) blocks of size ([0-9]+)\. ([0-9]+) blocks available' => 'SIZE',
	"Got a positive name query response from ([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})" => 'SKIP',
	"^session setup failed: (.*)\$" => 'LOGON_FAILURE',
	'^tree connect failed: ERRSRV - ERRbadpw' => 'LOGON_FAILURE',
	"^Error returning browse list: (.*)\$" => 'ERROR',
	"^tree connect failed: (.*)\$" => 'ERROR',
	"^Connection to .* failed\$" => 'CONNECTION_FAILED',
	'^NT_STATUS_INVALID_PARAMETER' => 'INVALID_PARAMETER',
	'^NT_STATUS_DIRECTORY_NOT_EMPTY removing' => 'DIRECTORY_NOT_EMPTY',
	'^NT_STATUS_OBJECT_PATH_NOT_FOUND removing remote directory' => 'DIRECTORY_NOT_EMPTY',
	'ERRDOS - ERRbadpath \(Directory invalid.\)' => 'NOT_A_DIRECTORY',
	'NT_STATUS_NOT_A_DIRECTORY' => 'NOT_A_DIRECTORY',
	'^NT_STATUS_NO_SUCH_FILE listing ' => 'NO_SUCH_FILE',
	'^NT_STATUS_ACCESS_DENIED' => 'ACCESS_DENIED',
	'.*NT_STATUS_ACCESS_DENIED' => 'ACCESS_DENIED',
	'^NT_STATUS_NETWORK_ACCESS_DENIED' => 'ACCESS_DENIED',
	'^cd (.*): NT_STATUS_OBJECT_PATH_NOT_FOUND' => 'OBJECT_PATH_NOT_FOUND',
	'^cd (.*): not a directory' => 'OBJECT_PATH_NOT_FOUND',
	'^cd (.*): NT_STATUS_OBJECT_NAME_NOT_FOUND' => 'OBJECT_NAME_NOT_FOUND',
	"^\t(.*)\$" => 'SERVERS_OR_WORKGROUPS',
	"^([0-9]+)[ ]+([0-9]+)[ ]+(.*)\$" => 'PRINT_JOBS',
	"^Job ([0-9]+) cancelled" => 'JOB_CANCELLED',
	'^[ ]+(.*)[ ]+([0-9]+)[ ]+(Mon|Tue|Wed|Thu|Fri|Sat|Sun)[ ](Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[ ]+([0-9]+)[ ]+([0-9]{2}:[0-9]{2}:[0-9]{2})[ ]([0-9]{4})$' => 'FILES',
	"^message start: ERRSRV - ERRmsgoff" => 'NOT_RECEIVING_MESSAGES',
	"^NT_STATUS_CANNOT_DELETE" => 'CANNOT_DELETE'
	);

	function samba ($path='')
	{
		if ($path <> '') $this->Go ($path);
		print $path;
	}

	//將path拆解成：share名稱、server名稱、path路徑、name檔案名稱、parent上層目錄、type型態、fullPath完整分享路徑名稱
	function Go ($path = '')
	{
		$a = ($path <> '') ? explode('/',$path) : array();
		for ($i=0, $ap=array(); $i<count($a); $i++)
		switch ($i) {
			case 0: $this->server = $a[$i]; break;
			case 1: $this->share = $a[$i]; break;
			default: $ap[] = $a[$i];
		}
		$this->path = join('/', $ap);
		$this->type = $this->types[(count($a) > 2) ? 2 : count($a)];
		$this->name = preg_replace("@^.*/@","",$path);
		$this->parent = $this->_DirectoryName($this->path);
		$this->fullPath = $path;
	}

	function Browse ($order='NA')
	{
		$this->results = array();
		$this->shares = $this->servers = $this->workgroups = $this->files = $this->printjobs = array();
		$server = ($this->server == '') ? $this->cfgDefaultServer : $this->server;
		# smbclient call
		switch ($this->type) {
			case 'share':
				$this->_SmbClient('dir', $this->path);
				switch ($this->status) {
					case 'NO_SUCH_FILE':
						$this->_SmbClient('queue', $this->path);
						$this->type = 'printer';
						break;
					case 'OBJECT_PATH_NOT_FOUND':
					case 'NOT_A_DIRECTORY': $this->_Get ();
				}
				break;
			default: 
				$this->_SmbClient('', $server);
		}
		# fix a smbclient bug (i think)
		if (! isset($this->servers[$server]))
			$this->servers[$server] = array ('name'=>$server, 'type'=>'server', 'comment'=>'');
		# sort and select results
		$results = array (
			'network' => 'workgroups', 'workgroup' => 'servers',
			'server' => 'shares', 'share' => 'files', 'folder' => 'files',
			'printer' => 'printjobs'
		);
		if (isset($results[$this->type])) {
			$this->results = $this->$results[$this->type];
			# we need a global var for the compare function
			$GLOBALS['SMBWEBCLIENT_SORT_BY'] = ($this->order <> '') ? $this->order : 'NA';
			uasort($this->results, array('samba', '_GreaterThan'));
		} 
		return $this->status;
	}

	function PrintFile ($file)
	{
		$this->_SmbClient('print '.$file);
	}

	function CancelPrintJob ($job)
	{
		$this->_SmbClient('cancel '.$job);
	}

	function _GreaterThan ($a, $b)
	{
		global $SMBWEBCLIENT_SORT_BY;
		list ($yes, $no) = ($SMBWEBCLIENT_SORT_BY[1] == 'D') ? array(-1,1) : array (1,-1);
		if ($a['type'] <> $b['type']) {
			return ($a['type'] == 'file') ? $yes : $no;
		} else {
			switch ($SMBWEBCLIENT_SORT_BY[0]) {
				case 'N': return (strtolower($a['name']) > strtolower($b['name'])) ? $yes : $no;
				case 'D': return (@$a['time'] > @$b['time']) ? $yes : $no;
				case 'S': return (@$a['size'] > @$b['size']) ? $yes : $no;
				case 'C': return (strtolower(@$a['comment']) > strtolower(@$b['comment'])) ? $yes : $no;
				case 'T':
					$pia = pathinfo(strtolower($a['name']));
					$pib = pathinfo(strtolower($b['name']));
					return (@$pia['extension'] > @$pib['extension']) ? $yes : $no;
			}
		}
	}

	function _MasterOf ($workgroup)
	{
		$saved = array ($this->type, $this->user, $this->pw);
		if ($this->cfgDefaultUser <> '') {
			list ($this->user, $this->pw) = array ($this->cfgDefaultUser, $this->cfgDefaultPassword);
		}
		$this->type = 'network';
		$this->_SmbClient('', $this->cfgDefaultServer);
		list ($this->type, $this->user, $this->pw) = $saved;
		return $this->workgroups[$this->workgroup]['comment'];
	}

	# get a file (including a cache)
	function _Get ()
	{
		$this->_SmbClient('dir "'.$this->name.'"', $this->parent);
		if ($this->status == '') {
			$this->type = 'file';
			$this->size = $this->files[$this->name]['size'];
			$this->time = $this->files[$this->name]['time'];
			if ($this->cfgCachePath == '') {
				$this->tempFile = "";
				$getFile = true;
			} else {
				$this->tempFile = $this->cfgCachePath . $this->fullPath;
				$getFile = filemtime($this->tempFile) < $this->time OR !file_exists($this->tempFile);
				if ($getFile AND ! is_dir($this->_DirectoryName($this->tempFile)))
					$this->_MakeDirectoryRecursively($this->_DirectoryName($this->tempFile));
			}
			$this->cached = ! $getFile;
		}
	}

	# get a file (including a cache)
	function _Old_Get ()
	{
		$this->_SmbClient('dir "'.$this->name.'"', $this->parent);
		if ($this->status == '') {
			$this->type = 'file';
			$this->size = $this->files[$this->name]['size'];
			$this->time = $this->files[$this->name]['time'];
			if ($this->cfgCachePath == '') {
				$this->tempFile = tempnam('/tmp','swc');
				$getFile = true;
			} else {
				$this->tempFile = $this->cfgCachePath . $this->fullPath;
				$getFile = filemtime($this->tempFile) < $this->time OR !file_exists($this->tempFile);
				if ($getFile AND ! is_dir($this->_DirectoryName($this->tempFile)))
					$this->_MakeDirectoryRecursively($this->_DirectoryName($this->tempFile));
			}
			if ($getFile) $this->_SmbClient('get "'.$this->name.'" "'.$this->tempFile.'"', $this->parent);
			$this->cached = ! $getFile;
		}
	}

	function SendMessage ($server, $message)
	{
		$this->_SmbClient ('message', $server, $message);
	}

	function _SmbClient ($command='', $path='', $message='')
	{
		$this->status = '';
		if ($command == '') {
			$smbcmd = "-L ".escapeshellarg($path);
		}
		elseif ($command == 'message') {
			$smbcmd = "-M ".escapeshellarg($path);
		} else {
			$smbcmd = escapeshellarg("//{$this->server}/{$this->share}").
			" -c ".escapeshellarg($command);
			//$smbcmd .= ' -D '.escapeshellarg($path);
			if ($path <> '') $smbcmd .= ' -D '.escapeshellarg($path);
		}
		
		$options = '';
		if ($command <> '') {
			if ($this->workgroup <> '') $options .= ' -W '.escapeshellarg($this->workgroup);
			if ($this->socketOptions <> '') $options .= ' -O '.escapeshellarg($this->socketOptions);
			if ($this->blockSize <> '') $options .= ' -b '.$this->blockSize;
		}
		if ($this->user <> '') {
			# not anonymous
			switch ($this->cfgAuthMode) {
				case 'SMB_AUTH_ENV': putenv('USER='.$this->user.'%'.$this->pw); break;
				case 'SMB_AUTH_ARG': $smbcmd .= ' -U '.escapeshellarg($this->user.'%'.$this->pw);
			}
		}
		//Leon 2005/03/07
		//echo "smb_pwd0=".$this->pw."<BR>";
		//$smb_pwd=stripslashes($this->pw);
		//$smb_pwd = preg_replace("/(\")/","\\\\$0",$this->pw);
		//$smb_pwd = preg_replace("/(\")/","\\\\$0",$smb_pwd);
		//echo "smb_pwd1=".$smb_pwd."<BR>";
		for($i=0;$i<strlen($this->pw);$i++){
		  $char=substr($this->pw,$i,1);
		  if(ord($char)==92){
		    $char=chr(92).$char;
		  }
		  $tmp_pwd.=$char;
		}
		$smb_pwd=$tmp_pwd;
		//echo "smb_pwd2=".$smb_pwd."1<br>";
		$cmdline = $this->cfgSmbClient." ".$smbcmd." ".$options." -U ".escapeshellarg($this->user."%".$smb_pwd)." 2>&1";
		//echo $cmdline;exit;
		if ($message <> '') $cmdline = "echo ".escapeshellarg($message).' | '.$cmdline;
		//echo "cmdline=" . $cmdline . "<br>";
		//echo $cmdline."<br>".$command."<br>".$path;
		$strExec="/img/bin/auth.sh ".escapeshellarg($this->user)." ".escapeshellarg($smb_pwd);
		
		exec($strExec,$out,$ret);
		
		if($ret!="0"){
		  $this->status="LOGON_FAILURE";
		  return;
		}else{
			// set user login role
			if($role = each($out)){
				$_SESSION["role"] = ($role["value"] === "Login success") ? "user" : $role["value"];
			}
		}
		$this->_ParseSmbClient ($cmdline, $command, $path);
		if($command == ''){
			$cmdline = "/usr/bin/net rpc share -I 127.0.0.1 -U \"".$this->user."%".$smb_pwd."\"";
			$share_list = explode("\n",shell_exec($cmdline));
			foreach($share_list as $v){
				if($v==""||$v=="IPC$"||$v=="ADMIN$" || $v=="Could not connect to server 127.0.0.1")
					continue;
				$this->shares[$v] = array('name'=>$v,'type'=>'disk','comment'=>'');
			}
		}
		return;
	}

	function _ParseSmbClient ($cmdline)
	{
		$output = shell_exec($cmdline);
		$debug_command = ($this->debug > 1) ? "\n[smbclient]\n{$output}\n[/smbclient]" : "";
		$sec_cmdline = str_replace($this->pw, '****', $cmdline);
		$this->Debug("{$sec_cmdline}{$debug_command}");
		$lineType = $mode = '';
		foreach (explode("\n", $output) as $line){
			if ($line <> '') {
				$regs = array();
				$regs = array();
				reset ($this->parser);
				$linetype = 'skip';
				foreach ($this->parser as $regexp => $type) {
					# preg_match is much faster than ereg (Bram Daams)
					if (preg_match('/'.$regexp.'/', $line, $regs)) {
						$lineType = $type;
						break;
					}
				}
				switch ($lineType) {
					case 'SKIP': continue;
					case 'SHARES_MODE': $mode = 'shares'; break;
					case 'SERVERS_MODE': $mode = 'servers'; break;
					case 'WORKGROUPS_MODE': $mode = 'workgroups'; break;
					case 'SHARES':
						$name = trim($regs[1]);
						if ($this->cfgHideSystemShares <> 'on' OR $name[strlen($name)-1] <> '$') {
							$this->shares[$name] = array (
								'name' => $name,
								'type' => strtolower($regs[2]),
								'comment' => $regs[3]
							);
						}
						break;
					case 'SERVERS_OR_WORKGROUPS':
						$name = trim(substr($line,1,21));
						$comment = trim(substr($line, 22));
						if ($mode == 'servers')
							$this->servers[$name] = array ('name' => $name, 'type' => 'server', 'comment' => $comment);
						else
							$this->workgroups[$name] = array ('name' => $name, 'type' => 'workgroup', 'comment' => $comment);
						break;
					case 'FILES':
						# with attribute ?
						if (preg_match("/^(.*)[ ]+([D|A|H|S|R]+)$/", trim($regs[1]), $regs2)) {
							$attr = trim($regs2[2]);
							$name = trim($regs2[1]);
						} else {
							$attr = '';
							$name = trim($regs[1]);
						}
						if ($name <> '.' AND $name <> '..') {
							$type = (strpos($attr,'D') === false) ? 'file' : 'folder';
							$this->files[$name] = array (
								'name' => $name,
								'attr' => $attr,
								'size' => $regs[2],
								'time' => $this->_ParseTime($regs[4],$regs[5],$regs[7],$regs[6]),
								'type' => $type
							);
						}
						break;
					case 'PRINT_JOBS':
						$name = $regs[1].' '.$regs[3];
						$this->printjobs[$name] = array(
							'name'=>$name,
							'type'=>'printjob',
							'id'=>$regs[1],
							'size'=>$regs[2]
						);
						break;
					case 'SIZE':
						$this->size = $regs[1] * $regs[2];
						$this->available = $regs[3] * $regs[2];
						break;
					case 'ERROR': $this->status = $regs[1]; break;
					default:  $this->status = $lineType;
				}
			}
		}
	}

	# returns unix time from smbclient output
	function _ParseTime ($m, $d, $y, $hhiiss)
	{
		$his= explode(':', $hhiiss);
		$im = 1 + strpos("JanFebMarAprMayJunJulAugSepOctNovDec", $m) / 3;
		return mktime($his[0], $his[1], $his[2], $im, $d, $y);
	}

	# make a directory recursively
	function _MakeDirectoryRecursively ($path, $mode = 0777)
	{
		if (strlen($path) == 0) return 0;
		if (is_dir($path)) return 1;
		elseif ($this->_DirectoryName($path) == $path) return 1;
		return ($this->_MakeDirectoryRecursively($this->_DirectoryName($path), $mode)
			and mkdir($path, $mode));
	}

	# I do not like PHP dirname
	function _DirectoryName ($path='')
	{
		$a = explode('/', $path);
		$n = (trim($a[count($a)-1]) == '') ? (count($a)-2) : (count($a)-1);
		for ($dir=array(),$i=0; $i<$n; $i++) $dir[] = $a[$i];
		return join('/',$dir);
	}

}
?>
