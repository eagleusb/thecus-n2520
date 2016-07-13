<?php
// ensure this file is being included by a parent file
if( !defined( '_JEXEC' ) && !defined( '_VALID_MOS' ) ) die( 'Restricted access' );
/**
 * @version $Id: footer.php 107 2008-07-22 17:27:12Z soeren $
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
 * Shows the About Box!
 */
function show_about() {			// footer for html-page
	echo "\n<div id=\"ext_footer\" style=\"text-align:center;\">
	<img src=\""._EXT_URL."/images/eXtplorer.gif\" align=\"middle\" alt=\"eXtplorer Logo\" />
	<br />
	".ext_Lang::msg('your_version').": <a href=\"".$GLOBALS['ext_home']."\" target=\"_blank\">eXtplorer {$GLOBALS['ext_version']}</a>
	<br />
 (<a href=\"http://virtuemart.net/index2.php?option=com_versions&amp;catid=5&amp;myVersion=". $GLOBALS['ext_version'] ."\" onclick=\"javascript:void window.open('http://virtuemart.net/index2.php?option=com_versions&catid=5&myVersion=". $GLOBALS['ext_version'] ."', 'win2', 'status=no,toolbar=no,scrollbars=yes,titlebar=no,menubar=no,resizable=yes,width=640,height=580,directories=no,location=no'); return false;\" title=\"".$GLOBALS["messages"]["check_version"]."\">".$GLOBALS["messages"]["check_version"]."</a>)
	
	";
	if(function_exists("disk_free_space")) {
		$size = disk_free_space($GLOBALS['home_dir']. $GLOBALS['separator']);
		$free=parse_file_size($size);
	} 
	elseif(function_exists("diskfreespace")) {
		$size = diskfreespace($GLOBALS['home_dir'] . $GLOBALS['separator']);
		$free=parse_file_size($size);
	} 
	else $free = "?";
	
	echo '<br />'.$GLOBALS["messages"]["miscfree"].": ".$free." \n";
	if( extension_loaded( "posix" )) {
	  	$owner_info = '<br /><br />'.ext_Lang::msg('current_user').' ';
	  	if( ext_isFTPMode() ) {
	  		$my_user_info = posix_getpwnam( $_SESSION['ftp_login'] );
	  		$my_group_info = posix_getgrgid( $my_user_info['gid'] );
	  	} else {
			$my_user_info = posix_getpwuid( posix_geteuid() );
			$my_group_info = posix_getgrgid(posix_getegid() );
	  	}
		$owner_info .= $my_user_info['name'].' ('. $my_user_info['uid'].'), '. $my_group_info['name'].' ('. $my_group_info['gid'].')'; 
	  
		echo $owner_info;
	}
	echo "
	</div>";
}

function show_footer()  {
	echo "\n<div id=\"ext_footer\" style=\"text-align:center;\">
	<img src=\""._EXT_URL."/images/eXtplorer.gif\" align=\"middle\" alt=\"eXtplorer Logo\" />
	</div>";
}
//------------------------------------------------------------------------------
?>
