
<div id='power'></div>

<script type="text/javascript">
var schedule_data='<{$power_action}>';//schedule option=>power on, power off, none  



function ExtDestroy(){ 
 Ext.destroy(
            Ext.getCmp('power_apply'),
            Ext.getCmp('en_checkbox'),
            Ext.getCmp('schedule_store'),
            Ext.getCmp('power_table'),
            Ext.getCmp('power_form')
            );  
}


Ext.onReady(function(){
/*
* disable or enable UI.
* @param value - disable true or false
* @returns none.
*/    
  function disable_option(value){
    <{foreach from=$db_data key=name item=data}>
      Ext.getCmp('_<{$name}>1').setDisabled(value);
      Ext.getCmp('_<{$name}>2').setDisabled(value);
      Ext.getCmp('_<{$name}>1_tt').setDisabled(value);
      Ext.getCmp('_<{$name}>2_tt').setDisabled(value);
    <{/foreach}>  
  }

/*
* determine UI disable or enable.
* @param value - checkbox status
* @returns none.
*/
  function disable_list(value){
    if(value){
      disable_option(false);
    }else{
      disable_option(true);      
    }
  }

/*
* Apply schedule setting.
* @param value - none
* @returns none.
*/  
  function check_validate()
  {
    Ext.Msg.confirm("<{$words.schedule}>","<{$gwords.confirm}>",function(btn){
    if(btn=='yes') 
    { 
      //disable_option(false);
    //  alert(power_form.getForm().getValues(true));
      
      processAjax('setmain.php?fun=setpower',onLoadForm,power_form.getForm().getValues(true));
      //if(!en_checkbox.getValue())
      //  disable_option(true);
    }})
  }

//Apply button
  var power_apply= new Ext.Button({
      id : 'power_apply',
      disabled : false,
      minWidth:80,
      text:'<{$gwords.apply}>',  
       handler : function() {
                    if (power_form.isVisible()) {
                      check_validate();                    
                    } 
      }
  });  


//disable or enable schedule checkbox
  var en_checkbox=new Ext.form.Checkbox({
    name:'_schedule_on',
    id:'_schedule_on',
    value:1,
    <{ if $schedule_on=="1"}>
    checked:true,
    <{/if}>
    boxLabel:'<{$words.enable}>'
  });

//when checkbox change to disable or enable schedule option
  en_checkbox.on('check',function(obj,check){
    disable_list(check)
  });

//schedule option=>power on, power off, none  
  var schedule_store=new Ext.data.SimpleStore({
    fields:['value','display'],
    data:eval(schedule_data)
  })

//schedule UI layout  
  var power_table=new Ext.Panel({
    layout:'table',    
    name:'spcae_table',
    width:600,
    defaults: {
          // applied to each contained panel
          bodyStyle:'padding:10px',
          width:100
    },
    layoutConfig: {
          // The total column count must be specified here
          columns:5 
    },
      items: [{    
                colspan: 5,
                items:[en_checkbox],
                width:600
              },{},
              {
                html:'<{$words.action}>'
              },{
                html:'<{$gwords.time}>'
              },{
                html:'<{$words.action}>'
              },{
                html:'<{$gwords.time}>'
              }
              <{foreach from=$db_data key=name item=data}>
              ,{
                xtype:'panel',
                html:'<{$data[0]}>:'
              },{
                xtype:'combo',
                store:schedule_store,
                valueField :'value',
                displayField:'display',
                mode: 'local',
                forceSelection: true,
                editable: false,
                triggerAction: 'all',
                hiddenName:'<{$name}>1',
                id:'_<{$name}>1',
                hideLabel:true,
                //width:100,
                listWidth:100,
                value:'<{$data[1]}>'            
              },{
                xtype:'timefield',
                hideLabel:false,
                name:'<{$name}>1_tt',
                id:'_<{$name}>1_tt',
                increment:5,
                model:'local',
                format:'H:i',
                forceSelection:true, 
                emptyText:'00:00',
                emptyClass:'x-form-focus',
                value:'<{$data[2]}>:<{$data[3]}>'
              },{
                xtype:'combo',
                defaults:{style:'height:60px'},
                store:schedule_store,
                valueField :'value',
                displayField:'display',
                mode: 'local',
                forceSelection: true,
                editable: false,
                triggerAction: 'all',
                hiddenName:'<{$name}>2',
                id:'_<{$name}>2',
                hideLabel:true,
                listWidth:100,                
                value:'<{$data[4]}>'            
              },{
                xtype:'timefield',
                hideLabel:false,
                name:'<{$name}>2_tt',
                id:'_<{$name}>2_tt',
                increment:5,
                model:'local',
                format:'H:i',
                forceSelection:true,
                emptyText:'00:00',
                emptyClass:'x-form-focus',
                value:'<{$data[5]}>:<{$data[6]}>'            
              }            
              <{/foreach}>
              ]
  });            
  
//schedule form 
  var power_form=new Ext.FormPanel({
    name:'power_form',
    height:370,
    buttonAlign:'left',
    renderTo:'power',
    style: 'margin: 10px;',
    items:[power_table],
    buttons:[power_apply]
  });
  disable_list(<{$schedule_on}>);
  power_table.syncSize();
});
</script>