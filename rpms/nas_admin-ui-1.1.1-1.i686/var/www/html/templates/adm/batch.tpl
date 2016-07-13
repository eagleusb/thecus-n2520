<fieldset class="x-fieldset" style="margin: 10px;"><legend class="legend"><{$words.batch_title}></legend>
<div id="import_form" name="import_form"></div>

<script language="javascript">
var fp = new Ext.FormPanel({
        fileUpload: true,
        height:300,
        renderTo: 'import_form',
        frame: false,
        baseCls: 'x-plain',
        layout:'absolute',
        defaults: {
            msgTarget: 'side'
        },
        defaultType: 'textfield',
        items: [{
        	x:0,
		y:0,
		xtype: 'fileuploadfield',
		id: 'batch_file',
		name: 'batch_file',
		emptyText: '<{$words.choose_file_prompt}>',
		width:400,
		buttonCfg: {
			text: '',
			iconCls: 'upload-icon'
		}
	},{
		xtype: 'panel',
		x:410,
		y:0,
		items:{
			xtype:'button',
			text:'<{$gwords.import}>',
			handler: function(){
				var batch_file=document.getElementById('batch_file').value;
				if(batch_file != "<{$words.choose_file_prompt}>" && batch_file != ""){
					fp.getForm().submit({
						url: 'setmain.php?fun=setbatch&import=1',
						waitMsg: "<{$gwords.upload}>.....",
						success: function(fp, o){
							if(o.result.content!=null){
								document.getElementById('batch_content').value=o.result.content;
								//document.getElementById('batch_file').value='<{$words.choose_file_prompt}>';
							}
						}
					});
				}else{
					Ext.Msg.alert("test","<{$words.choose_file_prompt}>");
					return false;
				}
			}
		}
	},{
		x: 0,
		y: 30,
		xtype: 'textarea',
		id: 'batch_content',
		name: 'batch_content',
		id: 'batch_content',
		anchor: '76% 90%'
		//fieldLabel: ''
	},{
		xtype: 'panel',
		x:0,
		y:275,
		items:{
			xtype:'button',
			text:'<{$gwords.apply}>',
			handler: function(){
				Ext.Msg.confirm("<{$words.batch_title}>","<{$words.batch_confirm}>",function(btn){
					if(btn=="yes"){
						processAjax('<{$form_action}>',onLoadForm,fp.getForm().getValues(true));
					}
				});
			}
		}
        }]
});
</script></fieldset>




<fieldset class="x-fieldset" style="margin: 10px;"><legend class="legend"><{$gwords.description}></legend>
<form id="upsform" name="upsform" method="post">
<input type="hidden" name="ups_option" id="ups_option" value="<{$words.batch_description}>" >
<table width="100%" border="0" cellspacing="4"  class="x-form-field">
  <tr name="ups_tr" id="ups_tr">
  <td><div align="left"><{$words.batch_description}></div></td>
  </tr>
</table>
</fieldset>


