<?php
// ensure this file is being included by a parent file
if( !defined( '_JEXEC' ) && !defined( '_VALID_MOS' ) ) die( 'Restricted access' );
/**
 * @version $Id: search.php 98 2008-02-11 17:56:04Z soeren $
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
 * File-Search Functions
 */

function find_item($dir,$pat,&$list,$recur) {	// find items
	$homedir = ($GLOBALS["realpath"]==1) ? realpath($GLOBALS['home_dir']) : $GLOBALS['home_dir'];
	$handle = @$GLOBALS['ext_File']->opendir(get_abs_dir($dir));
	//printf("1 Kevin handle=%s dir=%s abs_dir=%s\n",$handle,$dir,get_abs_dir($dir));
	
	if($handle===false && $dir=="") {
	  	$handle = @$GLOBALS['ext_File']->opendir($homedir . $GLOBALS['separator']);
	//printf("2 Kevin handle=%s dir=%s \n",$handle,$dir);
	}
	if($handle===false) {
		ext_Result::sendResult('search', false, $dir.": ".$GLOBALS["error_msg"]["opendir"]);
	}
	
	while(($new_item=$GLOBALS['ext_File']->readdir($handle))!==false) {
		if( is_array( $new_item ))  {
			$abs_new_item = $new_item;
			//printf("A Kevin loop in \n");
			//print_r($new_item);
		} else {
			$abs_new_item = get_abs_item($dir, $new_item);
			//printf("B Kevin loop in \n");
			//printf("abs_new_item=%s \n",$abs_new_item);
		}
		if(!$GLOBALS['ext_File']->file_exists($abs_new_item)) continue;
		//printf("A Kevin loop in get_show_item($dir, $new_item)=%s\n",get_show_item($dir, $new_item));
		if(!get_show_item($dir, $new_item)) continue;
		// match?
		//printf("B Kevin loop in pat=%s new_item=%s \n",$pat,$new_item);
		if(@eregi($pat,$new_item)) {
			$list[]=array($dir,$new_item);
			//printf("B Kevin loop in new_item=%s \n",$new_item);
		}
		//printf("B Kevin loop in \n");
		
		// search sub-directories
		if(get_is_dir($abs_new_item) && $recur) {
			find_item(get_rel_item($dir,$new_item),$pat,$list,$recur);
		}
		//printf("C Kevin loop in \n");
	}
	//printf("C Kevin loop in \n");
	$GLOBALS['ext_File']->closedir($handle);
	
}
//------------------------------------------------------------------------------
function make_list($dir,$item,$subdir) {	// make list of found items
	// convert shell-wildcards to PCRE Regex Syntax
	$pat="^".str_replace("?",".",str_replace("*",".*",str_replace(".","\.",$item))).".*$";
	
	// search
	find_item($dir,$pat,$list,$subdir);
	if(is_array($list)) sort($list);
	return $list;
}
//------------------------------------------------------------------------------
function get_result_table($list) {			// print table of found items
	if(!is_array($list)) return;
	
	$cnt = count($list);
	$response = '';
	for($i=0;$i<$cnt;++$i) {
		$dir = $list[$i][0];	$item = $list[$i][1];
		$s_dir=$dir;	if(strlen($s_dir)>65) $s_dir=substr($s_dir,0,62)."...";
		$s_item=$item;	if(strlen($s_item)>45) $s_item=substr($s_item,0,42)."...";
		$link = "";	$target = "";
		
		if(get_is_dir($dir,$item)) {
			$img = "dir.png";
			$link = make_link("list",get_rel_item($dir, $item),NULL);
		} else {
			$img = get_mime_type( $item, "img");
			//if(get_is_editable($dir,$item) || get_is_image($dir,$item)) {
			$link = $GLOBALS["home_url"]."/".get_rel_item($dir, $item);
			$target = "_blank";
			//}
		}
		
		$response .= "<tr><td>" . "<img border=\"0\" width=\"22\" height=\"22\" ";
		$response .= "align=\"absmiddle\" src=\""._EXT_URL."/images/" . $img . "\" alt=\"\" />&nbsp;";
		/*if($link!="")*/ 
		//$response .= "<a href=\"".$link."\" target=\"".$target."\">";
		$response .= "<a href=\"" . make_link("list",$dir,null)."\">";
		//else echo "<a>";
		$response .= $s_item."</a></td><td><a href=\"" . make_link("list",$dir,null)."\"> /";
		$response .= $s_dir."</a></td></tr>\n";
	}
	return $response;
}
//------------------------------------------------------------------------------
function search_items($dir) {			// search for item
	if(isset($GLOBALS['__POST']["searchitem"])) {
		$searchitem=stripslashes($GLOBALS['__POST']["searchitem"]);
		$subdir= !empty( $GLOBALS['__POST']["subdir"] );
		$list=make_list($dir,"*".$searchitem,$subdir);
	} else {
		$searchitem=NULL;
		$subdir=true;
	}
	//print_r($list);
	
	if(!empty($searchitem)) {
		$msg=$GLOBALS["messages"]["actsearchresults"];
		$msg.=": (/" . get_rel_item($dir, $searchitem).")";
	} else {
		$msg = $GLOBALS["messages"]["searchlink"];
	}
	
	// Search Box
	$response = '		<div>
	    <div class="x-box-tl"><div class="x-box-tr"><div class="x-box-tc"></div></div></div>
	    <div class="x-box-ml"><div class="x-box-mr"><div class="x-box-mc">
	
	        <h3 style="margin-bottom:5px;">'.$msg.'</h3>
	        <div id="adminForm">
	
	        </div>
	    </div></div></div>
	    <div class="x-box-bl"><div class="x-box-br"><div class="x-box-bc"></div></div></div>
	</div>
	<script type="text/javascript">
	var form = new Ext.form.Form({
	    labelWidth: 125, // label settings here cascade unless overridden
	    url:"'. gbasename( $GLOBALS['script_name']) .'"
	});
	form.add(
	    new Ext.form.TextField({
	        fieldLabel: "'. ext_Lang::msg( 'nameheader', true ) .'",
	        name: "searchitem",
	        width:175,
	        allowBlank:false
	    }),
		new Ext.form.Checkbox({
			fieldLabel: "'.ext_Lang::msg( 'miscsubdirs', true ) .'?",
			name: "subdir",
			checked: true
		})
	);
	form.addButton({ text: "'.ext_Lang::msg( 'btnsearch', true ).'", type: "submit" }, function() {
	    form.submit({
	        waitMsg: "'.ext_Lang::msg('search_processing', true ).'",
	        //reset: true,
	        reset: false,
	        success: function(form, action) {
	    		dialog_panel.setContent( action.result.message, true );
	        },
	        failure: function(form, action) {Ext.MessageBox.alert("'.ext_Lang::err('error').'!", action.result.error);},
	        scope: form,
	        // add some vars to the request, similar to hidden fields
	        params: {
	        	option: "com_extplorer", 
	        	action: "search", 
	        	dir: "'.$GLOBALS['__POST']["dir"] .'"
	        }
	    });
	});
	form.addButton("'. ext_Lang::msg( 'btncancel', true ) .'", function() { dialog.hide();dialog.destroy(); } );

	form.render("adminForm");
	</script>';

	// Results
	if($searchitem!=NULL) {
		$response .= "<div class=\"scroll\">";
		$response .= "<table width=\"95%\"><tr><td colspan=\"2\"><hr></td></tr>\n";
		if(count($list)>0) {
			// table header
			$response .= "<tr>\n<td width=\"42%\" class=\"header\"><b>".$GLOBALS["messages"]["nameheader"];
			$response .= "</b></td>\n<td width=\"58%\" class=\"header\"><b>".$GLOBALS["messages"]["pathheader"];
			$response .= "</b></td></tr>\n<tr><td colspan=\"2\"><hr></td></tr>\n";
	
			// make & print table of found items
			$response .= get_result_table($list);

			$response .= "<tr><td colspan=\"2\"><hr></td></tr>\n<tr><td class=\"header\">".count($list)." ";
			$response .= $GLOBALS["messages"]["miscitems"].".</td><td class=\"header\"></td></tr>\n";
		} else {
			$response .= "<tr><td>".$GLOBALS["messages"]["miscnoresult"]."</td></tr>";
		}
		$response .= "<tr><td colspan=\"2\"><hr></td></tr></table>\n";
		$response .= "</div>";
	}
	if( empty( $searchitem ) && $searchitem!='0' ) {
		echo $response;
	} else {
		while( @ob_end_clean() );
		ext_Result::sendResult('search', true, $response );
	}

}
//------------------------------------------------------------------------------
?>
