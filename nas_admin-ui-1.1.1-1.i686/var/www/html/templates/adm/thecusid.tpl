<script type="text/javascript">
Ext.ns('TCode.Thecusid');

textfield_width=200;
WORDS = <{$WORDS}>;

TCode.Thecusid.LoginPanel = function (c) {
    var me = this,
        ui = {},
        ajax = c.ajax;
    
    c = Ext.apply(c || {}, {
        frame: false,
        layout: 'anchor',
        bodyStyle: 'padding: 5px;',
        height: 550,
        defaults: {
            labelAlign: 'right',
            labelWidth: 100
        },
        items: [{
//登入後顯示畫面
                id: 'DDNSShowPanel',
                xtype: 'fieldset',
                anchor: '100% 40%',
                title: WORDS.title_status,
                hidden: true,
                items: [
                    {
                        xtype: 'textfield',
                        id: 'o_thecusid',
                        fieldLabel:WORDS.thecusid,
                        labelStyle: 'text-align: left;',
                        disabled: true,
                        width: textfield_width
                    },
                    {
                        xtype: 'textfield',
                        id: 'o_ddns',
                        fieldLabel:WORDS.ddns,
                        labelStyle: 'text-align: left;',
                        disabled: true,
                        width: textfield_width
                    },
                    {
                        xtype: 'button',
                        style: 'margin-top:8px',
                        text: WORDS.logout,
                        handler: onLogout
                    }
                ]
            },
            
            
//DDNS登入設定畫面
            {
                id: 'DDNSSettingPanel',
                xtype: 'fieldset',
                anchor: '100% 35%',
                title: WORDS.title_setting,
                hidden: true,
                items: [
                    {
                        xtype: 'textfield',
                        id: 's_thecusid',
                        fieldLabel:WORDS.thecusid,
                        labelStyle: 'text-align: left;',
                        vtype: 'email',
                        width: textfield_width
                    },
                    {
                        xtype: 'textfield',
                        id: 's_passwd',
                        fieldLabel:WORDS.passwd,
                        labelStyle: 'text-align: left;',
                        inputType: 'password',
                        vtype: 'alphanum',
                        width: textfield_width
                    },
                    {
                        layout:'column',
                        defaults:{
                            layout:'form',
                            border:false,
                            xtype:'panel'
                        },
                        items:[{
                            columnWidth: 0.31,
                            items:[{
                                xtype: 'textfield',
                                labelStyle: 'text-align: left;',
                                id: 's_ddns',
                                fieldLabel: WORDS.ddns,
                                value: '',
                                vtype: 'alphanum',
                                width: textfield_width
                            }]
                        },
                        {
                            columnWidth: 0.68,
                            items:[{
                                xtype:'label',
                                text: '.thecuslink.com',
                                style: 'font-size: 14px;'
                                
                            }]
                        }
                        ]
                    },
                    {
                        xtype: 'button',
                        style: 'margin-top:8px',
                        text: WORDS.apply,
                        handler: onApllyDDNSSetteing
                    },
                    {
                        xtype: 'label',
                        style: 'display: block; margin-top:15px; text-align: left;',
                        text: WORDS.info_register
                    },
                    {
                        xtype: 'button',
                        style: 'margin-top: 8px;',
                        text: WORDS.register,
                        handler: onRegister
                    }
                ]
            },


//
// 下方regitster畫面
//
           {
                id: 'CreateThecusIDPanel',
                xtype: 'fieldset',
anchor: '100% 40%',
                title: WORDS.title_create,
                hidden: true,
                items: [
                    {
                        id: 'r_thecusid',
                        xtype: 'textfield',
                        fieldLabel:WORDS.thecusid,
                        labelStyle: 'text-align: left;',
                        vtype: 'email',
                        width: textfield_width
                    },
                    {
                        xtype: 'textfield',
                        id: 'r_passwd',
                        fieldLabel:WORDS.passwd,
                        labelStyle: 'text-align: left;',
                        inputType: 'password',
                        vtype: 'alphanum',
                        width: textfield_width
                    },
                    {
                        xtype: 'textfield',
                        id: 'r_cpasswd',
                        fieldLabel:WORDS.cpasswd,
                        labelStyle: 'text-align: left;',
                        inputType: 'password',
                        vtype: 'alphanum',
                        width: textfield_width
                    },
                    {
                        xtype: 'textfield',
                        id: 'r_f_name',
                        fieldLabel: WORDS.f_name,
                        labelStyle: 'text-align: left;',
                        vtype: 'alphanum',
                        width: textfield_width
                    },
                    {
                        xtype: 'textfield',
                        id: 'r_m_name',
                        fieldLabel: WORDS.m_name,
                        labelStyle: 'text-align: left;',
                        vtype: 'alphanum',
                        width: textfield_width
                    },
                    {
                        xtype: 'textfield',
                        fieldLabel: WORDS.l_name,
                        id: 'r_l_name',
                        labelStyle: 'text-align: left;',
                        vtype: 'alphanum',
                        width: textfield_width
                    },
                    {
                        id: 'process_label',
                        xtype: 'label',
                        text: ''
                    },
                    {
                        xtype: 'button',
                        text: WORDS.apply,
                        style: 'margin-top: 5px;',
                        handler: onApplyRegister
                    }
                ]
           }

        ]
    });
    
    TCode.Thecusid.LoginPanel.superclass.constructor.call(me, c);
    
    function onApllyDDNSSetteing() {
        var thecusid = Ext.getCmp('s_thecusid').getValue();
        var passwd = Ext.getCmp('s_passwd').getValue();
        var ddns = Ext.getCmp('s_ddns').getValue();
        
        if ((thecusid === '') || (passwd === '') || (ddns === '')) {
            Ext.Msg.alert('Warning', WORDS.error_code0x51 + ' or ' + WORDS.error_code0x52);
        }else{
            ajax.Setddns(thecusid, passwd, ddns, function(error_code){
                eval('str_error_code = WORDS.error_code0x' + error_code);
                if (error_code == 0) {
                    ajax.getDdns(function (ddns_state) {
                        if (ddns_state.thecusid === '') {
                            Ext.getCmp('DDNSSettingPanel').show();
                            Ext.getCmp('DDNSShowPanel').hide();
                        }else{
                            Ext.getCmp('DDNSSettingPanel').hide();
                            Ext.getCmp('DDNSShowPanel').show();
                            Ext.getCmp('o_thecusid').setValue(ddns_state.thecusid);
                            Ext.getCmp('o_ddns').setValue(ddns_state.ddns + '.thecuslink.com');
                        }
                    });
                }else{
                    Ext.Msg.alert('Warning', str_error_code);
                }
            });
        }
    }
    
    function onLogout() {
        ajax.Logout(function(){
            Ext.getCmp('DDNSSettingPanel').show();
            Ext.getCmp('CreateThecusIDPanel').hide();
            Ext.getCmp('DDNSShowPanel').hide();
            Ext.Msg.alert('Information!', WORDS.info_logout);
        });
    }
    
    
    function onApplyRegister(){
        Ext.getCmp('process_label').setText(WORDS.processing);
        var thecusid = Ext.getCmp('r_thecusid').getValue();
        var passwd = Ext.getCmp('r_passwd').getValue();
        var cpasswd = Ext.getCmp('r_cpasswd').getValue();
        var f_name = Ext.getCmp('r_f_name').getValue();
        var m_name = Ext.getCmp('r_m_name').getValue();
        var l_name = Ext.getCmp('r_l_name').getValue();
    
        if ((passwd !== cpasswd) || (thecusid === '') || (passwd === '') || (cpasswd === '')) {
            Ext.Msg.alert('Warning', WORDS.error_code0x51 + ' or ' + WORDS.error_code0x52);
        }else{
            
            ajax.registerThecusid(thecusid, passwd, f_name, m_name, l_name, function(error_code){
                eval('str_error_code = WORDS.error_code0x' + error_code);
                if (error_code == 0) {
                    Ext.getCmp('DDNSSettingPanel').show();
                    Ext.getCmp('CreateThecusIDPanel').hide();
                    Ext.Msg.alert('Successful!!', WORDS.info_register_suc);
                }else{
                    Ext.Msg.alert('Warning', str_error_code);
                }
                Ext.getCmp('process_label').setText('');
            });   
            
    }
}
    
    

}
Ext.extend(TCode.Thecusid.LoginPanel, Ext.Panel);
Ext.reg('TCode.Thecusid.LoginPanel', TCode.Thecusid.LoginPanel);
  
function onRegister(){
    Ext.getCmp('DDNSSettingPanel').hide();
    Ext.getCmp('CreateThecusIDPanel').show();
    Ext.getCmp('r_thecusid').focus();
}



//function onClickBack() {
//    Ext.getCmp('DDNSSettingPanel').show();
//    Ext.getCmp('CreateThecusIDPanel').hide();
//}



//  
//ddns_fqdn = <{$ddns_fqdn}>;
//
//if ((ddns_fqdn.thecusid == '') && (ddns_fqdn.ddns == '')){
//  var Login_state = false;
//}else{
//  var Login_state = true;
//}


TCode.Thecusid.Container = function (c) {
    var me = this,
        ajax = new TCode.ux.Ajax('setthecusid', <{$METHODS}>);
    var ap = {};
    
    c = Ext.apply(c || {}, {
        layout: 'column',
        defaults: {
            style: 'float: left;',
            ajax: ajax,
            width: 785
        },
        items: [
            {
                xtype: 'TCode.Thecusid.LoginPanel'
            }
        ]
    });
    
    TCode.Thecusid.Container.superclass.constructor.call(me, c);
    me.on('render', onGetState);

    function onGetState() {
      //code
      ajax.getDdns(function (ddns_state) {
        if (ddns_state.thecusid === '') {
            Ext.getCmp('DDNSSettingPanel').show();
            Ext.getCmp('DDNSShowPanel').hide();
        }else{
            Ext.getCmp('DDNSSettingPanel').hide();
            Ext.getCmp('DDNSShowPanel').show();
            Ext.getCmp('o_thecusid').setValue(ddns_state.thecusid);
            Ext.getCmp('o_ddns').setValue(ddns_state.ddns + '.thecuslink.com');
        }
      });
    }
    
    
}
Ext.extend(TCode.Thecusid.Container, Ext.Panel);
Ext.reg('TCode.Thecusid.Container', TCode.Thecusid.Container);

Ext.onReady(function () {
    TCode.desktop.Group.add({
        xtype: 'TCode.Thecusid.Container'
    });

});


</script>

