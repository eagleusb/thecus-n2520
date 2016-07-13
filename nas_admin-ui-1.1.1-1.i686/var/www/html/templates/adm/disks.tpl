<form name="disk" id="disk" method="post">
<input type="hidden" name="disk_no" id="disk_no" value="">
<input type="hidden" name="smartdev" id="smartdev" value="<{$smartdev}>">
<input type="hidden" name="disk_type" id="disk_type" value="">
<input type="hidden" name="usb_id" id ="usb_id" value="">
<input type="hidden" name="disk_id" id ="disk_id" value="">
</form>

<form name="eject_usb" id="eject_usb">
<input type="hidden" name="usb_disk_no" id="usb_disk_no" value="">
<input type="hidden" name="ej_usb_id" id="ej_usb_id" value="">
</form>

<form name="smart" id="smart" method="post">
<input type=hidden name="smart_status" id="smart_status" value="">
<input type=hidden name="diskno" id="diskno" value="">
<input type=hidden name="trayno" id="trayno" value="">
<input type=hidden name="smartdev" id="smartdev" value="<{$smartdev}>">
<input type=hidden name="stype" id="stype" value="">
</form>


<script type="text/javascript">
var update_flag;
var smart_update_flag;
var show_smart_flag;
var disk_power_data=<{$disk_power_data}>;

var disks_ct = {};
function onComponentReady(ct){
    if (ct.cname) {
        disks_ct[ct.cname] = ct;
    }
}
function onPanelTextUpdate (value){
    if (this.cname){
        this.getEl().dom.innerHTML = value;
    }
}

/*
* update disks info .
* @param none
* @returns none.
*/    
function update_data(){
  if(replaceStr(this.req.responseText)!=""){
    var request = eval("("+replaceStr(this.req.responseText)+")"); 
    if(update_flag !=null)
      clearTimeout(update_flag);
    
    if(TCode.desktop.Group.page==='disks'){
      disk_info.load(request.disk_data);
      edisk_store.loadData(request.edisk_data);
      usb_store.loadData(request.usb_data);
      if(disks_ct.total)
        disks_ct.total.setText('<{$words.total}>: '+request.disk_total_capacity);
      if(request.usb_count==0){      
        if(disks_ct.usb_info_frame)
            disks_ct.usb_info_frame.hide();
      }else{
        if(disks_ct.usb_info_frame)
            disks_ct.usb_info_frame.show();
      }
      if(request.edisk_count==0){ 
        if(disks_ct.edisk_info_frame)
            disks_ct.edisk_info_frame.hide();
      } else{ 
        if(disks_ct.edisk_info_frame)
            disks_ct.edisk_info_frame.show();
      }      
       update_flag=setTimeout("processAjax('getmain.php?fun=disks&update=1',update_data)",10*1000);
    } 
  }else{
    if(update_flag !=null)
      clearTimeout(update_flag);
      
    update_flag=setTimeout("processAjax('getmain.php?fun=disks&update=1',update_data)",10*1000);
  }  
}


/*
* disk bad block execute success to change disk info.
* @param none
* @returns none.
*/  
function update_disk_status(){    
  var request = eval('('+this.req.responseText+')');
  clearTimeout(update_flag);
  
  if(request.show){
    mag_box(request.topic,request.message,request.icon,request.button,request.fn,request.prompt);
  }    
  
  processAjax('getmain.php?fun=disks&update=1',update_data);
  
}

/*
* when after smart execute to smart test, smart test data status will monitor.
* @param none
* @returns none.
*/  
function update_smart_data(){
  if(smart_update_flag !=null)
    clearTimeout(smart_update_flag);
    
  if(TCode.desktop.Group.page==='disks'){
  
    if(document.getElementById('smart_status').value==1)
      if(document.getElementById('diskno'))
        eval("smart_display('"+document.getElementById('diskno').value+"','"+document.getElementById('trayno').value+"')");        
    else
      clearTimeout(smart_update_flag);
  }
}

/*
* when disk smart test execute success to change smart info.
* @param none
* @returns none.
*/
function update_smart_status(){
  var request = eval('('+this.req.responseText+')'); 
  
  if(smart_update_flag!=null)  
    clearTimeout(smart_update_flag);
  
  if(request.show){
    mag_box(request.topic,request.message,request.icon,request.button,request.fn,request.prompt);
  }else{    
    if(document.getElementById('diskno') && document.getElementById('trayno'))
      eval("smart_display('"+document.getElementById('diskno').value+"','"+document.getElementById('trayno').value+"')");
  }
}
  

/*
* eject usb disk success and change disk status.
* @param none
* @returns none.
*/    
function eject_ok(){
  var request = eval('('+this.req.responseText+')'); 
  clearTimeout(update_flag);
  mag_box(request.topic,request.message,request.icon,request.button,request.fn,request.prompt);
  processAjax('getmain.php?fun=disks&update=1',update_data);
}

/*
* start disk bad block scan .
* @param val:  disk mount number
* @param types:disk type(usb disk or not)
* @param usb_id:usb disk number
* @returns none.
*/
function start_badblock(val,types,usb_id,status,disk_id){
  document.disk.disk_no.value=val;
	document.disk.disk_type.value=types;
	document.disk.usb_id.value=usb_id;
	document.disk.disk_id.value=disk_id;
	if(document.getElementById('diskno'))
	  processAjax('setmain.php?fun=setdisks',update_disk_status,document.getElementById('disk'));  
}

/*
* execute disk bad block scan .
* @param val:  disk mount number
* @param types:disk type(usb disk or not)
* @param usb_id:usb disk number
* @returns none.
*/
function block_scan(val,types,usb_id,status,disk_id){
  if(status==0){
    Ext.Msg.show({
       title:"<{$words.disk_scan_title}>",
       msg: "<{$words.block_warning}>",
       buttons: Ext.Msg.OK,
       width: '280',
       icon: Ext.MessageBox.INFO,
       fn:function(btn){
         if(btn=='ok'){ 
            start_badblock(val,types,usb_id,status,disk_id);
            disks_ct.tbar_badblock.setDisabled(true);
            disks_ct.tbar_badblockstop.setDisabled(true);
            disks_ct.tbar_smart.setDisabled(true);
         }
      }  
    });
  }else{
    start_badblock(val,types,usb_id,status,disk_id); 
 }
}

/*
* execute usb disk eject.
* @param val: disk mount number
* @param usb_id:eject usb disk number
* @returns none.
*/
function eject(val,usb_id){
  document.eject_usb.usb_disk_no.value=val;
  document.eject_usb.ej_usb_id.value=usb_id;
  if(document.getElementById('eject_usb'))
    processAjax('setmain.php?fun=setejectusb',eject_ok,document.getElementById('eject_usb'));
}

/*
* update and set smart status and info.
* @param none.
* @returns none.
*/
function setSmartPanel(){
  if(this.req.responseText!=""){
    var request = eval("("+replaceStr(this.req.responseText)+")"); 
    if(TCode.desktop.Group.page==='disks'){
      if(show_smart_flag==1){
        Window_smart.show();
      }
      disks_ct.stray_no.setHTML(request.tray_no);
      disks_ct.smodel.setHTML(request.model);
      disks_ct.smart_attr9.setHTML(request.ATTR9);
      var c = Number(request.ATTR194);
      c = isNaN(c) ? 0 : c;
      var f = (c*9)/5+32;
      var output = String.format('{0}&#176;C/{1}&#176;F', c, f);
      disks_ct.smart_attr194.setHTML(output);
      disks_ct.smart_attr5.setHTML(request.ATTR5);
      disks_ct.smart_attr197.setHTML(request.ATTR197);
      disks_ct.smart_attr184.setHTML(request.ATTR184);
      c = Number(request.ATTR194_old);
      c = isNaN(c) ? 0 : c;
      f = (c*9)/5+32;
      output = String.format('{0}&#176;C/{1}&#176;F(<{$words.last}>)', c, f);
      disks_ct.smart_attr194_old.getEl().dom.innerHTML = output;
      disks_ct.smart_attr5_old.setHTML(request.ATTR5_old+'(<{$words.last}>)');
      disks_ct.smart_attr197_old.setHTML(request.ATTR197_old+'(<{$words.last}>)');
      disks_ct.smart_attr184_old.setHTML(request.ATTR184_old+'(<{$words.last}>)');
      disks_ct.test_result.setHTML(request.smart_result);
      disks_ct.test_time.setHTML(request.smart_test_time);
      sbutton.setText(request.test_button);
      type_radio.setValue(request.test_type);
      if(document.getElementById('smart_status'))
        document.getElementById('smart_status').value=request.smart_status;
      if(request.smart_status==1)
        type_radio.setDisabled(true);
      else
        type_radio.setDisabled(false);
      if(document.getElementById('stype'))
        document.getElementById('stype').value=request.test_type;    
      if(document.getElementById('diskno'))
        document.getElementById('diskno').value=request.diskno;
      if(document.getElementById('trayno'))
        document.getElementById('trayno').value=request.tray_no;      
      if(request.disk_type==1){
        Window_smart.setSize(450,230);
      } else {     
        Window_smart.setSize(450,420);
      }
    
      if(request.smart_status ==1)
        smart_update_flag=setTimeout("update_smart_data()",10*1000);
      if(show_smart_flag==1){
        myMask.hide();
      }
    }
  }else{
    if(smart_update_flag !=null)
      clearTimeout(smart_update_flag);
    smart_update_flag=setTimeout("update_smart_data()",10*1000);
  }  
}

/*
* show this disk smart status and info.
* @param diskno:disk mount number.
* @param trayno:disk tray number.
* @returns none.
*/
function smart_display(diskno,trayno){
  if(update_flag !=null)
    clearTimeout(update_flag);
  
  processAjax('getmain.php?fun=smart&diskno='+diskno+'&trayno='+trayno,setSmartPanel);
}

/*
* show bad block icon style.
* @param value:bad block status.
* @param obj:.
* @param thisobj:disk grid object.
* @returns none.
*/
function buttonRenderer(value,obj,thisobj){
  var usb_id;
  if(value=='N/A')
  { 
    return String.format('{0}',value);
  }else{
    if(value=='0') 
      return String.format('<a href="javascript:void(0);" onclick="javascript:block_scan(\'{0}\',{1},{2},{3},{4})"><img src="<{$urlimg}>/default/grid/page-next.gif" align="absmiddle"></a>&nbsp;&nbsp;  '+thisobj.data['b_status'],thisobj.data['diskno'],thisobj.data['disk_type'],(thisobj.data['trayno']-thisobj.data['usb_sindex']+1),value,thisobj.data['trayno']);
    else  
      return String.format('<a href="javascript:void(0);" onclick="javascript:block_scan(\'{0}\',{1},{2},{3},{4})"><img src="<{$urlimg}>/default/sizer/square.gif" align="absmiddle"></a>&nbsp;&nbsp;  '+thisobj.data['b_status'],thisobj.data['diskno'],thisobj.data['disk_type'],(thisobj.data['trayno']-thisobj.data['usb_sindex']+1),value,thisobj.data['trayno']);
  }    
}

/*
* show usb disk eject icon style.
* @param value: eject value
* @param obj:.
* @param thisobj:usb grid object.
* @returns none.
*/
function ejectbutton(value,obj,thisobj){
  return String.format('<a href="javascript:void(0);" onclick="javascript:eject(\'{0}\',{1})"><img src="<{$urlimg}>/icons/fam/delete.gif"></a>',thisobj.data['diskno'],(thisobj.data['trayno']-thisobj.data['usb_sindex']+1));
}     

/*
* show disk smart status style.
* @param value: disk smart status
* @param obj:.
* @param thisobj:sata or esata grid object.
* @returns none.
*/     
function smartRenderer(value,obj,thisobj){
  if(value!='N/A')
    return String.format('<a href="javascript:void(0);" onclick="javascript:myMask.show();smart_display(\'{0}\',{1});show_smart_flag=1;"><img src="<{$urlimg}>/icons/fam/cog.png" align="absmiddle">&nbsp;&nbsp;&nbsp;<{$gwords.detect}></a>',thisobj.data['diskno'],thisobj.data['trayno'],value);
  else
    return String.format('{0}',value);  
}

//esata disk info
var edisk_store= new Ext.data.JsonStore({
  fields: [{name:'trayno', type:'int'},'capacity','model','linkrate','fireware','s_status','b_status','badblock','diskno','disk_type',{name:'usb_sindex' ,type:'int'}],
  data: <{$edisk_data}>    
});

//usb disk info
var usb_store= new Ext.data.JsonStore({
  fields: [{name:'trayno', type:'int'},'capacity','model','fireware','s_status','b_status','badblock','diskno','disk_type',{name:'usb_sindex' ,type:'int'}],
  data: <{$usb_data}>
});
  
//disk info grid    
var disk_info = new TCode.ux.Disk({
    disableSelection: false,
    width: 700,
    height: 320,
    frame: false,
    tbar: [
        {
            xtype: 'button',
            text: '<{$words.smart}>',
            iconCls: 'smart',
            cname: 'tbar_smart',
            tooltip: '<{$words.smart_tip}>',
            disabled: true,
            handler: function(){
                var rs = disk_info.getDiskSelected();
                if( typeof rs == 'undefined' ) {
                    return;
                }
                myMask.show();
                show_smart_flag=1;
                var disk = rs.data.product_no == 0 ? rs.data.disk_no : 'J' + rs.data.product_no + '-' + rs.data.disk_no;
                smart_display(rs.data.partition_no, disk);
                disks_ct.tbar_badblock.setDisabled(true);
                disks_ct.tbar_badblockstop.setDisabled(true);
                disks_ct.tbar_smart.setDisabled(true);
                delete rs;
            }
        },
        {
            xtype: 'button',
            cname:'tbar_badblock',
            text: '<{$words.bad_scan}>',
            tooltip: '<{$words.detect_bad_tip}>',
            iconCls:'resume',
            disabled:true,
            handler: function(){
                var rs = disk_info.getDiskSelected();
                disk_state = rs.data.status.state;
                if( typeof rs == 'undefined' ) {
                    return;
                }
                block_scan(
                    rs.data.partition_no,
                    0,
                    '',
                    '',
                    rs.data.tray_no
                );
                delete rs;
            }
        },
        {
            xtype: 'button',
            cname:'tbar_badblockstop',
            text: '<{$words.bad_scan_stop}>',
            tooltip: '<{$words.detect_bad_stop_tip}>',
            iconCls:'stop',
            disabled:true,
            handler: function(){
                var rs = disk_info.getDiskSelected();
                disk_state = rs.data.status.state;
                if( typeof rs == 'undefined' ) {
                    return;
                }
                Ext.Msg.show({
                    title:"<{$words.disk_scan_title}>",
                    msg: "<{$words.detect_bad_stop}>",
                    buttons: Ext.Msg.OK,
                    width: '250',
                    icon: Ext.MessageBox.INFO,
                    fn:function(btn){
                      if(btn=='ok'){ 
                        start_badblock(rs.data.partition_no,0,'','',rs.data.tray_no);
                        disks_ct.tbar_badblock.setDisabled(true);
                        disks_ct.tbar_badblockstop.setDisabled(true);
                        disks_ct.tbar_smart.setDisabled(true);
                      }
                   }  
                });
                delete rs;
            }
        }
    ],
    listeners: {
        render: function(ct) {
            //Get the instance of toolbar buttons
            disks_ct['tbar'] = ct.getTopToolbar();
            for( var i = 0 ; i < disks_ct['tbar'].items.length ; i++ ) {
                var tmp_ct = disks_ct['tbar'].items.get(i);
                if (tmp_ct.cname){
                    disks_ct[tmp_ct.cname] = tmp_ct;
                }
            }

            this.load();
            this.items.get(0).selModel.on('rowselect', function( sm, rowIndex, r) {
                if( r.data.status.state == 1 ) {
                      disks_ct.tbar_badblock.setDisabled(true);
                      disks_ct.tbar_badblockstop.setDisabled(false);
                  } else {
                      disks_ct.tbar_badblock.setDisabled(false);
                      disks_ct.tbar_badblockstop.setDisabled(true);
                  }
            });
        },
        diskSelect: function() {
            disks_ct.tbar_smart.setDisabled(false);
        },
        diskUnSelect: function() {
            disks_ct.tbar_smart.setDisabled(true);
        }
    }
});

//esata info grid  
var edisk_info = new Ext.grid.GridPanel({
  store: edisk_store, 
  width:<{if $lang=="fr" || $lang=="de"}>600<{else}>670<{/if}>,
  //height:50,
  trackMouseOver:true,
  disableSelection:true,
  loadMask: true,
//    enableColumnResize:false,
  autoHeight:true,  
  viewConfig: {
             // forceFit:false,
              //autoFill : true,
              //forceFit:true,
              //enableRowBody:true,
              //showPreview:false,
               scrollOffset: -1
              },  
  columns: [
            {header: '<{$words.disk_slot}>',width: 60, dataIndex: 'trayno', sortable: true},
            {header: '<{$gwords.model}>', width: 170, dataIndex: 'model', sortable: true}, 
            {header: '<{$capacity}>', width: 120, dataIndex: 'capacity', sortable: true},
            {header: '<{$gwords.firmware}>', width: 60, dataIndex: 'fireware', sortable: true},
            {header: '<{$gwords.status}>', width: 90, dataIndex: 's_status', sortable: true, renderer:smartRenderer}
           ]
});
      
//usb disk info grid
var usb_info = new Ext.grid.GridPanel({
        store: usb_store, 
        width:<{if $lang=="fr" || $lang=="de"}>600<{else}>670<{/if}>,
        autoHeight:true, 
        trackMouseOver:true,
        disableSelection:true,
        loadMask: true,
//          enableColumnResize:false,
        viewConfig: {
               // forceFit:false,
//                autoFill : true,
//                forceFit:true,
//                enableRowBody:true,
//                showPreview:false,
                     scrollOffset: -1
                   },    
        columns: [
            {header: '<{$words.disk_slot}>',width: 60, dataIndex: 'trayno', sortable: true},
            {header: '<{$capacity}>', width: 120, dataIndex: 'capacity', sortable: true},
            {header: '<{$gwords.model}>', width: 170, dataIndex: 'model', sortable: true}, 
            {header: '<{$gwords.firmware}>', width: 120, dataIndex: 'fireware', sortable: true}, 
            {header: '<{$words.usb_eject}> ', width: 90, dataIndex: 's_status', sortable: true , renderer:ejectbutton}
         //   {header: '<{$words.disk_bad_status}>', width: 105, dataIndex: 'b_status', sortable: true},
<{if ($badblock_scan=="1")}>
            ,{header: '<{$words.disk_scan_title}>', width: 110, dataIndex: 'badblock', sortable: true , renderer:buttonRenderer}  
<{/if}>
        ]
});              

//power management combox select
var disk_power_combox= new Ext.form.ComboBox({
  store: new Ext.data.SimpleStore({
         fields: ["values","display"],
         data: disk_power_data    
         }),
  fieldLabel:'<{$words.diskpower}>',
  valueField :'values',
  displayField:'display',
  mode: 'local',
  forceSelection: true,
  editable: false,
  triggerAction: 'all',
  name: 'diskpower',
  listWidth :50,    
  hiddenName:'_diskpower',
  width: 50
});
  
//power management form
var disk_spin_panel =new Ext.FormPanel({
  //width: 300,
  //height:40,
  method: 'POST',
  labelWidth:220,
  waitMsgTarget : true,
//    bodyStyle: 'padding:0 10px',
  name:'disk_spin',
  layout: 'table',
  layoutConfig: {columns: 5},
  items: [
      {
          xtype: 'panel',
          layout: 'form',
          items: disk_power_combox
      },{
          width : 30
      },{
          html:'<{$words.diskspin_min}>'
      },{
          width : 20
      },{
          xtype: 'button',
          text : '<{$gwords.apply}>',
          disabled : false,
          handler : function() {
              if (disk_spin_panel.getForm().isValid()) {
                  Ext.Msg.confirm("<{$words.disk_title}>","<{$gwords.confirm}>",function(btn){
                      if(btn=='yes') {
                          processAjax('setmain.php?fun=setdiskpower',onLoadForm,disk_spin_panel.getForm().getValues(true));
                      }
                  })
              }
          }
      }
  ]
});   
     
//disk smart test type radio
var type_radio= new Ext.form.RadioGroup({
  hideLabel:true,
  items: [
           {boxLabel: '<{$words.test_short}>',name: 'testtype', inputValue:'short'},
           {boxLabel: '<{$words.test_long}>', name: 'testtype', inputValue:'long' }
          ]  
});

//store smart type to hidden form stype
type_radio.on('change', function(obj,value){  
  if(document.getElementById('stype'))  
    document.getElementById('stype').value=value;
});

//disk smart form
var smart_form = new Ext.FormPanel({
  width:300, 
  method: 'POST',
  waitMsgTarget : true,
  buttonAlign :'left',
  items: [type_radio]
}); 
   
   
//disk smart test apply button   
var sbutton= new Ext.Button({
  disabled : false,
  minWidth:80,
  handler : function() {
                if (document.getElementById('smart')) {
                  if(document.smart.smart_status.value == 0)
                    document.smart.smart_status.value =1; 
                  else
                    document.smart.smart_status.value =0;
                  
                  show_smart_flag=0; 
                  if(document.getElementById('smart'))  
                    processAjax('setmain.php?fun=setsmart',update_smart_status,document.getElementById('smart'));
                  
                } 
  }
});  

//disk smart test table 
var smart_test = new Ext.Panel({
  layout:'table',
  name:'smart_test',    
  defaults: {
      // applied to each contained panel
      bodyStyle:'padding:5px',
      listeners:{
          render: onComponentReady
      },
      setHTML: onPanelTextUpdate
  },
  layoutConfig: {
      // The total column count must be specified here
      columns: 2
  },
  items: [{
            html: '<{$words.test_type}>:'
          },{
           items:[smart_form]
          },{
           html: '<{$words.test_result}>:',
           width: 100,
           cellCls: 'highlight'
          },{
           cname:'test_result'
          },{
           html: '<{$words.test_time}>:',
           cellCls: 'highlight'
          },{
           cname:'test_time'
          },{
           colspan: 2,
           buttonAlign:'left',
           buttons : [sbutton]
  }]
}); 

//disk smart inf table
var smart_info = new Ext.Panel({
  layout:'table',
  defaults: {
      // applied to each contained panel
      bodyStyle:'padding:5px',
      listeners:{
          render: onComponentReady
      },
      setHTML: onPanelTextUpdate
  },
  layoutConfig: {
      // The total column count must be specified here
      columns: 3
  },
  
  items: [{
      html: '<{$words.disk_slot}>:',
      width: 150
     // rowspan: 2
  },{
      cname: 'stray_no',
      colspan: 2
  },{
      html: '<{$gwords.model}>:',
      cellCls: 'highlight'
  },{
      cname:'smodel',
      colspan: 2
  },{
      html: '<{$words.smart_attr9}>:',
      cellCls: 'highlight'
  },{
      cname:'smart_attr9',
      colspan: 2
  },{
      html: '<{$words.smart_attr194}>:',
      cellCls: 'highlight'
  },{
      cname:'smart_attr194',
      width: 120
  },{
      cname:'smart_attr194_old',
      width: 120
  },{
      html: '<{$words.smart_attr5}>:',
      cellCls: 'highlight'
  },{
      cname:'smart_attr5'
  },{
      cname:'smart_attr5_old'
  },{
      html: '<{$words.smart_attr197}>:',
      cellCls: 'highlight'
  },{
      cname:'smart_attr197'
  },{
      cname:'smart_attr197_old'
  },{
      html: '<{$words.smart_attr184}>:',
      cellCls: 'highlight'
  },{
      cname:'smart_attr184'
  },{
      cname:'smart_attr184_old'
  }]
});   

//disk smart info and disk smart test 
var smart_table = new Ext.Panel({
//    title: 'Table Layout',
  frame:true,
  items: [
    {
      xtype:'fieldset', 
      title:'<{$gwords.info}>',
      autoHeight:true,
      defaultType: 'table',
      collapsed: false,   
      items:[smart_info]
    },{
      xtype:'fieldset', 
      title:'<{$words.test_status}>',
      autoHeight:true,
      defaultType: 'table',
      collapsed: false,   
      items:[smart_test]
    }]
});

//pop smart window
var Window_smart= new Ext.Window({  
  title:'<{$words.smart_title}>',
  closable:true,
  closeAction:'hide',
  width: 450,
  height:420,
  layout: 'fit',  
  modal: true , 
  draggable:false,
  resizable:false,
  items: smart_table 
});  
  
Window_smart.on("hide",function(obj,value){
  if(smart_update_flag!=null)
    clearTimeout(smart_update_flag); 
  if(TCode.desktop.Group.page==='disks'){   
    update_flag = setTimeout("processAjax('getmain.php?fun=disks&update=1',update_data)",1);
  }
    //processAjax('getmain.php?fun=disks&update=1',update_data); 
});

disk_power_combox.setValue('<{$spin_time}>');   

var panel = TCode.desktop.Group.addComponent({
    autoScroll: true,
    defaults:{
        xtype: 'fieldset',
        autoHeight: true,
        collapsed: false,
        listeners:{
            render: function(ct){
                onComponentReady(ct);
                if( ! ct.cname ) return;
                if( <{$usb_count}> != 0 && ct.cname == 'usb_info_frame' ){
                    ct.show();
                }else if( <{$edisk_count}> != 0 && ct.cname == 'edisk_info_frame'){
                    ct.show();
                }else{
                    ct.hide();
                }
            }
        }
    },
    items:[
        {
            title: '<{$words.disk_title}>',
            items:[
                disk_info,
                {
                    xtype: 'label',
                    cname: 'total',
                    text: '<{$words.total}>: <{$disk_total_capacity}>',
                    listeners: {
                        render: onComponentReady
                    }
                }
            ]
        },{
            cname: 'edisk_info_frame',
            title: '<{$words.esata_title}>',
            items: [edisk_info]
        },{
            cname: 'usb_info_frame',
            title: '<{$words.usb_title}>',
            items:[usb_info]
        },{
            title: '<{$words.diskpower}>',
            <{if ($spindown!="1")}>
            hidden: true,
            <{/if}>
            items:[disk_spin_panel]
        }
    ]
});
panel.on('beforedestroy', function(){
    disks_ct = {};
    delete disks_ct;
    if(update_flag !=null)
        clearTimeout(update_flag);
    if(smart_update_flag !=null)
        clearTimeout(smart_update_flag);
    edisk_store.destroy();
    usb_store.destroy();
    Window_smart.destroy();
});

if (update_flag !=null)
  clearTimeout(update_flag);
update_flag=setTimeout("processAjax('getmain.php?fun=disks&update=1',update_data)",10*1000);

Ext.QuickTips.init();
</script>
