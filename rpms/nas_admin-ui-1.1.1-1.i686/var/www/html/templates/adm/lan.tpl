<script language="javascript">

function redirect_reboot(){
    setCurrentPage('reboot');
    processUpdater('getmain.php','fun=reboot');
}

Ext.onReady(function(){

    // turn on validation errors beside the field globally
    Ext.form.Field.prototype.msgTarget = 'side';
    
    var prefix = new Ext.form.Hidden({id: 'prefix', name: 'prefix', value: 'lan'});
    var enable = new Ext.form.Hidden({id: '_enable', name: '_enable', value: '1'});

    var jumbo_store = new Ext.data.SimpleStore({
	fields: <{$lan_jumbo_fields}>,
	data: <{$lan_jumbo_data}>
    });
    if("<{$set_8023ad}>"=="1"){
    	Ext.Msg.show({
       		title:'<{$gwords.warning}>',
         	msg: '<{$words.lan_inactive}>',
        	buttons: Ext.Msg.OK,
            	icon: Ext.MessageBox.WARNING
        });
    }

    var jumbo_combo = new Ext.form.ComboBox({
                xtype: 'combo',
                name: '_jumbo',
                id: '_jumbo',
                hiddenName: '_jumbo_selected',
                fieldLabel: '<{$words.jumbo_frame}>',
		mode: 'local',
		store: jumbo_store,
		displayField: 'display',
		valueField: 'value',
        //readOnly: true,
		//typeAhead: true,
		selectOnFocus:true,
		triggerAction: 'all',
		maskRe: /^[0-9]$/,
		//regex: /[0-9]$/,
		listWidth:100
                <{if $set_8023ad=='1' }>,disabled:true<{/if}>                                                                                                      
    });
    
    jumbo_combo.on("blur", function(combo) {
    	var valtmp = combo.getRawValue();
    	if (valtmp.search("Disable") < 0) {
			if (valtmp.search("bytes") < 0) {	//if write
				if (valtmp > <{$lan_jombo_frame_max}>) {
					Ext.Msg.alert('<{$gwords.warning}>','<{$warn_jumbo}>');
					combo.setValue(<{$lan_jombo_frame_max}>);
					combo.setRawValue('<{$lan_jombo_frame_max}>');
				} else if (valtmp <= <{$lan_default_jumbo}>)	{
					Ext.Msg.alert('<{$gwords.warning}>','<{$warn_jumbo}>');
					combo.setValue(<{$lan_default_jumbo}>);
					combo.setRawValue('Disable');
				} else {
					combo.setValue(valtmp);
				}
			}
		}
	});
    
    var dhcp_radiogroup = new Ext.form.RadioGroup({
                xtype: 'radiogroup',
                width:200,
                fieldLabel: '<{$words.dhcp}>',
                //listeners: {change:{fn:function(){alert('radio changed');}}},
                items: [
                    {boxLabel: '<{$gwords.enable}>', name: '_dhcp', inputValue: 1 <{if $lan_dhcp =="1"}>, checked:true <{/if}>},
                    {boxLabel: '<{$gwords.disable}>', name: '_dhcp', inputValue: 0 <{if $lan_dhcp =="0" || $lan_dhcp ==""}>, checked:true <{/if}>}
                ]
                <{if $set_8023ad=='1' }>,disabled:true<{/if}>                                                                                                      
    });

    var fp = new Ext.FormPanel({
        frame: false,
        labelWidth: 110,
        //width: 600,
        autoWidth: 'true',
        buttonAlign: 'left',
        renderTo:'lanform',
        bodyStyle: 'padding:0 10px 0;',
        
        items: [{
            layout: 'column',
            border: false,
            defaults: {
                columnWidth: '.5',
                border: false
            }
            },prefix,enable,{
            
            /*====================================================================
             * LAN IP
             *====================================================================*/
                                               
            xtype:'fieldset',
            title: '<{$words.lan_title}>',
            autoHeight: true,
            layout: 'form',
            items: [
			{
                xtype: 'box'
                ,height: 25
                ,autoEl: {cn:"<table><tr height='20'><td width='115'><{$words.mac}>:</td><td><{$lan_mac}></td></tr></table>"}
            },{
            	items: [{
            		layout: 'column',
            		border: false,
            		items:[{
            			columnWidth: '.8',
            			layout: 'form',
            			items:jumbo_combo
					},{
						xtype:'box',
						autoEl:{cn:'<span style="color:green">( <{$limit}> )</span>'}
					}]
				}]
			},{
                xtype: 'textfield',
                name: '_ip',
                fieldLabel: '<{$gwords.ip}>',
                value: '<{$lan_ip}>'
                <{if $set_8023ad=='1' }>,disabled:true<{/if}>                                                                                                      
            },{
                xtype: 'textfield',
                name: '_netmask',
                fieldLabel: '<{$words.netmask}>',
                value: '<{$lan_netmask}>'
                <{if $set_8023ad=='1' }>,disabled:true<{/if}>                                                                                                      
            },{
                xtype: 'box'
                ,height: 25
                ,autoEl: {cn:"<table><tr height='20'><td width='115'><{$words.link_detect}>:</td><td><{$link_detect}></td></tr></table>"}
            },{
                xtype: 'box'
                ,height: 25
                ,autoEl: {cn:"<table><tr height='20'><td width='115'><{$words.link_speed}>:</td><td><{$link_speed}></td></tr></table>"}
            }]
        },{
            
            /*====================================================================
             * DHCP Server
             *====================================================================*/
            
            xtype:'fieldset',
            title: '<{$words.dhcp_title}>',
            autoHeight: true,
            items: [ dhcp_radiogroup,{
                xtype: 'textfield',
                name: '_startip',
                id: '_startip',
                fieldLabel: '<{$words.startip}>',
                value: '<{$lan_dhcp_startip}>'
                <{if $set_8023ad=='1' }>,disabled:true<{/if}>                                                                                                      
            },{
                xtype: 'textfield',
                name: '_endip',
                id: '_endip',
                fieldLabel: '<{$words.endip}>',
                value: '<{$lan_dhcp_endip}>'
                <{if $set_8023ad=='1' }>,disabled:true<{/if}>                                                                                                      
            },{
                xtype: 'textfield',
                name: '_gateway',
                id: '_gateway',
                fieldLabel: '<{$words.gateway}>',
                value: '<{$lan_gateway}>'
                <{if $ip_sharing=='1' || $set_8023ad=='1'}>                                                                                                          
                ,disabled:true<{/if}>
            },{
		html: "<table>"
                     +"<tr height='20'> <td width='115'><{$words.dns}>:</td> <td><{$lan_dns0}></td> </tr>"
                     +"<tr height='20'> <td width='115'></td> <td><{$lan_dns1}></td> </tr>"
                     +"<tr height='20'> <td width='115'></td> <td><{$lan_dns2}></td> </tr>"
                     +"</table>"
            }]
        }],
        
        buttons: [{
            text: '<{$gwords.apply}>',
            handler: function(){
                if(fp.getForm().isValid()){
			Ext.Msg.confirm('<{$gwords.lan}>',"<{$gwords.confirm}>",function(btn){
				if(btn=='yes'){
					processAjax('<{$form_action}>',onLoadForm,fp.getForm().getValues(true));
					//Ext.Msg.alert('Submitted Values', 'The following will be sent to the server: <br />'+ 
					//fp.getForm().getValues(true).replace(/&/g,', '));
			}})
                }
            }
            <{if $set_8023ad=='1' }>,disabled:true<{/if}>                                                                                                      
        }]
    });
    jumbo_combo.setValue('<{$lan_jumbo}>');
    jumbo_combo.on('expand', function( comboBox ){
      if (!window.ActiveXObject){
        comboBox.list.setWidth( 'auto' );
        comboBox.innerList.setWidth( 'auto' );
      }
    }, this, { single: true });
    
    if(<{$lan_dhcp}>=='0'){
	Ext.getDom("_startip").disabled=true;
	Ext.getDom("_endip").disabled=true;
	Ext.getDom("_gateway").disabled=true;
    }
    
    dhcp_radiogroup.on('change',function(RadioGroup,newValue)
    {
        if (newValue == '1'){
	    Ext.getDom("_startip").disabled=false;
	    Ext.getDom("_endip").disabled=false;
	    Ext.getDom("_gateway").disabled=false;
	}else{
	    Ext.getDom("_startip").disabled=true;
	    Ext.getDom("_endip").disabled=true;
	    Ext.getDom("_gateway").disabled=true;
	}
    	//Ext.Msg.alert('xxx','value changes from '+oldValue+"  to "+newValue);
    });
    
});

</script>
<div id="lanform"></div>
