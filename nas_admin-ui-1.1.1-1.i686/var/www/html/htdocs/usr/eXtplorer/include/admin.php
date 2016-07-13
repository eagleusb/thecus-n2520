<?php
// ensure this file is being included by a parent file
if( !defined( '_JEXEC' ) && !defined( '_VALID_MOS' ) ) die( 'Restricted access' );
/**
 * @package eXtplorer
 * @copyright soeren 2007
 * @author The eXtplorer project (http://sourceforge.net/projects/extplorer)
 * @author The  The QuiX project (http://quixplorer.sourceforge.net)
 * @license
 * @version $Id: admin.php 94 2008-01-30 07:37:06Z soeren $
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
 * Comment:
 * Administrative Functions
 * 
 */
//------------------------------------------------------------------------------
function admin($admin, $dir) {			// Change Password & Manage Users Form
	
	// Javascript functions:
	include _EXT_PATH . "/include/js_admin.php";
?>
<div style="width:auto;">
    <div class="x-box-tl"><div class="x-box-tr"><div class="x-box-tc"></div></div></div>
    <div class="x-box-ml"><div class="x-box-mr"><div class="x-box-mc">

        <h3 style="margin-bottom:5px;"><?php echo ext_Lang::msg('actadmin') ?></h3>
        <div id="adminForm">
	        <div id="passForm"></div>
	        <div id="userList"></div>
        </div>
    </div></div></div>
    <div class="x-box-bl"><div class="x-box-br"><div class="x-box-bc"></div></div></div>
</div>
	<script type="text/javascript">
	// Change Password
	var PassForm = new Ext.form.Form({
	    labelWidth: 125, // label settings here cascade unless overridden
	    url:'<?php echo gbasename( $GLOBALS['script_name']) ?>'
	});
	PassForm.add(
        
	    new Ext.form.TextField({
	        fieldLabel: '<?php echo ext_Lang::msg( 'miscoldpass', true ) ?>',
	        name: 'oldpwd',
	        inputType: 'password',
	        allowBlank:false
	    }),
	    new Ext.form.TextField({
	        fieldLabel: '<?php echo ext_Lang::msg( 'miscnewpass', true ) ?>',
	        name: 'newpwd1',
	        hiddenName: 'newpwd1',
	        inputType: 'password',
	        allowBlank:false
	    }),
	    new Ext.form.TextField({
	        fieldLabel: '<?php echo ext_Lang::msg( 'miscconfnewpass', true ) ?>',
	        name: 'newpwd2',
	        hiddenName: 'newpwd2',
	        inputType: 'password',
	        allowBlank:false
	    })
	);
	
	PassForm.addButton('<?php echo ext_Lang::msg( 'btnchange', true ) ?>', function() {
		if( !check_pwd() ) return;
		statusBarMessage( 'Please wait...', true );
	    PassForm.submit({    //Check user name and password
	        //reset: true,
	        reset: false,
	        success: function(form, action) {	
			Ext.MessageBox.alert(action.result.action, action.result.message);
	        	statusBarMessage( action.result.message, false, true );
			dialog.destroy();
	        },
	        failure: function(form, action) {
	        	if( !action.result ) return;
			Ext.MessageBox.alert(action.result.action, action.result.error);
			statusBarMessage( action.result.error, false, false );
			//dialog.destroy();
	        },
	        scope: PassForm,
	        // add some vars to the request, similar to hidden fields
	        params: {
	        	option: 'com_extplorer', 
        		action: 'admin',
        		action2: 'chpwd'
	        }
	    })
	});
	PassForm.render('passForm');
	PassForm.findField('oldpwd').focus();
	<?php
	if(0) {  //Disable admin permission config UI
	//if($admin) {
		?>
		
	// Edit / Add / Remove User
	var UserForm = new Ext.form.Form({
	    labelWidth: 125, // label settings here cascade unless overridden
	    url:'<?php echo gbasename( $GLOBALS['script_name']) ?>'
	});
	UserForm.add(
        <?php 
		$cnt=count($GLOBALS["users"]);
		for($i=0;$i<$cnt;++$i) {
			
			// Username & Home dir:
			$user=$GLOBALS["users"][$i][0];	if(strlen($user)>15) $user=substr($user,0,12)."...";
			$home=$GLOBALS["users"][$i][2];	if(strlen($home)>30) $home=substr($home,0,27)."...";
			?>
	
			new Ext.form.Radio( {
				name: 'nuser',
				inputValue: '<?php echo $GLOBALS["users"][$i][0] ?>',
				fieldLabel: '<?php echo $user ?>',
				boxLabel: '<?php echo '<strong>Homedir:</strong> '.$home.'; '
					.($GLOBALS["users"][$i][4] ? $GLOBALS["messages"]["miscyesno"][2]:$GLOBALS["messages"]["miscyesno"][3]).'; '
					.$GLOBALS["users"][$i][6].'; '
					.($GLOBALS["users"][$i][7] ? $GLOBALS["messages"]["miscyesno"][2]:$GLOBALS["messages"]["miscyesno"][3]);
				 ?>'
			})
			<?php 
			echo $i+1<$cnt ? ',' : '';
		}
		?>
    );

   	UserForm.addButton('<?php echo ext_Lang::msg( 'btnadd', true ) ?>', function() {
	    dialog_panel.load({url: '<?php echo gbasename($GLOBALS['script_name']) ?>', 
	    		params: {
		        	option: 'com_extplorer', 
	        		action: 'admin',
	        		action2: 'adduser'
		        }
	    });
   	});
   	UserForm.addButton('<?php echo ext_Lang::msg( 'btnedit', true ) ?>', function() {
   		try {
   			 theUser = UserForm.findField(0).getGroupValue();
   		} catch(e) {
   			Ext.Msg.alert( 'Error', '<?php echo ext_Lang::err('miscselitems', true ) ?>' );
   			return;
   		}
	    dialog_panel.load({url: '<?php echo gbasename($GLOBALS['script_name']) ?>', 
	    		params: {
		        	option: 'com_extplorer', 
	        		action: 'admin',
	        		action2: 'edituser',
	        		nuser: theUser
		        }
	    });
	});
   	
   	UserForm.addButton('<?php echo ext_Lang::msg( 'btnremove', true ) ?>', function() {
   		try {
   			 theUser = UserForm.findField(0).getGroupValue();
   		} catch(e) {
   			Ext.Msg.alert( 'Error', '<?php echo ext_Lang::err('miscselitems', true ) ?>' );
   			return;
   		}
		
		Ext.Msg.confirm( '', String.format( '<?php echo ext_Lang::err('miscdeluser', true ) ?>', theUser ), function( btn ) {
			if( btn != 'yes') return;
			statusBarMessage( 'Please wait...', true );
	    	UserForm.submit({
		        success: function(form, action) {	
		        	statusBarMessage( action.result.message, false, true );
		        },
		        failure: function(form, action) {
		        	if( !action.result ) return;
					Ext.MessageBox.alert('Error!', action.result.error);
					statusBarMessage( action.result.error, false, true );
		        },
		        scope: UserForm,
		        // add some vars to the request, similar to hidden fields
		        params: {
		        	option: 'com_extplorer', 
	        		action: 'admin',
	        		action2: 'rmuser',
	        		user: theUser
		        }
		    });
		});
   	});
	UserForm.render('userList');
	Ext.get('userList').createChild({
        tag:'center', 
        cn: {
            tag:'span',
            html: '<?php echo ext_Lang::msg('miscuseritems', true ) ?>',
            style:'margin-bottom:5px;'
        }
    });
		<?php
	}
	?>
	var tabs = new Ext.TabPanel("adminForm");
	//tabs.addTab("userList", '<?php echo ext_Lang::msg('actusers', true) ?>');
	tabs.addTab("passForm", '<?php echo ext_Lang::msg('actchpwd', true) . sprintf("[%s]",$_SESSION["s_user"]); ?>');
	<?php
	/*    Disable user list page
	if( $_SESSION['s_user'] == 'admin' && $_SESSION['s_pass'] == extEncodePassword('admin')) {
		echo 'tabs.activate("passForm");';
	} else {
		echo 'tabs.activate("userList");';
	}*/
	//Always active passForm
	echo 'tabs.activate("passForm");';
	?>
		
	</script>
	<?php
}
//------------------------------------------------------------------------------
function changepwd($dir) {			// Change Password
	global $session;
		
	//$pwd=extEncodePassword(stripslashes($GLOBALS['__POST']["oldpwd"]));
	//remove password encode
	$pwd=stripslashes($GLOBALS['__POST']["oldpwd"]);
	if($GLOBALS['__POST']["newpwd1"]!=$GLOBALS['__POST']["newpwd2"]) {
		ext_Result::sendResult('changepwd', false, $GLOBALS["error_msg"]["miscnopassmatch"]);
	}
	
	$valid = new validate();
	if(!$valid->limitblank($GLOBALS['__POST']["newpwd1"]) && $GLOBALS['__POST']["newpwd1"]!=''){
		ext_Result::sendResult('changepwd', false, $GLOBALS["error_msg"]["miscnouserpass"]);
	}
	$pwd_tmp=$GLOBALS['__SESSION']["s_pass"];
	$user_tmp=$GLOBALS['__SESSION']["s_user"];
	$data=find_user($GLOBALS['__SESSION']["s_user"],$pwd,true);
	if($data==NULL) {
		//$data_tmp=find_user($GLOBALS['__SESSION']["s_user"],$GLOBALS['__SESSION']["s_pass"]);
		//$session->chgLocalPasswd($user_tmp,$data_tmp[1]);
		//update_user($data_tmp[0],$data_tmp);
		//session_start();
		//activate_user($GLOBALS['__SESSION']["s_user"],$GLOBALS['__SESSION']["s_pass"]);
		ext_Result::sendResult('changepwd', false, $GLOBALS["error_msg"]["miscnouserpass"]);
	}
	//$data[1]=extEncodePassword(stripslashes($GLOBALS['__POST']["newpwd1"]));
	$data[1]=stripslashes($GLOBALS['__POST']["newpwd1"]);
	
	//Change password
	$session->chgLocalPasswd($GLOBALS['__SESSION']["s_user"],$data[1]);
	/*
	if(!update_user($data[0],$data)) {
		ext_Result::sendResult('changepwd', false, $data[0].": ".$GLOBALS["error_msg"]["chpass"]);
	}
	$_SESSION['s_pass']	= $data[1];
	*/
	activate_user($data[0],$data[1]);
	
	ext_Result::sendResult('changepwd', true, ext_Lang::msg('change_password_success'));
}
//------------------------------------------------------------------------------
function adduser($dir) {			// Add User
	if(isset($GLOBALS['__POST']["confirm"]) && $GLOBALS['__POST']["confirm"]=="true") {
		$user=stripslashes($GLOBALS['__POST']["nuser"]);
		if($user=="" || $GLOBALS['__POST']["home_dir"]=="") {
			ext_Result::sendResult('adduser', false, $GLOBALS["error_msg"]["miscfieldmissed"]);
		}
		if($GLOBALS['__POST']["pass1"]!=$GLOBALS['__POST']["pass2"]) {
			ext_Result::sendResult('adduser', false, $GLOBALS["error_msg"]["miscnopassmatch"]);
		}
		$data=find_user($user,NULL);
		if($data!=NULL) {
			ext_Result::sendResult('adduser', false, $user.": ".$GLOBALS["error_msg"]["miscuserexist"]);
		}
		
		$data=array($user,extEncodePassword(stripslashes($GLOBALS['__POST']["pass1"])),
			stripslashes($GLOBALS['__POST']["home_dir"]),stripslashes($GLOBALS['__POST']["home_url"]),
			$GLOBALS['__POST']["show_hidden"],stripslashes($GLOBALS['__POST']["no_access"]),
			$GLOBALS['__POST']["permissions"],$GLOBALS['__POST']["active"]);
			
		if(!add_user($data)) {
			ext_Result::sendResult('adduser', false, $user.": ".$GLOBALS["error_msg"]["adduser"]);
		}
		ext_Result::sendResult('adduser', false, $user.": The user has been added");
		return;
	}
	
	// Javascript functions:
	include _EXT_PATH . "/include/js_admin2.php";
	
	show_userform();
	
}
//------------------------------------------------------------------------------
function edituser($dir) {			// Edit User
	$user=stripslashes($GLOBALS['__POST']["nuser"]);
	$data=find_user($user,NULL);
	if($data==NULL) {
		ext_Result::sendResult('edituser', false, $user.": ".$GLOBALS["error_msg"]["miscnofinduser"]);
	}
	
	if($self=($user==$GLOBALS['__SESSION']["s_user"])) $dir="";
	
	if(isset($GLOBALS['__POST']["confirm"]) && $GLOBALS['__POST']["confirm"]=="true") {
		
		$nuser=stripslashes($GLOBALS['__POST']["nuser"]);
		if($nuser=="" || $GLOBALS['__POST']["home_dir"]=="") {
			ext_Result::sendResult('edituser', false, $GLOBALS["error_msg"]["miscfieldmissed"]);
		}
		if(isset($GLOBALS['__POST']["chpass"]) && $GLOBALS['__POST']["chpass"]=="true")	{
			if($GLOBALS['__POST']["pass1"]!=$GLOBALS['__POST']["pass2"]) ext_Result::sendResult('edituser', false, $GLOBALS["error_msg"]["miscnopassmatch"]);
			$pass=extEncodePassword(stripslashes($GLOBALS['__POST']["pass1"]));
		} else {
			$pass=$data[1];
		}
		
		if($self) $GLOBALS['__POST']["active"]=1;
		
		$data=array($nuser,$pass,stripslashes($GLOBALS['__POST']["home_dir"]),
			stripslashes($GLOBALS['__POST']["home_url"]),$GLOBALS['__POST']["show_hidden"],
			stripslashes($GLOBALS['__POST']["no_access"]),$GLOBALS['__POST']["permissions"],$GLOBALS['__POST']["active"]);
			
		if(!update_user($user,$data)) {
			ext_Result::sendResult('edituser', false, $user.": ".$GLOBALS["error_msg"]["saveuser"]);
		}
		if($self) {
			activate_user($nuser,NULL);
		}
		ext_Result::sendResult('edituser', true, $user.": ".$GLOBALS["error_msg"]["saveuser"]);
	}
	
	// Javascript functions:
	include _EXT_PATH . "/include/js_admin3.php";
	show_userform( $data);
}

function show_userform( $data = null ) {
	if( $data == null ) { $data = array('', '', '', '', '', '', '' ); }
	
?>
	<div>
	    <div class="x-box-tl"><div class="x-box-tr"><div class="x-box-tc"></div></div></div>
	    <div class="x-box-ml"><div class="x-box-mr"><div class="x-box-mc">
	
	        <h3 style="margin-bottom:5px;"><?php
	        if( !empty( $data[0] )) {
	        	echo $GLOBALS["messages"]["actadmin"].": ".sprintf($GLOBALS["messages"]["miscedituser"],$data[0]);
	        	
	        } else {
	        	echo $GLOBALS["messages"]["actadmin"].": ".$GLOBALS["messages"]["miscadduser"];
	        }
	        ?></h3>
	        <div id="adminForm">
	
	        </div>
	    </div></div></div>
	    <div class="x-box-bl"><div class="x-box-br"><div class="x-box-bc"></div></div></div>
	</div>
	<script type="text/javascript">
	var yesno = new Ext.data.SimpleStore({
	    fields: ['yesno', 'Yes_No'],
	    data :  [
	        ['1', '<?php echo ext_Lang::msg( array('miscyesno' => 0), true ) ?>'],
	        ['0', '<?php echo ext_Lang::msg( array('miscyesno' => 1), true ) ?>']
	        ]
	});
	var permvalues = new Ext.data.SimpleStore({
		fields: ['value', 'text'],
		data: [
	
	<?php
		$permvalues = array(0,1,2,3,7);
		$permcount = count($GLOBALS["messages"]["miscpermnames"]);
		for($i=0;$i<$permcount;++$i) {
			if( $permvalues[$i]==7) $index = 4;
			else $index = $i;
			echo "['{$permvalues[$i]}', '".ext_lang::msg( array('miscpermnames' => $index))."' ]\n";
			if( $i+1<$permcount) echo ',';
		}
		?>
	]});
	var userform = new Ext.form.Form({
	    labelWidth: 125, // label settings here cascade unless overridden
	    url:'<?php echo gbasename( $GLOBALS['script_name']) ?>'
	});

	
	userform.add(
	    new Ext.form.TextField({
	        fieldLabel: '<?php echo ext_Lang::msg( 'miscusername', true ) ?>',
	        name: 'nuser',
	        value: '<?php echo @$data[0] ?>',
	        width:175,
	        allowBlank:false
	    }),
	    new Ext.form.TextField({
	        fieldLabel: '<?php echo ext_Lang::msg( 'miscconfpass', true ) ?>',
	        name: 'pass1',
	        inputType: 'password',
	        width:175
	    }),
	    new Ext.form.TextField({
	        fieldLabel: '<?php echo ext_Lang::msg( 'miscconfnewpass', true ) ?>',
	        name: 'pass2',
	        inputType: 'password',
	        width:175
	    }),
	    <?php
	    if( !empty($data[0])) { ?>
		    new Ext.form.Checkbox({
		        fieldLabel: '<?php echo ext_Lang::msg( 'miscchpass', true ) ?>',
		        name: 'chpass',
		        hiddenValue: 'true'
			}),
			<?php 
	    } ?>
	    
	    new Ext.form.TextField({
	        fieldLabel: '<?php echo ext_Lang::msg( 'mischomedir', true ) ?>',
	        name: 'home_dir',
	        value: '<?php echo !empty($data[2]) ? $data[2] : $_SERVER['DOCUMENT_ROOT'] ?>',
	        width:175,
	        allowBlank:false
	    }),	    
	    new Ext.form.TextField({
	        fieldLabel: '<?php echo ext_Lang::msg( 'mischomeurl', true ) ?>',
	        name: 'home_url',
	        value: '<?php echo !empty($data[3]) ? $data[3] : $GLOBALS["home_url"] ?>',
	        width:175,
	        allowBlank:false
	    }),		
		new Ext.form.ComboBox({
			fieldLabel: '<?php echo ext_Lang::msg( 'miscshowhidden', true ) ?>',
		    store: yesno,
		    displayField:'Yes_No',
		    valueField: 'yesno',
		    hiddenName: 'show_hidden',
		    disableKeyFilter: true,
		    value: '<?php echo ( !empty($data[4]) ? $data[4] : (int)$data[4] ) ?>',
		    editable: false,
		    triggerAction: 'all',
		    mode: 'local',
		    allowBlank: false,
		    selectOnFocus:true
		}),
	    new Ext.form.TextField({
	        fieldLabel: '<?php echo ext_Lang::msg( 'mischidepattern', true ) ?>',
	        name: 'no_access',
	        value: '<?php echo @$data[5] ?>',
	        width:175,
	        allowBlank:true
	    }),
	
		new Ext.form.ComboBox({
			fieldLabel: '<?php echo ext_Lang::msg( 'miscperms', true ) ?>',
		    store: permvalues,
		    valueField: 'value',
		    displayField:'text',
		    hiddenName: 'permissions',
		    disableKeyFilter: true,
		    value: '<?php echo (int)@$data[6] ?>',
		    editable: false,
		    triggerAction: 'all',
		    mode: 'local'
		}),
		new Ext.form.ComboBox({
			fieldLabel: '<?php echo ext_Lang::msg( 'miscactive', true ) ?>',
		    store: yesno,
		    displayField:'Yes_No',
		    valueField: 'yesno',
		    hiddenName: 'active',
		    disableKeyFilter: true,
		    value: '<?php echo ( !empty($data[7]) ? $data[7] : 0 ) ?>',
		    disabled: <?php echo !empty($self) ? 'true' : 'false' ?>,
		    editable: false,
		    triggerAction: 'all',
		    mode: 'local',
		    allowBlank: false,
		    selectOnFocus:true
		})
	);
	userform.addButton('<?php echo ext_Lang::msg( 'btnsave', true ) ?>', function() {
		if( !check_pwd()) return;
		statusBarMessage( 'Please wait...', true );
	    userform.submit({
	        success: function(form, action) {	
	        	statusBarMessage( action.result.message, false, true );
				dialog_panel.load({ url: '<?php echo make_link('admin','') ?>' });
	        },
	        failure: function(form, action) {
	        	if( !action.result ) return;
				Ext.MessageBox.alert('Error!', action.result.error);
				statusBarMessage( action.result.error, false, true );
	        },
	        scope: userform,
	        // add some vars to the request, similar to hidden fields
	        params: {option: 'com_extplorer', 
	        		user: '<?php echo @$data[0] ?>',
	        		action: 'admin', 
	        		action2: '<?php echo @$data[0] ? 'edituser' : 'adduser' ?>',
	        		confirm: 'true'
	        }
	    })
	});
	userform.addButton('<?php echo ext_Lang::msg( 'btncancel', true ) ?>', 
		function() { 
			dialog_panel.load({ url: '<?php echo make_link('admin', '') ?>' });
		} 
	);
	userform.render('adminForm');
	</script>
	<?php
}
//------------------------------------------------------------------------------
function removeuser($dir) {			// Remove User
	$user=stripslashes($GLOBALS['__POST']["user"]);
	if($user==$GLOBALS['__SESSION']["s_user"]) {
		ext_Result::sendResult('removeuser', false, $GLOBALS["error_msg"]["miscselfremove"]);
	}
	if(!remove_user($user)) {
		ext_Result::sendResult('removeuser', false, $user.": ".$GLOBALS["error_msg"]["deluser"]);
	}
	ext_Result::sendResult('removeuser', true, $user." was successfully removed." );
	
}
//------------------------------------------------------------------------------
function show_admin($dir) {			// Execute Admin Action
	$pwd=(($GLOBALS["permissions"]&2)==2);
	$admin=(($GLOBALS["permissions"]&4)==4);
	
	if(!$GLOBALS["require_login"]) ext_Result::sendResult('admin', false, $GLOBALS["error_msg"]["miscnofunc"]);
	if(!$pwd && !$admin) ext_Result::sendResult('admin', false, $GLOBALS["error_msg"]["accessfunc"]);
	
	if(isset($GLOBALS['__GET']["action2"])) $action2 = $GLOBALS['__GET']["action2"];
	elseif(isset($GLOBALS['__POST']["action2"])) $action2 = $GLOBALS['__POST']["action2"];
	else $action2="";
	
	switch($action2) {
	case "chpwd":
		changepwd($dir);
	break;
	case "adduser":
		if(!$admin) ext_Result::sendResult('admin', false, $GLOBALS["error_msg"]["accessfunc"]);
		adduser($dir);
	break;
	case "edituser":
		if(!$admin) ext_Result::sendResult('admin', false, $GLOBALS["error_msg"]["accessfunc"]);
		edituser($dir);
	break;
	case "rmuser":
		if(!$admin) ext_Result::sendResult('admin', false, $GLOBALS["error_msg"]["accessfunc"]);
		removeuser($dir);
	break;
	default:
		admin($admin,$dir);
	}
}
//------------------------------------------------------------------------------

?>
