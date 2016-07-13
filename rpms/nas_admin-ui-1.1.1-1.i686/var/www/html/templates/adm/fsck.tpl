<fieldset class="x-fieldset" style="margin: 10px;"><legend class="legend"><{$words.fsck_title}></legend>
<tr><td><{$words.ApplySuccess}></td></tr>
<tr><td><div id='template_site' name='template_site'></div></td></tr>
<div id='fsck_form'></div>
</fieldset>

<script type="text/javascript">
var zfs_limit_html='<b><span style="color:red"><{$words.fsck_limit_fs}></span></b><br>';
var encrypt_limit_html='<b><span style="color:red"><{$words.fsck_limit_encrypt}></span></b><br>';
var apply_msg_html='<{$apply_msg}>';
//var html='<span style="color:red"><{$words.fsck_limit_fs}></span><br><{$apply_msg}>';
var tpl = new Ext.Template(<{if $fs_zfs=='1'}>zfs_limit_html,<{/if}>apply_msg_html);

var fsck_form = new Ext.FormPanel({
	baseCls: 'x-plain',
	layout:'absolute',
	height:40,
	defaultType: 'textfield',
	renderTo:'fsck_form',
	items:[{
		xtype: 'panel',
		x:0,
		y:15,
		items:{
			xtype:'button',
			text:'<{$gwords.apply}>',
			handler: function(){
				Ext.Msg.confirm("<{$words.fsck_title}>","<{$gwords.confirm}>",function(btn){
					if(btn=="yes"){
						processAjax('setmain.php?fun=setfsck&reboot=1',onLoadForm,document.fsck_form);
					}
				});
			}
		}
	}]
});

<{if $fs_zfs==1 || $encrypt_raid==1}>
	tpl.append(document.getElementById('template_site'));
<{/if}>

function check_validate(){
	Ext.Msg.confirm('<{$words.fsck_title}>',"<{$confirm_msg}>",function(btn){
	if(btn=='yes')
		processAjax('function/setfsck.php?reboot=1',onLoadForm,document.fsck_form);
	})
}
</script>
