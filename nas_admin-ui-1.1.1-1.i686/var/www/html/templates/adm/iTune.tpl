<div id="iTuneform"></div>

<script language="javascript">

Ext.onReady(function(){

    // turn on validation errors beside the field globally
    Ext.form.Field.prototype.msgTarget = 'side';
    
    var prefix = new Ext.form.Hidden({id: 'prefix', name: 'prefix', value: 'iTune'});
    var enableCheck = new Ext.form.Hidden({id: 'enableCheck', name: 'enableCheck', value: '1'});
    
    var rescan_interval_store = new Ext.data.SimpleStore({
        fields: <{$iTune_rescan_interval_fields}>,
        data: <{$iTune_rescan_interval_data}>
    });
    
    var rescan_interval_combo = new Ext.form.ComboBox({
        xtype: 'combo',
        name: '_rescan_interval',
        id: '_rescan_interval',
        hiddenName: '_rescan_interval_selected',
        fieldLabel: '<{$words.rescan_interval}>',
        mode: 'local',
        store: rescan_interval_store,
        displayField: 'display',
        valueField: 'value',
        readOnly: true,
        typeAhead: true,
        selectOnFocus:true,
        triggerAction: 'all'
    });
    
    var encode_store = new Ext.data.SimpleStore({
        fields: <{$iTune_encode_fields}>,
        data: <{$iTune_encode_data}>
    });
    
    var encode_combo = new Ext.form.ComboBox({
        xtype: 'combo',
        name: '_encode',
        id: '_encode',
        hiddenName: '_encode_selected',
        fieldLabel: '<{$words.encode}>',
        mode: 'local',
        store: encode_store,
        displayField: 'display',
        valueField: 'value',
        readOnly: true,
        typeAhead: true,
        selectOnFocus:true,
        triggerAction: 'all'
    });
    
    var iTune_radiogroup = new Ext.form.RadioGroup({
        xtype: 'radiogroup',
        width: 300,
        fieldLabel: '<{$words.iTune}>',
        //listeners: {change:{fn:function(){alert('radio changed');}}},
        items: [
            {boxLabel: '<{$gwords.enable}>', name: '_iTune', inputValue: 1 <{if $iTune_iTune =="1"}>, checked:true <{/if}>},
            {boxLabel: '<{$gwords.disable}>', name: '_iTune', inputValue: 0 <{if $iTune_iTune =="0" || $iTune_iTune ==""}>, checked:true <{/if}>}
        ]
    });
    
    
    var fp = new Ext.FormPanel({
        labelWidth: 200,
        autoWidth : true,
        style: 'margin: 10px;',
        renderTo: 'iTuneform',
    
        items: [
            {
                layout: 'column',
                border: false,
                defaults: {
                    columnWidth: '.5',
                    border: false
                }
            },
            prefix,
            {
                xtype:'fieldset',
                title: '<{$words.iTune_title}>',
                autoHeight: true,
                layout: 'form',
                buttonAlign: 'left',
                items: [
                    iTune_radiogroup,
                    {
                        xtype: 'textfield',
                        allowBlank:false,
                        name: '_servername',
                        maxLength:63, 
                        id: '_servername',
                        fieldLabel: '<{$words.servername}>',
                        value: '<{$iTune_servername}>'
                    },
                    {
                        xtype: 'textfield',
                        inputType: "password",
                        name: '_passwd',
                        id: '_passwd',
                        maxLength:32, 
                        fieldLabel: '<{$gwords.password}>',
                        value: '<{$iTune_passwd}>',
                        vtype: 'iTune' 
                    },
                    rescan_interval_combo ,
                    encode_combo
                ],
                buttons: [{
                    text: '<{$gwords.apply}>',
                    handler: function(){
                        if (Ext.getCmp("enableCheck").value == "1") {
                            if (fp.getForm().isValid()) {
                                Ext.Msg.confirm('<{$words.iTune}>',"<{$gwords.confirm}>",function(btn){
                                    if (btn=='yes') {
                                        if ( <{$ha_enable}> ) {
                                            processAjax('<{$form_action}>',onLoadForm,fp.getForm().getValues(true)+"&_servername="+Ext.getDom("_servername").value);
                                        } else {
                                            processAjax('<{$form_action}>',onLoadForm,fp.getForm().getValues(true));
                                        }
                                    }
                                })
                            }
                        } else {
                            Ext.Msg.confirm('<{$words.iTune}>',"<{$gwords.confirm}>",function(btn){
                                if (btn=='yes') {
                                    if ( <{$ha_enable}> ) {
                                        processAjax('<{$form_action}>',onLoadForm,fp.getForm().getValues(true)+"&_servername="+Ext.getDom("_servername").value);
                                    } else {
                                        processAjax('<{$form_action}>',onLoadForm,fp.getForm().getValues(true));
                                    }
                                }
                            })
                        }
                    }
                }]
            }
        ]
    
    });
    
    
    rescan_interval_combo.setValue('<{$iTune_rescan_interval}>');
    rescan_interval_combo.on('expand', function( comboBox ){
        //if (!window.ActiveXObject){
        //	comboBox.list.setWidth( 'auto' );
        //	comboBox.innerList.setWidth( 'auto' );
        //}
        }, this, { single: true });
    
    encode_combo.setValue('<{$iTune_encode}>');
    encode_combo.on('expand', function( comboBox ){
        //if (!window.ActiveXObject){
        //	comboBox.list.setWidth( 'auto' );
        //	comboBox.innerList.setWidth( 'auto' );
        //}
        }, this, { single: true });
    
    if(<{$iTune_iTune}>=='0'){
        Ext.getDom("_servername").disabled=true;
        Ext.getDom("_passwd").disabled=true;
        Ext.getDom("_rescan_interval").disabled=true;
        Ext.getDom("_encode").disabled=true;
        Ext.getCmp("enableCheck").value = "0";
        rescan_interval_combo.disable();
        encode_combo.disable();
    } else {
        if( <{$ha_enable}> ) {
            Ext.getDom("_servername").disabled=true;
        }
    }
    
    iTune_radiogroup.on('change',function(RadioGroup,newValue){
        if (newValue == '1'){
            if ( <{$ha_enable}> ) {
                Ext.getDom("_servername").disabled=true;
            } else {
                Ext.getDom("_servername").disabled=false;
            }
    
            Ext.getDom("_passwd").disabled=false;
            Ext.getDom("_rescan_interval").disabled=false;
            Ext.getDom("_encode").disabled=false;
            Ext.getCmp("enableCheck").value = "1";
            rescan_interval_combo.enable();
            encode_combo.enable();
        }else{
            Ext.getDom("_servername").disabled=true;
            Ext.getDom("_passwd").disabled=true;
            Ext.getDom("_rescan_interval").disabled=true;
            Ext.getDom("_encode").disabled=true;
            Ext.getCmp("enableCheck").value = "0";
            rescan_interval_combo.disable();
            encode_combo.disable();
        }
        //Ext.Msg.alert('xxx','value changes from '+oldValue+"  to "+newValue);
    });

});
</script>
