<script type="text/javascript">   
var nfs_mount_point;  //NFS mount point description varaible

//********************* dynamic load css , for IE css problem*******************
var headID = document.getElementsByTagName("head")[0];
var newCss = document.createElement('link');
newCss.type = 'text/css';
newCss.rel = "stylesheet";
newCss.href = "<{$urlcss}>share.css";
headID.appendChild(newCss); 



function confirm_add_share(){
    //confirm_msg = (Ext.getDom('action_share').value=='update' )?"Do you want to edit?":"Do you want to add?"; 
    Ext.Msg.confirm('<{$gwords.info}>', "<{$gwords.confirm}>" , function(btn){ 
        if(btn=='yes'){   
            processAjax('<{$set_url}>', onLoadForm, formpanel_share.getForm().getValues(true)+'&md_num='+raidnum_combo.getValue());
        }
    });
}


function confirm_add_nfs(){
   // confirm_msg = (Ext.getDom('nfs_action_share').value=='nfs_update')?"Do you want to edit?":"Do you want to add?"; 
    Ext.Msg.confirm('<{$words.nfs_title}>', "<{$gwords.confirm}>" , function(btn){
        if(btn=='yes'){ 
            Ext.getCmp('_hostname').setDisabled(false); 
             
             processAjax('<{$set_url}>', onLoad_nfs_apply, formpanel_nfs.getForm().getValues(true));  
        }
    });
}

function clear_formpanel_share(){
    Ext.getCmp('_share').setValue('');
    Ext.getCmp('_comment').setValue('');
    Ext.getCmp('_quota_limit').setValue('');
    Ext.getCmp('action_share').setValue('');
    Ext.getCmp('path').setValue('');
}
  

function schedule_apply(){ 
    Ext.Msg.confirm('<{$gwords.info}>', '<{$swords.snap_schedule_confirm}>' , function(btn){ 
        if(btn=='yes'){  
               var chk1='0',chk2='0';
               if(Ext.getCmp('chk1').checked) 
                    chk1='1'; 
               if(Ext.getCmp('chk2').checked) 
                    chk2='1'; 
               var node = tree.getSelectionModel().getSelectedNode();    
               var param='&action_snapshot=set_schedule'+ 
                      '&share='+encodeURIComponent(node.attributes.share)+
                      '&md_num='+node.attributes.md_num+
                      '&_enable_schedule='+chk1+
                      '&_enable_autodel='+chk2; 
               param+='&'+formpanel_schedule.getForm().getValues(true)+'&_schedule_rule='+Ext.getCmp('combo_rule').value; 
               
               processAjax('<{$set_url}>',onLoad_result_schedule,param); 
        }
    });
    
}  
/**
* after add share, get quota count from server-side
*/
function onLoadAddShare()
{
  var request = eval('('+this.req.responseText+')');   
  var int_quota_count = request.quota_count;
  CheckQuotaFolderLimit(int_quota_count,0,'add');
}
/**
* check quota folder limit,
* handle disabled share folder limit column. 
*/
function CheckQuotaFolderLimit(quota_count,quota_limit,ac)
{
      // check quota folder limit
   var quota_folder_limit= "<{$quota_folder_limit}>";
      if(quota_folder_limit <=quota_count && (quota_limit==0 || ac=='add' )){
                 Ext.getCmp('_quota_limit').setDisabled(true);
         }
}

// click sharefolder toolbar [add/edit/remove/acl/nfs] then popup Window  
function toolbar_share(clickid){
   var node = tree.getSelectionModel().getSelectedNode();    
   if(node!=null || clickid.id=='add'){
         switch(clickid.id){
            case 'add':
               tree.getSelectionModel().clearSelections();
              processAjax('<{$get_url}>&tree=quota', onLoadAddShare);  
                window_ext.getLayout().setActiveItem(formpanel_share);
                <{if $open_mraid!='0'}>
                raidnum_combo.setValue("<{$md_num_default}>,<{$file_system_default}>");
                <{/if}> 
                raidnum_combo.setDisabled(false);
               <{if $file_system_default=='xfs' || $file_system_default=='ext4' || $file_system_default=='ext3'}>
                  Ext.getCmp('_quota_limit').setDisabled(true);
               <{else}>
                  Ext.getCmp('_quota_limit').setDisabled(false);
                <{/if}>
                Ext.getCmp('share_usage_panel').setVisible(false);
                Ext.getCmp('path').setValue("/"); 
                Ext.getCmp('_share').setValue(''); 
                Ext.getCmp('_quota_limit').setValue('0');  
                Ext.getCmp('action_share').setValue('add'); 
                Ext.getCmp('radio_guest_only').setValue('no'); 
                Ext.getCmp('_share').setDisabled(false);
    Ext.getCmp('sysfolder').setValue('1');
                window_ext.setTitle('<{$aswords.settingTitle}>');
                window_ext.center();
                window_ext.show();
                Ext.getCmp('quota_usage_value').setValue(0);
                break;
            case 'edit':
                window_ext.getLayout().setActiveItem(formpanel_share);
                <{if $open_mraid!='0'}>
                var md_num_default = node.attributes.md_num+","+node.attributes.file_system;
                raidnum_combo.setValue(md_num_default);
                <{/if}>
                raidnum_combo.setDisabled(true);
                var path = '/'+node.attributes.share; 
                Ext.getCmp('path').setValue(path); 
                Ext.getCmp('o_share').setValue(node.attributes.share); 
                Ext.getCmp('o_quota_limit').setValue(node.attributes.quota_limit);  
                Ext.getCmp('o_guest_only').setValue(node.attributes.guest_only);  
                Ext.getCmp('o_browseable').setValue(node.attributes.browseable);  
                Ext.getCmp('o_md_num').setValue(node.attributes.md_num);   
                if(node.attributes.quota_percent!=''){ 
        Ext.getCmp('share_usage_panel').setVisible(true); 
        Ext.getCmp('quota_usage_txt').setText(node.attributes.quota_percent);   
                    Ext.getCmp('quota_usage_value').setValue(node.attributes.quota_usage);
    }else{  
       Ext.getCmp('share_usage_panel').setVisible(false);  
    }
                
                Ext.getCmp('radio_guest_only').setValue(node.attributes.guest_only);

                Ext.getCmp('_share').setValue(node.attributes.share); 
                Ext.getCmp('sysfolder').setValue(node.attributes.share_delete);
                if(node.attributes.file_system=='xfs' || node.attributes.file_system=='ext4' || node.attributes.file_system=='ext3'){
                  Ext.getCmp('_quota_limit').setDisabled(true);
                }else{
                  Ext.getCmp('_quota_limit').setDisabled(false);
                }
                Ext.getCmp('_quota_limit').setValue(node.attributes.quota_limit); 
                Ext.getCmp('action_share').setValue('update'); 
                Ext.getCmp('_share').setDisabled(node.attributes.share_delete =='0');
                window_ext.setTitle('<{$mswords.settingTitle}>');
                window_ext.center();
                window_ext.show();
        var quota_count = node.attributes.quota_count;  // count share folder number that have setted quota
        var quota_limit = node.attributes.quota_limit;  // current record quota limit 
        CheckQuotaFolderLimit(quota_count,quota_limit,clickid.id);
                break;
            case 'remove':
                Ext.Msg.confirm('<{$gwords.info}>', "<{$gwords.confirm}>" , function(btn){
                        if(btn=='yes'){
              Ext.Msg.prompt("<{$words.title}>","<{$words.delete_folder_prompt}>",function(btn,msg){
                if(btn=="ok"){
                    if(msg=="Yes"){
                    var sharename=encodeURIComponent(node.attributes.share);
                    processAjax('<{$set_url}>', onLoadForm,
                      '&action_share=remove&path=/'+sharename+
                      '&_share='+sharename+
                      '&md_num='+node.attributes.md_num);
                  }else if(msg!="Yes"){
                    Ext.Msg.show({
                      title:"<{$words.title}>",
                      msg: "<{$words.prompt_fail}>",
                      buttons: Ext.Msg.OK,
                      icon: Ext.MessageBox.INFO
                    });
                  }
                }
              });
                        }
                 });
                break;
            case 'nfs':   
                tabpanel_nfs.setActiveTab(0);
                window_ext.getLayout().setActiveItem(tabpanel_nfs);
                nfs_store.proxy.conn.url='<{$get_url}>&store=nfs_store&share='+encodeURIComponent(node.attributes.share)+'&md='+node.attributes.md_num;   
                nfs_store.load();
                if(node.attributes.guest_only=='yes'){
                      Ext.getCmp('radio_rootaccess').setDisableds('root_squash',false);
                      Ext.getCmp('radio_rootaccess').setDisableds('all_squash'),false;
                }else{
                      Ext.getCmp('radio_rootaccess').setDisableds('root_squash',true);
                      Ext.getCmp('radio_rootaccess').setDisableds('all_squash',true);
                }
                break; 
            case 'smb':               
                if(node.attributes.guest_only=='no'){
                    Ext.getCmp('readonlypanel').setVisible(false);
                }else{
                    Ext.getCmp('readonlypanel').setVisible(true);
                }
                
                if (node.attributes.speclevel=='1'){
                  Ext.getCmp('readonlypanel').setVisible(false);
                }
                
                Ext.getCmp('browseable_radio').setValue(node.attributes.browseable);
                window_ext.getLayout().setActiveItem(tabpanel_smb);
                window_ext.setTitle('<{$words.smb_title}>');
                window_ext.center();
                window_ext.show();
                Ext.getCmp('_comment').setValue(node.attributes.desc_all);
                Ext.getCmp('_smbreadonly').setValue(node.attributes.readonly);
                Ext.getCmp('smb_share').el.dom.innerHTML=node.attributes.share; 
                break; 
            case 'snapshot':  
                processAjax('<{$get_url}>', onLoad_schedule, '&store=schedule_store'+
                                                        '&share='+encodeURIComponent(node.attributes.share)+
                                                        '&md='+node.attributes.md_num);   
                window_ext.getLayout().setActiveItem(tabpanel);
                tabpanel.setActiveTab(0);
                var snap_title = '<{$swords.snap_title}>';
                snap_title = snap_title.replace('%s',node.attributes.share);
                window_ext.setTitle(snap_title+'- <{$snap_description}>');
                window_ext.center();
                window_ext.show();
                break; 
            case 'acl': 
                acl_popup(node);
                break;
      }
   }else{
         Ext.Msg.alert('<{$gwords.info}>', '<{$nwords.delete_confirm}>');
   }  
}


   
// click NFS toolbar [add/edit/remove] then change panel
function toolbar_nfs(clickid){
   var len = nfs_grid.getSelections();    
   var rows = nfs_grid.getSelectionModel().getSelected();   
   var node = tree.getSelectionModel().getSelectedNode();    
   if(len.length > 0 || clickid.id=='nfs_add'){
         Ext.getCmp('nfs_sharename').setValue(node.attributes.share); 
         Ext.getCmp('nfs_md_num').setValue(node.attributes.md_num);  
        // Ext.getCmp('radio_rootaccess').setDisabled((node.attributes.share_delete=='0'));
         
         switch(clickid.id){
            case 'nfs_add':   
                Ext.getCmp('nfs_action_share').setValue('nfs_add'); 
                Ext.getCmp('_hostname').setValue('xxx.xxx.xxx.xxx'); 
                Ext.getCmp('_hostname').setDisabled(false); 
                Ext.getCmp('radio_privilege').setValue('rw');
    <{if $NAS_DB_KEY=="1"}>
                Ext.getCmp('radio_os_support').setValue('0');
    <{else}>
                    Ext.getCmp('radio_os_support').setValue('secure');
    <{/if}>
                Ext.getCmp('radio_rootaccess').setValue('no_root_squash'); 
                Ext.getCmp('radio_sync_support').setValue('async');
                break;
            case 'nfs_edit': 
                Ext.getCmp('formpanel_nfs').setTitle('<{$gwords.edit}>'); 
                tabpanel_nfs.setActiveTab(1);
                Ext.getCmp('radio_privilege').setValue(rows.get('privilege'));
                Ext.getCmp('radio_os_support').setValue(rows.get('os_value'));
                Ext.getCmp('radio_rootaccess').setValue(rows.get('map_value')); 
                Ext.getCmp('radio_sync_support').setValue(rows.get('sync_value')); 
                Ext.getCmp('_hostname').setValue(rows.get('hostname'));
                Ext.getCmp('_hostname').setDisabled(true); 
                Ext.getCmp('nfs_action_share').setValue('nfs_update');  
                break;
            case 'nfs_remove':
                Ext.Msg.confirm('<{$gwords.info}>', "<{$gwords.confirm}>", function(btn){ 
                        if(btn=='yes'){  
                            processAjax('<{$set_url}>', onLoad_nfs_remove, '&nfs_action_share=nfs_remove&nfs_sharename='+encodeURIComponent(node.attributes.share)+'&_hostname='+rows.get('hostname')+'&nfs_md_num='+node.attributes.md_num);  
                        }
                 });
                break;
         }
   }else{
         Ext.Msg.alert('<{$gwords.info}>','<{$nwords.delete_confirm}>');
   }  
} 


function toolbar_snapshot(clickid){
   var len = snapshot_grid.getSelections();    
   var rows = snapshot_grid.getSelectionModel().getSelected();   
   var node = tree.getSelectionModel().getSelectedNode();    
   if(len.length > 0 || clickid.id=='takeshot' || clickid.id=='schedule'){
         switch(clickid.id){
            case 'takeshot': 
                processAjax('<{$set_url}>', onLoadForm, '&action_snapshot=take_shot&share='+encodeURIComponent(node.attributes.share)+'&md_num='+node.attributes.md_num);  
                break; 
            case 'snapshot_remove':
                Ext.Msg.confirm('<{$gwords.info}>', "<{$gwords.confirm}>" , function(btn){ 
                        if(btn=='yes'){  
                            processAjax('<{$set_url}>', onLoadForm, '&action_snapshot=del_shot&share='+encodeURIComponent(node.attributes.share)+
                                                                    '&md_num='+node.attributes.md_num+
                                                                    '&share_date='+rows.get('share_date')+
                                                                    '&zfs_pool='+rows.get('zfs_pool')+
                                                                    '&zfs_share='+rows.get('zfs_share'));  
                        }
                 });
                break;
         }
   }else{
         Ext.Msg.alert('<{$gwords.info}>', '<{$nwords.delete_confirm}>');
   }  
} 

function showmsg(msg,aftersuccess){ 
   if(msg.show)
        mag_box(msg.topic,msg.message,msg.icon,msg.button,msg.fn,msg.prompt);
   if(msg.icon!='ERROR'){
        if(aftersuccess=='hidereload'){
            if(window_ext.isVisible())
                window_ext.hide();
            tree_loader.load(tree.getRootNode()); 
        }
        if(aftersuccess=='hide'){
            if(window_ext.isVisible())
                window_ext.hide();
        }
        if(aftersuccess=='schedule'){ 
            formpanel_snapshot.show();
            window_ext.setTitle('<{$snap_title}> - <{$snap_description}>');
            window_ext.center();
            if(!window_ext.isVisible()) { window_ext.show();}
        }
   }
}
//*********************** onLoad  **************************

function onLoad_result_schedule(){
    var request = eval('('+this.req.responseText+')'); 
    showmsg(request,'hide');
}
function onLoad_schedule(){ 
    var request = eval('('+this.req.responseText+')');   
    snapshot_store.loadData(request.snapshot);
     
    request.schedule.day = (request.schedule.day=='')?'1':request.schedule.day; 
    request.schedule.hour = (request.schedule.hour=='')?'0':request.schedule.hour;  
    Ext.getCmp('chk1').setValue(request.schedule.enabled);
    Ext.getCmp('chk2').setValue(request.schedule.autodel);    
    
     
    Ext.getDom('div_monthly').style.display='none';
    Ext.getDom('div_weekly').style.display='none';
    Ext.getDom('div_daliy').style.display='none';  
          
    if(request.schedule.enabled=='1'){
        Ext.getCmp('combo_rule').setValue(request.schedule.rule);
    }else{
        Ext.getCmp('combo_rule').setValue("m");
        Ext.getCmp('time1_combo').setDisabled(true); 
        Ext.getCmp('date_combo').setDisabled(true);
    } 
    if(request.schedule.rule=='m'){ 
        Ext.getDom('div_monthly').style.display='block';
        Ext.getCmp('date_combo').setValue(request.schedule.day);
        Ext.getCmp('time1_combo').setValue(request.schedule.hour); 
        if(request.schedule.enabled=='1'){
          Ext.getCmp('time1_combo').setDisabled(false); 
          Ext.getCmp('date_combo').setDisabled(false);
        } 
    }else if(request.schedule.rule=='w'){ 
        Ext.getDom('div_weekly').style.display='block';
        Ext.getCmp('week_combo').setValue(request.schedule.week);
        Ext.getCmp('time2_combo').setValue(request.schedule.hour); 
        Ext.getCmp('week_combo').setDisabled(false); 
        Ext.getCmp('time2_combo').setDisabled(false);
    }else if(request.schedule.rule=='d'){ 
        Ext.getDom('div_daliy').style.display='block';
        Ext.getCmp('time3_combo').setValue(request.schedule.hour);  
        Ext.getCmp('time3_combo').setDisabled(false);
    }
}
 
function onLoad_snapshot(){
    var node = tree.getSelectionModel().getSelectedNode();
    snapshot_store.proxy.conn.url='<{$get_url}>&store=snapshot_store&share='+encodeURIComponent(node.attributes.share)+'&md='+node.attributes.md_num; 
    snapshot_store.load();
}

function onLoad_share_apply(){ 
  if(window_ext.isVisible())
     window_ext.hide();
  tree_loader.dataUrl='<{$get_url}>&tree=rootfolder';
  tree_loader.load(tree.getRootNode()); 
};
 
function onLoad_nfs_remove(){  
  var node = tree.getSelectionModel().getSelectedNode();   
  nfs_store.proxy.conn.url='<{$get_url}>&store=nfs_store&&share='+encodeURIComponent(node.attributes.share)+'&md='+node.attributes.md_num;  
  nfs_store.load(); 
}; 

function onLoad_nfs_apply(){ 
  var request = eval('('+this.req.responseText+')'); 
  showmsg(request,'');
 // nfs_action_share = Ext.getCmp('nfs_action_share').getValue();
  if(request.icon!='ERROR'){
        tabpanel_nfs.setActiveTab(0);
        var node = tree.getSelectionModel().getSelectedNode();   
        nfs_store.proxy.conn.url='<{$get_url}>&store=nfs_store&&share='+encodeURIComponent(node.attributes.share)+'&md='+node.attributes.md_num;  
        nfs_store.load(); 
  } 
}; 

function onLoad_smb_apply(){ 
  var request = eval('('+this.req.responseText+')'); 
  showmsg(request,'hidereload'); 
}; 
 //***************************** ComboBox*************************
    var raidnum_store = new Ext.data.SimpleStore({
        fields: <{$combo_fields}>,
        data: <{$combo_value}>
    });
    var raidnum_combo = new Ext.form.ComboBox({
                xtype: 'combo',
                name: 'md_num',
                fieldLabel: "<{$gwords.raid_id}>", 
                hiddenName: '_charset_selected',
                mode: 'local',
                store: raidnum_store,
                displayField: 'display',
                valueField: 'value',
                readOnly: true,
                selectOnFocus:true,
                triggerAction: 'all' ,
                listeners:{
                    select:function(v){
                      var ary = v.value.split(",");
                      if(ary[1]=='xfs' || ary[1]=='ext4' ||ary[1]=='ext3') 
                         Ext.getCmp('_quota_limit').setDisabled(true);
                      else 
                         Ext.getCmp('_quota_limit').setDisabled(false);
                    }
                }
    }); 
//**********************Toolbar******************************** 
   var tb_items = [
      {
         text: '<{$gwords.add}>',
         iconCls: 'add',
         id:'add',
         handler: toolbar_share,
         disabled:false
      },'-',{
         text: '<{$gwords.edit}>',
         iconCls: 'edit',
         id:'edit',
         handler: toolbar_share,
         disabled:true
      },'-',{
         text: '<{$gwords.remove}>',
         iconCls: 'remove',
         id:'remove',
         handler: toolbar_share,
         disabled:true
      },'-'
      ];
   if ('<{$show_nfs}>' != '0') {
      tb_items.push(
         {
            text: '<{$gwords.nfs}>',
            iconCls: 'nfs',
            id:'nfs',
            handler: toolbar_share,
            disabled:true
         },
         '-'
      );
    } else {
      //Add hidden button to prevent Ext.getCmp('nfs') error.
      tb_items.push(
         {
            text: '<{$gwords.nfs}>',
            iconCls: 'nfs',
            id:'nfs',
            handler: toolbar_share,
            disabled:true,
            hidden:true
         }
      );
   }
   tb_items.push(
      {
         text: "<{$words.smb_name}>",
         iconCls: 'smb',
         id:'smb',
         handler: toolbar_share
      },'-'
   );
   if ('<{$show_snapshot}>' == '1') {
      tb_items.push(
         {
            text: '<{$gwords.snapshot}>',
            iconCls: 'snapshot',
            id:'snapshot',
            handler: toolbar_share,
            disabled:true
         },
         '-'
      );
   }
   tb_items.push(
      {
         text: '<{$gwords.acl}>',
         iconCls: 'wrench',
         id:'acl',
         handler: toolbar_share,
         disabled:true
      }
   );

    var tb = new Ext.Toolbar({
        id:'tb',
        items: tb_items
    });
     var tb_nfs = new Ext.Toolbar({
        id:'tb_nfs',
        items:[/*{ 
            text: '<{$gwords.add}>',
            iconCls: 'add',
            id:'nfs_add',
            handler:toolbar_nfs 
        },'-',*/{
            text: '<{$gwords.edit}>',
            iconCls: 'edit',
            id:'nfs_edit',
            handler:toolbar_nfs
        },'-',{
            text: '<{$gwords.remove}>',
            iconCls: 'remove',
            id:'nfs_remove',
            handler:toolbar_nfs
        }]
    });
     var tb_snapshot = new Ext.Toolbar({
        id:'tb_snapshot',
        items:[{ 
            text: '<{$swords.snap_manual}>',
            iconCls: 'add',
            id:'takeshot',
            handler:toolbar_snapshot 
        }/*,'-',{
            text: '<{$gwords.schedule}>',
            iconCls: 'edit',
            id:'schedule',
            handler:toolbar_snapshot 
        }*/,'-',{
            text: '<{$gwords.remove}>',
            iconCls: 'remove',
            id:'snapshot_remove',
            handler:toolbar_snapshot 
        }]
    });
    
    
 //**********************JsonStore********************************
    var snapshot_store = new Ext.data.JsonStore({
        id:'snapshot_store', 
        fields: ['snap_date','share_date','zfs_pool','zfs_share'] 
    });  
    var nfs_store = new Ext.data.JsonStore({
        id:'nfs_store', 
        fields: ['hostname','privilege_words','privilege','os','map','os_value','map_value', 'nfs_mount_point','sync_value'] 
    }); 
    
 //**********************Columns********************************
    var snapshot_cols =[
        {header: '<{$swords.snap_date}>', width: 170, sortable: true,dataIndex: 'snap_date'},
        {header: 'share_date',dataIndex: 'share_date',hidden:true},
        {header: 'zfs_pool',dataIndex: 'zfs_pool',hidden:true},
        {header: 'zfs_share',dataIndex: 'zfs_share',hidden:true}
    ];
    var nfs_cols =[
        {header: "<{$gwords.hostname}>", width: 80, sortable: true, dataIndex: 'hostname',menuDisabled:true},
        {header: '<{$gwords.privilege}>', width: 70, sortable: true, dataIndex: 'privilege_words',menuDisabled:true},
        {header: '<{$words.nfs_os_support}>', width: 80, sortable: true, dataIndex: 'os',menuDisabled:true},
        {header: '<{$words.nfs_id_mapping}>', width: 350, sortable: true,dataIndex: 'map',menuDisabled:true},
        {header: '<{$words.nfs_sync}> / <{$words.nfs_async}>', width: 80, sortable: true,dataIndex: 'sync_value',menuDisabled:true},
        { dataIndex: 'os_value',hidden:true},
        { dataIndex: 'map_value',hidden:true},
        { dataIndex: 'privilege',hidden:true}
    ];
 //**********************GridPanel********************************
    var snapshot_grid = new Ext.grid.GridPanel({
        bodyStyle:'padding:0px 0px 0px 0px;', 
        tbar             : tb_snapshot,
        id               :'snapshot_grid', 
        store            : snapshot_store,
        columns          : snapshot_cols, 
        stripeRows       : true,   
        width            : 470, 
        height           :253,
        stripeRows       : true, 
        loadMask:true,
        viewConfig: {
            forceFit:true 
        }
    });
    var nfs_grid = new Ext.grid.GridPanel({
        bodyStyle:'padding:0px 0px 0px 0px;', 
        tbar             : tb_nfs,
        id               :'nfs_grid', 
        store            : nfs_store,
        columns          : nfs_cols, 
        stripeRows       : true,   
        width            : 800, 
        height           : 330, 
        loadMask:true,
        viewConfig: {
            forceFit:true 
        }
    });
    

    
 //**********************FormPanel******************************** 
 
     
    var formpanel_schedule = new Ext.FormPanel({ 
        title:'<{$gwords.schedule}>',
        id:'formpanel_schedule',
        frame: true,  
        labelAlign:'left',
        buttonAlign:'left' , 
        contentEl : 'schedule_table',
        items:[{xtype: 'hidden'}], 
        listeners:{
             'show':function(){
                      document.getElementById('schedule_table').style.display='block';                      
             }
          }
    });  
    
   

    var formpanel_snapshot = new Ext.FormPanel({ 
        title:'<{$gwords.snapshot}>',
        bodyStyle:'padding:0px 0px 0px 0px;', 
        id:'formpanel_snapshot', 
        frame: true, 
        buttonAlign:'left' , 
         autoHeight:true,
        defaults:{autoScroll: true},
        items: [snapshot_grid] 
    });
  

    
    
    var share_limit_panel = new Ext.Panel({
                id:'share_limit_panel',  
                layout:'table',
                hidden:<{$share_limit_hidden}>, 
                layoutConfig: {columns:4}, 
                defaults: {frame:false },// applied to child components
                items:[{
                      xtype:'label',
                      id:'quota_limit_label',
                      text:'<{$aswords.quota_limit}>:',
                      width:148 
                  
                  },{
                      xtype: 'textfield', 
                      width:60,
                      style:'margin-top:1px',
                      value:'0',
                      name:'_quota_limit',
                      id:'_quota_limit'
                        
                },{ 
                    xtype:'box',
                    style:'padding-left:10px',
                    autoEl:{cn:'GB'}
                },{ 
                    xtype:'box',
                    style:'padding-left:10px',
                    autoEl:{cn:'(<{$aswords.quotalimit_add}>)'}
                }]
            }); 
    
 
    var share_usage_panel = new Ext.Panel({  
                id:'share_usage_panel',   
                layout:'table', 
                layoutConfig: {columns:2},  
                defaults: {frame:false }, 
                style:'padding-top:6px', 
                items:[{ 
                      xtype:'label',  
                      id:'quota_usage_label', 
                      text:'<{$mswords.quota_Usage}>:', 
                      width:148  
                },{  
                    xtype:'label', 
                     id:'quota_usage_txt', 
                     text:''  
                },{  
                    xtype:'hidden', 
                     id:'quota_usage_value', 
                     text:''  
                }] 
            })

    //if in firefox
    if(Ext.isGecko){ 
          Ext.getCmp('quota_limit_label').style='margin-right:52px'; 
          Ext.getCmp('quota_usage_label').style='margin-right:52px'; 
    }
    var formpanel_share = new Ext.FormPanel({
        frame: true, 
        labelAlign:'left',
        height:180,
        buttonAlign:'left',
        labelWidth:140,
        bodyStyle:'padding:8px 8px 0px 8px;',
        buttons:[{ text: '<{$gwords.apply}>', handler:confirm_add_share  }] ,
        items: [
            <{if $open_mraid=='0' }>{
                      xtype: 'hidden', 
                      name: 'md_num' ,
                      id: 'md_num' ,
                      <{if $NAS_DB_KEY=="1"}>
                      value:'1'
            <{else}>
                      value:'0'
                      <{/if}>
                    } 
                    <{else}>
                      raidnum_combo
                    <{/if}>,{
                      xtype: 'textfield',
                      fieldLabel: "<{$gwords.folder_name}>", 
                      name: '_share',
                      id:'_share',
                      width:300
                    },{
                      xtype: 'radiogroup',
                      fieldLabel: "<{$aswords.public}>", 
                      name:'radio_guest_only',
                      id:'radio_guest_only', 
                      width:150,
                      items: [
                          {boxLabel: 'Yes', name: '_guest_only',inputValue:'yes'},
                          {boxLabel: 'No', name: '_guest_only',inputValue:'no',checked:true} 
                      ],
                      listeners:{
                          change:function(obj){
                              var node = tree.getSelectionModel().getSelectedNode();
                              if(node){
                              if(obj.getValue()=='yes' && node.attributes.share=='nsync'){
                                 Ext.Msg.alert("<{$gwords.info}>","<{$mswords.nsync_warning}>"); 
                              } 
                              }
                          }
                      }
                    }
                    ,share_limit_panel
                    ,share_usage_panel
                    ,{
                      xtype: 'hidden', 
                      name:'action_share', 
                      id:'action_share', 
                      value:'add'
                    },{
                      xtype: 'hidden', 
                      name:'path', 
                      id:'path',  
                      value:'/'
                    },{
                      xtype: 'hidden', 
                      name:'sysfolder', 
                      id:'sysfolder' 
                    },{
                      xtype: 'hidden', 
                      name:'o_share', 
                      id:'o_share' 
                    },{ 
                      xtype: 'hidden', 
                      name:'o_quota_limit', 
                      id:'o_quota_limit' 
                    },{ 
                      xtype: 'hidden', 
                      name:'o_guest_only', 
                      id:'o_guest_only'
                    },{ 
                      xtype: 'hidden', 
                      name:'o_browseable', 
                      id:'o_browseable'
                    },{ 
                      xtype: 'hidden', 
                      name:'o_comment', 
                      id:'o_comment'
                    },{ 
                      xtype: 'hidden', 
                      name:'o_md_num', 
                      id:'o_md_num'
                    }]
           // }]
    });
    
    
    
    
    var formpanel_nfslist = new Ext.FormPanel({ 
        bodyStyle:'padding:0px 0px 0px 0px;', 
        title:'<{$gwords.nfs}>',
        id:'formpanel_nfslist',
        frame: true, 
        labelAlign:'left',
        items: [
            {
                xtype:'label', 
                id:'nfslist_title'
            },
            nfs_grid
        ],
        listeners:{
             'activate':function(tab){
                    Ext.getCmp('formpanel_nfs').setTitle('<{$gwords.add}>'); 
              }
        }
        
        
    });
      var formpanel_nfs = new Ext.FormPanel({ 
        bodyStyle:'padding:0px 0px 0px 0px;', 
        title:'<{$gwords.add}>',
        id:'formpanel_nfs',
        frame: true,
        layout:'form',
        height:400,
        labelAlign:'left',
        defaults: {
            labelStyle: 'width:150'
        },
        items: [
                    {
                      xtype: 'textfield',
                      fieldLabel: "<{$gwords.hostname}>",
                      name: '_hostname',  
                      id:'_hostname',
                      labelStyle: 'width:170',
                      width:120
                    },{
                      xtype:'label',
                      html:"<span style='color:red;'><{$words.nfs_host_des}></span>" 
                    },{
                      xtype: 'radiogroup',
                      fieldLabel: "<{$gwords.privilege}>",
                      columns: 1,
                      id:'radio_privilege',
                      items: [
                          {boxLabel: "<{$gwords.readonly}>", name: '_privilege',inputValue:'ro',width:150},
                          {boxLabel: "<{$gwords.writable}>", name: '_privilege',inputValue:'rw' ,checked: true,width:150} 
                      ]
                    },{
                      xtype: 'radiogroup',
                      fieldLabel: "<{$words.nfs_os_support}>",
                      columns: 1,
                      id:'radio_os_support',
                      items: [
			<{if $NAS_DB_KEY=="1"}>
                          {boxLabel: "<{$words.nfs_linux}> ", name: '_os_support',inputValue:'0', checked: true,width:600}
                          ,{boxLabel: "<{$words.nfs_aix}> ", name: '_os_support',inputValue:'1',width:600}

			<{else}>
                          {boxLabel: "<{$words.nfs_linux}> ", name: '_os_support',inputValue:'secure', checked: true,width:600}
                          ,{boxLabel: "<{$words.nfs_aix}> ", name: '_os_support',inputValue:'insecure',width:600}
			<{/if}>
                      ]
                    },{
                      xtype: 'radiogroup',
                      fieldLabel: "<{$words.nfs_id_mapping}>",
                      columns: 1,  
                      id:'radio_rootaccess',
                      items: [
                          //{boxLabel: "<{$words.nfs_norootsquash}>", name: '_rootaccess',inputValue:'no_root_squash', checked: true,width:600},
                          //{boxLabel: "<{$words.nfs_rootsquash}>", name: '_rootaccess',inputValue:'root_squash',width:600}
                          // These code is not fit with IE 
                          {xtype: 'panel', items:[{boxLabel: "root:root", name: '_rootaccess',inputValue:'no_root_squash',width:600},
                          {xtype: 'label' , text: "<{$words.nfs_norootsquash}>", width: 600}]},
                          
                          {xtype: 'panel', items:[{boxLabel: "nobody:nogroup", name: '_rootaccess',inputValue:'root_squash',width:600},
                          {xtype: 'label' , text: "<{$words.nfs_rootsquash}>", width: 600}]}
                          
                          <{if $NAS_DB_KEY=="1"}>
                          ,{boxLabel: "<{$words.nfs_allsquash}>", name: '_rootaccess',inputValue:'all_squash',width:600}
                          <{/if}>
                      ]
                    },{
                      xtype: 'radiogroup',
                      fieldLabel: "<{$words.nfs_sync}> / <{$words.nfs_async}>",
                      columns: 1,
                      id:'radio_sync_support',
                      items: [
                          {boxLabel: "<{$words.nfs_sync}> ", name: '_sync_support',inputValue:'sync', width:600}
                          ,{boxLabel: "<{$words.nfs_async}> ", name: '_sync_support',inputValue:'async', checked: true, width:600} 
                      ]
                    },{
                      xtype: 'hidden', 
                      name: 'nfs_sharename',  
                      id: 'nfs_sharename' 
                    },{
                      xtype: 'hidden', 
                      name: 'nfs_md_num',  
                      id: 'nfs_md_num' 
                    },{
                      xtype: 'hidden', 
                      name: 'nfs_action_share',  
                      id: 'nfs_action_share'
                    },{ 
                       buttonAlign:'left', 
                       buttons:[{text: '<{$gwords.apply}>', handler:confirm_add_nfs}] 
                    }
            ], 
            listeners:{
                 'activate':function(tab){ 
                        if(tab.title=='<{$gwords.add}>'){
                            var node = tree.getSelectionModel().getSelectedNode();    
                            Ext.getCmp('nfs_sharename').setValue(node.attributes.share); 
                            Ext.getCmp('nfs_md_num').setValue(node.attributes.md_num); 
         
                            Ext.getCmp('nfs_action_share').setValue('nfs_add'); 
                            Ext.getCmp('_hostname').setValue('xxx.xxx.xxx.xxx'); 
                            Ext.getCmp('_hostname').setDisabled(false); 
                            Ext.getCmp('radio_privilege').setValue('rw');
      <{if $NAS_DB_KEY=="1"}>
                            Ext.getCmp('radio_os_support').setValue('0');
      <{else}>
                            Ext.getCmp('radio_os_support').setValue('secure');
      <{/if}>
                            Ext.getCmp('radio_rootaccess').setValue('no_root_squash');  
                            Ext.getCmp('radio_sync_support').setValue('async');
                        }
                  }
            }
    });
    
    
       

  //Tab panel
  var tabpanel = new Ext.TabPanel({
    autoTabs       : true,
    activeTab      : 0,
    deferredRender : false,
    border         : true,
    bodyStyle:'padding:0px 0px 0px 0px;',  
    items: [formpanel_snapshot,formpanel_schedule]
  });
    
    
  //Tab panel
  var tabpanel_nfs = new Ext.TabPanel({
    autoTabs       : true,
    activeTab      : 0,
    deferredRender : false,
    border         : true,
    bodyStyle:'padding:0px 0px 0px 0px;',  
    height: 435,
    items: [formpanel_nfslist,formpanel_nfs],
    listeners:{
        beforeshow: function(){
            window_ext.setWidth(830);
        },
        hide: function(){
            window_ext.setWidth(510);
        }
    }
  });
    
     
    var readonlypanel = new Ext.Panel({
        id:'readonlypanel',
        items:[{
                xtype:'checkboxgroup',     
                id:'readonlychk',   
                items:[
                    {boxLabel:"<{$words.readonly}>", name:'_smbreadonly', id:'_smbreadonly',  inputValue:'1'}
                ] 
            }
        ]
    
    }); 

    //samba panel
    var tabpanel_smb = new Ext.FormPanel({
        frame: true,    
        bodyStyle:'padding:8px 8px 0px 8px;',
        buttonAlign:'left',
        labelWidth:140,
        height:180,
        items: [{
                layout:'column',
                items:[
                    {
                        width:150,
                        height:22,
                        html: "<{$gwords.folder_name}>:"
                    },{
                        xtype:'label',
                        id:'smb_share',
                        html:''
                    }
                    
                ]
            },{
                layout:'form',
                items:[{
                        xtype:'textfield',
                        name:'_comment',
                        id:'_comment',
                        fieldLabel: "<{$gwords.description}>",
                        width:300
                    },{
                        xtype:'radiogroup',
                        fieldLabel: "<{$aswords.browseable}>",
                        width:150,
                        id:'browseable_radio',
                        items:[
                            {boxLabel:"<{$gwords.yes}>", name:'_browseable', inputValue:'yes'},
                            {boxLabel:"<{$gwords.no}>", name:'_browseable', inputValue:'no'}
                        ]
                    },readonlypanel
                ]
            }
        ],
        buttons:[
            {
                text:"<{$gwords.apply}>",
                handler: function(){ 

                    Ext.Msg.confirm("<{$words.smb_name}>", "<{$gwords.confirm}>" , function(btn){ 
                        if(btn=='yes'){ 
                            var node = tree.getSelectionModel().getSelectedNode();
                            var param = tabpanel_smb.getForm().getValues(true)+"&readonly_visible="+Ext.getCmp('readonlypanel').isVisible()+"&share="+node.attributes.share+"&md="+node.attributes.md_num+"&o_browseable="+node.attributes.browseable+"&action_smb=1";
                            processAjax('<{$set_url}>', onLoad_smb_apply, param);  
                        }
                    });
                }
            }
        ]
	});

//**********************Window********************************
    var window_ext = new Ext.Window({
      closable:true,
      closeAction:'hide',
      width: 510,
      autoHeight: true,
      draggable:false,
      plain: true,
      modal: true,
      layout: 'card',
      activeItem: 0,
      shadow: false,
      items: [tabpanel_nfs,formpanel_share,tabpanel,tabpanel_smb]
    });

    
//**********************TreeLoader******************************** 
        var tree_loader = new Ext.tree.TreeLoader({
            dataUrl:'<{$get_url}>&tree=rootfolder',
            uiProviders:{
                'col': Ext.tree.ColumnNodeUI 
            },
            listeners: {
              beforeload: function(treeLoader, node) {
                node.getOwnerTree().getEl().mask('<{$gwords.wait_msg}>....');
              },
              load: function(treeLoader, node) {
                node.getOwnerTree().getEl().unmask();
                
              }
            } 
   });

 function ColumnTreeExpand(expand){ 
      setCurrentPage('share');
      processUpdater('getmain.php','fun=share&expand='+expand); 
 }
//**********************ColumnTree********************************
   var tree = TCode.desktop.Group.addComponent({
        xtype: 'Ext.tree.ColumnTree',
        tbar:tb,
        rootVisible:false,
        useArrows:true,
        animate:true,
        autoScroll: true,
        columns:[
        <{if $expand=='1'}>
        {
            header:'<{$gwords.folder_name}> <img src="/theme/images/default/layout/collapse.gif" align="absmiddle" border=0 style="cursor:pointer" onclick="ColumnTreeExpand(0)" />',
            width:820, 
            dataIndex:'share_title'
        }
        <{else}>
         {
            header:'<{$gwords.folder_name}> <img src="/theme/images/default/layout/expand.gif" align="absmiddle" border=0 style="cursor:pointer" onclick="ColumnTreeExpand(1)" />',
            width:400, 
            dataIndex:'share_title'
<{if $NAS_DB_KEY=="1"}>            
        },{
            header:'<{$words.quotalimit}>',
            width:70,
            dataIndex:'quota_limit_gb'
<{/if}>
        },{
            header:'<{$gwords.raid_id}>',
            width:70,
            dataIndex:'raidid'
        },{
            header:'<{$rwords.filesystem}>',
            width:70,
            dataIndex:'file_system'
        },{
            header:'<{$aswords.public}>',
            width:60,
            dataIndex:'guest_only'
        },{
            header:'<{$gwords.description}>',
            width:220,
            dataIndex:'desc'
        } 
        <{/if}>], 
        loader: tree_loader,
        root: new Ext.tree.AsyncTreeNode({   
            id:'0' ,
            text:'root'
        }),
        listeners: {
            render: function(){
                //to render window_ext at very beginning
                window_ext.setPagePosition(-1000000, -1000000);
                window_ext.show();
                window_ext.hide();
            }
        }
    });
  
new Ext.tree.TreeSorter(tree, {
   folderSort: true,
   sortType: function(node) {
      return node['attributes']['share'];
   }
});

tree.on("beforeload", function(v) {
      if(v.text=='root'){
          tree_loader.dataUrl='<{$get_url}>&tree=root';
      }else{   
          tree_loader.dataUrl='<{$get_url}>&tree=subfolder&path='+encodeURIComponent(v.attributes.path)+'&zfs='+v.attributes.zfs_disable+'&guest_only='+v.attributes.guest_only+'&speclevel='+v.attributes.speclevel;
      }
}); 
tree.on("click", function(v) {
      var rootfolder = v.attributes.rootfolder;   
      if (rootfolder=='1'){//main folder
	   if("<{$smbservice}>"=="0"){
	       Ext.getCmp('smb').setDisabled(true);
	   }else{
	       Ext.getCmp('smb').setDisabled(false);
	   }
           Ext.getCmp('add').setDisabled(false);
           Ext.getCmp('edit').setDisabled(false);
           if(v.attributes.share_delete=='0'){
                Ext.getCmp('remove').setDisabled(true); 
           }else{
                Ext.getCmp('remove').setDisabled(false);
           } 
           
           if(v.attributes.nfs_disable=='0'){
                Ext.getCmp('nfs').setDisabled(true); 
           }else{
                Ext.getCmp('nfs').setDisabled(false); 
           }
           
           if(v.attributes.snapshot_disable=='0'){
                if(Ext.getCmp('snapshot'))
                   Ext.getCmp('snapshot').setDisabled(true); 
           }else{
                if(Ext.getCmp('snapshot'))
                  Ext.getCmp('snapshot').setDisabled(false);
           } 
           
           
           if(v.attributes.guest_only=='yes'){
                Ext.getCmp('acl').setDisabled(true); 
           }else{
                Ext.getCmp('acl').setDisabled(false); 
           }
           
           if(v.attributes.speclevel=='1'){
             Ext.getCmp('acl').setDisabled(true);
             Ext.getCmp('edit').setDisabled(true);
             Ext.getCmp('remove').setDisabled(true);
             Ext.getCmp('nfs').setDisabled(true);
           }
      }else{ //subfolder
           Ext.getCmp('add').setDisabled(true);
           Ext.getCmp('edit').setDisabled(true);
           Ext.getCmp('remove').setDisabled(true);
           Ext.getCmp('nfs').setDisabled(true);
           Ext.getCmp('smb').setDisabled(true);
           if(Ext.getCmp('snapshot'))
               Ext.getCmp('snapshot').setDisabled(true); 
           
           if( (v.attributes.len>4 && v.attributes.usb=='1') ||v.attributes.zfs=='1' || v.attributes.guest_only=='yes'){
                Ext.getCmp('acl').setDisabled(true); 
           }else{
                if(v.attributes.speclevel=='1'){
	                Ext.getCmp('acl').setDisabled(true);
                }else{
	                Ext.getCmp('acl').setDisabled(false);  
                }
           } 
            
      }  
});

tree.on("beforedestroy", function(v) {
    window_ext.destroy();
    window_acl.destroy();
});  

nfs_store.on('load',function(obj,records){
                var node = tree.getSelectionModel().getSelectedNode();
                nfs_mount_point = records[(records.length-1)].data["nfs_mount_point"];
                Ext.getCmp('nfslist_title').getEl().update(nfs_mount_point);
                //Ext.getCmp('nfs_title').setTitle(nfs_mount_point); 
                mainMask.hide();
                window_ext.setTitle('<{$words.nfs_title}>');
                window_ext.center();
                if(!window_ext.isVisible()) { window_ext.show();}
                });    
nfs_store.on('beforeload',function(v){mainMask.show();});       


 
      
new Ext.form.Checkbox({
    applyTo: "chk2",
    id:'chk2',
    name:'_enable_autodel',
    inputValue :'1',
    boxLabel:"<{$swords.snap_autodel}>",
    disabled:true
});
 /**************************************************************
                          snapshot schedule ComboBox 
    **************************************************************/
    var date_store = new Ext.data.SimpleStore({
        fields: <{$combo_fields}>,
        data: <{$combo_date}>
    });
    var time_store = new Ext.data.SimpleStore({
        fields: <{$combo_fields}>,
        data: <{$combo_time}>
    });
    var week_store = new Ext.data.SimpleStore({
        fields: <{$combo_fields}>,
        data: <{$combo_week}>
    });
    
     var rule_store = new Ext.data.SimpleStore({
        fields: <{$combo_fields}>,
        data: [['m','<{$gwords.monthly}>'],
                    ['w','<{$gwords.weekly}>'],
                    ['d','<{$swords.snap_schedule_way_daliy}>']]
    });
      
    var date_combo = new Ext.form.ComboBox({
                xtype: 'combo',
                name: '_month_day', 
                id: 'date_combo', 
                mode: 'local',
                store: date_store,
                displayField: 'display',
                valueField: 'value',
                readOnly: true, 
                selectOnFocus:true,
                triggerAction: 'all', 
                renderTo:'combo_date' ,
                disabled:true

    });
    date_combo.setValue('1'); 
    
    var week_combo = new Ext.form.ComboBox({
                xtype: 'combo',
                name: '_week_day', 
                id: 'week_combo', 
                mode: 'local',
                store: week_store,
                width:80,
                displayField: 'display',
                valueField: 'value',
                readOnly: true, 
                selectOnFocus:true,
                triggerAction: 'all',
                renderTo:'combo_week' ,
                disabled:true

    });
    week_combo.setValue('<{$combo_week_select}>');
    var time1_combo = new Ext.form.ComboBox({
                xtype: 'combo',
                name: '_month_hours', 
                id: 'time1_combo', 
                mode: 'local',
                store: time_store,
                width:40,
                displayField: 'display',
                valueField: 'value',
                readOnly: true, 
                selectOnFocus:true,
                triggerAction: 'all',
                renderTo:'combo_time1' ,
                disabled:true

    }); 
    time1_combo.setValue('0');
    var time2_combo = new Ext.form.ComboBox({
                xtype: 'combo',
                name: '_week_hours', 
                id: 'time2_combo', 
                mode: 'local',
                store: time_store,
                width:40,
                displayField: 'display',
                valueField: 'value',
                readOnly: true, 
                selectOnFocus:true,
                triggerAction: 'all',
                renderTo:'combo_time2' ,
                disabled:true

    });
    time2_combo.setValue('0');
    var time3_combo = new Ext.form.ComboBox({
                xtype: 'combo',
                name: '_day_hours', 
                id: 'time3_combo', 
                mode: 'local',
                store: time_store,
                width:40,
                displayField: 'display',
                valueField: 'value',
                readOnly: true, 
                selectOnFocus:true,
                triggerAction: 'all',
                renderTo:'combo_time3' ,
                disabled:true

    });
    time3_combo.setValue('0');
    
       
  
  var combo_rule = new Ext.form.ComboBox({
                xtype: 'combo',  
                id: 'combo_rule', 
                mode: 'local', 
                store:rule_store, 
                displayField: 'display',
                valueField: 'value',
                readOnly: true, 
                selectOnFocus:true,
                triggerAction: 'all',
                renderTo:'combo_rule_div' ,
                disabled:true,
      listeners: { select :function(v){ 
          var rdovalue = v.value;   
          Ext.getDom('div_monthly').style.display='none';
          Ext.getDom('div_weekly').style.display='none';
          Ext.getDom('div_daliy').style.display='none'; 
          if(rdovalue=='m'){
               Ext.getDom('div_monthly').style.display='block';
               Ext.getCmp('date_combo').setDisabled(false); 
               Ext.getCmp('time1_combo').setDisabled(false);   
               Ext.getCmp('week_combo').setDisabled(true); 
               Ext.getCmp('time2_combo').setDisabled(true);   
               Ext.getCmp('time3_combo').setDisabled(true);   
          }else if(rdovalue=='w'){
               Ext.getDom('div_weekly').style.display='block';
               Ext.getCmp('date_combo').setDisabled(true); 
               Ext.getCmp('time1_combo').setDisabled(true);   
               Ext.getCmp('week_combo').setDisabled(false); 
               Ext.getCmp('time2_combo').setDisabled(false);   
               Ext.getCmp('time3_combo').setDisabled(true);    
          }else if(rdovalue=='d'){
               Ext.getDom('div_daliy').style.display='block';
               Ext.getCmp('date_combo').setDisabled(true); 
               Ext.getCmp('time1_combo').setDisabled(true);   
               Ext.getCmp('week_combo').setDisabled(true); 
               Ext.getCmp('time2_combo').setDisabled(true);   
               Ext.getCmp('time3_combo').setDisabled(false);  
            
          }
        }
      } 

    }); 
    
new Ext.form.Checkbox({
    applyTo: "chk1",
    id:'chk1',
    name:'_enable_schedule',
    inputValue :'1',
    boxLabel:"<{$swords.snap_enable_schedule}>",
    listeners :{
        check : function(checkbox, checked){  
               Ext.getCmp('date_combo').setDisabled(!checked);  
               Ext.getCmp('week_combo').setDisabled(!checked);  
               Ext.getCmp('time1_combo').setDisabled(!checked);  
               Ext.getCmp('time2_combo').setDisabled(!checked);  
               Ext.getCmp('time3_combo').setDisabled(!checked);  
               Ext.getCmp('combo_rule').setDisabled(!checked);   
                
               Ext.getCmp('chk2').setDisabled(!checked);  
        }
    }
});



new Ext.Button({ 
  type:'button',
  applyTo:'schedule_btn',
  text:'<{$gwords.apply}>',
  minWidth :80,
  handler:schedule_apply 
}); 



if("<{$smbservice}>"=="0"){
    Ext.getCmp('smb').setDisabled(true);
}






 /*********************************************************************
            ACL 
 **********************************************************************/
<{include file='adm/acl.tpl'}>

</script>

<div id="tree-div" ></div>


<div id="schedule_table"   style="display:none">
<table   border="0" cellspacing="2" cellpadding="2">
  <tr>
    <td colspan="2"><div id="chk1"></div></td>
  </tr>
  <tr>
    <td colspan="2"><div id="chk2"></div></td>
  </tr>
  <tr>
    <td  nowrap="nowrap"><{$swords.snap_schedule_rule}>:</td>
    <td nowrap="nowrap"  >
      <table width="100%" border="0">
        <tr>
          <td>&nbsp;<div id="combo_rule_div"></div></td>
          <td>&nbsp;
      
  <div id="div_monthly" style="display:none">
      <table>
        <tr>
          <td><div id="combo_date"></div></td>
          <td><{$swords.snap_schedule_way_day}></td>
          <td><div id="combo_time1"></div></td>
          <td><{$gwords.hour}></td>
        </tr>
      </table></div>
    
    
  <div id="div_weekly" style="display:none">
      <table>
        <tr>
          <td><div id="combo_week"></div></td>
          <td><div id="combo_time2"></div></td>
          <td><{$gwords.hour}></td>
        </tr>
      </table></div>
    
    <div id="div_daliy" style="display:none">
    <table>
      <tr>
      <td><div id="combo_time3"></div></td>
      <td><{$gwords.hour}></td>
      </tr>
      </table></div>  
    
    </td>
        </tr>
      </table>
     </td>
  </tr> 
  <tr>
    <td style="height:50px"><div id="schedule_btn"></div></td>
    <td></td>
  </tr> 
</table>
</div>  

