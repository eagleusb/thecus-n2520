<?
    @session_start();
		require_once('../../../../function/conf/localconfig.php');
		require_once(INCLUDE_ROOT.'session.php');
    require_once(WEBCONFIG);
    require_once(INCLUDE_ROOT.'sqlitedb.class.php');
    $db=new sqlitedb();
    $_SESSION['lang'] = $db->getvar("admin_lang","en");;
    $db->db_close();
    unset($db);

//    require_once("../../setlang/lang.html");
//    require_once("../../webconfig");
    $words=$session->PageCode("xpublish");
    $gwords=$session->PageCode("global");
    require_once("../GlobalVars.html");
    $ONNEXT_SCRIPT = 'return check();';
    $ONBACK_SCRIPT = 'window.external.FinalBack();';
    $WIZARD_BUTTONS = 'true,true,false';

    $rs=trim(shell_exec('cat /proc/mdstat | grep md1 |wc -l'));
    //$rs = 0;
    if ($rs < 1){
	$WIZARD_BUTTONS = 'false,false,false';
        echo('<form><Table><TR><TD width=400 valign="Top"><BR><BR><BR>'.$words['raid_no_init'].'<BR><BR><BR></TD><TD><img src="/usr/gallery/img/login.jpg" height="220" /></TD></TR></Table></form>');
    }else if(!file_exists(AlbumRoot)){
	$WIZARD_BUTTONS = 'false,false,false';
        echo('<form><Table><TR><TD width=400 valign="Top"><BR><BR><BR>'.$words['album_no_init'].'<BR><BR><BR></TD><TD><img src="/usr/gallery/img/login.jpg" height="220" /></TD></TR></Table></form>');
    }else{
//    	if((!isset($_SESSION['username'])) || ($_SESSION['username']=="admin")){
    	if((!isset($_SESSION['username']))){
		login_form();
		@session_unset();
		@session_destroy();
	 }else{
		$service = empty($_POST['service']) ? '' : $_POST['service'];
		switch ($service){
			case "gallery":
				gallery();
				break;
			default:
				publish();
				$ONNEXT_SCRIPT = 'publish.submit();';
				break;
		}
	}
    }
    //=========================================================================
    //Function Area
    //=========================================================================

    function GiveRight($id,$path){
        $group="smbusers";
        chown($path,$id);
	chgrp($path,$group);
	chmod($path,0754);
    }

    function ScanDirs($id,$album){
        if(!file_exists(AlbumRoot)){
		 @mkdir(AlbumRoot,0754);
	}

        $root=AlbumRoot;
        if ($id)
                $root .= $id . "/";
        if ($album)
                $root .= $album . "/";

        chdir($root);
        $dir=dir(".");
        $dir->rewind();

        while($file=$dir->read()){
        	if (!$album){
                	if(is_dir($file) && ($file!=".") && ($file!="..")){
	                $obj[]=array(filectime($file),$file);
        	        }
        	}
	        else{
        	        if(is_file($file)){
                	        if(File_Format_confirm($file)){
                        	        if( filesize($file) <= MaxFileSize )
                                	$obj[]=array(filectime($file),$file);
	                        }
        	        }
	        }
        }
        $dir->close();
        if (count($obj)>0)
                rsort($obj);
        return $obj;
    }

    function Fix_post($arg){
        $arg=str_replace("\\\\","\t",$arg);
        $arg=str_replace("\\","",$arg);
        return str_replace("\t","\\",$arg);
    }

    function javascript_string($str){
    	// replace \ with \\ and then ' with \'.
    	$str = str_replace('\\', '\\\\', $str);
    	$str = str_replace('\'', '\\\'', $str);
    	return $str;
    }

?>


<?function gallery(){
	global $words;

	if(!is_dir(AlbumRoot . $_SESSION['username'])){
        	@mkdir(AlbumRoot . $_SESSION['username'],0755);
        	$group="smbusers";
       	        chown(AlbumRoot . $_SESSION['username'],$_SESSION['username']);
		chgrp(AlbumRoot . $_SESSION['username'],$group);
        }

	if ($_POST['admin']=="confirm_create"){
        	if (@mkdir(AlbumRoot . $_SESSION['username']. "/" . trim(Fix_post($_POST['album_name'])),0755)){
        	        @GiveRight($_SESSION['username'],AlbumRoot . $_SESSION['username'] . "/" . trim(Fix_post($_POST['album_name'])));
        	}
		$obj = ScanDirs($_SESSION['username'],"");
		if (count($obj)==0){
        		$GLOBALS['WIZARD_BUTTONS'] = 'true,false,false';
		}else{
        		$GLOBALS['WIZARD_BUTTONS'] = 'true,true,false';
	        	$GLOBALS['ONNEXT_SCRIPT'] = 'gallery.submit();';
		}
	}else{
		$obj = ScanDirs($_SESSION['username'],"");
		if (count($obj)==0){
        		$GLOBALS['WIZARD_BUTTONS'] = 'true,false,false';
		}else{
        		$GLOBALS['WIZARD_BUTTONS'] = 'true,true,false';
			if (isset($_POST['album'])){
	        		$GLOBALS['ONNEXT_SCRIPT'] = 'startUpload("'.$_POST['album'].'");';
			}else{
	        		$GLOBALS['ONNEXT_SCRIPT'] = 'gallery.submit();';
			}
		}	
	}
  ?>

  <form name="gallery" method="post">
	<input type="hidden" name="service" value="gallery">
	<?if (isset($_POST['album']) && ($_POST['admin']=="")){?>
		<Table><TR>
			<TD width=400 valign="Top">
		<BR><BR><BR>
		<?echo "<BR>".$words['selecter_album']." <B>".$_POST['album']."</B>. <BR><BR>";
		echo $words['be_sure_pubilsh']."<br>";
		echo "<BR><BR>";
		$GLOBALS['ONBACK_SCRIPT']  = 'gallery.submit();';
	}else{?>
		<Table><TR>
			<TD width=400 valign="Top">
		<BR><BR><BR>
		<input type="hidden" name="admin" value="">
		<?=$words['service_on_gallery']?> :
		<BR><BR><BR>
		<?=$words['select_album_upload']?> :
        	<select name="album">
        	<?
                	for ($i=0;$i<count($obj);$i++)
                        	echo('<option>'.$obj[$i][1].'</option>');
        	?>
        	</select>
		<BR><BR>
		<?=$words['album_name']?> :
		<input type="text" name="album_name" maxlength="20" size="12" onkeyup="checklength(this,20)">
		<input type=button name="Create_Album" value="Create Album" onclick="CreateAlbumClick()";>
		<BR>
	<?}?>
			</TD>
			<TD><img src="/usr/gallery/img/login.jpg" height="220" /></TD>
		</TR></Table>
  </form>

  <?
  //=========================================================================
  //Javascript Area
  //=========================================================================
  ?>

  <script language="javascript">

  function isDirName(s){
        var s = typeof(s.value)=='undefined' ? s : s.value;
        for(var account=0;account<s.length;account++){
            var tmp_index = s.charCodeAt(account);
            if(tmp_index == 92 || tmp_index == 47 || tmp_index ==58 || tmp_index == 42 ||
               tmp_index == 63 || tmp_index == 60 || tmp_index ==62 || tmp_index == 34 ||
               tmp_index ==124){
                return false;
            }
        }
        return true;
  }

  function check(){
 /*       for(var i=0;i<document.gallery.album_name.value.length;i++){
                if(document.gallery.album_name.value.charCodeAt(i)==32){
                	alert("<?=$words['ill_floder']?>");
                	return false;
                }
        }
 */
        var len=document.gallery.album_name.value.length;
        if(document.gallery.album_name.value.charCodeAt(0)==32 || document.gallery.album_name.value.charCodeAt(len-1)==32){
                	alert("<?=$words['ill_floder']?>");
                	return false;          
        }

        if((!isDirName(document.gallery.album_name)) || 
	   (!document.gallery.album_name.value.length)){
                alert("<?=$words['ill_floder']?>");
                return false;
        }
        return true;
  }

  function manage(ACT){
        document.gallery.admin.value=ACT;
        document.gallery.submit();
  }

  function CreateAlbumClick(){
        if(!check()){
                return false;
	}
        checklength(document.gallery.album_name,20)
        manage('confirm_create');
        return true;
  }

  function enableClick(){
         for(var i=0;i<document.gallery.album_name.value.length;i++){
                if(document.gallery.album_name.value.charCodeAt(i)!=32){
                        document.gallery.Create_Album.disabled=false;
                        return true;
                }
        }
        document.gallery.Create_Album.disabled=true;
        return false;
  }

  function checklength(key,len){
        var sharename=key.value;
        var sharename_length = 0;
        var count = 0;
        for(var i=0;i<sharename.length;i++){
                if(sharename.charCodeAt(i)  > 255){
                        sharename_length += 2;
                        count++;
                        if(sharename_length>len)
                                key.value=sharename.substr(0,key.value.length-1);
                }else{
                        sharename_length ++;
                        count++;
                        if(sharename_length>len)
                                key.value=sharename.substr(0,key.value.length-1);
                }
        }
        if(sharename_length >= len){
                key.maxLength = count;
                return false;
        }else
                key.maxLength = len;
        return true;
  }

  </script>
<?}?>


<?function publish(){
global $words;
?>
	<form name="publish" method="post">
		<Table><TR>
			<TD width=400 valign="Top">
			<BR><BR><BR>
			&nbsp;<?=$words['welcome']?> <font color="orange"> <b><?=$_SESSION['username']?></b></font>,
			<BR><BR>
			&nbsp;<?=$words['click_next']?> : <br><BR>
			<input type="hidden" name="service" value="gallery">
			<BR><BR><BR><BR>
			<?=$words['file_type_size']?> <?=MaxFileSize/(1024*1024)?> MB.
			</TD>
			<TD><img src="/usr/gallery/img/login.jpg" height="220" /></TD>
		</TR></Table>
	</form>
<?}?>


<?function login_form(){
global $words,$gwords;
?>
  <form method="post" id="login" name="login" action="/usr/gallery/XPublish/?cmd=identify">
	<Table><TR>
		<TD width=400 valign="Top">
		<br><br><br>
    <font class="small-c"><?=$words['input_id_pwd']?></font>
    <table border="0">
      <tr>
  		<td class="small-c"><?=$words['id']?> : </td>
		<td><input class="small-c" name="username" type="text" size="12" maxlength="32"></td>
      </tr>
      <tr>
		<td class="small-c"><?=$gwords['password']?> : </td>
		<td><input class="small-c" name="pwd" type="password" size="12" maxlength="16"></td>
      </tr>
    </table>

		</TD>
		<TD><img src="/usr/gallery/img/login.jpg" height="220"/></TD>
	</TR></Table>
  </form>

  <script language="javascript" src="/usr/gallery/js/isSingleByteChar.js"></script>
  <script language="javascript" src="/usr/gallery/js/isAccount.js"></script>
  <script language="javascript">
  <!--
  var username = document.getElementsByName('username')[0];
  function check(){
	var pwd = document.getElementsByName('pwd')[0].value;
	var username = document.getElementsByName('username')[0].value;
	if(username.replace(/ /,'') == ''){
		alert("<?=$words['empty_usrname']?>");
		return false;
	}
	if(!isAccount(username)){
		alert("<?=$words['error_usrname']?>");
		return false;
	}
	if(!isSingleByteChar(pwd)){
		alert("<?=$words['error_pwd']?>");
		return false;
	}
	login.submit();
  }
  //-->
  </script>
<?}?>


<?
//=========================================================================
//footer Area
//=========================================================================
?>

<div id="content"></div>

<script language='javascript'>

function startUpload(album) {
        var xml = window.external.Property('TransferManifest');
        var files = xml.selectNodes('transfermanifest/filelist/file');
	var filelist = xml.selectSingleNode('transfermanifest/filelist');
	var firstNode = filelist.firstChild;
	var lastNode =filelist.lastChild;
	var tmpNode;
	var curNode = firstNode;
	var ftype = curNode.getAttribute("contenttype");
	var fsize = curNode.getAttribute("size");

	for (;;){
		//alert(curNode.getAttribute("source"));
		if (((ftype == "image/jpeg")||(ftype == "image/jpg")||(ftype == "image/gif")||
		    (ftype == "image/png")||(ftype == "image/bmp"))&&(fsize < <?=MaxFileSize?>)){
			if (curNode.getAttribute("source") == lastNode.getAttribute("source"))
				break;
			curNode = curNode.nextSibling;
			ftype = curNode.getAttribute("contenttype");
			fsize = curNode.getAttribute("size");
		}else{
			if (curNode.getAttribute("source") == lastNode.getAttribute("source")){
				filelist.removeChild(lastNode);
				break;
			}
			tmpNode = curNode.nextSibling;
			filelist.removeChild(curNode);
			curNode = tmpNode;
			ftype = curNode.getAttribute("contenttype");
			fsize = curNode.getAttribute("size");
		}
	}

        for (i = 0; i < files.length; i++) {
               	var postTag = xml.createNode(1, 'post', '');
               	postTag.setAttribute('href', '<?php echo 'http://' . $HTTP_SERVER_VARS['HTTP_HOST'] .  
				     '/usr/gallery/XPublish/?cmd=add_picture'?>&album=' + encodeURI(album) + 
				     '&PicName=' + encodeURI(files.item(i).getAttribute("destination")) +
				     '&id=' + encodeURI('<?=$_SESSION['username']?>'));
               	postTag.setAttribute('name', 'userpicture');

               	var dataTag = xml.createNode(1, 'formdata', '');
               	dataTag.setAttribute('name', 'MAX_FILE_SIZE');
               	dataTag.text = '10000000';
               	postTag.appendChild(dataTag);

               	files.item(i).appendChild(postTag);
        }

        var uploadTag = xml.createNode(1, 'uploadinfo', '');
        uploadTag.setAttribute('friendlyname', '<?=$webconfig['product_no']?><?=$webconfig['pro']?> Photo Gallery');
        var htmluiTag = xml.createNode(1, 'htmlui', '');
        htmluiTag.text = '<?php echo 'http://'.$HTTP_SERVER_VARS['HTTP_HOST'].'/'?>usr/gallery/?contant=/gallery/iframe_gallery.html';
        uploadTag.appendChild(htmluiTag);

        xml.documentElement.appendChild(uploadTag);

        window.external.Property('TransferManifest')=xml;
        window.external.SetWizardButtons(true,true,true);
        content.innerHtml=xml;
        window.external.FinalNext();
}

function OnBack() {
        <?=$ONBACK_SCRIPT?>
        window.external.SetWizardButtons(false,true,false);
}

function OnNext() {
        <?=$ONNEXT_SCRIPT?>
}

function OnCancel() {
}

function window.onload() {
        window.external.SetHeaderText('<?=$webconfig['product_no']?><?=$webconfig['pro']?> <?=$words['headertext']?>','<?=$words['poweredby']?> <?=$webconfig['manufactur']?>');
        window.external.SetWizardButtons(<?=$WIZARD_BUTTONS?>);
}
</script>
</body>
</html>
