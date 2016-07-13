<div id="iscsi"/>

<script text="text/javascript">
var raidunused=<{$raidunused}>;
var now_md="<{$now_md}>"; //record now raid id
var raid_capacity=1;
var target_iscsi='';//record will modify iSCSI id
var target_lun='';//record will modify lun id
var target_iqn='';//record will modify iqn
var now_percent;//record select raid capacity percent
var tr_height='padding:1px';
var td_width=200;  
var text_tr_height='padding:1px 0px 0px 0px';
var now_space_grid;
var space_type_set=<{$space_type}>;
var is_refresh;
var iscsi_own_capacity=0;
var win_width=730;
var real_unused_capacity=0;
var thin_provision_max=<{$iscsi_limit_size}>;
var ajax_mask=false;
var m1;
var build_lun_flag=0;

/**
* number vtype
*/
Ext.form.VTypes["numberVal"] = /^\d+$/;
Ext.form.VTypes["number"]=function(v){
  return Ext.form.VTypes["numberVal"].test(v);
}
Ext.form.VTypes["numberText"]="0-9";
Ext.form.VTypes["numberMask"]=/[0-9]/;

/*
* show this raid do not execute space allocation message.
* @param none
* @returns none.
*/   
function raid_busy_message(){
  Ext.Msg.show({
      title:"<{$gwords.iscsi}>",
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
  
  if ((TCode.desktop.Group.page!='iscsi'))
    return;

  if ((request.build_status != "") && (now_space_grid.getId()!='_build_lun_status')){
    clearTimeout(m1);
    space_tabpanel.unhideTabStripItem(lun_status_panel);
    space_tabpanel.setActiveTab(lun_status_panel);
  }
    
  raid_store.loadData(request.raid_info);
  now_md=request.now_md;

  raidunused=request.raidunused;
  if((now_space_grid.getId()==space_type_set[2]+'_grid') && (request.build_status == "")){
    acl_grid.getStore().loadData(request.init_iqn_data);    
  }else if((now_space_grid.getId()==space_type_set[1]+'_grid')&& (request.build_status == "")){       
    lun_grid.getStore().loadData(request.lun_info);
  }else if((now_space_grid.getId()==space_type_set[0]+'_grid')&& (request.build_status == "")){    
    now_space_grid.getStore().loadData(request.iscsi_info);
    lun_grid.getStore().loadData(request.lun_info);
      
    if(request.iscsi_disable_flag == "1"){
      now_space_grid.getTopToolbar().items.get(0).setDisabled(true);
    }
  }else if (now_space_grid.getId()=='_build_lun_status'){
    if (request.build_status != ""){
      build_lun_flag=1;
      build_lun_status_textarea.setValue(request.build_status);
      m1=setTimeout("processAjax('setmain.php?fun=iscsi',update_raid_info,'&md="+now_md+"&select_action=1&type=iscsi'), false", 15000);
    }else{
      build_lun_flag=0;
      build_lun_status_textarea.setValue('');
      space_tabpanel.hideTabStripItem(lun_status_panel);
      space_tabpanel.setActiveTab(iscsi_panel);
    }
  }
    
  target_iscsi='';
  target_lun='';
}

function update_lun_info(){
  var request = eval('('+this.req.responseText+')');
  lun_grid.getStore().loadData(request.lun_info);
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

  if (data_count >= <{$open_iscsi}> && id == space_type_set[0]+"_store"){
    grid.getTopToolbar().items.get(0).setDisabled(true);
  }else if(id == space_type_set[1]+"_store"){
    if(data_count == 0){  
      grid.getTopToolbar().items.get(0).setDisabled(true);
    }

    if(data_count == 1){  
      grid.getTopToolbar().items.get(6).setDisabled(true);
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
  else if(value == 6) {lun_name.focus(true);}
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
    Ext.getCmp('user_name_title').setDisabled(true);
    Ext.getCmp('password_title').setDisabled(true);
    Ext.getCmp('cpassword_title').setDisabled(true);
    password_comfirm.setDisabled(true);
    mutual_auth_check.setDisabled(true);
    disable_item2("",false,"");
  }else{
    user_name.setDisabled(false);
    password.setDisabled(false);
    Ext.getCmp('user_name_title').setDisabled(false);
    Ext.getCmp('password_title').setDisabled(false);
    Ext.getCmp('cpassword_title').setDisabled(false);
    password_comfirm.setDisabled(false);      
    mutual_auth_check.setDisabled(false);
    disable_item2("",mutual_auth_check.checked,"");
  }
}

/*
* change user name and password status (disable or enable).
* @param obj: auth_radio
* @param obj: auth_radio new value
* @param obj: auth_radio old value
* @returns none.
*/
function disable_item2(obj,newValue,oldValue ){
  if(newValue==true){
    mutual_user_name.setDisabled(false);
    mutual_password.setDisabled(false);
    mutual_password_comfirm.setDisabled(false);
    Ext.getCmp('mutual_user_name_title').setDisabled(false);
    Ext.getCmp('mutual_password_title').setDisabled(false);
    Ext.getCmp('mutual_cpassword_title').setDisabled(false);
  }else{
    mutual_user_name.setDisabled(true);
    mutual_password.setDisabled(true);
    mutual_password_comfirm.setDisabled(true);
    Ext.getCmp('mutual_user_name_title').setDisabled(true);
    Ext.getCmp('mutual_password_title').setDisabled(true);
    Ext.getCmp('mutual_cpassword_title').setDisabled(true);
  }
}

/*
* change user name and password status (disable or enable).
* @param obj: auth_radio
* @param obj: auth_radio new value
* @param obj: auth_radio old value
* @returns none.
*/
function enable_lunitem(newValue){
  lun_name.setDisabled(newValue);
  lun_radio.setDisabled(newValue);
  un_combox.setDisabled(newValue);
  lun_capacity.setDisabled(newValue);
  iscsi_block_size_select.setDisabled(newValue);
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
  real_unused_capacity=obj.maxValue;
  obj.setValue(1,true,true); 
  now_percent = 1;
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
  now_percent = request.unused_size;
  thin_provision_max=request.iscsi_limit_size;
  
  raidunused = request.raidunused;  
  tmp = raidunused+" GB";
  document.getElementById('common_allocation').innerHTML=tmp;
  document.getElementById('unused_title').innerHTML='<div style="'+tr_height+'">&nbsp;<{$words.allocation}>:</div>';
  document.getElementById('allocation_title').innerHTML='<div style="'+tr_height+'">&nbsp;<{$words.unused}>:</div>';  

  if(request.type == 'iscsi_modify')
    raid_capacity = request.lv_capacity;
  else
    raid_capacity = raidunused;
   
  space_slider_setting(un_combox);  
  lun_capacity.setValue(1);
  
  iscsi_name.setValue(request.iscsi_name);
  user_name.setValue(request.username);
  password.setValue(request.password);
  password_comfirm.setValue(request.password);
  mutual_user_name.setValue(request.mutual_username);
  mutual_password.setValue(request.mutual_password);
  mutual_password_comfirm.setValue(request.mutual_password);
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
  
  if(request.mutual_auth != null){      
    mutual_auth_check.setValue(request.mutual_auth);
    disable_item2('',request.mutual_auth,'');    
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
    lun_id_store.loadData(request.lun_data);
    lun_combox.setValue(request.lun_index);
  }
  
  if(request.lun_thin != null){
    lun_radio.setValue(request.lun_thin);
  }

  if(request.lunname != null){
    lun_name.setValue(request.lunname);
  }

  if(request.lun_id != null){
    lun_combox.setValue(request.lun_id); 
  }

  if(request.lun_percent != null){
    lun_capacity.setValue(request.lun_percent);
    un_combox.setValue(request.lun_percent);
  }
  
  if(request.lun_block != null){
    iscsi_block_size_select.setValue(request.lun_block);
  }

  if(request.connection_data != null){
    connection_store.loadData(request.connection_data);
    connection_combox.setValue(request.connection);
  }

  if(request.error_recovery_data != null){
    error_recovery_store.loadData(request.error_recovery_data);
    error_recovery_combox.setValue(request.error_recovery);
  }
  
  if(request.initR2T_data != null){
    initR2T_store.loadData(request.initR2T_data);
    initR2T_combox.setValue(request.initR2T);
  }
  
  crc_data.setValue(request.crc_data);
  crc_header.setValue(request.crc_header);
  
  if(request.desp != null){
    document.getElementById("space_description").innerHTML = request.desp;
  }
  
  allocate_button.setText('<{$gwords.ok}>');
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
    if (object.id != space_type_set[2]+"_add"){
      if (raidunused <1){ 
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
  
  Ext.getCmp('space_fieldset').setVisible(true);
  option_table.setVisible(true); 
  iscsi_expand_table.setVisible(false);

  Ext.getCmp('advanced_fieldset').setVisible(true);
  advanced_table.setVisible(true); 

  Ext.getCmp('lun_fieldset').setVisible(true);
  Ext.getCmp('lun_desc').setVisible(true);

  if(option_type==0){   
    lun_windows_title='<{$words.create_lun}>';
    now_windows_title='<{$words.iscsi_title_create}>';

    if(object.id == (space_type_set[1]+'_add')){
      var win_height;
      now_space_grid=lun_grid;

      Ext.getCmp('space_fieldset').setVisible(false);
      Ext.getCmp('advanced_fieldset').setVisible(false);

      if(Ext.isIE)
        win_height = 350;
      else
        win_height = 360;       
       
      var record2 = lun_grid.getStore().getAt(0);  
      target_iscsi = record2.get('lv');
      target_lun='';
      
      enable_lunitem(false);
      Window_space.setSize(win_width,win_height);
      setWindowPosition(win_width,win_height);
      Ext.getCmp('lun_fieldset').setTitle(lun_windows_title);
    }else{
      now_space_grid=iscsi_grid;
      Ext.getCmp('advanced_fieldset').setVisible(false);

      if(Ext.isIE)
        win_height = 665;
      else
        win_height = 685;
      
      iscsi_modify_itme_show(false);
    
      enable_lunitem(false);
      Window_space.setSize(win_width,win_height);
      setWindowPosition(win_width,win_height);
    }     
  }else{
    if (object.id == (space_type_set[1]+'_modify')){
      Ext.getCmp('space_fieldset').setVisible(false);
      Ext.getCmp('advanced_fieldset').setVisible(false);
      now_space_grid=lun_grid;
      type_title = "<{$words.lun_title_modify}>";
      
      if(Ext.isIE)
        win_height = 360;
      else
        win_height = 360;  
        
      lun_windows_title='<{$words.lun_modify}>';

      m = lun_grid.getSelections();       
      
      if(m.length > 0){
        if(!Window_space.isVisible()){
          target_iscsi = lun_grid.getSelectionModel().getSelected().get("lv");
          target_lun = lun_grid.getSelectionModel().getSelected().get("name");
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

      enable_lunitem(true);
      Window_space.setSize(win_width,win_height);
      setWindowPosition(win_width,win_height);
      Ext.getCmp('lun_fieldset').setTitle(lun_windows_title);
    }else{
      var m,this_grid,type_title;
      var win_height;
      now_space_grid=iscsi_grid;
      
      if (object.id != (space_type_set[0]+'_expand')){
        Ext.getCmp('advanced_fieldset').setVisible(false);
        Ext.getCmp('lun_fieldset').setVisible(false);
        Ext.getCmp('lun_desc').setVisible(false);

        if(Ext.isIE)
          win_height = 460;
        else
          win_height = 480;

        type_title = "<{$words.iscsi_title_modify}>";
        now_windows_title= "<{$words.iscsi_title_modify}>";
      }else{
        Ext.getCmp('space_fieldset').setVisible(false);
        Ext.getCmp('lun_fieldset').setVisible(false);
        Ext.getCmp('lun_desc').setVisible(false);

        if(Ext.isIE)
          win_height = 260;
        else
          win_height = 240;
        
        type_title = "<{$words.advance_title}>";
      }
      
      this_grid = now_space_grid; 
      
      m = this_grid.getSelections();       

      if(m.length > 0){
        if(!Window_space.isVisible()){
          target_iscsi = this_grid.getSelectionModel().getSelected().get("name");
          target_lun='';
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

      iscsi_modify_itme_show(true);
      un_combox.setDisabled(true);
      now_windows_title=type_title;
      Window_space.setSize(win_width,win_height);
      setWindowPosition(win_width,win_height);
    }
  }
  
  Ext.getCmp('space_fieldset').setTitle(now_windows_title);

  now_add_id=object.id;

  Window_space.show();  
  processAjax('getmain.php?fun=iscsi_allocate_data',show_space_form,"&md="+now_md+"&type="+object.id+"&target_iscsi="+target_iscsi+"&target_lun="+target_lun);
} 

/*
* display iscsi expand option.
* @param none
* @returns none.
*/
function show_iscsi_expand_option(){
  var request = eval('('+this.req.responseText+')');  
  document.getElementById("iscsi_expand_name").innerHTML = request.lun_name;
  raidunused=request.raidunused;
  tmp=raidunused+" GB";
  document.getElementById("iscsi_expand_unused").innerHTML = tmp;
  now_percent = request.unused_size;
  thin_provision_max=request.iscsi_limit_size;
  raid_capacity=raidunused;
  space_slider_setting(expand_unused);
  lun_expand_capacity.setValue(1);
  document.getElementById("space_description").innerHTML=request.desp;
  allocate_button.setText('<{$gwords.expand}>');
}

/*
* show iscsi expand form.
* @param object : toolbar option object
* @returns none.
*/
function show_expand_form(object){
  if (object.id == (space_type_set[1]+'_expand')){
    now_space_grid=lun_grid;
    form_title = "<{$words.lun_title_expand}>";
    name_title = "&nbsp;<{$gwords.name}>:";
  }else{
    show_edit_form(object);
    return;
  }

  var m = now_space_grid.getSelections();
  var form_title,name_title;

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
      target_iscsi = now_space_grid.getSelectionModel().getSelected().get("lv");
      target_lun = lun_grid.getSelectionModel().getSelected().get("name");
      Ext.getCmp('lun_fieldset').setVisible(false);
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

  Ext.getCmp('space_fieldset').setVisible(true);
  iscsi_expand_table.setVisible(true);
  option_table.setVisible(false); 
  Ext.getCmp('advanced_fieldset').setVisible(false);
  Window_space.setSize(win_width,180); 
  setWindowPosition(win_width,180);
  
  Ext.getCmp('space_fieldset').setTitle(form_title);
  now_add_id=object.id;
  Window_space.show(); 
  Ext.getCmp('iscsci_expand_title').setTitle(name_title);
  processAjax('getmain.php?fun=iscsi_allocate_data',show_iscsi_expand_option,"&md="+now_md+"&type="+object.id+"&target_iscsi="+target_iscsi+"&target_lun="+target_lun);
}

/*
* exectue option setting success and click 'OK' button to do.
* @param value: 
* @returns none.
*/
function execute_success(value){
  if(Window_space.isVisible())
    Window_space.hide();     
    
  if(Window_acl.isVisible())
    Window_acl.hide();     

  //alert(value);
  processAjax('getmain.php?fun=iscsi',update_raid_info,"&md="+now_md+"&select_action=1&type="+now_type+"&iscsiname="+value);
}

/*
* exectue option setting success will show message.
* @param none. 
* @returns none.
*/
function execute_space_prccess(){
  var request = eval("("+replaceStr(this.req.responseText)+")");  

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

  if (obj.id.indexOf(space_type_set[0],0) == 0){
    this_grid = iscsi_grid;
    now_space_grid=iscsi_grid;
  }else if (obj.id.indexOf(space_type_set[1],0) == 0){
    this_grid = lun_grid;
    now_space_grid=lun_grid;
  }

  m = this_grid.getSelections();   
  
  if(m.length > 0){
    if(!Window_space.isVisible()){
      msg="<{$words.del_confirm}>";
      if (obj.id.indexOf(space_type_set[0],0) == 0){
        target_iscsi = iscsi_grid.getSelectionModel().getSelected().get("name");
      }else if (obj.id.indexOf(space_type_set[1],0) == 0){
        target_iscsi = lun_grid.getSelectionModel().getSelected().get("lv");
        target_lun = lun_grid.getSelectionModel().getSelected().get("name");
        msg=msg+"<br>"+"<{$words.target_restart}>";
      }

      now_add_id=obj.id;
      Ext.Msg.confirm("<{$gwords.iscsi}>","<{$words.del_confirm}>",function(btn){
        if(btn=='yes'){
          processAjax('setmain.php?fun=setiscsi',execute_space_prccess,"&now_add_id="+now_add_id+"&md="+now_md+"&target_iscsi="+target_iscsi+"&target_lun="+target_lun);
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
  now_space_grid=iscsi_grid;
  processAjax('getmain.php?fun=iscsi',update_raid_info,"&md="+record.data['md_num']+"&select_action=1&type=iscsi");
    
  })
<{/if}>

//raid total info
var raid_store= new Ext.data.JsonStore({
  fields: ['m_raid','id','raid_level','status','udisks','total_capacity','data_capacity','fs'],
  data: <{$raid_info}>
});
  
//raid total info grid
var raid_info = new Ext.grid.GridPanel({
  store: raid_store, 
  width:630,
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
              {header: '  <{$words.Raid_data}>', width:110, dataIndex: 'data_capacity', sortable: false },
              {header: '  <{$words.filesystem}>', width:70, dataIndex: 'fs', sortable: false }
           ]
});

var space_tab_height;
space_tab_height = 345;
  
var space_tabpanel = new Ext.TabPanel({
  id:'space_tabpanel',
  autoTabs:true,
  activeTab:0,
  autoHeight:true,
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
  
  if (build_lun_flag==1){
    space_tabpanel.setActiveTab(lun_status_panel);
    return; 
  }
    
  if(is_refresh==1)
    processAjax('getmain.php?fun=iscsi',update_raid_info,"&md="+now_md+"&select_action=1&type="+now_type);
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
               handler:function(object) {
                var ajax = {
                    url: 'getmain.php',
                    params: {
                        fun: 'iscsi_allocate_data',
                        querycapacity: '1',
                        md:now_md
                    },
                    success: function(response, opts){
                      var request = eval('('+response.responseText+')');
                      var titlestr="";

                      if (request.unused_size==0){
                      
                        if (object.id == space_type_set[1]+'_add'){
                          titlestr="<{$words.lun_title_create}>";
                        }else{
                          titlestr="<{$words.iscsi_title_create}>";
                        }
                        
                        Ext.Msg.show({
                          title:titlestr,
                          msg: "<{$words.space_not_enough}>",
                          buttons: Ext.Msg.OK,
                          icon: Ext.MessageBox.ERROR
                        });
                      }else{
                        show_edit_form(object);
                      }
                    }
                }
                Ext.Ajax.request(ajax);
               }

             },'-',{
               id:grid_id+'_modify',
               text:'<{$gwords.modify}>',
               iconCls:'edit',
               handler:show_edit_form

             },'-',{
               id:grid_id+'_expand',
               text:'<{$gwords.expand}>',
               iconCls:'edit',
               handler:function(object) {
                var ajax = {
                    url: 'getmain.php',
                    params: {
                        fun: 'iscsi_allocate_data',
                        querycapacity: '1',
                        md:now_md
                    },
                    success: function(response, opts){
                      var request = eval('('+response.responseText+')');

                      if ((request.unused_size==0) && (object.id != space_type_set[0]+"_expand")){
                        Ext.Msg.show({
                          title:"<{$words.lun_title_expand}>",
                          msg: "<{$words.space_not_enough}>",
                          buttons: Ext.Msg.OK,
                          icon: Ext.MessageBox.ERROR
                        });
                      }else{
                        show_expand_form(object);
                      }
                    }
                }
                Ext.Ajax.request(ajax);
               }

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
    autoHeight:true,
    autoscroll:true,
    store: space_store,
    trackMouseOver:true,
    disableSelection:false,
    loadMask: true,
    bodyStyle:'padding:0px',
     // grid columns
    columns:[
             {id: 'type', header: '<{$words.allocate_type}>', dataIndex: 'type',width: 250, sortable: true, hidden:true},
             {id: 'name', header: '<{$gwords.name}>', dataIndex: 'name', width: 250, sortable: true},
             {id: 'capacity', header: '<{$gwords.capacity}>(GB)', dataIndex: 'capacity', width: 230, sortable: true},
             {id: 'thin', header: '<{$words.lun_allocation}>', dataIndex: 'modify_flag', width: 120, sortable: true}
            ],
    tbar:space_tbar
  });   

  //when space_grid data is empty will disable iscsi_modify,space_delete
  space_grid.getStore().on('load',function(obj,records){    
    grid_option_edit(space_grid,obj.id,records.length);
  });

  if(space_tabpanel.items.length==0)
    now_space_grid=space_grid;

  return space_grid; 
}

<{if $open_iscsi!="0"}>
  var iscsi_grid = create_space_grid("<{$gwords.iscsi}>",1,space_type_set[0]); 
  var lun_grid = create_space_grid("<{$words.lun}>",2,space_type_set[1]); 

  iscsi_grid.width=621;
  iscsi_grid.height=190;      
  lun_grid.width=621;
  //lun_grid.height=240;      
  
  //lun_grid.autoHeight=false;
  iscsi_grid.autoHeight=false;
  iscsi_grid.getColumnModel().setColumnHeader(2,"<{$gwords.status}>");
  iscsi_grid.getColumnModel().setHidden(3,true);
  var iscsi_panel = new Ext.Panel({
    title:"<{$gwords.iscsi_target}>",
    name:'iscsi_panel',
    id:space_type_set[0],
    autoHeight:true,
    //layout:'fit',
    frame:true,
    bodyStyle:'padding:0px 0px 0px 0px;',
    items:[iscsi_grid,{height:10},lun_grid]
  });
  space_tabpanel.add(iscsi_panel);

  iscsi_grid.on('cellclick',function(thisobj, rowNum, columnNum, e_code){ 
    var record = thisobj.getStore().getAt(rowNum);  
    var fieldName = thisobj.getColumnModel().getDataIndex(1); // Get field name
    var data = record.get(fieldName);
    
    processAjax('getmain.php?fun=iscsi',update_lun_info,"&md="+now_md+"&select_action=1&type=lun&iscsiname="+data);
  });
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
    hideLabel : true,
    store: block_size_store,
    valueField :"value",
    displayField:"display",
    mode: 'local',
    forceSelection: true,
    editable: false,
    triggerAction: 'all',
    hiddenName:'advance_iscsi_block_size',
    value:'<{$iscsi_block_size}>',
    listWidth:200,
    width:150   
  });
  
/*
* exectue delete space allocate.
* @param obj:delete object. 
* @returns none.
*/
function delete_lun_acl(obj){
  var m,this_grid;

  if (obj.id.indexOf(space_type_set[2],0) == 0){
    this_grid = acl_grid;
  }

  m = this_grid.getSelections();   
  
  if(m.length > 0){
    if(!Window_acl.isVisible()){
       target_iqn = acl_grid.getSelectionModel().getSelected().get("init_iqn");

      now_add_id=obj.id;
      Ext.Msg.confirm("<{$words.lun_acl}>","<{$words.del_lunacl_confirm}>",function(btn){
        if(btn=='yes'){
          processAjax('setmain.php?fun=setlunacl',execute_space_prccess,"&now_add_id="+now_add_id+"&target_iqn="+target_iqn);
        }
      })
    }   
  }else{
    Ext.Msg.show({
      title:"<{$words.lun_acl}>",
      msg: "<{$words.iqn_no_select}>",
      buttons: Ext.Msg.OK,
      icon: Ext.MessageBox.ERROR
    });
    
    return;
  }
}

function show_acl_form(){
  var request = eval('('+this.req.responseText+')');

  iqn_grid.getStore().loadData(request.init_lun_data);
  iqn_name.setValue(request.iqn_name);
  
  if(request.type==(space_type_set[2]+"_modify")){
    iqn_name.setDisabled(true);
  }else{
    iqn_name.setDisabled(false);
  }
}


function show_edit_acl(object){
  var now_windows_title;
  var option_type;
  
  if(object.id.indexOf("add",0) != -1)
    option_type=0;
  else
    option_type=1;
    
  if(Ext.isIE)
    win_height = 450;
  else
    win_height = 465;

  m = acl_grid.getSelections();       

  if (option_type==1){
    if(m.length > 0){
      if(!Window_space.isVisible()){
        target_iqn = acl_grid.getSelectionModel().getSelected().get("init_iqn");
      }   
    }else{
      Ext.Msg.show({
        title: "<{$words.lun_acl}>",
        msg: "<{$words.user_no_select}>",
        buttons: Ext.Msg.OK,
        icon: Ext.MessageBox.ERROR
      });
        
      return;
    }
  }else{
    target_iqn='';
  }

  Window_acl.setSize(win_width,win_height);
  Window_acl.show(); 
  
  processAjax('getmain.php?fun=iscsi_allocate_data',show_acl_form,"&md="+now_md+"&type="+object.id+"&target_iqn="+target_iqn);
  now_add_id=object.id;
  //setWindowPosition(win_width,win_height);
}

//lun name
var iqn_name=new Ext.form.TextField({
  id:'iqn_name',
  name:'iqn_name',
  fieldLabel: '<{$words.init_iqn}>',
  maxLength:150,
  width:350,
  hideLabel:false
});

function create_radio(v,cellmata,record,rowIndex,colIndex){
	var privilege=0;
	var tvalue=0;
	var t_lunname=record.data['lunname'];
	var check="";
	var html="";
  
  if (colIndex==2){
    privilege=record.data['write'];
    tvalue=0;
  }else if (colIndex==3){
    privilege=record.data['read'];
    tvalue=1;
  }else if (colIndex==4){
    privilege=record.data['deny'];
    tvalue=2;
  }

	if(privilege==1){
		check="checked";
	}
	
  html="<div>";
	html+="<input type='radio' name='radio_"+t_lunname+"' value='" + tvalue + "' "+check+">";
	html+="</div>";
	return html;
}

//initiator iqn info  
var iqn_store = new Ext.data.JsonStore({
  id:'iqn_store',
  sortInfo:{field: 'iscsiname', direction: "ASC"},
  fields: ['iscsiname', 'lunname', 'write','read','deny']
});  

//initiator iqn ACL info grid
var iqn_grid = new Ext.grid.GridPanel({
    title:"<{$words.lun_acl}>",
    id:"iqn_grid",
//    width:300,
    height:330,
//    autoHeight:true,
    autoscroll:true,
    store: iqn_store,
    trackMouseOver:true,
    disableSelection:false,
    loadMask: true,
    bodyStyle:'padding:0px',
     // grid columns
    columns:[
             {id: 'acl_iscsiname', header: '<{$gwords.iscsi_target}>', dataIndex: 'iscsiname', width: 200, sortable: true},
             {id: 'acl_lunname', header: '<{$words.lun_name}>', dataIndex: 'lunname', width: 200, sortable: true},
             {
                header: '<{$gwords.read_write}>',
                id:'allradio',
                name:'allradio',
                width:90,
                menuDisabled:true,
                renderer:create_radio
			       },{
                header: '<{$gwords.readonly}>',
                id:'allradio1',
                name:'allradio1',
                width:90,
                menuDisabled:true
                ,renderer:create_radio
			       },{
                header: '<{$gwords.deny}>',
                id:'allradio2',
                name:'allradio2',
                width:90,
                menuDisabled:true,
                renderer:create_radio
			       }
            ]
  });   

//set LUN ACL button(add or modify)
var acl_button= new Ext.Button({
  id : 'acl_select',
  disabled : false,
  minWidth:80,
  text:'<{$gwords.ok}>',
  handler : function() {
    var post_data,comfirm,title,option_type; 
      
    switch(now_add_id){
      case space_type_set[2]+'_add':
        title="<{$words.lun_acl}>";
        comfirm="<{$words.add_lunacl_confirm}>";      
        break;
      case space_type_set[2]+'_modify':
        title="<{$words.lun_acl}>";
        comfirm="<{$words.modify_lunacl_confirm}>";      
        break;
    }
    
    if(space_form.getForm().isValid()){
      Ext.Msg.confirm(title,comfirm,function(btn){
        if(btn=='yes'){
          processAjax('setmain.php?fun=setlunacl',execute_space_prccess,acl_form.getForm().getValues(true)+"&now_add_id="+now_add_id+"&target_iqn="+target_iqn);
        }
      })
    }     
  } 
});

//acl option setting form
var acl_form = new Ext.FormPanel({
  id:'acl_form',
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
            id:'acl_fieldset',
            width: 700,
//            title:'<{$gwords.space_allocate}>',
            autoHeight:true,
            //autoWidth:true,
            //height:180,
            //defaults: {width: 300},
            collapsed: false,   
            buttonAlign:'left',
            items:[iqn_name,iqn_grid]
          }]
         ,buttons:[acl_button]
});  

var Window_acl= new Ext.Window({  
  title:"<{$words.lun_acl}>",
  closable:true,
  closeAction:'hide',
  width: 500,
  height:420,
  resizable : false,
  maximized : false,
  layout: 'fit',  
  modal: true ,
  draggable:false,
  items:[acl_form]
});

//initiator iqn info  
  var acl_store = new Ext.data.JsonStore({
    id:space_type_set[2]+'_store',
    fields: ['init_iqn']
  });  

//initiator iqn ACL option
   var acl_tbar =new Ext.Toolbar({
     id:space_type_set[2]+'_bar',
     items :[{
               id:space_type_set[2]+'_add',
               text:'<{$gwords.add}>',
               iconCls:'add',
               handler:show_edit_acl
             },'-',{
               id:space_type_set[2]+'_modify',
               text:'<{$gwords.modify}>',
               iconCls:'edit',
               handler:show_edit_acl
             },'-',{
               id:space_type_set[2]+'_delete',
               text:'<{$gwords.delete}>',
               iconCls:'remove',
               handler:delete_lun_acl
             }]
   });

  //initiator iqn ACL info grid
  var acl_grid = new Ext.grid.GridPanel({
    title:"",
    id:space_type_set[2]+"_grid",
//    width:300,
//    height:150,
//    autoHeight:true,
    autoscroll:true,
    store: acl_store,
    trackMouseOver:true,
    disableSelection:false,
    loadMask: true,
    bodyStyle:'padding:0px',
     // grid columns
    columns:[
             {id: 'init_iqn', header: '<{$words.init_iqn}>', dataIndex: 'init_iqn', width: 400, sortable: true}
            ],
    tbar:acl_tbar
  });   

  var acl_panel = new Ext.Panel({
    title:"<{$words.lun_acl}>",
    name:'acl_panel',
    id:space_type_set[2],
    height:300,
    layout:'fit',
    frame:true,
    bodyStyle:'padding:0px 0px 0px 0px;',
    items:[acl_grid]
  });
  space_tabpanel.add(acl_panel);

  var build_lun_status_textarea=new Ext.form.TextArea({
    xtype: 'textarea',
    width: '500',
    height: '400',
    id: '_build_lun_status',
    name: '_build_lun_status',
    readOnly:true,
    hideLabel:true,
    fieldLabel: '',
    value: ''
  });
    
  var lun_status_panel = new Ext.Panel({
    title:"<{$gwords.status}>",
    name:'lun_status',
    id:'lun_status',
    height:200,
    layout:'fit',
    frame:true,
    bodyStyle:'padding:0px 0px 0px 0px;',
    items:[build_lun_status_textarea]
  });

  space_tabpanel.add(lun_status_panel);
<{/if}>

//set space allocte button(add or modify)
var allocate_button= new Ext.Button({
  id : 'share_select',
  disabled : false,
  minWidth:80,
  text:'<{$gwords.ok}>',
  handler : function() {
    var post_data,comfirm,title,option_type; 
      
    switch(now_add_id){
      case space_type_set[0]+'_add':
        title="<{$words.iscsi_title_create}>";
        comfirm="<{$words.add_iscsi_confirm}>";      
        break;
      case space_type_set[1]+'_add':
        title="<{$words.lun_title_create}>";
        comfirm="<{$words.lun_title_create}>?";      
        break;
      case space_type_set[0]+'_modify':
        title="<{$words.iscsi_title_modify}>";
        comfirm="<{$words.modify_iscsi_confirm}>";
        break;
      case space_type_set[1]+'_modify':
        title="<{$words.lun_modify}>";
        comfirm="<{$words.modify_lun_confirm}>";
        break;
      case space_type_set[0]+'_expand':
        title="<{$words.iscsi_title_modify}>";
        comfirm="<{$words.modify_iscsi_confirm}>";
        break;
      case space_type_set[1]+'_expand':
        title="<{$words.lun_title_expand}>";
        comfirm="<{$gwords.confirm}>";
        break;  
    }  

    if(space_form.getForm().isValid()){
      Ext.Msg.confirm(title,comfirm,function(btn){
        if(btn=='yes'){
          processAjax('setmain.php?fun=setiscsi',execute_space_prccess,space_form.getForm().getValues(true)+"&now_add_id="+now_add_id+"&md="+now_md+"&target_iscsi="+target_iscsi+"&percent="+now_percent+"&target_lun="+target_lun);
        }
      })
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
      return String.format('<b>{0}G</b>', slider.getValue());
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
        thisobj.nrField.dom.innerHTML = this.setZero; 
    }else{
        if(value == thisobj.maxValue){
          tValue=raid_capacity;
          thisobj.nrField2.dom.value = tValue + this.setMsg;
          thisobj.nrField.dom.innerHTML = tValue + this.setMsg;
        }else{
          tValue=value;          
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
	  
	  if (id_name=="expand_capacity"){
      lun_expand_capacity.setValue(thisobj.getValue());
	  }else{
      lun_capacity.setValue(thisobj.getValue());
    }
  });

  return slider;
}


var un_combox = unused_slider('use_capacity');
var expand_unused = unused_slider('expand_capacity');

var lun_id_store = new Ext.data.JsonStore({
  fields: ['lun_id']
});

//select raid combox    
var lun_combox =  new Ext.form.ComboBox({
  store: lun_id_store,
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

//the lun if thin-provision or instant allocation
var lun_radio= new Ext.form.RadioGroup({
  id:'lun_thin',
  width:300,
  hideLabel:true,
  listeners: {change: handleFormlun_thin},
  items: [{boxLabel: '<{$words.thin_provision}>', name: 'lun_thin', inputValue: 1 <{if $lun_thin==1}>,checked:true<{/if}> , width:100},
          {boxLabel: '<{$words.instant_allocation}>', name: 'lun_thin', inputValue: 0 <{if $lun_thin==0}>,checked:true<{/if}>}             
         ]  
});  

//adjust the max capacity of the lun
function handleFormlun_thin(obj,value){
  if (value == '0'){
    un_combox.maxValue=real_unused_capacity;

    if (now_percent > real_unused_capacity){
      now_percent=real_unused_capacity;
    }

    tmp = real_unused_capacity+" GB";
  }else{
    un_combox.maxValue=thin_provision_max;
    tmp = thin_provision_max+" GB";
  }

  document.getElementById('common_allocation').innerHTML=tmp;
  un_combox.setValue(now_percent);
  lun_capacity.setValue(now_percent);
}

var mutual_auth_check= new Ext.form.Checkbox({
		id:'mutual_auth',
		inputValue :'1',
		boxLabel:"<{$words.mutual_iscsi_auth}>"
});

mutual_auth_check.on('check',disable_item2);

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

//mutual auth for user name
var mutual_user_name=new Ext.form.TextField({
  id:'mutual_username',
  name:'mutual_username',
  maxLength:12,
  hideLabel:true
});  
  
//mutual auth for user's password
var mutual_password=new Ext.form.TextField({
  id:'mutual_password',
  inputType:'password',
  maxLength:16,
  hideLabel:true
});

//mutual comfirm password
var mutual_password_comfirm=new Ext.form.TextField({
  fieldLabel: 'xxx',
  id:'mutual_password_comfirm',
  inputType:'password',
  maxLength:16,
  hideLabel:false
});

//lun name
var lun_name=new Ext.form.TextField({
  id:'lun_name',
  name:'lun_name',
  maxLength:12,
  hideLabel:true
});

//lun capacity
var lun_capacity=new Ext.form.TextField({
  id:'lun_capacity',
  name:'lun_capacity',
  maxLength:12,
  width:50,
  vtype:'number',
  hideLabel:true
});

//lun expand capacity
var lun_expand_capacity=new Ext.form.TextField({
  id:'lun_expand_capacity',
  name:'lun_expand_capacity',
  maxLength:12,
  width:50,
  vtype:'number',
  hideLabel:true
});

//iscsi enable info  
var iscsi_int_info=new Ext.form.TextArea({
  id:'init_info',
  name:'init_info',
//  maxLength:250,
  width:350,
  height:60,
  hideLabel:true,
  readOnly :true
});  

lun_capacity.on('blur',function(thisobj){
  var is_thin=lun_radio.getValue();
  
  if (is_thin=="1"){
    if (thisobj.getValue() > thin_provision_max){
      now_percent=Math.floor(thin_provision_max);
      thisobj.setValue(now_percent);
    }else{
      now_percent=thisobj.getValue();
    }
  }else{
    if (thisobj.getValue() > raidunused){
      now_percent=Math.floor(raidunused);
      thisobj.setValue(now_percent);
    }else{
      now_percent=thisobj.getValue();
    }
  }
  
  un_combox.setValue(now_percent);
}); 

lun_expand_capacity.on('blur',function(thisobj){
  
  if (thisobj.getValue() > raidunused){
    now_percent=Math.floor(raidunused);
    thisobj.setValue(now_percent);
  }else{
    now_percent=thisobj.getValue();
  }

  expand_unused.setValue(now_percent);

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
minWidth  : 200
        
  },
  layoutConfig: {
    // The total column count must be specified here
    columns: 2
  },
  items: [
          {
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
            html:"&nbsp;<{$words.iscsi_auth}>:",   
            id:'auth_title'
          },{
            id:'auth_option',
            colspan: 2,
            items:[auth_radio]
          },{
            xtype:'label',
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
            xtype:'label',
            width:td_width,
            bodyStyle:tr_height, 
            html:"&nbsp;<{$gwords.password}>:",   
            id:'password_title'
          },{
            id:'password_option',
            colspan: 2,
            bodyStyle:text_tr_height,
            items:[password,{
                   id:'password_option_desp',
                   xtype:'label',
                   html:"<span style='color:red'><{$words.password_limit}></span>"
                   }]
          },{
            xtype:'label',
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
            id:'mutual_auth_option',
            colspan: 1,
            bodyStyle:text_tr_height,  
            items:[mutual_auth_check]
          },{
            id:'mutual_auth_option1',
            colspan: 2,
            bodyStyle:text_tr_height,  
            items:[mutual_auth_check]
          },{
            xtype:'label',
            width:td_width,
            bodyStyle:tr_height, 
            html:"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<{$gwords.username}>:",   
            id:'mutual_user_name_title'
          },{
            id:'mutual_user_name_option',
            colspan: 2,
            bodyStyle:text_tr_height,
            items:[mutual_user_name,{
                   xtype:'label',
                   html:"<span style='color:red'><{$words.username_limit}></span>"
                   }]
          },{
            xtype:'label',
            width:td_width,
            bodyStyle:tr_height, 
            html:"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<{$gwords.password}>:",   
            id:'mutual_password_title'
          },{
            id:'mutual_password_option',
            colspan: 2,
            bodyStyle:"pan",
            bodyStyle:text_tr_height,
            items:[mutual_password,{
                   id:'mutual_password_option_desp',
                   xtype:'label',
                   html:"<span style='color:red'><{$words.password_limit}></span>"
                   }]
          },{
            xtype:'label',
            width:td_width,
            bodyStyle:tr_height, 
            html:"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<{$words.iscsi_password_confirm}>:",   
            id:'mutual_cpassword_title'
          },{
            id:'mutual_cpassword_option',
            colspan: 2,
            bodyStyle:"pan",
            bodyStyle:text_tr_height,
            items:[mutual_password_comfirm]
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
	
//iscsi option setting table
var lun_table = new Ext.Panel({
  layout:'table',
  name:'lun_table',
  autoHeight:true,
  defaults: {
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
            width:td_width,
            bodyStyle:tr_height, 
            html:"&nbsp;<{$words.lun_allocation}>:",   
            id:'lun_space_title'
          },{
            id:'lun_space',
            colspan: 2,
            items:[lun_radio]
          },{
            xtype:'panel',
            width:td_width,
            bodyStyle:tr_height, 
            html:"&nbsp;<{$words.lun_name}>:",   
            id:'tlun_space_title'
          },{
            id:'tlun_space',
            colspan: 2,
            bodyStyle:text_tr_height,
            items:[lun_name,{
                   xtype:'label'
                   ,html:"<span style='color:red'><{$words.target_name_limit}></span>"
                   }]
          },{
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
            width:td_width,
            bodyStyle:tr_height, 
            id:'unused_title',
            html:"&nbsp;<{$words.unused}>:"
          },{
            width:500,
            colspan: 2,
            id:'unused_title_option',           
            items:[
              { layout: 'column', border: false, defaults: { columnWidth: '.8', border: false }, 
                items:[
                  { columnWidth:0.31, items:[un_combox]},
                  { columnWidth:0.15, items:[lun_capacity,{
                   xtype:'label'
                   ,html:"<span>GB</span>"
                   }]}
                ]
              }
            ]
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
            html:"&nbsp;<{$words.iscsi_block}>:",   
            id:'lun_block'
          },{
            id:'tlun_block',
            colspan: 2,
            items:[iscsi_block_size_select]
          }
        ]
}); 

var connection_store = new Ext.data.JsonStore({
  fields: ['connection_id']
});

//iscsi max connections select cmobox
var connection_combox =  new Ext.form.ComboBox({
  store: connection_store,
  valueField: "connection_id",
  displayField: "connection_id",
  mode: 'local',
  forceSelection: true,
  editable: false,
  triggerAction: 'all',
  hiddenName:'connection_id',
  hideLabel: true,
  maxHeight: 150,
  width:80 
});

var crc_data= new Ext.form.Checkbox({
		id:'crc_data',
		name:'crc_data',
		inputValue :'1',
		width:300,
		boxLabel:"<{$words.crc_data}>"
});

var crc_header= new Ext.form.Checkbox({
		id:'crc_header',
		name:'crc_header',
		inputValue :'1',
		width:300,
		boxLabel:"<{$words.crc_header}>"
});

var error_recovery_store = new Ext.data.JsonStore({
  fields: ['error_recovery_id']
});

//iscsi max connections select cmobox
var error_recovery_combox =  new Ext.form.ComboBox({
  store: error_recovery_store,
  valueField: "error_recovery_id",
  displayField: "error_recovery_id",
  mode: 'local',
  forceSelection: true,
  editable: false,
  triggerAction: 'all',
  hiddenName:'error_recovery_id',
  hideLabel: true,
  maxHeight: 150,
  width:80 
});

var initR2T_store = new Ext.data.JsonStore({
  fields: ['initR2T_id']
});
  
//iscsi initialR2T select cmobox
var initR2T_combox =  new Ext.form.ComboBox({
  store: initR2T_store,
  valueField: "initR2T_id",
  displayField: "initR2T_id",
  mode: 'local',
  forceSelection: true,
  editable: false,
  triggerAction: 'all',
  hiddenName:'initR2T_id',
  hideLabel: true,
  maxHeight: 150,
  width:80
});

//iscsi option setting table
var advanced_table = new Ext.Panel({
  layout:'table',
  name:'advanced_table',
  autoHeight:true,
  defaults: {
  },
  layoutConfig: {
    // The total column count must be specified here
    columns: 3
  },
  items: [
          {
            xtype:'panel',
            width:td_width,
            bodyStyle:tr_height, 
            html:"&nbsp;<{$words.iscsi_crc}>:",
            id:'advance_crc_title'
          },{
            id:'advance_crc_data',
            colspan: 2,
            items:[crc_data]
          },{
            xtype:'panel',
            width:td_width,
            bodyStyle:tr_height,
            html:"&nbsp;",
            id:'advance_crc_title2'
          },{
            id:'advance_crc_header',
            colspan: 2,
            items:[crc_header]
          },{
            xtype:'panel',
            width:td_width,
            bodyStyle:tr_height, 
            html:"&nbsp;<{$words.maxconnection}>:",
            id:'advance_connection_title'
          },{
            id:'advance_connection',
            colspan: 2,
            items:[connection_combox]
          },{
            xtype:'panel',
            width:td_width,
            bodyStyle:tr_height, 
            html:"&nbsp;<{$words.error_recovery}>:",
            id:'advance_error_recovery_title'
          },{
            id:'advance_error_recovery',
            colspan: 2,
            items:[error_recovery_combox]
          },{
            xtype:'panel',
            width:td_width,
            bodyStyle:tr_height,
            html:"&nbsp;<{$words.initr2t}>:",
            id:'advance_initR2T_title'
          },{
            id:'advance_initR2T',
            colspan: 2,
            items:[initR2T_combox]
          }
        ]
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
            width:500,
            colspan: 2,
            id:'unused_title_option',           
            items:[
              { layout: 'column', border: false, defaults: { columnWidth: '.8', border: false }, 
                items:[
                  { columnWidth:0.31, items:[expand_unused]},
                  { columnWidth:0.15, items:[lun_expand_capacity,{
                   xtype:'label'
                   ,html:"<span>GB</span>"
                   }]}
                ]
              }
            ]
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
            items:[option_table,iscsi_expand_table]
          },{  
            xtype:'fieldset', 
            id:'advanced_fieldset',
            title:"<{$words.advance_title}>",
            autoHeight:true,
            width:700,
            items:[advanced_table]
         },{  
            xtype:'fieldset', 
            id:'lun_fieldset',
            title:"<{$words.create_lun}>",
            autoHeight:true,
            width:700,
            items:[lun_table]
         },{  
            xtype:'fieldset', 
            id:'lun_desc',
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
         }],
            buttons:[allocate_button]
});

var Window_space= new Ext.Window({  
  title:"<{$gwords.iscsi}>",
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
  target_iscsi='';
  target_lun='';
}); 

function iscsi_status(val) {
  if (val == 0){
    Ext.getCmp("_isns").setDisabled(true);
    Ext.getCmp("_isns_ip").setDisabled(true);
  }else{
    Ext.getCmp("_isns").setDisabled(false);
    if (Ext.getCmp("_isns").checked)
      Ext.getCmp("_isns_ip").setDisabled(false);
    else
      Ext.getCmp("_isns_ip").setDisabled(true);
  }
}


var iscsi_radiogroup = new Ext.form.RadioGroup({
  xtype: 'radiogroup',
  width: 250,
  fieldLabel: '<{$gwords.iscsi}>',
  items: [
    {boxLabel: '<{$gwords.enable}>', name: '_iscsi', inputValue: 1 <{if $iscsi_enabled =="1"}>, checked:true <{/if}>},
    {boxLabel: '<{$gwords.disable}>', name: '_iscsi', inputValue: 0 <{if $iscsi_enabled =="0"}>, checked:true <{/if}>}
  ],
  listeners:{
    change:{
      fn:function(obj,val){
        iscsi_status(val);
      }
    }
  }
});

//disable or enable schedule checkbox
var isns_checkbox = new Ext.form.Checkbox({
    name:'_isns',
    id:'_isns',
    hideLabel:true,
    value:1,
    <{if $isns_enabled=="1"}>
    checked:true,
    <{/if}>
    boxLabel:'<{$gwords.enable}> <{$words.isns}>',
    listeners:{
        check:{
            fn:function(obj, chk){
                if(chk) {
                  Ext.getCmp("_isns_ip").setDisabled(false);
                } else {
                  Ext.getCmp("_isns_ip").setDisabled(true);
                }
            }
        }
    }
});
  
var iscsipanel = new Ext.FormPanel({
    frame: false,
    autoWidth: 'true',
    style: 'padding-left:7px;',
    defaults: {
        labelStyle: 'width:110'
    },
    items: [
        iscsi_radiogroup,
        isns_checkbox,
        {
            xtype: 'textfield',
            name: '_isns_ip',
            id:  '_isns_ip',
            maxLength:16,
            fieldLabel: "&nbsp;&nbsp;&nbsp;&nbsp;<{$words.isns_ip}>",
            labelWidth: 150,
            value: '<{$isns_ip}>'
        }
    ],
    buttonAlign: 'left',
    buttons: [{
        text: '<{$gwords.apply}>',
        style: 'position:relative;left:-7px;',
        handler: function(){
            if(iscsipanel.getForm().isValid()){
                Ext.Msg.confirm('<{$gwords.iscsi}>',"<{$gwords.confirm}>",function(btn){
                    if(btn=='yes'){
                        var isns_enabled=0;
                        if (Ext.getCmp("_isns").checked){
                            isns_enabled=1;
                        }else{
                            isns_enabled=0;
                        }
                        processAjax('setmain.php?fun=setiscsi_service',onLoadForm,iscsipanel.getForm().getValues(true)+"&isns_enabled="+isns_enabled);
                    }
                });
            }
        }
    }]
});
    
//space allocate layout
var spcae_table = new Ext.Panel({ 
    name:'spcae_table',
    frame:false,
    renderTo:'iscsi',
    defaults: {
        // applied to each contained panel
        bodyStyle:'padding:0px,0px,0px,0px'
    },
    items: [{
        xtype:'fieldset', 
        title: "<{$gwords.iscsi}>",
        width: 690,
        autoHeight: true,
        defaults: {
            autoHeight: true
        },
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
                width:660,
                items:[raid_info]
              },{
                xtype:'fieldset',
                width:660,
                title:"<{$words.iscsi_support}>",
                items:[iscsipanel]
              },{  
               xtype:'fieldset',
               width:660,
               autoHeight:true,
               title:"<{$gwords.iscsi_target}>",
               items:[space_tabpanel]
              }
            ]
    }]
}); 

now_space_grid.getStore().loadData(<{$iscsi_info}>);
lun_grid.getStore().loadData(<{$lun_info}>);

if( "<{$iscsi_disable_flag}>" == "1" && now_space_grid.getId()==space_type_set[0]+'_grid'){
  now_space_grid.getTopToolbar().items.get(0).setDisabled(true);
}

raid_info.getView().refresh(true);
iscsi_grid.getTopToolbar().items.get(4).setText("<{$gwords.advanced}>");

space_tabpanel.hideTabStripItem(lun_status_panel);
if ('<{$build_status}>' != ''){
  space_tabpanel.unhideTabStripItem(lun_status_panel);
  space_tabpanel.setActiveTab(lun_status_panel);
}

iscsi_status(<{$iscsi_enabled}>);

</script>
