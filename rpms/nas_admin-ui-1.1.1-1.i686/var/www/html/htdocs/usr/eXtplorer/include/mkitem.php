<?php
// ensure this file is being included by a parent file
if( !defined( '_JEXEC' ) && !defined( '_VALID_MOS' ) ) die( 'Restricted access' );
/**
 * @version $Id: mkitem.php 107 2008-07-22 17:27:12Z soeren $
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
 * Allows to create dirs, files and symlinks on a server
 *
 */
class ext_Mkitem extends ext_Action {
	
	function execAction($dir) {		// make new directory or file
		if(($GLOBALS["permissions"]&01)!=01) ext_Result::sendResult( 'mkitem', false, $GLOBALS["error_msg"]["accessfunc"]);
		
		if( extGetParam($_POST,'confirm') == 'true') {
			$mkname=$GLOBALS['__POST']["mkname"];
			$mktype=$GLOBALS['__POST']["mktype"];
			$symlink_target = $GLOBALS['__POST']['symlink_target'];
			//ext_Result::sendResult( 'mkitem', false,  sprintf("<br>mkname=%s stripslashes(mkname)=%s gbasename(stripslashes(mkname))=%s <br>",$mkname,stripslashes($mkname),gbasename(stripslashes($mkname))) );
			
			$mkname=gbasename(stripslashes($mkname));
			
			$valid = new validate();
            if(!$valid->check_sharefolder($mkname) ){                                                                                            
                 if($mktype=="dir") {
                        $err=$GLOBALS["error_msg"]["createdir"];
                 } elseif( $mktype == 'file') { 
                        $err=$GLOBALS["error_msg"]["createfile"]; 
                 }
                 ext_Result::sendResult( 'mkitem', false, $err);
            }
			if(!$valid->limitblank($mkname)){
				ext_Result::sendResult( 'mkitem', false,  $GLOBALS["error_msg"]["miscnoname"]); 
			}
			
			$new = get_abs_item($dir,$mkname);
		
			if(@$GLOBALS['ext_File']->file_exists($new)) {
				ext_Result::sendResult( 'mkitem', false, $mkname.": ".$GLOBALS["error_msg"]["itemdoesexist"]);
			}
			$err = print_r( $_POST, true );
			if($mktype=="dir") {
				//printf("new = %s <br>",$new);
				$ok=@$GLOBALS['ext_File']->mkdir($new, 0666);
				$err=$GLOBALS["error_msg"]["createdir"];
			} elseif( $mktype == 'file') {
				$ok=@$GLOBALS['ext_File']->mkfile($new);
				$err=$GLOBALS["error_msg"]["createfile"];
			} elseif( $mktype == 'symlink' ) {
				if( empty( $symlink_target )) {
					ext_Result::sendResult( 'mkitem', false, 'Please provide a valid <strong>target</strong> for the symbolic link.');
				}
				if( !file_exists($symlink_target) || !is_readable($symlink_target)) {
					ext_Result::sendResult( 'mkitem', false, 'The file you wanted to make a symbolic link to does not exist or is not accessible by PHP.');
				}
				$ok = symlink( $symlink_target, $new );
				$err = 'The symbolic link could not be created.';
			}
			
			if($ok==false || PEAR::isError( $ok )) {
				if( PEAR::isError( $ok ) ) $err.= $ok->getMessage();
				ext_Result::sendResult( 'mkitem', false, $err);
			}
			$tmp_dir=get_abs_dir($dir);
			$tmp_aclfile="/tmp/expfile.acl";						
			shell_exec("/usr/bin/getfacl ".$tmp_dir." >".$tmp_aclfile);
			shell_exec("/usr/bin/setfacl -P --modify-file=".$tmp_aclfile." '".$new."'");
			//chmod($new,0777);
			chown($new,"nobody");
			chgrp($new,"nogroup");
			ext_Result::sendResult( 'mkitem', true, 'The item '.$new.' was created' );
			
			return;
		}
	?>
		<div>
	    <div class="x-box-tl"><div class="x-box-tr"><div class="x-box-tc"></div></div></div>
	    <div class="x-box-ml"><div class="x-box-mr"><div class="x-box-mc">
	
	        <h3 style="margin-bottom:5px;"><?php echo ext_Lang::msg( 'create_title', true ) ?></h3>
	        <div id="adminForm">
	
	        </div>
	    </div></div></div>
	    <div class="x-box-bl"><div class="x-box-br"><div class="x-box-bc"></div></div></div>
	</div>
	<script type="text/javascript">
	var mktypes = new Ext.data.SimpleStore({
	    fields: ['mktype', 'type'],
	    data :  [
	        ['dir', '<?php echo ext_Lang::mime( 'dir', true ) ?>'],
	        ['file', '<?php echo ext_Lang::mime( 'file', true ) ?>']
	        <?php
	        /* Make for Symbolic Link
	        if( !ext_isFTPMode() && !$GLOBALS['isWindows']) { ?>
	        	,['symlink', '<?php echo ext_Lang::mime( 'symlink', true ) ?>']
	        	<?php
	        }*/ ?>
	        ]
	});
	var simple = new Ext.form.Form({
	    labelWidth: 125, // label settings here cascade unless overridden
	    url:'<?php echo gbasename( $GLOBALS['script_name']) ?>'
	});
	simple.add(
	    new Ext.form.TextField({
	        fieldLabel: '<?php echo ext_Lang::msg( 'nameheader', true ) ?>',
	        name: 'mkname',
	        width:175,
	        allowBlank:false
	    }),
		new Ext.form.ComboBox({
			fieldLabel: '<?php echo ext_Lang::msg( 'typeheader', true ) ?>',
		    store: mktypes,
		    displayField:'type',
		    valueField: 'mktype',
		    value: 'dir',
		    hiddenName: 'mktype',
		    disableKeyFilter: true,
		    editable: false,
		    triggerAction: 'all',
		    mode: 'local',
		    allowBlank: false,
		    selectOnFocus:true
		})/*,  //Make for Symbloic Link
	    new Ext.form.TextField({
	        fieldLabel: '<?php echo ext_Lang::msg( 'symlink_target', true ) ?>',
	        name: 'symlink_target',
	        width:175,
	        allowBlank:true
	    })*/
	);
	
	simple.addButton('<?php echo ext_Lang::msg( 'btncreate', true ) ?>', function() {
		statusBarMessage( 'Please wait...', true );
	    simple.submit({
	        //reset: true,
	        reset: false,
	        success: function(form, action) {	
	        	statusBarMessage( action.result.message, false, true );
	        	try{ 
	        		dirTree.getSelectionModel().getSelectedNode().reload(); 
	        	} catch(e) {}
				datastore.reload();
				dialog.destroy();
	        },
	        failure: function(form, action) {
	        	if( !action.result ) return;
				Ext.MessageBox.alert('Error!', action.result.error);
				statusBarMessage( action.result.error, false, true );
	        },
	        scope: simple,
	        // add some vars to the request, similar to hidden fields
	        params: {option: 'com_extplorer', 
	        		action: 'mkitem', 
	        		dir: datastore.directory, 
	        		confirm: 'true'}
	    })
	});
	simple.addButton('<?php echo ext_Lang::msg( 'btncancel', true ) ?>', function() { dialog.destroy(); } );
	simple.render('adminForm');
	simple.findField( 'mkname').focus();
	</script>
	<?php
	}
}

//------------------------------------------------------------------------------
?>
