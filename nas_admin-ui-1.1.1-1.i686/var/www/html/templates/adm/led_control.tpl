<fieldset class="x-fieldset" style="margin: 10px;">
    <legend class="legend"><{$words.led_control_title}></legend>
    <div id="bonjour"> </div>
</fieldset>

<script type="text/javascript">
function ExtDestroy(){ 
 Ext.destroy(
        Ext.getCmp('led_radio'),
        Ext.getCmp('ledpanel')
    );  
}

/*
* execute bonjour setting.
* @param none
* @returns none.
*/   
function check_validate()
{
  Ext.Msg.confirm('<{$words.led_control_title}>',"<{$gwords.confirm}>",function(btn){
    if(btn=='yes') 
    {
      processAjax('<{$form_action}>',onLoadForm,ledpanel.getForm().getValues(true));        
    }})
}

//led enable or disable
var led_radio= new Ext.form.RadioGroup({
  id:'_enable',
  width: 300,
  fieldLabel: '&nbsp;<{$words.led_logo_service}>',
  items: [
           {boxLabel: '<{$gwords.enable}>', name: '_enable', inputValue: 1},
           {boxLabel: '<{$gwords.disable}>', name: '_enable', inputValue: 0}
          ]  
})

led_radio.items[<{$LOGO1_enabled}>].checked = true;
 
//led form  
var ledpanel = new Ext.FormPanel({
  id:'ledform', 
  labelWidth: 150,
  method: 'POST',
  waitMsgTarget : true,
  renderTo : 'bonjour',
  bodyStyle: 'padding:0 10px',
  buttonAlign :'left',
  items: [led_radio],
  buttons : [{
               text : '<{$gwords.apply}>',
               disabled : false,
               handler : function() {
                 if (ledpanel.form.isValid()) {
                     check_validate();
                 } 
               }
            }]
}); 
   
ledpanel.render();

</script>
