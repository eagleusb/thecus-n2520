<script type="text/javascript">
var stackable_ct = {};
stackable_ct['actionId'] = Ext.id();
stackable_ct['stackable_buttonId'] = Ext.id();
function onComponentReady(ct) {
    if (ct.cname) {
        stackable_ct[ct.cname] = ct;
    }
}

Ext.QuickTips.init();
//********************* dynamic load css , for IE css problem*******************
var headID = document.getElementsByTagName("head")[0];
var newCss = document.createElement('link');
newCss.type = 'text/css';
newCss.rel = "stylesheet";
newCss.href = "<{$urlcss}>share.css";
headID.appendChild(newCss); 


// change formpanel style
function change_flow(element){
  formpanel_stackable.hide();
  element.show();
}

// setting window width/height/title
function setWindow_attribute(w,h,title,tmode){
    window_ext.setSize(w,h);  
    window_ext.setTitle(title);  
    if(!tmode){
        if(!window_ext.isVisible())
            window_ext.show();
    }
}


 
function confirm_add_stackable(){
     iqn_combo.setDisabled(false);
     processAjax('<{$set_url}>', onLoadForm, formpanel_stackable.getForm().getValues(true)); 
     iqn_combo.setDisabled(true);
}
  

// click sharefolder toolbar [add/edit/remove/acl/nfs] then popup Window  
function toolbar_share(clickid){
   var win_height=380;
   var node = tree.getSelectionModel().getSelectedNode();    
   if(node!=null || clickid.cname=='add'){
         Ext.getCmp(stackable_ct.actionId).setValue(clickid.cname);
         switch(clickid.cname){
            case 'add':  
                change_flow(formpanel_stackable);
                iqn_store.loadData(['','']);
                window_ext.disable();
                setWindow_attribute(580,win_height,'<{$words.add_title}>',false);
                iqn_combo.setValue(false);
                iqn_combo.setDisabled(true);
                
                stackable_ct._target_ip.setDisabled(false);
                stackable_ct._username.setDisabled(true);
                stackable_ct._password.setDisabled(true);
                stackable_ct._share.setDisabled(true);
                //Ext.getCmp('share_limit').setDisabled(true);
                stackable_ct._comment.setDisabled(true);
                stackable_ct.radio_browseable.setDisabled(true);
                stackable_ct.radio_public.setDisabled(true);
                Ext.getCmp(stackable_ct.stackable_buttonId).setDisabled(true);
                stackable_ct._username.setValue('');
                stackable_ct._password.setValue('');
                stackable_ct._share.setValue('');
                stackable_ct._o_share.setValue('');
                stackable_ct._comment.setValue('');
                stackable_ct._target_ip.setValue('');
                stackable_ct.radio_enable.setValue('1');
                stackable_ct.radio_browseable.setValue('yes');
                stackable_ct.radio_public.setValue('no');
                stackable_ct.iqn_discovery_btn.setDisabled(false);
                window_ext.enable();
                break;
            case 'edit':
                change_flow(formpanel_stackable);
                processAjax('<{$get_url}>',onLoad_edit,'store=edit&share='+node.attributes.share); 
                setWindow_attribute(580,win_height,'<{$words.edit_title}>',false);
                break;
            case 'remove':
                Ext.Msg.confirm('<{$words.stackable_title}>', "<{$gwords.confirm}>", function(btn){ 
                        if(btn=='yes'){  
                            processAjax('<{$set_url}>', onLoadForm, 
                                      '&action=remove'+
                                      '&_share='+node.attributes.share);
                        }
                 });
                break;
            case 'format':
                  processAjax('<{$set_url}>', onLoadForm, 
                                      '&action=format'+
                                      '&_share='+node.attributes.share);
                  break;
            case 'reconnect':
                  processAjax('<{$set_url}>', onLoadForm, 
                                      '&action=reconnect'+
                                      '&_share='+node.attributes.share);
                  break;
            case 'acl': 
                acl_popup(node);   
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
            mainMask.show();
            tree_loader.load(tree.getRootNode()); 
        }
        if(aftersuccess=='hide'){
            if(window_ext.isVisible())
                window_ext.hide();
        }
        
        if(aftersuccess=='hidereloadclose'){
            mainMask.show();
            tree_loader.load(tree.getRootNode()); 
            if(window_ext.isVisible())
                window_ext.hide();
        }
   }
}
function iqn_discovery(){ 
      processAjax('<{$get_url}>', onLoad_discovery, '&store=iqn_discovery&_target_ip='+stackable_ct._target_ip.getValue()+'&_target_port='+stackable_ct._target_port.value);
}
//*********************** onLoad  **************************
function onLoad_edit(){
  var request = eval('('+this.req.responseText+')');    
  if(request.success){
        var iqn_data = eval(request.iqn_combo);
        iqn_store.loadData(iqn_data); 
        iqn_combo.setValue(request.data.iqn);
        iqn_combo.setDisabled(true);
        stackable_ct.iqn_discovery_btn.setDisabled(true);
        stackable_ct._target_ip.setDisabled(true);
        stackable_ct._username.setDisabled(false);
        stackable_ct._password.setDisabled(false);
        stackable_ct._share.setDisabled(false);
        //Ext.getCmp('share_limit').setDisabled(false);
        stackable_ct._comment.setDisabled(false);
        stackable_ct.radio_browseable.setDisabled(false);
        stackable_ct.radio_public.setDisabled(false);
        Ext.getCmp(stackable_ct.stackable_buttonId).setDisabled(false);
        stackable_ct._username.setValue(request.data.username);
        stackable_ct._password.setValue(request.data.password);
        stackable_ct._share.setValue(request.data.share_name);
        stackable_ct._o_share.setValue(request.data.o_share_name);
        stackable_ct._comment.setValue(request.data.comment);
        stackable_ct._target_ip.setValue(request.data.target_ip);
        stackable_ct.radio_enable.setValue(request.data.enabled);
        stackable_ct.radio_browseable.setValue(request.data.browseable);
        stackable_ct.radio_public.setValue(request.data.guest_only);
  }
}
function onLoad_stackable(){ 
   if(window_ext.isVisible())
        window_ext.hide();
   tree_loader.dataUrl='<{$get_url}>&tree=1';
   tree_loader.load(tree.getRootNode()); 
}

function onLoad_sync_apply(){  
  var request = eval('('+this.req.responseText+')'); 
  showmsg(request,'') 
}; 
function onLoad_discovery(){
  var request = eval('('+this.req.responseText+')'); 
  if(!request.success){
      showmsg(request.msg,'');
  }else{ 
      var iqndata = eval(request.iqn_combo);
      iqn_store.loadData(iqndata); 
      
      stackable_ct.iqn_discovery_btn.setDisabled(true);
      iqn_combo.setValue(iqndata[0]['value']);
      iqn_combo.setDisabled(false);
      stackable_ct._username.setDisabled(false);
      stackable_ct._password.setDisabled(false);
      stackable_ct._share.setDisabled(false);
      stackable_ct._comment.setDisabled(false);
      stackable_ct.radio_browseable.setDisabled(false);
      stackable_ct.radio_public.setDisabled(false);
      //Ext.getCmp('share_limit').setDisabled(false);
      Ext.getCmp(stackable_ct.stackable_buttonId).setDisabled(false);
  }  
}

 //***************************** ComboBox*************************
   

    var iqn_store = new Ext.data.JsonStore({
      	fields: <{$combo_fields}>,
      	data: <{$iqn_combo}>
    });
    
    var iqn_combo = new Ext.form.ComboBox({
        width:360,
        fieldLabel: "<{$words.iqn}>",
        name: '_iqn',
        mode: 'local', 
        store: iqn_store,
        displayField: 'display',
        hiddenName: '_iqn_select',
        valueField: 'value',
        readOnly: true  ,
        selectOnFocus:true,
        disabled:true,
        triggerAction: 'all'
    });
    
//**********************Toolbar******************************** 
var tb = [{
    text: '<{$gwords.add}>',
    iconCls: 'add',
    cname:'add',
    handler: toolbar_share,
    disabled:false
},'-',{
    text: '<{$gwords.edit}>',
    iconCls: 'edit',
    cname:'edit',
    handler: toolbar_share,
    disabled:true
},'-',{
    text: '<{$gwords.remove}>',
    iconCls: 'remove',
    cname:'remove',
    handler: toolbar_share,
    disabled:true
},'-',{
    text: '<{$gwords.format}>',
    iconCls: 'option',
    cname:'format',
    handler: toolbar_share,
    disabled:true
},'-',{
    text: '<{$gwords.reconnect}>',
    iconCls: 'connect',
    cname:'reconnect',
    handler: toolbar_share,
    disabled:true
},'-',{
    text: '<{$gwords.acl}>',
    iconCls: 'wrench',
    cname:'acl',
    handler: toolbar_share,
    disabled:true
}];

(function (){
    for (var i = 0; i < tb.length; i ++) {
        tb[i]['listeners'] = {
            render: onComponentReady
        };
    }
})();

/*
//**********************JsonStore********************************
var nfs_store = new Ext.data.JsonStore({
id:'nfs_store', 
		fields: ['hostname','privilege','os','map','os_value','map_value'] 
});  

//**********************Columns********************************
var nfs_cols =[
                {header: "<{$gwords.hostname}>", width: 170, sortable: true, dataIndex: 'hostname'},
    		{header: '<{$gwords.privilege}>', width: 170, sortable: true, dataIndex: 'privilege'},
    		{header: '<{$words.nfs_os_support}>', width: 170, sortable: true, dataIndex: 'os_value'},
    		{header: '<{$words.nfs_id_mapping}>', width: 170, sortable: true,dataIndex: 'map_value'}
    	  ]; 
 //**********************GridPanel********************************
    
    

*/
    
 //**********************FormPanel******************************** 
    
  


    var items_targetip = new Ext.Panel({
        layout:'column',
        defaults:{
                layout:'form',
                xtype:'panel',
                labelWidth: 150,
                defaults: { // for items in items
                    listeners: {
                        render: onComponentReady
                    }
                }
        },
        items:[{
                columnWidth:.55,
                items:[{
                        xtype: 'textfield',
                        fieldLabel:"<{$words.target_ip}>", 
                        width:135,
                        cname:'_target_ip',
                        name:'_target_ip' 
                }]
        }/*,{ 
                columnWidth:.07,
                items:[{
                        xtype:'box',
                        autoEl:{cn:'&nbsp;:<{$target_port}>&nbsp;&nbsp;&nbsp;'}
                }]
        }*/,{
                columnWidth:.2,
                items:[{
                        xtype: 'button', 
                        hideLabel:true ,
                        cname:'iqn_discovery_btn',
                        text:'<{$gwords.discovery}>',
                        handler:iqn_discovery
                }]
        }
]
    });

    //show the iqn of initiator
    var mount_lun_limit = new Ext.form.Label({
      html : "<span style='color:red'><{$words.mount_lun_limit}></span>"
    });

    var formpanel_stackable = new Ext.FormPanel({ 
        frame: true,  
        autoHeight:true,
        buttonAlign:'left',
        buttons:[{ text: '<{$gwords.apply}>',disabled:true,id: stackable_ct.stackable_buttonId, handler:confirm_add_stackable }],
        defaults: {
            labelStyle: 'width:155px',
            listeners: {
                render: onComponentReady
            }
        },
        items: [{
                      xtype: 'radiogroup',
                      fieldLabel: "<{$words.enable_title}>",
                      cname:'radio_enable',
                      name:'radio_enable',
                      columns: 2,
                      items: [
                          {boxLabel: '<{$gwords.enable}>', name: '_enable',inputValue:'1',checked:true},
                          {boxLabel: '<{$gwords.disable}>', name: '_enable',inputValue:'0'}
                      ]
                    },
                    items_targetip,
                    {
                        xtype: 'panel',
                        height: 30,
                        layout: 'table',
                        layoutConfig: {
                            columns:2
                        },
                        items: [
                            {
                                html: "<{$words.iqn}>",
                                width: 155
                            },
                            iqn_combo
                        ]
                    },
                    {
                      xtype: 'textfield',
                      fieldLabel: "<{$gwords.username}>",
                      cname:'_username',
                      name:'_username',
                      disabled:true
                    },{
                      xtype: 'textfield',
                      fieldLabel: "<{$gwords.password}>",
                      inputType:'password',
                      cname:'_password',
                      name:'_password',
                      disabled:true
                      
                    },{
                        xtype: 'textfield',
                        fieldLabel:"<{$words.share_name}>",
                        cname:'_share',
                        name:'_share',
                        disabled:true,
                        vtype: 'StackName',
                        width:200
                    },{
                      xtype: 'textfield',
                      fieldLabel: "<{$gwords.description}>",
                      cname:'_comment',
                      name:'_comment',
                      width:360,
                      disabled:true
                    },{
                      xtype: 'radiogroup',
                      fieldLabel: "<{$words.browseable}>",
                      cname:'radio_browseable',
                      name:'radio_browseable',
                      width:300,
                      disabled:true,
                      items: [
                          {boxLabel: 'yes', name: '_browseable',inputValue:'yes',checked:true},
                          {boxLabel: 'no', name: '_browseable',inputValue:'no'}
                      ]
                    },{
                      xtype: 'radiogroup',
                      fieldLabel: "<{$words.public}>",
                      name:'radio_public',
                      cname:'radio_public',
                      width:300,
                      disabled:true,
                      items: [
                          {boxLabel: 'yes', name: '_guest_only',inputValue:'yes'},
                          {boxLabel: 'no', name: '_guest_only',inputValue:'no',checked:true}
                      ]
                    },mount_lun_limit,{
                      xtype: 'hidden',
                      cname:'_o_share',
                      name:'_o_share'
                    },{ 
                      xtype: 'hidden',
                      name:'action',
                      id: stackable_ct.actionId,
                      value:'add'
                    },{ 
                      xtype: 'hidden',
                      cname:'_target_port',
                      name:'_target_port',
                      value:'<{$target_port}>'
                    }]
    });
      
//**********************Window******************************** 
    var window_ext = new Ext.Window({ 
      closable:true,
      closeAction:'hide',
      width: 700,
      autoHeight: true,
      draggable:false,
      layout: 'fit',  
      plain: true,
      modal: true , 
      items: [formpanel_stackable]
    });  
    
    
//**********************TreeLoader******************************** 
        var tree_loader = new Ext.tree.TreeLoader({
            dataUrl:'<{$get_url}>&tree=1',
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

//**********************ColumnTree********************************

    var tree = new Ext.tree.ColumnTree({ 
        tbar:tb,
        width: 764,
        height: 440,
        rootVisible:false,
        autoScroll:true,
        useArrows:true,
        animate:true,
        containerScroll: true,
        columns:[{
            header:'<{$words.share_name}>',
            width:150,
            dataIndex:'share',
            renderer: function(value, treenode) {
                return String.format('<span ext:qtip="{0}" ext:qalign="b?" ext:qwidth="auto">{0}</span>', value);
            }
        },{
            header:'<{$gwords.ip}>', 
            width:120, 
            dataIndex:'ip'
        },{
            header:'<{$words.capacity}>', 
            width:140, 
            dataIndex:'capacity'
        },{
            header:'<{$gwords.status}>', 
            width:80, 
            dataIndex:'status'
        },{
            header:'<{$gwords.description}>', 
            width:80, 
            dataIndex:'comment'
        },{
            header:'<{$words.iqn}>', 
            width:350, 
            dataIndex:'iqn'
        }], 
        loader: tree_loader,
        root: new Ext.tree.AsyncTreeNode({   
            text:'root'
        })
    }); 
   

tree.on("beforeload", function(v) {  
  // mainMask.show();
      if(v.text=='root'){
          //tree_loader.dataUrl='<{$get_url}>&tree=root';
          tree_loader.dataUrl='<{$get_url}>&tree=1';
      }else{   
          tree_loader.dataUrl='<{$get_url}>&tree=subfolder&path='+v.attributes.path+'&aclshow='+v.attributes.acl;
      }      
}); 
tree.on("click", function(v) {
      var rootfolder = v.attributes.rootfolder;   
      //var format = (v.attributes.format=='on')?false:true; 
      //var reconnect = (v.attributes.reconnect=='on')?false:true; 
      //var acl = (v.attributes.acl=='on')?false:true; 
      if (rootfolder=='1'){//main folder
           stackable_ct.add.setDisabled(false);
           stackable_ct.edit.setDisabled(false);
           stackable_ct.remove.setDisabled(false);
           stackable_ct.format.setDisabled(v.attributes.format);
           stackable_ct.reconnect.setDisabled(v.attributes.reconnect);
           stackable_ct.acl.setDisabled(v.attributes.acl);
      }else{ //subfolder
           stackable_ct.add.setDisabled(true);
           stackable_ct.edit.setDisabled(true);
           stackable_ct.remove.setDisabled(true);
           //stackable_ct.acl.setDisabled(false);
           stackable_ct.acl.setDisabled(v.attributes.acl);
      }  
});  
     
var panel = TCode.desktop.Group.addComponent({
    items: [{
        xtype: 'fieldset',
        autoHeight: true,
        //collapsed: false,
        title: '<{$words.stackable_title}>',
        items: [
            {
                //show the iqn of initiator
                xtype: 'label',
                text: '<{$words.local_iqn}> <{$initiator_iqn}>'
            },
            tree
        ]
    }]
});
    
panel.on('beforedestroy',function(){
   stackable_ct = {};
   delete stackable_ct;
   Ext.destroy(
       window_acl,
       window_ext
   );
});

 


 /*********************************************************************
            ACL 
 **********************************************************************/
<{include file='adm/acl.tpl'}>

</script>
