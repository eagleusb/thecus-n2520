
var ENCRYPTKEY_MAX_LEN = 16;
var RAID_ID_MAX_LEN = 12;
var raid_wizard = null;
var raid_disk_form = null;
var raid_level_form = null;
var raid_property_form = null;
var raid_sys_form = null;
var raid_confirm_form = null;
var raid_final_form = null;
var raid_disk_used_count = 0;
var raid_disk_spare_count = 0;
var raid_suffix_id = "";
var wizard_btn = {"N": "<{$gwords.next}>", "P": "<{$gwords.prev}>", "C": "<{$gwords.cancel}>", "S": "<{$gwords.submit}>", "F": "<{$gwords.finish}>"};
var url = ("<{$geturl}>" !== "")?"<{$geturl}>":"getmain.php?fun=raid";
var raidConfirmData = "";

/* Check if zfs fiel system is available. 
 * Only for raid.tpl & raid_create.tpl
 * @author: ellie_chien
 * 
 * @return: none
 */
function check_zfs(){
	raid_wizard.mask.hide();
	var request = eval('('+this.req.responseText+')');
	var zfs_status=request.zfs_status;
	var msg=request.msg;
	if(zfs_status==1){
		Ext.Msg.alert("<{$rwords.raid_config_title}>",msg);
		if (button_click == "init" || button_click == "create") {
			raid_wizard.setDisabledBtn('N',true);
		} else if(button_click == "edit") {
			apply_btn.setDisabled(true);
		}
	}else{
		if (button_click == "init" || button_click == "create") {
			raid_wizard.setDisabledBtn('N',false);
		} else if(button_click == "edit") {
			apply_btn.setDisabled(false);
		}
	}
}

/* Used when hiding an item of radiogroup.
 * Only for raid_create.tpl
 * @author: Kenny Wu
 * 
 */
function setRaidLevelShow(id, hide) {
    if(hide == false) {
        Ext.getCmp(id).container.dom.parentNode.parentNode.parentNode.parentNode.style.position = 'absolute';
        Ext.getCmp(id).container.dom.parentNode.parentNode.parentNode.parentNode.style.left = -1000;
    }else{
        Ext.getCmp(id).container.dom.parentNode.parentNode.parentNode.parentNode.style.position = '';
        Ext.getCmp(id).container.dom.parentNode.parentNode.parentNode.parentNode.style.left = '';
    }
}

/* Process the raid level condition according to the used disk count and the spare disk couont.
 * Only for raid_create.tpl
 * @author: ellie_chien
 * 
 * @return: [string] raid_level_list, sperated by comma
 */
function processRaidLevelByDiskCount()
{
	//var hv_lock = (file_system_store.totalLength == 1);
	var hv_lock = 0;
	Ext.getCmp("jbod" + raid_suffix_id).setValue(false);
	Ext.getCmp("raid0" + raid_suffix_id).setValue(false);
	Ext.getCmp("raid1" + raid_suffix_id).setValue(false);
	Ext.getCmp("raid5" + raid_suffix_id).setValue(false);
	Ext.getCmp("raid6" + raid_suffix_id).setValue(false);
	Ext.getCmp("raid10" + raid_suffix_id).setValue(false);
	Ext.getCmp("raid50" + raid_suffix_id).setValue(false);
	Ext.getCmp("raid60" + raid_suffix_id).setValue(false);

	var raid_level_list = "";
	if (raid_disk_used_count <= 0) return raid_level_list;
	
	if(raid_disk_used_count > 0 && raid_disk_spare_count==0 && !hv_lock){
		Ext.getCmp("jbod" + raid_suffix_id).show();
		setRaidLevelShow("jbod" + raid_suffix_id);
		Ext.getCmp("jbod_desc" + raid_suffix_id).show();
		raid_level_list = "JBOD,";
	} else {
		Ext.getCmp("jbod" + raid_suffix_id).hide();
		setRaidLevelShow("jbod" + raid_suffix_id, false);
		Ext.getCmp("jbod_desc" + raid_suffix_id).hide();
	}
	if(raid_disk_used_count >= 2 && raid_disk_spare_count==0 && !hv_lock){
		Ext.getCmp("raid0" + raid_suffix_id).show();
		setRaidLevelShow("raid0" + raid_suffix_id);
		Ext.getCmp("raid0_desc" + raid_suffix_id).show();
		raid_level_list += "RAID 0,";
	} else {
		Ext.getCmp("raid0" + raid_suffix_id).hide();
		setRaidLevelShow("raid0" + raid_suffix_id, false);
		Ext.getCmp("raid0_desc" + raid_suffix_id).hide();
	}
	if(raid_disk_used_count >= 2 && !hv_lock){
		Ext.getCmp("raid1" + raid_suffix_id).show();
		setRaidLevelShow("raid1" + raid_suffix_id);
		Ext.getCmp("raid1_desc" + raid_suffix_id).show();
		raid_level_list += "RAID 1,";
	} else {
		Ext.getCmp("raid1" + raid_suffix_id).hide();
		setRaidLevelShow("raid1" + raid_suffix_id, false);
		Ext.getCmp("raid1_desc" + raid_suffix_id).hide();
	}
	if(raid_disk_used_count >= 3){
		Ext.getCmp("raid5" + raid_suffix_id).show();
		setRaidLevelShow("raid5" + raid_suffix_id);
		Ext.getCmp("raid5_desc" + raid_suffix_id).show();
		raid_level_list += "RAID 5,";
	} else {
		Ext.getCmp("raid5" + raid_suffix_id).hide();
		setRaidLevelShow("raid5" + raid_suffix_id, false);
		Ext.getCmp("raid5_desc" + raid_suffix_id).hide();
	}
	if(raid_disk_used_count >= 4){
		Ext.getCmp("raid6" + raid_suffix_id).show();
		setRaidLevelShow("raid6" + raid_suffix_id);
		Ext.getCmp("raid6_desc" + raid_suffix_id).show();
		raid_level_list += "RAID 6,";
	} else {
		Ext.getCmp("raid6" + raid_suffix_id).hide();
		setRaidLevelShow("raid6" + raid_suffix_id, false);
		Ext.getCmp("raid6_desc" + raid_suffix_id).hide();
	}
	if((raid_disk_used_count%2) == 0 && raid_disk_used_count >= 4){
		Ext.getCmp("raid10" + raid_suffix_id).show();
		setRaidLevelShow("raid10" + raid_suffix_id);
		Ext.getCmp("raid10_desc" + raid_suffix_id).show();
		raid_level_list += "RAID 10,";
	} else {
		Ext.getCmp("raid10" + raid_suffix_id).hide();
		setRaidLevelShow("raid10" + raid_suffix_id, false);
		Ext.getCmp("raid10_desc" + raid_suffix_id).hide();
	}
	if((raid_disk_used_count%2) == 0 && raid_disk_used_count >= 6){
		Ext.getCmp("raid50" + raid_suffix_id).show();
		setRaidLevelShow("raid50" + raid_suffix_id);
		Ext.getCmp("raid50_desc" + raid_suffix_id).show();
		raid_level_list += "RAID 50,";
	} else {
		Ext.getCmp("raid50" + raid_suffix_id).hide();
		setRaidLevelShow("raid50" + raid_suffix_id, false);
		Ext.getCmp("raid50_desc" + raid_suffix_id).hide();
	}
	if((raid_disk_used_count%2) == 0 && raid_disk_used_count >= 8){
		Ext.getCmp("raid60" + raid_suffix_id).show();
		setRaidLevelShow("raid60" + raid_suffix_id);
		Ext.getCmp("raid60_desc" + raid_suffix_id).show();
		raid_level_list += "RAID 60,";
	} else {
		Ext.getCmp("raid60" + raid_suffix_id).hide();
		setRaidLevelShow("raid60" + raid_suffix_id, false);
		Ext.getCmp("raid60_desc" + raid_suffix_id).hide();
	}
	
	if (raid_level_list.length > 0) {
		raid_level_list = raid_level_list.substr(0, raid_level_list.length - 1);
	}
	if( hv_lock && raid_disk_used_count < 3 )
		raid_wizard.setDisabledBtn('N',true);
	else
		raid_wizard.setDisabledBtn('N',false);
	
	return raid_level_list;
}

/* Calculate the used and spare disk number.
 * If the checkbox has been checked and then count plus 1.
 * Otherwise count minus 1.
 * Only for raid_create.tpl
 * Used by renderRaidUsedDisk() & renderRaidSpareDisk()
 * @author: ellie_chien
 * 
 * @param {Object} disk_index: disk number
 * @param {Object} disk_type: to express the item is a used disk or a spare disk
 * 
 * @return: none
 */
function checkDiskCount(allocate,disk_index,disk_type)
{
    raid_disk_used_count = 0;
    for(tray in allocate.used) {
        var disk = allocate.used[tray];
        raid_disk_used_count++;
    }
    
    raid_disk_spare_count = 0;
    for(tray in allocate.spare) {
        var disk = allocate.spare[tray];
        raid_disk_spare_count++;
    }
    
	if (raid_disk_used_count <= 0 || (raid_disk_used_count == 1 && raid_disk_spare_count > 0)) {
		var wizard = init_wizard || raid_wizard;
		wizard.setDisabledBtn('N', true);
		if( raid_wizard ) {
		    Ext.getCmp("raid_level_list" + raid_suffix_id).getEl().dom.innerHTML = "<{$rwords.raid_level_list}><{$gwords.none}>";
		}
	} else {
		var wizard = init_wizard || raid_wizard;
		wizard.setDisabledBtn('N', false);
		if( raid_wizard ) {
		    Ext.getCmp("raid_level_list" + raid_suffix_id).getEl().dom.innerHTML = "<{$rwords.raid_level_list}>" + processRaidLevelByDiskCount();
		}
	}
}

/* Embed html code into grid cell to show the disk status by color.
 * Only for raid.tpl & raid_create.tpl
 * @author: ellie_chien
 * 
 * @param {Object} value: the grid cell value
 * @param {Object} cellmata: the grid cell data information
 * @param {Object} record: the record in the index line
 * @param {Object} rowIndex: row index
 * 
 * @return: status (html string)
 */
function change_disk_status_color(value,cellmata,record,rowIndex){
	var status;
	if (value != "OK" && value != "N/A") {
		status = "<span style='color:red'>" + value + "</span>";
	} else {
		status = value;
	}
	return status;
}

/* Render disk grid.
 * Only for raid_create.tpl & init.tpl.
 * @author: ellie_chien
 * 
 * @param {Object} id: the disk grid's id
 * 
 * @return diskgrid
 */
function renderDiskGrid (id) 
{
    return new TCode.ux.Disk({
        id: id,
        width: 553,
        height: 250,
        frame: false,
        disableSelection: true,
        used: true,
        spare: true,
        listeners: {
            diskAllocate: function(allocate) {
                if( typeof checkInitDiskCount == 'function' ) {
                    checkInitDiskCount(allocate);
                }
                checkDiskCount(allocate)
            }
        }
    });
}

/* Render the form including disk grid.
 * Only for raid_create.tpl
 * @author: ellie_chien
 * 
 * @return: none
 */
function renderDiskForm ()
{
	var diskgrid = renderDiskGrid("disk" + raid_suffix_id);
	var raid_disk_form = new Ext.FormPanel({
		frame: true,
		items: [
		diskgrid,
		{
			xtype: "box",
			autoEl: {
				html: "<br><br><{$gwords.description}>:"
			},
			cls: "wizard-desc-head"
		},{
			xtype: "box",
			autoEl: {
				html: "<br><{$rwords.disk_list_desc}>"
			},
			cls: "wizard-desc"
		},{
			xtype: "box",
			id: "raid_level_list" + raid_suffix_id,
			autoEl: {
				html: "<br><{$rwords.raid_level_list_}>"
			},
			cls: "wizard-desc"
		}]
	});
	return raid_disk_form;
}

/* Render the form including a radiogroup of raid levels.
 * Only for raid_create.tpl
 * @author: ellie_chien
 * 
 * @return: raid_level_form
 */
function renderRaidLevelForm ()
{
	var raid_level_form = new Ext.FormPanel({
		frame: true,
		items:[
		{	
			fieldLabel: "<{$rwords.raidlevel}>",
			xtype: "radiogroup",
			id: "raid_level",
			columns: [100, 100, 100, 100, 100, 100, 100, 100],
			vertical: true,
			defaults: {bodyStyle: "padding:0 0 0 0;margin:0px;", width: 100},
			listeners: {
				change:{
					fn:function(r,c){
						var wizard = init_wizard || raid_wizard;
						wizard.setDisabledBtn('N', false);
						if(c == "J" || c == "0"){
							Ext.getCmp('_assume_clean' + raid_suffix_id).setDisabled(true);
							Ext.getCmp('_assume_clean' + raid_suffix_id).setValue(false);
						}else{
							Ext.getCmp('_assume_clean' + raid_suffix_id).setDisabled(false);
						}
						if(c==1){
							Ext.getCmp("chunk" + raid_suffix_id).setDisabled(true);
						}else{
							Ext.getCmp("chunk" + raid_suffix_id).setDisabled(false);
						}
						if('<{$NAS_DB_KEY}>' != '1'){
							Ext.getCmp("data_percent" + raid_suffix_id).setDisabled(true);
						}
					}
				}
			},
			items: [
			{
				boxLabel: "JBOD",
				id: "jbod" + raid_suffix_id,
				name: "type",
				inputValue: "J"
			},{
				boxLabel: "RAID 0",
				id: "raid0" + raid_suffix_id,
				name: "type",
				inputValue: "0"
			},{
				boxLabel: "RAID 1",
				id: "raid1" + raid_suffix_id,
				name: "type",
				inputValue: "1"
			},{
				boxLabel: "RAID 5",
				id: "raid5" + raid_suffix_id,
				name: "type",
				inputValue: "5"
			},{
				boxLabel: "RAID 6",
				id: "raid6" + raid_suffix_id,
				name: "type",
				inputValue: "6"
			},{
				boxLabel: "RAID 10",
				id: "raid10" + raid_suffix_id,
				name: "type",
				inputValue: "10"
			},{
				boxLabel: "RAID 50",
				id: "raid50" + raid_suffix_id,
				name: "type",
				inputValue: "50"
			},{
				boxLabel: "RAID 60",
				id: "raid60" + raid_suffix_id,
				name: "type",
				inputValue: "60"
			}]
		},{
			xtype: "box",
			autoEl: {
				html: "<{$gwords.description}>:"
			},
			cls: "wizard-desc-head"
		},{
			xtype: "box",
			id: "jbod_desc" + raid_suffix_id,
			autoEl: {
				html: "<br><span class=wizard-desc-head>JBOD: </span><{$rwords.jbod_desc}>"
			},
			cls: "wizard-desc"
		},{
			xtype: "box",
			id: "raid0_desc" + raid_suffix_id,
			autoEl: {
				html: "<br><span class=wizard-desc-head>RAID 0: </span><{$rwords.raid0_desc}>"
			},
			cls: "wizard-desc"
		},{
			xtype: "box",
			id: "raid1_desc" + raid_suffix_id,
			autoEl: {
				html: "<br><span class=wizard-desc-head>RAID 1: </span><{$rwords.raid1_desc}>"
			},
			cls: "wizard-desc"
		},{
			xtype: "box",
			id: "raid5_desc" + raid_suffix_id,
			autoEl: {
				html: "<br><span class=wizard-desc-head>RAID 5: </span><{$rwords.raid5_desc}>"
			},
			cls: "wizard-desc"
		},{
			xtype: "box",
			id: "raid6_desc" + raid_suffix_id,
			autoEl: {
				html: "<br><span class=wizard-desc-head>RAID 6: </span><{$rwords.raid6_desc}>"
			},
			cls: "wizard-desc"
		},{
			xtype: "box",
			id: "raid10_desc" + raid_suffix_id,
			autoEl: {
				html: "<br><span class=wizard-desc-head>RAID 10: </span><{$rwords.raid10_desc}>"
			},
			cls: "wizard-desc"
		},{
			xtype: "box",
			id: "raid50_desc" + raid_suffix_id,
			autoEl: {
				html: "<br><span class=wizard-desc-head>RAID 50: </span><{$rwords.raid50_desc}>"
			},
			cls: "wizard-desc"
		},{
			xtype: "box",
			id: "raid60_desc" + raid_suffix_id,
			autoEl: {
				html: "<br><span class=wizard-desc-head>RAID 60: </span><{$rwords.raid60_desc}>"
			},
			cls: "wizard-desc"
		}]
	});
	
	return raid_level_form;
}

/* Render the form including [RAID ID], [Master RAID], [Encryption] and [Quick Raid].
 * Only for raid_create.tpl
 * @author: ellie_chien
 * 
 * @return: raid_property_form
 */
function renderRaidPropertyForm ()
{
	//var hv_lock = (file_system_store.totalLength == 1);
	var hv_lock = 0;
	var raid_property_form = new Ext.FormPanel({
		frame: true,
		items:[
		{
			xtype: "textfield",
			fieldLabel: "<{$gwords.raid_id}>",
			width: 100,
			id: "raid_id" + raid_suffix_id,
			name: "raid_id",
			value:"RAID",
			allowBlank: false,
			maxLength: RAID_ID_MAX_LEN,
			maskRe: /^[0-9a-zA-Z]$/,
			regex: /[0-9a-zA-Z]$/
		},{
			xtype: "checkbox",
			id: "master" + raid_suffix_id,
			hidden: hv_lock,
			name: "master",
			hideLabel: true,
			inputValue: "1",
			checked: <{if $sysconf.m_raid == 0}>true<{else}>false<{/if}>,
			boxLabel: "<{$rwords.raidmaster}>",
			listeners: {
				check: function (obj, chk) {
					if (chk) {
						Ext.Msg.alert("<{$rwords.raid_config_title}>","<{$rwords.warn_master_raid}>");
					}
				}
			}
		},{
			xtype: "checkbox",
			hideLabel: true,
			hidden: hv_lock,
			boxLabel: "<{$rwords.encrypt}>",
			id: "_encrypt" + raid_suffix_id,
			name: "_encrypt",
			value: "",
			disabled: <{if $open_encrypt == 1}>false<{else}>true<{/if}>,
			listeners:{
				check : function(obj,chk) {
					if (chk == true){
						Ext.Msg.alert("<{$rwords.raid_config_title}>", "<{$gwords.warn_encrypt}>");
						Ext.getCmp("_encryptkey" + raid_suffix_id).setDisabled(false);
						Ext.getCmp("_confirmkey" + raid_suffix_id).setDisabled(false);
					}else{
						Ext.getCmp("_encryptkey" + raid_suffix_id).clearInvalid();
						Ext.getCmp("_confirmkey" + raid_suffix_id).clearInvalid();
						Ext.getCmp("_encryptkey" + raid_suffix_id).setDisabled(true);
						Ext.getCmp("_confirmkey" + raid_suffix_id).setDisabled(true);
					}
				}
			}
		},{
			xtype: "textfield",
			id: "_encryptkey" + raid_suffix_id,
			hidden: hv_lock,
			hideLabel: hv_lock,
			name: "_encryptkey",
			inputType: "password",
			fieldLabel: "<{$gwords.password}>",
			labelWidth: 150,
			labelStyle: "text-indent: 18; width: 150px;",
			maxLength: ENCRYPTKEY_MAX_LEN,
			allowBlank: false,
			disabled: true
		},{
			xtype: "textfield",
			id: "_confirmkey" + raid_suffix_id,
			hidden: hv_lock,
			hideLabel: hv_lock,
			name: "_confirmkey",
			inputType: "password",
			fieldLabel: "<{$gwords.pwd_confirm}>",
			labelStyle: "text-indent: 18; width: 150px;",
			allowBlank: false,
			maxLength: ENCRYPTKEY_MAX_LEN,
			disabled: true
		},{
			xtype: "checkbox",
			hideLabel: true,
			boxLabel: "<{$rwords.assume_clean}>",
			id: "_assume_clean" + raid_suffix_id,
			name: "_assume_clean",
			inputValue: "1",
			checked: false
		},{
			xtype: "box",
			autoEl: {
				html: "<br><br><{$gwords.description}>:"
			},
			cls: "wizard-desc-head"
		},{
			xtype: "box",
			autoEl: {
				html: "<br>" + ( hv_lock ? "<{$rwords.prop_desc}>".split("<br>")[0] : "<{$rwords.prop_desc}>" )
			},
			cls: "wizard-desc"
		}]
	});
	
	if("<{$sysconf.m_raid}>" == "0"){
		Ext.getCmp('master' + raid_suffix_id).hide();
	}
	
	return raid_property_form;
}

/* Render the form including [Stripe Size], [File System] and [Data Percentage].
 * Only for raid_create.tpl
 * @author: ellie_chien
 * 
 * @return: raid_sys_form
 */
function renderRaidSysForm ()
{
	var chunk_combobox = new Ext.form.ComboBox({
		store: chunk_store,	// global parameter from raid.tpl
		fieldLabel: "<{$rwords.chunksize}>",
		valueField: "value",
		displayField:"display",
		mode: "local",
		forceSelection: true,
		editable: false,
		triggerAction: "all",
		id: "chunk" + raid_suffix_id,
		name: "chunk" + raid_suffix_id,
		hiddenName: "chunk",
		width: 80,
		listWidth: 80,
		value: 64
	});
	var fs = "ext4";
	//if(file_system_store.totalLength == 1) {
	//	fs = "hv";
	//}
	var fs_combobox = new Ext.form.ComboBox({
		store: file_system_store,	// global parameter from raid.tpl
		fieldLabel: "<{$rwords.filesystem}>",
		valueField: "value",
		displayField: "display",
		mode: "local",
		forceSelection: true,
		editable: false,
		triggerAction: "all",
		id: "filesystem" + raid_suffix_id,
		name: "filesystem" + raid_suffix_id,
		hiddenName: "filesystem",
		value: fs,
		width: 60,
		listWidth: 60,
		listeners: {
			select:{
				fn:function(Obj,record,index){
					if (record.data["value"] == "zfs") {
						raid_wizard.mask.show();
						processAjax(url + "&action=check_zfs&fsmode="+record.data["value"],check_zfs,"", false);
					}
				}
			}
		}
	});
	var data_percent_tip = new Ext.ux.SliderTip({
		getText: function(slider){
			return String.format('<b>{0}%</b>', slider.getValue());
		}
	});


	var data_percent_slider = new Ext.form.SliderField({
		xtype:"sliderfield",
		fieldLabel: "<{$rwords.datapercent}>",
		id: "data_percent" + raid_suffix_id,
		name: "data_percent",
		width: 200,
		value: <{if $NAS_DB_KEY == 1}>95<{else}>100<{/if}>,
		minValue: "1",
		setMsg: " %",
		setZero: "1 %",
		maxValue: 100,
		plugins: data_percent_tip
	});

	var raid_sys_form = new Ext.FormPanel({
		frame: true,
		items: [
		chunk_combobox,
		fs_combobox,
<{if $NAS_DB_KEY == 1}>
		data_percent_slider,
<{else}>
<{/if}>
		{
			xtype: "box",
			autoEl: {
				html: "<br><br><{$gwords.description}>:"
			},
			cls: "wizard-desc-head"
		},{
			xtype: "box",
			autoEl: {
			<{if $NAS_DB_KEY == 1}>
				html: "<br><{$rwords.sys_desc_1}><br><{$rwords.sys_desc_2}>"
			<{else}>
				html: "<br><{$rwords.sys_desc_1}>"
			<{/if}>
			},
			cls: "wizard-desc"
		}]
	});
	
	return raid_sys_form;
}

/* Render the grid including each field confirmed data.
 * Only for raid_create.tpl & init.tpl
 * @author: ellie_chien
 * 
 * @param {Object} id: the confirmed grid id
 * 
 * @return: raid_confirm_grid
 */
function renderRaidConfirmGrid (id)
{
	var raid_confirm_store = new Ext.data.Store({
		proxy: new Ext.data.MemoryProxy([]),
		reader: new Ext.data.ArrayReader({},[
			{name: "field"},
			{name: "value"}
		])
	});

	var raid_confirm_grid = new Ext.grid.GridPanel({
		id: id,
		store: raid_confirm_store,
		columns: [
			{id:"field", header: "<{$gwords.field}>", dataIndex: "field", width: 200},
			{header: "<{$gwords.value}>", dataIndex: "value", width: 220}
		],
		title: "<{$rwords.raid_confirm}>",
		width: 535,
		autoHeight:true,
		loadMask:true,
		border:false
	});
	
	return raid_confirm_grid;
}

/* Render the form including the confirmed grid
 * Only for raid_create.tpl
 * @author: ellie_chien
 * 
 * @return: raid_confirm_form
 */
function renderRaidConfirmForm ()
{
	var raid_confirm_form = new Ext.FormPanel({
		frame: true,
		items: [
			renderRaidConfirmGrid("raid_confirm" + raid_suffix_id)
		]
	});
	
	return raid_confirm_form;
}

/* Render the final step form for raid creation wizard.
 * Only for raid_create.tpl
 * @author: ellie_chien
 * 
 * @return: finalForm
 */
function renderRaidFinalForm ()
{
	var finalForm = new Ext.Panel({
		id: "raid_final",
		frame: true,
		items:[{
			xtype: "label",
			style: "margin-top:20px;",
			html: "<h1><{$rwords.raid_finished_desc}></h1>" 
		}]
	});
	
	return finalForm;
}
/* Run the "Create Raid" wizard.
 * Only for raid.tpl & init.tpl
 * @author: ellie_chien
 * 
 * @param {Object} create_type: including "create" & "init" two types
 * @param {Object} is_submit: [Yes] to add a handler function (raidSubmitHandler) for submit button.
 * 	If @create_type is "create", is_submit is true.
 * 	If @create_type is "init", is_submit is false and go back to init wizard after clicking "submit" button
 * 
 * @return: none
 */
function runCreateRaidWizard (create_type, is_submit)
{
	raid_suffix_id = "_" + Ext.id();
	if (typeof button_click == "undefined") {
		button_click = "";
	} else {
		button_click = create_type;
	}
	
	raid_wizard = new Ext.smart.Wizard(raid_suffix_id);
	raid_disk_form = raid_disk_form?raid_disk_form:renderDiskForm();
	raid_level_form = raid_level_form?raid_level_form:renderRaidLevelForm();
	raid_property_form = raid_property_form?raid_property_form:renderRaidPropertyForm();
	raid_sys_form = raid_sys_form?raid_sys_form:renderRaidSysForm();
	raid_confirm_form = raid_confirm_form?raid_confirm_form:renderRaidConfirmForm();
	raid_final_form = raid_final_form?raid_final_form:renderRaidFinalForm();
	raid_wizard.addWizardItem("raid_list", "<{$rwords.disk_list}>", raid_disk_form, 0, "first", "<{$rwords.disk_step_desc}>");
	raid_wizard.addWizardItem("raid_level", "<{$rwords.level_step_title}>", raid_level_form, 1, "middle", "<{$rwords.level_step_desc}>");
	raid_wizard.addWizardItem("raid_property", "<{$rwords.raid_prop_setup}>", raid_property_form, 2, "middle", "<{$rwords.prop_step_desc}>");
	raid_wizard.addWizardItem("raid_sys", "<{$rwords.raid_sys_setup}>", raid_sys_form, 3, "middle", "<{$rwords.sys_step_desc}>");
	raid_wizard.addWizardItem("raid_confirm", "<{$rwords.raid_confirm}>", raid_confirm_form, 4, "submit", "<{$rwords.confirm_step_desc}>");
	raid_wizard.addWizardItem("raid_done", "<{$gwords.final}>", raid_final_form, 5, "final", "<{$rwords.final_step_desc}>");
	raid_wizard.mask_msg = "<{$gwords.wait_msg}>";
	raid_wizard.setTitle("<{$rwords.raid_wizard_title}>");
	raid_wizard.show();
	raid_wizard.setHeight(525);
	raid_wizard.setCenter();
	
//	if (Ext.getCmp("disk" + raid_suffix_id)) {
		Ext.getCmp("disk" + raid_suffix_id).load();
//	}

	raid_wizard.onStepActive = raidOnStepActive;
	raid_wizard.beforeStepActive = raidBeforeStepActive;
	raid_wizard.setDisabledBtn('N', true);
	if (is_submit) {
		raid_wizard.addBtnHandler('S', raidSubmitHandler);
		raid_wizard.btnClick = 'S';
	}
	raid_wizard.getWin().on("hide", function(e) {
		if (create_type == "create" && raid_store) {
			reload_flag=1;
			raid_store.load();
		} else if (create_type == "init") {
			Ext.getCmp("init_window" + init_suffix_id).setDisabled(false);
			init_wizard.setDisabledBtn('N', true);
			Ext.getCmp("raid_confirm" + init_suffix_id).show();
			if (raid_wizard.btnClick == "S") {
				Ext.getCmp("raid_confirm" + init_suffix_id).getStore().loadData(raidConfirmData);
				init_wizard.setDisabledBtn('N', false);
				Ext.getCmp("cancel_adv" + init_suffix_id).hide();
			} else {
				Ext.getCmp("raid_confirm" + init_suffix_id).getStore().loadData([]);
				Ext.getCmp("cancel_adv" + init_suffix_id).show();
			}
		}
		raid_wizard.resetWizard(true);
		destroyRaidWizard();
		raid_wizard = null;
	});
}

/* Handle something when the stpe is active.
 * Only for raid_create.tpl
 * @ahthor: ellie_chien
 * 
 * @param {Object} activeStep: active step name
 * 
 * @return: none
 */
function raidOnStepActive (activeStep)
{
	var max_tray = "<{$max_tray}>";
	if(max_tray == ''){
		max_tray = 0;
	}else{
		max_tray = parseInt(max_tray);
	}
	switch (activeStep) {
	case 'raid_list':
		break;
	case 'raid_level':
		if (Ext.getCmp("jbod" + raid_suffix_id).getValue() || Ext.getCmp("raid0" + raid_suffix_id).getValue() || Ext.getCmp("raid1" + raid_suffix_id).getValue() || 
		Ext.getCmp("raid5" + raid_suffix_id).getValue() || Ext.getCmp("raid6" + raid_suffix_id).getValue() || Ext.getCmp("raid10" + raid_suffix_id).getValue() || Ext.getCmp("raid50" + raid_suffix_id).getValue() || Ext.getCmp("raid60" + raid_suffix_id).getValue()) {
			var wizard = init_wizard || raid_wizard;
			wizard.setDisabledBtn('N', false);
		} else {
			var wizard = init_wizard || raid_wizard;
			wizard.setDisabledBtn('N', true);
		}
		if(max_tray <= 2){
			if (Ext.getCmp("raid5" + raid_suffix_id).isVisible()) {
				Ext.getCmp("raid5" + raid_suffix_id).hide();
			}
			if (Ext.getCmp("raid6" + raid_suffix_id).isVisible()) {
				Ext.getCmp("raid6" + raid_suffix_id).hide();
			}
			if (Ext.getCmp("raid10" + raid_suffix_id).isVisible()) {
				Ext.getCmp("raid10" + raid_suffix_id).hide();
			}
		}
		break;
	case 'raid_property':
		break;
	case 'raid_sys':
		break;
	case 'raid_confirm':
		break;
	default:	
		
	}
	
}

/* Parse parameter value for the confirmed data.
 * Only for raid_create.tpl & init.tpl (parseRaidParams function)
 * @author: ellie_chien
 * 
 * @param {Object} fieldId: field id
 * @param {Object} paramVal: the first param value
 * @param {Object} paramVal2: the second param value
 * 
 * @return: the parsed value
 */
function parseRaidParam (fieldId, paramVal, paramVal2)
{
    switch (fieldId) {
    case "disk_used":
        var html = '';
        var id = init_suffix_id || raid_suffix_id;
        var disks = Ext.getCmp("disk" + id);
        var allocate = disks.getAllocate();
        var used = [];
        for(tray in allocate.used) {
			var rs = allocate.used[tray];
			var loc = Number(rs.get('product_no'));
			var pos = rs.get('disk_no');
			tray = loc == 0 ? pos : 'J' + loc + '-' + pos;
            used.push(tray);
        }
        if( used.length > 0 ) {
            html += '<span style="font-weight:bold;">' + used + '</span>';
        }
        var spare = [];
        for(tray in allocate.spare) {
			var rs = allocate.spare[tray];
			var loc = Number(rs.get('product_no'));
			var pos = rs.get('disk_no');
			tray = loc == 0 ? pos : 'J' + loc + '-' + pos;
            spare.push(tray);
        }
        if( spare.length > 0 ) {
            html += '<span style="color:gray">,' + spare + '</span>';
        }
        
        return html;
	case "type":
		var typeData = {
			"J": "JBOD",
			"0": "RAID 0",
			"1": "RAID 1",
			"5": "RAID 5",
			"6": "RAID 6",
			"10": "RAID 10",
			"50": "RAID 50",
			"60": "RAID 60"
		};
		return typeData[paramVal];
	case "master":
	case "_assume_clean":
	case "_encrypt":
		if (paramVal == "on" || paramVal == 1) {
			return "<{$gwords.yes}>";
		} else {
			return "<{$gwords.no}>";
		}
	case "chunk":
		if (paramVal === undefined) {
			return "<{$gwords.disable}>";
		} else {
			return paramVal + " KB";
		}
	case "filesystem":
		var fsData = {
			"ext3": "<{$gwords.ext3}>",
			"zfs" : "<{$gwords.zfs}>",
			"xfs": "<{$gwords.xfs}>",
			"ext4": "<{$gwords.ext4}>",
			"btrfs": "<{$gwords.btrfs}>",
			"hv": "VE"
		};
		
		return fsData[paramVal];
	default:
	}
	
	return paramVal;
}

/* If raid_id is valid, let next step active after setraid.php checking.
 * Only for raid_create.tpl
 * @author: ellie_chien
 * 
 * @return: none
 */
function raidIdOk ()
{
	raid_wizard.setActiveStep("raid_sys");
}

/* Handle something before the step is active.
 * Only for raid_create.tpl
 * @author: ellie_chien
 * 
 * @param {Object} activeStep: the active step name
 * @param {Object} btn: the button type. If the active stpe is limit, disable the button
 * 
 * @return: true or false
 */
function raidBeforeStepActive (activeStep, btn)
{
	switch (activeStep) {
	case 'raid_level':
		break;
	case 'raid_property':
		break;
	case 'raid_sys':
		if (btn == 'N') {
			<{if $open_encrypt == 1}>
			if (Ext.getCmp("_encrypt" + raid_suffix_id).checked && Ext.getCmp("_encryptkey" + raid_suffix_id).getValue() != Ext.getCmp("_confirmkey" + raid_suffix_id).getValue()) {
				Ext.Msg.alert("<{$rwords.raid_config_title}>", "<{$rwords.warn_password_confirm}>");
				return false;
			}
			<{/if}>
			if (!raid_property_form.getForm().isValid()) {
				if (Ext.getCmp("raid_id" + raid_suffix_id).getValue().length > RAID_ID_MAX_LEN) {
					Ext.Msg.alert("<{$rwords.raid_config_title}>", "<{$rwords.raid_id_len_warn}>");
				}
				if (Ext.getCmp("_encryptkey" + raid_suffix_id).getValue().length > ENCRYPTKEY_MAX_LEN) {
					Ext.Msg.alert("<{$rwords.raid_config_title}>", "<{$rwords.encryptkey_len_warn}>");
				}
				return false;
			}
			processAjax("setmain.php?fun=setraid", onLoadRaid, "&action=checkid&raid_id=" + Ext.getCmp("raid_id" + raid_suffix_id).getValue(), false);
			return false;
		}
		break;
	case 'raid_confirm':
		var raid_wizard_params = raid_wizard.getValues();
		if (!raid_wizard_params) {
			Ext.Msg.alert("<{$rwords.raid_config_title}>", "<{$gwords.sys_error}>");
			return false;
		}

		raidConfirmData = [
			["<{$rwords.disk_list}>", parseRaidParam("disk_used", raid_wizard_params["inraid[]"], raid_wizard_params["spare[]"])],
			["<{$rwords.raidlevel}>", parseRaidParam("type", raid_wizard_params.type)],
			["<{$gwords.raid_id}>", raid_wizard_params.raid_id],
			["<{$rwords.assume_clean}>", parseRaidParam("_assume_clean", raid_wizard_params._assume_clean)],
			["<{$rwords.chunksize}>", parseRaidParam("chunk", raid_wizard_params.chunk)],
			["<{$rwords.filesystem}>", parseRaidParam("filesystem", raid_wizard_params.filesystem)]
			<{if $NAS_DB_KEY=="1"}>,["<{$rwords.datapercent}>", raid_wizard_params.data_percent]<{/if}>
		];
		
		//if( file_system_store.totalLength > 1 ) {
			raidConfirmData.push(
				["<{$rwords.master_raid}>", parseRaidParam("master", raid_wizard_params.master)]
				<{if $open_encrypt == 1}>
				,["<{$rwords.encrypt}>", parseRaidParam("_encrypt", raid_wizard_params._encrypt)]
				<{/if}>
			);
		//}
		
		Ext.getCmp("raid_confirm" + raid_suffix_id).getStore().loadData(raidConfirmData);
		break;
	default:	
		
	}
	return true;
}

function onLoadRaid()
{
	raid_wizard.mask.hide();
	if(this.req.responseText == 'logout') {
		location.href = '/index.php';
	}
	
	var request = eval('('+this.req.responseText+')');

	if (!request) return;
	if (!request.show) {
		if (!request.fn  || request.fn === "") {
			return;
		}
		eval(request.fn);
		return;
	};

	mag_box(request.topic,request.message,request.icon,request.button,request.fn,request.prompt);
}

/* Submit handler function.
 * Only for raid_create.tpl
 * @author: ellie_chien
 * 
 * @return: none
 */
function raidSubmitHandler ()
{
    Ext.Msg.confirm("<{$rwords.raid_config_title}>","<{$rwords.create_confirm}>",function(btn){
        if(btn=="yes"){
            raidlock=1;
            raid_wizard.mask.show();
            var url = '<{$form_action}>' || 'setmain.php?fun=setraid';
            
            var disks = Ext.getCmp("disk" + raid_suffix_id);
            var allocate = disks.getAllocate();
            var inraid = [];
            for(tray in allocate.used) {
                inraid.push('inraid[]=' + tray);
            }
            inraid = '&' + inraid.join('&');
            
            var spare = [];
            for(tray in allocate.spare) {
                spare.push('spare[]=' + tray);
            }
            spare = '&' + spare.join('&');
            var param = raid_wizard.getValues(true).replace(/disk_ext[^=]*=on&/, '');
            
            processAjax(url,onLoadRaid,"&action=create&"+param+inraid+spare, false);
        }
    });
}

/* The final step function.
 * Only for raid_create.tpl
 * @author: ellie_chien
 * 
 * @return: none
 */
function raidWizardFinal()
{
	raid_wizard.mask.hide();
	raid_wizard.setActiveStep("raid_done");
	if(raid_ct.create_raid){
		raid_ct.create_raid.setDisabled(true);
	}
	if(raid_ct.edit_raid){
		raid_ct.edit_raid.setDisabled(true);
	}
	if(raid_ct.recover){
		raid_ct.recover.setDisabled(true);
	}
}

/* Destroy every wizard's element when the wizard is hide.
 * Only for raid_create.tpl
 * @author: ellie_chien
 * 
 * @return: none
 */
function destroyRaidWizard()
{
	raid_disk_used_count = 0;
	raid_disk_spare_count = 0;
	raid_suffix_id = "";
	raidConfirmData = "";

	if (raid_disk_form) {
		raid_disk_form.items.each(function(item, index, maxLength){
			item.destroy();
		});
		raid_disk_form.destroy();
		raid_disk_form = null;
	}
	if (raid_level_form) {
		raid_level_form.items.get(0).items.each(function(item, index, maxLength){
            item.destroy();
        });
		raid_level_form.destroy();
		raid_level_form = null;
	}
	
	if (raid_property_form) {
		raid_property_form.items.each(function(item, index, maxLength){
			item.destroy();
		});
		raid_property_form.destroy();
		raid_property_form = null;
		
	}
	if (raid_sys_form) {
		raid_sys_form.items.each(function(item, index, maxLength){
			item.destroy();
		});
		raid_sys_form.destroy();
		raid_sys_form = null;
	}
	if (raid_confirm_form) {
		raid_confirm_form.items.each(function(item, index, maxLength){
			item.destroy();
		});
		raid_confirm_form.destroy();
		raid_confirm_form = null;
	}
	if (raid_final_form) {
		raid_final_form.items.each(function(item, index, maxLength){
			item.destroy();
		});
		raid_final_form.destroy();
		raid_final_form = null;
	}
}
