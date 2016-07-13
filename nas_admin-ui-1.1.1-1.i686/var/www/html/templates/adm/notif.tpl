<div id="notifform"></div>

<script language="javascript">

Ext.onReady(function(){
    Ext.QuickTips.init();
    // turn on validation errors beside the field globally
    Ext.form.Field.prototype.msgTarget = 'side';

    var prefix = new Ext.form.Hidden({id: 'prefix', name: 'prefix', value: 'notif'});
    var enableCheck = new Ext.form.Hidden({id: 'enableCheck', name: 'enableCheck', value: '1'});

    var auth_store = new Ext.data.SimpleStore({
        fields: <{$notif_auth_fields}>,
        data: <{$notif_auth_data}>
    });
    
    var auth_combo = new Ext.form.ComboBox({
        xtype: 'combo',
        name: '_auth',
        id: '_auth',
        hiddenName: '_auth_selected',
        fieldLabel: "<{$words.email_auth}>",
        labelSeparator: ':',
        hideLabel: false,
        mode: 'local',
        store: auth_store,
        displayField: 'display',
        valueField: 'value',
        readOnly: true,
        typeAhead: true,
        selectOnFocus:true,
        triggerAction: 'all',
        listeners:{
            select:function(combo, record,index){
                if (combo.value == 'gmail') {
                    Ext.getCmp("_ssl").setValue("tls");
                    Ext.getCmp("_smtport").setValue(587);
                    Ext.getCmp("_from").setValue("");
                    Ext.getCmp("_from").disable();
                } else {
                    Ext.getCmp("_from").setValue("<{$notif_sender}>");
                    Ext.getCmp("_from").enable();
                }
            }
        }
    });
    
    var level_store = new Ext.data.SimpleStore({
        fields: <{$notif_level_fields}>,
        data: <{$notif_level_data}>
    });
    
    var level_combo = new Ext.form.ComboBox({
        xtype: 'combo',
        name: '_level',
        id: '_level',
        hiddenName: '_level_selected',
        fieldLabel: "<{$words.log_level}>",
        labelSeparator: ':',
        hideLabel: false,
        mode: 'local',
        store: level_store,
        displayField: 'display',
        valueField: 'value',
        readOnly: true,
        listWidth:130,
        typeAhead: true,
        selectOnFocus:true,
        triggerAction: 'all'
    });
    
    var ssl_store = new Ext.data.SimpleStore({
        fields: <{$notif_ssl_fields}>,
        data: <{$notif_ssl_data}>
    });
    
    var ssl_combo = new Ext.form.ComboBox({
        xtype: 'combo',
        name: '_ssl',
        id: '_ssl',
        hiddenName: '_ssl_selected',
        fieldLabel: "<{$words.email_ssl}>",
        labelSeparator: ':',
        hideLabel: false,
        mode: 'local',
        store: ssl_store,
        displayField: 'display',
        valueField: 'value',
        readOnly: true,
        listWidth:130,
        typeAhead: true,
        selectOnFocus:true,
        triggerAction: 'all',
        listeners:{
            select:function(combo, record,index){
                if (combo.value == 'ssl') {
                    Ext.getCmp("_smtport").setValue(465);
                } else if (combo.value == 'tls') {
                    Ext.getCmp("_smtport").setValue(587);
                } else {
                    Ext.getCmp("_smtport").setValue(25);
                }
            }
        }

    });

    var beep_radiogroup = new Ext.form.RadioGroup({
        xtype: 'radiogroup',
        fieldLabel: "<{$words.beep_alert_notification}>",
        labelSeparator: '',
        width: 290,
        hideLabel: false,
        //listeners: {change:{fn:function(){alert('radio changed');}}},
        items: [
            {boxLabel: '<{$gwords.enable}>', name: '_beep', inputValue: 1 <{if $notif_beep =="1"}>, checked:true <{/if}>},
            {boxLabel: '<{$gwords.disable}>', name: '_beep', inputValue: 0 <{if $notif_beep =="0" || $notif_beep ==""}>, checked:true <{/if}>}
        ]
    });

    var mail_radiogroup = new Ext.form.RadioGroup({
        xtype: 'radiogroup',
        fieldLabel: "<{$words.email_alert_notification}>",
        labelSeparator: '',
        width: 290,
        hideLabel: false,
        listeners: {change: handleFormDisabled},
        items: [
            {boxLabel: '<{$gwords.enable}>', name: '_mail', inputValue: 1 <{if $notif_mail =="1"}>, checked:true <{/if}>},
            {boxLabel: '<{$gwords.disable}>', name: '_mail', inputValue: 0 <{if $notif_mail =="0" || $notif_mail ==""}>, checked:true <{/if}>}
        ]
    });
    
    
    var Led_radiogroup = new Ext.form.RadioGroup({
        xtype: 'radiogroup',
        fieldLabel: "<{$words.led_alert_notification}>",
        labelSeparator: '',
        width: 290,
        hideLabel: false,
        items: [
            {boxLabel: '<{$gwords.enable}>', name: '_led', inputValue: 1 <{if $warn_led =="1"}>, checked:true <{/if}> },
            {boxLabel: '<{$gwords.disable}>', name: '_led', inputValue: 0 <{if $warn_led =="0" || $warn_led ==""}>, checked:true <{/if}>}
        ]
    });
    
    var fp = new Ext.FormPanel({
        labelWidth: 220,
        renderTo:'notifform',
        bodyStyle: 'padding:0 10px 0;',
        width:830,
        items: [
            prefix,
            {
                /*====================================================================
                * notif IP
                *====================================================================*/
                xtype:'fieldset',
                title: '<{$words.notif_title}>',
                autoHeight: true,
                layout: 'form',
                items: [
                    <{if $buzzer == '1'}>
                    beep_radiogroup,
                    <{/if}>
                    
                    <{if $led == '1'}>
                    Led_radiogroup,
                    <{/if}>
                    
                    mail_radiogroup,
                    auth_combo ,
                    ssl_combo,
                    {
                        layout:'column',
                        width: 770,
                        // defaults for columns
                        defaults:{
                            layout:'form',
                            border:false,
                            xtype:'panel'
                        },
                        items:[{
                            columnWidth: 0.5,
                            items:[{
                                xtype: 'textfield',
                                name: '_smtp',
                                id: '_smtp',
                                hideLabel: false,
                                fieldLabel: "<{$words.email_hostname}>",
                                labelSeparator: ':',
                                maxLength:60,
                                value: '<{$notif_smtp}>'
                            }]
                        },{
                            labelWidth:0,
                            items:[{
                                xtype: 'textfield',
                                name: '_smtport',
                                id: '_smtport',
                                hideLabel: false,
                                fieldLabel: "<{$gwords.port}>",
                                labelSeparator: ':',
                                labelStyle: 'text-align:right;',
                                maxLength:5,
                                width:50,
                                value: '<{$notif_smtport}>'
                            }]
                        }]
                    },
                    {
                        xtype: 'textfield',
                        name: '_account',
                        id: '_account',
                        hideLabel: false,
                        fieldLabel: "<{$words.email_account}>",
                        labelSeparator: ':',
                        maxLength:32,
                        value: '<{$notif_account}>'
                    },
                    {
                        xtype: 'textfield',
                        inputType: "password",
                        name: '_password',
                        id: '_password',
                        hideLabel: false,
                        fieldLabel: "<{$words.email_password}>",
                        labelSeparator: ':',
                        maxLength:32,
                        value: '<{$notif_password}>'
                    },
                        level_combo,
                    {
                        xtype: 'textfield',
                        name: '_from',
                        id: '_from',
                        hideLabel: false,
                        fieldLabel: "<{$words.email_from}>",
                        labelSeparator: ':',
                        width:315,
                        value: '<{$notif_sender}>',
                        disabled:<{if $notif_auth=="gmail"}>true<{else}>false<{/if}>
                    },
                    {
                        xtype: 'textfield',
                        name: '_domain',
                        id: '_domain',
                        hideLabel: false,
                        fieldLabel: "<{$words.email_domain}>",
                        labelSeparator: ':',
                        width:315,
                        value: '<{$notif_domain}>',
                        vtype: 'Domain'
                    },
                    {
                        xtype: 'textfield',
                        name: '_addr1',
                        id: '_addr1',
                        hideLabel: false,
                        fieldLabel: "<{$words.email_addr}> 1",
                        labelSeparator: ':',
                        width:315,
                        value: '<{$notif_addr1}>'
                    },
                    {
                        xtype: 'textfield',
                        name: '_addr2',
                        id: '_addr2',
                        hideLabel: false,
                        fieldLabel: "<{$words.email_addr}> 2",
                        labelSeparator: ':',
                        width:315,
                        value: '<{$notif_addr2}>'
                    },
                    {
                        xtype: 'textfield',
                        name: '_addr3',
                        id: '_addr3',
                        hideLabel: false,
                        fieldLabel: "<{$words.email_addr}> 3",
                        labelSeparator: ':',
                        width:315,
                        value: '<{$notif_addr3}>'
                    },
                    {
                        xtype: 'textfield',
                        name: '_addr4',
                        id: '_addr4',
                        hideLabel: false,
                        fieldLabel: "<{$words.email_addr}> 4",
                        labelSeparator: ':',
                        width:315,
                        value: '<{$notif_addr4}>'
                    }                        
                ],
                        
                buttons: [
                    {
                        //xtype: 'button',
                        name: '_test',
                        id: '_test',
                        text: '<{$words.email_test}>',
                        handler: function(){
                            processAjax('setmain.php?fun=notif2',onLoadForm,fp.getForm().getValues(true));
                       }
                    },
                    {
                        text: '<{$gwords.apply}>',
                        handler: function(){
                            if(Ext.getCmp("enableCheck").value == "1"){
                                if(fp.getForm().isValid()){
                                    Ext.Msg.confirm("<{$words.notif_title}>","<{$gwords.confirm}>",function(btn){
                                    if(btn=='yes'){
                                        processAjax('<{$form_action}>',onLoadForm,fp.getForm().getValues(true));
                                        //Ext.Msg.alert('Submitted Values', 'The following will be sent to the server: <br />'+
                                        //fp.getForm().getValues(true).replace(/&/g,', '));
                                    }})
                                }
                            }
                            else{
                                Ext.Msg.confirm("<{$words.notif_title}>","<{$gwords.confirm}>",function(btn){
                                if(btn=='yes'){
                                    processAjax('<{$form_action}>',onLoadForm,fp.getForm().getValues(true));
                                    //Ext.Msg.alert('Submitted Values', 'The following will be sent to the server: <br />'+
                                    //fp.getForm().getValues(true).replace(/&/g,', '));
                                }})
                            }
                        }
                    }
                ],
                
                buttonAlign:'left'
            }
        ]
    });

    auth_combo.setValue('<{$notif_auth}>');
    auth_combo.on('expand', function( comboBox ){
        if (!window.ActiveXObject){
            comboBox.list.setWidth( 'auto' );
            comboBox.innerList.setWidth( 'auto' );
        }
    },this,{ single: true });
    
    level_combo.setValue('<{$notif_level}>');
    level_combo.on('expand', function( comboBox ){
        if (!window.ActiveXObject){
            comboBox.list.setWidth( 'auto' );
            comboBox.innerList.setWidth( 'auto' );
        }
    },this,{ single: true });

    ssl_combo.setValue('<{$notif_ssl}>');
    ssl_combo.on('expand', function( comboBox ){
        if (!window.ActiveXObject){
            comboBox.list.setWidth( 'auto' );
            comboBox.innerList.setWidth( 'auto' );
        }
    },this,{ single: true });

    if(<{$notif_mail}>=='0'){
        Ext.getDom("_smtp").disabled=true;
        Ext.getDom("_smtport").disabled=true;
        Ext.getDom("_auth").disabled=true;
        Ext.getDom("_account").disabled=true;
        Ext.getDom("_password").disabled=true;
        Ext.getDom("_level").disabled=true;
        Ext.getDom("_from").disabled=true;
        Ext.getDom("_domain").disabled=true;
        Ext.getDom("_ssl").disabled=true;
        Ext.getDom("_addr1").disabled=true;
        Ext.getDom("_addr2").disabled=true;
        Ext.getDom("_addr3").disabled=true;
        Ext.getDom("_addr4").disabled=true;
        Ext.getCmp("_test").disable();
        Ext.getCmp("enableCheck").value = "0";
        auth_combo.disable();
        level_combo.disable();
        ssl_combo.disable();
    }
    
    /**
    * E-mail notification change to "Enabled/Disabled"
    */
    function handleFormDisabled(obj,value){
        if (value == '1'){
            // E-mail notification change to "Enabled"
            // get E-mail information on Ajax.
            Ext.getDom("_smtp").disabled=false;
            Ext.getDom("_smtport").disabled=false;
            Ext.getDom("_auth").disabled=false;
            Ext.getDom("_account").disabled=false;
            Ext.getDom("_password").disabled=false;
            Ext.getDom("_level").disabled=false;
            Ext.getDom("_from").disabled=false;
            Ext.getDom("_domain").disabled=false;
            Ext.getDom("_ssl").disabled=false;
            Ext.getDom("_addr1").disabled=false;
            Ext.getDom("_addr2").disabled=false;
            Ext.getDom("_addr3").disabled=false;
            Ext.getDom("_addr4").disabled=false;
            Ext.getCmp("_test").enable();
            Ext.getCmp("enableCheck").value = "1";
            auth_combo.enable();
            level_combo.enable();
            ssl_combo.enable();
            processAjax('getmain.php?fun=notif',onLoadMail,'ac=mailinfo',false);  //get E-mail information
        }else{
            // E-mail notification change to "Disabled"
            // clean all component value in UI
            Ext.getDom("_smtp").value='';
            Ext.getDom("_smtport").value='';
            Ext.getDom("_account").value='';
            Ext.getDom("_password").value='';
            Ext.getDom("_from").value='';
            Ext.getDom("_domain").value='';
            Ext.getDom("_addr1").value='';
            Ext.getDom("_addr2").value='';
            Ext.getDom("_addr3").value='';
            Ext.getDom("_addr4").value='';
            auth_combo.setValue();
            level_combo.setValue();
            ssl_combo.setValue();
            
            Ext.getDom("_smtp").disabled=true;
            Ext.getDom("_smtport").disabled=true;
            Ext.getDom("_auth").disabled=true;
            Ext.getDom("_account").disabled=true;
            Ext.getDom("_password").disabled=true;
            Ext.getDom("_level").disabled=true;
            Ext.getDom("_from").disabled=true;
            Ext.getDom("_domain").disabled=true;
            Ext.getDom("_ssl").disabled=true;
            Ext.getDom("_addr1").disabled=true;
            Ext.getDom("_addr2").disabled=true;
            Ext.getDom("_addr3").disabled=true;
            Ext.getDom("_addr4").disabled=true;
            Ext.getCmp("_test").disable();
            Ext.getCmp("enableCheck").value = "0";
            auth_combo.disable();
            level_combo.disable();
            ssl_combo.disable();
        }
    }

    //result E-mail information
    function onLoadMail(){
        var rq = eval('('+this.req.responseText+')');
        Ext.getDom("_smtp").value=rq.smtp;
        if (rq.smtport == ''){
            Ext.getDom("_smtport").value="25";
        } else {
            Ext.getDom("_smtport").value=rq.smtport;
        }
        Ext.getDom("_account").value=rq.account;
        Ext.getDom("_password").value=rq.password;
        Ext.getDom("_from").value=rq.sender;
        Ext.getDom("_domain").value=rq.domain;
        Ext.getDom("_addr1").value=rq.addr1;
        Ext.getDom("_addr2").value=rq.addr2;
        Ext.getDom("_addr3").value=rq.addr3;
        Ext.getDom("_addr4").value=rq.addr4;
        auth_combo.setValue(rq.auth);
        level_combo.setValue(rq.level);
        ssl_combo.setValue(rq.ssl);
    }

});

</script>
