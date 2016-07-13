<div id="tftpform"></div>

<script language="javascript">

Ext.reg("sliderfield", Ext.form.SliderField); 

Ext.onReady(function(){
	// turn on validation errors beside the field globally
	Ext.form.Field.prototype.msgTarget = "side";
	var nics = <{$interface_list}>;
	var prefix = new Ext.form.Hidden({id: "prefix", name: "prefix", value: "tftp"});

	var tftp_radiogroup = new Ext.form.RadioGroup({
		xtype: "radiogroup",
		width: 400,
		fieldLabel: "<{$words.tftp}>",
		items: [
			{boxLabel: "<{$gwords.enable}>", name: "_tftp", inputValue: 1 <{if $tftp_enabled =="1"}>, checked:true <{/if}>},
			{boxLabel: "<{$gwords.disable}>", name: "_tftp", inputValue: 0 <{if $tftp_enabled =="0" || $tftp_enabled ==""}>, checked:true <{/if}>}
		],
		listeners:{
			change:{
				fn:function(obj,val){
					tftp_status(val);
				}
			}
		}
	});

	var write_item = new Ext.Panel({
		layout:"column",
		border:false,
		bodyStyle:"padding:0 0 0 0;",
		defaults:{
			layout:"form",
			border:false,
			bodyStyle:"padding:0 0 0 0;",
			xtype:"panel"
		}
	});

	var folder_store=new Ext.data.JsonStore({
		fields: ["folder_name"],
		data:<{$folder_list}>
	});
	var folder_combobox = new Ext.form.ComboBox({
		store:folder_store,
		fieldLabel: "<{$words.tftp_folder}>",
		valueField : "folder_name",
		displayField: "folder_name",
		mode: "local",
		forceSelection: true,
		editable: false,
		triggerAction: "all",
		id: "_folder",
		name: "_folder",
		listWidth :150,
		width:200
	});
	folder_combobox.setValue("<{$tftp_folder}>");
	
	// check if the original folder is found among the folder list
	var match_flag = false;
	for (var i = 0; i < <{$folder_list}>.length; i++) {
		if (<{$folder_list}>[i]["folder_name"] == "<{$tftp_folder}>") {
			match_flag = true;
			break;
		}
	}
	folder_combobox.on("render", function(combox) {
		if (!match_flag) {
			Ext.getCmp("_folder_error").html="<span style='color:red'>" + "<{$words.tftp_folder_not_found}>".replace("%s","<{$tftp_folder}>") + "</span>";
		}
	});
	folder_combobox.on("select", function() {
		if (Ext.getCmp("_folder_error").getEl().dom.innerHTML != "") {
			Ext.getCmp("_folder_error").getEl().dom.innerHTML = "";
			match_flag = true;
		}
	});

	var nic_selected = {};

	var fp = new Ext.FormPanel({
		frame: false,
		labelWidth: 160,
		width: 830,
		renderTo: "tftpform",
		style: "margin: 10px;",
		hideMode: "offsets",

		items: [
		{
			layout: "column",
			border: false,
			defaults: {
				columnWidth: ".5",
				border: false
			}
		},prefix,{
			xtype:"fieldset",
			title: "<{$words.tftp}>",
			autoHeight: true,
			layout: "form",
			buttonAlign: "left",
			items: [
			tftp_radiogroup,
			{
				layout: 'table',
				layoutConfig: {
					columns: 2
				},
				style: 'margin-bottom: 3px;',
				items: [
					{
						xtype: 'panel',
						html: 'NICs:',
						width: 160
					},
					{
						xtype: 'button',
						text: 'Available',
						fieldLabel: "<{$gwords.ip}>",
						menu: {
							items: (function(){
								var menu = [];
								for( i = 0 ; i < nics.length ; ++i ) {
									var nic = nics[i];
									if( nic[2] ) {
										if( nic[0] == 1 ) {
											nic_selected[nic[3] + '-' + nic[1]] = true;
										}
										menu.push(new Ext.menu.CheckItem({
										    nic: nic[4],
											mac: nic[1],
											eth: nic[3],
											checked: nic[0] == 1,
											text: String.format('{0}[{1}]', nic[4], nic[2] || ''),
											listeners: {
												checkchange: function(checkitem, checked) {
												        var nic_mac = checkitem.eth + '-' + checkitem.mac;
													if( checked ) {
														nic_selected[nic_mac] = true;
													} else {
														delete nic_selected[nic_mac];
													}
												}
											}
										}))
									}
								}
								return menu;
							})()
						}
					}
				]
			},
			{
				xtype: "numberfield",
				name: "_port",
				id: "_port",
				width: "50",
				fieldLabel: "<{$gwords.port}>",
				value: "<{$tftp_port}>",
				maxLength:5
			},
			folder_combobox,
			{
				xtype: "label",
				id: "_folder_error",
				name: "_folder_error",
				html: ""
			},{
				xtype: "checkbox",
				id: "_read",
				name: "_read",
				hideLabel:false,
				fieldLabel: "<{$words.tftp_permission}>",
				boxLabel: "<{$words.tftp_read}>",
				checked: "<{$tftp_read}>"
			},{
                xtype: "checkbox",
                labelSeparator : "",
                id: "_write",
                name: "_write",
                boxLabel: "<{$words.tftp_write}>",
                checked: "<{$tftp_write}>",
                listeners:{
                    check:{
                        fn:function(obj, chk){
                            if(chk) {
                                Ext.getCmp("_overwrite").setDisabled(false);
                            } else {
                                Ext.getCmp("_overwrite").setDisabled(true);
                                Ext.getCmp("_overwrite").setValue(false);
                            }
                        }
                    }
                }
            },{
                xtype: "checkbox",
                id:"_overwrite",
                name:"_overwrite",
                labelSeparator : "",
                boxLabel: "<{$words.tftp_overwrite}>",
                checked: "<{if $tftp_overwrite}> true <{/if}>",
                disabled: <{if $tftp_write}> false <{else}> true <{/if}>
			}],
			buttons: [
			{
				text: "<{$gwords.apply}>",
				handler: function(){
					var nics = [];
					for( mac in nic_selected ) {
						nics.push(mac);
					}
					
					var errmsg = "";
					if (!fp.getForm().isValid()) {
						return;
					}
					if (tftp_radiogroup.getValue() == 1) {
						if (Ext.getDom("_port").value == "" || Ext.getDom("_port").value == null) {
							errmsg += "<{$words.tftp_port_empty}> <br>";
						}
						if (!Ext.getDom("_read").checked && !Ext.getDom("_write").checked) {
							errmsg += "<{$words.tftp_permission_warn}> <br>";
						}
						if (!match_flag) {
							errmsg += "<{$words.tftp_folder_not_found}>".replace("%s","<{$tftp_folder}>");
						}
						if( nics.length == 0 ) {
						        errmsg += "<{$words.no_ip}>";
						}
						if (errmsg != "") {
							mag_box("<{$words.tftp}>", errmsg, "WARNING", "OK", null, false);
							return;
						}
						
					}
					
					nics = String.format('&nics={0}', nics.join('|'));
					Ext.Msg.confirm("<{$words.tftp}>","<{$gwords.confirm}>",function(btn){
						if(btn=="yes"){
							ftp_flag=0;
							if (Ext.getDom("_port").disabled){
								ftp_flag=1;
								tftp_status(1);
							}
							processAjax("<{$form_action}>",onLoadForm,fp.getForm().getValues(true) + nics);
							if (ftp_flag == 1) 
								tftp_status(0);
						}
					})
				}
			}]			
		}]
	});
	
	function tftp_status(val) {
		if (val == 0) {
			Ext.getCmp("_read").setDisabled(true);
			Ext.getCmp("_write").setDisabled(true);
			Ext.getCmp("_overwrite").setDisabled(true);
			Ext.getCmp("_folder").setDisabled(true);
			Ext.getCmp("_port").setDisabled(true);
		} else {
			Ext.getCmp("_read").setDisabled(false);
			Ext.getCmp("_write").setDisabled(false);
			if (Ext.getCmp("_write").getValue()) {
				Ext.getCmp("_overwrite").setDisabled(false);
			} else {
				Ext.getCmp("_overwrite").setDisabled(true);
			}
			Ext.getCmp("_folder").setDisabled(false);
			Ext.getCmp("_port").setDisabled(false);
		}
	};
	
	tftp_status(<{$tftp_enabled}>);
	
});

</script>
