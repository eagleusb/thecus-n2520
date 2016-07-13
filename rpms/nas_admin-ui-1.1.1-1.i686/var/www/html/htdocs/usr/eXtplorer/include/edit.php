<?php
// ensure this file is being included by a parent file
if( !defined( '_JEXEC' ) && !defined( '_VALID_MOS' ) ) die( 'Restricted access' );
/**
 * @version $Id: edit.php 105 2008-05-31 13:38:38Z soeren $
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
 * File-Edit Functions
 *
 */
class ext_Edit extends ext_Action {
	
	function execAction($dir, $item) {		// edit file
		global $mainframe, $mosConfig_live_site;
		
		if(($GLOBALS["permissions"]&01)!=01) {
			ext_Result::sendResult('edit', false, ext_Lang::err('accessfunc' ));
		}
		$fname = get_abs_item($dir, $item);
		
		if(!get_is_file(cutf8_decode($fname)))  {
			ext_Result::sendResult('edit', false, $item.": ".ext_Lang::err('fileexist' ));
		}
		if(!get_show_item($dir, $item)) {
			ext_Result::sendResult('edit', false, $item.": ".ext_Lang::err('accessfile' ));	
		}
		
		if(isset($GLOBALS['__POST']["dosave"]) && $GLOBALS['__POST']["dosave"]=="yes") {
			// Save / Save As
			$item=gbasename(stripslashes($GLOBALS['__POST']["fname"]));
			$fname2=get_abs_item($dir, $item);
			
			if(!isset($item) || $item=="") {
				ext_Result::sendResult('edit', false, ext_Lang::err('miscnoname' ));
			}
			if($fname!=$fname2 && @$GLOBALS['ext_File']->file_exists($fname2)) {
				ext_Result::sendResult('edit', false, $item.": ".ext_Lang::err('itemdoesexist' ));
			}
			  
			$this->savefile($fname2);
			$fname=$fname2;
			
			ext_Result::sendResult('edit', true, ext_Lang::msg('savefile').': '.$item );
			
		}
		
		// header
		$s_item=get_rel_item($dir,$item);	if(strlen($s_item)>50) $s_item="...".substr($s_item,-47);
		$s_info = pathinfo( $s_item );
		$s_extension = str_replace('.', '', $s_info['extension'] );
		switch (strtolower($s_extension)) {
			case 'txt':
				$cp_lang = 'text'; break;
			case 'cs':
				$cp_lang = 'csharp'; break;
			case 'css':
				$cp_lang = 'css'; break;
			case 'html':
			case 'htm':
			case 'xml':
			case 'xhtml':
				$cp_lang = 'html'; break;
			case 'java':
				$cp_lang = 'java'; break;
			case 'js':
				$cp_lang = 'javascript'; break;
			case 'pl': 
				$cp_lang = 'perl'; break;
			case 'ruby': 
				$cp_lang = 'ruby'; break;
			case 'sql':
				$cp_lang = 'sql'; break;
			case 'vb':
			case 'vbs':
				$cp_lang = 'vbscript'; break;
			case 'php':
				$cp_lang = 'php'; break;
			default: 
				$cp_lang = 'generic';
		}
	?>
	<div style="width:auto;">
	    <div class="x-box-tl"><div class="x-box-tr"><div class="x-box-tc"></div></div></div>
	    <div class="x-box-ml"><div class="x-box-mr"><div class="x-box-mc">
	
	        <h3 style="margin-bottom:5px;"><?php 
	        	echo $GLOBALS["messages"]["actedit"].": /".$s_item .'&nbsp;&nbsp;&nbsp;&nbsp;';
	        	?></h3>
    
	        <div id="adminForm">
	
	        </div>
	    </div></div></div>
	    <div class="x-box-bl"><div class="x-box-br"><div class="x-box-bc"></div></div></div>
	</div>
	
	<?php	
	// Show File In TextArea
	$content = $GLOBALS['ext_File']->file_get_contents( $fname );
	if( get_magic_quotes_runtime()) {
		$content = stripslashes( $content );
	}
	//$content = htmlspecialchars( $content );
		
	?><script type="text/javascript">//<!--
	dialog.setContentSize( 700, 500 );
	simple = new Ext.form.Form({
	    labelAlign: 'top',
	    url:'<?php echo gbasename( $GLOBALS['script_name']) ?>'
	});
	simple.add(		
	    new Ext.form.TextArea({
	        fieldLabel: 'File Contents',
	        name: 'thecode',
	        id: 'ext_codefield',
	        fieldClass: 'x-form-field',
	        value: '<?php echo str_replace(Array("\r", "\n", '<', '>'), Array('\r', '\n', '&lt;', '&gt;') , addslashes($content)) ?>',
	        width: '100%',
	        height: 300
	    })		
	);
	simple.column( {width: 250 }, 
		new Ext.form.TextField({
	        fieldLabel: '<?php echo ext_Lang::msg('copyfile', true ) ?>',
	        name: 'fname',
	        value: '<?php echo $item ?>',
	        width:175
		})
	);
	simple.column( {width: 250, style:'margin-left:10px', clear:true }, 
		new Ext.form.Checkbox({
	        fieldLabel: '<?php echo ext_Lang::msg('returndir', true ) ?>',
	        name: 'return_to_dir',
	        width:175
		})
	);
	simple.addButton('<?php echo ext_Lang::msg('btnsave', true ) ?>', function() {
		statusBarMessage( '<?php echo ext_Lang::msg('save_processing', true ) ?>', true );

	    simple.submit({
	        //waitMsg: 'Processing Data, please wait...',
	        //reset: true,
	        reset: false,
	        success: function(form, action) {
	        	datastore.reload();
	        	statusBarMessage( action.result.message, false, true );
	        	if( simple.findField('return_to_dir').getValue() ) {
	        		dialog.destroy();
	        	}
	        },
	        failure: function(form, action) {
	        	statusBarMessage( action.result.error, false, false );
	        	Ext.MessageBox.alert('<?php echo ext_Lang::err('error', true) ?>!', action.result.error);
	        },
	        scope: simple,
	        // add some vars to the request, similar to hidden fields
	        params: {option: 'com_extplorer', 
	        		action: 'edit', 
	        		code: editAreaLoader.getValue("ext_codefield"),
	        		dir: '<?php echo stripslashes($dir) ?>', 
	        		item: '<?php echo stripslashes($item) ?>', 
	        		dosave: 'yes'
	        }
	    });
	});
	
	simple.addButton('<?php echo ext_Lang::msg('btnclose', true ) ?>', function() { dialog.destroy(); } );
	simple.render('adminForm');
	simple.findField('thecode').setValue(simple.findField( 'thecode').getValue().replace( /&gt;/g, '>').replace( /&lt;/g, '<'));
	editAreaLoader.baseURL = "<?php echo _EXT_URL ?>/scripts/editarea/";
	editAreaLoader.init({
		id : "ext_codefield"		// textarea id
		,syntax: "<?php echo $cp_lang ?>"			// syntax to be uses for highgliting
		,start_highlight: true		// to display with highlight mode on start-up
		,display: "later"
	});
	editAreaLoader.start("ext_codefield");
	// -->
	</script><?php
	
	}
	function savefile($file_name) {			// save edited file
		if( get_magic_quotes_gpc() ) {
			$code = stripslashes($GLOBALS['__POST']["code"]);
		}
		else {
			$code = $GLOBALS['__POST']["code"];
		}
		
		$res = $GLOBALS['ext_File']->file_put_contents( $file_name, $code );
		
		if( $res==false || PEAR::isError( $res )) {
			$err = gbasename($file_name).": ".ext_Lang::err('savefile' );
			if( PEAR::isError( $res ) ) {
				$err .= $res->getMessage();
			}
			ext_Result::sendResult( 'edit', false, $err );
		}
		
	}
}
//------------------------------------------------------------------------------
?>
