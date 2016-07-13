<?php
// ensure this file is being included by a parent file
if( !defined( '_JEXEC' ) && !defined( '_VALID_MOS' ) ) die( 'Restricted access' );
/**
 * @package eXtplorer
 * @copyright soeren 2007
 * @author The eXtplorer project (http://sourceforge.net/projects/extplorer)
 * @author The  The QuiX project (http://quixplorer.sourceforge.net)
 * @license
 * @version $Id: archive.php 105 2008-05-31 13:38:38Z soeren $
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
 * Zip & TarGzip Functions
 *
 */
class ext_Archive extends ext_Action {

	function execAction( $dir ) {
		
		if(($GLOBALS["permissions"]&01)!=01) {
			ext_Result::sendResult('archive', false, $GLOBALS["error_msg"]["accessfunc"]);
		}
		if(!$GLOBALS["zip"] && !$GLOBALS["tgz"]) {
			ext_Result::sendResult('archive', false, $GLOBALS["error_msg"]["miscnofunc"]);
		}

		$allowed_types = array( 'zip', 'tgz', 'tbz', 'tar' );

		// If we have something to archive, let's do it now
		if(extGetParam($_POST, 'confirm' ) == 'true' ) {
			$saveToDir = cutf8_decode($GLOBALS['__POST']['saveToDir']);
			if( !file_exists( get_abs_dir($saveToDir ) )) {
				ext_Result::sendResult('archive', false, ext_Lang::err('archive_dir_notexists'));
			}
			if( !is_writable( get_abs_dir($saveToDir ) )) {
				ext_Result::sendResult('archive', false, ext_Lang::err('archive_dir_unwritable'));
			}
			require_once( _EXT_PATH .'/libraries/Archive/archive.php' );

			if( !in_array(strtolower( $GLOBALS['__POST']["type"] ), $allowed_types )) {
				ext_Result::sendResult('archive', false, ext_Lang::err('extract_unknowntype').': '.htmlspecialchars($GLOBALS['__POST']["type"]));

			}
			// This controls how many files are processed per Step (it's split up into steps to prevent time-outs)
			$files_per_step = 2000;

			$cnt=count($GLOBALS['__POST']["selitems"]);
			$abs_dir= get_abs_dir($dir);
			$name=gbasename(stripslashes($GLOBALS['__POST']["name"]));
			if($name=="") {
				ext_Result::sendResult('archive', false, $GLOBALS["error_msg"]["miscnoname"]);
			}

			$startfrom = extGetParam( $_REQUEST, 'startfrom', 0 );
			
			$dir_contents_cache_name = 'ext_'.md5(implode(null, $GLOBALS['__POST']["selitems"]));
			$dir_contents_cache_file = _EXT_FTPTMP_PATH.'/'.$dir_contents_cache_name.'.txt';
			
			$archive_name = get_abs_item($saveToDir,$name);
			$fileinfo = pathinfo( $archive_name );

			if( empty( $fileinfo['extension'] )) {
				$archive_name .= ".".$GLOBALS['__POST']["type"];
				$fileinfo['extension'] = $GLOBALS['__POST']["type"];

				foreach( $allowed_types as $ext ) {
					if( $GLOBALS['__POST']["type"] == $ext && @$fileinfo['extension'] != $ext ) {
						$archive_name .= ".".$ext;
					}
				}
			}
			if( $startfrom == 0 ) {
				for($i=0;$i<$cnt;$i++) {
	
					$selitem=stripslashes($GLOBALS['__POST']["selitems"][$i]);
					if( $selitem == 'ext_root') { 
						$selitem = '';
					}
					if( is_dir( cutf8_decode($abs_dir ."/". $selitem ))) {					
						$items = extReadDirectory(cutf8_decode($abs_dir ."/".  $selitem), '.', true, true );
						foreach ( $items as $item ) {
							if( is_dir( $item ) || !is_readable( $item ) || $item == $archive_name ) continue;
							$v_list[] = str_replace('\\', '/', $item );
						}
					}
					else {					
						$v_list[] = cutf8_decode(str_replace('\\', '/', $abs_dir ."/". $selitem ));
					}
				}
				if( count($v_list) > $files_per_step ) {
					if( file_put_contents($dir_contents_cache_file, implode("\n", $v_list )) == false ) {
						ext_Result::sendResult('archive', false, 'Failed to create a temporary list of the directory contents' );
					}
				}
			} else {
				$file_list_string = file_get_contents($dir_contents_cache_file);
				if( empty( $file_list_string )) {
					ext_Result::sendResult('archive', false, 'Failed to retrieve the temporary list of the directory contents' );
				}
				$v_list = explode("\n", $file_list_string );
			}
			$cnt_filelist = count( $v_list );
			// Now we go to the right range of files and "slice" the array
			$v_list = array_slice( $v_list, $startfrom, $files_per_step-1  );
			
			$remove_path = $GLOBALS["home_dir"];
			if( $dir ) {
				$remove_path .= $dir;
			}

			$debug = 'Starting from: '.$startfrom."\n";
			$debug .= 'Files to process: '.$cnt_filelist."\n";
			$debug .= implode( "\n", $v_list );
			//file_put_contents( 'log.txt', $debug, FILE_APPEND );

			// Do some setup stuff
			ini_set('memory_limit', '128M');
			@set_time_limit( 0 );
			error_reporting( E_ERROR | E_PARSE );
			$result = extArchive::create( $archive_name, $v_list, $GLOBALS['__POST']["type"], '', $remove_path  );

			if( PEAR::isError( $result ) ) {
				ext_Result::sendResult('archive', false, $name.': '.ext_Lang::err('archive_creation_failed').' ('.$result->getMessage().$archive_name.')' );
			}
			$json = new ext_Json();
			if( $cnt_filelist > $startfrom+$files_per_step ) {

				$response = Array( 'startfrom' => $startfrom + $files_per_step,
				'totalitems' => $cnt_filelist,
				'success' => true,
				'action' => 'archive',
				'message' => sprintf( ext_Lang::msg('processed_x_files'), $startfrom + $files_per_step, $cnt_filelist )
				);
			}
			else {
				@unlink($dir_contents_cache_file);
				if( $GLOBALS['__POST']["type"] == 'tgz' || $GLOBALS['__POST']["type"] == 'tbz') {
					chmod( $archive_name, 0644 );
				}
				$response = Array( 'action' => 'archive',
				'success' => true,
				'message' => ext_Lang::msg('archive_created'),
				'newlocation' => make_link( 'download', $dir, gbasename($archive_name) )
				);

			}

			echo $json->encode( $response );
			ext_exit();
		}
	?>
<div style="width:auto;">
    <div class="x-box-tl"><div class="x-box-tr"><div class="x-box-tc"></div></div></div>
    <div class="x-box-ml"><div class="x-box-mr"><div class="x-box-mc">

        <h3 style="margin-bottom:5px;"><?php echo $GLOBALS["messages"]["actarchive"] ?></h3>
        
        <div id="adminForm"></div>
    </div></div></div>
    <div class="x-box-bl"><div class="x-box-br"><div class="x-box-bc"></div></div></div>
</div>
	<script type="text/javascript">	
	var comprTypes = new Ext.data.SimpleStore({
		fields: ['type', 'typename'],
		data :  [
		['zip', 'Zip (<?php echo ext_Lang::msg('normal_compression', true ) ?>)'],
		['tgz', 'Tar/Gz (<?php echo ext_Lang::msg('good_compression', true ) ?>)'],
		<?php
		if(extension_loaded("bz2")) {
			echo "['tbz', 'Tar/Bzip2 (".ext_Lang::msg('best_compression', true ).")'],";
		}
		?>
		['tar', 'Tar (<?php echo ext_Lang::msg('no_compression', true ) ?>)']
		]
	});
	var form = new Ext.form.Form({
		labelWidth: 125, // label settings here cascade unless overridden
		url:'<?php echo gbasename( $GLOBALS['script_name']) ?>'
	});
	var combo = new Ext.form.ComboBox({
		fieldLabel: '<?php echo ext_Lang::msg('typeheader', true ) ?>',
		store: comprTypes,
		displayField:'typename',
		valueField: 'type',
		name: 'type',
		value: 'zip',
	    triggerAction: 'all',
		hiddenName: 'type',
		disableKeyFilter: true,
		editable: false,
		mode: 'local',
		allowBlank: false,
		selectOnFocus:true,
		width: 200
	});
	form.add( new Ext.form.TextField({
		fieldLabel: '<?php echo ext_Lang::msg('archive_name', true ) ?>',
		name: 'name',
		width: 200
	}),
	combo,
	new Ext.form.TextField({
		fieldLabel: '<?php echo ext_Lang::msg('archive_saveToDir', true ) ?>',
		name: 'saveToDir',
		value: '<?php echo str_replace("'", "\'", $dir ) ?>',
		width: 200
	}),
	new Ext.form.Checkbox({
		fieldLabel: '<?php echo ext_Lang::msg('downlink', true ) ?>?',
		name: 'download',
		checked: true
	})
	);
	combo.on('select', function(o, record ) {

		var nameField = form.findField('name').getValue();
		if( nameField.indexOf( '.' ) > 0 ) {
			form.findField('name').setValue( nameField.substring( 0, nameField.indexOf('.')+1 ) + record.get('type') );
		} else {
			form.findField('name').setValue( nameField + '.'+ record.get('type'));
		}
	});

	form.addButton({text: '<?php echo ext_Lang::msg( 'btncreate', true ) ?>', type: 'submit' }, function() { formSubmit(0) });
	form.addButton('<?php echo ext_Lang::msg( 'btncancel', true ) ?>', function() { dialog.hide();dialog.destroy(); } );

	form.render('adminForm');

	function formSubmit( startfrom, msg ) {
		if( startfrom == 0 ) {
			Ext.MessageBox.show({
		           title: 'Please wait',
		           msg: msg ? msg : '<?php echo ext_Lang::msg( 'creating_archive', true ) ?>',
		           progressText: 'Initializing...',
		           width:300,
		           progress:true,
		           closable:false
       		});
       	}
		form.submit({
			reset: false,
			success: function(form, action) {
				if( !action.result ) return;
				
				if( action.result.startfrom > 0 ) {
					formSubmit( action.result.startfrom, action.result.message );
			       
					i = action.result.startfrom/action.result.totalitems;
			       Ext.MessageBox.updateProgress(i, action.result.startfrom + " of "+action.result.totalitems + " (" + Math.round(100*i)+'% completed)');
			        
					return
				} else {

					if( form.findField('download').getValue() ) {
						datastore.reload();
						location.href = action.result.newlocation;
						dialog.hide();
						dialog.destroy();
					} else {
						Ext.MessageBox.alert('<?php echo ext_Lang::msg('success', true) ?>!', action.result.message);
						datastore.reload();
						dialog.hide();
						dialog.destroy();
					}
					return;
				}
			},
			failure: function(form, action) {
				if( action.result ) {
					Ext.MessageBox.alert('<?php echo ext_Lang::err('error', true) ?>', action.result.error);
				}
			},
			scope: form,
			// add some vars to the request, similar to hidden fields
			params: {option: 'com_extplorer',
			action: 'archive',
			dir: '<?php echo stripslashes($GLOBALS['__POST']["dir"]) ?>',
			'selitems[]':  [ '<?php echo implode("','", $GLOBALS['__POST']["selitems"]) ?>' ],
			startfrom: startfrom,
			confirm: 'true'}
		});
	}

	</script>

	<?php
	}
}
//------------------------------------------------------------------------------
?>