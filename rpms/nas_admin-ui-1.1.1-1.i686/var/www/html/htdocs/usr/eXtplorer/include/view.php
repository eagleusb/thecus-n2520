<?php
// ensure this file is being included by a parent file
if( !defined( '_JEXEC' ) && !defined( '_VALID_MOS' ) ) die( 'Restricted access' );
/**
 * @version $Id: view.php 96 2008-02-03 18:13:22Z soeren $
 * @package eXtplorer
 * @copyright soeren 2007
 * @author The eXtplorer project (http://sourceforge.net/projects/extplorer)
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
 */

/**
 * Allows to view sourcecode (formatted by GeSHi or unformatted) and images
 *
 */
class ext_View extends ext_Action {
	
	function execAction($dir, $item) {		// show file contents
	
		echo '<div>
    <div class="x-box-tl"><div class="x-box-tr"><div class="x-box-tc"></div></div></div>
    <div class="x-box-ml"><div class="x-box-mr"><div class="x-box-mc">
	<h3 style="margin-bottom:5px;">'.$GLOBALS["messages"]["actview"].": ".$item.'</h3>';
       echo '</div></div></div>
	    <div class="x-box-bl"><div class="x-box-br"><div class="x-box-bc"></div></div></div>
	</div><hr />';
		/*$index2_edit_link = str_replace('/index3.php', '/index2.php', make_link('edit', $dir, $item ));
		echo '<a name="top" class="componentheading" href="javascript:window.close();">[ '._PROMPT_CLOSE.' ]</a>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
		$abs_item = get_abs_item($dir, $item);
		if( get_is_editable( $abs_item) && $GLOBALS['ext_File']->is_writable( $abs_item )) {
			// Edit the file in the PopUp
			echo '<a class="componentheading" href="'.make_link('edit', $dir, $item ).'&amp;return_to='.urlencode($_SERVER['PHP_SELF'].'?'.$_SERVER['QUERY_STRING'] ).'">[ '.$GLOBALS["messages"]["editlink"].' ]</a>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
			// Edit the file in the parent window
			//echo '<a class="componentheading" href="javascript:opener.location=\''.$index2_edit_link.'\'; window.close();">[ '.$GLOBALS["messages"]["editlink"].' ]</a>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
		}
		echo '<a class="componentheading" href="#bottom">[ '._CMN_BOTTOM.' ]</a>';
		
		echo '<br /><br />';
		*/
		
		if( @eregi($GLOBALS["images_ext"], $item)) {
			echo '<img src="'.make_link( 'get_image', $dir, rawurlencode($item)).'" alt="'.$GLOBALS["messages"]["actview"].": ".$item.'" /><br /><br />';
		}
		
		else {
			
			$geshiFile = _EXT_PATH . '/libraries/geshi/geshi.php';
			
			if( file_exists( $geshiFile )) {
				ext_RaiseMemoryLimit('32M'); // GeSHi 1.0.7 is very memory-intensive
				include_once( $geshiFile );
				// Create the GeSHi object that renders our source beautiful
				$geshi = new GeSHi( '', '', dirname( $geshiFile ).'/geshi' );
				$file = get_abs_item($dir, $item);
				$pathinfo = pathinfo( $file );
				if( ext_isFTPMode() ) {
					$file = ext_ftp_make_local_copy( $file );
				}
				if( is_callable( array( $geshi, 'load_from_file'))) {
					$geshi->load_from_file( $file );
				}
				else {
					$geshi->set_source( file_get_contents( $file ));
				}
				if( is_callable( array($geshi,'getlanguagesuage_name_from_extension'))) {
					$lang = $geshi->getlanguagesuage_name_from_extension( $pathinfo['extension'] );
				}
				else {
					$pathinfo = pathinfo($item);
					$lang = $pathinfo['extension'];
				}
				
				$geshi->set_language( $lang );
				$geshi->enable_line_numbers( GESHI_NORMAL_LINE_NUMBERS );
			
				$text = $geshi->parse_code();
				
				if( ext_isFTPMode() ) {
					unlink( $file );
				}
				echo $text;
				echo '<hr /><div style="line-height:25px;vertical-align:middle;text-align:center;" class="small">Rendering Time: <strong>'.$geshi->get_time().' Sec.</strong></div>';
			}
			else {
				// When GeSHi is not available, just display the plain file contents
				echo '<div class="quote" style="text-align:left;">'
					.nl2br( htmlentities(  $GLOBALS['ext_File']->file_get_contents(get_abs_item($dir, $item) )))
					.'</div>';
			}
		}
		
		//echo '<a href="#top" name="bottom" class="componentheading">[ '._CMN_TOP.' ]</a><br /><br />';
	}
	function sendImage( $dir, $item ) {
		$abs_item = get_abs_item( $dir, $item );
		if( $GLOBALS['ext_File']->file_exists( $abs_item )) {
  			if(!@eregi($GLOBALS["images_ext"], $item)) return;
  			while( @ob_end_clean() );
  			
  			$pathinfo = pathinfo( $item );
			switch(strtolower($pathinfo['extension'])) {
				case "gif":
					header ("Content-type: image/gif");
					break;
				case "jpg":
				case "jpeg":
					header ("Content-type: image/jpeg");
					break;
				case "png":
					header ("Content-type: image/png");
		  			break;
	  		}
	  		
			echo $GLOBALS['ext_File']->file_get_contents( $abs_item );
			
		}
		exit;
	}
}
?>