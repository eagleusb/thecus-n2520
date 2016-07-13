var booting_win = new Ext.Window({
    id:"booting_win",
    title:wait_msg,
    border:false,
    resizable:false,
    modal:true,
    closable:false,
    width:400,
    height:120,
    bodyStyle:"padding:20px;background-color:#c3d2e6",
    defaults:{
        bodyStyle:"background-color:#c3d2e6;"
    },
    items:[
        {
            xtype:"label",
            id:"bootimg",
            html:"<img src='/theme/images/icons/rebuild_icon.png' align='middle' style='padding-right:20px'/>"
        },
        {
            xtype:"label",
            id:"boottext"
        }
    ]
});

var HA = function(){
    var force_boot_flag;
    var role;
    var current_ha;
    var ha_num;
    var ha_warn;
    var wording;
    var count = 0;
    var rebooting = false;
    
    return {
        monitor: function(obj){
            force_boot_flag = true;
            var role = obj.dbrole;            //db role
            var current_ha = obj.tmprole;     //tmp role
            var ha_num = obj.res;     //result code
            var ha_warn = obj.msg    //result error wording
            var wording = obj.wording //wording
  
            // check role is change.... refresh to HA page
        if(current_ha != ''){  
            if(role_tmp != current_ha){
                    change_role=1;
            }
            if(role_tmp==current_ha && change_role==1){
                    change_role=0;
                processUpdater('getmain.php','fun=ha');
            }
        }
              
              // show ha monitor window
              if(ha_num!=""){
                 if( booting_win && booting_win.rendered ) {
                     booting_win.hide();
                 }
                 if( Window_log && Window_log.rendered ) {
                     Window_log.hide();
                 }
                 mainMask.hide();
                 booting_win.show();
              } 
              
              // show ha monitor content window
              switch(ha_num){ 
                  //--------------------
                  // halt
                  //--------------------
                  case '0': // wait halt
                      Ext.getCmp('boottext').el.dom.innerHTML = wording.ready_shutdown;
                    break;
                  case '1': // success halt 
                     booting_win.hide();
                     mainMask.hide();
                     clearTimeout(monitor); 
                     processAjax('setmain.php?fun=setreboot',onLoadForm,'action=shutdown&noaction=1'); 
                      break;
                      
                  //--------------------
                  // reboot
                  //--------------------
                  case '2': //wait reboot
                      Ext.getCmp('boottext').el.dom.innerHTML = wording.ready_reboot;
                    break;
                  case '3': // success reboot
                     booting_win.hide();
                     clearTimeout(monitor);
                     processAjax('setmain.php?fun=setreboot',onLoadForm,'action=reboot&noaction=1');
                      break;
                      
                  //--------------------
                  // enable ha
                  //--------------------
                  case '4': //wait enable
                      if( count < 3 ) {
                        count++;
                      }
                      var ha_wait_enable_msg = "";
                      if(role=='0'){
                             ha_wait_enable_msg = wording.wait_standby;
                      }else{
                             ha_wait_enable_msg = wording.wait_checkconf;
                      } 
                      booting_win.hide();
                      Ext.Msg.show({
                          minWidth:380,
                          msg:ha_wait_enable_msg + '<br><br>' + wording.confirm_reboot, 
                          closable:false,
                          icon: Ext.MessageBox.INFO,
                          buttons: count < 3 ? null : Ext.Msg.CANCEL,
                          fn:function(btn){
                              count = 0;
                              processAjax('setmain.php?fun=setreboot',null,'action=cancel');
                          }
                      });
                    break;
                  case '5': // success enable
                      Ext.Msg.hide();
                      if(role=='0'){
                          booting_win.hide();
                          if(force_boot_flag){
                            if( TreeMenu.getValue().treeid != '23' ) {
                              TreeMenu.setCurrentPage(treereboot[0]);
                              force_boot_flag = false;
                            }
                          }
                      }else{
                            booting_win.hide();
                            Ext.Msg.show({
                                minWidth:380,
                                msg:wording.wait_activereboot, 
                                closable:false,
                                icon:'rebuild',
                                buttons: null,
                                fn:function(btn){
                                    processAjax('setmain.php?fun=setreboot',null,'action=cancel');
                                }
                            });
                      }
                      break;
                      
                      
                  case '20': // success enable without reboot
                      booting_win.hide();
                       Ext.Msg.show({
                           title:wording.success,
                           minWidth:300,
                           msg:wording.success_ha, 
                           closable:false,
                           buttons:eval('Ext.MessageBox.OK'),
                           fn:function(btn){
                               processAjax('setmain.php?fun=setreboot',null,'action=cancelboot');
                           }
                       });
                      break;
                      
                      
                  //--------------------
                  // rebuild ha
                  //--------------------
                  case '16': //wait rebuild config
                  case '16.5':
                      force_boot_flag = true;
                      Ext.getCmp('boottext').el.dom.innerHTML = wording.checkconfig;
                      break;
                  case '17': // success rebuild config
                      Ext.getCmp('boottext').el.dom.innerHTML = wording.create_raid_ha; 
                      break;
                  case '19': // success ready to reboot
                       booting_win.hide();
                      if(rebooting == false && force_boot_flag){
                        Ext.Msg.show({
                            title:wording.success,
                            minWidth:400,
                            msg:wording.success_readyreboot ,
                            closable:false,
                            buttons:eval('Ext.MessageBox.OK'),
                            fn:function(btn){
                               rebooting = true;
                               processAjax('setmain.php?fun=setreboot&action=reboot',onLoadForm);
                               return;
                            }
                        });
                        force_boot_flag = false;
                      }
                      break;
                      
                  //--------------------
                  // failure.....
                  //--------------------
                  // fail
                  case '101':   //halt
                     booting_win.hide();
                       Ext.Msg.show({
                           title:wording.warn,
                           minWidth:300,
                           msg:wording.error_shutdown,
                           closable:false,
                           buttons:eval('Ext.MessageBox.OK'),
                           icon: Ext.MessageBox.ERROR,
                           fn:function(btn){
                               processAjax('setmain.php?fun=setreboot',null,'action=cancelboot');
                           }
                       });
                      break;
                  case '103':   //reboot
                     booting_win.hide();
                       Ext.Msg.show({
                           title:wording.warn,
                           minWidth:300,
                           msg:wording.error_reboot,
                           closable:false,
                           buttons:eval('Ext.MessageBox.OK'),
                           icon: Ext.MessageBox.ERROR,
                           fn:function(btn){
                               processAjax('setmain.php?fun=setreboot',null,'action=cancelboot');
                           }
                       });
                      break;
                  case '105': 
                  case '117':
                  case '119':
                     booting_win.hide();
                       Ext.Msg.show({
                           title:wording.warn,
                           minWidth:300,
                           msg:ha_warn,
                           closable:false,
                           buttons:eval('Ext.MessageBox.OK'),
                           icon: Ext.MessageBox.ERROR,
                           fn:function(btn){
                               processAjax('setmain.php?fun=setreboot',null,'action=cancel');
                           }
                       });
                      break;
                  default:
                    if(booting_win.rendered){
                        booting_win.hide();  
                    }
              } 
        }
    } 
}();

