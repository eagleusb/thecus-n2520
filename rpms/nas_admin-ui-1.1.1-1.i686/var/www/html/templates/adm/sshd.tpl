<script language="javascript">

/**
 *  after execute seting, will change o_ field value
 *
 * @param sshd : sshd enable/disable
 * @param port : port number
 * @param sftp : sftp enable/dsiable
 */
function change_old(sshd,port,sftp){
    Ext.getCmp('o_sshd').setValue(sshd);
    Ext.getCmp('o_port').setValue(port);
    Ext.getCmp('o_sftp').setValue(sftp);
}

/**
 *  Destroy object
 *
 * @param none
 */
function ExtDestroy(){ 
  Ext.destroy(
            Ext.getCmp('sshd_radiogroup'),
            Ext.getCmp('sshd_sftpradiogroup'),
            Ext.getCmp('fp')
  );
}

Ext.onReady(function(){
    // turn on validation errors beside the field globally
    Ext.form.Field.prototype.msgTarget = 'side';
    var prefix = new Ext.form.Hidden({id: 'prefix', name: 'prefix', value: '<{$prefix}>'});

    /**
     *  This is sshd enable/disable radio object
     *
     * @param none
     */
    var sshd_radiogroup = new Ext.form.RadioGroup({
        xtype: 'radiogroup',
        width:200,
        fieldLabel: "<{$words.sshd_title}>",
        items: [
            {boxLabel: "<{$gwords.enable}>", name: '_sshd', inputValue: 1 <{if $sshd_enabled =="1"}>, checked:true <{/if}>},
            {boxLabel: "<{$gwords.disable}>", name: '_sshd', inputValue: 0 <{if $sshd_enabled =="0" || $sshd_enabled ==""}>, checked:true <{/if}>}
        ]
    });

    /**
     *  This is sftp enable/disable radio object
     *
     * @param none
     */    
    var sshd_sftpradiogroup = new Ext.form.RadioGroup({
        xtype: 'radiogroup',
        width:200,
        fieldLabel: "<{$words.sftp_title}>",
        items: [
            {boxLabel: "<{$gwords.enable}>", name: '_sftp', inputValue: 1 <{if $sshd_sftpen =="1"}>, checked:true <{/if}>},
            {boxLabel: "<{$gwords.disable}>", name: '_sftp', inputValue: 0 <{if $sshd_sftpen =="0" || $sshd_sftpen ==""}>, checked:true <{/if}>}
        ]
    });

    /**
     *  This is port check Xtype setting
     *
     * @param none
     */
    Ext.QuickTips.init();
    Ext.form.VTypes['portListVal'] = /^(22|102[5-9]|10[3-9][0-9]|1[1-9][0-9]{2}|[2-9][0-9]{3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$/;
    Ext.form.VTypes['portListMask'] = /[0-9]/;
    Ext.form.VTypes['portListText'] = "<{$words.ssh_port_out_range}>";
    Ext.form.VTypes['portList'] = function (v) {
        return Ext.form.VTypes['portListVal'].test(v);
    }

    /**
     *  This is SSH Form object
     *
     * @param none
     */
    var fp = new Ext.FormPanel({
        frame: false,
        labelWidth: 110,
        autoWidth: 'true',
        renderTo:'sshdform',
        bodyStyle: 'padding:0 10px 0;',

        items: [
            {
                layout: 'column',
                border: false,
                defaults: {
                    columnWidth: '.5',
                    border: false
                }
            },prefix,{
            
            /*====================================================================
             * SSH
             *====================================================================*/
                xtype:'fieldset',
                title: "<{$words.title}>",
                autoHeight: true,
                layout: 'form',
                buttonAlign: 'left',
                items: [
                    sshd_radiogroup,
                    {
                        xtype: 'textfield',
                        name: '_port',
                        id: '_port',
                        fieldLabel: "<{$words.sshd_port}>",
                        width:50,
                        value: '<{$sshd_port}>',
                        vtype: 'portList'
                     },
                     sshd_sftpradiogroup,
                     {
                         xtype:'hidden',
                         id:'o_sshd',
                         name:'o_sshd' ,
                         value:'<{$sshd_enabled}>'
                     },{
                         xtype:'hidden',
                         id:'o_port',
                         name:'o_port' ,
                         value:'<{$sshd_port}>'
                     },{
                         xtype:'hidden',
                         id:'o_sftp',
                         name:'o_sftp' ,
                         value:'<{$sshd_sftpen}>'
                     }
            ],
            buttons: [{
                text: "<{$gwords.apply}>",
                handler: function(){
                    if(fp.getForm().isValid()){
                        Ext.Msg.confirm("<{$words.title}>","<{$gwords.confirm}>",function(btn){
                            if(btn=='yes'){
                                if(sshd_radiogroup.getValue()==Ext.getCmp('o_sshd').getValue() && Ext.getCmp('o_port').getValue() == Ext.getCmp('_port').getValue() && sshd_sftpradiogroup.getValue()==Ext.getCmp('o_sftp').getValue())
                                    Ext.Msg.show({
                                        title: "<{$words.title}>",
                                        msg: "<{$gwords.setting_confirm}>",
                                        buttons: Ext.Msg.OK,
                                        icon: Ext.MessageBox.INFO
                                    });
                                else
                                    processAjax('<{$form_action}>',onLoadForm,fp.getForm().getValues(true));
                        }})
                    }
                }
            }]
        },{  /*====================================================================
                        * Description
                  *====================================================================*/
            xtype:'fieldset',
            title: "<{$gwords.description}>",
            autoHeight: true,
            items: [{
                html:"<li><{$words.limit1}></li><li><{$words.limit2}></li><li><{$words.limit3}></li><li><{$words.limit4}></li>"
            }]
        }]
    });
    
    if('<{$sshd_enabled}>'=='0'){
        sshd_sftpradiogroup.disable();
        Ext.getCmp('_port').setDisabled(true);
    }

    sshd_radiogroup.on('change',function(RadioGroup,newValue)
    {
        if (newValue == '1'){
            sshd_sftpradiogroup.enable();
            Ext.getCmp('_port').setDisabled(false);
        }else{
            sshd_sftpradiogroup.disable();
            Ext.getCmp('_port').setDisabled(true);
        }
    });
});

</script>
<div id="sshdform"></div>
