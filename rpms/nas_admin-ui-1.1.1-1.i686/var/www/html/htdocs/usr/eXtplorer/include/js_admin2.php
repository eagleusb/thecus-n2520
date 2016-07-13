<?php
/** ensure this file is being included by a parent file */
if( !defined( '_JEXEC' ) && !defined( '_VALID_MOS' ) ) die( 'Restricted access' );
?>
<script type="text/javascript">
//<!--
	function check_pwd() {
		if(userform.findField('nuser').getValue()=="" || userform.findField('home_dir').getValue()=="") {
			Ext.Msg.alert('Status', "<?php echo ext_Lang::err('miscfieldmissed', true ); ?>");
			return false;
		}
		if(userform.findField('pass1').getValue() != userform.findField('pass2').getValue())
		{			
			Ext.Msg.alert('Status', "<?php echo ext_Lang::err('miscnopassmatch', true ); ?>");
			return false;
		}
		return true;
	}
// -->
</script>
