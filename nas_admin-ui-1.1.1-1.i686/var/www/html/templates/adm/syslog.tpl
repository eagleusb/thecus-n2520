<script type="text/javascript"> 
Ext.onReady(function(){
/***
* onClick apply handler
*/
function handle_apply(){   
	processAjax('<{$set_url}>',onLoadForm,formpanel.getForm().getValues(true));   
}  

/***
* onChange enabled/disabled radio
*/
function onSyslogRadio_change(radio,value){
	//selected disabled , hide target and ip
	if(value=='0'){ 
		Ext.getCmp('rdo_target').setDisabled(true);
		Ext.getCmp('_syslogd_ip').setDisabled(true);
		Ext.getDom("_level").disabled=true;
		level_combo.disable();
    folder_combo.disable();
    Ext.getCmp('rdo_server').setDisabled(true);
	//selected enabled
	}else{
		//show target
    Ext.getCmp('rdo_server').setDisabled(false);
    if(Ext.getCmp('rdo_server').getValue()=='0'){
       folder_combo.enable();
       Ext.getCmp('rdo_target').setDisabled(false);
       Ext.getDom("_level").disabled=false;
       level_combo.enable();
       if(Ext.getCmp('rdo_target').getValue()=='0'){
			   Ext.getCmp('_syslogd_ip').setDisabled(true); 
		     //target selected remove, show ip
		   }else{
			   Ext.getCmp('_syslogd_ip').setDisabled(false); 
		   }
    }else{
			 folder_combo.enable();
       Ext.getCmp('rdo_target').setDisabled(true);
       Ext.getCmp('_syslogd_ip').setDisabled(true); 
		}	
	} 
}
function onSyslogRadio_server_change(radio,value){
    if(value=='1'){
        folder_combo.enable();
        Ext.getCmp('rdo_target').setDisabled(true);
		    Ext.getCmp('_syslogd_ip').setDisabled(true);
		    Ext.getDom("_level").disabled=true;
		    level_combo.disable();
    }else{
        Ext.getCmp('rdo_target').setDisabled(false);
        
        if(Ext.getCmp('rdo_target').getValue()=='0'){
			   Ext.getCmp('_syslogd_ip').setDisabled(true);
			   folder_combo.enable();
		    }else{
			   Ext.getCmp('_syslogd_ip').setDisabled(false);
			   folder_combo.disable();
		    }
		    
		    Ext.getDom("_level").disabled=false;
        level_combo.enable();
		    
    }
}
/***
* onChange target radio
*/
function onTargetRadio_change(radio,value){
	//target selected local, hide ip
	if(value=='0'){ 
		Ext.getCmp('_syslogd_ip').setDisabled(true);
    folder_combo.enable();
	//target selected remove, show ip
	}else{
		Ext.getCmp('_syslogd_ip').setDisabled(false);
		folder_combo.disable();
	}
}


/***
* Formpanel
*/
var folder_store = new Ext.data.JsonStore({
	fields: ["folder_name"],
	data: <{$server_data}>
});
	
var folder_combo = new Ext.form.ComboBox({
	xtype: 'combo',
	name: '_folder',
	id: '_folder',
	hiddenName: '_folder_selected',
	fieldLabel: "<{$words.log_folder}>",
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

var level_store = new Ext.data.SimpleStore({
	fields: <{$_level_fields}>,
	data: <{$_level_data}>
});
	
var level_combo = new Ext.form.ComboBox({
	xtype: 'combo',
	name: '_level',
	id: '_level',
	listWidth: 100,
	width: 100,
	hiddenName: '_level_selected',
	fieldLabel: "<{$words.log_level}>",
	labelSeparator: ':',
	hideLabel: false,
	mode: 'local',
	store: level_store,
	displayField: 'display',
	valueField: 'value',
	readOnly: true,
	typeAhead: true,
	selectOnFocus:true,
	triggerAction: 'all'
});

var formpanel = new Ext.FormPanel({ 
        id:'formpanel',  
        renderTo:'div_syslog',
		bodyStyle: 'background: transparent;',
        style: 'margin: 10px;',
		border: false,
		items :[{
				  xtype: 'radiogroup',
				  fieldLabel: '<{$words.deamon}>',
				  width: 300,
				  id:'rdo_deamon',
					  listeners: {change:onSyslogRadio_change} ,
				  items: [{boxLabel: '<{$gwords.enable}>', name: '_syslogd_enabled',inputValue:'1' <{if $syslogd_enabled=='1' }> ,checked:true <{/if}>},
						  {boxLabel: '<{$gwords.disable}>', name: '_syslogd_enabled',inputValue:'0' <{if $syslogd_enabled=='0' }> ,checked:true <{/if}>}] 
			  },{
				  xtype: 'radiogroup',
				  fieldLabel: '<{$words.server_client}>',
				  width: 300,
				  id:'rdo_server',
					  listeners: {change:onSyslogRadio_server_change} ,
				  items: [{boxLabel: '<{$words.server}>', name: '_syslogd_server',inputValue:'1' <{if $syslogd_server=='1' }> ,checked:true <{/if}>},
						  {boxLabel: '<{$words.client}>', name: '_syslogd_server',inputValue:'0' <{if $syslogd_server=='0' }> ,checked:true <{/if}>}] 
			  },
			  {
				  xtype: 'radiogroup',
				  fieldLabel: '<{$words.target}>',
				  width: 300,
				  id:'rdo_target',
					  listeners: {change:onTargetRadio_change} ,
				  items: [{boxLabel: '<{$words.local}>', name: '_syslogd_target',inputValue:'0' <{if $syslogd_target=='0' }> ,checked:true <{/if}>},
						  {boxLabel: '<{$words.remote}>', name: '_syslogd_target',inputValue:'1' <{if $syslogd_target=='1' }> ,checked:true <{/if}>}] 
			  },
			  folder_combo,
						level_combo,
			  {
				  xtype: 'textfield',
				  fieldLabel: '<{$words.ip}>',
					  value:'<{$syslogd_ip}>',
				  id:'_syslogd_ip' ,
				  name:'_syslogd_ip'
				  <{if $syslogd_target=='0' || $syslogd_enabled=='0'}>,disabled:true<{/if}>
			  }],
			buttonAlign:'left' , 
			buttons:[{ text: '<{$gwords.apply}>',handler:handle_apply}]
    });
    
folder_combo.setValue('<{$log_folder}>');
level_combo.setValue('<{$syslogd_level}>');

level_combo.on('expand', function( comboBox ){
	if (!window.ActiveXObject){
		comboBox.list.setWidth( 'auto' );
		comboBox.innerList.setWidth( 'auto' );
	}
},this,{ single: true });

	if(<{$syslogd_enabled}>=='0'){ 
		Ext.getCmp('rdo_target').setDisabled(true);
		Ext.getCmp('_syslogd_ip').setDisabled(true);
		Ext.getDom("_level").disabled=true;
		level_combo.disable();
    folder_combo.disable();
    Ext.getCmp('rdo_server').setDisabled(true);
	//selected enabled
	}else{
		//show target
		Ext.getCmp('rdo_server').setDisabled(false);
    if(<{$syslogd_server}>=='0'){
       folder_combo.disable();
       Ext.getCmp('rdo_target').setDisabled(false);
       Ext.getDom("_level").disabled=false;
       level_combo.enable();
       if(<{$syslogd_target}>=='0'){
			   Ext.getCmp('_syslogd_ip').setDisabled(true); 
		   }else{
			   Ext.getCmp('_syslogd_ip').setDisabled(false); 
		   }
    }else{
			 folder_combo.enable();
       Ext.getCmp('rdo_target').setDisabled(true);
       Ext.getCmp('_syslogd_ip').setDisabled(true); 
		}
	} 
	if(<{$syslogd_server}>=='0'){ 
		   if(<{$syslogd_enabled}>=='1'){ 
		    if(<{$syslogd_target}>=='0'){
          Ext.getCmp('_syslogd_ip').setDisabled(true);
          if(<{$syslogd_server}>=='1'){
             folder_combo.disable();
             Ext.getCmp('rdo_target').setDisabled(true);
             Ext.getDom("_level").disabled=true;
		         level_combo.disable();
          }else{
             folder_combo.enable();
             Ext.getCmp('rdo_target').setDisabled(false);
             Ext.getDom("_level").disabled=false;
		         level_combo.enable();
          }  
        }else{
              Ext.getCmp('_syslogd_ip').setDisabled(false);
              folder_combo.disable();
        }
      }
		    
	}else{
        if(<{$syslogd_enabled}>=='0'){
	         folder_combo.disable();
	      }else{
           folder_combo.enable();
        }
        Ext.getCmp('rdo_target').setDisabled(true);
		    Ext.getCmp('_syslogd_ip').setDisabled(true);
		    Ext.getDom("_level").disabled=true;
		    level_combo.disable();
  }
});
</script>  
<div id="div_syslog"></div> 

