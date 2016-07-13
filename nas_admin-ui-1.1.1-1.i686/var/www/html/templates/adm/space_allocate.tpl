
<div id="space_allocate"></div>

<script text="text/javascript">
var raidunused=<{$raidunused}>;
var now_md="<{$now_md}>"; //record now raid id
var raid_capacity=1;
var now_add_id=''; //record now action id (iscsi or target usb)
var lvname='';//record will modify space id
var now_percent;//record select raid capacity percent
var tr_height='padding:1px';
var td_width=200;  
var text_tr_height='padding:1px 0px 0px 0px';
//var space_desp="<{$words.iscsi_block_size_msg}><br><{$words.iscsi_block_size_4k}><br><{$words.iscsi_block_size_512}>";
//var expand_desp="<{$words.iscsi_expend_note}>";
var raidun_precent;
var now_space_grid;
var now_type;
//var space_type_set=['iscsi','thin_iscsi','usb','thin_iscsi_mb'];
var space_type_set=<{$space_type}>;
var is_refresh;
var iscsi_own_capacity=0;
var thin_max_capacity=<{$thin_max_space}>;
var win_width=730;

function ExtDestroy(){ 
 Ext.destroy(
            Ext.getCmp('raid_id_store'),
            Ext.getCmp('raid_combox'),
            Ext.getCmp('raid_select'),
            Ext.getCmp('raid_store'),
            Ext.getCmp('raid_info'),
            Ext.getCmp('thin_iscsi_grid'),
            Ext.getCmp('space_tbar'),
            Ext.getCmp('iscsi_grid'),
            Ext.getCmp('usb_grid'),
            Ext.getCmp('thin_space_grid'),
            Ext.getCmp('spcae_table'),
            Ext.getCmp('space_panel'),
            Ext.getCmp('allocate_button'),
            Ext.getCmp('un_combox'),
            Ext.getCmp('en_radio'),
            Ext.getCmp('auth_radio'),
            Ext.getCmp('iscsi_name'),
            Ext.getCmp('year_store'),
            Ext.getCmp('year_combox'),
            Ext.getCmp('month_store'),
            Ext.getCmp('month_combox'),
            Ext.getCmp('user_name'),
            Ext.getCmp('password'),
            Ext.getCmp('password_comfirm'),
            Ext.getCmp('iscsi_int_info'),
            Ext.getCmp('option_table'),
            Ext.getCmp('space_form')
            );  
}

/*
* show this raid do not execute space allocation message.
* @param none
* @returns none.
*/   
function raid_busy_message(){
  Ext.Msg.show({
      title:"<{$gwords.space_allocate}>",
      msg: "<{$gwords.raid_lock_warning}>",
      buttons: Ext.Msg.OK,
      icon: Ext.MessageBox.INFO
    });  
}  

/*
* when execute space add or delete , raid info will update.
* @param none
* @returns none.
*/  
function update_raid_info(){
  var request = eval('('+this.req.responseText+')');
  raid_store.loadData(request.raid_info);
  now_md=request.now_md;
  if(now_type!=space_type_set[4]) {   
    now_space_grid.getStore().loadData(request.iscsi_info);  
    raidunused=request.raidunused;
    thin_max_capacity=request.thin_max_space;
    
    if(request.allocate_flag == 0){      
      now_space_grid.getTopToolbar().setDisabled(true);
      raid_busy_message();
    }else{
     if(now_space_grid.getId()==space_type_set[2]+'_grid'){     
       option_hide(now_space_grid,true,1,4);    
     }else if(now_space_grid.getId()==space_type_set[1]+'_grid'){       
       thin_iscsi_grid.getStore().loadData(request.thin_iscsi_info);
       option_hide(now_space_grid,true,1,2);
       option_hide(thin_iscsi_grid,true,3,4);
     }else{    
       option_hide(now_space_grid,false,1,4);
     }
     if(request.iscsi_disable_flag == "1" && now_space_grid.getId()==space_type_set[0]+'_grid'){
       now_space_grid.getTopToolbar().items.get(0).setDisabled(true);
     }
     lvname='';
    }
  }else{
    iscsi_block_size_select.setValue(request.iscsi_block_size);
    iscsi_crc_select.setValue(request.iscsi_crc);
  }
}  

/*
* when grid load , toolbar option operate.
* @param grid : load data of grid
*        id : store id
*        data_count: store record count
* @returns none.
*/  
function grid_option_edit(grid,id,data_count){
  grid.getTopToolbar().setDisabled(false);
  
  if(data_count==0){
     option_disabled(grid);     
  }
  
  if((data_count >= <{$open_iscsi}> && id == space_type_set[0]+"_store") || (data_count >= <{$open_target_usb}> && id == space_type_set[2]+"_store")){
    grid.getTopToolbar().items.get(0).setDisabled(true);
  }else if(id == space_type_set[1]+"_store"){
     if(data_count == 1){  
       grid.getTopToolbar().items.get(0).setDisabled(true);
       thin_iscsi_grid.show(); 
     }else{  
      thin_iscsi_grid.hide(); 
     }
  }else if(id == space_type_set[3]+"_store"){
     if (data_count >= <{$open_thin}>){
      thin_iscsi_grid.getTopToolbar().items.get(0).setDisabled(true);      
    }else{
      thin_iscsi_grid.getTopToolbar().items.get(0).setDisabled(false);
    }
  }  
}


/*
* when no any raid, will not setting any space allocation .
* @param none
* @returns none.
*/  
function disable_space(value){
  if(value=='ok'){
    setCurrentPage("raid");
    processUpdater("getmain.php","fun=raid");
  }
}

<{if $no_raid_flag == 1}>    
Ext.Msg.show({
           title:"<{$gwords.space_allocate}>",
           msg: "<{$gwords.raid_exist_warning}>",
           buttons: Ext.Msg.OK,
           icon: Ext.MessageBox.ERROR,
           fn:disable_space           
});
<{/if}>

/*
* setting space allocate and have error then will focus on error.
* @param value: error code
* @returns none.
*/
function error_status(value){    
  if(value == 1) {password_comfirm.focus(true);}
  else if(value == 2) {iscsi_name.focus(true); }
  else if(value == 3) {user_name.focus(true);}
  else if(value == 4) {password.focus(true);}
  else if(value == 5) {lun_combox.focus(true);}
}

/*
* set iscsi advace success.
* @param none.
* @returns none.
*/
function onLoadAdvace(){
  var request = eval('('+this.req.responseText+')'); 
  if(request.show){
    mag_box(request.topic,request.message,request.icon,request.button,request.fn,request.prompt);    
  }   
}

/*
* deal different grid will hide different toolbar option.
* @param thisobj : grid object
*        value : true or false (show or hide)
*        start : toolbar option start seat
*        end : toolbar option end seat
* @returns none.
*/
function option_hide(thisobj,value,start,end){
  if(value){
    for (i=start;i<=end;i++)
      thisobj.getTopToolbar().items.get(i).hide();
  }else{   
    for (i=start;i<=end;i++)
      thisobj.getTopToolbar().items.get(i).show();
  }   
}

/*
* disable grid toolbar (modify expand delete) when grid record is 0.
* @param thisobj : grid object
* @returns none.
*/
function option_disabled(grid){
  grid.getTopToolbar().items.get(2).setDisabled(true);  
  grid.getTopToolbar().items.get(4).setDisabled(true);
  grid.getTopToolbar().items.get(6).setDisabled(true); 
}

/*
* change user name and password status (disable or enable).
* @param obj: auth_radio
* @param obj: auth_radio new value
* @param obj: auth_radio old value
* @returns none.
*/
function disable_item(obj,newValue,oldValue ){
  if(newValue==0){
    user_name.setDisabled(true);
    password.setDisabled(true);
    password_comfirm.setDisabled(true);
  }else{
    user_name.setDisabled(false);
    password.setDisabled(false);
    password_comfirm.setDisabled(false);      
  }
}

/*
* option of space allocate setting will show or hide.
* @param value: true or false
* @returns none.
*/
function iscsi_item_show(value){
  Ext.getCmp('auth_title').setVisible(value);
  Ext.getCmp('auth_option').setVisible(value);
  Ext.getCmp('en_title').setVisible(value);
  Ext.getCmp('en_option').setVisible(value);
  Ext.getCmp('tname_title').setVisible(value);
  Ext.getCmp('tname_option').setVisible(value);
  Ext.getCmp('year_title').setVisible(value);
  Ext.getCmp('year_option').setVisible(value);
  Ext.getCmp('month_title').setVisible(value);
  Ext.getCmp('month_option').setVisible(value);
  Ext.getCmp('user_name_title').setVisible(value);
  Ext.getCmp('user_name_option').setVisible(value);
  Ext.getCmp('password_title').setVisible(value);
  Ext.getCmp('password_option').setVisible(value);
  Ext.getCmp('cpassword_title').setVisible(value);
  Ext.getCmp('cpassword_option').setVisible(value);  
  Ext.getCmp('password_option_desp').setVisible(value);
  Ext.getCmp('lun_title').setVisible(value);
  Ext.getCmp('lun_option').setVisible(value);
  
}
 
/*
* show edit form option allocate or thin allocate.
* @param select_type: toolbar option id
* @returns none.
*/
function capacity_item_show(select_type){
   if(select_type.indexOf(space_type_set[3],0) != -1){
     Ext.getCmp('thin_title').setVisible(true);
     Ext.getCmp('thin_select').setVisible(true);
     Ext.getCmp('unused_title').setVisible(false);
     Ext.getCmp('unused_title_option').setVisible(false);
   }else{
     Ext.getCmp('thin_title').setVisible(false);
     Ext.getCmp('thin_select').setVisible(false);
     Ext.getCmp('unused_title').setVisible(true);
     Ext.getCmp('unused_title_option').setVisible(true);  
   }
} 
 
/*
* option of space allocate setting will show or hide.
* @param value: true or false
* @returns none.
*/
function iscsi_modify_itme_show(value){
  Ext.getCmp('iqn_title').setVisible(value);    
  Ext.getCmp('iqn_option').setVisible(value);    
  Ext.getCmp('init_title').setVisible(value);    
  Ext.getCmp('init_option').setVisible(value);      
}

/*
* set pop windows position.
* @param value: true or false
* @returns none.
*/
function setWindowPosition(width,height){
  var ww = (document.body.clientWidth-width)/2;
  var hh = (document.body.clientHeight-height)/2;
  Window_space.setPagePosition(ww,hh);        
}

/*
* set vir.
* @param obj: virtual_size slider object 
* @returns none.
*/
function space_slider_setting(obj){
  obj.maxValue = now_percent;
  obj.minValue = 1;
  obj.setValue(now_percent,true,true); 
  obj.nrField2.dom.value = raid_capacity + un_combox.setMsg;
  obj.nrField.dom.innerHTML = raid_capacity + un_combox.setMsg;
  
}

/*
* show space allocate setting form(target usb ,iscsi add , iscsi modify).
* @param nones
* @returns none.
*/  
function show_space_form(){
  var request = eval('('+this.req.responseText+')');
  var tmp;
    
  <{if $hidden_column==0}>
  document.getElementById('common_title').innerHTML=request.raidid;     
  <{/if}>
  
  iscsi_own_capacity=0;
  iscsi_own_capacity = request.lv_capacity;
  raidun_precent = request.unused_percent;
  now_percent = request.unused_data_index;
  
  raidunused = request.raidunused;  
  tmp = request.unused_percent+" % (" +request.raidunused+" GB)";
  document.getElementById('common_allocation').innerHTML=tmp;
  document.getElementById('unused_title').innerHTML='<div style="'+tr_height+'">&nbsp;<{$words.allocation}>:</div>';
  document.getElementById('allocation_title').innerHTML='<div style="'+tr_height+'">&nbsp;<{$words.unused}>:</div>';  

  if(request.type == 'iscsi_modify')
    raid_capacity = request.lv_capacity;
  else
    raid_capacity = raidunused;
   
  if(request.type.indexOf(space_type_set[3],0) != -1){
//    thin_capacity.syncSize();
//    thin_capacity.syncThumb();
    thin_capacity.minValue = request.thin_space;
    thin_capacity.maxValue = request.thin_max_space;
    thin_capacity.setValue(request.space_index,true,true);
  }else{
//    un_combox.syncThumb();
//    un_combox.syncSize();
    space_slider_setting(un_combox);  
  }
  
  iscsi_name.setValue(request.iscsi_name);
  user_name.setValue(request.username);
  password.setValue(request.password);
  password_comfirm.setValue(request.password);
  iscsi_int_info.setValue(request.init_info);
  if(request.iscsi_iqn != null) 
    document.getElementById('iqn_option').innerHTML = request.iscsi_iqn;
  else
    document.getElementById('iqn_option').innerHTML = '';
    
  if(request.enable != null){
    en_radio.setValue(request.enable);      
 //     disable_item('',request.enable,'');
  }
  
  if(request.auth != null){      
    auth_radio.setValue(request.auth);
    disable_item('',request.auth,'');    
  }
  
  if(request.year_data != null){
    year_store.loadData(request.year_data);
    year_combox.setValue(request.year_index);
  }    
  
  if(request.month_data != null){
    month_store.loadData(request.month_data); 
    month_combox.setValue(request.month_index);
  }
  
  if(request.lun_data != null){
    lun_store.loadData(request.lun_data);
    lun_combox.setValue(request.lun_index);
  }
  document.getElementById("space_description").innerHTML = request.desp;
  allocate_button.setText('<{$gwords.ok}>');
  if(request.show_lun == 0){
    lun_combox.setDisabled(true);
  }
}

/*
* display pop window for add or modify iscsi or add target usb.
* @param object: option object(modify or add iscsi or modify iscsi)
* @returns none.
*/
function show_edit_form(object){
  var now_windows_title;
  var option_type;
  
  if(object.id.indexOf("add",0) != -1)
    option_type=0;
  else
    option_type=1;
    
  if(option_type==0){
    if (object.id != space_type_set[3]+"_add"){
      if (raidunused <1){ 
        Ext.Msg.show({
          title:"<{$gwords.space_allocate}>",
          msg: "<{$words.space_not_enough}>",
          buttons: Ext.Msg.OK,
          icon: Ext.MessageBox.ERROR
        });
        return ;
      }
    } else {
      if (thin_max_capacity <1){ 
        Ext.Msg.show({
          title:"<{$gwords.space_allocate}>",
          msg: "<{$words.space_not_enough}>",
          buttons: Ext.Msg.OK,
          icon: Ext.MessageBox.ERROR
        });
        return ;      
      }
    }  
  } 
    
  option_table.setVisible(true);
  iscsi_expand_table.setVisible(false);

  if(option_type==0){    
    if(object.id == (space_type_set[2]+'_add') || object.id == (space_type_set[1]+'_add')){
       var win_height;
       if(Ext.isIE)
         win_height = 220;
       else
         win_height = 200;       
         win_height+=100;
       
       if(object.id == (space_type_set[2]+'_add'))
         now_windows_title='<{$words.usb_title}>';
       else
         now_windows_title='<{$words.thin_space_title_create}>';         
       
       iscsi_item_show(false);
       iscsi_modify_itme_show(false);
       un_combox.setDisabled(false);
       Window_space.setSize(win_width,win_height);
       setWindowPosition(win_width,win_height);
     }else{
       if(Ext.isIE)
         win_height = 510;
       else
         win_height = 500;
       iscsi_item_show(true);
       iscsi_modify_itme_show(false);
       un_combox.setDisabled(false);
       thin_capacity.setDisabled(false); 
       if(object.id == (space_type_set[0]+'_add'))
         now_windows_title='<{$words.iscsi_title_create}>';
       else
         now_windows_title='<{$words.thin_iscsi_title_create}>';
       
       Window_space.setSize(win_width,win_height);
       setWindowPosition(win_width,win_height);
         //Window_space.setWidth(500); 
     }     
  }else{
    var m,this_grid,type_title;
    var win_height;
    if(Ext.isIE)
      win_height = 580;
    else
      win_height = 580;
    if (object.id.indexOf(space_type_set[3],0) == -1){
      this_grid = now_space_grid; 
      type_title = "<{$words.iscsi_title_modify}>";
    }else{
      this_grid = thin_iscsi_grid;
      type_title = "<{$words.thin_iscsi_title_modify}>";
    }
    
    m = this_grid.getSelections();       

    if(m.length > 0){
      if(!Window_space.isVisible()){
        lvname = this_grid.getSelectionModel().getSelected().get("lv");
      }   
    }else{
      Ext.Msg.show({
        title:type_title,
        msg: "<{$words.user_no_select}>",
        buttons: Ext.Msg.OK,
        icon: Ext.MessageBox.ERROR
      });
      
      return;
    }
   
    iscsi_item_show(true);
    iscsi_modify_itme_show(true);
    un_combox.setDisabled(true);
    thin_capacity.setDisabled(true);
    now_windows_title=type_title;
    Window_space.setSize(win_width,win_height);
    setWindowPosition(win_width,win_height);
  }
  
  capacity_item_show(object.id); 
  Ext.getCmp('space_fieldset').setTitle(now_windows_title);
  now_add_id=object.id;
//    Window_space.add(space_form);  
  Window_space.show();  
  processAjax('getmain.php?fun=space_allocate_data',show_space_form,"&md="+now_md+"&type="+object.id+"&lv="+lvname);
}  

/*
* display iscsi expand option.
* @param none
* @returns none.
*/
function show_iscsi_expand_option(){
  var request = eval('('+this.req.responseText+')');  
  document.getElementById("iscsi_expand_name").innerHTML = request.iscsi_name;
  tmp=request.unused_percent+" % (" +request.raidunused+" GB)";
  document.getElementById("iscsi_expand_unused").innerHTML = tmp;
  raidun_precent=request.unused_percent;
  now_percent=request.unused_percent;
  raidunused=request.raidunused;
  raid_capacity=raidunused;
  space_slider_setting(expand_unused);
  document.getElementById("space_description").innerHTML=request.desp;
  allocate_button.setText('<{$gwords.expand}>');
}

/*
* show iscsi expand form.
* @param object : toolbar option object
* @returns none.
*/
function show_expand_form(object){
  var m = now_space_grid.getSelections();
  var form_title,name_title;
  if(now_space_grid.getId() == space_type_set[0]+"_expand"){
    form_title = "<{$words.iscsi_expand_title}>";
    name_title = "&nbsp;<{$gwords.name}>:";
  }else{
    form_title = "<{$words.thin_space_title_expand}>";
    name_title = "&nbsp;<{$gwords.raid_id}>:";
  }
  
  if (raidunused <1){ 
    Ext.Msg.show({
      title:form_title,
      msg: "<{$words.expand_fail}>",
      buttons: Ext.Msg.OK,
      icon: Ext.MessageBox.ERROR
    });
    return ;
  } 

  if(m.length > 0){
    if(!Window_space.isVisible()){
      lvname = now_space_grid.getSelectionModel().getSelected().get("lv");
    }   
  }else{
    Ext.Msg.show({
      title:form_title,
      msg: "<{$words.user_no_select}>",
      buttons: Ext.Msg.OK,
      icon: Ext.MessageBox.ERROR
    });
      
    return;
  }

  iscsi_expand_table.setVisible(true);
  option_table.setVisible(false); 
  Window_space.setSize(win_width,280); 
  setWindowPosition(win_width,280);
  
  Ext.getCmp('space_fieldset').setTitle(form_title);
  now_add_id=object.id;
  Window_space.show(); 
  Ext.getCmp('iscsci_expand_title').setTitle(name_title);
  processAjax('getmain.php?fun=space_allocate_data',show_iscsi_expand_option,"&md="+now_md+"&type="+object.id+"&lv="+lvname);
}

/*
* calculate disk capacity.
* @param object: option object(modify or add iscsi or modify iscsi)
* @returns none.
*/
function ForDight(Dight,How){ 
  Dight = Math.round  (Dight*Math.pow(10,How))/Math.pow(10,How);  
  return Dight;  
}
  
/*
* exectue option setting success and click 'OK' button to do.
* @param value: 
* @returns none.
*/
function execute_success(value){
  if(Window_space.isVisible())
    Window_space.hide();     
  processAjax('getmain.php?fun=space_allocate',update_raid_info,"&md="+now_md+"&select_action=1&type="+now_type);
}

/*
* exectue option setting success will show message.
* @param none. 
* @returns none.
*/
function execute_space_prccess(){
  var request = eval('('+this.req.responseText+')');
  if(request.show){
    mag_box(request.topic,request.message,request.icon,request.button,request.fn,request.prompt);
  } 
}

/*
* exectue delete space allocate.
* @param obj:delete object. 
* @returns none.
*/
function delete_space(obj){
  var m,this_grid;
  if (obj.id.indexOf(space_type_set[3],0) == -1)
    this_grid = now_space_grid; 
  else
    this_grid =thin_iscsi_grid;

  m = this_grid.getSelections();   
  
  if(m.length > 0){
    if(!Window_space.isVisible()){
      lvname = this_grid.getSelectionModel().getSelected().get("lv");
      now_add_id=obj.id;
      Ext.Msg.confirm("<{$gwords.space_allocate}>","<{$words.del_confirm}>",function(btn){
        if(btn=='yes'){
          processAjax('setmain.php?fun=setspace_allocate',execute_space_prccess,"&now_add_id="+now_add_id+"&md="+now_md+"&use_capacity="+this_grid.getSelectionModel().getSelected().get("capacity")+"&lvname="+lvname);
        }
      })
    }   
  }else{
    Ext.Msg.show({
      title:"<{$gwords.del_confirm}>",
      msg: "<{$words.user_no_select}>",
      buttons: Ext.Msg.OK,
      icon: Ext.MessageBox.ERROR
    });
    
    return;
  }
} 
  
<{if $raid_count!=1 && $raid_count!=0}>
//raid id
var raid_id_store=new Ext.data.JsonStore({
  fields: ['md_num','raidid'],
  data:<{$raid_combox_info}>
});

//select raid combox    
var raid_combox =  new Ext.form.ComboBox({
  store: raid_id_store,
  valueField :"md_num",
  displayField:"raidid",
  mode: 'local',
  forceSelection: true,
  editable: false,
  triggerAction: 'all',
  hiddenName:'md',
  value:<{$now_md}>,
  height:50,
  listWidth:100,
  width:150
});

//when select raid will change info
raid_combox.on('select',function(obj,record,index){
  processAjax('getmain.php?fun=space_allocate',update_raid_info,"&md="+record.data['md_num']+"&select_action=1&type="+now_type);
    
  })
<{/if}>

//raid total info
var raid_store= new Ext.data.JsonStore({
  fields: ['m_raid','id','raid_level','status','udisks','total_capacity','data_capacity'
            <{if $open_snapshot=="1"}>
            ,'snapshot_capacity'
            <{/if}>
            <{if $open_target_usb=="1"}>
            ,'usb_capacity'
            <{/if}>
            <{if $open_iscsi!="0"}>
            ,'iscsi_capacity'
            <{/if}>],
  data: <{$raid_info}>
});
  
//raid total info grid
var raid_info = new Ext.grid.GridPanel({
  store: raid_store, 
  width:<{if $lang=='fr' || $lang=='de'}>570<{else}>630<{/if}>,
  height:100,
  trackMouseOver:true,
  disableSelection:true,
  loadMask: true,
  enableHdMenu:false,
  bodyStyle:'padding:0px',
  viewConfig: {
                forceFit:true,
                autoFill : true,
                scrollOffset: -1
               },
  columns: [
              <{if $hidden_column==0}>
              {header: '  <{$words.Raid_master}>',width:50,  dataIndex: 'm_raid', sortable: false},
              {header: '  <{$words.Raid_id}>', width:70, dataIndex: 'id', sortable: false},
              <{/if}>
              {header: '  <{$words.Raid_level}>', width:50, dataIndex: 'raid_level', sortable: false}, 
              {header: '  <{$gwords.status}>', width:70, dataIndex: 'status', sortable: false}, 
              {header: '  <{$words.Raid_disk_used}>', width:70, dataIndex: 'udisks', sortable: false},
              {header: '  <{$words.Raid_total}>', width:70, dataIndex: 'total_capacity', sortable: false},
              {header: '  <{$words.Raid_data}>', width:110, dataIndex: 'data_capacity', sortable: false }
              <{if $open_snapshot=="1"}>
       //       ,{header: '  <{$words.Raid_snapshot}>', width:70, dataIndex: 'snapshot_capacity', sortable: false }
              <{/if}>
              <{if $open_target_usb=="1"}>
              ,{header: '  <{$words.Raid_usb}>', width:70, dataIndex: 'usb_capacity', sortable: false }
              <{/if}>
              <{if $open_iscsi!="0"}>
              ,{header: '  <{$words.Raid_iscsi}>', width:70, dataIndex: 'iscsi_capacity', sortable: false }   
              <{/if}>
           ]
});

var space_tab_height;
space_tab_height = 345;
  
var space_tabpanel = new Ext.TabPanel({
  id:'space_tabpanel',
  autoTabs:true,
  activeTab:0,
  border:true,
	bodyStyle:'padding:0px 0px 0px 0px;',  
	width: 635,
	height : space_tab_height,
	layoutOnTabChange: true,
	autoScroll:true,
	frame: true//,
});
  
space_tabpanel.on('beforetabchange',function(thisobj,newTab,currentTab){ 
  if(currentTab==null)
    is_refresh=0;
  else
    is_refresh=1;
});

space_tabpanel.on('tabchange',function(thisobj,newTab,currentTab){ 
  now_type=newTab.id;        
  now_space_grid=newTab.items.get(0);

  if(is_refresh==1)
    processAjax('getmain.php?fun=space_allocate',update_raid_info,"&md="+now_md+"&select_action=1&type="+now_type);
});

function create_space_grid(tab_title,space_type,grid_id){    
//raid space allocate info  
  var space_store = new Ext.data.JsonStore({
    id:grid_id+'_store',
    fields: ['type','name','capacity','modify_flag','lv']
//    data: <{$iscsi_info}>
  });  

//space allocate option
   var space_tbar =new Ext.Toolbar({
     id:grid_id+'_bar',
     items :[{
               id:grid_id+'_add',
               text:'<{$gwords.add}>',
               iconCls:'add',
               handler:show_edit_form
             },'-',{
               id:grid_id+'_modify',
               text:'<{$gwords.modify}>',
               iconCls:'edit',
               handler:show_edit_form
             },'-',{
               id:grid_id+'_expand',
               text:'<{$gwords.expand}>',
               iconCls:'edit',
               handler:show_expand_form
             },'-',{
               id:grid_id+'_delete',
               text:'<{$gwords.delete}>',
               iconCls:'remove',
               handler:delete_space
             }]
   });
   
  //raid space allocate info grid
  var space_grid = new Ext.grid.GridPanel({
    title:tab_title,
    id:grid_id+"_grid",
//    width:300,
//    height:150,
//    autoHeight:true,
    autoscroll:true,
    store: space_store,
    trackMouseOver:true,
    disableSelection:false,
    loadMask: true,
    bodyStyle:'padding:0px',
     // grid columns
    columns:[{id: 'type', header: '<{$words.allocate_type}>', dataIndex: 'type',width: 250, sortable: true},
             {id: 'name', header: '<{$gwords.name}>', dataIndex: 'name', width: 250, sortable: true},
             {id: 'capacity', header: '<{$gwords.capacity}>', dataIndex: 'capacity', width: 99, sortable: true}
            ],
    tbar:space_tbar
  });   

  //when space_grid data is empty will disable iscsi_modify,space_delete
  space_grid.getStore().on('load',function(obj,records){    
    grid_option_edit(space_grid,obj.id,records.length);
  });

  //check iscsi_modify is disable or enable
/*  space_grid.on('cellclick',function(grid,rowIndex,columnIndex,e){
    var record=grid.getStore().getAt(rowIndex);
    if (record.data['modify_flag']==0) {
      option_disabled(true);
    }else{
      option_disabled(false);
    }
  });
*/          
  if(space_tabpanel.items.length==0)
    now_space_grid=space_grid;

  return space_grid; 
}

<{if $open_iscsi!="0"}>
  var iscsi_grid = create_space_grid("",1,space_type_set[0]); 
  var iscsi_panel = new Ext.Panel({
    title:"<{$gwords.iscsi_target}>",
    name:'iscsi_panel',
    id:space_type_set[0],
    layout:'fit',
    frame:true,
    bodyStyle:'padding:0px 0px 0px 0px;',
    items:[iscsi_grid]
  });
  space_tabpanel.add(iscsi_panel);
<{/if}>

<{if $open_thin!="0"}>
  var thin_space_grid = create_space_grid("<{$words.thin_space_title}>",1,space_type_set[1]);
  var thin_iscsi_grid = create_space_grid("<{$words.thin_iscsi}>",2,space_type_set[3]);
  if(Ext.isIE){
    thin_iscsi_grid.width=621;  
    thin_iscsi_grid.height=200;  
  }else{
    thin_iscsi_grid.width=621;
    thin_iscsi_grid.height=180;      
  }
//thin_iscsi_grid.setAutoScroll(true);
  thin_space_grid.autoHeight=true;
  var thin_panel = new Ext.Panel({
     title:"<{$words.thin_iscsi_title}>",
     name:'thin_panel',
     id:space_type_set[1],
     frame:true,
     layout:'fit',
     bodyStyle:'padding:0px 0px 0px 0px;',    
     items: [thin_space_grid,{height:10},thin_iscsi_grid]
  }); 
  space_tabpanel.add(thin_panel);
<{/if}>

<{if $open_target_usb=="1"}>
  var usb_grid = create_space_grid("",0,space_type_set[2]);
  var usb_panel = new Ext.Panel({
    title:"<{$gwords.target_usb}>",
    name:'usb_panel',
    id:space_type_set[2],
    frame:true,
    layout:'fit',
    bodyStyle:'padding:0px 0px 0px 0px;',  
    items:[usb_grid]
  });
  space_tabpanel.add(usb_panel);
<{/if}>

<{if $open_iscsi!="0"}>
  //advance option iscsi block data
  var block_size_store=new Ext.data.SimpleStore({
    fields: ['value','display'],
    data:eval('<{$block_size_data}>')
  });
  
  //iscsi block size select cmobox
  var iscsi_block_size_select =  new Ext.form.ComboBox({
    fieldLabel:"&nbsp;<{$words.iscsi_block}>",
    store: block_size_store,
    valueField :"value",
    displayField:"display",
    mode: 'local',
    forceSelection: true,
    editable: false,
    triggerAction: 'all',
    hiddenName:'advance_iscsi_block_size',
     // hideLabel:true,
    value:'<{$iscsi_block_size}>',
    listWidth:200,
    width:150   
  });
  
  //iscsi crc data
  var crc_store=new Ext.data.SimpleStore({
    fields: ['value','display'],
    data:eval('<{$crc_data}>')
  });
  
  //iscsi crc select cmobox
  var iscsi_crc_select =  new Ext.form.ComboBox({
    store: crc_store,
    fieldLabel:"&nbsp;<{$words.iscsi_crc}>",
    valueField :"value",
    displayField:"display",
    mode: 'local',
    forceSelection: true,
    editable: false,
    triggerAction: 'all',
    hiddenName:'advance_iscsi_crc',
    //hideLabel:true,
    value:'<{$iscsi_crc}>',
    listWidth:100,
    width:150   
  });
  
  //iscsi advance apply button
  var advance_apply= new Ext.Button({
    id : 'advance_apply',
    disabled : false,
    minWidth:80,
    text:'<{$gwords.apply}>',
    handler : function() {      
               //   alert(advance_form.getForm().getValues(true));
              //    return;
                Ext.Msg.confirm("<{$gwords.space_allocate}>","<{$gwords.confirm}>",function(btn){
                 if(btn=='yes'){
                   if(advance_form.getForm().isValid())
                     processAjax('setmain.php?fun=setspace_allocate_advance',onLoadAdvace,advance_form.getForm().getValues(true));
                 }
                });
              } 
  });
  
  //advance iscsi option form
  var advance_form = new Ext.FormPanel({
    id:'advance_form',
    title: "<{$words.advance_title}>",
  //    width:100,
    height:10, 
    method: 'POST',
    buttonAlign:'left',
    waitMsgTarget:true,
    hideBorders:false,
    labelWidth:150,
    frame:true,
    items: [iscsi_block_size_select,iscsi_crc_select,advance_apply,
            {  
              xtype:'fieldset', 
              title:"<{$gwords.description}>",
              height:120,
              autoScroll:true,              
              width:600,
              style:'margin-top:10px',
              // defaults:{style:''},
              //defaults: {width: 660},
              items:[{
                      html:"<{$words.iscsi_block_size_msg}><br><{$words.iscsi_block_size_4k}><br><{$words.iscsi_block_size_512}>" 
              }]
            }
           ]
      
  });   
  space_tabpanel.add(advance_form);
<{/if}>



/*  var space_panel = new Ext.Panel({
    title: '<{$gwords.space_allocate}>',
  //  renderTo:'space_allocate',
    items: [
      {
        xtype:'fieldset', 
        title:'<{$gwords.space_allocate}>',
        autoHeight:true,
        height: 390,
        width: 690,
        //defaults: {width: 640},
        defaultType: 'table',
        collapsed: false,   
        items:[spcae_table]
      }]
  });
*/  
  
//space allocate tab  
/*var tabpanel = new Ext.TabPanel({
  id:'tabpanel',
  autoTabs:true,
  activeTab:0,
  deferredRender:false,
  border:true,
	renderTo:'space_allocate',
	bodyStyle:'padding:0px 0px 0px 0px;',  
	width: 695,
	height : 480,
	//defaults:{bodyStyle:'padding:0px'},
	items: [spcae_table
	       <{if $open_iscsi > "0"}>
	        ,advance_form
	        <{/if}>
	       ]
});  
*/



//set space allocte button(add or modify)
var allocate_button= new Ext.Button({
  id : 'share_select',
  disabled : false,
  minWidth:80,
  text:'<{$gwords.ok}>',
  handler : function() {
    var post_data,now_form='',comfirm,title,option_type; 
      
    switch(now_add_id){
      case space_type_set[0]+'_add':
        title="<{$words.iscsi_title_create}>";
        comfirm="<{$words.add_iscsi_confirm}>";      
        break;
      case space_type_set[1]+'_add':
        title="<{$words.thin_space_title}>";
        comfirm="<{$words.space_create_comfirm}>";      
        break;
      case space_type_set[2]+'_add':
        comfirm="<{$words.add_usb_confirm}>";
        title="<{$words.usb_title}>";  
        break;
      case space_type_set[3]+'_add':
        title="<{$words.thin_iscsi_title}>";
        comfirm="<{$words.thin_create_comfirm}>";  
        break;
      case space_type_set[0]+'_modify':
        title="<{$words.iscsi_title_modify}>";
        comfirm="<{$words.modify_iscsi_confirm}>";
        break;
      case space_type_set[3]+'_modify':
        title="<{$words.thin_iscsi_title}>";
        comfirm="<{$words.thin_modify_comfirm}>"; 
        break;
      case space_type_set[0]+'_expand':
        title="<{$words.iscsi_title_modify}>";
        comfirm="<{$words.expand_prompt}>";
        break;
      case space_type_set[1]+'_expand':
        title="<{$words.thin_space_title}>";
        comfirm="<{$words.expand_prompt}>";
        break;  
    }  
    //  alert(space_form.getForm().getValues(true)+"&now_add_id="+now_add_id+"&now_md="+now_md+"&lvname="+lvname+"&percent="+now_percent);
    //  return;
    if(now_add_id.indexOf("_expand",0) != -1){
      if(space_form.getForm().isValid()){
        Ext.Msg.prompt(title,comfirm,function(btn,text){
          if(btn=='ok'){
            if(text=='Yes')
              processAjax('setmain.php?fun=setspace_allocate',execute_space_prccess,space_form.getForm().getValues(true)+"&now_add_id="+now_add_id+"&md="+now_md+"&lvname="+lvname+"&percent="+now_percent);
            else{
         		  Ext.Msg.show({
                 title:title,
                 msg: "<{$words.prompt_fail}>",
                 buttons: Ext.Msg.OK,
                 icon: Ext.MessageBox.INFO         
              });
            } 
          }
        })
      }    
    }else{  
      if(space_form.getForm().isValid()){
        Ext.Msg.confirm(title,comfirm,function(btn){
          if(btn=='yes'){
            processAjax('setmain.php?fun=setspace_allocate',execute_space_prccess,space_form.getForm().getValues(true)+"&now_add_id="+now_add_id+"&md="+now_md+"&lvname="+lvname+"&percent="+now_percent);
          }
        })
      }     
    }        
  } 
});    
  
//typeof Ext.Slider
Ext.form.SliderFields = Ext.extend(Ext.Slider, {
  isFormField: true
  ,setMsg:''
  ,setZero:''
  ,setM:1
  ,setD:1
  ,setF:0
  ,tValue:0
  ,onRender: function(){
    Ext.form.SliderField.superclass.onRender.apply(this, arguments);
    if (this.value == 0)
      v=this.setZero;
    else
      v=this.value+this.setMsg;
      this.nrField = this.el.createChild({
        //tag: 'input', type: 'text', name: this.name, value: v, readonly: 'readonly', style: 'position: relative; float:right; height:20px; left: 80px; margin-top:-20px; font-size:12px;width:60px;'
        tag: 'label', html: v, style: 'position: relative; float:right;height:20px; left: 120px; margin-top:-20px; font-size:12px;width:100px;'
      });
      this.nrField2 = this.el.createChild({
        tag: 'input', type: 'hidden', name: this.name, value: v, readonly: 'readonly', style: 'position: relative; float:right; height:20px; left: 80px; margin-top:-20px; font-size:12px;width:60px;'
        //tag: 'label', html: v, style: 'position: relative; float:right;height:20px; left: 80px; margin-top:-20px; font-size:12px;width:60px;'
      });
  }
  ,setValue: function(v,animate,comp) {
    if(this.maxValue && v > this.maxValue) v = this.maxValue;
    if(this.minValue && v < this.minValue) v = this.minValue;    
    Ext.form.SliderField.superclass.setValue.apply(this, arguments);
    this.halfThumb = (this.vertical ? this.thumb.getHeight() : this.thumb.getWidth())/2;
    this.thumb.shift({left: this.translateValue(v), stopFx: true, duration:.35});
  }
  ,markInvalid: Ext.emptyFn
  ,clearInvalid: Ext.emptyFn
  ,validate: function(){this.nrField.dom.disabled=false;this.nrField2.dom.disabled=false;return true;}
}); 

Ext.reg('sliderfields', Ext.form.SliderFields);  

//show slider tip 
function unused_slider(id_name){
  var tip1 = new Ext.ux.SliderTip({
    getText: function(slider){
      return String.format('<b>{0}%</b>', slider.getValue());
    }
  });   


//unused capacity select 
  var slider = new Ext.form.SliderFields({
    xtype: 'sliderfield',
    name: id_name,
    id: id_name,
    width: 150,
    increment: 1,
    minValue: 1,
    setMsg:' GB',
    setZero:'0 %',
    hideLabel:true,
    plugins: tip1
  });

  slider.on('changecomplete',function(thisobj,value){
    var tValue=0;
    now_percent=value;

    if (value == 0){      
        thisobj.nrField2.dom.value = this.setZero;
        thisobj.nrField.dom.innerHTML = this.setZero;//Math.round  (Dight*Math.pow(10,How))/Math.pow(10,How); 
    }else{
        if(value == thisobj.maxValue){
          tValue=raid_capacity;
          thisobj.nrField2.dom.value = tValue + this.setMsg;
          thisobj.nrField.dom.innerHTML = tValue + this.setMsg;
        }else{
          tValue=ForDight((raidunused*value)/raidun_precent,1);          
          thisobj.nrField2.dom.value = tValue + this.setMsg;
          thisobj.nrField.dom.innerHTML = tValue + this.setMsg;
        }  
    }

    if( (iscsi_own_capacity+tValue) > parseFloat(<{$max_size_for_lv}>)){
		  Ext.Msg.show({
           title:"<{$gwords.space_allocate}>",
           msg: "<{$words.lv_16t_size_limit}>",
           buttons: Ext.Msg.OK,
           icon: Ext.MessageBox.ERROR         
      });
		  thisobj.setValue(1);
	  }
  });

  return slider;
}

var un_combox = unused_slider('use_capacity');
var expand_unused = unused_slider('expand_capacity');


var lun_store = new Ext.data.JsonStore({
  fields: ['lun_id']
});

//select raid combox    
var lun_combox =  new Ext.form.ComboBox({
  store: lun_store,
  valueField: "lun_id",
  displayField: "lun_id",
  mode: 'local',
  forceSelection: true,
  editable: false,
  triggerAction: 'all',
  hiddenName:'lun_id',
  hideLabel: true,
  maxHeight: 150,
  width:80 
});

//enable iscsi 
var en_radio= new Ext.form.RadioGroup({
  id:'enable',
  width:200,
  hideLabel:true,
  items: [{boxLabel: '<{$gwords.enable}>', name: 'enable', inputValue: 1 <{if $enable==1}>,checked:true<{/if}> , width:100},
          {boxLabel: '<{$gwords.disable}>', name: 'enable', inputValue: 0 <{if $enable==0}>,checked:true<{/if}> }
         ]  
});
 
//auth is disable or enable
var auth_radio= new Ext.form.RadioGroup({
  id:'auth',
  width:200,
  hideLabel:true,
  items: [{boxLabel: '<{$words.iscsi_none}>', name: 'auth', inputValue: 0 <{if $auth==0}>,checked:true<{/if}> , width:100},
          {boxLabel: '<{$words.iscsi_chap}>', name: 'auth', inputValue: 1 <{if $auth==1}>,checked:true<{/if}>}             
         ]  
});  

auth_radio.on('change',disable_item);

//iscsi name
var iscsi_name=new Ext.form.TextField({
  id:'iscsi_name',
  name:'iscsi_name',
  maxLength:12,
  hideLabel:true
});

//year info
var year_store=new Ext.data.JsonStore({
  fields: ['year']
});

//year select
var year_combox =  new Ext.form.ComboBox({
  store: year_store,
  valueField :"year",
  displayField:"year",
  mode: 'local',
  forceSelection: true,
  editable: false,
  triggerAction: 'all',
  hiddenName:'iscsi_year',
  hideLabel:true,
  value:'<{$year_index}>',
  maxHeight: 150,
  width:80    
});
  
//month info
var month_store=new Ext.data.JsonStore({
  fields: ['month','display']
});

//month select
var month_combox =  new Ext.form.ComboBox({
  store: month_store,
  valueField :"month",
  displayField:"display",
  mode: 'local',
  forceSelection: true,
  editable: false,
  triggerAction: 'all',
  hiddenName:'iscsi_month',
  hideLabel:true,
  value:'<{$month_index}>',
  maxHeight: 150,
  width:80    
});

//auth for user name
var user_name=new Ext.form.TextField({
  id:'username',
  name:'username',
  maxLength:12,
  hideLabel:true
});  

//auth for user's password
var password=new Ext.form.TextField({
  id:'password',
  inputType:'password',
  maxLength:16,
  hideLabel:true
});

//comfirm password
var password_comfirm=new Ext.form.TextField({
  id:'password_comfirm',
  inputType:'password',
  maxLength:16,
  hideLabel:true
});
  
//iscsi enable info  
var iscsi_int_info=new Ext.form.TextArea({
  id:'init_info',
  name:'init_info',
//  maxLength:250,
  width:250,
  height:60,
  hideLabel:true,
  readOnly :true
});  

var thin_tip = new Ext.ux.SliderTip({
	getText: function(slider){
    return String.format('<b>{0}GB</b>', slider.getValue());
  }
}); 

var thin_capacity = new Ext.form.SliderFields({
   	xtype: 'sliderfield',
    name: 'virtual_size',
    id: 'virtual_size',
    width: 130,
    increment: 1,
    minValue: <{$thin_capacity_min}>,
    maxValue: <{$thin_max_space}>,
    setMsg:' GB',
    setZero:'0',
    style:"margin-top:2px",
    plugins: thin_tip
});

thin_capacity.on('changecomplete',function(thisobj,newvalue){
  thisobj.nrField.dom.innerHTML = newvalue + thisobj.setMsg;
  this.nrField2.dom.value = newvalue + this.setMsg;
});



//iscsi option setting table
var option_table = new Ext.Panel({
  layout:'table',
  name:'option_table1',
 // width: 480,
//    height:210,
  autoHeight:true,
  defaults: {
    // applied to each contained panel
//        bodyStyle:'padding:10px',
//        height:50,
        
  },
  layoutConfig: {
    // The total column count must be specified here
    columns: 3
  },
  items: [
          <{if $hidden_column==0}>
          {             
            xtype:'panel',
            bodyStyle:tr_height,
            width:td_width,
            html:"&nbsp;<{$gwords.raid_id}>:"
          },{
            xtype:'panel',
            colspan: 2,
            bodyStyle:tr_height,
            id:'common_title'
          },
          <{/if}>
          {
            xtype:'panel',
            bodyStyle:tr_height,
            id:'allocation_title',
            width:td_width,
            html:"&nbsp;<{$words.allocation}>:"
          },{
            xtype:'panel', 
            bodyStyle:tr_height,
            colspan: 2,
            id:'common_allocation'
          },{
            xtype:'panel',
            bodyStyle:tr_height,
            id:'thin_title',
            width:td_width,
            html:"&nbsp;<{$words.virtual_size}>"
          },{
            id:'thin_select',
            colspan: 2,
            items:[thin_capacity]  
          },{
            xtype:'panel',
            width:td_width,
            bodyStyle:tr_height, 
            id:'unused_title',
            html:"&nbsp;<{$words.unused}>:"
          },{
            width:350,
            colspan: 2,
            id:'unused_title_option',           
            items:[un_combox]
          },{
            xtype:'panel',
            width:td_width,
            bodyStyle:tr_height, 
            html:"&nbsp;<{$words.iscsi_enable}>:",   
            id:'en_title'
          },{
            id:'en_option',
            colspan: 2,
            items:[en_radio]             
          },{
            xtype:'panel',
            width:td_width,
            bodyStyle:tr_height, 
            html:"&nbsp;<{$words.iscsi_name}>:",   
            id:'tname_title'
          },{
            id:'tname_option',
            colspan: 2,
            bodyStyle:text_tr_height,
            items:[iscsi_name,{
                   xtype:'label'
                   ,html:"<span style='color:red'><{$words.target_name_limit}></span>"
                   }]
          },{
            xtype:'panel',
            width:td_width,
            bodyStyle:tr_height, 
            html:"&nbsp;<{$words.iscsi_year}>:",   
            id:'year_title'
          },{
            id:'year_option',
            colspan: 2,
            items:[year_combox]
          },{
            xtype:'panel',
            width:td_width,
            bodyStyle:tr_height, 
            html:"&nbsp;<{$words.iscsi_month}>:",   
            id:'month_title'
          },{
            id:'month_option',
            colspan: 2,
            items:[month_combox]
          },{
            xtype:'panel',
            width:td_width,
            bodyStyle:tr_height, 
            html:"&nbsp;<{$words.lun_id}>:",   
            id:'lun_title'
          },{
            id:'lun_option',
            colspan: 2,
            items:[lun_combox]
          },{
            xtype:'panel',
            width:td_width,
            bodyStyle:tr_height, 
            html:"&nbsp;<{$words.iscsi_auth}>:",   
            id:'auth_title'
          },{
            id:'auth_option',
            colspan: 2,
            items:[auth_radio]
          },{
            xtype:'panel',
            width:td_width,
            bodyStyle:tr_height, 
            html:"&nbsp;<{$gwords.username}>:",   
            id:'user_name_title'
          },{
            id:'user_name_option',
            colspan: 2,
            bodyStyle:text_tr_height,
            items:[user_name,{
                   xtype:'label',
                   html:"<span style='color:red'><{$words.username_limit}></span>"
                   }]
          },{
            xtype:'panel',
            width:td_width,
            bodyStyle:tr_height, 
            html:"&nbsp;<{$gwords.password}>:",   
            id:'password_title'
          },{
            id:'password_option',
            colspan: 2,
            bodyStyle:text_tr_height,
            items:[password]
          },{
          },{
            id:'password_option_desp',
            colspan: 2,
            height:20,
            html:"<span style='color:red'><{$words.password_limit}></span>"
          },{
            xtype:'panel',
            width:td_width,
            bodyStyle:tr_height, 
            html:"&nbsp;<{$words.iscsi_password_confirm}>:",   
            id:'cpassword_title'
          },{
            id:'cpassword_option',
            colspan: 2,
            bodyStyle:"pan",
            bodyStyle:text_tr_height,
            items:[password_comfirm]
          },{             
            xtype:'panel',
            id:'iqn_title',
            width:td_width,
            bodyStyle:tr_height,
            html:"&nbsp;<{$words.iscsi_iqn}>:"
          },{
            xtype:'panel',
            colspan: 2,
            bodyStyle:tr_height,
            id:'iqn_option'
          },{             
            xtype:'panel',
            id:'init_title',
            bodyStyle:tr_height,
            html:"&nbsp;<{$words.iscsi_init_info}>:"
          },{
            xtype:'panel',
            colspan: 2,
            id:'init_option',
            items:[iscsi_int_info]
          }]
}); 

var iscsi_expand_table = new Ext.Panel({
  layout:'table',
  name:'option_table1',
//    width: 480,
//    height:210,
  autoHeight:true,
  defaults: {
    // applied to each contained panel
//        bodyStyle:'padding:10px',
//        height:50,
        
  },
  layoutConfig: {
    // The total column count must be specified here
    columns: 2
  },
  items: [{             
            xtype:'panel',
            bodyStyle:tr_height,
            width:td_width,
            id:'iscsci_expand_title',
            html:"&nbsp;<{$gwords.name}>:"
          },{
            xtype:'panel',            
            bodyStyle:tr_height,
            id:'iscsi_expand_name'
          },{
            xtype:'panel',
            bodyStyle:tr_height,            
            width:td_width,
            html:"&nbsp;<{$words.unused}>:"
          },{
            xtype:'panel', 
            bodyStyle:tr_height,            
            id:'iscsi_expand_unused'
          },{
            xtype:'panel',
            width:td_width,
            bodyStyle:tr_height, 
            html:"&nbsp;<{$words.expand_capacity}>:"
          },{
            width:250,
            items:[expand_unused]
          }]
});

//iscsi option setting form
var space_form = new Ext.FormPanel({
  id:'space_form',
//  width: 480,
//   height:180,
  autoWidth:true,
  autoHieght:true,
  method: 'POST',
  waitMsgTarget : true,   
//   bodyStyle: 'padding:0 10px',
  buttonAlign :'left', 
  frame: true  ,
  items: [{
            xtype:'fieldset', 
            id:'space_fieldset',
            width: 700,
//            title:'<{$gwords.space_allocate}>',
            autoHeight:true,
            //autoWidth:true,
            //height:180,
            //defaults: {width: 300},
            collapsed: false,   
            buttonAlign:'left',
            items:[option_table,iscsi_expand_table] ,
            buttons:[allocate_button]  
          },{  
            xtype:'fieldset', 
            title:"<{$gwords.description}>",
            //height:80,
            autoHeight:true,
            width:700,
            // defaults:{style:''},
            //defaults: {width: 660},
            items:[{
                    xtype:'panel',
                    id:'space_description'
//                    html:space_desp
                   }]
         }]
});

var Window_space= new Ext.Window({  
  title:"<{$gwords.space_allocate}>",
  closable:true,
  closeAction:'hide',
  width: 500,
  height:420,
  resizable : false,
  maximized : false,
  layout: 'fit',  
  modal: true ,
  draggable:false,
  items:[space_form]
});  

Window_space.on("hide",function(obj,value){
  lvname='';  
});    
  
var raid_height,space_height,list_height;
if(Ext.isIE){
  raid_height = 90;
  space_height = 555;
  list_height = 375;
}  
else{
  raid_height = 100;
  space_height = 560;
  list_height = 385;
}  
//space allocate layout
var spcae_table = new Ext.Panel({ 
  name:'spcae_table',
  frame:false,
  renderTo:'space_allocate',
  style: 'margin: 10px;',
  defaults: {
        // applied to each contained panel
    bodyStyle:'padding:0px,0px,0px,0px'
  },
  items: [{
           xtype:'fieldset', 
           title: "<{$gwords.space_allocate}>",
           width: <{if $lang=='fr' || $lang=='de'}>630<{else}>690<{/if}>,
	         height: space_height,
           items:[
                  <{if $raid_count!=1 && $raid_count!=0}>
                  {    
                    height:30,
                    items:[raid_combox]
                  },
                  <{/if}>
                  {
                    xtype:'fieldset', 
                    title:"<{$words.Raid_info}>",
                    height:raid_height,
                    width:<{if $lang=='fr' || $lang=='de'}>600<{else}>660<{/if}>,
                    //defaults: {width: 660},
                    items:[raid_info]
                  },{  
                    xtype:'fieldset',
                    //autoHeight:true,
                   width:<{if $lang=='fr' || $lang=='de'}>600<{else}>660<{/if}>,
                   height:list_height,//260,
                   //defaults: {width: 660}, 
                   title:"<{$words.allocate_list}>",
                   items:[space_tabpanel]
                  }]
           }]
}); 

now_space_grid.getStore().loadData(<{$iscsi_info}>);

if( "<{$iscsi_disable_flag}>" == "1" && now_space_grid.getId()==space_type_set[0]+'_grid'){
  now_space_grid.getTopToolbar().items.get(0).setDisabled(true);
}

if(now_space_grid.id == space_type_set[1]+'_grid')
  thin_iscsi_grid.getStore().loadData(<{$thin_iscsi_info}>);
  
raid_info.getView().refresh(true);

</script>
