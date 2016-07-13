<script language="javascript">
function redirect_reboot(){
	setCurrentPage('reboot');
	processUpdater('getmain.php','fun=reboot');
}

var wepkey_array=["_wepkey1","_wepkey2","_wepkey3","_wepkey4"];
var wirelessRadioGroup1 = new Ext.form.RadioGroup({
	xtype:'radiogroup',
	width:'200',
	renderTo:'wireless_essid_broadcast_radio',
	items:[{
		boxLabel:'<{$gwords.enable}>',
		name:'_essid_broadcast',
		<{if $wireless.essid_broadcast =="1"}>checked:true,<{/if}>
		inputValue:1
	},{
		boxLabel:'<{$gwords.disable}>',
		name:'_essid_broadcast',
		<{if $wireless.essid_broadcast =="0"}>checked:true,<{/if}>
		inputValue:0
	}]
});

var wirelessRadioGroup2 = new Ext.form.RadioGroup({
	xtype:'radiogroup',
	width:'200',
	listeners: {change:{fn:function(r,c){
		if(c==1){
				Disable_Fn(1,"disable_wep");
				wirelessRadioGroup4.setDisabled(false);
				Ext.getCmp('wepkey_radio_group').setDisabled(false);
		}else{
			//wirelessRadioGroup3.setDisabled(true);
			wirelessRadioGroup4.setDisabled(true);
			Ext.getCmp('wepkey_radio_group').setDisabled(true);
			Disable_Fn(0,"disable_wep");
			//Disable_item(true,wepkey_array);
			select_widge_fixed();
		}
	}}},
	items:[{
		boxLabel:'<{$gwords.enable}>',
		name:'_wep_enabled',
		<{if $wireless.wep_enabled =="1"}>checked:true,<{/if}>
		inputValue:1
	},{
		boxLabel:'<{$gwords.disable}>',
		name:'_wep_enabled',
		<{if $wireless.wep_enabled =="0"}>checked:true,<{/if}>
		inputValue:0
	}],
	renderTo:'wireless_wep_enable_radio'
});

var wirelessRadioGroup3 = new Ext.form.RadioGroup({
	xtype:'radiogroup',
	width:'200',
	items:[{
		boxLabel:'<{$words.shared}>',
		name:'_authmode',
		<{if $wireless.authmode =="2"}>checked:true,<{/if}>
		inputValue:2
	},{
		boxLabel:'<{$words.opened}>',
		name:'_authmode',
		<{if $wireless.authmode =="0"}>checked:true,<{/if}>
		inputValue:0
	}],
	renderTo:'wireless_auth_mode_radio'
});

var wirelessRadioGroup4 = new Ext.form.RadioGroup({
	xtype:'radiogroup',
	width:'200',
	listeners: {change:{fn:function(r,c){
		if(c==1){
			key_length(10);
		}else{
			key_length(26);
		}
	}}},
	items:[{
		boxLabel:'<{$words.wep_64}>',
		name:'_wep_key_length',
		<{if $wireless.wep_key_length =="1"}>checked:true,<{/if}>
		inputValue:1
	},{
		boxLabel:'<{$words.wep_128}>',
		name:'_wep_key_length',
		<{if $wireless.wep_key_length =="5"}>checked:true,<{/if}>
		inputValue:5
	}],
	renderTo:'wireless_wepkey_length_radio'
});

var wirelessRadioGroup5 = new Ext.form.RadioGroup({
	xtype:'radiogroup',
	width:'200',
	listeners: {change:{fn:function(r,c){
		if(c==1){
			Disable_Fn(0,"disable_dhcp");
			select_widge_fixed();
		}else{
			Disable_Fn(1,"disable_dhcp");
		}
	}}},
	items:[{
		boxLabel:'<{$gwords.enable}>',
		name:'_dhcp',
		<{if $wireless.dhcp =="0"}>checked:true,<{/if}>
		inputValue:0
	},{
		boxLabel:'<{$gwords.disable}>',
		name:'_dhcp',
		<{if $wireless.dhcp =="1"}>checked:true,<{/if}>
		inputValue:1
	}],
	renderTo:'wireless_dhcp_server_radio'
});


var wirelessApplyBtn = new Ext.Button({
	type:'button',
	applyTo:'wireless_apply_btn',
	text:'<{$gwords.apply}>',
	handler: function() {
		check_validate(Ext.getDom('wireless_form'));
	}
});

var wepkey = new Ext.Panel({
	baseCls: 'x-plain',
	layout:'absolute',
	//border: true,
	defaultType: 'textfield',
	height:100,
	width:20,
	renderTo:'test_item',
	items: [{
		xtype: 'panel',
		x: 0,
		y: 0,
		items: {
			xtype: 'radiogroup',
			id:'wepkey_radio_group',
			columns: 1,
			items: [
				{boxLabel: '', name: '_wep_index', inputValue: '0'},
				{boxLabel: '', name: '_wep_index', inputValue: '1'},
				{boxLabel: '', name: '_wep_index', inputValue: '2'},
				{boxLabel: '', name: '_wep_index', inputValue: '3'}
			]
		}
	}]
});
Ext.getCmp('wepkey_radio_group').setValue('<{$wireless.wep_index}>');

var channel_store=new Ext.data.SimpleStore({
	fields:['channel'],
	data:[['1'],['2'],['3'],['4'],['5'],['6'],['7'],['8'],['9'],['10'],['11'],['12'],['13'],['14']]
});

var channel_combobox=new Ext.form.ComboBox({
	store:channel_store,
	renderTo:'wireless_channel_combobox',
	valueField :'channel',
	displayField:'channel',
	mode: 'local',
	forceSelection: true,
	editable: false,
	triggerAction: 'all',
	id: '_channel',
	name: '_channel',
	listWidth :50,
	width: 50
});
channel_combobox.setValue('<{$wireless.channel}>');

</script>
<fieldset class="x-fieldset"><legend class="legend"><{$words.wireless_title}></legend>
<form method=post name="wireless_form" id="wireless_form">
	<input type=hidden name="prefix" id="prefix" value="wireless">
	<input type=hidden id="_enable" name="_enable" value="1">
	<table border="0" cellspacing=1 cellpadding=0 name="nic_field">
		<tr>
			<td width="130">
				&nbsp;<{$words.mac}>:
			</td>
			<td colspan="2">
				<{$wireless.mac}>
			</td>
		</tr>
		<tr>
			<td>
				&nbsp;<{$gwords.ip}>:
			</td>
			<td colspan="2">
				<input name="_ip" id="_ip" value="<{$wireless.ip}>" class="x-form-text x-form-field">
			</td>
		</tr>
		<tr>
			<td>
				&nbsp;<{$words.netmask}>:
			</td>
			<td colspan="2">
				<input name="_netmask" id="_netmask" value="<{$wireless.netmask}>" class="x-form-text x-form-field">
			</td>
		</tr>
		<tr >
			<td>
				&nbsp;<{$words.essid}>:
			</td>
			<td colspan="2">
				<input name="_essid" id="_essid" value="<{$wireless.essid}>" maxlength="32" class="x-form-text x-form-field">
			</td>
		</tr>
		<tr>	
			<td>
				&nbsp;<{$words.essidbroadcast}>:
	    </td>
    	<td colspan="2">
    		<div id="wireless_essid_broadcast_radio"></div>
			</td>
		</tr>
		<tr>
			<td>
				&nbsp;<{$words.channel}>:
	    		</td>
			<td colspan="2">
				<div id='wireless_channel_combobox'></div>
			</td>
		</tr>
		<tr>
			<td>
      	&nbsp;<{$words.wepauthmode}>:
      </td>
			<td colspan="2">
				<div id="wireless_auth_mode_radio"></div>
      </td>
		</tr>
		<tr>	
			<td>
				&nbsp;<{$words.wepenabled}>:
	    </td>
			<td colspan="2">
				<div id="wireless_wep_enable_radio"></div>
			</td>
		</tr>
		<tr name="disable_wep" id="disable_wep">	
			<td>
				&nbsp;<{$words.wepekeylength}>:
	    </td>
    	<td colspan="2">
    		<div id="wireless_wepkey_length_radio"></div>
			</td>
		</tr>
		<tr name="disable_wep" id="disable_wep">
			<td>
				&nbsp;<{$words.wepkey1}>:
			</td>
			<td rowspan="4">
				<div id='test_item'></div>
			</td>
			<td>
					<input type="text" name="_wepkey1" id="_wepkey1" value="<{$wireless.wepkey1}>" maxlength="26" class="x-form-text x-form-field">(HEX)
			</td>			
		</tr>
		<tr name="disable_wep" id="disable_wep">
			<td>
				&nbsp;<{$words.wepkey2}>:
			</td>
			<td>
				<input type="text" name="_wepkey2" id="_wepkey2" value="<{$wireless.wepkey2}>" maxlength="26" class="x-form-text x-form-field">(HEX)
			</td>
		</tr>
		<tr name="disable_wep" id="disable_wep">
			<td>
				&nbsp;<{$words.wepkey3}>:
			</td>
			<td>
				<input type="text" name="_wepkey3" id="_wepkey3" value="<{$wireless.wepkey3}>" maxlength="26" class="x-form-text x-form-field">(HEX)
			</td>
		</tr>
		<tr name="disable_wep" id="disable_wep">
			<td>
				&nbsp;<{$words.wepkey4}>:
			</td>
			<td>
				<input type="text" name="_wepkey4" id="_wepkey4" value="<{$wireless.wepkey4}>" maxlength="26" class="x-form-text x-form-field">(HEX)
			</td>
		</tr>
		<tr>
			<td> 
				&nbsp;<{$words.dhcp}>:
			</td>
			<td colspan="2">
				<div id="wireless_dhcp_server_radio"></div>
			</td>					
		</tr>
		<tr name="disable_dhcp" id="disable_dhcp">
			<td>
				&nbsp;<{$words.startip}>:
			</td>
			<td colspan="2">
				<input name="_startip" id="_startip" value="<{$wireless.startip}>" class="x-form-text x-form-field">
			</td>
		</tr>
		<tr name="disable_dhcp" id="disable_dhcp">
			<td>
				&nbsp;<{$words.endip}>:
			</td>
			<td colspan="2">
				<input name="_endip" id="_endip" value="<{$wireless.endip}>" class="x-form-text x-form-field">
			</td>
		</tr>
		<tr>
			<td valign="top">
				&nbsp;<{$words.dns}>1:
			</td>
			<td colspan="2">
				<input name="_dns1" id="_dns1" value="<{$dns1}>" class="x-form-text x-form-field x-item-disabled" disabled readonly>
			</td>
		</tr>				
		<tr>
			<td valign="top">
				&nbsp;<{$words.dns}>2:
			</td>
			<td colspan="2">
				<input name="_dns2" id="_dns2" value="<{$dns2}>" class="x-form-text x-form-field x-item-disabled" disabled readonly>
			</td>
		</tr>				
		<tr>
			<td valign="top">
				&nbsp;<{$words.dns}>3:
			</td>
			<td colspan="2">
				<input name="_dns3" id="_dns3" value="<{$dns3}>" class="x-form-text x-form-field x-item-disabled" disabled readonly>
			</td>
		</tr>				
		<tr>
			<td>
				<div id="wireless_apply_btn"></div>
			</td>
		</tr>
	</table>
	<div style="visibility:hidden;position:absolute;top:-200px;left:-100px;width:0px;">
        	<input name="_wep" id="_wep" value="" class="x-form-text x-form-field">
		<input name="_tmp_ip" id="_tmp_ip" value="" class="x-form-text x-form-field">
		<input name="_tmp_mask" id="_tmp_mask" value="" class="x-form-text x-form-field">
		<input name="_chip" id="_chip" value="0" class="x-form-text x-form-field">
		<input name="_length" id="_length" value="10" class="x-form-text x-form-field">
	</div>
</form>

<script language="javascript">

function check_validate(thisForm){
	Ext.Msg.confirm("<{$words.wireless_title}>","<{$gwords.confirm}>",function(btn){
		if(btn=='yes'){
			processAjax('<{$form_action}>',<{$form_onload}>,thisForm);
		}
	});
}

function key_length(len){
	var key1 = document.getElementById("_wepkey1");
 	key1.maxLength = len;
	var key2 = document.getElementById("_wepkey2");
 	key2.maxLength = len;
	var key3 = document.getElementById("_wepkey3");
 	key3.maxLength = len;
	var key4 = document.getElementById("_wepkey4");
 	key4.maxLength = len;
}

function Disable_item(v,s){
	for(var c=0;c<s.length;c++){
		document.getElementById(s[c]).disabled=v;
		//Ext.getDom(s[c]).disabled=v;
	}
}

var static_ip = document.getElementsByName("_dhcp");
if(static_ip[0].checked)
        Disable_Fn(1,"disable_dhcp");
else{
        Disable_Fn(0,"disable_dhcp");
        select_widge_fixed();
}

var wep_enabled= document.getElementsByName("_wep_enabled");
if(wep_enabled[0].checked){
		Disable_Fn(1,"disable_wep");
		wirelessRadioGroup4.setDisabled(false);
		Ext.getCmp('wepkey_radio_group').setDisabled(false);
}else{
	wirelessRadioGroup4.setDisabled(true);
	Ext.getCmp('wepkey_radio_group').setDisabled(true);
	Disable_Fn(0,"disable_wep");
	select_widge_fixed();
}

var dhcp=document.getElementsByName('_dhcp');
if(dhcp[0].checked){
	Disable_Fn(1,"disable_dhcp");
}else{
	Disable_Fn(0,"disable_dhcp");
}

function select_widge_fixed(){
        var channel = document.getElementById('_channel');
        channel.style.visibility = 'visible';
}

</script>
