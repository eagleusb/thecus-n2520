<?php
// ensure this file is being included by a parent file
if( !defined( '_JEXEC' ) && !defined( '_VALID_MOS' ) ) die( 'Restricted access' );
/**
 * @version $Id: rename.php 96 2008-02-03 18:13:22Z soeren $
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
 * Allows to rename files and dirs
 *
 */
class ext_Rename extends ext_Action {
	
	function execAction($dir, $item) {		// rename directory or file
	
		if(($GLOBALS["permissions"]&01)!=01) {
			ext_Result::sendResult('rename', false, $GLOBALS["error_msg"]["accessfunc"]);
		}
		
		if(isset($GLOBALS['__POST']["confirm"]) && $GLOBALS['__POST']["confirm"]=="true") {
			
			$newitemname=$GLOBALS['__POST']["newitemname"];
			$newitemname=trim(gbasename(stripslashes($newitemname)));
			
			if($newitemname=='' ) {
				ext_Result::sendResult('rename', false, $GLOBALS["error_msg"]["miscnoname"]);
			}
			if( !ext_isFTPMode()) {
				$abs_old = get_abs_item($dir,$item);
				$abs_new = get_abs_item($dir,$newitemname);
			} else {
				$abs_old = get_item_info($dir,$item);
				$abs_new = get_item_info($dir,$newitemname);
			}
			
			if(@$GLOBALS['ext_File']->file_exists($abs_new)) {
				ext_Result::sendResult('rename', false, $newitemname.": ".$GLOBALS["error_msg"]["itemdoesexist"]);
			}
			$perms_old = $GLOBALS['ext_File']->fileperms( $abs_old );
			
			$ok=$GLOBALS['ext_File']->rename( get_abs_item($dir,$item), get_abs_item($dir,$newitemname) );
			if( ext_isFTPMode()) {
				$abs_new = get_item_info($dir,$newitemname);
			}
			
			/**
			* When get a filesize > 2GB , parms function will fail, so I markup it.
			* Modify by Heidi Date: 2010-07-14 
			*/ 
			//$GLOBALS['ext_File']->chmod( $abs_new, $perms_old );
			
			if($ok===false || PEAR::isError($ok)) {
				ext_Result::sendResult('rename', false, 'Could not rename '.$dir.'/'.$item.' to '.$newitemname);
			}
			
			$msg = sprintf( $GLOBALS['messages']['success_rename_file'], $item, $newitemname );
			
			ext_Result::sendResult('rename', true, $msg );
		}
		$is_dir = get_is_dir(ext_isFTPMode() ? get_item_info($dir,$item) : get_abs_item($dir,$item));
	
	?>
	<div style="width:auto;">
	    <div class="x-box-tl"><div class="x-box-tr"><div class="x-box-tc"></div></div></div>
	    <div class="x-box-ml"><div class="x-box-mr"><div class="x-box-mc">
	
	        <h3 style="margin-bottom:5px;"><?php echo $GLOBALS['messages']['rename_file'] ?></h3>
	        <div id="adminForm">
	
	        </div>
	    </div></div></div>
	    <div class="x-box-bl"><div class="x-box-br"><div class="x-box-bc"></div></div></div>
	</div>
	<script type="text/javascript">
	var simple = new Ext.form.Form({
	    labelWidth: 75, // label settings here cascade unless overridden
	    url:'<?php echo gbasename( $GLOBALS['script_name']) ?>'
	});
	simple.add(
	    new Ext.form.TextField({
	        fieldLabel: '<?php echo ext_Lang::msg( 'newname', true ) ?>',
	        name: 'newitemname',
	        value: '<?php echo str_replace("'", "\'", stripslashes($item) ) ?>',
	        width:175,
	        allowBlank:false
	    })
	    );
	
	simple.addButton('<?php echo ext_Lang::msg( 'btnsave', true ) ?>', function() {
		statusBarMessage( 'Please wait...', true );
	    simple.submit({
	        //reset: true,
	        reset: false,
	        success: function(form, action) {
	        	<?php 
	        	if( $is_dir ) {
	        		?>
	        		parentDir = dirTree.getSelectionModel().getSelectedNode().parentNode;
	        		parentDir.reload();
	        		parentDir.select();
	    		<?php 
	        	} else {
		    		?>
		    		datastore.reload();
		        	<?php 
	        	}
	    		?>
	    		statusBarMessage( action.result.message, false, true );
	        	dialog.destroy();
	        },
	        failure: function(form, action) {	        	
	        	if( !action.result ) return;
	        	Ext.MessageBox.alert('Error!', action.result.error);
	        	statusBarMessage( action.result.error, false, false );
	        },
	        scope: simple,
	        // add some vars to the request, similar to hidden fields
	        params: {option: 'com_extplorer', 
	        		action: 'rename', 
	        		dir: '<?php echo stripslashes($dir) ?>', 
	        		item: '<?php echo stripslashes($item) ?>', 
	        		confirm: 'true'}
	    });
	});
	simple.addButton('<?php echo ext_Lang::msg( 'btncancel', true ) ?>', function() { dialog.destroy(); } );
	simple.render('adminForm');
	</script>
	<?php
	
	}
}
?>
