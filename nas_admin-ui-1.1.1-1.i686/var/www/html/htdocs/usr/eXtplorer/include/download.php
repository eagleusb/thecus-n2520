<?php
// ensure this file is being included by a parent file
if( !defined( '_JEXEC' ) && !defined( '_VALID_MOS' ) ) die( 'Restricted access' );
/**
 * @version $Id: download.php 96 2008-02-03 18:13:22Z soeren $
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
 * 
 */
	
/**
 * File-Download Functions
 *
 */
class ext_Download extends ext_Action {
	
	function execAction($dir, $item, $unlink=false) {		// download file
		global $action, $mosConfig_cache_path;
		// Security Fix:
		$item=gbasename($item);
		while( @ob_end_clean() );
	    ob_start();
		
		if( ext_isFTPMode() ) {
			$abs_item = $dir.'/'.$item;
		}
		else {
			$abs_item = get_abs_item($dir,$item);
			//if( !strstr( $abs_item, $GLOBALS['home_dir']) )
			//  $abs_item = realpath($GLOBALS['home_dir']).$abs_item;
		}
		//printf("abs_item=%s \n",$abs_item);
		//ob_end_flush();
		//ext_exit();
		
		if(($GLOBALS["permissions"]&01)!=01) ext_Result::sendResult( 'download', false, $GLOBALS["error_msg"]["accessfunc"]);
		if(!$GLOBALS['ext_File']->file_exists($abs_item)) ext_Result::sendResult( 'download', false, $item.": ".$GLOBALS["error_msg"]["fileexist"]);
		if(!get_show_item($dir, $item)) ext_Result::sendResult( 'download', false, $item.": ".$GLOBALS["error_msg"]["accessfile"]);
	
		if( ext_isFTPMode() ) {
	
			$abs_item = ext_ftp_make_local_copy( $abs_item );
			$unlink = true;
		}
		$browser=id_browser();
	//ext_Result::sendResult( 'download', false, $abs_item);
		header('Content-Type: '.(($browser=='IE' || $browser=='OPERA')?
			'application/octetstream':'application/octet-stream'));
		header('Content-Type: application/force-download');
		header('Content-Type: application/download');
		header('Expires: '.gmdate('D, d M Y H:i:s').' GMT');
		header('Content-Transfer-Encoding: binary');
		header('Content-Length: '.filesize(realpath($abs_item)));
	    //header("Content-Encoding: none");
		if($browser=='IE') {
			header('Content-Disposition: attachment; filename="'.str_replace("+"," ",urlencode($item)).'"');
			header('Cache-Control: must-revalidate, post-check=0, pre-check=0');
			header('Pragma: public');
		} else {
			header('Content-Disposition: attachment; filename="'.$item.'"');
			header('Cache-Control: no-cache, must-revalidate');
			header('Pragma: no-cache');
		}
		@set_time_limit( 0 );
		@readFileChunked(cutf8_decode($abs_item));
		
		if( $unlink==true ) {
		  	unlink( cutf8_decode($abs_item) );
		}
	    ob_end_flush();
		ext_exit();
	}
}
//------------------------------------------------------------------------------
?>
