 <form id="form_snmp" name="form_snmp" method="post" style="margin: 10px;">
<table width="90%" border="0" cellspacing="4"  class="x-form-field">
  <tr>
    <td><div align="left"><{$words.snmp}>:</div></td>
    <td><div id="snmp_radio"></div> 
    </td>
  </tr>
  <tr name="snmp_tr" id="snmp_tr">
    <td><div align="left"><{$words.snmp_read_comm}>:</div></td>
    <td><input name="_snmp_read_comm" id="_snmp_read_comm" type="text" class="x-form-text" size="35" value="<{$snmp_read_comm}>" />
    <span class="style1">&nbsp;&nbsp;<span style="color:red">(<{$words.comm_limit}>)</span></span></td>
  </tr>
  <tr name="snmp_tr" id="snmp_tr">
    <td><div align="left"><{$words.snmp_sys_contact}>:</div></td>
    <td><input type="text" name="_snmp_sys_contact" id="_snmp_sys_contact"  class="x-form-text" size="35" value="<{$snmp_sys_contact}>"/></td>
  </tr>
  <tr name="snmp_tr" id="snmp_tr">
    <td><div align="left"><{$words.snmp_sys_locate}>:</div></td>
    <td><input type="text" name="_snmp_sys_locate" id="_snmp_sys_locate" value="<{$snmp_sys_locate}>"  class="x-form-text" size="35" /></td>
  </tr>
  <{foreach from=$snmp_trap_target_ip key=k item=val}>
      <tr name="snmp_tr" id="snmp_tr">
        <td><div align="left"><{$words.snmp_trap_target_ip}><{$k}>:</div></td>
        <td><input type="text" name="_snmp_trap_target_ip<{$k}>" id="_snmp_trap_target_ip<{$k}>" value="<{$val}>"  class="x-form-text" size="35"/></td>
      </tr>
  <{/foreach}>
  <tr>
    <td><div id='snmp_btn'></div></td>
    <td> 
    </td>
  </tr>
</table>  
</form>


<script type="text/javascript">
Disable_Fn(<{$snmp_enabled}>,'snmp_tr');

new Ext.Button({ 
  type:'button',
  applyTo:'snmp_btn',
  text:'<{$gwords.apply}>',
  minWidth :80,
  handler: function() {
	  	Ext.Msg.confirm("<{$words.snmp_title}>", "<{$gwords.confirm}>" , function(btn){ 
	        if(btn=='yes'){  
	            processAjax('<{$form_action}>',<{$form_onload}>,document.getElementById('form_snmp')); 
	        }
	    });
    
  }
}); 

new Ext.form.RadioGroup({
      xtype: 'radiogroup',
      fieldLabel: '<{$words.snmp}>', 
      renderTo:'snmp_radio',
      columns: 2,
      listeners: {change:{fn:function(r,c){ 
                      if(c==1){  
                          Disable_Fn(1,'snmp_tr'); 
                      }else{ 
                          Disable_Fn(0,'snmp_tr'); 
                      }
      }}},
      items: [
          {boxLabel: '<{$gwords.enable}>',name: '_snmp_enabled', inputValue: 1 <{if $snmp_enabled =="1"}>, checked:true <{/if}>},
          {boxLabel: '<{$gwords.disable}>', name: '_snmp_enabled',  inputValue: 0 <{if $snmp_enabled =="0"}>, checked:true <{/if}>} 
      ] 
});

</script> 
