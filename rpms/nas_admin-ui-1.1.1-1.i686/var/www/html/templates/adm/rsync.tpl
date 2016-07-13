<fieldset class="x-fieldset" style="margin: 10px;"><legend class="legend"><{$words.title}></legend>
<div id="rsync_form"></div>
</fieldset>


<script language"javascript">
Ext.QuickTips.init();
Ext.apply(Ext.QuickTips.getQuickTip(), {dismissDelay: 10000}); 

var rsync_monitor = null;
var rsyncForm = renderRsyncForm();
var rsync_task_win_type = "";
var rsync_page_limit=13;
var rsync_progress_monitor = null;
var rsync_required_fields = new Array("rsync_dest_ip", "rsync_user", "rsync_pwd", "rsync_src_list");
var rsync_src_folder_list = "";

if ("<{$reload}>" == "1") {
	clearTimeout(rsync_monitor); // prevent mulitple monitor
	rsync_monitor = setTimeout(reloadBkpStatus,10000);
}

function ExtDestroy(){
	Ext.destroy(Ext.getCmp('rsync_task_win'));
	Ext.destroy(Ext.getCmp("rsync_progress_win"));
	Ext.destroy(Ext.getCmp("rsync_log_win"));
	clearTimeout(rsync_monitor);
	clearTimeout(rsync_progress_monitor);
}

function renderRsyncForm() {
	var taskGrid = renderGridPanel();

	var fp = new Ext.FormPanel({
		frame: true,
		labelAlign:'left',
		labelWidth:180,
		buttonAlign:'left',
		items: [
			taskGrid
		],
		renderTo:'rsync_form'
	});

	return fp;
}

function renderGridPanel() {
	var toolbar =new Ext.Toolbar({
		items:[
		{
			text:"<{$gwords.add}>",
			iconCls:'add',
			handler:function(){
				rsync_task_win_type = "add";
				processAjax("<{$geturl}>",openRsyncTaskWin,"&action=task_default");
			}
		}, '-',{
			text:"<{$gwords.edit}>",
			iconCls:'edit',
			handler:function(){
				rsync_task_win_type = "modify";
				var tasklist = getSelectedTasks();
				if (tasklist.length != 1) {
					Ext.Msg.alert("<{$words.title}>","<{$words.modify_confirm}>");
					return;
				}
				processAjax("<{$geturl}>",openRsyncTaskWin,"&action=task_data&taskname=" + tasklist[0]);
			}
		}, '-',{
			text:"<{$gwords.del}>",
			iconCls:'remove',
			handler:function(){
				rsync_task_win_type = "";
				var tasklist = getSelectedTasks();
				if (tasklist.length <= 0) {
					Ext.Msg.alert("<{$words.title}>","<{$words.rsync_no_selected}>");
					return;
				}
				processAjax("<{$form_action}>",reloadBkpStatus,"&action=delete&tasklist="+encodeURIComponent(tasklist.join("<{$folder_sep}>")));
			}
		}]
	});
	
	
	var rsync_store = new Ext.data.JsonStore({
		storeId:'rsync_store',
		config:{
			pruneModifiedRecords:true
		},
		fields:[
			'taskname','desp','model','folder','ip','port','dest_folder','subfolder','username','log_folder','backup_enable','backup_time','end_time','status','src_folder','dest_path','task_status'
		],
		data: <{$rsync_task}>
	});
	rsync_store.on("load", function(store, records, obj) {
		var len = records.length;
		for (var i = 0; i < len; i++) {
			var taskname = records[i].get("taskname");
			if (records[i].get("task_status") == "<{$words.task_running}>") {
				Ext.getDom(taskname + "_box").disabled = "disabled";
			} else {
				Ext.getDom(taskname + "_box").disabled = "";
			}
		}
	});
	

	var grid = new Ext.grid.GridPanel({
		id:'rsync_task_grid',
		disableSelection:false,
		store:rsync_store,
		enableHdMenu:false,
		bodyStyle:"align:center;",
		cm: new Ext.grid.ColumnModel([{
			header: "<input type='checkbox' onclick='selectAll(this)'>",
			width:45,
			renderer:renderChecked,
			menuDisabled:true
		},{
			header: "<{$gwords.task_name}>", 
			width: 80, 
			sortable: true, 
			dataIndex: 'taskname'
		},{
			header: "<{$words.folder}>", 
			width: 150, 
			sortable: true,
			dataIndex: 'src_folder'
		},{
			header: "<{$gwords.schedule}>", 
			width: 80, 
			sortable: false,
			renderer:renderSchedule,
			dataIndex: 'schedule'
		},{
			header: "<{$words.target_path}>", 
			width: 130, 
			sortable: true, 
			dataIndex: 'dest_path'
		},{
			header: "<{$words.lasttime}>", 
			width: 90, 
			sortable: true,
			dataIndex: 'end_time'
		},{
			header: "<{$words.laststatus}>", 
			width: 120, 
			sortable: true,
			renderer:renderStatus,
			dataIndex: 'task_status'
		},{
			header: "<{$gwords.action}>", 
			width: 50, 
			height :50, 
			renderer:renderAction, 
			dataIndex: 'action'
		}]),
		listeners:{
			rowclick:function(gridObj,rowIndex,event){
				var boxid=gridObj.getStore().getAt(rowIndex).get('taskname')+'_box';
				if(Ext.getDom(boxid).checked){
					Ext.getDom(boxid).checked=false;
				}else{
					if(!Ext.getDom(boxid).disabled){
						Ext.getDom(boxid).checked=true;
					}
				}
			}
		},
		width:750,
		autoHeight:true,
		authWidth:true,
		tbar:toolbar
	});
	
	return grid;
}

function getSelectedTasks() {
	var grid = Ext.getCmp("rsync_task_grid");
	var total = grid.getStore().getCount();
	var tasklist = new Array();
	for (var i=0;i<total;i++){
		var boxid = grid.getStore().getAt(i).get('taskname')+'_box';
		if(Ext.getDom(boxid).checked){
			tasklist.push(grid.getStore().getAt(i).get('taskname'));
		}
	}
	
	return tasklist;
}

function selectAll(element){
	var grid = Ext.getCmp("rsync_task_grid");
	var size = grid.getStore().getCount();
	var boxid;
	for (var i=0;i<size;i++){
		boxid = grid.getStore().getAt(i).get('taskname')+'_box';
		if(element.checked && !Ext.getDom(boxid).disabled){
			Ext.getDom(boxid).checked=true;
		}else{
			Ext.getDom(boxid).checked=false;
		}
	}
}

function renderChecked(v,cellmata,record,rowIndex) {
	var taskname = record.data["taskname"];
	var mode = "";
	var innerHtml = "";
	if (record.data["model"] == "1") {
		mode = "I";
	} else {
		mode = "S";
	}
	
	if (record.data["task_status"] == "<{$words.task_running}>") {
		innerHtml = "<div><input type='checkbox' onclick='this.checked=(this.checked)?false:true;' name='"+ taskname +"_box' id='"+ taskname +"_box' disabled='disabled'>&nbsp;"+mode+"</div>";
	} else {
		innerHtml = "<div><input type='checkbox' onclick='this.checked=(this.checked)?false:true;' name='"+ taskname +"_box' id='"+ taskname +"_box'>&nbsp;"+mode+"</div>";
	}

	return innerHtml;
}

function renderRsyncTaskWin() {
	var rsync_mode_radio = new Ext.form.RadioGroup({
		id:'rsync_mode',
		fieldLabel: "<{$words.model}>",
		width:500,
        defaults: {autoHeight: true},
		columns:1,
		items: [{
			boxLabel: "<{$words.sync}> <{$words.sync_desp}>",
			name: 'rsync_mode',
			checked:true,
			inputValue: "0"
		},{
			boxLabel: "<{$words.increm}> <{$words.increm_desp}>",
			name: 'rsync_mode',
			inputValue: "1"
		}]
	});
	
	var folder_store=new Ext.data.SimpleStore({
		fields:<{$share_fields}>,
		data:<{$share_data}>
	});

	var select_src_btn = new Ext.Button({
		text:"<{$words.select_src}>",
		handler:function(){
			openSrcFolderWin();
		}
	});
	
	var rsync_src = new Ext.Panel({
		layout:'column',
		border:false,
		defaults:{
			layout:'form',
			xtype:'panel'
		},
		items:[
		{
			columnWidth:'.75',
			items:[
			{
				xtype: 'textfield',
				id:'rsync_src_list',
				fieldLabel:"<{$words.folder}>",
				width: 350,
				readOnly: true,
				value:'',
				listeners: {
					focus:{fn:function(field){
						openSrcFolderWin();
					}}
				}
			}]
	},{
			columnWidth:'.25',
			items:select_src_btn
		}]
	});
	
  var encrypt_checkbox = new Ext.form.Checkbox({
    name:'rsync_encrypt_on',
    id:'rsync_encrypt_on',
    hideLabel:true,
    value:1,
    boxLabel:'<{$words.ssh_support}>'
  });

  var compression_checkbox = new Ext.form.Checkbox({
    name:'rsync_compression',
    id:'rsync_compression',
    hideLabel:true,
    value:1,
    boxLabel:'<{$words.compression}>'
  });

  var sparse_checkbox = new Ext.form.Checkbox({
    name:'rsync_sparse',
    id:'rsync_sparse',
    hideLabel:true,
    value:1,
    boxLabel:'<{$words.handle_sparse}>'
  });

	var log_combobox = new Ext.form.ComboBox({
		store:folder_store,
		fieldLabel:"<{$words.log_folder}>",
		valueField :'value',
		displayField:'display',
		mode: 'local',
		forceSelection: true,
		editable: false,
		triggerAction: 'all',
		disabled:false,
		id: 'rsync_log_folder',
		name: 'rsync_log_folder',
		listWidth :150,
		width:150,
		value:"<{$default_folder}>"
	});

	var test_btn = new Ext.Button({
		text:"<{$words.rsync_test}>",
		handler:function(){
			var invalid_fields = getInvalidFields();
			if (invalid_fields !== "") {
				if (rsync_task_win_type == "add") {
					Ext.Msg.alert("<{$words.msg_add_title}>","<{$words.field_required}><br>"+invalid_fields);
				} else {
					Ext.Msg.alert("<{$words.msg_modify_title}>","<{$words.field_required}><br>"+invalid_fields);
				}
				return;
			}
			
			var currentShareList = Ext.getCmp("rsync_src_list").getValue();
			if (currentShareList === "") {
				if (rsync_task_win_type == "add") {
					Ext.Msg.alert("<{$words.msg_add_title}>","<{$words.no_src_warn}>");
				} else {
					Ext.Msg.alert("<{$words.msg_modify_title}>","<{$words.no_src_warn}>");
				}
				return;
			}
			var form = Ext.getCmp("rsync_task_form").getForm();
			var pwd_change = 0;
			if (Ext.getCmp("rsync_pwd").getValue() != "<{$default_pwd}>") {
				pwd_change = 1;
			}
			var param = "";
			if (rsync_task_win_type == "add") {
				param = form.getValues(true) + "&action=test&src_folder=" + rsync_src_folder_list + "&pwd_change=" + pwd_change;
			} else {
				// Because taskname field is disabled in edit dialog, fp.getForm().getValues(true) didn't include taskname
				param = form.getValues(true) + "&action=test&src_folder=" + rsync_src_folder_list + "&pwd_change=" + pwd_change + "&taskname=" + Ext.getCmp("taskname").getValue();
			}
			processAjax("<{$geturl}>", updateTestMsg, param);
		}
	});
	
	var schedule_time = new Ext.form.TimeField({
		fieldLabel: "<{$gwords.time}>",
		mode: 'local',
		id: 'rsync_schedule_time',
		format:'H:i',
		increment:1,
		forceSelection:true,
		autoWidth:true,
		value:"00:00"
	});
	
	var day_store= new Ext.data.SimpleStore({
		fields: <{$day_fields}>,
		data: <{$day_data}>
	});
	
	var day_combobox = new Ext.form.ComboBox({
		store:day_store,
		valueField :'value',
		displayField:'display',
		mode: 'local',
		forceSelection: true,
		editable: false,
		triggerAction: 'all',
		id: 'rsync_day',
		name: 'rsync_day',
		autoWidth:true,
		value:1,
		hidden:true
	});
	
	var week_store=new Ext.data.SimpleStore({
		fields: <{$week_fields}>,
		data: <{$week_data}>
	});
	
	var week_combobox = new Ext.form.ComboBox({
		store:week_store,
		valueField :'value',
		displayField:'display',
		mode: 'local',
		forceSelection: true,
		editable: false,
		triggerAction: 'all',
		id: 'rsync_week',
		name: 'rsync_week',
		autoWidth:true,
		value:"0",
		hidden:true
	});
	
	var rsync_schedule_type_radio = new Ext.form.RadioGroup({
		id:'rsync_schedule_type',
		fieldLabel: "<{$gwords.type}>",
		width:400,
		columns:3,
		listeners: {change:{fn:function(r,c){
			if(c=='daily'){
				day_combobox.hide();
				week_combobox.hide();
			}else if(c=='weekly'){
				week_combobox.show();
				day_combobox.hide();
			}else if(c=='monthly'){
				week_combobox.hide();
				day_combobox.show();
			}
		}}},
		items: [{
			boxLabel: "<{$gwords.daily}>",
			name: 'rsync_schedule_type',
			checked:true,
			inputValue: 'daily'
		},{
			boxLabel: "<{$gwords.weekly}>",
			name: 'rsync_schedule_type',
			inputValue: 'weekly'
		},{
			boxLabel: "<{$gwords.monthly}>",
			name: 'rsync_schedule_type',
			inputValue: 'monthly'
		}]
	});
	
	var rsync_schedule_combo = new Ext.form.RadioGroup({
		fieldLabel: "",
		labelSeparator: "",
		width:400,
		columns:3,
		items: [{
			xtype:'field',
			disabled:true,
			hidden:true
		},
		week_combobox,
		day_combobox
		]
	});
	
	var rsync_schedule_radio = new Ext.form.RadioGroup({
		xtype: 'radiogroup',
		id:'rsync_schedule',
		fieldLabel: "<{$gwords.enable}>/<{$gwords.disable}>",
		width:200,
		listeners: {change:{fn:function(r,c){
			if(c=='0'){
				schedule_time.setDisabled(true);
				schedule_time.setVisible(true);
				rsync_schedule_type_radio.setDisabled(true);
				week_combobox.setDisabled(true);
				day_combobox.setDisabled(true);
			}else{
				schedule_time.setDisabled(false);
				rsync_schedule_type_radio.setDisabled(false);
				week_combobox.setDisabled(false);
				day_combobox.setDisabled(false);
			}
		}}},
		items: [{
			boxLabel: "<{$gwords.enable}>",
			name: 'rsync_schedule',
			checked:true,
			inputValue: '1'
		},{
			boxLabel: "<{$gwords.disable}>",
			name: 'rsync_schedule',
			inputValue: '0'
		}]
	});
	
	var dest_addr = new Ext.Panel({
		layout:'column',
		border:false,
		defaults:{
			layout:'form',
			xtype:'panel'
		},
		items:[
		{
			columnWidth:'.45',
			items:[
			{
				xtype: 'textfield',
				id:'rsync_dest_ip',
				fieldLabel:"<{$words.server_port}>",
				value:''
			}]
		},{
			columnWidth:'.02',
			items:[
			{
				xtype:'label',
				text:':'
			}]
		},{
			columnWidth:'.53',
			items:[
			{
				xtype: 'textfield',
				id:'rsync_dest_port',
				width:50,
				hideLabel:true,
				value:'873'
			}]
		}]
	});

	var dest_folder = new Ext.Panel({
		layout:'column',
		border:false,
		defaults:{
			layout:'form',
			xtype:'panel'
		},
		items:[
		{
			columnWidth:'.45',
			items:[
			{
				xtype: 'textfield',
				id:'rsync_dest_folder',
				fieldLabel:"<{$words.target_folder}>",
				value:''
			}]
		},{
			columnWidth:'.02',
			items:[
			{
				xtype:'label',
				text:'/'
			}]
		},{
			columnWidth:'.2',
			items:[
			{
				xtype: 'textfield',
				id:'rsync_subfolder',
				hideLabel:true,
				value:''
			}]
		},{
			columnWidth:'.03',
			items:[
			{
				xtype: "box",
				id: "rsync_dest_folder_desc",
				autoEl: {
					html: "<img src='<{$urlimg}>/icons/fam/icon-question.gif' style='cursor: pointer;' ext:qtip=\"<a style='color:red'><{$words.dest_folder_desc}></a>\" >"
				}
			}]
		}]
	});
	
	var fp = new Ext.FormPanel({
		id:'rsync_task_form',
		frame: true,
		labelAlign:'left',
		labelWidth:180,
		buttonAlign:'left',
		items: [{
			xtype:'fieldset',
			title:"<{$words.title}>",
			width:760,
			autoHeight:true,
			collapsed: false,
			items:[{
				xtype: 'textfield',
				id:'taskname',
				fieldLabel:"<{$gwords.task_name}>",
				value:''
			},{
				xtype: 'textfield',
				id:'rsync_desp',
				fieldLabel:"<{$words.task_desp}>",
				width:500,
				value:''
			},
			rsync_mode_radio,
			rsync_src,
			dest_addr,
			dest_folder,
			{
				xtype: 'textfield',
				id:'rsync_user',
				fieldLabel:"<{$gwords.username}>",
				value:''
			},{
				xtype: 'textfield',
				inputType:'password',
				id:'rsync_pwd',
				fieldLabel:"<{$gwords.password}>",
				value:"<{$default_pwd}>",
				minLength:4,
				maxLength:16
			},
			log_combobox,
			encrypt_checkbox,
			compression_checkbox,
			sparse_checkbox,
			test_btn
			]
		},{
			xtype:'fieldset',
			width:760,
			title:"<{$gwords.schedule}>",
			autoHeight:true,
			items:[
			rsync_schedule_radio,
			{
				xtype: 'hidden',
				id:"backup_time",
				name:"backup_time",
				value:''
			},
			schedule_time,
			rsync_schedule_type_radio,
			rsync_schedule_combo
			]
		}],
		buttons:[{
			id:'rsync_apply_btn',
			text:"<{$gwords.add}>",
			handler:function(v){
				var invalid_fields = getInvalidFields();
				if (invalid_fields !== "") {
					if (rsync_task_win_type == "add") {
						Ext.Msg.alert("<{$words.msg_add_title}>","<{$words.field_required}><br>"+invalid_fields);
					} else {
						Ext.Msg.alert("<{$words.msg_modify_title}>","<{$words.field_required}><br>"+invalid_fields);
					}
					return;
				}
				var pwd_change = 0;
				if (Ext.getCmp("rsync_pwd").getValue() != "<{$default_pwd}>") {
					pwd_change = 1;
				}
				Ext.getCmp("backup_time").setValue(getCrondStr());
				var param = "";
				if (rsync_task_win_type == "add") {
					param = fp.getForm().getValues(true) + "&action=" + rsync_task_win_type + "&pwd_change=" + pwd_change + "&src_folder=" + rsync_src_folder_list;
				} else {
					// Because taskname field is disabled in edit dialog, fp.getForm().getValues(true) didn't include taskname
					param = fp.getForm().getValues(true) + "&action=" + rsync_task_win_type + "&pwd_change=" + pwd_change + "&src_folder=" + rsync_src_folder_list + "&taskname=" + Ext.getCmp("taskname").getValue();
				}
				processAjax("<{$form_action}>",onLoadForm,param);
			}
		}]
	});

	var rsyncWin = new Ext.Window({
		id:'rsync_task_win',
		closable:true,
		closeAction:'hide',
		width: 790,
		autoHeight:true,
		draggable:false,
		autoScroll:true,
		modal: true,
		resizable:false,
		title:"<{$words.title}>",
		items: fp
	});
	rsyncWin.on("show", function() {
		var src_grid =  Ext.getCmp("rsync_src_grid");
		if (src_grid) {
			src_grid.getSelectionModel().clearSelections();
			rsync_src_folder_list = "";
		}
	});
	rsyncWin.on("hide", function() {
		reloadBkpStatus();
	});

	return rsyncWin;
}

function renderRsyncConnTestWin() {
	var fp = new Ext.FormPanel({
		frame: true,
		labelAlign:'left',
		labelWidth:100,
		buttonAlign:'left',
		items: [{
			xtype: 'textarea',
			id:'rsync_test_msg',
			fieldLabel:"<{$words.rsync_test}>",
			width:300,
			readOnly:true,
			value:''
		}]
	});

	var rsyncConnTestWin = new Ext.Window({
		id:'rsync_conn_test_win',
		closable:true,
		closeAction:'hide',
		width: 450,
		autoHeight:true,
		draggable:false,
		autoScroll:true,
		modal: true,
		resizable:false,
		title:"<{$words.title}>",
		items: fp
	});

	return rsyncConnTestWin;
}

function openRsyncConnTestWin(msg) {
	var rsyncConnTestWin = Ext.getCmp("rsync_conn_test_win");
	if (!rsyncConnTestWin) {
		rsyncConnTestWin = renderRsyncConnTestWin();
		rsyncConnTestWin.show();
	} else if (rsyncConnTestWin.isVisible()) {
		rsyncConnTestWin.toFront();
	} else {
		rsyncConnTestWin.show();
	}
	
	Ext.getCmp("rsync_test_msg").setValue(msg)
}

function updateTestMsg() {
	var request = eval('('+this.req.responseText+')');
	openRsyncConnTestWin(request.rsync_test_msg);
}

function renderSrcFolderWin() {
	var rsync_src_store = new Ext.data.JsonStore({
		storeId:'rsync_src_store',
		fields:[
			'src_folder'
		],
		data: {}
	});

	var srcGrid = new Ext.grid.GridPanel({
		id:'rsync_src_grid',
		store:rsync_src_store,
		bodyStyle:"align:center;",
		cm: new Ext.grid.ColumnModel([
			{id:'src_folder', header: "<{$words.folder}>", width: 400,  sortable: true, dataIndex: 'src_folder'}
		]),
		sm: new Ext.grid.RowSelectionModel({}),
		width:400,
		autoHeight:true
	});
	
	var rsyncSrcWin = new Ext.Window({
		id:'rsync_src_win',
		closable:true,
		closeAction:'hide',
		width: 400,
		draggable:false, 
		autoHeight:true,
		modal: true,
		resizable:false,
		title:'<{$words.title}>',
		items: [
		{
			xtype: "box",
			autoEl: {
				style:'color:red;',
				html: "(<{$words.folder_desp}>)<br>"
			}
		},
		srcGrid],
		buttonAlign:'right',
		buttons:[{
			text:"<{$gwords.add}>",
			handler:function(v){
				var shareAry = getSelectedSrcFolder();
				if (shareAry.length === 0) {
					if (rsync_task_win_type == "add") {
						Ext.Msg.alert("<{$words.msg_add_title}>","<{$words.no_src_warn}>");
					} else {
						Ext.Msg.alert("<{$words.msg_modify_title}>","<{$words.no_src_warn}>");
					}
					return;
				}
				rsync_src_folder_list = shareAry.join("<{$folder_sep}>");	// the value is for database
				var len = shareAry.length;
				for (var i = 0; i < len; i++) {
					shareAry[i] = "[" + shareAry[i] + "]"
				}
				var share_list = shareAry.join(",");
				Ext.getCmp("rsync_src_list").setValue(share_list);
				Ext.QuickTips.unregister(Ext.getCmp('rsync_src_list').getEl());
				Ext.QuickTips.tips({
					target: 'rsync_src_list',
					text: share_list
				});
				rsyncSrcWin.hide();
			}
		}]
	});
	
	return rsyncSrcWin;

}

function getSelectedSrcFolder() {
	var shareAry = new Array();
	if (!Ext.getCmp("rsync_src_grid")) {
		return shareAry;
	}
	var records = Ext.getCmp("rsync_src_grid").getSelectionModel().getSelections();
	var len = records.length;
	for (var i = 0; i < len; i++) {
		var rec = records[i];
		shareAry.push(rec.data["src_folder"]);
	}
	
	return shareAry;
}

function openSrcFolderWin() {
	var rsyncSrcWin = Ext.getCmp("rsync_src_win");
	if (!rsyncSrcWin) {
		rsyncSrcWin = renderSrcFolderWin();
		rsyncSrcWin.show();
	} else if (rsyncSrcWin.isVisible()) {
		rsyncSrcWin.toFront();
	} else {
		rsyncSrcWin.show();
	}
	
	processAjax('<{$geturl}>&action=src_folder',onLoadSrcFolder);
}

function onLoadSrcFolder() {
	var request = eval('('+this.req.responseText+')');
	if (!request) return;
	
	var srcGrid = Ext.getCmp("rsync_src_grid");
	srcGrid.getStore().loadData(request.src_folder);
}

function getInvalidFields() {
	var count = rsync_required_fields.length;
	var invalid_field = new Array();
	for (var i = 0; i < count; i++) {
		var field = Ext.getCmp(rsync_required_fields[i]);
		if (!field) continue;
		if (!field.getValue() || field.getValue() === "") {
			invalid_field.push(field.fieldLabel);
		}
	}
	if (invalid_field.length === 0) {
		return "";
	}
	return invalid_field.join(",");
}

function window_rsync_hide() {
	Ext.getCmp("rsync_task_win").hide();
}

function openRsyncTaskWin() {
	var request = eval('('+this.req.responseText+')');
	if (!request) return;
	
	if (rsync_task_win_type == "modify" && request.task_data === "") {
		Ext.Msg.alert("<{$words.msg_modify_title}>","<{$words.task_no_existed}>");
		reloadBkpStatus();
		return;
	}
	
	clearTimeout(rsync_monitor);
	var taskWin = Ext.getCmp('rsync_task_win');
	if (!taskWin) {
		taskWin = renderRsyncTaskWin();
		taskWin.show();
	} else if (taskWin.isVisible()) {
		taskWin.toFront();
	} else {
		taskWin.show();
	}

	if (rsync_task_win_type == "add") {
		Ext.getCmp("rsync_apply_btn").setText("<{$gwords.add}>");
		Ext.getCmp("taskname").setDisabled(false);
		var task_data = new Array();
		task_data["taskname"] = request.taskname;
		task_data["port"] = 873;
		task_data["model"] = "0";
		task_data["folder"] = "";
		task_data["log_folder"] = "<{$default_folder}>";
		task_data["backup_enable"] = 1;
		task_data["backup_time"] = "";
		task_data["passwd"] = "";
		task_data["tmp1"] = "0";
		task_data["tmp2"] = "0";
		task_data["tmp3"] = "0";
		loadTaskData(task_data);
	} else {
		Ext.getCmp("rsync_apply_btn").setText("<{$gwords.modify}>");
		Ext.getCmp("taskname").setDisabled(true);
		loadTaskData(request.task_data);
	}
}

function loadTaskData(task_data) {
	Ext.getCmp("taskname").setValue(task_data["taskname"]);
	Ext.getCmp("rsync_mode").setValue(task_data["model"]);
	Ext.getCmp("rsync_src_list").setValue(task_data["folder"]);
	Ext.getCmp("rsync_desp").setValue(task_data["desp"]?task_data["desp"]:"");
	Ext.getCmp("rsync_dest_ip").setValue(task_data["ip"]?task_data["ip"]:"");
	Ext.getCmp("rsync_dest_port").setValue(task_data["port"]?task_data["port"]:"");
	Ext.getCmp("rsync_dest_folder").setValue(task_data["dest_folder"]?task_data["dest_folder"]:"");
	Ext.getCmp("rsync_subfolder").setValue(task_data["subfolder"]?task_data["subfolder"]:"");
	Ext.getCmp("rsync_user").setValue(task_data["username"]?task_data["username"]:"");
	Ext.getCmp("rsync_log_folder").setValue(task_data["log_folder"]);
	Ext.getCmp("rsync_encrypt_on").setValue(task_data["tmp1"]);
	Ext.getCmp("rsync_compression").setValue(task_data["tmp2"]);
	Ext.getCmp("rsync_sparse").setValue(task_data["tmp3"]);
	Ext.getCmp("rsync_pwd").setValue(task_data["passwd"]);
	
	setScheduleVal(task_data["backup_enable"], task_data["backup_time"]);
	
	Ext.QuickTips.unregister(Ext.getCmp('rsync_src_list').getEl());
	if (rsync_task_win_type == "modify") {
		Ext.QuickTips.tips({
			target: 'rsync_src_list',
			text: Ext.getCmp('rsync_src_list').getValue()
		});
	}
}

function setScheduleVal(schedule_enable, schedule) {
	Ext.getCmp("rsync_schedule").setValue(schedule_enable);
	Ext.getCmp("backup_time").setValue(schedule);
	
	if (schedule === "") {
		Ext.getCmp("rsync_schedule_type").setValue("daily");
		Ext.getCmp("rsync_day").hide();
		Ext.getCmp("rsync_week").hide();
		Ext.getCmp("rsync_schedule_time").setValue("00:00");
		return;
	}
	var crond = schedule.split(" ");
	if (crond[2] != "*") {
		Ext.getCmp("rsync_schedule_type").setValue("monthly");
		Ext.getCmp("rsync_day").show();
		Ext.getCmp("rsync_week").hide();
	} else if (crond[4] != "*") {
		Ext.getCmp("rsync_schedule_type").setValue("weekly");
		Ext.getCmp("rsync_day").hide();
		Ext.getCmp("rsync_week").show();
	} else {
		Ext.getCmp("rsync_schedule_type").setValue("daily");
		Ext.getCmp("rsync_day").hide();
		Ext.getCmp("rsync_week").hide();
	}
	Ext.getCmp("rsync_schedule_time").setValue(crond[1] + ":" + crond[0]);
}

function getCrondStr() {
	if (!Ext.getCmp("rsync_schedule").getValue()) {
		return Ext.getCmp("backup_time").getValue();
	}
	
	var crond_str = "";
	var time = Ext.getCmp("rsync_schedule_time").getValue().split(":");
	var schedule_type = Ext.getCmp("rsync_schedule_type").getValue();
	switch (schedule_type) {
		case "weekly":
			crond_str = time[1] + " " + time[0] + " * * " + Ext.getCmp("rsync_week").getValue();
			break;
		case "monthly":
			crond_str = time[1] + " " + time[0] + " " + Ext.getCmp("rsync_day").getValue() + " * *";
			break;
		default:
			crond_str = time[1] + " " + time[0] + " * * *";
	}
	
	return crond_str;
}

function openStatusWin(statusType, taskname, dest_folder) {
	if (statusType == "log") {
		popupLogWin(taskname);
	} else {
		callProgressWin(taskname, dest_folder);
	}
}
function popupLogWin(taskname){
	var rsync_log_win = Ext.getCmp("rsync_log_win");
	
	if (!rsync_log_win) {
		rsync_log_win = renderLogWin();
	}
	clearTimeout(rsync_monitor);
	rsync_log_win.show();
	Ext.getCmp("rsync_log_page").store.proxy.conn.url='<{$geturl}>&action=log&taskname='+encodeURIComponent(taskname);
	Ext.getCmp("rsync_log_page").store.load({params:{start:0, limit:rsync_page_limit}});
}

function renderLogWin() {
	var rsync_log_store = new Ext.data.JsonStore({
		storeId:'rsync_log_store',
		root:'log_data',
		totalProperty: 'total_count',
		idProperty: 'log_msg',
		fields:[
			'log_msg'
		],
		url: '<{$geturl}>&action=log'
	});
	
	var pagingBar = new Ext.PagingToolbar({
		id:"rsync_log_page",
		pageSize: rsync_page_limit,
		store: rsync_log_store,
		displayInfo: true,
		beforePageText:"<{$gwords.page1}>",
		afterPageText:"<{$gwords.page2}> {0} <{$gwords.page3}> "
	});

	var gridFormLog = new Ext.grid.GridPanel({
		id:'rsync_log',
		disableSelection:false,
		store:rsync_log_store,
		cm: new Ext.grid.ColumnModel([
			{header: "", width: 650, sortable: true, dataIndex: 'log_msg'}
		]),
		width:680,
		height:340,
		bbar: pagingBar,
		loadMask:true
	});

	var rsyncLogWin = new Ext.Window({
		id:'rsync_log_win',
		closable:true,
		closeAction:'hide',
		width: 700,
		draggable:false, 
		autoHeight:true,
		modal: true,
		resizable:false,
		title:'<{$words.title}>',
		items: gridFormLog,
		buttonAlign:'left'
	});
	rsyncLogWin.on("hide", function() {
		reloadBkpStatus();
	});
	
	return rsyncLogWin;
}

function callProgressWin(taskname, dest_folder){
	clearTimeout(rsync_monitor);
	var rsyncProgressWin = Ext.getCmp("rsync_progress_win");
	if (!rsyncProgressWin) {
		rsyncProgressWin = renderProgressWin();
		rsyncProgressWin.show();
	} else if (!rsyncProgressWin.isVisible()) {
		rsyncProgressWin.show();
	} else {
		rsyncProgressWin.toFront();
	}
	processAjax('<{$geturl}>&action=progress&taskname=' + encodeURIComponent(taskname) + '&dest_folder=' + dest_folder,popupProgressWin);
}

function popupProgressWin(){
	var request = eval('('+this.req.responseText+')');
	var close = request.close;
	if(close == "1"){
		Ext.getCmp("rsync_progress_win").hide();
	}else{
		var taskname = request.progress.taskname;
		var dest_folder = request.progress.dest_folder;
		rsync_progress_monitor = setTimeout("processAjax('<{$geturl}>&action=progress&taskname=" + encodeURIComponent(taskname) + "&dest_folder=" + dest_folder + "',popupProgressWin)",10000);
		Ext.getDom('rsync_status_task_name').value = taskname;
		Ext.getDom('rsync_status_ip').value = request.progress.dest_folder;
		Ext.getDom('rsync_status_start_time').value = request.progress.start_time;
		Ext.getDom('rsync_status_progress').value = request.progress.process_file;
		if (request.progress.status == "") {
			Ext.getDom('rsync_status_proceed').value = "<{$gwords.wait_msg}>";
		} else {
			Ext.getDom('rsync_status_proceed').value = request.progress.status;
		}
	}
}

function renderProgressWin() {
	var statusForm = new Ext.FormPanel({
		labelAlign:'left',
		buttonAlign:'left',
		frame: true,
		items:[{
			xtype:'fieldset',
			title:"<{$words.rsync_log_title}>",
			autoHeight:true,
			collapsed: false,
			defaults:{width: '230'},
			items:[{
				xtype: 'textfield',
				id:'rsync_status_task_name',
				fieldLabel:"<{$gwords.task_name}>",
				disabled:true,
				value:''
			},{
				xtype: 'textfield',
				id:'rsync_status_ip',
				fieldLabel:"<{$words.target_path}>",
				disabled:true,
				value:''
			},{
				xtype: 'textfield',
				id:'rsync_status_start_time',
				fieldLabel:"<{$words.start_time}>",
				disabled:true,
				value:''
			},{
				xtype: 'textfield',
				id:'rsync_status_progress',
				fieldLabel:"<{$words.process_file}>",
				disabled:true,
				value:''
			},{
				xtype: 'textarea',
				id:'rsync_status_proceed',
				fieldLabel:"<{$gwords.status}>",
				disabled:true,
				value:''
			}]
		}]
	});
	
	var rsyncProgressWin = new Ext.Window({
		id:'rsync_progress_win',
		closable:true,
		closeAction:'hide',
		width: 400,
		draggable:false,
		autoHeight:true,
		modal: true,
		resizable:false,
		title:"<{$words.title}>",
		items:statusForm,
		listeners: {
			hide:{
				fn:function(r,c){
					clearTimeout(rsync_progress_monitor);
				}
			}
		}
	});
	rsyncProgressWin.on("hide", function() {
		reloadBkpStatus();
	});
	
	return rsyncProgressWin;
}

function renderSchedule(v,cellmata,record,rowIndex) {
	var crond_str = record.data["backup_time"];
	var enable = record.data["backup_enable"];
	var crond = crond_str.split(" ");
	var schedule_str = "";
	
	if(crond[4] != "*"){
		var week = new Array("<{$gwords.sunday}>","<{$gwords.monday}>","<{$gwords.thuesday}>","<{$gwords.wednesday}>","<{$gwords.thursday}>","<{$gwords.friday}>","<{$gwords.saturday}>");
		schedule_str = week[crond[4]];
	} else if (crond[2] != "*"){
		schedule_str = "<{$gwords.monthly}> (" + crond[2] + ")";
	}else{
		schedule_str = "<{$words.daily}>";
	}

	if (enable == "1") {
		schedule_str += "&nbsp(<span style='color:blue'><{$gwords.enable}></span>)";
	} else {
		schedule_str += "&nbsp(<span style='color:red'><{$gwords.disable}></span>)";
	}
	
	return schedule_str;
}

function renderStatus(v,cellmata,record,rowIndex) {
	var task_status = record.data["task_status"];
	var taskname = record.data["taskname"];
	var dest_folder = record.data["dest_folder"];
	var statusType;
	var status;
	
	if (task_status == "") {
		return "";
	}
	if (task_status == "<{$words.task_running}>") {
		statusType = "progress";
	} else {
		statusType = "log";
	}
	
	status = "<div style='cursor:pointer;' onclick='openStatusWin(\""+ statusType + "\",\"" + taskname +"\",\"" + dest_folder + "\");'>";
	status += "<span style='color:blue'>"+ task_status +"</span>";
	status += "</div>";
	
	return status;
}

function renderAction(v,cellmata,record,rowIndex) {
	var content = "";
	var btnImg = "";
	var actionType = "";
	if (record.data["task_status"] == "<{$words.task_running}>") {
		btnImg = "/default/sizer/square.gif";
		actionType = "stop";
	} else {
		btnImg = "/default/grid/page-next.gif";
		actionType = "start";
	}
	
	content = "<img src='<{$urlimg}>" + btnImg + "' style=\"cursor: pointer;\" onclick='actionProcess(\"" + actionType + "\",\"" + record.data["taskname"] + "\")'/>";
	
	return content;
}

function actionProcess(actionType, taskname) {
	processAjax("<{$form_action}>",reloadBkpStatus,"&action="+ actionType + "&taskname=" + encodeURIComponent(taskname));
}

function reloadBkpStatus() {
	processAjax("<{$geturl}>",onLoadBkpStatus,"&action=monitor");
}

function onLoadBkpStatus() {
	var request = eval('('+this.req.responseText+')');
	if (!request) return;

	var rsync_store = Ext.getCmp("rsync_task_grid").getStore();
	if(request.reload == 1){
		rsync_store.loadData(request.rsync_task);
		clearTimeout(rsync_monitor);	// to prevent multiple monitor
		rsync_monitor = setTimeout(reloadBkpStatus,10000);
	}else{
		rsync_store.loadData(request.rsync_task);
		if (!rsync_monitor) {
			clearTimeout(rsync_monitor);
			rsync_monitor = null;
		}
	}
}

</script>
