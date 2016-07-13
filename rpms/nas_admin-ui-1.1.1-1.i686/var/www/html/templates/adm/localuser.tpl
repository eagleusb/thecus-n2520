<script language="javascript"> 
  var Data_grouplist =<{$Data_grouplist}>;
  <{include file='adm/search_list.tpl'}>
  
  
  function setAdd_Form(){
     Window_user.show();
     var request = eval('('+this.req.responseText+')');
     store_usergroup.loadData(eval(request.data));
     panel_ct.action.setValue('add');
     panel_ct.groupname.setValue(request.groupname);
     panel_ct.username.reset();
     panel_ct.userid.setValue(request.get_userid);
     panel_ct.pwd.reset();
     panel_ct.pwd2.reset();
     panel_ct.pwd_lock.setValue('0');
     panel_ct.username.enable();
     panel_ct.userid.enable();
     initDropDrag();
  };
  function setEdit_Form(){
     Window_user.show();
     var request = eval('('+this.req.responseText+')');
     var rows = grid.getSelectionModel().getSelected();
     store_usergroup.loadData(eval(request.data));
     panel_ct.action.setValue('update');
     panel_ct.groupname.setValue(request.groupname);
     panel_ct.username.setValue(rows.get("username"));
     panel_ct.userid.setValue(rows.get("userid"));
     panel_ct.pwd.setValue('password lock');
     panel_ct.pwd2.setValue('password lock');
     panel_ct.pwd_lock.setValue('1');
     panel_ct.username.disable();
     panel_ct.userid.disable();
     initDropDrag();
  };
   
  function initDropDrag(){
      var firstGridDropTarget = new Ext.dd.DropTarget(GridPanel_groupmember.getView().el.dom.childNodes[0].childNodes[1], {
          ddGroup    : 'firstGridDDGroup',
          copy       : true,
          notifyDrop : function(ddSource, e, data){
            function addRow(record, index, allItems) {
                    var foundItem = store_usergroup.findBy(function(r){ return r.get('groupname') == record.data.groupname; });
                    if (foundItem  == -1) {
                        store_usergroup.add(record);
                        panel_ct.groupname.getEl().dom.value += ' '+record.data.groupname;
                    }
                    ddSource.grid.store.remove(record);
            }
                        
            Ext.each(ddSource.dragData.selections ,addRow);
            return(true);
          }
     }); 	
     var destGridDropTarget = new Ext.dd.DropTarget(GridPanel_grouplist.getView().el.dom.childNodes[0].childNodes[1], {
           ddGroup    : 'secondGridDDGroup',
           copy       : true,
           notifyDrop : function(ddSource, e, data){
               function addRow(record, index, allItems) {
                     var foundItem = store_grouplist.findBy(function(r){ return r.get('groupname') == record.data.groupname; });
                     if(record.data.groupname!='users'){
                      			var gn = panel_ct.groupname.getEl().dom;
                      			var search = gn.value.split(' ');
                      			var tmp='users';
                      			for(var i =0;i<search.length;i++){
                      					  if(search[i]!=record.data.groupname && search[i]!='users'){
                      					    tmp+=' '+search[i]; 
                      					  }
                      			}   
                      			gn.value =tmp;                      			
                      			if(foundItem==-1)
                      			    store_grouplist.add(record);  
                      			ddSource.grid.store.remove(record);
                    }
                }
                Ext.each(ddSource.dragData.selections ,addRow);
                return(true);
           }
      });        
  };
  

   /*************************************************************
     when click toolbar from [User Grid]
     @param object obj,Ext.toolbar.obj.act
   **************************************************************/
    function toolbar_handle(obj){
        var selects = grid.getSelections(); 
        var rows = grid.getSelectionModel().getSelected();         
        var group_search = tb_grouplist.items.get(1);
        if(group_search){
               group_search.setValue('');
               store_grouplist.loadData(Data_grouplist);   
        }
        switch(obj.act){
           case  'add': 
                processAjax('<{$get_url}>',setAdd_Form,'get_userid=1');   
                Window_user.setTitle('<{$gwords.add}>');
           break;
           case 'edit':
              if(selects.length > 0){
                    processAjax('<{$get_url}>',setEdit_Form,'get_userid=1&username='+rows.get("username")); 
                    Window_user.setTitle('<{$gwords.edit}>');
              }else{
                    Ext.Msg.alert('<{$words.user_setting}>', "<{$words.user_no_select}>");
              }           
           break;
           case 'remove':  
              if(selects.length > 0){  
                    Ext.Msg.confirm('<{$words.user_setting}>', '<{$words.delete_confirm}>' , function(btn){ 
                        if(btn=='yes'){  
                             processAjax('<{$set_url}>',onLoadForm,'action=delete&username='+rows.get("username"));  
                             
                        }
                    });  
              }else{
                 Ext.Msg.alert('<{$words.user_setting}>', "<{$words.user_no_select}>");
              } 
           break;
        }
    }
    

//******************************  onLoad  ***********************************// 
   function onLoadApply(){
      var request = eval('('+this.req.responseText+')'); 
      if(request.show)
          mag_box(request.topic,request.message,request.icon,request.button,request.fn,request.prompt);
      if(request.icon=='ERROR'){
         if(panel_ct.action.getValue() == 'update'){
               panel_ct.username.disable();
               panel_ct.userid.disable();
         }
      }else{ 
         Window_user.hide();
      }
   };
 
   function onLoadStore(){ 
      store.load({params:{start:0, limit:<{$limit}>}});  
   }; 
   
    
  	
  	//**********************JsonStore********************************
    var store_usergroup = new Ext.data.JsonStore({
        fields: [ {name: 'groupid'},{name: 'groupname'}] 
    });
    var store_grouplist = new Ext.data.SimpleStore({
        fields: [{name: 'groupid'},{name: 'groupname'}], 
        data:Data_grouplist
    }); 
   
    //**********************GridPanel********************************
    var GridPanel_groupmember = new Ext.grid.GridPanel({
        ddGroup          : 'secondGridDDGroup',
        store            : store_usergroup,
        columns: [
            {header: "Group ID", sortable:true, width:60, dataIndex:'groupid'},
            {header: "Group Name", sortable:true, width:150, dataIndex:'groupname'}
        ],
        enableDragDrop   : true,
        stripeRows       : true,  
        height           :200,
        width            :388,
        loadMask:true,
        title            : '<{$words.group_member}>', 
        viewConfig: {
            forceFit:true 
        }
    });
 
    
    var tb_grouplist = new Ext.Toolbar({
        items:[ {
            xtype:'label',
            text:'<{$gwords.search}>:',
            style:'padding-right:20px;padding-left:10px'
          },{
            xtype:'textfield' ,
            width:210,
            enableKeyEvents :true,
            listeners:{
                keyup:function(obj){
                    store_grouplist.loadData(searchGrid(obj,Data_grouplist));  
                }
              }
        }] 
    });  
      
    
    var GridPanel_grouplist = new Ext.grid.GridPanel({
        tbar:tb_grouplist,
        ddGroup          : 'firstGridDDGroup',
        store            : store_grouplist,
        columns: [
            {header: "Group ID", sortable:true, width:60, dataIndex:'groupid'},
            {header: "Group Name", sortable:true, width:150, dataIndex:'groupname'}
        ],
        enableDragDrop   : true,
        stripeRows       : true,
        loadMask         : true,
        width            : 500,
        region           : 'center', 
        title            : '<{$words.group_list}>', 
        viewConfig: {
            forceFit:true 
        }
    });
 
    //**********************FormPanel********************************
    var panel_ct = {};
    function onComponentReady(ct){
        if (ct.cname) {
            panel_ct[ct.cname] = ct;
        }
    }
    var FormPanel_user = new Ext.FormPanel({ 
        title: '<{$words.user_setting}>',
        defaults:{
            labelStyle: 'width:50%',
            listeners: {
                render: onComponentReady
            }
        },
        frame: true,
        region           : 'west', 
        width:400,
        margins : '0 3 0 0',
        labelAlign:'left',
        items :[{
                xtype: 'textfield',
                style: 'margin: 0.1px 0 0 0',//ie
                fieldLabel: "<{$words.username}>", 
                name: 'username', 
                cname: 'username',
                allowBlank:false
            },{
                xtype: 'textfield',
                fieldLabel: '<{$words.user_id}>', 
                name: 'userid', 
                cname: 'userid',
                allowBlank:false
            },{ 
                xtype:'textfield',
                inputType:'password',
                fieldLabel: '<{$gwords.password}>', 
                name: 'pwd'  , 
                cname: 'pwd',
                allowBlank:false,
                listeners: { 
                    change:function(){
                        panel_ct.pwd_lock.setValue('0');
                    },
                    focus:function(){ 
                        this.selectText();
                    },
                    render: onComponentReady
                }
            },{ 
                xtype:'textfield',
                inputType:'password',
                fieldLabel: '<{$gwords.pwd_confirm}>', 
                name: 'pwd2'  , 
                cname: 'pwd2',
                allowBlank:false,
                listeners: {  
                    focus:function(){ 
                       this.selectText();
                    },
                    render: onComponentReady
                }
            }, { 
                xtype:'hidden',  
                name: 'groupname', 
                cname: 'groupname',
                value:'' 
            },GridPanel_groupmember,
            { 
                xtype:'hidden',  
                name: 'action', 
                cname: 'action',
                value:'add' 
            },{
                xtype:'hidden',
                name: 'pwd_lock',
                cname: 'pwd_lock',
                value:'1'
        }]
    });

    //**********************Window********************************
    var Window_user= new Ext.Window({ 
      closable:true,
      closeAction:'hide',
      width: 720,
      height:420,
      layout: 'border',  
      modal: true , 
      draggable:false,
      items: [FormPanel_user ,GridPanel_grouplist],  
        buttonAlign:'left',
        buttons: [{
        text: '<{$gwords.apply}>',
        handler:function(){  
           if(FormPanel_user.getForm().isValid()){ 
                var confirm_msg = '';
                if(panel_ct.action.getValue() == 'update'){
                     confirm_msg = '<{$words.modify_confirm}>';
                }else{
                     confirm_msg = '<{$words.new_confirm}>';
                }
                if(panel_ct.pwd.getValue() != panel_ct.pwd2.getValue()){
                    mag_box('<{$words.user_setting}>','<{$words.pwd_error}>','ERROR','OK');
                }else{   
                    Ext.Msg.confirm('<{$words.user_setting}>', confirm_msg , function(btn){ 
                        if(btn=='yes'){
                            if(panel_ct.action.getValue() == 'update'){
                                 panel_ct.username.enable();
                                 panel_ct.userid.enable();
                            }
                            processAjax('<{$set_url}>',onLoadApply,FormPanel_user.getForm().getValues(true));  
                        }
                    });
                }
            } 
          } 
        }]
    });  


	  //**********************Toolbar******************************** 
    var tb = new Ext.Toolbar({
        items:[{ 
            text: '<{$gwords.add}>',
            iconCls: 'add',
            act:'add',
            handler: toolbar_handle
        },'-',{
            text: '<{$gwords.edit}>',
            iconCls: 'edit',
            act:'edit',
            handler: toolbar_handle
        },'-',{
            text: '<{$gwords.remove}>',
            iconCls: 'remove',
            act:'remove',
            handler: toolbar_handle
        }]
    });
     



    
    var store = new Ext.data.JsonStore({
        root: 'data',
        totalProperty: 'totalcount',
        idProperty: 'userid',
        //remoteSort: true,
        fields: [ {name: 'userid'},{name: "username"}],
        url: '<{$get_url}>' 
    });



    var pagingBar = new Ext.PagingToolbar({
        pageSize: <{$limit}>,
        store: store,
        displayInfo: true,
        displayMsg: 'Displaying topics {0} - {1} of {2}',
        emptyMsg: "No topics to display" 
    });
	
    var grid = TCode.desktop.Group.addComponent({
        xtype: 'grid',
        store: store,
        trackMouseOver:false,
        disableSelection:false,
        loadMask: false,
        loadMask:true,
        columns:[
            {header:'<{$words.user_id}>',width:80,dataIndex:'userid',sortable: true},
            {header:"<{$words.username}>",dataIndex:'username',sortable: true}
        ],   
        frame:false, 
        viewConfig: {
            forceFit:true 
        }, 
        bbar: pagingBar, 
        tbar :tb

    });
    grid.on('beforedestroy', function(){
        panel_ct = {};
        delete panel_ct;
        Ext.destroy(
            store_usergroup,
            store_grouplist,
            store,
            Window_user
        );
    });
 
    store.load({params:{start:0, limit:<{$limit}>}});
    

</script> 
