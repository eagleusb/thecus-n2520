<div id="ddom"></div>

<script type="text/javascript">
var item_type = new Array("auto","daily","weekly","monthly");
var now_type = "<{$ddom_default_setting.type}>";
var update_flag;
var rand=Math.random();

function ExtDestroy(){ 
 Ext.destroy(
            Ext.getCmp('en_checkbox'),
            Ext.getCmp('weekly_combobox'),
            Ext.getCmp('monthly_combobox'),
            Ext.getCmp('auto_radio'),
            Ext.getCmp('daily_radio'),
            Ext.getCmp('weekly_radio'),
            Ext.getCmp('monthly_radio'),
            Ext.getCmp('daily_time'),
            Ext.getCmp('weekly_time'),
            Ext.getCmp('monthly_time'),
            Ext.getCmp('ddom_table'),
            Ext.getCmp('ddom_manual'),
            Ext.getCmp('list_grid'),
            Ext.getCmp('ddom_apply')
            );  
}

/*
* update dual dom list info and manual button status.
* @param value - none
* @returns none.
*/    
function update_data(){
  if(replaceStr(this.req.responseText) != ""){
    var request = eval("("+replaceStr(this.req.responseText)+")"); 
    
    if(update_flag != null)
      clearTimeout(update_flag);
    if(TCode.desktop.Group.page === 'ddombackup'){   
      if(request.list_store != null)
        list_store.loadData(request.list_store);
      
      if(request.process_flag !=null ){
        document.getElementById("ddom_status").innerHTML="<span style='color:red'>"+request.ddom_status+"</span>";
        if(request.process_flag == "1" )        
          ddom_manual.setDisabled(true);
        else
          ddom_manual.setDisabled(false);
      }    
      update_flag = setTimeout("processAjax('getmain.php?fun=ddombackup&update=1&rand="+rand+"',update_data)",10*1000);
    } 
  }else{
    if(update_flag != null)
      clearTimeout(update_flag);     
  }  
}

/*
* Set object disable or enable.
* @param obj : object
*        values : ture or false
* @returns none.
*/
function set_item_disable(obj,values){ 
  if(Ext.getCmp(obj))
    Ext.getCmp(obj).setDisabled(values);  
}

/*
* When check enable/disable checkbox, all items disable or enable.
* @param check : true or false
* @returns none.
*/
function disable_list(check){
  var obj;
  if(!check){
    set_item('',0);
  }else{
    set_item(now_type,1);
  }
}

/*
* Set some option disable or enable.
* @param check : true or false
* @returns none.
*/
function set_item(type_name,radio_flag){
  var obj;
  for(var i=0; i<item_type.length; i++){
    obj=item_type[i]+"_radio";
    if(radio_flag == 1)
      set_item_disable(obj,false);
    else
      set_item_disable(obj,true);
    if(item_type[i] == type_name){
      obj=item_type[i]+"_time";
      set_item_disable(obj,false);
      obj=item_type[i]+"_combobox";
      set_item_disable(obj,false);
    }else{      
      obj=item_type[i]+"_time";
      set_item_disable(obj,true);
      obj=item_type[i]+"_combobox";
      set_item_disable(obj,true);
    }      
  }
}

/*
* When execute apply or manual, update status.
* @param value - none.
* @returns none.
*/
function update_ddom_status(){    
  var request = eval('('+this.req.responseText+')'); 
  if(request.show){
    mag_box(request.topic,request.message,request.icon,request.button,request.fn,request.prompt);
  }
  if(request.process_flag){
    ddom_manual.setDisabled(true);
    document.getElementById("ddom_status").innerHTML="<span style='color:red'><{$words.ddom_manual_start}></span>";
  }
}
/*
* Apply dual dom setting or manual start dual dom backup.
* @param value - none
* @returns none.
*/
function check_validate(b_types)
{
  var msg;
  
  if(b_types == "ddom_mnaul"){
    msg = "<{$words.ddom_comfirm}>";
  }else{
    msg = "<{$gwords.confirm}>";
  }
  
  Ext.Msg.confirm("<{$words.ddom_title}>",msg,function(btn){
  if(btn=='yes'){ 
    //alert(ddom_form.getForm().getValues(true));
    processAjax('setmain.php?fun=setddombackup',update_ddom_status,ddom_form.getForm().getValues(true)+"&act="+b_types);
  }})
}

/*
* Apply dual dom setting or manual start dual dom backup.
* @param value - none
* @returns none.
*/
function radio_check(thisobj,check){
  var type_array = thisobj.getId().split("_");
  if(check){
      now_type = type_array[0];
      set_item(type_array[0],1);
  }
}
  

//disable or enable ddombackup checkbox
var en_checkbox = new Ext.form.Checkbox({
  name:'ddom_on',
  id:'ddom_on',
  value:1,
  <{ if $ddom_enable=="1"}>
  checked:true,
  <{/if}>
  boxLabel:'<{$words.ddom_enabled}>'
});

//when checkbox change to disable or enable dual dom option
en_checkbox.on('check',function(obj,check){
  disable_list(check);
});

//week data for week combox
var week_store = new Ext.data.SimpleStore({
	fields: <{$week_fields}>,
	data: <{$week_data}>
});

//week combox sun-sat
var weekly_combobox = new Ext.form.ComboBox({
	store:week_store,
	valueField :'value',
	displayField:'display',
	mode: 'local',
	forceSelection: true,
	editable: false,
	triggerAction: 'all',
	id: 'weekly_combobox',
	name: 'weekly_combobox',
	hiddenName:'week_day',
	listWidth :100,
	width:100,
	value:"<{$ddom_default_setting.w_default}>"
});

//day data for week combox  
var month_store= new Ext.data.SimpleStore({
	fields: <{$day_fields}>,
	data: <{$day_data}>
});

//day combobox 1-31  
var monthly_combobox = new Ext.form.ComboBox({
	store:month_store,
	fieldLabel:'<{$gwords.time}>',
	valueField :'value',
	displayField:'display',
	mode: 'local',
	forceSelection: true,
	editable: false,
	triggerAction: 'all',
	id: 'monthly_combobox',
	name: 'monthly_combobox',
	hiddenName:'month_day',
	listWidth :50,
	width:50,
	value:"<{$ddom_default_setting.m_default}>"
});

/*
* Create radio.
* @param  item_name - for boxLabel text
*         item_value - for default value
*         item_id - for radio id 
* @returns none.
*/
function create_radio(item_name,item_value,item_id){
  new_radio = new Ext.form.Radio({
    boxLabel : item_name,
    name : "ddom_type",
    id : item_id,
    inputValue : item_value,
    width : 80,
    handler : radio_check
  });

  return new_radio;       
}
  
var auto_radio = create_radio("<{$words.auto}>","auto","auto_radio");
var daily_radio = create_radio("<{$words.daily}>","daily","daily_radio");
var weekly_radio = create_radio("<{$gwords.weekly}>","weekly","weekly_radio");
var monthly_radio = create_radio("<{$gwords.monthly}>","monthly","monthly_radio");

/*
* Create time field.
* @param  item_name - for field name and id
*         item_value - for default value
* @returns none.
*/
function create_time_field(item_name,time_value){
  return new Ext.form.TimeField({
           hideLabel:false,
           name: item_name,
           id: item_name,
           increment:5,
           model:"local",
           format:"H:i",
           forceSelection:true, 
           emptyText:"00:00",
           emptyClass:"x-form-focus",
           value: time_value
         });
}
  
var daily_time = create_time_field("daily_time","<{$ddom_default_setting.d_time}>");
var weekly_time = create_time_field("weekly_time","<{$ddom_default_setting.w_time}>");
var monthly_time = create_time_field("monthly_time","<{$ddom_default_setting.m_time}>");

//show dual dom backup status
var ddom_status = new Ext.form.Label({
  id : "ddom_status",
  html : "<span style='color:red'><{$ddom_status}></span>"
});

//dual dom option table
var ddom_table=new Ext.Panel({
  layout:'table',
  name:'ddom_table',
  width:600,
  defaults: {
        // applied to each contained panel
        bodyStyle:'padding:5px'
  },
  layoutConfig: {
        // The total column count must be specified here
        columns:3 
  },
    items: [{    
              colspan: 3,
              items: [en_checkbox]
            },{   
              items: [auto_radio]
            },{},{},{
              items: [daily_radio]
            },{
              items: [daily_time]
            },{},{
              items: [weekly_radio]
            },{
              items: [weekly_combobox]
            },{
              items: [weekly_time]
            },{
              items: [monthly_radio]
            },{
              items: [monthly_combobox]
            },{
              items: [monthly_time]
            },{
              xtype:"panel",
              html:"<{$gwords.status}>:"
            },{
              colspan: 2,
              items: [ddom_status]
            }]
});   

//Apply button
var ddom_apply= new Ext.Button({
  id : 'ddom_apply',
  disabled : false,
  minWidth : 80,
  text:'<{$gwords.apply}>',  
  handler : function(thisobj) {
                  if (ddom_form.isVisible()) {                    
                    check_validate(thisobj.getId());
                  }
            }
});

//Manual button
var ddom_manual= new Ext.Button({
  id : 'ddom_mnaul',
  disabled : false,
  minWidth : 80,
  text:'<{$gwords.manual}>',
  handler : function(thisobj) {
                  if (ddom_form.isVisible()) {
                    check_validate(thisobj.getId());
                  }
            }
});

//doul dom backup list store for list grid
var list_store = new Ext.data.JsonStore({
  id:'backup_store',
  fields: ['task','date','fw']
  <{ if ($list_store != "null") }>
  ,data: <{$list_store}>
  <{/if}>
});
  
//doul dom backup list grid
var list_grid = new Ext.grid.GridPanel({ 
  id:"backup_grid",
  autoHeight:true,
  store: list_store,
  trackMouseOver:true,
  disableSelection:true,
  enableHdMenu:false,
  loadMask: true,
  bodyStyle:'padding:0px',
  viewConfig: {
    autoFill : true
  },        
   // grid columns
  columns:[{id: 'task', header: '<{$words.task_name}>', dataIndex: 'task'},
           {id: 'date', header: '<{$gwords.date}>', dataIndex: 'date'},
           {id: 'fw', header: '<{$gwords.firmware}>', dataIndex: 'fw'}
          ]
});    

//doul dom backup form 
var ddom_form=new Ext.FormPanel({
  name:'ddom_form',
  id:'ddom_form',
  buttonAlign:'left',
  renderTo:'ddom',
  style: 'margin: 10px;',
  frame:false,
  items:[{
          xtype:'fieldset', 
          id:'ddom_fieldset',
          width: 695,
          title:"<{$words.ddom_title}>",
          autoHeight:true,        
          collapsed: false,   
          buttonAlign:'left',
          items:[ddom_table],
          buttons:[ddom_manual,ddom_apply]
        },{
          xtype:'fieldset', 
          id:'list_fieldset',
          width: 695,
          title:"<{$words.ddom_list_title}>",
          autoHeight:true,        
          collapsed: false,
          items:[list_grid]
        }] 
});
  
Ext.getCmp(now_type+"_radio").setValue(now_type);
disable_list(<{$ddom_enable}>);
<{if $process_flag == 1}>
  ddom_manual.setDisabled(true);
<{/if}>  
update_flag=setTimeout("processAjax('getmain.php?fun=ddombackup&update=1&rand="+rand+"',update_data)",10*1000);

</script>

