<script language="javascript">
Ext.onReady(function(){
    // turn on validation errors beside the field globally
    Ext.form.Field.prototype.msgTarget = 'side';
    var prefix = new Ext.form.Hidden({id: 'prefix', name: 'prefix', value: 'access_log'});
	var ACCESS = <{$sys_access_log}>;

    function onAccess_log_Radio_change(radio,value){
        if(value=='0'){ 
            Ext.getCmp('_folder').setDisabled(true);
            Ext.getCmp('serviceGroup').setDisabled(true);
        }else{
            Ext.getCmp('_folder').setDisabled(false);
            Ext.getCmp('serviceGroup').setDisabled(false);
        } 
    }

    var access_log_radiogroup = new Ext.form.RadioGroup({
        xtype: 'radiogroup',
        width:200,
        fieldLabel: '<{$words.Log}>',
        listeners: {change:onAccess_log_Radio_change} ,
        items: [
            {boxLabel: '<{$gwords.enable}>', name: 'access_log_enabled', inputValue: 1 <{if $access_log_enabled =="1"}>, checked:true <{/if}>},
            {boxLabel: '<{$gwords.disable}>', name: 'access_log_enabled', inputValue: 0 <{if $access_log_enabled =="0" || $access_log_enabled ==""}>, checked:true <{/if}>}
        ]
    });

    var folder_store = new Ext.data.JsonStore({
        fields: ["folder_name"],
        data: <{$server_data}>
    });
    
    var folder_combo = new Ext.form.ComboBox({
        xtype: 'combo',
        name: '_folder',
        id: '_folder',
        hiddenName: 'access_log_folder',
        fieldLabel: '<{$words.ftype_folder}>',
        labelSeparator: ':',
        mode: 'local',
        store: folder_store,
        displayField: 'folder_name',
        valueField: 'folder_name',
        forceSelection: true,
        editable: false,
        triggerAction: 'all',
        listWidth:150,
        width:200
    });

    var services = [
        {
            boxLabel: '<{$iwords.tree_ftp}>',
            name: 'ftp_log',
            checked: +'<{$ftp_log}>'
        },
        {
            boxLabel: '<{$iwords.tree_samba}>',
            name: 'smb_log',
            checked: +'<{$smb_log}>'
        },
        {
            boxLabel: '<{$iwords.tree_sshd}>',
            name: 'sshd_log',
            checked: +'<{$sshd_log}>'
        },
        {
            boxLabel: '<{$iwords.tree_afp}>',
            name: 'apple_log',
            checked: +'<{$apple_log}>'
        }
    ];
    
    if (ACCESS['iscsi_limit'] === 1) {
        services.push({
            boxLabel: '<{$iwords.tree_iscsi}>',
            name: 'iscsi_log',
            checked: +'<{$iscsi_log}>'
        });
    }

    var serviceCheckboxGroup = {//new Ext.form.CheckboxGroup({ 
        id:'serviceGroup', 
        xtype: 'checkboxgroup', 
        fieldLabel: '<{$gwords.service}>', 
        itemCls: 'x-check-group-alt', 
        // Put all controls in a single column with width 100%
        items: services
    };
    
    
    var fp = new Ext.FormPanel({
        frame: false,
        labelWidth: 150,
        autoWidth: 'true',
        renderTo:'accesslog_form',
        bodyStyle: 'padding:0 10px 0;',
        items: [{
            layout: 'column',
            border: false,
            defaults: {
                columnWidth: '.5',
                border: false
            }
        },prefix,
        {
            xtype:'fieldset',
            title: '<{$words.Log}> <{$gwords.support}>',
            autoHeight: true,
            buttonAlign: 'left',
            items:[ 
                access_log_radiogroup,
                folder_combo,
                serviceCheckboxGroup
            ],
            
            buttons: [{
                text: '<{$gwords.apply}>',
                handler: function(){
                    if(fp.getForm().isValid()){
                        Ext.Msg.confirm('<{$words.Log}>',"<{$gwords.confirm}>",function(btn){
                        if(btn=='yes'){
                            processAjax('<{$form_action}>',onLoadForm,fp.getForm().getValues(true));
                        }})
                    }
                }
            }]
        },{
            /*====================================================================
            * Description
            *====================================================================*/
            xtype:'fieldset',
            title: '<{$gwords.description}>',
            autoHeight: true,
            items: [{
                html:'<{$words.fun_desc}>'
            }]
        }]
    });

    folder_combo.setValue('<{$access_log_folder}>');
    
    if(<{$access_log_enabled}>=='0'){ 
        Ext.getCmp('_folder').setDisabled(true);
        Ext.getCmp('serviceGroup').setDisabled(true);
    }
    

});

</script>
<div id="accesslog_form"></div>
