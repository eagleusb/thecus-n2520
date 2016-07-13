<script type="text/javascript">
/*
* execute wol setting.
* @param none
* @returns none.
*/   
function check_validate()
{
  Ext.Msg.confirm("<{$words.wol}>","<{$gwords.confirm}>",function(btn){
    if(btn=='yes') 
    {
      processAjax('<{$form_action}>',onLoadForm,wolpanel.items.get(0).getForm().getValues(true));
    }})
}

//wol enable or disable
var en_radio= new Ext.form.RadioGroup({
  columns: 2,
  fieldLabel: '&nbsp;<{$words.wol}>',
  items: [
           {boxLabel: '<{$gwords.enable}>', name: '_wol_enabled', inputValue: 1},
           {boxLabel: '<{$gwords.disable}>', name: '_wol_enabled', inputValue: 0}
          ]  
})

en_radio.items[<{$wol_enabled}>].checked = true;

//Wan: wol enable or disable
var wan_wol_radio= new Ext.form.RadioGroup({
  columns: 2,
  fieldLabel: <{if $wkonlan=='1'}>'&nbsp;<{$gwords.wan}>'<{else}>'&nbsp;<{$words.wol}>'<{/if}>,
  items: [
           {boxLabel: '<{$gwords.enable}>', name: '_wan_wol_enabled', inputValue: 1},
           {boxLabel: '<{$gwords.disable}>', name: '_wan_wol_enabled', inputValue: 0}
          ]  
});

wan_wol_radio.items[<{$wol_wan}>].checked = true;

//Lan: wol enable or disable
var lan_wol_radio= new Ext.form.RadioGroup({
  columns: 2,
  fieldLabel: '&nbsp;<{$gwords.lan}>',
  items: [
           {boxLabel: '<{$gwords.enable}>', name: '_lan_wol_enabled', inputValue: 1},
           {boxLabel: '<{$gwords.disable}>', name: '_lan_wol_enabled', inputValue: 0}
          ]  
});

lan_wol_radio.items[<{$wol_lan}>].checked = true;

//wol form  
var wolpanel = TCode.desktop.Group.addComponent({
    xtype: 'fieldset',
    title: '<{$words.wakeUP_title}>',
    autoHeight:true,
    collapsed: false,
    items:{
        xtype:'form',
        method: 'POST',
        waitMsgTarget : true,
        labelWidth:210,
        bodyStyle: 'padding:0 10px',
        buttonAlign :'left',
        items: [
            <{ if $wan_lan=="1"}>
            en_radio
            <{/if}>
            <{ if $wan_lan=="2"}>
            wan_wol_radio<{if $wkonlan=='1'}>, lan_wol_radio<{/if}>
            <{/if}>
        ],
        buttons : [{
            text : '<{$gwords.apply}>',
            disabled : false,
            handler : function() {
                if (wolpanel.items.get(0).getForm().isValid()) {
                   check_validate();
                }
            }
        }]
    }
}); 

</script>
