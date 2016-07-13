<{include file="adm/raid_create.tpl"}>

var USER_PWD_MIN_LEN = 4;
var USER_PWD_MAX_LEN = 16;
var USERNAME_MAX_LEN = 64;
var init_suffix_id = "";
var init_wizard = null;
var init_notif_form = null;
var init_raid_form = null;
var init_user_form = null;
var init_confirm_form = null;
var init_final_form = null;
var init_disk_load = false;
var init_disk_used_count = 0;
var init_disk_spare_count = 0;
var init_user_checked = false;
var button_click = "";

/* Run the "Initialization" wizard
 * @author: ellie_chien
 * 
 * @return: none
 */
function runInitWizard()
{
	init_suffix_id = "_" + Ext.id();
	
	init_wizard = new Ext.smart.Wizard(init_suffix_id,false);
	init_notif_form = init_notif_form?init_notif_form:renderNotifForm();
	init_raid_form = init_raid_form?init_raid_form:renderRaidForm();
	init_user_form = init_user_form?init_user_form:renderUserForm();
	init_confirm_form = init_confirm_form?init_confirm_form:renderInitConfirmForm();
	init_final_form = init_final_form?init_final_form:renderFinalForm();
	init_wizard.addWizardItem("notif", "<{$init_words.notif_step_title}>", init_notif_form, 0, "first", "<{$init_words.notif_step_desc}>");
	init_wizard.addWizardItem("raid", "<{$init_words.raid_step_title}>", init_raid_form, 1, "middle", "<{$init_words.raid_step_desc}>");
	init_wizard.addWizardItem("user", "<{$init_words.user_step_title}>", init_user_form, 2, "middle", "<{$init_words.user_step_desc}>");
	init_wizard.addWizardItem("confirm", "<{$init_words.confirm_step_title}>", init_confirm_form, 3, "submit", "<{$init_words.confirm_step_desc}>");
	init_wizard.addWizardItem("final", "<{$init_words.final_step_title}>", init_final_form, 4, "final", "<{$init_words.final_step_desc}>");
	init_wizard.mask_msg = "<{$gwords.wait_msg}>";
	init_wizard.setTitle("<{$words.init_wizard_title}>");
	init_wizard.onStepActive = initOnStepActive;
	init_wizard.beforeStepActive = initBeforeStepActive;
	init_wizard.addBtnHandler('S', initSubmitHandler);
	init_wizard.addBtnHandler('C', initCancelHandler);
	init_wizard.setTitle("<{$init_words.init_wizard_title}>");
	init_wizard.show();

	init_wizard.getWin().on("hide", function(e) {
		init_wizard.resetWizard(true);
		destroyInitWizard();
		init_wizard = null;
	});
}

/* Render the notification form.
 * @author: ellie_chien
 * 
 * @return: init_notif_form
 */
function renderNotifForm()
{
	var auth_store = new Ext.data.SimpleStore({
		fields: ['value', 'display'],
		data: [
			['on','on'],
			['plain','plain'],
			['cram-md5','cram-md5'],
			['login','login'],
			['gmail','gmail'],
			['off','off']]
	});

	var init_notif_form = new Ext.FormPanel({
		frame: true,
		labelWidth: 180,
		items:[
		{
			fieldLabel: "<{$notif_words.email_alert_notification}>",
			xtype: "radiogroup",
			layout: "form",
			width: 300,
			height: 40,
			listeners: {
				change:{
					fn:function(radio,checked){
						if (checked == 1) {
							Ext.getCmp("_smtp" + init_suffix_id).setDisabled(false);
							Ext.getCmp("_smtport" + init_suffix_id).setDisabled(false);
							Ext.getCmp("_auth_selected" + init_suffix_id).setDisabled(false);
							Ext.getCmp("_account" + init_suffix_id).setDisabled(false);
							Ext.getCmp("_password" + init_suffix_id).setDisabled(false);
							Ext.getCmp("_from" + init_suffix_id).setDisabled(false);
							Ext.getCmp("_addr1" + init_suffix_id).setDisabled(false);
						} else {
							init_notif_form.getForm().clearInvalid();
							Ext.getCmp("_smtp" + init_suffix_id).setDisabled(true);
							Ext.getCmp("_smtport" + init_suffix_id).setDisabled(true);
							Ext.getCmp("_auth_selected" + init_suffix_id).setDisabled(true);
							Ext.getCmp("_account" + init_suffix_id).setDisabled(true);
							Ext.getCmp("_password" + init_suffix_id).setDisabled(true);
							Ext.getCmp("_from" + init_suffix_id).setDisabled(true);
							Ext.getCmp("_addr1" + init_suffix_id).setDisabled(true);
						}
					}
				}
			},
			items: [
			{
				boxLabel: "<{$gwords.enable}>",
				name: "_mail",
				inputValue: 1
			},{
				boxLabel: "<{$gwords.disable}>",
				name: "_mail",
				inputValue: 0,
				checked: true
			}]
		},{	
			xtype: "textfield",
			fieldLabel: "<{$notif_words.email_hostname}>",
			width: 150,
			id: "_smtp" + init_suffix_id,
			name: "_smtp",
			allowBlank: false,
			maskRe: /^[0-9a-zA-Z_\.\/:\-]*$/,
			regex: /[0-9a-zA-Z_\.\/:\-]*$/
		},{
			xtype: "numberfield",
			fieldLabel: "<{$gwords.port}>",
			width: 50,
			id: "_smtport" + init_suffix_id,
			name: "_smtport",
			allowBlank: false
		},{
			xtype: "combo",
			store: auth_store,
			fieldLabel: "<{$notif_words.email_auth}>",
			valueField: "value",
			displayField:"display",
			mode: "local",
			forceSelection: true,
			editable: false,
			triggerAction: "all",
			id: "_auth_selected" + init_suffix_id,
			name: "_auth_selected",
			hiddenName: "_auth_selected",
			width: 80,
			value: "off",
			listWidth: 80,
			listeners:{
				select:{
					fn: function (combo, rec, idx) {
						if (rec.data.value == "gmail") {
							Ext.getCmp("_smtport" + init_suffix_id).setValue(587);
						} else if (Ext.getCmp("_smtport" + init_suffix_id).getValue() == 587) {
							Ext.getCmp("_smtport" + init_suffix_id).reset();
						}
					}
				}
			}
		},{
			xtype: "textfield",
			fieldLabel: "<{$notif_words.email_account}>",
			width: 150,
			id: "_account" + init_suffix_id,
			name: "_account",
			disabled: true,
			maxLength: 32
		},{
			xtype: "textfield",
			fieldLabel: "<{$notif_words.email_password}>",
			width: 150,
			id: "_password" + init_suffix_id,
			name: "_password",
			inputType: "password",
			disabled: true,
			minLength: 4,
			maxLength: 32
		},{
			xtype: "textfield",
			fieldLabel: "<{$notif_words.email_from}>",
			width: 300,
			id: "_from" + init_suffix_id,
			name: "_from",
			maskRe: /^[0-9a-zA-Z_\.\-@]*$/,
			regex: /([a-zA-Z0-9_-])+@([a-zA-Z0-9_-])+(\.[a-zA-Z0-9_-])+/,
			maxLength: 128
		},{
			xtype: "textfield",
			fieldLabel: "<{$notif_words.email_addr}>",
			width: 300,
			id: "_addr1" + init_suffix_id,
			allowBlank: false,
			name: "_addr1",
			maskRe: /^[0-9a-zA-Z_\.\-@]*$/,
			regex: /([a-zA-Z0-9_-])+@([a-zA-Z0-9_-])+(\.[a-zA-Z0-9_-])+/,
			maxLength: 128
		},{
			xtype: "label",
			html: "<br><br><span class=wizard-desc-head><{$gwords.description}>:</span><br><span class=wizard-desc><{$init_words.notif_desc}></span>"
		}]
	});
	Ext.getCmp("_smtp" + init_suffix_id).setDisabled(true);
	Ext.getCmp("_smtport" + init_suffix_id).setDisabled(true);
	Ext.getCmp("_auth_selected" + init_suffix_id).setDisabled(true);
	Ext.getCmp("_account" + init_suffix_id).setDisabled(true);
	Ext.getCmp("_password" + init_suffix_id).setDisabled(true);
	Ext.getCmp("_from" + init_suffix_id).setDisabled(true);
	Ext.getCmp("_addr1" + init_suffix_id).setDisabled(true);	
	
	return init_notif_form;
}

/* Embed checkbox (used disk) into grid panel which is used by renderRaidForm().
 * @author: ellie_chien
 * 
 * @param {Object} value: the grid cell value
 * @param {Object} metaData: the grid cell data information
 * @param {Object} record: the record in the index line
 * @param {Object} rowIndex: row index
 * @param {Object} colIndex: column index
 * @param {Object} store: data store
 * 
 * @return: html(string)
 */
function renderInitUsedDisk(value, metaData, record, rowIndex, colIndex, store)
{
	var used=record.data['disk_no'] - 1;
	var disable = "";
	var check = "";
	var html = "";

	if(record.data['used']==1){
		check="checked";
		disable="disabled";
	}else if(record.data['spare'] == 1 || record.data['disk_capacity'] == "N/A"){
		disable="disabled";
	}

	html="<input type='checkbox' id='inraid"+used+init_suffix_id+"' name='inraid[]' value='"+used+"' onclick='checkInitDiskCount("+used+",\"raid\")' "+disable+" "+check+">";
	return html;
}

/* Embed checkbox (spared disk) into grid panel which is used by renderRaidForm().
 * Only for raid_create.tpl
 * @author: ellie_chien
 * 
 * @param {Object} value: the grid cell value
 * @param {Object} metaData: the grid cell data information
 * @param {Object} record: the record in the index line
 * @param {Object} rowIndex: row index
 * @param {Object} colIndex: column index
 * @param {Object} store: data store
 * 
 * @return: html(string)
*/
function renderInitSpareDisk(value, metaData, record, rowIndex, colIndex, store)
{
	var spare=record.data['disk_no'] - 1;
	var disable = "";
	var check = "";
	var html = "";

	if(record.data['spare']==1){
		check="checked";
		disable="disabled";
	}else if(record.data['used'] == 1 || record.data['disk_capacity'] == "N/A"){
		disable="disabled";
	}

	html="<input type='checkbox' id='spare"+spare+init_suffix_id+"' name='spare[]' value='"+spare+"' onclick='checkInitDiskCount("+spare+",\"spare\")' "+disable+" "+check+">";
	return html;
}

function updateRaidParam ()
{
	var paramObj = {};
	if (init_disk_used_count >= 4) {
		paramObj.type = "6";
		paramObj._assume_clean = "1";
		paramObj.chunk = "64";
		paramObj.raid_id ="RAID";
		paramObj.filesystem = "ext4";
		paramObj.data_percent = <{if $NAS_DB_KEY == 1}>"95"<{else}>"100"<{/if}>;
	} else if (init_disk_used_count == 3) {
		paramObj.type = "5";
		paramObj._assume_clean = "1";
		paramObj.chunk = "64";
		paramObj.raid_id ="RAID";
		paramObj.filesystem = "ext4";
		paramObj.data_percent = <{if $NAS_DB_KEY == 1}>"95"<{else}>"100"<{/if}>;
	} else if (init_disk_used_count == 2) {
		paramObj.type = "1";
		paramObj._assume_clean = "1";
		paramObj.raid_id ="RAID";
		paramObj.filesystem = "ext4";
		paramObj.data_percent = <{if $NAS_DB_KEY == 1}>"95"<{else}>"100"<{/if}>;
	} else if (init_disk_used_count > 0 && init_disk_spare_count === 0) {
		paramObj.type = "J";
		paramObj.chunk = "64";
		paramObj.raid_id ="RAID";
		paramObj.filesystem = "ext4";
		paramObj.data_percent = <{if $NAS_DB_KEY == 1}>"95"<{else}>"100"<{/if}>;
	} else {
		paramObj.empty = true;
	}

	return paramObj;
}

/* Show raid description according to init_disk_used_count & init_disk_spare_count in the step of "Create Raid".
 * @author: ellie_chien
 * 
 * 
 */
function showRaidDesc ()
{
	if( init_suffix_id == '' ) {
	    return;
	}
	var raid_params = updateRaidParam();
	if (typeof raid_params.empty !== undefined && raid_params.empty) {
		if (init_disk_used_count <= 0 & init_disk_spare_count <= 0) {
			Ext.getCmp("raid_desc" + init_suffix_id).show();
			Ext.getCmp("raid_desc_detail" + init_suffix_id).hide();
		} else {
			if (Ext.getCmp("raid_desc" + init_suffix_id).isVisible()) {
				Ext.getCmp("raid_desc" + init_suffix_id).hide();
			}
			Ext.getCmp("raid_level" + init_suffix_id).getEl().dom.innerHTML = "<br><{$rwords.raidlevel}>: <span style='color:red;'><{$gwords.none}></span>";
			Ext.getCmp("_assume_clean" + init_suffix_id).getEl().dom.innerHTML = "<{$rwords.assume_clean}>: <{$gwords.no}>";
			Ext.getCmp("chunk" + init_suffix_id).getEl().dom.innerHTML = "<{$rwords.chunksize}>: <{$gwords.none}>";
			Ext.getCmp("raid_id" + init_suffix_id).getEl().dom.innerHTML = "<{$gwords.raid_id}>: <{$gwords.none}>";
			Ext.getCmp("filesystem" + init_suffix_id).getEl().dom.innerHTML = "<{$rwords.filesystem}>: <{$gwords.none}>";
			Ext.getCmp("data_percent" + init_suffix_id).getEl().dom.innerHTML = "<{$rwords.datapercent}>: <{$gwords.none}>";
			if (!Ext.getCmp("raid_desc_detail" + init_suffix_id).isVisible()) {
				Ext.getCmp("raid_desc_detail" + init_suffix_id).show();
			}
		}
		return;
	}
	
	Ext.getCmp("raid_level" + init_suffix_id).getEl().dom.innerHTML = "<br><{$rwords.raidlevel}>: " + parseRaidParam("type", raid_params.type);
	Ext.getCmp("_assume_clean" + init_suffix_id).getEl().dom.innerHTML = "<{$rwords.assume_clean}>: " + parseRaidParam("_assume_clean", raid_params._assume_clean);
	Ext.getCmp("chunk" + init_suffix_id).getEl().dom.innerHTML = "<{$rwords.chunksize}>: " + parseRaidParam("chunk", raid_params.chunk);
	Ext.getCmp("raid_id" + init_suffix_id).getEl().dom.innerHTML = "<{$gwords.raid_id}>: RAID";
	Ext.getCmp("filesystem" + init_suffix_id).getEl().dom.innerHTML = "<{$rwords.filesystem}>: " + parseRaidParam("filesystem", raid_params.filesystem);
	Ext.getCmp("data_percent" + init_suffix_id).getEl().dom.innerHTML = "<{$rwords.datapercent}>: " + raid_params.data_percent + "%";

	if (Ext.getCmp("raid_desc" + init_suffix_id).isVisible()) {
		Ext.getCmp("raid_desc" + init_suffix_id).hide();
	}
	if (!Ext.getCmp("raid_desc_detail" + init_suffix_id).isVisible()) {
		Ext.getCmp("raid_desc_detail" + init_suffix_id).show();
	}
}

/* Calculate the used and spare disk number.
 * If the checkbox has been checked and then count plus 1.
 * Otherwise count minus 1.
 * Used by renderInitUsedDisk() & renderInitSpareDisk().
 * @author: ellie_chien
 * 
 * @param {Object} disk_index: disk number
 * @param {Object} disk_type: to express the item is a used disk or a spare disk
 * 
 * @return: none
 */
function checkInitDiskCount(allocate)
{
    init_disk_used_count = 0;
    for( var used in allocate.used ) {
        init_disk_used_count++;
    }
    
    init_disk_spare_count = 0;
    for( var spare in allocate.spare ) {
        init_disk_spare_count++;
    }
    /*
	if(disk_type=="raid"){
		if (Ext.getDom("inraid" + disk_index + init_suffix_id).checked) {
			init_disk_used_count++;
		} else {
			init_disk_used_count--;
		}
		if (Ext.getDom("spare"+disk_index + init_suffix_id).checked) {
			Ext.getDom("spare"+disk_index + init_suffix_id).checked = false;
			init_disk_spare_count--;
		}
	}else{
		if (Ext.getDom("spare" + disk_index + init_suffix_id).checked) {
			init_disk_spare_count++;
		} else {
			init_disk_spare_count--;
		}
		if (Ext.getDom("inraid" + disk_index + init_suffix_id).checked) {
			Ext.getDom("inraid" + disk_index + init_suffix_id).checked = false;
			init_disk_used_count--;
		}
	}
*/	
	showRaidDesc();
}

/* Render the raid form.
 * @author: ellie_chien
 * 
 * @return: init_raid_form
 */
function renderRaidForm()
{
	var diskgrid = renderDiskGrid("disk" + init_suffix_id, renderInitUsedDisk, renderInitSpareDisk);
	var raid_confirm_grid = null;
	var init_raid_form = new Ext.FormPanel({
		frame: true,
		hideLabel: false,
		labelWidth: 50,
		autoHeight:true,
		items:[
		diskgrid,
		{
			xtype: "label",
			id: "raid_desc" + init_suffix_id,
			html:"<br><br><span class=wizard-desc-head><{$gwords.description}>:</span><br><span class=wizard-desc><br><{$init_words.raid_desc}><br></span>"
		},{
			xtype: "panel",
			id: "raid_desc_detail" + init_suffix_id,
			items:[{
				xtype: "box",
				id: "raid_level" + init_suffix_id,
				autoEl: {
					html: "<{$rwords.raidlevel}>:"
				},
				cls: "wizard-dynamic-desc"
			},{
				xtype: "box",
				id: "raid_id" + init_suffix_id,
				autoEl: {
					html: "<{$gwords.raid_id}>: RAID"
				},
				cls: "wizard-dynamic-desc"
			},{
				xtype: "box",
				id: "_encrypt" + init_suffix_id,
				autoEl: {
					html: "<{$rwords.encrypt}>: <{$gwords.no}>"
				},
				cls: "wizard-dynamic-desc"
			},{
				xtype: "box",
				id: "_assume_clean" + init_suffix_id,
				autoEl: {
					html: "<{$rwords.assume_clean}>: <{$gwords.no}>"
				},
				cls: "wizard-dynamic-desc"
			},{
				xtype: "box",
				id: "chunk" + init_suffix_id,
				autoEl: {
					html: "<{$rwords.chunksize}>: 64 KB"
				},
				cls: "wizard-dynamic-desc"
			},{
				xtype: "box",
				id: "filesystem" + init_suffix_id,
				autoEl: {
					html: "<{$rwords.filesystem}>: <{$gwords.ext4}>"
				},
				cls: "wizard-dynamic-desc"
			},{
				xtype: "box",
				id: "data_percent" + init_suffix_id,
				autoEl: {
					html: "<{$rwords.datapercent}>: " + <{if $NAS_DB_KEY == 1}>"95%"<{else}>"100%"<{/if}>
				},
				cls: "wizard-dynamic-desc"
			}]
		}]
	});
	
	Ext.getCmp("raid_desc_detail" + init_suffix_id).hide();
	
	return init_raid_form;
}

/* Render the local user form.
 * @author: ellie_chien
 * 
 * @return: init_user_form
 */
function renderUserForm()
{
	var init_user_form = new Ext.FormPanel({
		frame: true,
		labelWidth: 180,
		items:[
		{
			xtype: "textfield",
			fieldLabel: "<{$user_words.username}>",
			id: "username" + init_suffix_id,
			name: "username",
			width: 150,
			maxLength: USERNAME_MAX_LEN,
			maskRe: /^[^\/\ :;<=>?@\[\]\\\|*\+\,\"]$/,
			regex: /[^\/\ :;<=>?@\[\]\\\|*\+\,\"]$/,
			regexText: "<{$init_words.username_err}>"
		},{
			xtype: "textfield",
			inputType: "password",
			fieldLabel: "<{$gwords.password}>",
			id: "user_pwd" + init_suffix_id,
			name: "user_pwd",
			width: 150,
			minLength: USER_PWD_MIN_LEN,
			maxLength: USER_PWD_MAX_LEN
		},{
			xtype: "textfield",
			inputType: "password",
			fieldLabel: "<{$gwords.pwd_confirm}>",
			id: "user_confirm_pwd" + init_suffix_id,
			name: "user_confirm_pwd",
			width: 150,
			minLength: USER_PWD_MIN_LEN,
			maxLength: USER_PWD_MAX_LEN
		},{
			xtype: "label",
			html: "<br><br><span class=wizard-desc-head><{$gwords.description}>:</span><br><span class=wizard-desc><{$init_words.user_desc}></span>"
		}]
	});
	
	return init_user_form;
}

/* Render the confirm form.
 * @author: ellie_chien
 * 
 * @return: init_confirm_form
 */
function renderInitConfirmForm()
{
	var init_confirm_store = new Ext.data.Store({
		proxy: new Ext.data.MemoryProxy([]),
		reader: new Ext.data.ArrayReader({},[
			{name: "function"},
			{name: "field"},
			{name: "value"}
		])
	});
	
	var init_confirm_grid = new Ext.grid.GridPanel({
		id: "init_confirm" + init_suffix_id,
		store: init_confirm_store,
		columns: [
			{id:"function", header: "Function", dataIndex: "function", width: 150},
			{header: "Field", dataIndex: "field", width: 170},
			{header: "Value", dataIndex: "value", width: 170}
		],
		title: "<{$init_words.confirm_step_title}>",
		width: 535,
		autoHeight:true,
		loadMask:true,
		border:false
	});
	
	var init_confirm_form = new Ext.FormPanel({
		frame: true,
		items: [
			init_confirm_grid
		]
	});
	
	return init_confirm_form;
}

/* Render the final step form.
 * @author: ellie_chien
 * 
 * @return: ellie_chien
 */
function renderFinalForm ()
{
	var finalForm = new Ext.Panel({
		id: "init_final",
		frame: true,
		items:[{
			xtype: "label",
			style: "margin-top:20px;",
			html: "<h1><{$init_words.final_desc}></h1>"
		}]
	});
	
	return finalForm;
}

/* Handle something when the stpe is active.
 * @ahthor: ellie_chien
 * 
 * @param {Object} activeStep: active step name
 * 
 * @return: none
 */
function initOnStepActive(activeStep)
{
	switch (activeStep) {
	case "raid":
		if (init_disk_load) {
			return;
		}
		init_wizard.setDisabledBtn('N', true);
		/*
		Ext.getCmp("disk" + init_suffix_id).getStore().load();
		Ext.getCmp("disk" + init_suffix_id).getStore().on("load", function () {
			init_wizard.setDisabledBtn('N', false);
		});
		*/
		Ext.getCmp("disk" + init_suffix_id).load();
		init_disk_load = true;
		break;
	default:
		
	}
}

/* Parse each field value of notification form
 * @author: ellie_chien
 * @param {Object} params: all of the wizard parameters
 * 
 * @return: an array including each value of notification fields
 */
function parseNotifParams (params)
{
	if (params._mail == 0) {
		return [["<{$init_words.notif_step_title}>", "<{$notif_words.email_alert_notification}>", "<{$gwords.disable}>"]];
	}
	
	return [
		["<{$init_words.notif_step_title}>", "<{$notif_words.email_alert_notification}>", "<{$gwords.enable}>"],
		["", "<{$notif_words.email_hostname}>", params._smtp],
		["", "<{$gwords.port}>", params._smtport],
		["", "<{$notif_words.email_auth}>", params._auth_selected],
		["", "<{$notif_words.email_account}>", params._account],
		["", "<{$notif_words.email_from}>", params._from],
		["", "<{$notif_words.email_addr}>", params._addr1]
	];	
}

/* Parse each field value of raid form
 * @author: ellie_chien
 * @param {Object} params: all of the wizard parameters
 * 
 * @return: an array including each value of raid fields
 */
function parseRaidParams (params)
{
	if (typeof params.empty !== undefined && params.empty) {
		return [["<{$init_words.raid_step_title}>", "<{$rwords.Raid_disk_used}>", "<{$gwords.none}>"]];
	}
	
	var disk_list = parseRaidParam("disk_used", params["inraid[]"], params["spare[]"]);
	return [
		["<{$init_words.raid_step_title}>", "<{$rwords.disk_list}>", disk_list],
		["", "<{$rwords.raidlevel}>", parseRaidParam("type", params.type)],
		["", "<{$gwords.raid_id}>", params.raid_id],
		["", "<{$rwords.filesystem}>", parseRaidParam("filesystem", params.filesystem)],
		["", "<{$rwords.datapercent}>", params.data_percent + "%"]
	];
}

/* Parse each field value of user form
 * @author: ellie_chien
 * @param {Object} params: all of the wizard parameters
 * 
 * @return: an array including each value of user fields
 */
function parseUserParams (params)
{
	return [["<{$init_words.user_step_title}>", "<{$user_words.username}>", (params.username === "")?"<{$gwords.none}>":params.username]];
}

/* Handle something before the step is active.
 * @author: ellie_chien
 * 
 * @param {Object} activeStep: the active step name
 * @param {Object} btn: the button type. If the active stpe is limit, disable the button
 * 
 * @return: true or false
 */
function initBeforeStepActive(activeStep, btn)
{
	var sys_user_arr = ['root','ftp','admin','sshd','nobody'];

	switch (activeStep) {
	case "notif":
		break;
	case "raid":
		if (btn == 'N') {
			if (!init_notif_form.getForm().isValid()) {
				Ext.Msg.alert("<{$init_words.init_wizard_title}>", "<{$gwords.field_invalid}>");
				return false;
			}
		}
		break;
	case "user":
		if (btn == 'N') {
			if (init_disk_used_count <= 0 || (init_disk_used_count == 1 && init_disk_spare_count > 0)) {
				Ext.Msg.confirm("<{$rwords.init_wizard_title}>","<{$init_words.no_raid_create_warn}>",function(btn){
					if(btn=="yes"){
						init_wizard.setActiveStep("confirm");
					}
				});
				return false;
			}
		} else if (btn == 'P' ) {
			if (init_disk_used_count <= 0 || (init_disk_used_count == 1 && init_disk_spare_count > 0)) {
				init_wizard.setActiveStep("raid");
				return false;
			}
		}
		break;
	case "confirm":
		var params = init_wizard.getValues();
		if (!params) {
			Ext.Msg.alert("<{$init_words.init_wizard_title}>", "<{$gwords.sys_error}>");
			return false;
		}
		Ext.apply(params, updateRaidParam());
		var init_data = parseNotifParams(params);
		init_data = init_data.concat(parseRaidParams(params));
		init_data = init_data.concat(parseUserParams(params));
		
		// If no user is added, show warning message and then go forward to the confirm step
		if (btn == 'N' && init_wizard.getActiveStep() == "user") {
			if (params.username === "") {
				// init data has been checked, return true immediately
				if (init_user_checked) {
					init_user_checked = false;
					Ext.getCmp("init_confirm" + init_suffix_id).getStore().loadData(init_data);
					return true;
				}
				Ext.Msg.confirm("<{$words.init_wizard_title}>","<{$init_words.no_user_add_warn}>",function(btn){
					if (btn=="yes"){
						init_user_checked = true;
						init_wizard.setActiveStep("confirm");
					} else {
						init_user_checked = false;
					}
				});
				return false;
			}
			// check username and password are valid
			for (var i = 0; i < sys_user_arr.length; i++) {
				if (params.username == sys_user_arr[i]) {
					Ext.Msg.alert("<{$init_words.init_wizard_title}>", "<{$user_words.user_error}>");
					return false;
				}
			}
			if (params.username.length > USERNAME_MAX_LEN) {
				Ext.Msg.alert("<{$init_words.init_wizard_title}>", "<{$user_words.username_len_warn}>");
				return false;
			}
			if (params.user_pwd != params.user_confirm_pwd || !singleByteCheck(params.user_pwd) ||
				params.user_pwd.length === 0 || params.user_confirm_pwd === 0) {
				Ext.Msg.alert("<{$init_words.init_wizard_title}>", "<{$user_words.pwd_error}>");
				return false;
			}
			if (params.user_pwd.length < USER_PWD_MIN_LEN || params.user_pwd.length > USER_PWD_MAX_LEN) {
				Ext.Msg.alert("<{$init_words.init_wizard_title}>", "<{$init_words.user_pwd_len_warn}>");
				return false;
			}

			if (!init_user_form.getForm().isValid()) {
				Ext.Msg.alert("<{$init_words.init_wizard_title}>", "<{$gwords.field_invalid}>");
				return false;
			}
		}
		
		Ext.getCmp("init_confirm" + init_suffix_id).getStore().loadData(init_data);
	default:
	}
	
	return true;
}

/* Destroy every wizard's element when the wizard is hide.
 * @author: ellie_chien
 * 
 * @return: none
 */
function destroyInitWizard()
{
	init_suffix_id = "";
	init_disk_load = false;
	init_disk_used_count = 0;
	init_disk_spare_count = 0;
	init_user_checked = false;
	fun_idx = 0;
	
	if (init_notif_form) {
		init_notif_form.items.each(function(item, index, maxLength){
			item.destroy();
		});
		init_notif_form.destroy();
		init_notif_form = null;
		
	}
	if (init_raid_form) {
		init_raid_form.items.each(function(item, index, maxLength){
			item.destroy();
		});
		init_raid_form.destroy();
		init_raid_form = null;
	}
	if (init_user_form) {
		init_user_form.items.each(function(item, index, maxLength){
			item.destroy();
		});
		init_user_form.destroy();
		init_user_form = null;
	}
	if (init_confirm_form) {
		init_confirm_form.items.each(function(item, index, maxLength){
			item.destroy();
		});
		init_confirm_form.destroy();
		init_confirm_form = null;
	}
	if (init_final_form) {
		init_final_form.items.each(function(item, index, maxLength){
			item.destroy();
		});
		init_final_form.destroy();
		init_final_form = null;
	}
}

var fun_arr = ["chkinit", "setnotif", "setinit", "setraid", "none"];
var fun_idx = 0;
/* For processAjax function.
 * @author: ellie_chien
 * 
 * @return: none
 */
function onLoadInit ()
{
	if (this.req) {
		if (this.req.responseText=='logout') {
			location.href='/index.php';
		}
		var request = eval('('+this.req.responseText+')'); 
	
		if (request && request.message !== "") {
			Ext.Msg.alert("<{$init_words.init_wizard_title}>", request.message, function (btn) {
				if (btn == 'ok') {
					init_wizard.mask.hide();
					fun_idx = 0;
				}
			});
			return;
		}
	}
	var ret = initSubmitHandler2(fun_arr[fun_idx]);
	fun_idx++;
	if (ret == 0) {
		this.req = null;
		onLoadInit();
	}
}

/* Submit handler function.
 * @author: ellie_chien
 * 
 * @return: none
 */
function initSubmitHandler()
{
	init_wizard.mask.show();
	onLoadInit();
}

/* Send request according to different @param fun.
 * @author: ellie_chien
 * 
 * @param {Object} fun: the parameter for setmain.php
 * 
 * @return
 * 		0: no calling processAjax
 * 		1: calling processAjax
 */
function initSubmitHandler2(fun)
{
	switch (fun) {
	case "chkinit":
		processAjax("setmain.php?fun=setinit",onLoadInit, "&action=chkinit", false);
		break;
	case "setnotif":
		if (init_notif_form.getForm().getValues()._mail == 0) {
			return 0;
		}
		processAjax("setmain.php?fun=setnotif",onLoadInit,"&action=init&_beep=1&"+init_notif_form.getForm().getValues(true), false);
		break;
	case "setraid":
		var raid_params = updateRaidParam();
		if (typeof raid_params.empty != "undefined" && raid_params.empty) {
			return 0;
		}
		var disks = Ext.getCmp("disk" + init_suffix_id);
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
		
		var raid_params_str = inraid + '&' + spare;
		raid_params_str += ("&type=" + raid_params.type);
		if (typeof raid_params._assume_clean != "undefined") {
			raid_params_str += ("&_assume_clean=" + raid_params._assume_clean);
		}
		if (typeof raid_params.chunk != "undefined") {
			raid_params_str += ("&chunk=" + raid_params.chunk);
		}
		raid_params_str += ("&raid_id=" + raid_params.raid_id);
		raid_params_str += ("&filesystem=" + raid_params.filesystem);
		raid_params_str += ("&data_percent=" + raid_params.data_percent + "%20%25");

		processAjax("setmain.php?fun=setraid",onLoadInit,"&action=create&"+raid_params_str, false);
		break;
	case "setinit":
		var data = "&action=setdb";
		if (Ext.getCmp("raid_level" + init_suffix_id).text !== "" && Ext.getCmp("username" + init_suffix_id).getValue() !== "") {
			data = "&action=adduser&" + init_user_form.getForm().getValues(true);
		}		
		processAjax("setmain.php?fun=setinit",onLoadInit, data, false);
		break;
	default:
		init_wizard.mask.hide();
		init_wizard.setActiveStep("final");
	}
	return 1;
}

/* Handler function for cancel button.
 * @author: ellie_chien
 * 
 * @return: none
 */
function initCancelHandler()
{
	Ext.Msg.confirm("<{$words.init_wizard_title}>","<{$init_words.cancel_msg}>",function(btn){
		if(btn=="yes"){
			init_wizard.getWin().hide();
			processAjax("setmain.php?fun=setinit",onLoadForm, "&action=setdb");
		}
	});
}
