<div id="ddnsform"></div>
<script language="javascript">

Ext.onReady(function(){

    // turn on validation errors beside the field globally
    Ext.form.Field.prototype.msgTarget = 'side';
    
    var prefix = new Ext.form.Hidden({id: 'prefix', name: 'prefix', value: 'ddns'});

    var ddns_radiogroup = new Ext.form.RadioGroup({
                xtype: 'radiogroup',
                width: 300,
                fieldLabel: '<{$words.ddns}>',
                //listeners: {change:{fn:function(){alert('radio changed');}}},
                items: [
                    {boxLabel: '<{$gwords.enable}>', name: '_ddns', inputValue: 1 <{if $ddns_ddns =="1"}>, checked:true <{/if}>},
                    {boxLabel: '<{$gwords.disable}>', name: '_ddns', inputValue: 0 <{if $ddns_ddns =="0" || $ddns_ddns ==""}>, checked:true <{/if}>}
                ]
    });
    
    var reg_store = new Ext.data.SimpleStore({
	fields: <{$ddns_reg_fields}>,
	data: <{$ddns_reg_data}>
    });

    var reg_combo = new Ext.form.ComboBox({
        xtype: 'combo',
        name: '_reg',
        id: '_reg',
        hiddenName: '_reg_selected',
        fieldLabel: '<{$words.ddns_reg}>',
        mode: 'local',
        store: reg_store,
        displayField: 'display',
        valueField: 'value',
        readOnly: true,
        typeAhead: true,
        selectOnFocus:true,
        triggerAction: 'all',
        listWidth:160,
        width: 160
    });

    var fp = new Ext.FormPanel({
        frame: false,
        labelWidth: 150,
        //width: 600,
        autoWidth: 'true',
        renderTo:'ddnsform',
        style: 'margin: 10px;',
        
        items: [{
            layout: 'column',
            border: false,
            defaults: {
                columnWidth: '.5',
                border: false
            }
            },prefix,{
            
            /*====================================================================
             * DDNS
             *====================================================================*/
                                               
            xtype:'fieldset',
            title: '<{$words.ddns_title}>',
            autoHeight: true,
            layout: 'form',
            buttonAlign: 'left',
            items: [
                ddns_radiogroup,
                reg_combo ,{
                    xtype: 'textfield',
                    name: '_uname',
                    id: '_uname',
                    width: 160,
                    fieldLabel: '<{$words.ddns_uname}>',
                    value: '<{$ddns_uname}>'
                } ,{
                    xtype: 'textfield',
                    inputType: "password",
                    name: '_password',
                    id: '_password',
                    width: 160,
                    fieldLabel: '<{$words.ddns_password}>',
                    value: '<{$ddns_password}>'
                } ,{
                    xtype: 'textfield',
                    name: '_domain',
                    id: '_domain',
                    width: 160,
                    fieldLabel: '<{$words.ddns_domain}>',
                    value: '<{$ddns_domain}>'
                }],
            buttons: [{
                text: '<{$gwords.apply}>',
                handler: function(){
                    if(fp.getForm().isValid()){
		        Ext.Msg.confirm('<{$words.ddns}>',"<{$gwords.confirm}>",function(btn){
				if(btn=='yes'){
					ddns_flag=0;
  	                         	if (Ext.getDom("_reg").disabled){
				        	ddns_flag=1;
						reg_combo.enable();
						Ext.getDom("_uname").disabled=false;
						Ext.getDom("_password").disabled=false;
						Ext.getDom("_domain").disabled=false;
					}
					processAjax('<{$form_action}>',onLoadForm,fp.getForm().getValues(true));
					if (ddns_flag ==1 ){
						reg_combo.disable();
						Ext.getDom("_uname").disabled=true;
						Ext.getDom("_password").disabled=true;
						Ext.getDom("_domain").disabled=true;
					}
			}})
                    }
                }
            }]
        }]
    });
    
    reg_combo.setValue('<{$ddns_reg}>');
    reg_combo.on('expand', function( comboBox ){
      if (!window.ActiveXObject){
        comboBox.list.setWidth( 'auto' );
        comboBox.innerList.setWidth( 'auto' );
      }
    }, this, { single: true });
    
    if(<{$ddns_ddns}>=='0'){
    	reg_combo.disable();
	Ext.getDom("_uname").disabled=true;
	Ext.getDom("_password").disabled=true;
	Ext.getDom("_domain").disabled=true;
    }
    
    ddns_radiogroup.on('change',function(RadioGroup,newValue)
    {
        if (newValue == '1'){
	    reg_combo.enable();
	    Ext.getDom("_uname").disabled=false;
	    Ext.getDom("_password").disabled=false;
	    Ext.getDom("_domain").disabled=false;
	}else{
    	    reg_combo.disable();
	    Ext.getDom("_uname").disabled=true;
	    Ext.getDom("_password").disabled=true;
	    Ext.getDom("_domain").disabled=true;
	}
    });
    
});


</script>

