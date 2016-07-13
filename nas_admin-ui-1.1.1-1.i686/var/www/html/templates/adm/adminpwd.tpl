
<div id="adminpwdform"></div>

<script language="javascript">
Ext.onReady(function(){
    Ext.QuickTips.init();

    // turn on validation errors beside the field globally
    Ext.form.Field.prototype.msgTarget = 'side';
    
    var prefix = new Ext.form.Hidden({id: 'prefix', name: 'prefix', value: 'adminpwd'});
    var fp = new Ext.FormPanel({
        //frame: true,
        labelWidth: 150,
        width: 'auto',
        renderTo:'adminpwdform',
        bodyStyle: 'padding:0 10px 0;',
        style: 'margin: 10px;',
        items: [{
            layout: 'column',
            border: false,
            defaults:{
                columnWidth: '.5',
                border: false
            }
        },
        prefix,
        /*====================================================================
         * Change Administrator Password
         *====================================================================*/
        {
            xtype:'fieldset',
            title: "<{$words.adminpwd_title}>",
            autoHeight: true,
            layout: 'form',
            items: [{
                xtype: 'textfield',
                name: '_passwd1',
                id:  '_passwd1',
                fieldLabel: "<{$words.new_passwd}>",
                inputType: 'password',
                vtype: 'AdminPwd',
                value: ''
            },
            {
                xtype: 'textfield',
                name: '_passwd2',
                id: '_passwd2',
                fieldLabel: "<{$gwords.pwd_confirm}>",
                inputType: 'password',
                vtype: 'AdminPwd',
                value: ''
            }],
        
            buttons: [{
                text: "<{$gwords.apply}>",
                handler: function(){
                    if(fp.getForm().isValid()){
                        Ext.Msg.confirm("<{$words.adminpwd_title}>","<{$gwords.confirm}>",function(btn){
                            if(btn=='yes'){
                                prefix.setValue('adminpwd');
                                var pwd1 = encodeURIComponent(Ext.getCmp('_passwd1').getValue());
                                var pwd2 = encodeURIComponent(Ext.getCmp('_passwd2').getValue());
                                processAjax('<{$form_action}>',onLoadForm,"prefix=adminpwd&_passwd1="+pwd1+"&_passwd2="+pwd2);
                            
                                Ext.getDom("_passwd1").value="";
                                Ext.getDom("_passwd2").value="";
                            }
                        })              
                    }
                }
            }],
            
            buttonAlign:'left'
        }
        
        
<{if ($lcd_passwd_have ==1) }>        
        /*====================================================================
         * Change LCD Password
         *====================================================================*/
        ,{
            xtype:'fieldset',
            title: "<{$words.adminpwd_title2}>",
            autoHeight: true,
            layout: 'form',
            items: [{
                xtype: 'textfield',
                name: '_lcdpasswd1',
                id:  '_lcdpasswd1',
                fieldLabel: "<{$words.new_passwd}>",
                inputType: 'password',
                vtype: 'OLEDPwd',
                value: ''
            },
            {
                xtype: 'textfield',
                name: '_lcdpasswd2',
                id: '_lcdpasswd2',
                fieldLabel: "<{$gwords.pwd_confirm}>",
                inputType: 'password',
                vtype: 'OLEDPwd',
                value: ''
            }],
        
            buttons: [{
                text: "<{$gwords.apply}>",
                handler: function(){
                    if(fp.getForm().isValid()){
                        Ext.Msg.confirm("<{$words.adminpwd_title2}>","<{$gwords.confirm}>",function(btn){
                            if(btn=='yes'){
                                prefix.setValue('lcdpwd');
                                processAjax('<{$form_action}>',onLoadForm,fp.getForm().getValues(true));
                            
                                Ext.getDom("_lcdpasswd1").value="";
                                Ext.getDom("_lcdpasswd2").value="";
                            }
                        })              
                    }
                }
            }],
            
            buttonAlign:'left'
        }
<{/if}>           
        ]
    });
});


</script>
