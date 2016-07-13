<?php
// ensure this file is being included by a parent file
if( !defined( '_JEXEC' ) && !defined( '_VALID_MOS' ) ) die( 'Restricted access' );
/**
 * @version $Id: result.class.php 104 2008-05-28 17:20:00Z soeren $
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
 */

/**
 * Allows to handle errors and send results in JSON format
 *
 */
class ext_Result {
	function init() {
		ext_Result::empty_errors();
		ext_Result::empty_messages();
	}
	function add_message($message, $type='general') {
		$_SESSION['ext_message'][$type][] = $message;
	}
	function empty_messages() {
		$_SESSION['ext_message'] = array();
	}
	function count_messages() {
		
		if( empty($_SESSION['ext_message'])) {
			return 0;
		}
		$count = 0;
		foreach( $_SESSION['ext_message'] as $type ) {
			if( !empty( $type ) && is_array( $type )) {
				$count += sizeof( $type );
			}
		}
		return $count;
	}
	function add_error($error, $type='general') {
		$_SESSION['ext_error'][$type][] = $error;
	}
	function empty_errors() {
		$_SESSION['ext_error'] = array();
	}
	function count_errors() {
		if( empty($_SESSION['ext_error'])) {
			return 0;
		}
		$count = 0;
		foreach( @$_SESSION['ext_error'] as $type ) {
			if( !empty( $type ) && is_array( $type )) {
				$count += sizeof( $type );
			}
		}
		return $count;
	}
	function sendResult( $action, $success, $msg,$extra=array() ) {		// show error-message
		
	//	if( ext_isXHR() ) {
			$success = (bool)$success;
			if( $success && ext_Result::count_errors() > 0 ) {
				$success = false;
				foreach( @$_SESSION['ext_error'] as $type ) {
					if( is_array( $type )) {
						foreach( $type as $error ) {
							$msg .= '<br >'.$error;
						}
					}
				}
			}
                        $msg=str_replace("'", "'",$msg);
			$result = array('action' => $action,
							//'message' => str_replace("'", "\\'", $msg ),
							'message' => str_replace("'", "'", $msg ),
							'error' => $msg,
                                                        'errormsg' => array('msg'=>$msg) ,
							'success' => $success 
						);
			foreach( $extra as $key => $value ) {
				$result[$key] = $value;
			}
			$json = new ext_Json();
			$jresult = $json->encode($result);
			print $jresult;
			die();
			ext_exit();
	//	}

		if($extra != NULL) {
			$msg .= " - ".$extra;
		}
		ext_Result::add_error( $msg );
		
		if( empty( $_GET['error'] )) {
			session_write_close();
			extRedirect( make_link("show_error", $GLOBALS["dir"], null, null, null, null, '&error=1&extra='.urlencode( $extra )) );
		}
		else {
			show_header($GLOBALS["error_msg"]["error"]);
			
			echo '<div class="quote">';
			echo '<a href="#errors">'.ext_Result::count_errors() .' '.$GLOBALS["error_msg"]["error"].'</a>, ';
			echo '<a href="#messages">'.ext_Result::count_messages() .' '.$GLOBALS["error_msg"]["message"].'</a><br />';
			echo "</div>\n";
			
			if( !empty( $_SESSION['ext_message'])) {
				echo "<a href=\"".str_replace('&dir=', '&ignore=', make_link("list", '' ))."\">[ "
						.$GLOBALS["error_msg"]["back"]." ]</a>";
						
				echo "<div class=\"ext_message\"><a name=\"messages\"></a>
						<h3>".$GLOBALS["error_msg"]["message"].":</strong>"."</h3>\n";
				
				foreach ( $_SESSION['ext_message'] as $msgtype ) {
					foreach ( $msgtype as $message ) {
						echo $message ."\n<br/>";
					}
					echo '<br /><hr /><br />';
				}
				ext_Result::empty_messages();
				
				if( !empty( $_REQUEST['extra'])) echo " - ".htmlspecialchars(urldecode($_REQUEST['extra']), ENT_QUOTES );
				echo "</div>\n";
			}
			
			if( !empty( $_SESSION['ext_error'])) {
				echo "<div class=\"ext_error\"><a name=\"errors\"></a>
						<h3>".$GLOBALS["error_msg"]["error"].":</strong>"."</h3>\n";
				
				foreach ( $_SESSION['ext_error'] as $errortype ) {
					foreach ( $errortype as $error ) {
						echo $error ."\n<br/>";
					}
					echo '<br /><hr /><br />';
				}
				ext_Result::empty_errors();
			}
			echo "<a href=\"".str_replace('&dir=', '&ignore=', make_link("list", '' ))."\">".$GLOBALS["error_msg"]["back"]."</a>";
			if( !empty( $_REQUEST['extra'])) echo " - ".htmlspecialchars(urldecode($_REQUEST['extra']), ENT_QUOTES );
			echo "</div>\n";
			defined('EXPLORER_NOEXEC') or define('EXPLORER_NOEXEC', 1 );
		}
	}
}
//------------------------------------------------------------------------------
?>
