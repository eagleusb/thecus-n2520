<script language="javascript">

function redirect_reboot(){
    setCurrentPage('reboot');
    processUpdater('getmain.php','fun=reboot');
}

Ext.onReady(function(){
    // turn on validation errors beside the field globally
    Ext.form.Field.prototype.msgTarget = 'side';
    
    var prefix = new Ext.form.Hidden({id: 'prefix', name: 'prefix', value: '<{$prefix}>'});
    var num = new Ext.form.Hidden({id: 'num', name: 'num', value: "<{$num}>"});
    var mac = new Ext.form.Hidden({id: '_mac', name: '_mac', value: "<{$tengb_mac}>"});
    var default_ip = new Ext.form.Hidden({id: '_default_ip', name: '_default_ip', value: "<{$default_ip}>"});
    var default_sdbcp = new Ext.form.Hidden({id: '_default_sdbcp', name: '_default_sdbcp', value: "<{$default_sdbcp}>"});
    var default_edbcp = new Ext.form.Hidden({id: '_default_edbcp', name: '_default_edbcp', value: "<{$default_edbcp}>"});
    var default_mask = new Ext.form.Hidden({id: '_default_mask', name: '_default_mask', value: "<{$default_mask}>"});
    var default_jumbo = new Ext.form.Hidden({id: '_default_jumbo', name: '_default_jumbo', value: "<{$default_jumbo}>"});
    var db_mac = new Ext.form.Hidden({id: '_db_mac', name: '_db_mac', value: "<{$db_mac}>"});
    
    var jumbo_store = new Ext.data.SimpleStore({
        fields: <{$tengb_jumbo_fields}>,
        data: <{$tengb_jumbo_data}>
    });

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
		    listWidth:100
    });
    
    jumbo_combo.on("blur", function(combo) {
    	var valtmp = combo.getRawValue();
    	if (valtmp.search("Disable") < 0) {
			if (valtmp.search("bytes") < 0) {	//if write
				if (valtmp > <{$tengb_jombo_frame_max}>) {
					Ext.Msg.alert('<{$gwords.warning}>','<{$warn_jumbo}>');
					combo.setValue(<{$tengb_jombo_frame_max}>);
					combo.setRawValue('<{$tengb_jombo_frame_max}>');
				} else if (valtmp <= <{$tengb_default_jumbo}>)	{
					Ext.Msg.alert('<{$gwords.warning}>','<{$warn_jumbo}>');
					combo.setValue(<{$tengb_default_jumbo}>);
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
                  {boxLabel: '<{$gwords.enable}>', name: '_dhcp', inputValue: 1 <{if $tengb_dhcp =="1"}>, checked:true <{/if}>},
                  {boxLabel: '<{$gwords.disable}>', name: '_dhcp', inputValue: 0 <{if $tengb_dhcp =="0" || $tengb_dhcp ==""}>, checked:true <{/if}>}
        ]
    });

    var fp = new Ext.FormPanel({
        frame: false,
        labelWidth: 110,
        //width: 600,
        autoWidth: 'true',
        buttonAlign: 'left',
        renderTo:'tengbform',
        bodyStyle: 'padding:0 10px 0;',
        
        items: [{
                  layout: 'column',
                  border: false,
                  defaults: {
                      columnWidth: '.5',
                      border: false
                  }
                },prefix,num,mac,default_ip,default_sdbcp,default_edbcp,default_mask,default_jumbo,db_mac,{
            
            /*====================================================================
             * 10Gbe IP
             *====================================================================*/
                  xtype:'fieldset',
                  title: '<{$title}>',
                  autoHeight: true,
                  layout: 'form',
                  items: [
	    	         {
        	            xtype: 'box'
                        ,height: 25
                        ,autoEl: {cn:"<table><tr height='20'><td width='115'><{$words.mac}>:</td><td><{$tengb_mac}></td></tr></table>"}
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
                        value: '<{$tengb_ip}>'
                      },{
                        xtype: 'textfield',
                        name: '_netmask',
                        fieldLabel: '<{$words.netmask}>',
                        value: '<{$tengb_netmask}>'
                      },{
                        xtype: 'box'
                        ,height: 25
                        ,autoEl: {cn:"<table><tr height='20'><td width='115'><{$words.link_detect}>:</td><td><{$link_detect}></td></tr></table>"}
                      },{
                        xtype: 'box'
                        ,height: 25
                        ,autoEl: {cn:"<table><tr height='20'><td width='115'><{$words.link_speed}>:</td><td><{$link_speed}></td></tr></table>"}
                      }/*,{
                        xtype: 'textfield',
                        name: '_gateway',
                        fieldLabel: '<{$words.gateway}>',
                        value: '<{$lan_gateway}>'
                        <{if $ip_sharing=='1' }>                                                                                                          
                        ,disabled:true
                         <{/if}>
                      }*/]
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
                      value: '<{$tengb_dhcp_startip}>'
                  },{
                      xtype: 'textfield',
                      name: '_endip',
                      id: '_endip',
                      fieldLabel: '<{$words.endip}>',
                      value: '<{$tengb_dhcp_endip}>'
                  },{
		                  html: "<table>"
                           +"<tr height='20'> <td width='115'><{$words.dns}>:</td> <td><{$tengb_dns0}></td> </tr>"
                           +"<tr height='20'> <td width='115'></td> <td><{$tengb_dns1}></td> </tr>"
                           +"<tr height='20'> <td width='115'></td> <td><{$tengb_dns2}></td> </tr>"
                           +"</table>"
                  }]
        }],
        
        buttons: [{
            text: '<{$gwords.apply}>',
            handler: function(){
                if(fp.getForm().isValid()){
			              Ext.Msg.confirm('<{$title}>',"<{$gwords.confirm}>",function(btn){
				              if(btn=='yes'){
					                processAjax('<{$form_action}>',onLoadForm,fp.getForm().getValues(true));
					//Ext.Msg.alert('Submitted Values', 'The following will be sent to the server: <br />'+ 
					//fp.getForm().getValues(true).replace(/&/g,', '));
			                }})
                }
            }
        }]
    });
    
    jumbo_combo.setValue('<{$tengb_jumbo}>');
/*    jumbo_combo.on('expand', function( comboBox ){
      if (!window.ActiveXObject){
        comboBox.list.setWidth( 'auto' );
        comboBox.innerList.setWidth( 'auto' );
      }
    }, this, { single: true });
*/    
    if(<{$tengb_dhcp}>=='0'){
	      Ext.getDom("_startip").disabled=true;
	      Ext.getDom("_endip").disabled=true;
    }
    
    dhcp_radiogroup.on('change',function(RadioGroup,newValue)
    {
      if (newValue == '1'){
	        Ext.getDom("_startip").disabled=false;
	        Ext.getDom("_endip").disabled=false;
	    }else{
	        Ext.getDom("_startip").disabled=true;
	        Ext.getDom("_endip").disabled=true;
	    }
    	//Ext.Msg.alert('xxx','value changes from '+oldValue+"  to "+newValue);
    });
    
});

</script>
<div id="tengbform"></div>
