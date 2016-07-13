<fieldset class="x-fieldset" style="margin: 10px;">
    <legend class="legend"><{$words.bonjour_title}></legend>
    <div id="bonjour"> </div>
</fieldset>

<script type="text/javascript">
function ExtDestroy(){ 
 Ext.destroy(
        Ext.getCmp('en_radio'),
        Ext.getCmp('bonjourpanel')
    );  
}

/*
* execute bonjour setting.
* @param none
* @returns none.
*/   
function check_validate()
{
  Ext.Msg.confirm('<{$words.bonjour_title}>',"<{$gwords.confirm}>",function(btn){
    if(btn=='yes') 
    {
      processAjax('<{$form_action}>',onLoadForm,bonjourpanel.getForm().getValues(true));        
    }})
}

//bonjour enable or disable
var en_radio= new Ext.form.RadioGroup({
  id:'_enable',
  width: 300,
  fieldLabel: '&nbsp;<{$words.bonjour_service}>',
  items: [
           {boxLabel: '<{$gwords.enable}>', name: '_enable', inputValue: 1},
           {boxLabel: '<{$gwords.disable}>', name: '_enable', inputValue: 0}
          ]  
})

en_radio.items[<{$bonjour_enabled}>].checked = true;
 
//bonjour form  
var bonjourpanel = new Ext.FormPanel({
  id:'bonjourform', 
  labelWidth: 150,
  method: 'POST',
  waitMsgTarget : true,
  renderTo : 'bonjour',
  bodyStyle: 'padding:0 10px',
  buttonAlign :'left',
  items: [en_radio],
  buttons : [{
               text : '<{$gwords.apply}>',
               disabled : false,
               handler : function() {
                 if (bonjourpanel.form.isValid()) {
                     check_validate();
                 } 
               }
            }]
}); 
   
bonjourpanel.render();

</script>
