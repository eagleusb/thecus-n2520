<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="zh_tw" lang="zh_tw">
<link rel="shortcut icon" href="/theme/images/icons/browser.ico">
<head>
<title><{$webpage_title}></title>
<meta http-equiv="X-UA-Compatible" content="IE=EmulateIE7">
<meta http-equiv="X-UA-Compatible" content="chrome=1"/>
<meta http-equiv="content-type" content="text/html; charset=UTF-8" />   
<link rel="stylesheet" type="text/css" href="<{$urlcss}>ext-all.css?<{$randValue}>" />
<link rel="stylesheet" type="text/css" href="<{$urlcss}>loadmask.css?<{$randValue}>" />
<link rel="stylesheet" type="text/css" href="<{$urlcss}>login.css?<{$randValue}>" />
<script type="text/javascript" src="<{$urlextjs}>adapter/ext/ext-base.js?<{$randValue}>"></script>
<script type="text/javascript" src="<{$urlextjs}>ext-all.js?<{$randValue}>"></script>    
<script type="text/javascript" src="<{$urljs}>net.js?<{$randValue}>" ></script>   
 

<script type="text/JavaScript">
<!--
//
var mainMask; 
var piczza_enabled = false;
var webdisk_enabled = false;
var rebootflag;
var fwMask;

function MM_swapImgRestore() { //v3.0
  var i,x,a=document.MM_sr; for(i=0;a&&i<a.length&&(x=a[i])&&x.oSrc;i++) x.src=x.oSrc;
}

function MM_preloadImages() { //v3.0
  var d=document; if(d.images){ if(!d.MM_p) d.MM_p=new Array();
    var i,j=d.MM_p.length,a=MM_preloadImages.arguments; for(i=0; i<a.length; i++)
    if (a[i].indexOf("#")!=0){ d.MM_p[j]=new Image; d.MM_p[j++].src=a[i];}}
}

function MM_findObj(n, d) { //v4.01
  var p,i,x;  if(!d) d=document; if((p=n.indexOf("?"))>0&&parent.frames.length) {
    d=parent.frames[n.substring(p+1)].document; n=n.substring(0,p);}
  if(!(x=d[n])&&d.all) x=d.all[n]; for (i=0;!x&&i<d.forms.length;i++) x=d.forms[i][n];
  for(i=0;!x&&d.layers&&i<d.layers.length;i++) x=MM_findObj(n,d.layers[i].document);
  if(!x && d.getElementById) x=d.getElementById(n); return x;
}

function MM_swapImage() { //v3.0
  var i,j=0,x,a=MM_swapImage.arguments; document.MM_sr=new Array; for(i=0;i<(a.length-2);i+=3)
   if ((x=MM_findObj(a[i]))!=null){document.MM_sr[j++]=x; if(!x.oSrc) x.oSrc=x.src; x.src=a[i+2];}
}
function closewindow(){
  document.getElementById('login').style.display='none';
} 

function closeModuleWin(){
  document.getElementById('module_dlg').style.display='none';
} 

/*
* whatKey
* @param evt int - event.  
*/
function whatKey(evt){
    evt = (evt) ? evt : event; 
    keyVals = document.getElementById('ffKeyTrap').value;
    keyCode = evt.keyCode;
	if (navigator.appName.indexOf("Microsoft") != -1) {	// skip IE browser
		return;
	}
    if( keyVals=='1' && keyCode == 13) {
         if(document.getElementById('login').style.display!='none' && document.getElementById('login_text').style.display=='none'){
               submitForm();
         }
    } 
} 
  
function windowOnload(){  
   mainMask= new Ext.LoadMask(Ext.getBody(),{msg:"<{$gwords.wait_msg}>..."});   
   mainMask.hide();   
   document.getElementById('loading').style.display='none';
   document.getElementById('loading-mask').style.display='none';
} 
if(Ext.get('loading')){
   document.getElementById('loading').style.display='block';
   document.getElementById('loading-mask').style.display='block';
}

function gotoModule(mod_name, mod_displayname, mod_login, mod_ui, mod_homepage) {
	var mod_url = "";
	if(mod_ui=='Thecus'){
		mod_url = "adm/getform.html?Module=" + mod_name;
	}else{
		mod_url = "/modules/" + mod_name + '/' + mod_homepage;
	}
	
	if (mod_login == 0) {
		window.open(mod_url);
	} else {
		document.getElementById('module_dlg').style.display = 'none';
		document.getElementById('url').value = "adm/login.php";
		document.getElementById('successurl').value = mod_url;
		showLoginWin(mod_displayname, 'module');
	}
}

function PopupWindow(type,url,name_gwords,successurl,id){
	if ("<{$raidexist}>" == "0" && name_gwords != "admin") {
		Ext.Msg.show({
			title:"",
			minWidth:300,
			msg:"<{$gwords.raid_exist_warning}>",
			buttons:Ext.MessageBox.OK,
			icon:Ext.MessageBox.WARNING
		});
		return;
	}
	if (name_gwords == "module") {
		document.getElementById('module_dlg').style.display='block';
		return;
	} else if ((name_gwords =="photo_server" && "<{$photo_login}>" == "0") ||
		(name_gwords =="web_disk" && "<{$webdisk_login}>" == "0")) {
		location.href = successurl;
		return;
	}

	document.getElementById('successurl').value=successurl;
	document.getElementById('url').value=url;
	showLoginWin(name_gwords, '');
}

function showLoginWin (name_gwords, loginType) {
	var usrNameField = document.getElementById('username');
	usrNameField.value='';
	usrNameField.disabled=false;
	document.getElementById('login').style.display='block'; 
	document.getElementById('ffKeyTrap').value='1'; 
	document.getElementById('pwd').value='';
	document.getElementById('title_panel').innerHTML="<{$gwords.name_gwords}>";
	document.getElementById('loginType').value = loginType;
	<{if $multi_logon=='1'}>
		document.getElementById('multi_logon').style.display='none'; 
	<{/if}> 
	if(name_gwords!='admin'){ 
		<{if $dombstart!="" or $only_domb=="0" or $raidexist=='0'}>
			document.getElementById('login_text').style.display='block';
			document.getElementById('login_field').style.display='none'; 
		<{/if}>
		document.getElementById('username_input').style.display='block';
		usrNameField.focus();
	}else{
		<{if $multi_logon=='1'}>
			document.getElementById('multi_logon').style.display='block'; 
		<{/if}>
		document.getElementById('login_text').style.display='none';
		document.getElementById('login_field').style.display='block';
		document.getElementById('username_input').style.display='block';
		usrNameField.value='admin';
		usrNameField.disabled=true;
		document.getElementById('pwd').focus();
	}
	<{if $dombstart!="" or $only_domb=="0"}>
		document.getElementById('login_text').style.display='block';
		document.getElementById('login_field').style.display='none';
	<{/if}>
}

function processResult(){ 
	document.getElementById('login').style.display='block';
	document.getElementById('pwd').value='';
	if(document.getElementById('username').value==''){
		document.getElementById('username').focus();
	}else{
		document.getElementById('pwd').focus();
	}
	document.getElementById('ffKeyTrap').value='1';
}
function onLoginPanel(){
	var request = eval('('+this.req.responseText+')');
	if(!request.success){
		document.getElementById('loading').style.display='none';
		document.getElementById('loading-mask').style.display='none';
		mainMask.hide();
		document.getElementById('ffKeyTrap').value='0';
		Ext.Msg.show({
			title:request.errormsg.title,
			minWidth:300,
			msg:request.errormsg.msg,
			buttons:Ext.MessageBox.OK,
			fn:processResult,
			icon:Ext.MessageBox.WARNING
		});
	}else{
		if (document.getElementById('loginType').value == "module") {  
			document.getElementById('loading').style.display='none';
			document.getElementById('loading-mask').style.display='none';
			window.open(document.getElementById('successurl').value);
		} else {
			location.href=document.getElementById('successurl').value;
		}
	}
}

function submitForm(){
	document.getElementById('loading').style.display='block';
	document.getElementById('loading-mask').style.display='block';
	var username=document.getElementById('username').value;
	var pwd=document.getElementById('pwd').value;
	var url=document.getElementById('url').value;
	
	var param = 
		"&eplang=<{$u_lang}>"+
		"&p_pass="+encodeURIComponent(pwd)+
		"&p_user="+encodeURIComponent(username)+
		"&username="+encodeURIComponent(username)+
		"&pwd="+encodeURIComponent(pwd)+
		"&action=login"+
		"&option=com_extplorer"; 
	if ('<{$smbservice}>' == '0' && username != 'admin') {
		document.getElementById('loading').style.display='none';
		document.getElementById('loading-mask').style.display='none';
		Ext.Msg.show({
			title:"<{$gwords.error}>",
			minWidth:300,
			msg:"<{$gwords.samba_service_warning}>",
			buttons:Ext.MessageBox.OK,
			fn:processResult,
			icon:Ext.MessageBox.WARNING
		});
	} else {
		new net.ContentLoader(true,url,onLoginPanel,null,'POST',param);
	} 
}

//-->
</script> 


 

</head>
<body bgcolor="#000000" onload="windowOnload()" onkeydown="whatKey(event)" >

<div id="loading-mask" ></div>
<div id="loading">
</div> 

<div id="mask_html">
<div class="top_logo"><a href='<{$logo_link}>' target="_blank"><img src="/theme/images/login/logo.png" alt="logo" /></a></div>
<div class="right_logo"><img  src="/theme/images/login/slogan.png" alt="slogan" /></div> 
<div id="login" name="login" style="display:none">

<div  align="center" style="position:absolute; width:100%; margin-top:250px; z-index:2" >
<{if $multi_logon=='1'}><div id="multi_logon" align="left" ><{$gwords.multi_logon}></div><{/if}>
</div>
 
 
 <div align="center" style="position:absolute; width:100%; margin-top:310px; z-index:1" >
<table width="100%" height="100%" border="0"><tr><td>
<form id="loginpanel" name="loginpanel" method="post" onsubmit="submitForm();return false;" >

  <input type="hidden" name='ffKeyTrap'  id='ffKeyTrap'  value='0' />
  <input type="hidden" name="url"        id="url"        value="<{$login_php}>" /> 
  <input type="hidden" name="successurl" id="successurl" value="/index.php" />
  <input type="hidden" nae="loginType" id="loginType" value=" /">
    
  <table  width="341" border="0" align="center" cellpadding="0" cellspacing="0">
      <tr>
        <td width="341" height="30" background="/theme/images/login/login_01.png"><table width="100%" cellspacing="2" cellpadding="2">
	  <tr>
	    <td width="84%"><div class="login_wd_title" style="padding-left:10px" id="title_panel" name="title_panel">Admin</div></td>
	    <td width="16%"><div align="right" style="padding-right:6px; cursor:pointer" >
	     <input name="close" type="image" id="close" src="/theme/images/login/close.png" title="<{$gwords.closewindow}>" alt="<{$gwords.closewindow}>" onclick="javascript:closewindow();return false;" />
	    </div></td>
	  </tr>
	</table>
	</td>
      </tr>
      <tr>
        <td><table width="100%" border="0" cellspacing="0" cellpadding="0">
          <tr>
            <td><img src="/theme/images/login/login_03.png" width="9" height="99" /></td>
            <td width="100%" class="login_table">

              <div id="login_text"   style="display:none" class="login_wd">
			<{if $dombstart!="" or $only_domb=="0"}><{$gwords.domb_boot}><{elseif $raidexist=='0'}><{$gwords.raid_exist_warning}><{/if}>
	      </div> 

              <div id="login_field">
              <table border="0" align="center" cellpadding="4" cellspacing="0">  
                <tr>
                  <td align="right" valign="middle" class="login_wd"><{$gwords.username}>:</td>
                  <td align="left" valign="middle"><span id="username_input" style="display:none"><input name="username" type="text" class="login_textfield" id="username" /></span></td>
                </tr>
                <tr>
                  <td align="right" valign="middle" class="login_wd"><{$gwords.password}>:</td>
                  <td align="left" valign="middle"><input name="pwd" type="password" class="login_textfield" id="pwd" /></td>
                </tr>
                <tr>
                  <td>&nbsp;</td>
                  <td align="right" valign="middle"><label>
                    <input name="login_bt" type="submit" class="login_bt" id="login_bt" value="<{$gwords.login}>" />
                  </label></td>
                </tr>
              </table></div> 

            </td>
            <td width="1%"><img src="/theme/images/login/login_06.png" width="8" height="99" /></td>
          </tr>
        </table></td>
      </tr>
      <tr>
        <td><img src="/theme/images/login/login_07.png" width="341" height="7" /></td>
      </tr>
      <tr>
        <td><img src="/theme/images/login/login_08.png" width="341" height="104" /></td>
      </tr>
    </table>
</form>
</td></tr></table>
  </div> 
</div>

<div id="module_dlg" style="position:absolute; width:100%; padding-top:150px; z-index:1; display:none;height:100%">
	<table width="391" border="0" align="center" cellpadding="0" cellspacing="0">
		<tr><td height="30" background="/theme/images/login/module_01.png">
			<table width="100%" cellspacing="2" cellpadding="2">
				<tr>
					<td width="84%"><div class="login_wd_title" style="padding-left:6px">Module List</div></td>
					<td width="16%">
						<div align="right" style="padding-right:0px; cursor:pointer" >
							<input name="close" type="image" id="close" src="/theme/images/login/close.png" alt="close" onclick="javascript:closeModuleWin();return false;" />
						</div>
					</td>
				</tr>
			</table>
		</td></tr>
		<tr><td><table width="100%" border="0" cellspacing="0" cellpadding="0" class="module_list_bg">
			
			<tr>
				<td><img src="/theme/images/login/module_03.png" width="8" height="291" /></td>
				<td><div class="module_list"> 
				<{foreach from=$modules item=data}>
					<div style="float:left;width:115px;height:90px;padding-top:40px;">
						<div align='center'><img width="100" height="85" src='<{$data.icon}>' style='cursor:pointer;' onclick='javascript:gotoModule("<{$data.name}>","<{$data.displayname}>","<{$data.login}>","<{$data.ui}>", "<{$data.homepage}>");return false;'></div><div align='center' class='login_wd_title'><{$data.displayname}></div>
					</div>
				<{/foreach}>
				</div></td>
				<td><img src="/theme/images/login/module_06.png" width="8" height="291" /></td>
			</tr>
		</table></td></tr>
      <tr>
        <td><img src="/theme/images/login/module_07.png" width="391" height="7" /></td>
      </tr>
      <tr>
        <td><img src="/theme/images/login/module_08.png" width="391" height="138" /></td>
      </tr>
	</table>
</div>
	
<div id="icons" name="icons">
<table width="100%" cellspacing="0" cellpadding="0" class="tb_login">
  <tr>
    <td ><div align="center" class="td_login">
      <table align="center"  cellpadding="0" cellspacing="20">
        <tr>
<{foreach from=$tab item=data}>
          <td width="124" height="194" >
 <div id="btntd"><table height="165" align="center" cellpadding="2" cellspacing="2">
              <tr>
                <td height="100" valign='top'><a href="javascript:void(0);" onmouseout="MM_swapImgRestore()" onclick="javascript:PopupWindow('','<{$data.url}>','<{$data.gwords}>','<{$data.successurl}>');" onmouseover="MM_swapImage('img_<{$data.id}>','','<{$data.iconpath_over}>',1)"><img style="padding-top:20px;padding-bottom:30px" width="100" height="85" src="<{$data.iconpath}>" name="img_<{$data.id}>"   border="0" id="img_<{$data.id}>" /><br />
                      <div align="center"  class="login_wd"><{$data.name}></div>
                </a></td>
              </tr>
          </table></div></td>
<{/foreach}> 
        </tr>
      </table>
      <div id="browser_limit_html"><{$gwords.login_limit}></div>
    </div></td>
  </tr>
</table>  
</div>
</div>

<{include file="adm/footer.tpl"}>
