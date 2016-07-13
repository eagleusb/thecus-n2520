<fieldset class="x-fieldset" style="margin: 10px;"><legend class="legend"><{$words.ups_Info}></legend>
<form id="upsform" name="upsform" method="post">
<input type="hidden" name="ups_option" id="ups_option" value="<{$ups_option}>" >
<table width="100%" border="0" cellspacing="4"  class="x-form-field">
  <tr>
    <td width="20%"><div align="left"><{$words.ups_use}>: </div></td>
    <td>
      <div id="en_raido"></div>
    </td>
  </tr>
  <tr name="ups_tr" id="ups_tr">
    <td width="20%"><div align="left"><{$words.ups_usems}>: </div></td>
    <td>
      <div id="master_slave_radio"></div>
    </td>
  </tr>
  <tr name="ups_ms" id="ups_ms">
      <td>
            <{$words.ups_ip}>:
      </td>
      <td>
            <input type="text" name="_ups_ip" id="_ups_ip" required=1 size="15" maxlength="50" style="width:150px" value="<{$ups_ip}>">
      </td>
  </tr>
  <tr name="ups_tr" id="ups_tr">
    <td><div align="left"><{$words.manufacture}>: </div></td>
    <td><div id="ups_brand"></div></td>
  <tr>  
  <tr name="ups_tr" id="ups_tr">
    <td><div align="left"><{$gwords.model}>: </div></td>
    <td><div id="ups_model"></div></td>
  <tr>
  <tr>
    <td></td>
    <td nowrap>
           <span style="color:red"><{$words.model_comment}></span>
    </td>
  </tr>
  </tr>
  <tr name="ups_tr" id="ups_tr">
    <td><div align="left"><{$words.ups_batt_stat}>: </div></td>
    <td><div id="battery_use"><{$battery_use}></div></td>
  </tr>
  <tr name="ups_tr" id="ups_tr">
    <td><div align="left"><{$words.ups_power}>: </div></td>
    <td><div id="power_stat"><{$power_stat}></div></td>
  </tr>
  <tr name="ups_tr" id="ups_tr">
    <td colspan="2" nowrap>
      <table>
        <tr><td width="75%"><{$words.ups_power_fail_notify}></td>
        <td><div id="ups_pollfreq" style="display:in-line"></div></td>
<!--            <td><{$gwords.seconds}></td>-->
       </tr>
       <tr><td width="75%"><{$words.ups_subpower_fail_notify}></td>
       <td><div id="ups_pollfreqalert" style="display:'inline'"></div></td>
<!--            <td><{$gwords.seconds}></td>-->
        </tr>  
        <tr><td width="75%"><{$words.ups_shutdown_less}></td>
        <td><div id="ups_finaldelay"></div></td>
<!--            <td>%</td>-->
        </tr>
      </table>
    </td>        
  </tr>
  <tr>
    <td colspan="2" style="padding:0"><div id="apply"> </div></td>
  </tr>
  </tr>
</table>
</fieldset>

<fieldset class="x-fieldset" style="margin: 10px;"><legend class="legend"><{$gwords.description}></legend>
<form id="upsform" name="upsform" method="post">
<input type="hidden" name="ups_option" id="ups_option" value="<{$ups_option}>" >
<table width="100%" border="0" cellspacing="4"  class="x-form-field">
  <tr name="ups_tr" id="ups_tr">
  <td><div align="left"><{$words.ups_description}></div></td>
  </tr>
</table>
</fieldset>


<script type="text/javascript">
var ups_data=[[5],[10],[20],[30],[40],[50],[60]];
var model_data=<{$model_data}>;
var power_minitor;
var IE4 = (navigator.appName == "Microsoft Internet Explorer" && parseInt(navigator.appVersion) >= 4);

function ExtDestroy(){ 
 Ext.destroy(
              Ext.getCmp('en_radio'),
              Ext.getCmp('master_slave_radio'),
              Ext.getCmp('ups_brand_store'),
              Ext.getCmp('ups_brand'),
              Ext.getCmp('ups_model_store'),
              Ext.getCmp('ups_model'), 
              Ext.getCmp('ups_pollfreqalert'),
              Ext.getCmp('ups_pollfreq'),
              Ext.getCmp('ups_finaldelay'),
              Ext.getCmp('apply_button')
              );  
}

/*
* update ups power and battery status.
* @param none
* @returns none.
*/    
function Update(){
  var request = eval("("+replaceStr(this.req.responseText)+")"); 
  if(document.getElementById('battery_use')!=null)
    document.getElementById('battery_use').innerHTML=request.battery_use;
  if(document.getElementById('power_stat')!=null)
    document.getElementById('power_stat').innerHTML=request.power_stat;
      
  if(TCode.desktop.Group.page === 'ups'){    
    if(document.getElementsByName('_ups_use')){
      if (document.getElementsByName('_ups_use')[0].checked == true){   
        power_minitor = setTimeout("processAjax('getmain.php?fun=ups&update=1',Update)",20*1000);
      }else{
        clearTimeout(power_minitor);
      }
    }  
  }else{
    clearTimeout(power_minitor);
  }
}

/*
* show result after  ups setting.
* @param none
* @returns none.
*/   
function execute_ups_result()
{
  var request = eval('('+this.req.responseText+')'); 
  clearTimeout(power_minitor);
  mag_box(request.topic,request.message,request.icon,request.button,request.fn,request.prompt);
  if(document.getElementsByName('_ups_use')[0].checked == true){
    processAjax('getmain.php?fun=ups&update=1',Update);    
  }  
}


/*
* execute ups setting.
* @param none
* @returns none.
*/
function check_validate()
{
  Ext.Msg.confirm('<{$words.ups_Info}>',"<{$gwords.confirm}>",function(btn){
    if(btn=='yes') 
    {
      if(document.getElementById('upsform')) 
        processAjax('setmain.php?fun=setups',execute_ups_result,document.getElementById('upsform'));      
     // power_minitor = setTimeout("processAjax('getmain.php?fun=ups&update=1',Update)",15*1000);
      if(document.getElementsByName('_ups_use')[1].checked == true) {
        Disable_Fn(0);        
        clearTimeout(power_minitor);
        document.getElementById('battery_use').innerHTML='<{$gword.na}>';
        document.getElementById('power_stat').innerHTML='<{$gword.na}>';
      }  
    }})
} 


/*
* when user select disable ups will disable option.
* @param value:enable or disable
* @returns none.
*/
function Disable_option(value)
{
  if(value!='0'){
//    ups_pollfreq.enable();
//    ups_subpower.enable();
//    ups_finaldelay.enable();
    master_slave_radio.enable();
    ups_model.enable();
    ups_brand.enable();
    ups_pollfreq.enable();  
    ups_pollfreqalert.enable();    
     ups_finaldelay.enable();
  }else{
//   ups_pollfreq.disable();
//   ups_subpower.disable();
//   ups_finaldelay.disable();
   Disable_Fn(0,"ups_ms"); 
   master_slave_radio.disable();   
   ups_model.disable();
   ups_brand.disable();
   ups_pollfreq.disable();
   ups_pollfreqalert.disable();
   ups_finaldelay.disable();
  }
}

/*
* ups mode will change when ups brand change.
* @param record: ups brand record 
* @param model_value: ups model initial value
* @returns none.
*/
function mfschange(record,model_value){
  ups_model.clearValue();
  ups_model.store.loadData(model_data[record.data.id]);
  var data = model_data[record.data.id];
  var maxLength = 0;
  for( var i = 0 ; i < data.length ; ++i ) {
    if ( data[i].info.length > maxLength ) {
        maxLength = data[i].info.length;
    }
  }
  maxLength += 7;
  
  ups_model.list.setWidth( maxLength * 12 / 2 );
  ups_model.setValue(model_value);
  ups_model.innerList.setWidth('auto');
  //if(document.getElementById('ups_option')) 
    document.getElementById('ups_option').value=model_data[record.data.id][0]['driver'];
}

//ups enable or disable radio
var en_radio= new Ext.form.RadioGroup({
  xtype: 'radiogroup',
  renderTo:'en_raido',
  fieldLabel: '<{$words.ups_use}>',
  columns: 2,
  items: [
           {boxLabel: '<{$gwords.enable}>', name: '_ups_use', inputValue: 1 <{if $ups_use==1}> ,checked:true<{/if}>},
           {boxLabel: '<{$gwords.disable}>', name: '_ups_use', inputValue: 0 <{if $ups_use==0}> ,checked:true<{/if}>}
          ]
  //listeners: {change:{fn:function(){alert('radio changed');}}}
});

var master_slave_radio= new Ext.form.RadioGroup({
  xtype: 'radiogroup',
  renderTo:'master_slave_radio',
  fieldLabel: '<{$words.ups_usems}>',
  columns: 2,
  items: [
           {boxLabel: '<{$gwords.enable}>', name: '_ups_usems', inputValue: 1 <{if $ups_usems==1}> ,checked:true<{/if}>},
           {boxLabel: '<{$gwords.disable}>', name: '_ups_usems', inputValue: 0 <{if $ups_usems==0}> ,checked:true<{/if}>}
          ]
});

//change ups option status
en_radio.on('change', function(obj,value){    
  Disable_option(value);
});
    
master_slave_radio.on('change', function(obj,valueip){    
  if(valueip!='0'){
    Disable_Fn(1,"ups_ms");
  }else{
    Disable_Fn(0,"ups_ms");
  }
});
//ups brand info
var ups_brand_store= new Ext.data.JsonStore({
         fields: ['id','info']
         <{if $mdata!='[]'}>
         ,data: <{$mdata}>
         <{/if}>    
});

//ups brand select combox
var ups_brand =  new Ext.form.ComboBox({
  store:ups_brand_store,
  renderTo:'ups_brand',
  fieldLabel:'<{$words.manufacture}>',
  valueField :"info",
  displayField:"info",
  mode: 'local',
  forceSelection: true,
  editable: false,
  triggerAction: 'all',
  name: '_ups_brand',
  listWidth: 250,
  listeners:{
      select:function(combo, record,index){
        mfschange(record,model_data[record.data.id][0]['info']);
      }
  }
});

//ups model info
var ups_model_store=new Ext.data.JsonStore({
         fields: ['info','driver']
         <{if $model_first_data!='null'}>
         ,data:<{$model_first_data}>
         <{/if}>
});

//ups model select combox
var ups_model =  new Ext.form.ComboBox({
  store: ups_model_store,
  renderTo:'ups_model',
  valueField :"info",
  displayField:"info",
  mode: 'local',
  forceSelection: true,
  editable: false,
  triggerAction: 'all',
  listWidth: 430,
  lazyInit: false,
  name: '_ups_model',
  listeners:{
      select:function(combo, record,index){
       //if(document.getElementById('ups_option')) 
         document.getElementById('ups_option').value=record.data.driver;
      }
  }
});

//ups setting apply button
var apply_button = new Ext.Button({
  text : '<{$gwords.apply}>',
  disabled : false,
  renderTo:'apply',
  handler : function() {
                check_validate();
              
            }
  }); 

//show slider tip message
var tip = new Ext.ux.SliderTip({
   getText: function(slider){
         return String.format('<b>{0}s</b>', slider.getValue());
     }
});    

//show slider tip message 
var tip1 = new Ext.ux.SliderTip({
   getText: function(slider){
         return String.format('<b>{0}%</b>', slider.getValue());
     }
});    
     
//ups pooll freq setting
var ups_pollfreq = new Ext.form.SliderField({
  xtype: 'sliderfield',
  name: '_ups_pollfreq',
  id: '_ups_pollfreq',
  width: 130,
  increment: 1,
  minValue: 5,
  maxValue: 60,
  setMsg:' s',
  setZero:'0 %',
  renderTo:"ups_pollfreq",
  hideLabel:true,
  value:'<{$ups_pollfreq}>',
  plugins: tip
});

//ups pooll freqalert setting
var ups_pollfreqalert = new Ext.form.SliderField({
  xtype: 'sliderfield',
  name: '_ups_pollfreqalert',
  id: '_ups_pollfreqalert',
  width: 130,
  increment: 1,
  minValue: 5,
  maxValue: 60,
  setMsg:' s',
  renderTo:"ups_pollfreqalert",
  hideLabel:true,
  value:'<{$ups_pollfreqalert}>',
  plugins: tip
});    

//ups final delay setting
var ups_finaldelay = new Ext.form.SliderField({
  xtype: 'sliderfield',
  name: '_ups_finaldelay',
  id: '_ups_finaldelay',
  width: 130,
  increment: 1,
  minValue: 5,
  maxValue: 60,
  setMsg:' %',
  setZero:'0 %',
  renderTo:"ups_finaldelay",
  hideLabel:true,
  value:'<{$ups_finaldelay}>',
  plugins: tip1
});

ups_brand.setValue('<{$ups_brand}>');
ups_model.setValue('<{$ups_model}>');
 
Disable_option(<{$ups_use}>);
<{if $ups_use}>
  processAjax('getmain.php?fun=ups&update=1',Update);
<{/if}>  

<{if $ups_usems=="0"}>
    Disable_Fn(0,"ups_ms");
<{/if}>
</script>
