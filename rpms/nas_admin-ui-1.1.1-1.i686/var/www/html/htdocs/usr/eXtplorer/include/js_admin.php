<?php
/** ensure this file is being included by a parent file */
if( !defined( '_JEXEC' ) && !defined( '_VALID_MOS' ) ) die( 'Restricted access' );
?>
<script type="text/javascript">
//<!--
	function check_pwd() {
		if(PassForm.findField('newpwd1').getValue() != PassForm.findField('newpwd2').getValue() ) {
			Ext.Msg.alert("<?php echo ext_Lang::msg('miscchpass',true);?>","<?php echo ext_Lang::err('miscnopassmatch', true ); ?>");
			return false;
		}
		if(PassForm.findField('oldpwd').getValue() ==PassForm.findField('newpwd1').getValue()) {
			Ext.Msg.alert("<?php echo ext_Lang::msg('miscchpass',true);?>","<?php echo ext_Lang::err('miscnopassdiff', true ); ?>");
			//alert("<?php echo ext_Lang::err('miscnopassdiff', true ); ?>");
			return false;
		}
		return true;
	}
	
	
	// Edit / Delete
	
	function Edit() {
		document.userform.action2.value = "edituser";
		document.userform.submit();
	}
	
	function Delete() {
		var ml = document.userform;
		var len = ml.elements.length;
		var user;
		for (var i=0; i<len; ++i) {
			var e = ml.elements[i];
			if(e.name == "user" && e.checked) {
				user=e.value;
				break;
			}
		}
		
		if(confirm("<?php echo $GLOBALS["error_msg"]["miscdeluser"]; ?>")) {
			document.userform.action2.value = "rmuser";
			document.userform.submit();
		}
	}

// -->
</script>
