<style type="text/css" media="all">
.x-btn td.x-btn-left, .x-btn td.x-btn-right {padding: 0; font-size: 1px; line-height: 1px;}
.x-btn td.x-btn-center {padding:0 5px; vertical-align: middle;}
</style>

<script language"javascript">
function ExtDestroy(){
	Ext.destroy(Ext.getCmp('Window_nsync'));
	Ext.destroy(Ext.getCmp('Window_log'));
	Ext.destroy(Ext.getCmp('Window_progress'));
}
var nsync_monitor;
var nsync_status_monitor;
var page_limit=13;
//var nsync_page_limit=2;
var tran_type;

function change_flow(elementid){
	Ext.getCmp('formpanel_nfslist').hide();
	Ext.getCmp('formpanel_nfs').hide();
	Ext.getCmp('formpanel_share').hide();
	Ext.getCmp(elementid).show();
}
function change_click(){
	callLogForm(this.task_name);
}

function getLastStatus(){
	var request = eval('('+this.req.responseText+')');
	var task_name=request.task_name;
	var status_id=task_name+"_status";
	Ext.getDom(status_id).task_name=task_name;
	Ext.getDom(status_id).innerHTML="<span style='color:blue'>"+request.last_status+"</span>";
	Ext.getDom(status_id).onclick=change_click;
	//alert (this.req.responseText);
	processAjax("<{$geturl}>&action=start",getStatus);
}

function selectAll(element){
	var size = grid.getStore().getCount();
	var boxid;
	for (var i=0;i<size;i++){
		boxid = grid.getStore().getAt(i).get('task_name')+'_box';
		if(element.checked && !Ext.getDom(boxid).disabled){
			Ext.getDom(boxid).checked=true;
		}else{
			Ext.getDom(boxid).checked=false;
		}
	}
}

function checkDel(){
	processAjax("<{$geturl}>",getNsyncList,"&action=start");
}

function getNsyncList(){
	var request = eval('('+this.req.responseText+')');
	//alert (this.req.responseText);
	nsync_store.loadData(request.nsync_status);
}

function Window_nsync_hide(){
	Window_nsync.hide();
	processAjax("<{$geturl}>",getNsyncList,"&action=start");
}

Ext.QuickTips.init();

var xg = Ext.grid;

var sm = new xg.CheckboxSelectionModel({
	width:20
});

function geticon(val,y,thisObj,row_index,col_index){
	var task_id=thisObj.data['task_name'];
	var status_id=thisObj.data['task_name']+"_status";
	var icon_id=thisObj.data['task_name']+"_icon";
	var status=thisObj.data['status'];
	Ext.lib.Event.onAvailable(icon_id, function(){
		if(Ext.getCmp('nsync_icon_'+row_index))
		   Ext.destroy(Ext.getCmp('nsync_icon_'+row_index));
		   
		var nsync_icon = new Ext.Button({
			id:'nsync_icon_'+row_index,
			xtype:'button',
			iconCls:'start-icon',
			//icon:'/theme/images/default/grid/page-next.gif',
			//icon:'/theme/images/default/tree/loading.gif',
			value:'start',
			handler:function(v){
				var boxid=grid.getStore().getAt(row_index).get('task_name')+'_box';
				v.id=grid.getStore().getAt(row_index).get('task_name')+'_tmp';
				//if(v.value=='start'){
				if(thisObj.data['action']!="1"){
				        Ext.getDom('lock').value='1';
					//alert (thisObj.data['ip']);
					//alert (thisObj.data['folder']);
					v.value='stop';
					v.setIconClass('stop-icon');
					document.getElementById(boxid).disabled=true;
					Ext.getDom(boxid).checked=false;
					Ext.getDom(status_id).innerHTML="Start VPN";
					Ext.getDom(status_id).style.cursor="";
					Ext.getDom(status_id).onclick="";
					Ext.getDom('act').value='start';
					//alert (thisObj.data['task_name']);
					//processAjax("<{$geturl}>",setTime,"&action=start&process_name="+thisObj.data['task_name']);
					processAjax("<{$form_action}>",setTime,"&action=start&process_name="+encodeURIComponent(thisObj.data['task_name']));
					//alert (document.getElementById(current_id).value);
					//alert('1='+ Ext.getDom('lock').value);
				}else{
					//alert( Ext.getDom('lock').value);
				
				        Ext.getDom('lock').value='0';
					v.value='start';
					v.setIconClass('start-icon');
					document.getElementById(boxid).disabled=false;
					Ext.getDom('act').value='stop';
					clearTimeout(nsync_monitor);
					processAjax("<{$form_action}>",getLastStatus,"&action=stop&process_name="+encodeURIComponent(thisObj.data['task_name']));
				}
			},
			listeners: {
				render:{
					fn:function(r,c){
						var boxid=thisObj.data['task_name']+"_box";
						//alert (Ext.getDom('act').value);
						if(thisObj.data['action']=="1"){
							r.setIconClass('stop-icon');
							document.getElementById(boxid).disabled=true;
						}else{
							r.setIconClass('start-icon');
							document.getElementById(boxid).disabled=false;
						}
					}
				}
			},
			renderTo:icon_id
		});
	});
	return '<div id="'+icon_id+'"></div>';
}

var tbar =new Ext.Toolbar({
	id:'nsync_bar',
	items:[{
		id:'add_nsync',
		text:"<{$gwords.add}>",
		iconCls:'add',
		handler:function(){
			if(!Window_nsync.isVisible()){
				processAjax("<{$geturl}>",popupAddForm,"&action=add");
			}else{
				Window_nsync.toFront();
			}
		}
	}, '-',{
		id:'edit_nsync',
		text:"<{$gwords.edit}>",
		iconCls:'edit',
		handler:function(){
			var total = grid.getStore().getCount();
			var count = 0;
			var task_name="";
			for (var i=0;i<total;i++){
				boxid = grid.getStore().getAt(i).get('task_name')+'_box';
				if(Ext.getDom(boxid).checked){
					task_name=grid.getStore().getAt(i).get('task_name');
					count++;
				}
			}
			if(count==0 || count>1){
				Ext.Msg.alert("<{$words.nsync_title}>","<{$words.modify_confirm}>");
			}else{
				if(!Window_nsync.isVisible()){
					processAjax("<{$geturl}>",popupEditForm,"&action=edit&task_name="+encodeURIComponent(task_name));
				}else{
					Window_nsync.toFront();
				}
			}
		}
	}, '-',{
		id:'restore_nsync',
		text:"<{$gwords.restore}>",
		iconCls:'restore',
		handler:function(){
			var total = grid.getStore().getCount();
			var count = 0;
			var task_name="";
			var task_array="";
			for (var i=0;i<total;i++){
				boxid = grid.getStore().getAt(i).get('task_name')+'_box';
				iconid=grid.getStore().getAt(i).get('task_name')+'_icon';
				statusid=grid.getStore().getAt(i).get('task_name')+'_status';
				tmpid=grid.getStore().getAt(i).get('task_name')+'_tmp';
				if(Ext.getDom(boxid).checked){
					task_name=grid.getStore().getAt(i).get('task_name');
					task_array=task_name+String.fromCharCode(26)+task_array;
					Ext.getDom(boxid).disabled=true;
					Ext.getDom(statusid).innerHTML="Start VPN";
					Ext.getDom(statusid).style.cursor="";
					Ext.getDom(statusid).onclick="";
					Ext.getDom(iconid).innerHTML="";
					count++
				}
			}
			if(count==0){
				Ext.Msg.alert("<{$words.nsync_title}>","<{$words.modify_confirm}>");
			}
			Ext.getDom('act').value="restore";
			Ext.getDom('lock').value='1';
			processAjax("<{$form_action}>",setTime,"&action=restore&process_name="+encodeURIComponent(task_array));
		}
	}, '-',{
		id:'del_nsync',
		text:"<{$gwords.del}>",
		iconCls:'remove',
		handler:function(){
			var total = grid.getStore().getCount();
			var count = 0;
			var task_name="";
			var task_array="";
			for (var i=0;i<total;i++){
				boxid = grid.getStore().getAt(i).get('task_name')+'_box';
				iconid=grid.getStore().getAt(i).get('task_name')+'_icon';
				statusid=grid.getStore().getAt(i).get('task_name')+'_status';
				tmpid=grid.getStore().getAt(i).get('task_name')+'_tmp';
				if(Ext.getDom(boxid).checked){
					task_name=grid.getStore().getAt(i).get('task_name');
					//task_array=task_array+","+task_name;
					task_array=task_name+String.fromCharCode(26)+task_array;
					Ext.getDom(boxid).disabled=true;
					Ext.getDom(statusid).style.cursor="";
					Ext.getDom(statusid).onclick="";
					Ext.getDom(iconid).innerHTML="";
					count++
				}
			}
			if(count==0){
				Ext.Msg.alert("<{$words.nsync_title}>","<{$words.modify_confirm}>");
			}
			processAjax("<{$form_action}>",checkDel,"&action=delete&process_name="+encodeURIComponent(task_array));
		}
	}]
});

var nsync_trans_mode_radio = new Ext.form.RadioGroup({
	xtype: 'radiogroup',
	fieldLabel: "<{$words.nsync_manufacturer}>",
	width:420,
	items: [{
		boxLabel: 'NAS',
		name: 'manufacturer',
		checked:true,
		inputValue: 'thecus'
	},{
		boxLabel: "<{$words.nsync_other_device}>",
		name: 'manufacturer',
		inputValue: 'other'
	},{
		boxLabel: "<{$words.rsync_server}>",
		name: 'manufacturer',
		inputValue: 'rsync'
	}]
});

var nsync_mode_radio = new Ext.form.RadioGroup({
	fieldLabel: "<{$words.nsync_mode}>",
	width:650,
	columns:1,
	items: [{
		boxLabel: "<{$words.sync}> ( <{$words.sync_desc}> )",
		name: 'nsync_mode',
		checked:true,
		inputValue: '0'
	},{
		boxLabel: "<{$words.inc}> ( <{$words.inc_desc}> )",
		name: 'nsync_mode',
		inputValue: '1'
	}]
});

var nsync_schedule_radio = new Ext.form.RadioGroup({
	xtype: 'radiogroup',
	fieldLabel: "<{$gwords.enable}>/<{$gwords.disable}>",
	width:200,
	listeners: {change:{fn:function(r,c){
		if(c=='0'){
			schedule_time.setDisabled(true);
			schedule_time.setVisible(true);
			nsync_schedule_type_radio.setDisabled(true);
			week_combobox.setDisabled(true);
			day_combobox.setDisabled(true);
		}else{
			schedule_time.setDisabled(false);
			nsync_schedule_type_radio.setDisabled(false);
			week_combobox.setDisabled(false);
			day_combobox.setDisabled(false);
		}
	}}},
	items: [{
		boxLabel: "<{$gwords.enable}>",
		name: 'nsync_schedule',
		checked:true,
		inputValue: '1'
	},{
		boxLabel: "<{$gwords.disable}>",
		name: 'nsync_schedule',
		inputValue: '0'
	}]
});

var hidden_store= new Ext.data.SimpleStore({
	fields: <{$day_fields}>,
	data: <{$day_data}>
});

var hidden_combobox = new Ext.form.ComboBox({
	store:hidden_store,
	valueField :'value',
	displayField:'display',
	mode: 'local',
	forceSelection: true,
	editable: false,
	triggerAction: 'all',
	id: 'hide',
	name: 'hide',
	hiddenName:'_hide',
	hidden:true,
	disabled:true,
	width:50,
	listWidth :50
	//emptyText:'1'
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
	id: 'day',
	name: 'day',
	hiddenName:'days',
	width:50,
	listWidth :50
	//emptyText:'1'
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
	id: '_week',
	name: '_week',
	hiddenName:'week_day',
	listWidth :80,
	width:80
});

var nsync_schedule_type_radio = new Ext.form.RadioGroup({
	xtype: 'radiogroup',
	fieldLabel: "<{$words.nsync_type}>",
	width:300,
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
		boxLabel: "<{$words.nsync_type_d}>",
		name: 'nsync_type',
		checked:true,
		inputValue: 'daily'
	},{
		boxLabel: "<{$gwords.weekly}>",
		name: 'nsync_type',
		inputValue: 'weekly'
	},{
		boxLabel: "<{$gwords.monthly}>",
		name: 'nsync_type',
		inputValue: 'monthly'
	},
		hidden_combobox,
		week_combobox,
		day_combobox
	]
});

var folder_store=new Ext.data.JsonStore({
	fields:['folder_name'],
	data:<{$folder_list}>
});

var folder_combobox = new Ext.form.ComboBox({
	store:folder_store,
	fieldLabel:"<{$words.nsync_folder}>",
	valueField :'folder_name',
	displayField:'folder_name',
	mode: 'local',
	forceSelection: true,
	editable: false,
	triggerAction: 'all',
	disabled:false,
	id: 'folder',
	name: 'folder',
	listWidth :150,
	width:150
});

var folder1_combobox = new Ext.form.ComboBox({
	store:folder_store,
	fieldLabel:"<{$words.nsync_folder}>",
	valueField :'folder_name',
	displayField:'folder_name',
	mode: 'local',
	forceSelection: true,
	editable: false,
	triggerAction: 'all',
	id: 'folder1',
	name: 'folder1',
	listWidth :150,
	//emptyText:'<{$default_folder}>',
	hideMode:'offsets',
	hideLabel:true,
	hidden:true
});


var hour_store= new Ext.data.SimpleStore({
	fields: <{$hour_fields}>,
	data: <{$hour_data}>
});

var hour_combobox = new Ext.form.ComboBox({
	store:hour_store,
	fieldLabel:"<{$gwords.time}>",
	valueField :'value',
	displayField:'display',
	mode: 'local',
	forceSelection: true,
	editable: false,
	triggerAction: 'all',
	id: 'hour',
	name: 'hour',
	hiddenName:'hours',
	listWidth :50,
	//emptyText:'0',
	width:50
});

var min_store= new Ext.data.SimpleStore({
	fields: <{$min_fields}>,
	data: <{$min_data}>
});

var min_combobox = new Ext.form.ComboBox({
	store:min_store,
	valueField :'value',
	displayField:'display',
	mode: 'local',
	forceSelection: true,
	editable: false,
	triggerAction: 'all',
	id: 'min',
	name: 'min',
	hiddenName:'mins',
	listWidth :50,
	width:50
});

var test_btn = new Ext.Button({
	id:'test_btn',
	text:"<{$words.nsync_test}>",
	handler:function(){
		var action_tmp=Ext.getCmp('action').getValue();
		Ext.getCmp('action').setValue('test');

		if(tran_type==""){
		  processAjax("<{$geturl}>",updateTestMsg,FormPanel_nsync.getForm().getValues(true));
		}else{
		  processAjax("<{$geturl}>",updateTestMsg,FormPanel_nsync.getForm().getValues(true)+"&manufacturer="+tran_type);
	  }
		Ext.getCmp('action').setValue(action_tmp);
	}
});

var schedule_time = new Ext.form.TimeField({
		fieldLabel: "<{$gwords.time}>",
		mode: 'local',
		id: 'time',
		format:'H:i',
		increment:1,
		width:100
});

var FormPanel_nsync = new Ext.FormPanel({
	frame: true,
	labelAlign:'left',
	labelWidth:180,
	buttonAlign:'left',
	items: [{
		xtype:'fieldset',
		id:'popup_nsync_title',
		title:"<{$words.add_nsync_title}>",
		autoHeight:true,
		collapsed: false,
		items:[{
			xtype: 'textfield',
			id:'action',
			hideMode:'offsets',
			hidden:true,
			hideLabel:true,
			value:''
		},{
			xtype: 'textfield',
			id:'task_name',
			fieldLabel:"<{$gwords.task_name}>",
			value:''
		},{
			xtype: 'textfield',
			id:'task_name1',
			hideMode:'offsets',
			hidden:true,
			hideLabel:true,
			value:''
		},
			nsync_trans_mode_radio,
			nsync_mode_radio,
		{
			xtype: 'textfield',
			id:'ip',
			fieldLabel:"<{$words.nsync_server}>",
			value:''
		},
			folder_combobox,
			folder1_combobox,
		{
			xtype: 'textfield',
			id:'task_id',
			fieldLabel:"<{$words.nsync_id}>",
			value:''
		},{
			xtype: 'textfield',
			inputType:'password',
			id:'task_pwd',
			fieldLabel:"<{$words.nsync_pwd}>",
			value:''
		},{
			xtype: 'textarea',
			id:'nsync_test_msg',
			fieldLabel:"<{$words.nsync_test}>",
			width:400,
			readOnly:true,
			value:''
		},
			test_btn
		]
	},{
		xtype:'fieldset',
		title:"<{$gwords.schedule}>",
		autoHeight:true,
		//collapsed: false,
		items:[
			nsync_schedule_radio,
			//hour_combobox,
		{
			xtype: 'textfield',
			id:'crond',
			hidden:true,
			hideLabel:true,
			value:''
		},
			schedule_time,
			nsync_schedule_type_radio
		]
	}],
	buttons:[{
		id:'apply_btn',
		text:"<{$gwords.add}>",
		handler:function(v){
			//alert (Ext.getCmp('action').getValue());
			//alert (Ext.getCmp('time').getValue());
			if(Ext.getCmp('action').getValue()=='add'){
				Ext.getCmp('action').setValue('add');
				processAjax("<{$form_action}>",onLoadForm,FormPanel_nsync.getForm().getValues(true));
				//processAjax("<{$form_action}>",test,FormPanel_nsync.getForm().getValues(true));
			}else if(Ext.getCmp('action').getValue()=='edit'){
				Ext.getCmp('action').setValue('edit');
				processAjax("<{$form_action}>",onLoadForm,FormPanel_nsync.getForm().getValues(true)+"&manufacturer="+tran_type);
				//processAjax("<{$form_action}>",test,FormPanel_nsync.getForm().getValues(true));
			}
		}
	}]
});

function test(){
	var request = eval('('+this.req.responseText+')');
	alert (this.req.responseText);
}

var Window_nsync = new Ext.Window({
	closable:true,
	closeAction:'hide',
	width: 850,
	//autoHeight:500,
	height:550,
	draggable:false,
	autoScroll:true,
	modal: true,
	resizable:false,
	title:"<{$words.nsync_title}>",
	items: FormPanel_nsync
});

function popupAddForm(){
	var request = eval('('+this.req.responseText+')');
	if (request.task_name == '0'){
	       Ext.Msg.alert("<{$gwords.warning}>", "<{$words.nsync_task_limit}>");
	   return;  
	}
    
    Window_nsync.show();
	day_combobox.hide();
	week_combobox.hide();
	Ext.getCmp('popup_nsync_title').setTitle("<{$words.add_nsync_title}>");
	Ext.getCmp('apply_btn').setText("<{$gwords.add}>");
	Ext.getDom('task_name').value=request.task_name;
	Ext.getDom('task_name').disabled=false;
	Ext.getDom('action').value='add';
	nsync_trans_mode_radio.setValue('thecus');
	nsync_trans_mode_radio.setDisabled(false);
	nsync_mode_radio.setValue('0');
	Ext.getDom('ip').value="";
	folder_combobox.setValue('<{$default_folder}>');
	folder_combobox.setDisabled(false);
	Ext.getDom('task_id').value="";
	Ext.getDom('task_pwd').value="";
	Ext.getDom('nsync_test_msg').value="";
	nsync_schedule_radio.setValue('1');
	Ext.getDom('crond').value="00,00,*,*,*";
	Ext.getDom('time').value="00:00";
	Ext.getDom('time').disabled=false;
	nsync_schedule_type_radio.setValue('daily');
	nsync_schedule_type_radio.setDisabled(false);
	week_combobox.setValue('0');
	week_combobox.setDisabled(false);
	day_combobox.setValue('1');
	day_combobox.setDisabled(false);
	tran_type="";
}

function popupEditForm(){
	Window_nsync.show();
	var request = eval('('+this.req.responseText+')');
	Ext.getCmp('popup_nsync_title').setTitle("<{$words.edit_nsync_title}>");
	Ext.getCmp('apply_btn').setText("<{$gwords.modify}>");
	Ext.getDom('task_name').value=request.task_name;
	Ext.getDom('task_name').disabled=true;
	Ext.getDom('task_name1').value=request.task_name;
	Ext.getDom('action').value='edit';
	nsync_trans_mode_radio.setValue(request.manufacturer);	
	nsync_trans_mode_radio.setDisabled(true);
	tran_type=request.manufacturer;
	nsync_mode_radio.setValue(request.nsync_mode);
	Ext.getDom('ip').value=request.ip;
	folder_combobox.setValue(request.folder);
	folder1_combobox.setValue(request.folder);
	folder_combobox.setDisabled(true);
	Ext.getDom('task_id').value=request.username;
	Ext.getDom('task_pwd').value=request.passwd;
	Ext.getDom('nsync_test_msg').value="";
	nsync_schedule_radio.setValue(request.nsync_schedule);
	Ext.getDom('crond').value=request.crond;
	Ext.getDom('time').value=request.time;
	if(request.day!="*"){
		nsync_schedule_type_radio.setValue('monthly');
	}else if(request.week!="*"){
		nsync_schedule_type_radio.setValue('weekly');
	}
	var nsync_type=nsync_schedule_type_radio.getValue();
	if(nsync_type=='daily'){
		day_combobox.hide();
		week_combobox.hide();
		week_combobox.setValue('0');
		day_combobox.setValue('1');
	}else if(nsync_type=='weekly'){
		week_combobox.show();
		day_combobox.hide();
		week_combobox.setValue(request.week);
		day_combobox.setValue('1');
	}else if(nsync_type=='monthly'){
		week_combobox.hide();
		day_combobox.show();
		week_combobox.setValue('0');
		day_combobox.setValue(request.day);
	}
	if(request.nsync_schedule==0){
		Ext.getDom('time').disabled=true;
		nsync_schedule_type_radio.setDisabled(true);
		week_combobox.setDisabled(true);
		day_combobox.setDisabled(true);
	}
}

function updateTestMsg(){
	var request = eval('('+this.req.responseText+')');
	Ext.getDom('nsync_test_msg').value=request.nsync_test_msg;
}

function create_checkbox(v,cellmata,record,rowIndex){
	if(record.data['crond'].substring(0,1)!="#"){
		record.data['schedule']="<{$gwords.enable}>";
	}else{
		record.data['schedule']="<{$gwords.disable}>";
	}
	var mode;

	if(record.data['manufacturer']=="thecus"){
		mode="N";
	}else if(record.data['manufacturer']=="other"){
		mode="F";
	}else{
		mode="R";
	}

	if(record.data['nsync_mode']=="0"){
		mode=mode+"S";
	}else{
		mode=mode+"I";
	}

	var id=record.data["task_name"];
	return "<div><input type='checkbox' onclick='this.checked=(this.checked)?false:true;' name='"+id+"_box' id='"+id+"_box'>&nbsp;"+mode+"</div>";
}

function status_div(v,cellmata,record,rowIndex){
	var id=record.data["task_name"];
	var status;
	if(v=="Start VPN"){
		v="In Progress";
	}
	if(v=="In Progress"){
		status="<div id='"+id+"_status' style='cursor:pointer;' onclick='callProgressForm(\""+record.data['task_name']+"\");'>";
		status+="<span style='color:blue'>"+v+"</span>";
		status+="</div>";
		record.data['action']="1";
	}else{
		status="<div id='"+id+"_status' style='cursor:pointer;' onclick='callLogForm(\""+record.data['task_name']+"\");'>";
		status+="<span style='color:blue'>"+v+"</span>";
		status+="</div>";
		record.data['action']="0";
	}
	//return "<div id='"+id+"_status'>"+status+"</div>";
	return status;
}

var statusForm = new Ext.FormPanel({
	labelAlign:'left',
	buttonAlign:'left',
	frame: true,
	items:[{
		xtype:'fieldset',
		title:"<{$words.nsync_log_title}>",
		autoHeight:true,
		collapsed: false,
		defaults:{width: '230'},
		items:[{
			xtype: 'textfield',
			id:'status_task_name',
			fieldLabel:"<{$gwords.task_name}>",
			disabled:true,
			value:''
		},{
			xtype: 'textfield',
			id:'status_ip',
			fieldLabel:"<{$words.nsync_ip}>",
			disabled:true,
			value:''
		},{
			xtype: 'textfield',
			id:'status_start_time',
			fieldLabel:"<{$words.nsync_start_time}>",
			disabled:true,
			value:''
		},{
			xtype: 'textfield',
			id:'status_progress',
			fieldLabel:"<{$words.nsync_process_file}>",
			disabled:true,
			value:''
		},{
			xtype: 'textarea',
			id:'status_proceed',
			fieldLabel:"<{$gwords.status}>",
			disabled:true,
			value:''
		}]
	}]
});

var Window_progress = new Ext.Window({
	closable:true,
	closeAction:'hide',
	width: 400,
	draggable:false,
	autoHeight:true,
	modal: true,
	resizable:false,
	title:"<{$words.nsync_title}>",
	items:statusForm,
	listeners: {
		hide:{
			fn:function(r,c){
				clearTimeout(nsync_status_monitor);
			}
		}
	}
});

/*
Window_progress.on('hide',function(e){
	clearTimeout(nsync_status_monitor);
});
*/

function callProgressForm(task){
	var boxid=task+"_box";
	Ext.getDom(boxid).checked=true;
	//alert (task);
	if(!Window_progress.isVisible()){
		Window_progress.show();
		//nsync_status_monitor = setInterval("processAjax('<{$geturl}>&action=getprogress&task_name="+task+"',popupProgressForm)",10000);
		processAjax('<{$geturl}>&action=getprogress&task_name='+encodeURIComponent(task),popupProgressForm);
	}else{
		Window_progress.toFront();
	}
}

function popupProgressForm(){
	var request = eval('('+this.req.responseText+')');
	//alert (this.req.responseText);
	var close=request.close;
	var task=request.task_name;
	//alert (close);
	if(close=="1"){
		clearTimeout(nsync_status_monitor);
		Window_progress.hide();
	}else{
		nsync_status_monitor = setTimeout("processAjax('<{$geturl}>&action=getprogress&task_name="+encodeURIComponent(task)+"',popupProgressForm)",10000);
	}
	Ext.getDom('status_task_name').value=request.task_name;
	Ext.getDom('status_ip').value=request.ip;
	Ext.getDom('status_start_time').value=request.start_time;
	Ext.getDom('status_progress').value=request.task_progress;
	Ext.getDom('status_proceed').value=request.proceed;
}

function callLogForm(task){
	var boxid=task+"_box";
	Ext.getDom(boxid).checked=true;
	popupLogForm(task);
	/*
	if(!Window_log.isVisible()){
		processAjax("<{$geturl}>&"+Math.random(99),popupLogForm,"&action=getlog&task_name="+task+'&'+Math.random(999));
	}else{
		Window_log.toFront();
	}
	*/
	//popupLogForm();
	//alert ('task = '+task);
}

var nsync_log_store = new Ext.data.JsonStore({
	storeId:'nsync_log_store',
	root:'log_data',
	totalProperty: 'total_count',
	idProperty: 'log_msg',
	fields:[
		'log_msg'
	],
	url: '<{$geturl}>&action=getlog'
});

var pagingBar = new Ext.PagingToolbar({
	pageSize: page_limit,
 	store: nsync_log_store,
 	displayInfo: true,
 	beforePageText:"<{$gwords.page1}>",
 	afterPageText:"<{$gwords.page2}> {0} <{$gwords.page3}> "
});

var GridFormLog = new xg.GridPanel({
	id:'nsync_log',
	disableSelection:false,
	store:nsync_log_store,
	cm: new xg.ColumnModel([
		{header: "", width: 650, sortable: true, dataIndex: 'log_msg'}
	]),
	width:680,
	height:340,
	bbar: pagingBar,
	loadMask:true
});


var Window_log = new Ext.Window({
  id:'Window_log',
  closable:true,
	closeAction:'hide',
	width: 700,
	draggable:false, 
	autoHeight:true,
	modal: true,
	resizable:false,
	title:'<{$words.nsync_title}>',
	items: GridFormLog,
	buttonAlign:'left'
});

function popupLogForm(task){
	Window_log.show();
	nsync_log_store.proxy.conn.url='<{$geturl}>&action=getlog&task_name='+encodeURIComponent(task);
	nsync_log_store.load({params:{start:0, limit:page_limit}});
}


var nsync_store = new Ext.data.JsonStore({
	storeId:'nsync_store',
	config:{
		pruneModifiedRecords:true
	},
	fields:[
		'task_name','manufacturer','ip','folder','username','passwd','crond','status','end_time','nsync_mode','schedule','action'
	],
	data: <{$nsync}>
});

var bandwidth_store=new Ext.data.SimpleStore({
	fields:<{$bandwidth_fields}>,
	data:<{$bandwidth_data}>
});
                
var bandwidth_combobox=new Ext.form.ComboBox({
	fieldLabel:'<{$words.nsync_qos}>',
	frame:true,
	store:bandwidth_store,
	valueField :'value',	
	displayField:'display',
	mode: 'local',
	forceSelection: true,
	editable: false,
	triggerAction: 'all',
	id: 'band_wdith',
	name: 'band_width',
	listWidth :100,
	width: 100,
	listeners:{
		select:function(v){
			Ext.Msg.confirm("<{$words.nsync_title}>","<{$gwords.confirm}>",function(btn){
				if(btn=='yes'){
					processAjax("<{$form_action}>",onLoadForm,"&action=qos&bandwidth="+v.value);
				}
			})
		}
	}
});

var grid = new xg.GridPanel({
	id:'nsync_item',
	disableSelection:false,
	store:nsync_store,
	enableHdMenu:false,
	cm: new xg.ColumnModel([
		//sm,
		{
			header: "<input type='checkbox' onclick='selectAll(this)'>",
			width:45,
			menuDisabled:true,
			renderer:create_checkbox
		},
		{header: "<{$gwords.task_name}>", width: 80, sortable: true, dataIndex: 'task_name'},
		{header: "<{$words.nsync_target}>", width: 80, sortable: true, dataIndex: 'ip'},
		{header: "<{$words.nsync_folder}>", width: 120, sortable: true, dataIndex: 'folder'},
		{header: "<{$words.nsync_time}>", width: 90, sortable: true,dataIndex: 'end_time'},
		{header: "<{$words.nsync_status}>", width: 120, sortable: true,renderer:status_div, dataIndex: 'status'},
		{header: "<{$gwords.schedule}>", width: 60, sortable: false, dataIndex: 'schedule'},
		{header: "<{$words.nsync_action}>", width: 50, height :50, renderer:geticon, dataIndex: 'action'}
	]),
	listeners:{
		rowclick:function(gridObj,rowIndex,event){
			var boxid=gridObj.getStore().getAt(rowIndex).get('task_name')+'_box';
			if(Ext.getDom(boxid).checked){
				Ext.getDom(boxid).checked=false;
			}else{
				if(!Ext.getDom(boxid).disabled){
					Ext.getDom(boxid).checked=true;
				}
			}
		}
	},
	//sm: sm,
	width:<{if $lang=='fr' || $lang=='de'}>590<{else}>650<{/if}>,
	//height:500,
	autoHeight:true,
	authWidth:true,
	//frame:true,
	//title:'Framed with Checkbox Selection and Horizontal Scrolling',
	//iconCls:'icon-grid',
	tbar:tbar
	//bbar: nsync_pagingBar,
//	bbar: bandwidth_combobox,
	//bbar: tbar2,
	//renderTo: 'nsync_form'
});

var GlobalFormPanel = new Ext.FormPanel({
	frame: true,
	labelAlign:'left',
	labelWidth:180,
	buttonAlign:'left',
	items: [
		grid,
		bandwidth_combobox
	],
	renderTo:'nsync_form'
});

function setTime(){
	clearTimeout(nsync_monitor);
	//var request = eval('('+this.req.responseText+')');
	//alert (this.req.responseText);
	//nsync_monitor = setInterval(call_getStatus,10000);
	call_getStatus();
}

function call_getStatus(){
	if(Ext.getDom('act')){
			action=Ext.getDom('act').value;
			//alert (action);
		  if(Ext.getDom('lock').value=='1'){
				//processAjax("<{$geturl}>&action="+action,getStatus);
				processAjax("<{$geturl}>&action=start",getStatus);
			}else{
		    Ext.getDom('act').value="";
			}
  }
}

function getStatus(){
	var request = eval('('+this.req.responseText+')');
	//alert (this.req.responseText);
	
	//alert (request.nsync_status[3]['action']);
	//alert (request.nsync_flag);
	if(request.nsync_flag==1){
		if(Ext.getDom('act')){
			nsync_store.loadData(request.nsync_status);
    	Ext.getDom('act').value="";
  	}
		clearTimeout(nsync_monitor);
	}else{
		nsync_store.loadData(request.nsync_status);
		nsync_monitor = setTimeout(call_getStatus,10000);
	}
	//alert (this.req.responseText);
}

if(nsync_monitor==null){
	clearTimeout(nsync_monitor);
}

Ext.getDom('lock').value="1";
//setTime();
processAjax("<{$geturl}>&action=start",getStatus);

bandwidth_combobox.setValue('<{$bandwidth}>');
<{if ($ipshare_enabled=="0")}>
	bandwidth_combobox.setDisabled(true);
<{/if}>
</script>
<fieldset class="x-fieldset"><legend class="legend"><{$words.nsync_title}></legend>
<div id="nsync_form"></div>
<input type='hidden' name='lock' id='lock' value='0' />
<input type='hidden' name='act' id='act' value='' />
