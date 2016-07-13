<script language="javascript">
var ldapRadioGroup1 = new Ext.form.RadioGroup({
    xtype:'radiogroup',
    listeners: {change:{fn:function(r,c){
        if(c==1){
            Disable_Fn(1,"disable_ldap");
            tls_combo.enable();
        }else{
            Disable_Fn(0,"disable_ldap");
            tls_combo.disable();
            ldapApplytestBtn.disable();
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
    renderTo:'ldap_enable_radio'
});

var tls_store = new Ext.data.SimpleStore({
    fields: <{$tls_fields}>,
    data: <{$tls_data}>
});

var tls_combo = new Ext.form.ComboBox({        
    name: '_tls',
    labelWidth: 125,
    listWidth: 60,
    width: 60,
    mode: 'local',
    store: tls_store,
    displayField: 'display',
    valueField: 'value',
    readOnly: false,
    typeAhead: true,
    editable: false,
    selectOnFocus:true,
    triggerAction: 'all',
    renderTo:'ldap_tls',
    items: [{
         xtype: 'combo',
         id: '_tls',
         hiddenName: '_tls_selected'
    }]        
});

    
var ldapApplyBtn = new Ext.Button({
    type:'button',
    applyTo:'ldap_apply_btn',
    text:'<{$gwords.apply}>',
    handler: function() {
        checkform(Ext.getDom('ldap_form'));
    }
});

var ldapApplytestBtn = new Ext.Button({
    type:'button',
    applyTo:'ldap_apply_test_btn',
    text:'<{$words.check_cb}>',
    handler: function() {
        checkform2(Ext.getDom('ldap_form'));
    }
});
</script>

<fieldset class="x-fieldset"><legend class="legend"><{$words.ldap_title}></legend>
<form method="post" id="ldap_form" name="ldap_form">
    <input type=hidden name="prefix" id="prefix" value="ldap">
    <table width="60%" border="0" cellspacing="4"  class="x-form-field">
        <tr>
            <td style="width:160px;">
                <{$words.ldap_client}> :
            </td>
            <td>
                <div id="ldap_enable_radio"></div>
            </td>
        </tr>
        <tr name="disable_ldap" id="disable_ldap">
            <td>
                <{$words.ldap_server_ip}> :
            </td>
            <td>
                <input type="text" name="_ldap_server_ip" id="_ldap_server_ip" required=1 size="15" maxlength="50" style="width:150px" value="<{$ldap_server_ip}>">
            </td>
        </tr>
        <tr name="disable_ldap" id="disable_ldap">
            <td>
                <{$words.domain_name}> :
            </td>
            <td>
                <input type="text" name="_domain_name" id="_domain_name" style="width:150px" value="<{$domain_name}>">
                (ex:dc=example,dc=com)
            </td>
        </tr>
        <tr name="disable_ldap" id="disable_ldap">
            <td>
                <{$words.user_name}> :
            </td>
            <td>
                <input type="text" name="_user_name" id="_user_name" maxlength="64" title="adminid" required="1" style="width:150px" value="<{$user_name}>">
            </td>
        </tr>
        <tr name="disable_ldap" id="disable_ldap">
            <td>
                <{$words.user_passwd}> :
            </td>
            <td>
                <input type="password" name="_user_passwd" id="_user_passwd" vtype="password" style="width:150px" value="<{$user_passwd}>">
            </td>
        </tr>	
        <tr name="disable_ldap" id="disable_ldap">
            <td>
                <{$words.user_dn}> :
            </td>
            <td>
                <input type="text" name="_user_dn" id="_user_dn" style="width:150px" value="<{$user_dn}>">
            </td>
        </tr>
        <tr name="disable_ldap" id="disable_ldap">
            <td>
                <{$words.group_dn}> :
            </td>
            <td>
                <input type="text" name="_group_dn" id="_group_dn" style="width:150px" value="<{$group_dn}>">
            </td>
        </tr>
        <tr>
            <td>
                <{$words.ldap_security}> :
            </td>
            <td>
                <div id="ldap_tls"></div>
            </td>
        </tr>   
        <tr>
            <td>
                <{$words.samba_sid}> :
            </td>
            <td>
                <{$samba_sid}>
            </td>
        </tr>   
        <tr>
            <td colspan="1">
                <table>
                    <tr>
                        <td style="width:50%;">
                            <span id='ldap_apply_test_btn'></span>
                        </td>
                        <td>
                            <span id='ldap_apply_btn'></span>
                        </td>
                    </tr>
                </table>
            </td>
            <td colspan="2"></td>
        </tr>
    </table>
</form>
</fieldset>

<script language="javascript">
var ldap_account = document.getElementsByName("_enable");
if(ldap_account[0].checked){
    Disable_Fn(1,"disable_ldap");
    tls_combo.enable();
    ldapApplytestBtn.enable();
}else{
    Disable_Fn(0,"disable_ldap");
    tls_combo.disable();
    ldapApplytestBtn.disable();
}

tls_combo.setValue('<{$tls_value}>');

function checkform(thisForm){
    if(ldap_account[0].checked){
        Ext.Msg.confirm("<{$words.ldap_title}>","<{$words.ldap_start}>",function(btn){
            if(btn=="yes"){
                processAjax('<{$form_action}>',<{$form_onload}>,thisForm);
            }
        });
        ldapApplytestBtn.enable();
    }else{
        Ext.Msg.confirm("<{$words.ldap_title}>","<{$words.ldap_stop}>",function(btn){
            if(btn=="yes"){
                processAjax('<{$form_action}>',<{$form_onload}>,thisForm);
            }
        });
        ldapApplytestBtn.disable();
    }
}

function checkform2(thisForm){
    processAjax('<{$form_action2}>',<{$form_onload}>,thisForm);
}

</script>

<fieldset class="x-fieldset" style="margin: 10px;"><legend class="legend"><{$gwords.description}></legend>
<form id="upsform" name="upsform" method="post">
<input type="hidden" name="ups_option" id="ups_option" value="<{$words.ldap_description}>" >
<table width="100%" border="0" cellspacing="4"  class="x-form-field">
  <tr name="ups_tr" id="ups_tr">
  <td><div align="left"><{$words.ldap_description}></div></td>
  </tr>
</table>
</fieldset>

