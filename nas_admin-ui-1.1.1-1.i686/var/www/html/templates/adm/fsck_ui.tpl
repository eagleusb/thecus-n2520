<script language"javascript">
Ext.QuickTips.init();

var xg = Ext.grid;
var fsck_monitor;
var status_monitor;
var item_monitor;

var sm = new xg.CheckboxSelectionModel({
	width:20
});

FSCK_LIST = <{$fsck_list}>;

function change_color(val){
	if(val=='Healthy' || val=='Normal')
		return '<b><span style="color:green;">'+val+'</span></b>';
	else if(val=='Degraded')
		return '<b><span style="color:blue;">'+val+'</span></b>';
	else
		return '<b><span style="color:red;">'+val+'</span></b>';
}

var FormPanel_fsck = new Ext.FormPanel({
	frame: true,
	labelAlign:'left',
	labelWidth:180,
	items: [{
		xtype:'fieldset',
		title:'<{$words.fsck_title}>',
		autoHeight:true,
		//height:450,
		//defaults: {width: 210},
		collapsed: false,
		items :[{
			 xtype: 'textfield',
			 id:'fsck_status',
			 width:450,
			 fieldLabel:'<{$gwords.status}>',
			 value:'<{$words.press_start}>',
			 disabled:true
		},{
			xtype:'textarea',
			id: 'fsck_info',
			name:'fsck_info',
			fieldLabel:'<{$words.latest20info}>',
			width:450,
			height:320,
			//value:'a\nb\nc\nb\nc\nb\nc\nb\nc\nb\nc\nb\nc\nb\nc\nb\nc\nb\nc\nb\nc\nb\nc\nb\nc\nb\nc\nb\nc\nb\nc\nb\nc\nb\nc\nb\nc\nb\nc\nb\nc',
			value:'',
			readOnly:true,
			config:{
				preventScrollbars:false
			}
		},{
			xtype:'textarea',
			id: 'fsck_result',
			name:'fsck_result',
			fieldLabel:'<{$gwords.result}>',
			width:450,
			height:65,
			//value:'a\nb',
			value:'',
			readOnly:true
		}]
	}],
	buttons:[{
		id:'start_btn',
		text:'<{$gwords.start}>',
		handler:function(v){
			//alert (document.getElementById('reboot_btn').value);
			if(v.text=='<{$gwords.start}>'){
				v.setText('<{$gwords.stop}>');
				Ext.getCmp('reboot_btn').setDisabled(true);
				//Ext.getCmp('close_btn').setDisabled(true);
				Ext.getDom('fsck_status').value='<{$gwords.wait_msg}>';
				processAjax("<{$form_action}>",set_time,"&action=start");
			}else if(v.text=='<{$gwords.stop}>'){
				Ext.Msg.confirm("<{$words.fsck_title}>","<{$words.stop_confirm}>",function(btn){
						if(btn=="yes"){
							v.setText('<{$gwords.start}>');
							Ext.getCmp('reboot_btn').setDisabled(false);
							//Ext.getCmp('close_btn').setDisabled(false);
							processAjax("<{$form_action}>",onLoadForm,"&action=stop");
						}
					}
				);
			}
		}
	},{
		id:'reboot_btn',
		text:'<{$gwords.reboot}>',
		handler:function(){
			Ext.Msg.confirm("<{$words.fsck_title}>","<{$words.reboot_confirm}>",function(btn){
					if(btn=="yes"){
						processAjax("<{$form_action}>",onLoadForm,"&action=reboot");
					}
				}
			);
		}
	}],
	buttonAlign:'left'
});

var Window_fsck= new Ext.Window({
	closable:true,
	closeAction:'hide',
	width: 700,
	autoHeight:500,
	modal: true,
	resizable:false,
	//autoScroll:true,
	items: FormPanel_fsck
});


function usageTipFormat(disks) {
    disks.sort();
    var tip = '';
    var loc;
    for( var i = 0 ; i < disks.length ; ++i ) {
        var disk = disks[i];
        var cur = disk.match(/J[0-9]+/) || [];
            cur = cur[0];
        if( loc != cur ) {
            loc = cur;
            tip += '<br>' + disk + ' ';
            continue;
        }
        tip += disk + ' ';
    }
    return tip;
}
                                                                                                            
function diskUsageTip(value, metadata) {
    var all = value.split(',');
    var used = [];
    var spare = [];
    for( var i = 0 ; i < all.length ; ++i ) {
        if( /span/.test(all[i]) ) {
             var s = all[i].match(/.*>(.*)<.*/);
             spare.push(s[1]);
        } else {
             used.push(all[i]);
        }
    }
    var title = "<{$rwords.Raid_disk_used}>:".replace('<br>', ' ');
    var tip = title + '<br>' + usageTipFormat(used);
    spare = spare || [];
    if( spare.length > 0 ) {
        tip += String.format('<br>{0}<br>', "<{$rwords.spare}>:");
        tip += '<span style=\'color:gray\'>';
        tip += usageTipFormat(spare);
        tip += '</span>';
    }
    metadata.attr = 'ext:qtip="' + tip + '"ext:qwidth="auto" ext:qheight="auto"';
    return value;
}

var grid = new xg.GridPanel({
	id:'fsck_item',
	store: new Ext.data.JsonStore({
		storeId:'fsck_store',
		fields:[
			'md_num','raid_level','raid_id','filesystem','disks','raid_status','fs_status','capacity','fsck_last_time'
			//{name:'fsck_last_time', type: 'date', dateFormat: 'n/j h:ia'}
		],
		//reader: reader,
        data: FSCK_LIST,
        listeners: {
            load: function(){
                for(var i=0 ; i < this.data.items.length ; i++) {
                    if ( this.data.items[i].data.raid_status == "" && typeof status_monitor == 'undefined' ) {
                        set_status_monitor();
                        return;
                    }
                }
                if( status_monitor ) {
                    clearInterval(status_monitor);
                    delete monitor_status;
                }
            }
        }
	}),
	cm: new xg.ColumnModel([
		sm,
		{id:'md_num',header: "<{$words.Raid_level}>", width: 100, sortable: true, dataIndex: 'raid_level'},
                {header: "<{$rwords.Raid_id}>", width: 120, sortable: true, dataIndex: 'raid_id'},
		{header: "<{$rwords.filesystem}>", width: 120, sortable: true, dataIndex: 'filesystem'},
		{header: "<{$words.Raid_disk_used}>", width: 120, sortable: true, dataIndex: 'disks', renderer: diskUsageTip},
		{header: "<{$gwords.status}>", width: 120, sortable: true, renderer:change_color, dataIndex: 'raid_status'},
		{header: "<{$words.FS_status}>", width: 120, sortable: true,dataIndex: 'fs_status'},
		{header: "<{$words.Raid_data}>", width: 120, sortable: true, dataIndex: 'capacity'},
		//{header: "Last Updated", width: 135, sortable: true, renderer: Ext.util.Format.dateRenderer('Y/d/m h/i/s'), dataIndex: 'last_time'}
		{header: "<{$words.Last_Time}>", width: 135, sortable: true, dataIndex: 'fsck_last_time'}
	]),
	buttons: [{
		text:'<{$gwords.next}>',
		handler: function(){
			//var a=document.getElementById('batch_file').value;
			var item=grid.getSelections();
			if(item.length > 0){
				if(!Window_fsck.isVisible()){
					var seltext = '';
					var sels = grid.getSelectionModel().getSelections();
					for( var i = 0; i < sels.length; i++ ) {
						seltext += sels[i].get('md_num') + ",";
				        }
				        seltext = seltext.substring(0,(seltext.length-1));
				        //Ext.Msg.alert('Selected', seltext);
					processAjax("<{$form_action}>",popup_Form,"&action=next&md_num="+seltext);
				}else{
					Window_fsck.toFront();
				}
			}else{
				Ext.Msg.alert('<{$words.fsck_title}>', '<{$words.fsck_no_selected}>');
			}
		}
	},{
		text:'<{$gwords.reboot}>',
		handler:function(){
			Ext.Msg.confirm("<{$words.fsck_title}>","<{$words.reboot_confirm}>",function(btn){
					if(btn=="yes"){
						processAjax("<{$form_action}>",onLoadForm,"&action=reboot");
					}
				}
			);
		}
	}],
	buttonAlign:'left',
        sm: sm,
        width:920,
        height:300,
        //frame:true,
        //title:'Framed with Checkbox Selection and Horizontal Scrolling',
        //iconCls:'icon-grid',
        renderTo: 'fsck_ui_form'
});
function popup_Form(){
    Window_fsck.show();
}

function set_status_monitor() {
    status_monitor = setInterval(monitor_status,3000);
}

function monitor_status(){
    processAjax("<{$geturl}>&action=getstatus",change_status);
}

function change_status(){
    var request = eval('('+this.req.responseText+')');
    Ext.getCmp('fsck_item').store.loadData(request);
}

function set_time(){
	fsck_monitor = setInterval(monitor_fsck,3000);
}
function monitor_fsck(){
	processAjax("<{$geturl}>&action=getlog",change_fsck);
	//Ext.getDom('fsck_status').value="aaa";
}
function change_fsck(){
	//Ext.getDom('fsck_status').value="aaa";
	var request = eval('('+this.req.responseText+')');
	//var rows = grid.getSelectionModel().getSelected();
	if(request.fsck_status!=""){
		Ext.getDom('fsck_status').value=request.fsck_status;
	}
	Ext.getDom('fsck_info').value=request.fsck_info;
	if(request.fsck_result!=""){
		Ext.getDom('fsck_result').value=request.fsck_result;
	}
	//Ext.getDom('fsck_result').value+="lock = "+request.fsck_lock;
	if(request.fsck_lock!='1'){
		//Ext.getCmp('start_btn').text='<{$gwords.start}>';
		Ext.getCmp('start_btn').setText('<{$gwords.start}>');
		Ext.getCmp('reboot_btn').setDisabled(false);
		//Ext.getCmp('close_btn').setDisabled(false);
		//alert (Ext.getCmp('start_btn').text);
		clearTimeout(fsck_monitor);
	}
	//Ext.getDom('fsck_status').value="<{$fsck_status}>";
}
function check_item(){
	var sels = grid.getStore();
	grid.getSelectionModel().selectRows('<{$fsck_dev}>');
	//grid.getSelectionModel().selectRows('0');
	if(grid.getSelectionModel().getSelections().length != ''){
		clearTimeout(item_monitor);
	}
}
<{if $fsck_lock=="1"}>
	item_monitor = setInterval(check_item,3000);
	popup_Form();
	Ext.getDom('fsck_status').value='<{$gwords.wait_msg}>';
	Ext.getCmp('start_btn').setText('<{$gwords.stop}>');
	Ext.getCmp('reboot_btn').setDisabled(true);
	//Ext.getCmp('close_btn').setDisabled(true);
	set_time();
<{/if}>
</script>

<fieldset class="x-fieldset"><legend class="legend"><{$words.fsck_title}></legend>
<{if $fs_zfs==1}>
	<div><span style="color:red"><{$words.fsck_limit_fs}><br><br></span></div>
<{/if}>
<div id="fsck_ui_form"></div>
