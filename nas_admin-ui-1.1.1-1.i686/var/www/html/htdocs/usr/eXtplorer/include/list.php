<?php
// ensure this file is being included by a parent file
if( !defined( '_JEXEC' ) && !defined( '_VALID_MOS' ) ) die( 'Restricted access' );
/**
 * @version $Id: list.php 105 2008-05-31 13:38:38Z soeren $
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
 * Directory-Listing Functions
 */
//------------------------------------------------------------------------------
// HELPER FUNCTIONS (USED BY MAIN FUNCTION 'list_dir', SEE BOTTOM)
function make_list(&$_list1, &$_list2) {		// make list of files
	$list = array();

	if($GLOBALS["direction"]=="ASC") {
		$list1 = $_list1;
		$list2 = $_list2;
	} else {
		$list1 = $_list2;
		$list2 = $_list1;
	}
	
	if(is_array($list1)) {
		while (list($key, $val) = each($list1)) {
			$list[$key] = $val;
		}
	}
	
	if(is_array($list2)) {
		while (list($key, $val) = each($list2)) {
			$list[$key] = $val;
		}
	}
	
	return $list;
}

/**
 * make tables & place results in reference-variables passed to function
 * also 'return' total filesize & total number of items
 *
 * @param string $dir
 * @param array $dir_list
 * @param array $file_list
 * @param int $tot_file_size
 * @param int $num_items
 */
function get_dircontents($dir, &$dir_list, &$file_list, &$tot_file_size, &$num_items) {						// make table of files in dir

	$homedir = ($GLOBALS["realpath"]==1) ? realpath($GLOBALS['home_dir']) : $GLOBALS['home_dir'];
	$tot_file_size = $num_items = 0;
	// Open directory
	$handle = @$GLOBALS['ext_File']->opendir(get_abs_dir($dir));
	if($handle===false && $dir=="") {
	  	$handle = @$GLOBALS['ext_File']->opendir($homedir . $GLOBALS['separator']);
	}
	if($handle===false) {
		ext_Result::sendResult('list', false, $dir.": ".$GLOBALS["error_msg"]["opendir"]);
	}
	$file_list = array();
	$dir_list = array();
	// Read directory
	while(($new_item = @$GLOBALS['ext_File']->readdir($handle))!==false) {
		
		if( is_array( $new_item ))  {
			$abs_new_item = $new_item;
		} else {
			$abs_new_item = get_abs_item($dir, $new_item);
		}
		if ($new_item == "." || $new_item == "..") continue;
		
		// modify by heidi
		// skip symbolic link directory
		if($dir!="" && is_link($abs_new_item) && readlink($abs_new_item)){
			continue;
		}
		
		if(!@$GLOBALS['ext_File']->file_exists($abs_new_item)) {
			//ext_Result::sendResult( 'list', false, $dir."/$abs_new_item: ".$GLOBALS["error_msg"]["readdir"]);
		}
		if(!get_show_item($dir, $new_item)) continue;		

		$new_file_size = @$GLOBALS['ext_File']->filesize($abs_new_item);
		$tot_file_size += $new_file_size;
		$num_items++;

		$new_item_name = $new_item;
		if( ext_isFTPMode() ) {
			$new_item_name = $new_item['name'];
		}
		if(get_is_dir( $abs_new_item)) {
			
			if($GLOBALS["order"]=="modified") {
				$dir_list[$new_item_name] =
					@$GLOBALS['ext_File']->filemtime($abs_new_item);
			} else {	// order == "size", "type" or "name"
				//Check ACL first
				if (getReadPermission($_SESSION['s_user'],$_SESSION['s_gid'],$abs_new_item)) {
					$dir_list[$new_item_name] = $new_item;
				}
			}
		} else {
			if($GLOBALS["order"]=="size") {
				$file_list[$new_item_name] = $new_file_size;
			} elseif($GLOBALS["order"]=="modified") {
				$file_list[$new_item_name] =
					@$GLOBALS['ext_File']->filemtime($abs_new_item);
			} elseif($GLOBALS["order"]=="type") {
				$file_list[$new_item_name] =
					get_mime_type( $abs_new_item, "type");
			} else {	// order == "name"
				//if (getReadPermission($_SESSION['s_user'],$_SESSION['s_gid'],$abs_new_item)) {
					$file_list[$new_item_name] = $new_item;
				//}
			}
		}
	}
	
	@$GLOBALS['ext_File']->closedir($handle);
	
	//printf("dir list ...\n");
	//print_r($dir_list);
	// sort
	if(is_array($dir_list)) {
		if($GLOBALS["order"]=="modified") {
			if($GLOBALS["direction"]=="ASC") arsort($dir_list);
			else asort($dir_list);
		} else {	// order == "size", "type" or "name"
			if($GLOBALS["direction"]=="ASC") ksort($dir_list);
			else krsort($dir_list);
		}
	}
	
	// sort
	if(is_array($file_list)) {
		if($GLOBALS["order"]=="modified") {
			if($GLOBALS["direction"]=="ASC") arsort($file_list);
			else asort($file_list);
		} elseif($GLOBALS["order"]=="size" || $GLOBALS["order"]=="type") {
			if($GLOBALS["direction"]=="ASC") asort($file_list);
			else arsort($file_list);
		} else {	// order == "name"
			if($GLOBALS["direction"]=="ASC") ksort($file_list);
			else krsort($file_list);
		}
	}
	if( $GLOBALS['start'] > $num_items ) {
		$GLOBALS['start'] = 0;
	}

}
/**
 * This function assembles an array (list) of files or directories in the directory specified by $dir
 * The result array is send using JSON
 *
 * @param string $dir
 * @param string $sendWhat Can be "files" or "dirs"
 */
function send_dircontents($dir, $sendWhat='files') {	// print table of files
	global $dir_up, $mainframe;
	
	// make file & dir tables, & get total filesize & number of items
	get_dircontents($dir, $dir_list, $file_list, $tot_file_size, $num_items);
	if( $sendWhat == 'files') {
		$list = $file_list;
	} elseif( $sendWhat == 'dirs') {
		$list = $dir_list;
	} else {
		$list = make_list( $dir_list, $file_list );
	}
	
	$i = 0;
	$items['totalCount'] = count($list);
	$items['items'] = array();
	$dirlist = array();
	
	if( $sendWhat != 'dirs' ) {
		// Replaced array_splice, because it resets numeric indexes (like files or dirs with a numeric name)
		// Here we reduce the list to the range of $limit beginning at $start 
		$a = 0;
		$output_array = array();
		foreach( $list as $key => $value ) {
			if( $a >= $GLOBALS['start'] && ($a - $GLOBALS['start'] < $GLOBALS['limit'] )) {
				$output_array[$key] = $value;
			}
			$a++;
		}
		$list = $output_array;
	}
	
	while(list($item,$info) = each($list)) {
		// link to dir / file
		if( is_array( $info )) {
			$abs_item=$info;
			if( extension_loaded('posix')) {
				$user_info = posix_getpwnam( $info['user']);
				$file_info['uid'] = $user_info['uid'];
				$file_info['gid'] = $user_info['gid'];
			}
		} else {
			$abs_item=get_abs_item(cutf8_decode($dir), $item);
			$file_info = @stat( $abs_item );
		}
		$is_dir = get_is_dir($abs_item);
		
		$items['items'][$i]['name'] = ext_isFTPMode() ? $item : cutf8_encode($item);
		$items['items'][$i]['is_file'] = get_is_file($abs_item);
		$items['items'][$i]['is_archive'] = ext_isArchive( $item ) && !ext_isFTPMode();
		$items['items'][$i]['is_writable'] = $is_writable = @$GLOBALS['ext_File']->is_writable( $abs_item );
		$items['items'][$i]['is_chmodable'] = $is_chmodable = @$GLOBALS['ext_File']->is_chmodable( $abs_item );
		$items['items'][$i]['is_readable'] = $is_readable =@$GLOBALS['ext_File']->is_readable( $abs_item );
		$items['items'][$i]['is_deletable'] = $is_deletable = @$GLOBALS['ext_File']->is_deletable( $abs_item );
		$items['items'][$i]['is_editable'] = get_is_editable($abs_item);
		
		$items['items'][$i]['icon'] = _EXT_URL."/images/".get_mime_type($abs_item, "img");
		$items['items'][$i]['size'] = parse_file_size(get_file_size( $abs_item));
	// type
		$items['items'][$i]['type'] = get_mime_type( $abs_item, "type");
	// modified
		$items['items'][$i]['modified'] = parse_file_date( get_file_date($abs_item) );
	// permissions
		$perms = get_file_perms( $abs_item );
		if( strlen($perms)>3) {
			$perms = substr( $perms, 2 );
		}
		$items['items'][$i]['perms'] = $perms. ' ('. parse_file_perms( $perms ).')';
			
		if( extension_loaded( "posix" )) {
			$user_info = posix_getpwuid( $file_info["uid"] );
			//$group_info = posix_getgrgid($file_info["gid"] );
			$items['items'][$i]['owner'] = $user_info["name"]. " (".$file_info["uid"].")";
		} else {
			$items['items'][$i]['owner'] = 'n/a';
		}
		if( $is_dir && $sendWhat != 'files') {

			$id = str_replace('/', $GLOBALS['separator'], $dir). $GLOBALS['separator'].$item;
			$id = str_replace( $GLOBALS['separator'], '_RRR_', $id );

			$qtip ="<strong>".ext_Lang::mime('dir',true)."</strong><br /><strong>".ext_Lang::msg('miscperms',true).":</strong> ".$perms."<br />";
			$qtip.='<strong>'.ext_Lang::msg('miscowner',true).':</strong> '.$items['items'][$i]['owner'];
			$dirlist[] = array('text' => htmlspecialchars(ext_isFTPMode() ? $item : cutf8_encode($item)),
								'id' => ext_isFTPMode() ? $id : cutf8_encode($id),
								//'qtip' => $qtip,
								'is_writable' => $is_writable,
								'is_chmodable' => $is_chmodable,
								'is_readable' => $is_readable,
								'is_deletable' => $is_deletable,
								'file_level' => getFileLevel($abs_item),
								'cls' => 'folder');
		}
		if( !$is_dir && $sendWhat == 'files' || $sendWhat == 'both') {
			$i++;
		}
	}
	while( @ob_end_clean() );
	
	if( $sendWhat == 'dirs') {
		$result = $dirlist;
	} else {
		$result = $items;
	}
	$json = new ext_Json();
	echo $json->encode( $result );
	
	ext_exit();
	
}
class ext_List extends ext_Action {
	
	function execAction($dir) {			// list directory contents
		global $dir_up, $mosConfig_live_site, $_VERSION;
		
		$allow=($GLOBALS["permissions"]&01)==01;
		$admin=((($GLOBALS["permissions"]&04)==04) || (($GLOBALS["permissions"]&02)==02));
		
		$dir_up = dirname($dir);
		if($dir_up==".") $dir_up = "";
		
		if(!get_show_item($dir_up,basename($dir))) {
			ext_Result::sendResult('list', false, $dir." : ".$GLOBALS["error_msg"]["accessdir"]);	
		}
		
		// Sorting of items
		if($GLOBALS["direction"]=="ASC") {
			$_srt = "no";
		} else {
			$_srt = "yes";
		}
		
		show_header();
		$scriptTag = '
		<script type="text/javascript" src="'. _EXT_URL . '/fetchscript.php?'
			.'&amp;subdir[]=scripts/editarea/&amp;file[]=edit_area_full_with_plugins.js'
			.'&amp;subdir[]=scripts/extjs/&amp;file[]=yui-utilities.js'
			.'&amp;subdir[]=scripts/extjs/&amp;file[]=ext-yui-adapter.js'
			.'&amp;subdir[]=scripts/extjs/&amp;file[]=ext-all.js&amp;gzip=1"></script>
		<script type="text/javascript" src="'. $GLOBALS['script_name'].'?option=com_extplorer&amp;action=include_javascript&amp;file=functions.js"></script>		
		<link rel="stylesheet" href="'. _EXT_URL . '/fetchscript.php?'.
		'subdir[0]=style/css/&file[0]=ext-all.css&amp;'.
		'subdir[1]=style/&file[1]=customer.css&amp;'.
		'gzip=1" />';
		
		if( defined( 'EXT_STANDALONE' )) {
			$GLOBALS['mainframe']->addcustomheadtag( $scriptTag );
		} else {
			echo $scriptTag;
		}
		?>
		<div id="dirtree"></div>
	<div id="dirtree-panel"></div>
	<div id="item-grid"></div>
	<div id="ext_statusbar" class="ext_statusbar"></div>
	
	<?php
		// That's the main javascript file to build the Layout & App Logic
		include( _EXT_PATH.'/scripts/application.js.php' );
		
	}

}
?>
