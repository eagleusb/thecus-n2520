<fieldset class="x-fieldset" style="margin: 10px;"><legend class="legend"><{$words.ads_title}></legend>
<form method="post" id="ads_form" name="ads_form">
	<input type=hidden name="prefix" id="prefix" value="ads">
	<table width="60%" border="0" cellspacing="4"  class="x-form-field">
		<tr>
			<td width="250">
				<{$words.work_group}> :
			</td>
			<td>
				<input type="text" name="_domain" id="_domain" style="width:200px" value="<{$domain}>" class="x-form-text x-form-field">
			</td>
		</tr>
		<tr>
			<td>
				<{$words.WindowsADSAccounts}> :
			</td>
			<td>
				<div id="ads_enable_radio"></div>
			</td>
		</tr>

        <tr  name="disable_ads" id="disable_ads">
                <td>
                    <{if $NAS_DB_KEY=="1"}>  
                        <{$words.AuthType}> :
                    <{/if}>  
                </td>
                <td>
                	<div id="ads_auth_radio"></div>
		</td>
	</tr>
		<tr name="disable_ads" id="disable_ads">
			<td>
				<{$words.server_name}> :
			</td>
			<td>
				<input type="text" name="_ip" id="_ip" required=1 size="15" maxlength="50" style="width:200px" value="<{$ip}>">
			</td>
		</tr>
		<tr name="disable_ads" id="disable_ads">
			<td>
				<{$words.realm}> :
			</td>
			<td>
				<input type="text" name="_realm" id="_realm" style="width:200px" value="<{$realm}>">
			</td>
		</tr>
		<tr name="disable_ads" id="disable_ads">
			<td>
				<{$words.admid}> :
			</td>
			<td>
				<input type="text" name="_admid" id="_admid" maxlength="64" title="adminid" required="1" style="width:200px" value="<{$admin_id}>">
			</td>
		</tr>
		<tr name="disable_ads" id="disable_ads">
			<td>
				<{$words.admin_passwd}> :
			</td>
			<td>
				<input type="password" name="_admpwd" id="_admpwd" vtype="password" style="width:200px" value="<{$admin_pwd}>">
			</td>
		</tr>	
		<tr>
			<td colspan="2">
				<table>
					<tr>
						<td>
							<div id='ads_apply_btn'></div>
						</td>
					</tr>
				</table>
			</td>
		</tr>
	</table>
	</span>
</form>

<script language="javascript">
var adsRadioGroup1 = new Ext.form.RadioGroup({
	xtype:'radiogroup',
    //width: 250,
	columns: 2,
	listeners: {change:{fn:function(r,c){
		if(c==1){
			Disable_Fn(1,"disable_ads");
			adsRadioGroup2.setDisabled(false);
		}else{
			Disable_Fn(0,"disable_ads");
			adsRadioGroup2.setDisabled(true);
		}
	}}},
	items:[{
		boxLabel:'<{$gwords.enable}>',
		name:'_enable',
		<{if $enabled =="1"}>checked:true,<{/if}>
		inputValue:1
	},{
		boxLabel:'<{$gwords.disable}>',
		name:'_enable',
		<{if $enabled =="0"}>checked:true,<{/if}>
		inputValue:0
	}],
	renderTo:'ads_enable_radio'
});
var adsRadioGroup2 = new Ext.form.RadioGroup({
	xtype:'radiogroup',
	<{if $NAS_DB_KEY=="2"}>hidden: true,<{/if}>
	items:[{
		boxLabel:'<{$words.AuthByAds}>',
		name:'_AuthType',
		<{if $auth_type =="ads"}>checked:true,<{/if}>
		inputValue:'ads'
	},{
		boxLabel:'<{$words.AuthByNt}>',
		name:'_AuthType',
		<{if $auth_type =="nt"}>checked:true,<{/if}>
		inputValue:'nt'
	}],
	renderTo:'ads_auth_radio'
});
var adsApplyBtn = new Ext.Button({
	type:'button',
	applyTo:'ads_apply_btn',
	text:'<{$gwords.apply}>',
	handler: function() {
		checkform(Ext.getDom('ads_form'));
	}
});

var ads_account = document.getElementsByName("_enable");
if(ads_account[0].checked){
	Disable_Fn(1,"disable_ads");
	adsRadioGroup2.setDisabled(false);
}else{
	Disable_Fn(0,"disable_ads");
	adsRadioGroup2.setDisabled(true);
}

function checkform(thisForm){
	Ext.Msg.confirm("<{$words.ads_title}>","<{$gwords.confirm}>",function(btn){
		if(btn=="yes"){
			processAjax('<{$form_action}>',<{$form_onload}>,thisForm);
		}
	});
}
</script>
