<script language="javascript">

Ext.onReady(function(){

    // turn on validation errors beside the field globally
    Ext.form.Field.prototype.msgTarget = 'side';
    
    var prefix = new Ext.form.Hidden({id: 'prefix', name: 'prefix', value: 'afp'});

    var afp_radiogroup = new Ext.form.RadioGroup({
                xtype: 'radiogroup',
                width:400,
                fieldLabel: '<{$words.afp}>',
                //listeners: {change:{fn:function(){alert('radio changed');}}},
                items: [
                    {boxLabel: '<{$gwords.enable}>', name: '_afp', inputValue: 1 <{if $afp_enabled =="1"}>, checked:true <{/if}>},
                    {boxLabel: '<{$gwords.disable}>', name: '_afp', inputValue: 0 <{if $afp_enabled =="0" || $afp_enabled ==""}>, checked:true <{/if}>}
                ]
    });

    var afp_tmradiogroup = new Ext.form.RadioGroup({
     		xtype: 'radiogroup',
                width:400,
                fieldLabel: '<{$words.tm}>',
                //listeners: {change:{fn:function(){alert('radio changed');}}},
                items: [
                	{boxLabel: '<{$gwords.enable}>', name: '_afptm', inputValue: 1 <{if $afp_tmenabled =="1"}>, checked:true <{/if}>},
           		{boxLabel: '<{$gwords.disable}>', name: '_afptm', inputValue: 0 <{if $afp_tmenabled =="0" || $afp_tmenabled ==""}>, checked:true <{/if}>}
                ]
    });
    
    var charset_store = new Ext.data.SimpleStore({
	      fields: <{$afp_charset_fields}>,
	      data: <{$afp_charset_data}>
    });

    var charset_combo = new Ext.form.ComboBox({
        xtype: 'combo',
        name: '_charset',
        id: '_charset',
        hiddenName: '_charset_selected',
		mode: 'local',
		store: charset_store,
		displayField: 'display',
		valueField: 'value',
        readOnly: true,
		typeAhead: true,
		selectOnFocus:true,
		triggerAction: 'all',
		listWidth:130
    });

    var folder_store = new Ext.data.JsonStore({
	      fields: ["folder_name"],
	      data: <{$Time_Machine_folder}>
    });

    var folder_combo = new Ext.form.ComboBox({
        xtype: 'combo',
        name: '_folder',
        id: '_folder',
        hiddenName: '_folder_selected',
        mode: 'local',
        store: folder_store,
        displayField: 'folder_name',
        valueField: 'folder_name',
        readOnly: true,
        typeAhead: true,
        selectOnFocus:true,
        triggerAction: 'all',
        listWidth:130
    });
    
    folder_combo.setValue('<{$tm_folder}>');
    
    var fp = TCode.desktop.Group.addComponent({
        xtype: 'form',
        frame: false,
        labelWidth: 110,
        bodyStyle: 'padding:0 10px 0;',
        items: [{
            layout: 'column',
            border: false,
            defaults: {
                columnWidth: '.5',
                border: false
            }
            },prefix,{
            
            /*====================================================================
             * AFP
             *====================================================================*/
                                               
            xtype:'fieldset',
            title: '<{$words.afp_title}>',
            autoHeight: true,
            layout: 'form',
            buttonAlign: 'left',
            defaults: {labelStyle: 'width:200px;'},
            items: [
                afp_radiogroup,
                {
                    layout: 'table',
                    height: 30,
                    layoutConfig: {
                        columns: 2
                    },
                    items: [
                        {
                            html: '<{$words.afp_charset}>:',
                            width:200
                        },charset_combo
                    ]
                },{
                    xtype: 'textfield',
                    name: '_zone',
                    id: '_zone',
                    fieldLabel: '<{$words.afp_zone}>',
                    value: '<{$afp_zone}>'
                },
                afp_tmradiogroup,
                {
                    layout: 'table',
                    height: 30,
                    layoutConfig: {
                        columns: 2
                    },
                    items: [
                        {
                            html: '<{$words.tm_folder}>',
                            width:200
                        },folder_combo
                    ]
                }
            ],
            buttons: [{
                text: '<{$gwords.apply}>',
                handler: function(){
                    if(fp.getForm().isValid()){
		        Ext.Msg.confirm('<{$words.afp}>',"<{$gwords.confirm}>",function(btn){
				if(btn=='yes'){
					afp_flag=0;
  	                         	if (Ext.getDom("_charset").disabled){
				        	afp_flag=1;
						charset_combo.enable();
						Ext.getDom("_zone").disabled=false;
					}
					processAjax('<{$form_action}>',onLoadForm,fp.getForm().getValues(true));
					if (afp_flag ==1 ){
						charset_combo.disable();
						Ext.getDom("_zone").disabled=true;
					}
					//Ext.Msg.alert('Submitted Values', 'The following will be sent to the server: <br />'+ 
					//fp.getForm().getValues(true).replace(/&/g,', '));
			}})
                    }
                }
            }]
        }]
    });
    
    charset_combo.setValue('<{$afp_charset}>');
    charset_combo.on('expand', function( comboBox ){
      if (!window.ActiveXObject){
        comboBox.list.setWidth( 'auto' );
        comboBox.innerList.setWidth( 'auto' );
      }
    }, this, { single: true });
    
    if(<{$afp_enabled}>=='0'){
    	charset_combo.disable();
    	folder_combo.disable();
    	afp_tmradiogroup.disable();
	    Ext.getDom("_zone").disabled=true;
    }
    
    if(<{$afp_tmenabled}>=='0'){
    	folder_combo.disable();
    }
    
    afp_radiogroup.on('change',function(RadioGroup,newValue)
    {
        if (newValue == '1'){
	    charset_combo.enable();
	    afp_tmradiogroup.enable();
	    Ext.getCmp('_zone').setDisabled(false);
	        if(afp_tmradiogroup.getValue()=='1'){
	          folder_combo.enable();
	        }else{
            folder_combo.disable();
          }
	}else{
            charset_combo.disable();
    	    folder_combo.disable();
    	    afp_tmradiogroup.disable();
	        Ext.getCmp('_zone').setDisabled(true);
	}
    	//Ext.Msg.alert('xxx','value changes from '+oldValue+"  to "+newValue);
    });
    afp_tmradiogroup.on('change',function(RadioGroup,newValue)
    {
        if (newValue == '1'){
	        folder_combo.enable();
	      }else{
    	    folder_combo.disable();
	      }
    });
});


</script>
