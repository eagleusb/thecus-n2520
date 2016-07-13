<?php
// ensure this file is being included by a parent file
if( !defined( '_JEXEC' ) && !defined( '_VALID_MOS' ) ) die( 'Restricted access' );
/**
 * @version $Id: users.php 107 2008-07-22 17:27:12Z soeren $
 * @package eXtplorer
 * @copyright soeren 2007
 * @author The eXtplorer project (http://sourceforge.net/projects/extplorer)
 * @author The  The QuiX project (http://quixplorer.sourceforge.net)
 * 
 * @license
 * The contents of this file are subject to the Mozilla Public License
 * Version 1.1 (the "License"); you may not use this file except in
 * compliance with the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 * 
 * Software distributed under the License is distributed on an "AS IS"
 * basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
 * License for the specific language governing rights and limitations
 * under the License.
 * 
 * Alternatively, the contents of this file may be used under the terms
 * of the GNU General Public License Version 2 or later (the "GPL"), in
 * which case the provisions of the GPL are applicable instead of
 * those above. If you wish to allow use of your version of this file only
 * under the terms of the GPL and not to allow others to use
 * your version of this file under the MPL, indicate your decision by
 * deleting  the provisions above and replace  them with the notice and
 * other provisions required by the GPL.  If you do not delete
 * the provisions above, a recipient may use your version of this file
 * under either the MPL or the GPL."
 * 
 * Administrative Functions regarding users
 */
 

function load_users() {
	require _EXT_PATH."/config/htusers.php";
}
//------------------------------------------------------------------------------
function save_users() {
	$cnt=count($GLOBALS["users"]);
	if($cnt>0) sort($GLOBALS["users"]);
	
	// Make PHP-File
	$content='<?php 
	/** ensure this file is being included by a parent file */
	defined( "_VALID_MOS" ) or die( "Direct Access to this location is not allowed." );
	$GLOBALS["users"]=array(';
	for($i=0;$i<$cnt;++$i) {
		// if($GLOBALS["users"][6]&4==4) $GLOBALS["users"][6]=7;	// If admin, all permissions
		$content.="\r\n\tarray(\"".$GLOBALS["users"][$i][0].'","'.
			$GLOBALS["users"][$i][1].'","'.$GLOBALS["users"][$i][2].'","'.$GLOBALS["users"][$i][3].'",'.
			$GLOBALS["users"][$i][4].',"'.$GLOBALS["users"][$i][5].'",'.$GLOBALS["users"][$i][6].','.
			$GLOBALS["users"][$i][7].'),';
	}
	$content.="\r\n); \r\n?>";
	
	// Write to File
	if( !is_writable(_EXT_PATH."/config/htusers.php") && !chmod( _EXT_PATH."/config/htusers.php", 0644 ) ) {
		return false;
	}
	file_put_contents( _EXT_PATH."/config/htusers.php", $content);
	
	return true;
}
//------------------------------------------------------------------------------
function &find_user($user,$pass,$log=false) {
	global $session;
	$aryUser=array();
	
	if($log)
		$chkauth=$session->singleLogin($user,$pass); 
	else
		$chkauth=1;

	$uid=$session->getUID($user);
	if($uid!=""){
		$ulocal=$session->chkLocalUser($uid);
	}else{
		return $aryUser;
	}
	//printf("chkauth=%s uid=%s ulocal=%s \n",$chkauth,$uid,$ulocal);
	//exit;
	
	if ($chkauth==1) {
		$aryUser=array($user,$pass,"/raid/data/ftproot","http://localhost",1,"",7,1,$uid,$ulocal);
	}
	
	return $aryUser;
}
//------------------------------------------------------------------------------
function activate_user($user,$pass,$log=false) {
	$data=find_user($user,$pass,$log);
	if($data==NULL) return false;
	
	// Set Login
	$_SESSION['s_user']	= $data[0];
	$_SESSION['s_pass']	= $data[1];
	$GLOBALS["home_dir"]	= str_replace( '\\', '/', $data[2] );
	$GLOBALS["home_url"]	= $data[3];
	$GLOBALS["show_hidden"]	= $data[4];
	$GLOBALS["no_access"]	= $data[5];
	$GLOBALS["permissions"]	= $data[6];
	$_SESSION['s_uid']	= $data[8];
	$_SESSION['s_ulocal']	= $data[9];
	$_SESSION['s_gid']=trim(shell_exec("/usr/bin/getent group|awk '/:".preg_quote($username)."/||/,".preg_quote($username)."/'"));
	
	return true;
}
//------------------------------------------------------------------------------
function update_user($user,$new_data) {
	$data=&find_user($user,NULL);
	if($data==NULL) return false;
	
	$data=$new_data;
	return save_users();
}
//------------------------------------------------------------------------------
function add_user($data) {
	if(find_user($data[0],NULL)) return false;
	
	$GLOBALS["users"][]=$data;
	return save_users();
}
//------------------------------------------------------------------------------
function remove_user($user) {
	$data=&find_user($user,NULL);
	if($data==NULL) return false;
	
	// Remove
	$data=NULL;
	
	// Copy Valid Users
	$cnt=count($GLOBALS["users"]);
	for($i=0;$i<$cnt;++$i) {
		if($GLOBALS["users"][$i]!=NULL) $save_users[]=$GLOBALS["users"][$i];
	}
	$GLOBALS["users"]=$save_users;
	return save_users();
}
//------------------------------------------------------------------------------
/*
function num_users($active=true) {
	$cnt=count($GLOBALS["users"]);
	if(!$active) return $cnt;
	
	for($i=0, $j=0;$i<$cnt;++$i) {
		if($GLOBALS["users"][$i][7]) ++$j;
	}
	return $j;
}
*/
//------------------------------------------------------------------------------

?>
