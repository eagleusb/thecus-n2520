<fieldset class="x-fieldset" style="margin: 10px;">
    <legend class="legend"><{$words.thumbnail_title}></legend>
    <div id="outerform"> </div>
</fieldset>

<script language="javascript">
function ExtDestroy(){ 
  Ext.destroy(
            Ext.getCmp('thumbnail_radiogroup'),
            Ext.getCmp('fp')
  );
}

function check_validate()
{
  Ext.Msg.confirm('<{$words.thumbnail_title}>',"<{$gwords.confirm}>",function(btn){
    if(btn=='yes')
    {
      processAjax('<{$form_action}>',onLoadForm,fp.getForm().getValues(true));
    }})
}

var thumbnail_radiogroup = new Ext.form.RadioGroup({
    id:'_enable',
    width: 200,
    fieldLabel: "<{$words.thumbnail_service}>",
    items: [
        {boxLabel: "<{$gwords.enable}>", name: '_enable', inputValue: 1 <{if $thumbnail_enabled =="1"}>, checked:true <{/if}>},
        {boxLabel: "<{$gwords.disable}>", name: '_enable', inputValue: 0 <{if $thumbnail_enabled =="0" || $thumbnail_enabled ==""}>, checked:true <{/if}>}
    ]
})


//thumbnail form
var fp = new Ext.FormPanel({
    id:'thumbnailform',
    method: 'POST',
    labelWidth: 110,
    waitMsgTarget : true,
    renderTo : 'outerform',
    bodyStyle: 'padding:0 10px 0;',
    items: [thumbnail_radiogroup],
    buttonAlign:'left',
    buttons : [{
                  text : '<{$gwords.apply}>',
                  disabled : false,
                  handler : function() {
                      if (fp.form.isValid()) {
                          check_validate();
                      }
                  }
              }]
});

fp.render();
</script>

<fieldset class="x-fieldset" style="margin: 10px;"><legend class="legend"><{$gwords.description}></legend>
<form id="upsform" name="upsform" method="post">
<input type="hidden" name="ups_option" id="ups_option" value="<{$words.thumbnail_desc}>" >
<table width="100%" border="0" cellspacing="4"  class="x-form-field">
  <tr name="ups_tr" id="ups_tr">
    <td><div align="left"><li><{$words.thumbnail_desc}></li></div></td>
  </tr>
</table>
</fieldset>

