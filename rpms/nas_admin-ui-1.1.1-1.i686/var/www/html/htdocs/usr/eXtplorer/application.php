<?php
// ensure this file is being included by a parent file
if( !defined( '_JEXEC' ) && !defined( '_VALID_MOS' ) ) die( 'Restricted access' );
/**
 * @package eXtplorer
 * @copyright soeren 2007
 * @author The eXtplorer project (http://sourceforge.net/projects/extplorer)
 * @license
 * The contents of this file are subject to the Mozilla Public License
 * Version 1.1 (the "License"); you may not use this file except in
 * compliance with the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 * 
 * Software distributed under the License is distributed on an "AS IS"
 * basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
 * License for the specific language governing rights and limitations
 * under the License',
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
 * Abstract Action Class
 * @abstract 
 */
class ext_Action {
	
	/**
	 * This function executes the action
	 *
	 * @param string $dir
	 * @param string $item
	 */
	function execAction( $dir, $item ) {
		// to be overridden by the child class
	}
	
}
/**
 * Wrapper Class for the Global Language Array
 * @since 2.0.0
 * @author soeren
 *
 */
class ext_Lang {
	/**
	 * Returns a string from $GLOBALS['messages']
	 *
	 * @param string $msg
	 * @param boolean $make_javascript_safe
	 * @return string
	 */
	function msg( $msg, $make_javascript_safe=false ) {
		$str = ext_Lang::_get('messages', $msg );
		if( $make_javascript_safe ) {
			return ext_Lang::escape_for_javascript( $str );
		} else {
			return $str;
		}
	}
	/**
	 * Returns a string from $GLOBALS['error_msg']
	 *
	 * @param string $err
	 * @param boolean $make_javascript_safe
	 * @return string
	 */
	function err( $err, $make_javascript_safe=false ) {
		$str = ext_Lang::_get('error_msg', $err );
		if( $make_javascript_safe ) {
			return ext_Lang::escape_for_javascript( $str );
		} else {
			return $str;
		}
	}
	function mime( $mime, $make_javascript_safe=false ) {
		$str = ext_Lang::_get('mimes', $mime );
		if( $make_javascript_safe ) {
			return ext_Lang::escape_for_javascript( $str );
		} else {
			return $str;
		}
	}
	/**
	 * Gets the string from the array
	 *
	 * @param string $array_index
	 * @param string $message
	 * @return string
	 * @access private
	 */
	function _get( $array_index, $message ) {
		if( is_array( $message )) {
			return @$GLOBALS[$array_index][key($message)][current($message)];
		}
		return @$GLOBALS[$array_index][$message];
	}
	
	function escape_for_javascript( $string ) {
		return str_replace(Array("\r", "\n" ), Array('\r', '\n' ) , addslashes($string));
	}
	function detect_lang() {
		$default = 'english';
		if( empty($_SERVER['HTTP_ACCEPT_LANGUAGE'])) return $default;
		
		 $_AL=strtolower($_SERVER['HTTP_ACCEPT_LANGUAGE']);
		 $_UA=strtolower($_SERVER['HTTP_USER_AGENT']);
		 
		 //print_r($_SERVER);
		 
		 // Try to detect Primary language if several languages are accepted',
		 //foreach($GLOBALS['_LANG'] as $K => $lang) {
		 foreach($GLOBALS['_LANG'] as $itemData) {
		  if(strpos($_AL, $itemData["key"])===0) {
		  	//printf("lang=%s <br>_AL=%s <br> K=%s <br>",$lang,$_AL,$K);
		   	return file_exists( _EXT_PATH.'/languages/'.$itemData["keyname"].'.php' ) ? $itemData["keyname"] : $default;
		  }
		 }
		 
		 // Try to detect any language if not yet detected',
		 //foreach($GLOBALS['_LANG'] as $K => $lang) {
		 foreach($GLOBALS['_LANG'] as $itemData) {
		  if(strpos($_AL, $itemData["key"])!==false)
		   return file_exists( _EXT_PATH.'/languages/'.$itemData["keyname"].'.php' ) ? $itemData["keyname"] : $default;
		 }
		 //foreach($GLOBALS['_LANG'] as $K => $lang) {
		 foreach($GLOBALS['_LANG'] as $itemData) {
		  if(preg_match("/[\[\( ]{$K}[;,_\-\)]/",$_UA))
		   return file_exists( _EXT_PATH.'/languages/'.$itemData["keyname"].'.php' ) ? $lang : $default;
		 }
		 
		 // Return default language if language is not yet detected',
		 return $default;
	}
}
// Define all available languages',
// WARNING: uncomment all available languages

$GLOBALS['_LANG'] = array(
//array('key' => 'af', 'keyname' => 'afrikaans', 'showname' => 'afrikaans'),
//array('key' => 'ar', 'keyname' => 'arabic', 'showname' => 'arabic'),
//array('key' => 'bg', 'keyname' => 'bulgarian', 'showname' => 'bulgarian'),
//array('key' => 'ca', 'keyname' => 'catalan', 'showname' => 'catalan'),
//array('key' => 'cs', 'keyname' => 'czech', 'showname' => 'czech'),
//array('key' => 'da', 'keyname' => 'danish', 'showname' => 'danish'),
array('key' => 'de', 'keyname' => 'german', 'showname' => 'Deutsch'),
//array('key' => 'el', 'keyname' => 'greek', 'showname' => 'greek'),
array('key' => 'en', 'keyname' => 'english', 'showname' => 'English'),
array('key' => 'es', 'keyname' => 'spanish', 'showname' => 'Spanish'),
//array('key' => 'et', 'keyname' => 'estonian', 'showname' => 'estonian'),
//array('key' => 'fi', 'keyname' => 'finnish', 'showname' => 'finnish'),
array('key' => 'fr', 'keyname' => 'french', 'showname' => 'Français'),
//array('key' => 'gl', 'keyname' => 'galician', 'showname' => 'galician'),
//array('key' => 'he', 'keyname' => 'hebrew', 'showname' => 'hebrew'),
//array('key' => 'hi', 'keyname' => 'hindi', 'showname' => 'hindi'),
//array('key' => 'hr', 'keyname' => 'croatian', 'showname' => 'croatian'),
//array('key' => 'hu', 'keyname' => 'hungarian', 'showname' => 'hungarian'),
//array('key' => 'id', 'keyname' => 'indonesian', 'showname' => 'indonesian'),
array('key' => 'it', 'keyname' => 'italian', 'showname' => 'Italiano'),
array('key' => 'ja', 'keyname' => 'japanese', 'showname' => 'Japanese'),
array('key' => 'ko', 'keyname' => 'korean', 'showname' => 'Korean'),
//array('key' => 'ka', 'keyname' => 'georgian', 'showname' => 'georgian'),
//array('key' => 'lt', 'keyname' => 'lithuanian', 'showname' => 'lithuanian'),
//array('key' => 'lv', 'keyname' => 'latvian', 'showname' => 'latvian'),
//array('key' => 'ms', 'keyname' => 'malay', 'showname' => 'malay'),
//array('key' => 'nl', 'keyname' => 'dutch', 'showname' => 'dutch'),
//array('key' => 'no', 'keyname' => 'norwegian', 'showname' => 'norwegian'),
array('key' => 'pl', 'keyname' => 'polish', 'showname' => 'Polish'),
array('key' => 'pt', 'keyname' => 'portuguese', 'showname' => 'Portugal'),
//array('key' => 'ro', 'keyname' => 'romanian', 'showname' => 'romanian'),
array('key' => 'ru', 'keyname' => 'russian', 'showname' => 'Russia'),
//array('key' => 'sk', 'keyname' => 'slovak', 'showname' => 'slovak'),
//array('key' => 'sl', 'keyname' => 'slovenian', 'showname' => 'slovenian'),
//array('key' => 'sq', 'keyname' => 'albanian', 'showname' => 'albanian'),
//array('key' => 'sr', 'keyname' => 'serbian', 'showname' => 'serbian'),
//array('key' => 'sv', 'keyname' => 'swedish', 'showname' => 'swedish'),
//array('key' => 'th', 'keyname' => 'thai', 'showname' => 'thai'),
//array('key' => 'tr', 'keyname' => 'turkish', 'showname' => 'turkish'),
//array('key' => 'uk', 'keyname' => 'ukrainian', 'showname' => 'ukrainian'),
array('key' => 'zh-tw', 'keyname' => 'traditional_chinese', 'showname' => 'Traditional Chinese'),
//array('key' => 'tw', 'keyname' => 'traditional_chinese', 'showname' => 'Traditional Chinese'),
array('key' => 'zh', 'keyname' => 'simplified_chinese', 'showname' => 'Simplified Chinese')
);
