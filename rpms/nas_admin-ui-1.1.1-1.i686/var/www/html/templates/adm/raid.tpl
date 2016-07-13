<div id="raid_form"></div>
<br>
<div id="pie_chart_form">
<center><img id='pie_chart' align=center src="<{$urlimg}>default/shared/large-loading.gif"></img></center>
</div>
<br>
<div id='access_status'></div>


<script type="text/javascript" src="<{$urljs}>wizard.js?<{$randValue}>" ></script>

<script language="javascript">
var button_click="";
var current_disk="";
var raid_monitor="";
var raid_count="";
var disk_monitor="";
var master_alert=0;
var mdnum="";
var tap_index="";
var max_size_for_ext3="";
var reload_flag="";
var reloadUI2_time;
var raidlock=<{$lock}>;
var create=0;
var total_raid_limit=<{$sysconf.total_raid_limit}>;
var total_haraid_limit=<{$sysconf.total_haraid_limit}>;
var max_unused_size;
var raid_level_type = "";
var unused_disk_count=0;

var raid_ct = {};
function onComponentReady (ct){
    if (ct.cname) {
        raid_ct[ct.cname] = ct;
    }
}

function ExtDestroy(){
  Ext.destroy(Ext.getCmp(''));
}

function create_radio(v,cellmata,record,rowIndex){
  var md_num=record.data['md_num'];
  var radio_id="radio_"+md_num;
  
  var check="";
  ArrCookie=document.cookie.split("; ");
  for(i=0;i<ArrCookie.length;i++){
    if(ArrCookie[i]=="select_md="+md_num){
      check="checked";
      break;
    }
  }
  var html="";
  if(rowIndex==0 && raid_count==1){
    check="checked";
    document.cookie="select_md="+md_num;  
  }else{
    check=check;
  }
  html="<div>";
  html+="<input type='radio' id='radio_"+md_num+"' name='raid_radio' value='"+md_num+"' "+check+" onclick='radio_control(\""+rowIndex+"\",\""+record+"\");'>";
  html+="</div>";
  return html;
}

function radio_control(rowIndex,record){
  var md_num=RAIDGrid.getStore().getAt(rowIndex).get('md_num');
  var usb_capacity="",iscsi_capacity="";
  var data_partition=RAIDGrid.getStore().getAt(rowIndex).get('data_partition');
  if(data_partition=="N/A"){
    data_partition="0*";
  }else{
    data_partition+="*";
  }
  <{if $sysconf.target_usb=="1"}>
  usb_capacity=RAIDGrid.getStore().getAt(rowIndex).get('usb_capacity');
  if(usb_capacity=="N/A"){
    usb_capacity="0*";
  }else{
    usb_capacity+="*";
  }
  <{/if}>
  <{if $sysconf.iscsi_limit>="1"}>
  iscsi_capacity=RAIDGrid.getStore().getAt(rowIndex).get('iscsi_capacity');
  if(iscsi_capacity=="N/A"){
    iscsi_capacity="0*";
  }else{
    iscsi_capacity+="*";
  }
  <{/if}>
  var unused=RAIDGrid.getStore().getAt(rowIndex).get('unused');
  var data_url=data_partition+usb_capacity+iscsi_capacity+unused;

  document.cookie="select_md="+md_num;
}

function change_raid_status_color(v,cellmata,record,rowIndex){
    var status;
    var status_id="status"+record.data['md_num'];
    if(v=="Healthy"){
        status="<div id='"+status_id+"' title='"+v+"' style='color:green'><{$gwords.healthy}></div>";
    }else if(v=="Degraded"){
        status="<div id='"+status_id+"' title='"+v+"' style='color:orange'><{$gwords.degraded}></div>";
    }else if(v=="Damaged"){
        status="<div id='"+status_id+"' title='"+v+"' style='color:red'><{$gwords.damaged}></div>";
    }else{
        if(v.match("formatting")){
            status="<div id='"+status_id+"' title='"+v+"' style='color:blue'><{$gwords.format}></div>";
        }else if(v.match("Migrating")){
            status="<div id='"+status_id+"' title='"+v+"' style='color:blue'>"+v.replace(/Migrating RAID/,"<{$gwords.migrate_raid}>")+"</div>";
        }else if(v.match("Constructing")){
            status="<div id='"+status_id+"' title='"+v+"' style='color:blue'>"+v.replace(/Constructing/,"<{$gwords.construct}>")+"</div>";
        }else if(v.match("Recovering")){
            status="<div id='"+status_id+"' title='"+v+"' style='color:blue'>"+v.replace(/Recovering/,"<{$gwords.recover}>")+"</div>";
        }else if(v.match("Build")||v.match("Building")){
            status="<div id='"+status_id+"' title='"+v+"' style='color:blue'>"+v.replace(/Build/,"<{$gwords.build}>")+"</div>";
        }else if(v.match("Expand")){
            status="<div id='"+status_id+"' title='"+v+"' style='color:blue'>"+v.replace(/Expand/,"<{$gwords.expand}>")+"</div>";
        }else{
            status="<div id='"+status_id+"' title='"+v+"' style='color:blue'>"+v+"</div>";
        }
    }
    return status;
}

function popupSpareForm(){
  Window_hot_spare.show();
  Window_hot_spare.items.get(0).load();
  apply_btn4.setText('<{$gwords.apply}>');
}

function popupEditForm(){
  var request = eval('('+this.req.responseText+')');
  if(request.show==true){
    mag_box(request.topic,request.message,request.icon,request.button,'',request.prompt);
    if(Window_raid.isVisible()) {
      Window_raid.hide();
    }
    return;
  }
  
  Window_raid.show();
  raid_ct.raid_info.items.get(0).listRaidDisk(request.raid_info.RaidID);
  raid_ct.raid_info.items.get(0).load();
  current_disk=request.current_disk;
  var ha_enable=request.ha_enable;
  var raid_info=request.raid_info;
  var raid_level=raid_info.RaidLevel;
  var chunk_size=raid_info.ChunkSize;
  var m_raid=<{$sysconf.m_raid}>;
  var lock=request.lock;
  var raid_lock=request.raid_lock;
  unused_disk_count=request.unused_disk_count;
  var ha_raid = request.ha_raid;
  if (ha_enable=="1")
    tabs.hideTabStripItem(1); //expand_item tab hide
  else
  raid_level_type=raid_info.RaidLevel;
  tabs.unhideTabStripItem(1); //expand_item tab show
  <{if $offline_migrate == 1}>
    var check_migrate=(raid_level_type=="J" || raid_level_type=="10" || ha_enable=="1");    
  <{else}>
    var check_migrate=(raid_level_type=="J" || raid_level_type=="10" || raid_level_type=="0" || ha_enable=="1");
  <{/if}>
  if(check_migrate){
    tabs.hideTabStripItem(2); //migration_item tab hide
  }else{
    if(unused_disk_count == 0){
      tabs.hideTabStripItem(2); //migration_item tab hide
    }else{
      tabs.unhideTabStripItem(2); //migration_item tab show
    }
  }

  if(lock == "1" || raid_lock == "1"  || ha_raid == '1'){
    raid_ct.expand_item.setDisabled(true);
    raid_ct.migration_item.setDisabled(true);
  }else{
    raid_ct.expand_item.setDisabled(false);
    raid_ct.migration_item.setDisabled(false);
  }
  raid_ct.md_num.setValue(request.md_num);
  migration_level_radio.setDisabled(true);
    var grid = raid_ct.raid_info.items.get(0).items.get(0);
    var uidx = grid.colModel.findColumnIndex('used');
    var sidx = grid.colModel.findColumnIndex('spare');
    if( raid_level_type == 'J' ) {
        grid.colModel.setHidden(uidx, false);
        grid.colModel.setHidden(sidx, true);
    } else {
        grid.colModel.setHidden(uidx, true);
        grid.colModel.setHidden(sidx, false);
    }
    if(raid_level_type=="J"){
        raid_ct.raid_level_type.setValue('JBOD');
    }else{
        raid_ct.raid_level_type.setValue('RAID ' + raid_level_type);
    }
    if(request.raid_info.Encrypt=="1"){
        encryption_option.setValue('<{$gwords.yes}>');
    }else{
        encryption_option.setValue('<{$gwords.no}>');
    }
  raid_ct.raid_id.setValue(raid_info.RaidID);
  raid_ct.raid_id.setDisabled(false);
  
  if(raid_info.RaidMaster==1){
    master_alert=1;
    raid_ct.master.setValue(true);
    master_alert=0;
  }else{
    raid_ct.master.setValue(false);
  }
  raid_ct.master.setDisabled(false);
  if(m_raid==0){
    master_alert=1;
    raid_ct.master.setValue(true);
    raid_ct.master.hide();
    master_alert=0;
  }
  if(chunk_size==""){
    chunk_label.setValue('64');
  }else{
    chunk_label.setValue(chunk_size);  
  }
  
  file_system_label.setValue(raid_info.RaidFS.toUpperCase());
  apply_btn.setText('<{$gwords.apply}>');
    if (ha_enable == 1){
      apply_btn.setDisabled(true);
    remove_btn.hide();
      raid_ct.master.setDisabled(true);
    }else{
  apply_btn.setDisabled(false);
  remove_btn.show();
    }
}

function modifyExpandForm(){
  var request = eval('('+this.req.responseText+')');
  
  if(request.show==true){
    mag_box(request.topic,request.message,request.icon,request.button,'',request.prompt);
    Window_raid.hide();
    return;
  }
  
  apply_btn2.setText('<{$gwords.apply}>');
  var unused_item=request.unused_size+" GB ( "+request.unused_percent+" % )";
  max_unused_size=request.unused_size;
  if (raid_ct.unused) {
    raid_ct.unused.setText(unused_item);
    ExpandFormPanel.items.get(0).show();
  }
    <{if $NAS_DB_KEY == "1"}>
  expand_capacity_slider.maxValue=request.unused_percent;
  expand_capacity_slider.setValue(request.unused_percent,request.unused_size);
  expand_capacity_slider.setV=request.unused_size;
    <{/if}>
  if(request.expand==1){
    <{if $NAS_DB_KEY == "1"}>
    expand_capacity_slider.setDisabled(false);
    <{/if}>
    apply_btn2.setDisabled(false);
  }else{
    <{if $NAS_DB_KEY == "1"}>
    expand_capacity_slider.setDisabled(true);
    <{/if}>
    apply_btn2.setDisabled(true);
    Ext.Msg.alert("<{$rwords.raid_config_title}>","<{$rwords.expand_fail}>");
  }
}

function modifyMigrationForm(){
  var request = eval('('+this.req.responseText+')');

  if(request.show==true){
    mag_box(request.topic,request.message,request.icon,request.button,'',request.prompt);
    Window_raid.hide();
    return;
  }
  raid_ct.migration_item.items.get(0).load();
  apply_btn3.setText('<{$gwords.apply}>');
  apply_btn3.setDisabled(true);
  var raidinfo=request.raid_info;
  var raid_level=raidinfo.RaidLevel;
  var raid_list=raidinfo.RaidList;
  
  
  <{if $offline_migrate == 1}>
  if(raid_level==0){
    raid_ct.r0r0.setDisabled(false);
    raid_ct.r0r0.setValue(false);
    raid_ct.r0r5.setDisabled(false);
    raid_ct.r0r5.setValue(false);
  }else if(raid_level==1){
    raid_ct.r1r0.setDisabled(false);
    raid_ct.r1r0.setValue(false);
  }
  <{/if}> 
  if(raid_level==1){
    raid_ct.r1r5.setDisabled(false);
    raid_ct.r1r5.setValue(false);
    //raid_ct.r1r6.setDisabled(false);
    //raid_ct.r1r6.setValue(false);
  }else if(raid_level==5){
    raid_ct.r5r5.setDisabled(false);
    raid_ct.r5r5.setValue(false);
    if(unused_disk_count >= 2){
      raid_ct.r5r6.setDisabled(false);
      raid_ct.r5r6.setValue(false);
    }
  }else if(raid_level==6){
    raid_ct.r6r6.setDisabled(false);
    raid_ct.r6r6.setValue(false);
  }else if(raid_level==50){
    raid_ct.r50r50.setDisabled(false);
    raid_ct.r50r50.setValue(false);
    raid_ct.r50r60.setDisabled(false);
    raid_ct.r50r60.setValue(false);
  }else if(raid_level==60){
    raid_ct.r60r60.setDisabled(false);
    raid_ct.r60r60.setValue(false);
  }
}

Ext.QuickTips.init();

var lockId = Ext.id();
function create_hidden_item(v){
  var Hidden_item = new Ext.Panel({
    hidden:true,
    border:false,
    defaults:{
      xtype: 'textfield',
      hidden:true,
      hideLabel:true,
      border:false,
      listeners: {
        render: onComponentReady
      }
    },
    items:[{
      id:lockId+v,
      cname:'lock'+v,
      name:'lock'+v,
      value:'2'
    },{
      cname:'md_num'+v,
      name:'md_num'+v,
      value:''
    },{
      cname:'RI'+v,
      name: 'RI'+v,
      value:'0'
    }]
  });
  return Hidden_item;
}
var RAIDForm_hidden = create_hidden_item('');
var MigrationForm_hidden = create_hidden_item('m');


var encryption_option = new Ext.form.TextField({
    name: '_encrypt',
    fieldLabel:'<{$rwords.encrypt}>',
    cls: 'FakeLabel',
    style: 'border: 0px',
    disabled: true,
    value: '<{$gwords.no}>'
});

var chunk_label = new Ext.form.TextField({
    fieldLabel: '<{$rwords.chunksize}>',
    cls: 'FakeLabel',
    style: 'border: 0px',
    disabled: true
});

var chunk_store= new Ext.data.SimpleStore({
  fields: <{$chunk_fields}>,
  data: <{$chunk_data}>
});

var file_system_store= new Ext.data.SimpleStore({
  fields: <{$fs_fields}>,
  data: <{$fs_data}>
});

var file_system_label = new Ext.form.TextField({
    fieldLabel: '<{$rwords.filesystem}>',
    cls: 'FakeLabel',
    style: 'border: 0px',
    disabled: true
});

var expand_capacity_tip = new Ext.ux.SliderTip({
  getText: function(slider){
    return String.format('<b>{0}%</b>', slider.getValue());
  }
});

<{if $NAS_DB_KEY == "1"}>
var expand_capacity_slider = new Ext.form.SliderField({
  xtype:'sliderfield',
  fieldLabel: '<{$rwords.expand_capacity}>',
  name:'expand_capacity',
  width: 214,
  minValue: '1',
  setMsg:' GB',
  setZero:'0 GB',
  setV:0,
  maxValue: 100,
  value:1,
  plugins: expand_capacity_tip,
  listeners:{
    changecomplete:function(Obj,v){
      var unused_size=Obj.setV;
      var max1=Obj.maxValue;
      var expand_size=(unused_size*v)/max1;
      if(v != max1) {
        expand_size=Math.floor(expand_size*Math.pow(10,1))/Math.pow(10,1);
      } else {
        expand_size=max_unused_size;
      }
      expand_capacity_slider.setValue(v,expand_size);
    }
  }
});
<{/if}>

function create_apply_btn(){
  var apply_btn = new Ext.Button({
    text:'<{$gwords.create}>',
    border:false,
    handler:function(){
      var inraid="",spare="",migrate="";
      raid_count=RAIDGrid.getStore().getCount()+1;
      
      if(button_click=="create" || button_click=="edit"){
        var confirm_msg="";
          if(raid_ct.raid_id.getValue().length > 12 ){
            Ext.Msg.alert("<{$rwords.raid_config_title}>", "<{$rwords.raid_id_len_warn}>");
            return;
          }

          confirm_msg="<{$rwords.create_confirm}>";
        
        Ext.Msg.confirm("<{$rwords.raid_config_title}>",confirm_msg,function(btn){
          if(btn=="yes"){
            raidlock=1;
            var disks = [];
            
            var allocate = raid_ct.raid_info.items.get(0).getAllocate();
            if( raid_level_type == 'J' ) {
                for( tray in allocate.used) {
                    disks.push('inraid[]=' + Number(tray));
                }
            } else {
                for( tray in allocate.spare) {
                    disks.push('spare[]=' + Number(tray));
                }
            }
            
            disks = '&' + disks.join('&');
            processAjax("<{$form_action}>",onLoadForm,"&action=create&"+RAIDFormPanel.getForm().getValues(true)+disks);
          }
        });  
      }else if(button_click=="expand"){
        Ext.Msg.confirm("<{$rwords.raid_config_title}>","<{$rwords.expand_confirm}>",function(btn){
          if(btn=="yes"){
            Ext.Msg.prompt("<{$rwords.raid_config_title}>","<{$rwords.expand_prompt}>",function(btn,msg){
              if(msg=="Yes" && btn=="ok"){
                raidlock=1;
                processAjax("<{$action_expand}>",onLoadForm,"&action=expand&md_num="+mdnum+"&"+ExpandFormPanel.getForm().getValues(true));
              }else if(msg!="Yes" && btn=="ok"){
                  Ext.Msg.show({
                  title:"<{$rwords.raid_config_title}>",
                  msg: "<{$rwords.prompt_fail}>",
                  buttons: Ext.Msg.OK,
                  icon: Ext.MessageBox.INFO
                });
              }
            });  
          }
        });
      }else if(button_click=="migration"){
            var spare = [];
            var allocate = raid_ct.migration_item.items.get(0).getAllocate();
            for( tray in allocate.used) {
                spare.push('spare[]=' + Number(tray));
            }
            spare = '&' + spare.join('&');
            //processAjax("<{$action_migrate}>",onLoadForm,"&action=migrate&md_num="+mdnum+"&"+MigrationFormPanel.getForm().getValues(true)+spare+"&check=1");
            processAjax("<{$action_migrate}>",function(){
                var msg = Ext.decode(this.req.responseText);
                if( msg == null ) {
                    Ext.Msg.confirm("<{$rwords.raid_config_title}>","<{$rwords.migrate_confirm}>",function(btn){
                        if(btn=="yes"){
                            Ext.Msg.prompt("<{$rwords.raid_config_title}>","<{$rwords.migrate_prompt}>",function(btn,msg){
                                if(msg=="Yes" && btn=="ok"){
                                    raidlock=1;
                                    processAjax("<{$action_migrate}>",onLoadForm,"&action=migrate&md_num="+mdnum+"&"+MigrationFormPanel.getForm().getValues(true)+spare);
                                }else if(msg!="Yes" && btn=="ok"){
                                    Ext.Msg.show({
                                        title:"<{$rwords.raid_config_title}>",
                                        msg: "<{$rwords.prompt_fail}>",
                                        buttons: Ext.Msg.OK,
                                        icon: Ext.MessageBox.INFO
                                    });
                                }
                            });
                        }
                    });
                } else {
                    Ext.Msg.show({
                        title: msg.topic,
                        minWidth: 250,
                        msg: msg.message,
                        icon: msg.icon,
                        buttons: Ext.Msg.OK
                    })
                }
            },"&action=migrate&md_num="+mdnum+"&"+MigrationFormPanel.getForm().getValues(true)+spare+"&check=1");
      }else if(button_click=="hot_spare"){
        Ext.Msg.confirm("<{$rwords.hot_spare_title}>","<{$rwords.hot_spare_confirm}>",function(btn){
        if(btn=="yes"){
            raidlock=1;
            var spare = [];
            
            var allocate = Window_hot_spare.items.get(0).getAllocate();
            for( tray in allocate.hot_spare) {
                var disk = allocate.hot_spare[tray].data;
                spare.push('hotspare[]=' + disk.Serial);
            }
            spare = '&' + spare.join('&');
            processAjax("<{$action_hot_spare}>",onLoadForm,"&action=hot_spare"+spare);
        }
        });
      }
    }
  });
  return apply_btn;
}

var apply_btn=create_apply_btn();
var apply_btn2=create_apply_btn();
var apply_btn3=create_apply_btn();
var apply_btn4=create_apply_btn();

function window_raid_hide(){
  Window_raid.hide();
  if(Window_hot_spare.isVisible())
    Window_hot_spare.hide();
  raid_ct.create_raid.setDisabled(true);
  raid_ct.edit_raid.setDisabled(true);
  //raid_ct.hot_spare.setDisabled(true);
  radio_control('0','');
  reload_flag=1;
  raidlock=0;
  raid_store.load();
}

function redirect_reboot(){
  processAjax('setmain.php?fun=setreboot',onLoadForm,"&action=reboot");
}

function gotoRaidInfo(){
  if(Window_raid.isVisible())
    Window_raid.hide();
  if(Window_hot_spare.isVisible())
    Window_hot_spare.hide();
  raid_ct.create_raid.setDisabled(true);
  raid_ct.edit_raid.setDisabled(true);
  //raid_ct.hot_spare.setDisabled(true);
  reload_flag=1;
  raid_store.load();
}

function reloadUI(){
  var current_count=RAIDGrid.getStore().getCount();
  var status_id="";
  var status="";
  var count=0;
  if(current_count<raid_count){
    raid_store.load();
    setTimeout("reloadUI()",5000);
  }else{
    for(var c=1;c<=raid_count;c++){
      status_id="status"+c;
      if (document.getElementById(status_id) && document.getElementById(status_id).title=="Healthy") {
        count++;
      }
    }
    if(count==raid_count){
      raid_ct.create_raid.setDisabled(false);
      raid_ct.edit_raid.setDisabled(false);
    }else{
      raid_store.load();
      setTimeout("reloadUI()",5000);      
    }
  }
}   

var remove_btn = new Ext.Button({
  text:'<{$gwords.remove_raid}>',
  border:false,
  handler:function(){
    Ext.Msg.confirm("<{$rwords.raid_config_title}>","<{$rwords.DestroyWarning}>",function(btn){
      if(btn=="yes"){
        Ext.Msg.prompt("<{$rwords.raid_config_title}>","<{$rwords.destroy_prompt}>",function(btn,msg){
          if(msg=="Yes" && btn=="ok"){
            raid_count=RAIDGrid.getStore().getCount()-1;
            raidlock=0;
            processAjax("<{$form_action2}>",onLoadForm,"&action=destroy&md_num="+mdnum+"&"+RAIDFormPanel.getForm().getValues(true));  
          }else if(msg!="Yes" && btn=="ok"){
            Ext.Msg.show({
              title:"<{$rwords.raid_config_title}>",
              msg: "<{$rwords.prompt_fail}>",
              buttons: Ext.Msg.OK,
              icon: Ext.MessageBox.INFO         
            }); 
          }
        });  
      }
    });
  }
});

function raidIDRenderer(value,obj,thisobj){
  if(thisobj.data['encrypt']=='1') {
    return String.format('{0}<img src="<{$urlimg}>/default/lock.gif" align="absmiddle">',value);  
  } else {
    return String.format('{0}',value);
  }
}

var RAIDFormPanel = new Ext.FormPanel({
    frame:true,
    buttonAlign:'left',
    bodyStyle:'padding:0 0 0 0;',
    labelWidth:120,
    layout: 'column',
    columns: 2,
    items: [
        RAIDForm_hidden,
        {
            layout: 'form',
            columnWidth: .5,
            items: [
                {
                    xtype: 'textfield',
                    fieldLabel:'<{$gwords.raid_id}>',
                    width:80,
                    cname:'raid_id',
                    name:'raid_id',
                    maxLength: 12,
                    vtype: 'alphanum',
                    value:'',
                    listeners: {
                        render: function(ct) {
                            Ext.DomHelper.insertAfter(this.el, '<span style="color:red">  ( <{$rwords.raid_id_limit}> )</span>');
                            onComponentReady(ct);
                        }
                    }
                },
                {
                    xtype: 'checkbox',
                    cname:'master',
                    name:'master',
                    inputValue:'1',
                    boxLabel:'<{$rwords.raidmaster}>',
                    labelSeparator: '',
                    handler:function(Obj,val) {
                        if(val && master_alert==0) {
                            Ext.Msg.alert("<{$rwords.raid_config_title}>","<{$rwords.warn_master_raid}>");
                        }
                    },
                    listeners:{
                        render: function(ct){
                            onComponentReady(ct);
                            //if only one raid, hide the checkbox of master raid
                            (raid_store.getCount() == 1) ? raid_ct.master.hide() : raid_ct.master.show();
                        }
                    }
                }
            ]
        },
        {
            layout: 'form',
            columnWidth: .5,
            items: [
                {
                    xtype:'textfield',
                    cname: 'raid_level_type',
                    name: 'raid_level_type',
                    cls: 'FakeLabel',
                    disabled: true,
                    style: 'border: 0px;',
                    fieldLabel: '<{$rwords.raidlevel}>',
                    listeners:{
                        render: onComponentReady
                    }
                },
                chunk_label,
                file_system_label,
                encryption_option
            ]
        }
    ],
    buttons:[
        apply_btn,
        remove_btn
    ]
});

var ExpandFormPanel = new Ext.FormPanel({
    frame:true,
    buttonAlign:'left',
    bodyStyle:'padding:0 0 0 0;',
    items:[
        {
            xtype: 'panel',
            layout: 'table',
            layoutConfig: { columns: 2 },
            bodyStyle:'padding:0 0 0 0;',
                items: [{
                    width: 160,
                    html: '<{$rwords.unused}>: '
                },{
                    xtype: 'label',
                    cname: 'unused',
                    listeners: {
                        render: onComponentReady
                    }
                }
                <{if $NAS_DB_KEY == "1"}>
                ,{
                    //width: 160,
                    html: '<{$rwords.expand_capacity}>:'
                },{
                    width: 400,
                    items: expand_capacity_slider
                }
                <{/if}>
            ],
            listeners: {
                render: function(ct){
                    ct.hide();
                }
            }
        },{
            xtype:'hidden'
        }
    ],
    buttons:[
        apply_btn2
    ]
});

var migration_level_radio = new Ext.form.RadioGroup({
  fieldLabel: '<{$rwords.raidlevel}>',
  xtype: 'radiogroup',
  vertical:true,
  width: 600,
  defaults:{
    width: 250,
    listeners:{
        render: onComponentReady
    }
  },
  
  listeners: {
    change:{
      fn:function(r,c){
        apply_btn3.setDisabled(false);
      }
    }
  },
  
  columns:2,
  items: [
    <{if $offline_migrate == 1}>
    {
    boxLabel: 'RAID 0 -> RAID 0 <span style="color:red">(<{$rwords.offline_msg}>)</span>',
    cname:'r0r0',
    name: '_type',
    disabled:true,
    inputValue: '0_0'
  },{
    boxLabel: 'RAID 0 -> RAID 5 <span style="color:red">(<{$rwords.offline_msg}>)</span>',
    cname:'r0r5',
    name: '_type',
    disabled:true,
    inputValue: '0_5'
  },{
    boxLabel: 'RAID 1 -> RAID 0 <span style="color:red">(<{$rwords.offline_msg}>)</span>',
    cname:'r1r0',
    name: '_type',
    disabled:true,
    inputValue: '1_0'
  },<{/if}>{
    boxLabel: 'RAID 1 -> RAID 5 <span style="color:red">(<{$rwords.online_msg}>)</span>',
    cname:'r1r5',
    name: '_type',
    disabled:true,
    inputValue: '1_5'
//  },{
//    boxLabel: 'RAID 1 -> RAID 6 <span style="color:red">(<{$rwords.online_msg}>)</span>',
//    cname: 'r1r6',
//    name: '_type',
//    disabled:true,
//    inputValue: '1_6'
  },{
    boxLabel: 'RAID 5 -> RAID 5 <span style="color:red">(<{$rwords.online_msg}>)</span>',
    cname:'r5r5',
    name: '_type',
    disabled:true,
    inputValue: '5_5'
  },{
    boxLabel: 'RAID 5 -> RAID 6 <span style="color:red">(<{$rwords.online_msg}>)</span>',
    cname:'r5r6',
    name: '_type',
    disabled:true,
    inputValue: '5_6'
  },{
    boxLabel: 'RAID 6 -> RAID 6 <span style="color:red">(<{$rwords.online_msg}>)</span>',
    cname:'r6r6',
    name: '_type',
    disabled:true,
    inputValue: '6_6'
  },{
    boxLabel: 'RAID 50 -> RAID 50 <span style="color:red">(<{$rwords.offline_msg}>)</span>',
    cname:'r50r50',
    name: '_type',
    disabled:true,
    inputValue: '50_50'
  },{
    boxLabel: 'RAID 50 -> RAID 60 <span style="color:red">(<{$rwords.offline_msg}>)</span>',
    cname:'r50r60',
    name: '_type',
    disabled:true,
    inputValue: '50_60'
  },{
    boxLabel: 'RAID 60 -> RAID 60 <span style="color:red">(<{$rwords.offline_msg}>)</span>',
    cname:'r60r60',
    name: '_type',
    disabled:true,
    inputValue: '60_60'
  }]
});

var MigrationFormPanel = new Ext.FormPanel({
  frame:true,
  buttonAlign:'left',
  //bodyStyle:'padding:0 0 0 0;',
  //items:[{
    //xtype:'fieldset',
    //id:'migration',
    //defaults:{bodyStyle:'padding:0 0 0 0;'},
    //title:'<{$rwords.migrate_title}>',
    //autoHeight:true,
    //collapsed: false,
    buttonAlign:'left',
    items:[
        MigrationForm_hidden,
        migration_level_radio
    ],
    buttons:[
      apply_btn3
    ]
  //}]
});

var tabs = new Ext.TabPanel({
    width: 818,
    //height: 493,
    autoHeight: true,
    autoScroll:true,
    activeTab:0,
    //deferredRender:true,
    deferredRender: false,
    //layoutOnTabChange: true,
    layoutOnTabChange: false,
    plain: true,
    defaults: {
        autoHeight: true,
        bodyStyle: 'padding: 0px;',
        listeners: {
            render: onComponentReady
        }
    },
    items:[
        {
            title:'<{$rwords.Raid_info}>',
            cname:'raid_info',
            items: [
                {
                    xtype: 'disk',
                    width: 816,
                    height: 300,
                    used: true,
                    spare: true,
                    disableSelection: true,
                    listeners: {
                        diskLoaded: function() {
                            var grid = this.items.get(0);
                            var uidx = grid.colModel.findColumnIndex('used');
                            var sidx = grid.colModel.findColumnIndex('spare');
                            if( raid_level_type == 'J' ) {
                                grid.colModel.setHidden(uidx, false);
                                grid.colModel.setHidden(sidx, true);
                            } else {
                                grid.colModel.setHidden(uidx, true);
                                grid.colModel.setHidden(sidx, false);
                            }
                        },
                        diskAllocate: function(allocate) {
                            
                        }
                    }
                },
                RAIDFormPanel
            ]
        },
        {
            title:'<{$gwords.expand}>',
            cname:'expand_item',
            items:ExpandFormPanel
        },
        {
            title:'<{$gwords.migrate_raid}>',
            cname:'migration_item',
            items: [
                {
                    xtype: 'disk',
                    width: 816,
                    height: 300,
                    used: true,
                    //spare: true,
                    disableSelection: true
                },
                MigrationFormPanel
            ]
        }
    ],
    listeners:{
        tabchange:function(tab,newtab){
            if(newtab.cname=="expand_item"){
                button_click="expand";
                processAjax("<{$geturl}>",modifyExpandForm,"&action=expand&md_num="+mdnum);
            }else if(newtab.cname=="migration_item"){
                button_click="migration";
                raid_ct.lockm.setValue(raid_ct.lock.getValue());
                raid_ct.r1r5.setDisabled(true);
                //raid_ct.r1r6.setDisabled(true);
                raid_ct.r5r5.setDisabled(true);
                raid_ct.r5r6.setDisabled(true);
                raid_ct.r6r6.setDisabled(true);
                raid_ct.r50r50.setDisabled(true);
                raid_ct.r50r60.setDisabled(true);
                raid_ct.r60r60.setDisabled(true);
                processAjax("<{$geturl}>",modifyMigrationForm,"&action=migration&md_num="+mdnum);
            }else if(newtab.cname=="raid_info" && button_click!="create"){
                if(button_click!="edit"){
                    button_click="edit";
                    processAjax("<{$geturl}>",popupEditForm,"&action=edit&md_num="+mdnum);
                }
            }
        }
    }
});

var Window_raid = new Ext.Window({
  closable:true,
  closeAction:'hide',
  width:830,
  autoHeight: true,
  modal: true,
  draggable:false,
  resizable:false,
  border: false,
  shadow: false,
  title:'<{$rwords.raid_config_title}>',
  items: [tabs],
  listeners: {
      show: function(){
          //if only one raid, hide the checkbox of master raid
          if (raid_ct.master) {
              (raid_store.getCount() == 1 ) ? raid_ct.master.hide() : raid_ct.master.show();
          }
      }
  }
});

Ext.BLANK_IMAGE_URL = '/theme/images/default/s.gif';
Ext.QuickTips.init();

Ext.form.Field.prototype.msgTarget = 'qtip'; 

Ext.form.VTypes["ipVal"] = /^([1-9][0-9]{0,1}|1[013-9][0-9]|12[0-689]|2[01][0-9]|22[0-3])([.]([1-9]{0,1}[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])){2}[.]([1-9][0-9]{0,1}|1[0-9]{2}|2[0-4][0-9]|25[0-4])$/;
Ext.form.VTypes["ipText"]="<{$gwords.ip_error}>";
Ext.form.VTypes["ipMask"]=/[.0-9]/;
Ext.form.VTypes["ip"]=function(v){
        var res = Ext.form.VTypes["ipVal"].test(v);
	if(res){
		var ip = v;
		ip = ip.replace(/\.\d{1,3}$/g, "");
		var ipexr = "<{$ipexr}>";
		if(ip==ipexr){
			res=false;
		}
	}
	return res;
}
	

var InterfaceStore = new Ext.data.JsonStore({
    fields: ['id','name'],
    data : <{$interface_data}>
});
	
var ha_heartbeat_combo = new Ext.form.ComboBox({
    hiddenName:'hbtype',
    fieldLabel:"&nbsp;&nbsp;&nbsp;&nbsp;<{$words.interface}>",
    store: InterfaceStore,
    displayField:'name',
    valueField:'id',
    mode: 'local',
    readOnly:true,
    typeAhead:true,
    selectOnFocus:true,
    value:"<{$interface_default}>",
    triggerAction: 'all',
    listeners:{
            select:function(obj){
                    ha_heartbeat_combo.setValue(obj.value);
            }
    }
});


	
var Window_recover_ha = new Ext.Window({
  closable:true,
  closeAction:'hide',
  width:370,
  autoHeight:true,
  modal: true,
  draggable:false,
  resizable:false,
  title:"<{$rwords.recover_ha}>",
  border:false,
  layout:'table',
  layoutConfig:{columns:3},
  items:[ 
    {
        xtype:"label",
        html:"<{$rwords.recover_acheartbeatip}>:",
        colspan:3
    },ha_heartbeat_combo,
    {
       xtype:'label',
       html:':'
    },{
        xtype:"textfield",
        cname:'hbip',
        name:'hbip',
        value:"",
        allowBlank:false,
        width:200,
        vtype:'ip',
        listeners: {
            render: onComponentReady
        }
    }
  ],
  listeners:{
    show: function(){
      raid_ct.hbip.focus(true, 100);
    }  
  },
  buttons:[
    {
	    text: "<{$gwords.apply}>",
	    handler:function(){
	        if(raid_ct.hbip.isValid() && raid_ct.hbip.getValue()!=""){
                Window_recover_ha.hide();
	            var hbip = raid_ct.hbip.getValue();
                var hbtype = ha_heartbeat_combo.getValue();
	            var param = "&action=harecover&hbip="+hbip+"&hbtype="+hbtype;
                raid_ct.hbip.setValue("");
                processAjax("setmain.php?fun=setraid",recoverHA,param);
	        }
	    }
    }
  ]
});
function recoverHA(){
   processAjax('getmain.php?fun=nasstatus',onloadSysConfig);
}

var Window_hot_spare = new Ext.Window({
    closable:true,
    closeAction:'hide',
    width:640,
    autoHeight:true,
    modal: true,
    draggable:false,
    resizable:false,
    shadow: false,
    border: false,
    title:'<{$rwords.hot_spare_title}>',
    items: {
        xtype: 'disk',
        frame: false,
        hot_spare: true,
        disableSelection: true,
        width: 625,
        height: 300
    },
    buttons: [
        apply_btn4
    ]
});

var tbar =new Ext.Toolbar({
  items:[{
    cname:'create_raid',
    text:'<{$gwords.create}>',
    iconCls:'add',
    disabled:true,
    handler:function(ct){
      var total = RAIDGrid.getStore().getCount();
      var count = 0;
      for (var i=0;i<total;i++){
        var md_no = RAIDGrid.getStore().getAt(i).get('md_num');
        var radioid="radio_"+md_no;
        if(document.getElementById(radioid).checked){
          var md_num=md_no;
          count++
        }
      }
      mdnum=md_num;
      if(!Window_raid.isVisible()){
        button_click='create';
        tabs.setActiveTab(0); //tab cname raid_info
        Ext.getCmp(lockId).setValue('0'); //raid_ct.lock
        runCreateRaidWizard("create", true);
      }else{
        Window_raid.toFront();
      }
    },
    listeners: {render:onComponentReady}
  }, '-',{
    cname:'edit_raid',
    text:'<{$gwords.edit}>',
    iconCls:'edit',
    disabled:true,
    handler:function(){
      var total = RAIDGrid.getStore().getCount();
      var count = 0;
      for (var i=0;i<total;i++){
        var md_no = RAIDGrid.getStore().getAt(i).get('md_num');
        var radioid="radio_"+md_no;
        if(document.getElementById(radioid).checked){
          var md_num=md_no;
          count++
        }
      }
      mdnum=md_num;
      if(typeof(mdnum) == 'undefined')
        return;
      if(!Window_raid.isVisible()){
          tabs.setActiveTab(0); //tab cname raid_info
          button_click='edit';
          Ext.getCmp(lockId).setValue('1'); //raid_ct.lock
          processAjax("<{$geturl}>",popupEditForm,"&action=edit&md_num="+md_num);
      }else{
        Window_raid.toFront();
      }
    },
    listeners: {render:onComponentReady}
  }, '-',{
    cname:'hot_spare',
    text:'<{$rwords.hot_spare_title}>',
    iconCls:'edit',
    disabled:true,
    handler:function(){
        if(!Window_hot_spare.isVisible()){
            button_click='hot_spare';
            Ext.getCmp(lockId).setValue('1'); //raid_ct.lock
            popupSpareForm();
        }else{
            Window_hot_spare.toFront();
        }
    },
    listeners: {render:onComponentReady}
  }, '-',{
    cname:'recover',
    text:"<{$rwords.recover_ha}>",
    iconCls:'restore',
    disabled:true,
    handler:function(){
       if(!Window_recover_ha.isVisible()){ 
          Window_recover_ha.show();
      }else{ 
          Window_recover_ha.toFront();
      }
      raid_ct.hbip.setValue("");
      raid_ct.hbip.focus(true, 10);
    },
    listeners: {
        render: function(ct){
            onComponentReady(ct);
            <{if $ha_btn =='0'}>
                ct.setVisible(false);
            <{/if}>
        }
    }
  }]
});

var raid_store = new Ext.data.JsonStore({
  storeId:'raid_store',
  root:'raid_list',
  idProperty: 'md_num',
  fields:[
    <{if $sysconf.m_raid=="1"}>
    'md_num','master','raid_id','raid_level','raid_status','raid_disk','total_capacity','data_capacity','usb_capacity','iscsi_capacity','data_partition','unused','encrypt','filesystem'
    <{else}>
    'md_num','raid_id','raid_level','raid_status','raid_disk','total_capacity','data_capacity','usb_capacity','iscsi_capacity','data_partition','unused','encrypt','filesystem'
    <{/if}>
  ],
  url: '<{$geturl}>&action=getraidlist'
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

var RAIDGrid = {
  xtype: 'grid',
  disableSelection:false,
  store:raid_store,
  viewConfig: {
      forceFit: true,
      autoFill: true
  },
  cm: new Ext.grid.ColumnModel({
    columns:[
      {
        header: "",
        name:'allradio',
        width:30,
        menuDisabled:true,
        renderer:create_radio
      },
      <{if $sysconf.m_raid=="1"}>
      {header: "<{$rwords.Raid_master}>", width: 40, menuDisabled:true, dataIndex: 'master'},
      <{/if}>
      {header: "<{$rwords.Raid_id}>", width: 50, menuDisabled:true, dataIndex: 'raid_id' ,renderer:raidIDRenderer},
      {header: "<{$rwords.Raid_level}>", width: <{if $lang=="fr" || $lang=="de"}>65<{else}>80<{/if}>, menuDisabled:true, dataIndex: 'raid_level'},
      {header: "<{$gwords.status}>", width: 80, menuDisabled:true, renderer:change_raid_status_color, dataIndex: 'raid_status'},
      {header: "<{$rwords.Raid_disk_used}>", width: <{if $lang=="fr" || $lang=="de"}>65<{else}>100<{/if}>, menuDisabled:true, dataIndex: 'raid_disk', renderer: diskUsageTip},
      {header: "<{$rwords.Raid_total}>", width: 60, menuDisabled:true, dataIndex: 'total_capacity'},
      {header: "<{$rwords.Raid_data}>", width: 120, menuDisabled:true, dataIndex: 'data_capacity'}
      <{if $sysconf.target_usb=="1"}>
      ,{header: "<{$rwords.Raid_usb}>", width: 50, menuDisabled:true, dataIndex: 'usb_capacity'}
      <{/if}>
      <{if $sysconf.iscsi_limit>="1"}>
        <{if $NAS_DB_KEY == "1"}>
      ,{header: "<{$rwords.Raid_iscsi}>", width: 50, menuDisabled:true, dataIndex: 'iscsi_capacity'}
        <{/if}>
      <{/if}>
    ]
  }),
  listeners:{
    rowclick:function(gridObj,rowIndex,event){
      var md_num=gridObj.getStore().getAt(rowIndex).get('md_num');
      var radioid='radio_'+md_num;
      Ext.getDom('radio_'+md_num).checked=true;
      radio_control(rowIndex,"");
    },
    render: function () {
      RAIDGrid = this;
    }
  },
  width:<{if $lang=="fr" || $lang=="de"}>600<{else}>660<{/if}>,
  border:false,
  autoHeight:true,
  tbar:tbar
};

var GlobalFormPanel = new Ext.FormPanel({
  labelAlign:'left',
  labelWidth:180,
  buttonAlign:'left',
  layout: 'fit',
  items: [
    RAIDGrid
  ],
  renderTo:'raid_form'
});

reload_flag=1;
raid_store.load();

raid_store.on('load',function(){
  var now_raid_count=RAIDGrid.getStore().getCount();
  raid_count=now_raid_count;
  var disk_no='<{$disk_count}>';
  var m_raid=<{$sysconf.m_raid}>;
  if(now_raid_count!=0){
    if(Window_raid.isVisible() && button_click=="create"){
      Window_raid.hide();
    }
    if(Window_hot_spare.isVisible() && button_click=="hot_spare"){
      Window_hot_spare.hide();
    }
    check_radio();
    if(reload_flag==1){
      reloadUI2();
    }
    
    if( now_raid_count == 1 && /HA/.test(RAIDGrid.store.getAt(0).data.data_capacity) && '<{$ha_enable}>' != '1' ) {
         raid_ct.recover.setDisabled(false);
    } else {
        raid_ct.recover.setDisabled(true);
    }
  }else{
    if( <{$ha_enable}> != '1') {
        raid_ct.recover.setDisabled(false);
    }
    if(raidlock==0){
      raid_ct.create_raid.setDisabled(false);
      raid_ct.recover.setDisabled(false);
    }else{
      reloadUI2();
    }
  }
});

function check_radio(){
  var now_raid_count=RAIDGrid.getStore().getCount();
  var search_count=0,firstmd;
  for(var c=0;c<now_raid_count;c++){
    var md=RAIDGrid.getStore().getAt(c).get('md_num');

    var radioid="radio_"+md;
    if(c==0){
      firstmd=md;
    }
    if(Ext.getDom(radioid)){
          if(Ext.getDom(radioid).checked){
            radio_control(c,"");
            return true;
          }else{
            search_count++;
          }
    }
  }
  if(search_count==now_raid_count){
    Ext.getDom('radio_'+firstmd).checked=true;
    radio_control(0,"");
  }
}

function onLoadAddUser() 
{

}
function change_access_status(){
  if(TCode.desktop.Group.page!='raid'){
    clearTimeout(reloadUI2_time);
    return;
  }

  var request = eval('('+this.req.responseText+')');
  var div_value=request.div_value;
  var status=request.status;
  var edit=request.edit;
  var reload=request.reload;
  var m_raid=<{$sysconf.m_raid}>;
  var ha_enable=request.ha_enable;
  raid_ct.create_raid.setDisabled(true);
  raid_ct.edit_raid.setDisabled(true);
  //raid_ct.hot_spare.setDisabled(true);

  if(div_value==null) {
    div_value="";
  }

  if(reload==0){
    reload_flag=0;
    raid_store.load();
    if(edit==1){
      raid_ct.edit_raid.setDisabled(false);
    }
    if(ha_enable==0){ 
      if (m_raid==1 && request.create_btn==1 && raid_count<total_raid_limit){
        create=1;
        raid_ct.hot_spare.setDisabled(false);
        raid_ct.create_raid.setDisabled(false);
      }
    }else{
      if (m_raid==1 && request.create_btn==1 && raid_count<total_raid_limit && raid_count<total_haraid_limit){
        create=1;
        raid_ct.hot_spare.setDisabled(false);
        raid_ct.create_raid.setDisabled(false);
      }
      
      raid_ct.create_raid.setDisabled(true);
    }
    if (document.getElementById('access_status')) {
      document.getElementById('access_status').innerHTML="";
    }
  }else{
    if (document.getElementById('access_status')) {
      document.getElementById('access_status').innerHTML=div_value;
    }
    reload_flag=1;
    raid_store.load();
    reloadUI2_time = setTimeout("reloadUI2",5000);
  }
}

function reloadUI2(){
  processAjax("<{$geturl}>&action=getAccessStatus",change_access_status);
}

if('<{$display_pie_chart}>' == '0'){
  Ext.get("pie_chart_form").enableDisplayMode('none');
  Ext.get("pie_chart_form").hide();
}


<{if $recover_show == '1'}>
Window_recover_ha.show();
<{/if}>
<{include file="adm/raid_create.tpl"}>

</script>
