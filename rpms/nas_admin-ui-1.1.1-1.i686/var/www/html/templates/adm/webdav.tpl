<script language="javascript">
	
/**
 *  Destroy object
 *
 * @param none
 */
function ExtDestroy(){ 
	Ext.destroy(
		Ext.getCmp('webdav_radiogroup'),
		Ext.getCmp('webdav_port_textfield'),
		Ext.getCmp('webdav_ssl_radiogroup'),
		Ext.getCmp('webdav_ssl_port_textfield'),
		Ext.getCmp('browser_view_radiogroup'),
		Ext.getCmp('fp')
	);
}

Ext.onReady(function(){
	// turn on validation errors beside the field globally
	Ext.form.Field.prototype.msgTarget = 'side';
	var prefix = new Ext.form.Hidden({id: 'prefix', name: 'prefix', value: '<{$prefix}>'});
	
	/**
	 *  This is port check vtype setting
	 *
	 * @param none
	 */
	Ext.QuickTips.init();
	Ext.form.VTypes['portListVal'] = /^(102[5-9]|10[3-9][0-9]|1[1-9][0-9]{2}|[2-9][0-9]{3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$/;
	Ext.form.VTypes['portListMask'] = /[0-9]/;
	Ext.form.VTypes['portListText'] = "<{$words.port_out_range}>";
	Ext.form.VTypes['portList'] = function (v) {
		return Ext.form.VTypes['portListVal'].test(v);
	}
	
	/**
	 *  This is WebDAV enable/disable radio object
	 *
	 * @param none
	 */
	var webdav_radiogroup = new Ext.form.RadioGroup({
	xtype: 'radiogroup',
		width:200,
		fieldLabel: "<{$words.webdav_label}>",
		items: [
			{boxLabel: "<{$gwords.enable}>", name: 'webdav_enable', inputValue: 1 <{if $webdav_enable =="1"}>, checked:true <{/if}>},
			{boxLabel: "<{$gwords.disable}>", name: 'webdav_enable', inputValue: 0 <{if $webdav_enable =="0" || $webdav_enable ==""}>, checked:true <{/if}>}
		]
	});

	
	/**
	 *  This is WebDAV port text field
	 *
	 * @param none
	 */
	var webdav_port_textfield = new Ext.form.TextField({
	id: 'webdav_port',
	name: 'webdav_port',
	fieldLabel: "<{$gwords.port}>",
		width:50,
		value: '<{$webdav_port}>',
		vtype: 'portList'
	});
	
	/**
	 *  This is WebDAV on SSL enable/disable radio object
	 *
	 * @param none
	 */
	var webdav_ssl_radiogroup = new Ext.form.RadioGroup({
	xtype: 'radiogroup',
		width:200,
		fieldLabel: "<{$words.webdav_ssl_label}>",
		items: [
			{boxLabel: "<{$gwords.enable}>", name: 'webdav_ssl_enable', inputValue: 1 <{if $webdav_ssl_enable =="1"}>, checked:true <{/if}>},
			{boxLabel: "<{$gwords.disable}>", name: 'webdav_ssl_enable', inputValue: 0 <{if $webdav_ssl_enable =="0" || $webdav_ssl_enable ==""}>, checked:true <{/if}>}
		]
	});
	
	/**
	 *  This is WebDAV on SSL port text field
	 *
	 * @param none
	 */
	var webdav_ssl_port_textfield = new Ext.form.TextField({
	id: 'webdav_ssl_port',
	name: 'webdav_ssl_port',
	fieldLabel: "<{$gwords.port}>",
		width:50,
		value: '<{$webdav_ssl_port}>',
		vtype: 'portList'
	});
	
	/**
	 *  This is WebDAV allow view on browser function enable/disable radio object
	 *
	 * @param none
	 */
	var browser_view_radiogroup = new Ext.form.RadioGroup({
	xtype: 'radiogroup',
		width:200,
		fieldLabel: "<{$words.browser_view_label}>",
		items: [
			{boxLabel: "<{$gwords.enable}>", name: 'webdav_browser_view', inputValue: 1 <{if $webdav_browser_view =="1"}>, checked:true <{/if}>},
			{boxLabel: "<{$gwords.disable}>", name: 'webdav_browser_view', inputValue: 0 <{if $webdav_browser_view =="0" || $webdav_browser_view ==""}>, checked:true <{/if}>}
		]
	});
	
	/**
	 *  This is WebDAV Form object
	 *
	 * @param none
	 */

	var fp = new Ext.FormPanel({
		frame: false,
		labelWidth: 140,
		autoWidth: 'true',
		renderTo:'webdav_form',
		bodyStyle: 'padding:0 10px 0;',
		
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
				/*====================================================================
				* WebDAV
				*====================================================================*/
				xtype:'fieldset',
				title: '<{$words.webdav_title}>',
				autoHeight: true,
				buttonAlign: 'left',
				items:[ 
					webdav_radiogroup,
					webdav_port_textfield,
					webdav_ssl_radiogroup,
					webdav_ssl_port_textfield,
					browser_view_radiogroup,
					{
						xtype:'hidden',
						id:'o_webdav_enable',
						name:'o_webdav_enable' ,
						value:'<{$webdav_enable}>'
					},{
						xtype:'hidden',
						id:'o_webdav_port',
						name:'o_webdav_port' ,
						value:'<{$webdav_port}>'
					},{
						xtype:'hidden',
						id:'o_webdav_ssl_enable',
						name:'o_webdav_ssl_enable' ,
						value:'<{$webdav_ssl_enable}>'
					},{
						xtype:'hidden',
						id:'o_webdav_ssl_port',
						name:'o_webdav_ssl_port' ,
						value:'<{$webdav_ssl_port}>'
					},{
						xtype:'hidden',
						id:'o_webdav_browser_view',
						name:'o_webdav_browser_view' ,
						value:'<{$webdav_browser_view}>'
					}
				]
			},
			{
			    xtype: 'button',
				text: '<{$gwords.apply}>',
				handler: function(){
					if(fp.getForm().isValid()){
						Ext.Msg.confirm('<{$words.alert_title}>',"<{$gwords.confirm}>",function(btn){
							if(btn=='yes'){
								//Check setting is changed
								if( webdav_radiogroup.getValue()==Ext.getCmp('o_webdav_enable').getValue()
								   && webdav_port_textfield.getValue()==Ext.getCmp('o_webdav_port').getValue()
								   && webdav_ssl_radiogroup.getValue()==Ext.getCmp('o_webdav_ssl_enable').getValue()
								   && webdav_ssl_port_textfield.getValue()==Ext.getCmp('o_webdav_ssl_port').getValue()
								   && browser_view_radiogroup.getValue()==Ext.getCmp('o_webdav_browser_view').getValue())
									Ext.Msg.show({
										title: "<{$words.alert_title}>",
                                        msg: "<{$gwords.setting_confirm}>",
                                        buttons: Ext.Msg.OK,
                                        icon: Ext.MessageBox.INFO
									});
								else if( webdav_port_textfield.getValue()==webdav_ssl_port_textfield.getValue())
									Ext.Msg.show({
										title: "<{$words.alert_title}>",
                                        msg: "<{$words.webdav_eq_ssl}>",
                                        buttons: Ext.Msg.OK,
                                        icon: Ext.MessageBox.INFO
									});
								else
									processAjax('<{$form_action}>',onLoadForm,fp.getForm().getValues(true));
                                                                        Ext.getCmp('o_webdav_enable').setValue(webdav_radiogroup.getValue());
                                                                        Ext.getCmp('o_webdav_port').setValue(webdav_port_textfield.getValue());
                                                                        Ext.getCmp('o_webdav_ssl_enable').setValue(webdav_ssl_radiogroup.getValue());
                                                                        Ext.getCmp('o_webdav_ssl_port').setValue(webdav_ssl_port_textfield.getValue());
                                                                        Ext.getCmp('o_webdav_browser_view').setValue(browser_view_radiogroup.getValue());
							}
						});
					}
				}
			},
			{
				/*====================================================================
				* Description
				 *====================================================================*/
				xtype:'fieldset',
				title: '<{$gwords.description}>',
				autoHeight: true,
				items: [{
					html:'<{$words.fun_desc}>'
				}]
			}
		]
		
	});

	/*====================================================================
	 * Set items hide/show rule
	 *====================================================================*/ 

	if('<{$webdav_enable}>'=='0'){
		webdav_port_textfield.setDisabled(true);
	}
	
	if('<{$webdav_ssl_enable}>'=='0'){
		webdav_ssl_port_textfield.setDisabled(true);
	}
	
	if('<{$webdav_enable}>'=='0' && '<{$webdav_ssl_enable}>'=='0'){
		browser_view_radiogroup.disable();
	}
	
	webdav_radiogroup.on('change',function(RadioGroup,newValue)
	{
		if (newValue == '1'){
			webdav_port_textfield.setDisabled(false);
			browser_view_radiogroup.enable();
		}else{
			webdav_port_textfield.setDisabled(true);
			if(webdav_ssl_radiogroup.getValue() == '0'){
				browser_view_radiogroup.disable();
			}
		}
	});
	
	webdav_ssl_radiogroup.on('change',function(RadioGroup,newValue)
	{
		if (newValue == '1'){
			webdav_ssl_port_textfield.setDisabled(false);
			browser_view_radiogroup.enable();
		}else{
			webdav_ssl_port_textfield.setDisabled(true);
			if(webdav_radiogroup.getValue() == '0'){
				browser_view_radiogroup.disable();
			}
		}
	});
	
});

</script>
<div id="webdav_form"></div>
