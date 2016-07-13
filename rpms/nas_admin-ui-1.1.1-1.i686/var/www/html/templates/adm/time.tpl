
<style type="text/css" media="all">   
    .allow-float {clear:none!important;} 
    .stop-float {clear:both!important;}  
    .left {float:left;}   
    .center {float:center;}   
    .space20px {float:left;padding:0 0 0 20px;}   
    .space105px {float:left;padding:0 0 0 105px;}   

</style>   

<div id="timeform"></div>

<script language="javascript">

Ext.override(Ext.menu.DateMenu,{
    render : function(){
        Ext.menu.DateMenu.superclass.render.call(this);
        if(Ext.isGecko|| Ext.isSafari){
            this.picker.el.dom.childNodes[0].style.width = '200px';
            this.picker.el.dom.style.width = '200px';
        }
    }
});

function UpdateData(){
    var request = eval("("+replaceStr(this.req.responseText)+")");  
    
    Ext.getCmp('_date').getEl().dom.value= request.date_str;
    Ext.getCmp('_time').getEl().dom.value= request.time_str;
    //Ext.getCmp('_hour').getEl().dom.value= request.hour;
    //Ext.getCmp('_min').getEl().dom.value= request.min;

    if(TCode.desktop.Group.page === 'time'){   
        systatus_refresh = setTimeout("processAjax('getmain.php?fun=time&update=1', UpdateData)",60000);
    }else{
        clearTimeout(systatus_refresh);
    }
}

Ext.onReady(function(){
    // turn on validation errors beside the field globally
    Ext.form.Field.prototype.msgTarget = 'side';
    
    var prefix = new Ext.form.Hidden({id: 'prefix', name: 'prefix', value: 'time'});

    var timezone_store = new Ext.data.SimpleStore({
        fields: <{$timezone_fields}>,
        data: <{$timezone_data}>.sort()
    });

    var timezone_combo = new Ext.form.ComboBox({
        xtype: 'combo',
        name: '_timezone',
        id: '_timezone',
        listWidth: 350,
        width: 350,
        hiddenName: '_timezone_selected',
        fieldLabel: '<{$words.time_zone}>',
        mode: 'local',
        store: timezone_store,
        displayField: 'display',
        valueField: 'value',
        readOnly: false,
        typeAhead: true,
        selectOnFocus:true,
        triggerAction: 'all',
        autoWidth:true,
        value: '<{$matches[1]}>'
    });          

    var external_ntp_radiogroup = new Ext.form.RadioGroup({
        xtype: 'radiogroup',
        fieldLabel: '<{$words.ntp_server}>',
        width: 300,
        items: [
            {boxLabel: '<{$gwords.yes}>', name: '_ntp_cfg_mode', inputValue: 'yes' <{if $ntp_cfg_mode =='yes'}>, checked:true <{/if}>},
            {boxLabel: '<{$gwords.no}>', name: '_ntp_cfg_mode', inputValue: 'no' <{if $ntp_cfg_mode == 'no'}>, checked:true <{/if}>}
        ],
        listeners:{
            change: {
                fn:function(RadioGroup, newVal, oldVal){
                    if (newVal == 'yes'){
                        ntp_server_combo.enable();
                        
                    }else{
                        ntp_server_combo.disable();
                    }
                }
            }
        }
    });
    
    var ntp_mode_radiogroup = new Ext.form.RadioGroup({
        xtype: 'radiogroup',
        fieldLabel: '<{$words.ntp_server_mode}>',
        width: 300,
        //listeners: {change:{fn:function(){alert('radio changed');}}},
        items: [
            {boxLabel: '<{$gwords.enable}>', name: '_ntp_server_mode', inputValue: '1' <{if $ntp_server_mode =='1'}>, checked:true <{/if}>},
            {boxLabel: '<{$gwords.disable}>', name: '_ntp_server_mode', inputValue: '0' <{if $ntp_server_mode == '0'}>, checked:true <{/if}>}
        ]
    });
        
    var ntp_server_store = new Ext.data.SimpleStore({
        fields: <{$ntp_server_fields}>,
        data: <{$ntp_server_data}>
    });

    var ntp_server_combo = new Ext.form.ComboBox({
        xtype: 'combo',
        name: '_ntp_server',
        id: '_ntp_server',
        fieldLabel: '<{$words.external_ntp_server}>',
        mode: 'local',
        store: ntp_server_store,
        displayField: 'display',
        valueField: 'value',
        readOnly: false,
        typeAhead: true,
        selectOnFocus:true,
        triggerAction: 'all',
        listWidth: 130,
        autoWidth: true, 
        value: '<{$ntp_server}>'      
    });          

    var _time = new Ext.form.TimeField({
                    //xtype: 'timefield',
                    fieldLabel: '<{$gwords.time}>',
                    mode: 'local',
                    name: '_time',
                    id: '_time',
                    //hiddenName:'times',
                    //hiddenId:'times',
                    format:'H:i',
                    increment:1,
                    width:100,
                    disableKeyFilter:true, 
                    forceSelection:true,
                    emptyText:'00:00',
                    emptyClass:'x-form-focus',
                    value:'<{$datetime[3].":".$datetime[4]}>'
    });
    
    /*
    * ================  Date Range  =======================
    */
    
    var fp = new Ext.FormPanel({
        //frame: true,
        labelWidth: 250,
        width: 'auto',
        renderTo:'timeform',
        bodyStyle: 'background: transparent;',
        style: 'margin: 10px;',
        border: false,
        items: [{
                xtype: 'datefield',
                fieldLabel: '<{$gwords.date}>',
                name: '_date',
                id: '_date',
                width: 150,
                value: '<{$date_str}>'
            },
            _time,
            timezone_combo,
            ntp_mode_radiogroup,
            external_ntp_radiogroup,
            ntp_server_combo
        ],
        buttons: [{
            text: '<{$gwords.apply}>',
            handler: function(){
                if(fp.getForm().isValid()){
                    Ext.Msg.confirm("<{$gwords.time}>","<{$gwords.confirm}>",function(btn){
                        if(btn=='yes'){
                            processAjax('<{$form_action}>',onLoadForm,fp.getForm().getValues(true));
                            //refresh time after clicking the apply button
                            setTimeout("processAjax('getmain.php?fun=time&update=1', UpdateData)",2000);
                        }
                    })
                }
            }
        }],
        
        buttonAlign:'left'
    });

    //determine the ntp server shows
    if ('<{$ntp_cfg_mode}>' == 'yes')
        ntp_server_combo.enable();
    else if('<{$ntp_cfg_mode}>' == 'no')
        ntp_server_combo.disable();

    timezone_combo.on('expand', function( comboBox ){
        if (!window.ActiveXObject){
            comboBox.list.setWidth( 'auto' );
            comboBox.innerList.setWidth( 'auto' );
        }
    }, this, { single: true });    

    ntp_server_combo.on('expand', function( comboBox ){
        if (!window.ActiveXObject){
            comboBox.list.setWidth( 'auto' );
            comboBox.innerList.setWidth( 'auto' );
        }
    }, this, { single: true });    
  
    if(TCode.desktop.Group.page === 'time'){   
        systatus_refresh = setTimeout("processAjax('getmain.php?fun=time&update=1', UpdateData)",60000);
    }else{
        clearTimeout(systatus_refresh);
    }
});

</script>


