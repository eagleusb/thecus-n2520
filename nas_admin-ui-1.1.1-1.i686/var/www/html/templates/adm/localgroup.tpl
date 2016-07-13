<script language="javascript"> 
var Data_userlist =<{$Data_userlist}>;   

  <{include file='adm/search_list.tpl'}>
  
  function setAdd_Form(){
     Window_group.show();
     var request = eval('('+this.req.responseText+')');
     store_memberlist.loadData(false);
     panel_ct.action.setValue('add');
     panel_ct.username.reset();
     panel_ct.groupname.reset();
     panel_ct.groupid.setValue(request.get_groupid);
     panel_ct.groupname.enable();
     panel_ct.groupid.enable();
     initDropDrag();
  };
  function setEdit_Form(){
     Window_group.show();
     var request = eval('('+this.req.responseText+')');
     store_memberlist.loadData(eval(request.data));
     var rows = grid.getSelectionModel().getSelected();
     panel_ct.action.setValue('update');
     panel_ct.username.setValue(request.username+' ');
     panel_ct.groupname.setValue(rows.get('groupname'));
     panel_ct.groupid.setValue(rows.get('groupid'));
     panel_ct.groupname.disable();
     panel_ct.groupid.disable();
     initDropDrag();
  };

   function onLoadApply(){
      var request = eval('('+this.req.responseText+')'); 
      if(request.show)
          mag_box(request.topic,request.message,request.icon,request.button,request.fn,request.prompt);
      if(request.icon=='ERROR'){
         if(panel_ct.action.getValue() == 'update') {
               panel_ct.groupname.disable();
               panel_ct.groupid.disable();
         }
      }else{ 
         Window_group.hide();
      }
   };

   function onLoadStore(){ 
      store.load({params:{start:0, limit:<{$limit}>}});  
   }; 
  function initDropDrag(){
      var firstGridDropTarget = new Ext.dd.DropTarget(GridPanel_groupmember.getView().el.dom.childNodes[0].childNodes[1], {
          ddGroup    : 'firstGridDDGroup',
          copy       : true,
          notifyDrop : function(ddSource, e, data){
            function addRow(record, index, allItems) {
                    var foundItem = store_memberlist.findBy(function(r){ return r.get('username') == record.data.username; });
                    if (foundItem  == -1) {
                        	store_memberlist.add(record); 
                        	panel_ct.username.getEl().dom.value += record.data.username+' ';
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
                     var foundItem = store_userlist.findBy(function(r){ return r.get('username') == record.data.username; });
                      			var gn = panel_ct.username.getEl().dom;
                      			var search = gn.value.split(' ');
                      			var tmp='';
                      			for(var i =0;i<search.length;i++){
                      					  if(search[i]!=record.data.username){
                      					    tmp+=search[i]+' '; 
                      					  }
                      			}   
                      			tmp = tmp.substring(0,(tmp.length-1));
                      			gn.value =tmp;
                      			if (foundItem==-1)
                      			      store_userlist.add(record); 
                      			ddSource.grid.store.remove(record); 
                }
                Ext.each(ddSource.dragData.selections ,addRow);
                return(true);
           }
      });        
  };
  
  	//**********************JsonStore********************************
    var store_memberlist = new Ext.data.JsonStore({
        fields: [ {name: 'userid'},{name: 'username'}] 
    }); 
    
    var store_userlist = new Ext.data.SimpleStore({
        fields: [ {name: 'userid'},{name: 'username'}],
        data:Data_userlist
    }); 
    
   
    //**********************GridPanel********************************
    var GridPanel_groupmember = new Ext.grid.GridPanel({
        ddGroup          : 'secondGridDDGroup',
        store            : store_memberlist,
        loadMask         : true,
        enableDragDrop   : true,
        stripeRows       : true, 
        height           : 250,
        width            : 388,
        title            : '<{$words.members_list}>',
        columns:[
            {header:"User ID", sortable:true, width:60, dataIndex:'userid'},
            {header:"User Name", sortable:true, dataIndex:'username'}
        ],
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
                    store_userlist.loadData(searchGrid(obj,Data_userlist));  
                }
              }
        }] 
    });  
      
      
    var GridPanel_grouplist = new Ext.grid.GridPanel({
        tbar             : tb_grouplist,
        ddGroup          : 'firstGridDDGroup',
        store            : store_userlist,
        loadMask         : true,
        enableDragDrop   : true,
        stripeRows       : true,  
        region           : 'center',  
        title            : '<{$words.users_list}>', 
        columns: [
            {header: "User ID", sortable:true, width:60, dataIndex:'userid'},
            {header: "User Name", sortable:true, dataIndex:'username'}
        ],
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
    var FormPanel_group = new Ext.FormPanel({ 
        title: '<{$words.group_setting}>',
        frame: true,
        region  : 'west',
        margins : '0 3 0 0',  
        width:400,
        defaults: {
            labelStyle: 'width:50%',
            listeners:{
                render: onComponentReady
            }
        },
        items :[{
                xtype: 'textfield',
                style: 'margin: 0.1px 0 0 0',//ie
                fieldLabel: '<{$words.groupname}>', 
                name: 'groupname', 
                cname: 'groupname',
                allowBlank:false
            },{
                xtype: 'textfield',
                fieldLabel: '<{$words.group_id}>', 
                name: 'groupid', 
                cname: 'groupid',
                allowBlank:false
            },GridPanel_groupmember,
            { 
                xtype:'hidden',  
                name: 'username', 
                cname: 'username',
                value:'' 
            },
            { 
                xtype:'hidden',  
                name: 'action', 
                cname: 'action',
                allowBlank:false,
                value:'add' 
        }]
    });

    //**********************Window********************************
    var Window_group= new Ext.Window({  
      closable:true,
      closeAction:'hide',
      width: 720,
      height:420,
      layout: 'border',  
      modal: true , 
      draggable:false,
      items: [FormPanel_group,GridPanel_grouplist],  
        buttonAlign:'left',
        buttons: [{
        text: '<{$gwords.apply}>',
        handler:function(){  
           if(FormPanel_group.getForm().isValid()){ 
                var confirm_msg = '';
                if(panel_ct.action.getValue() == 'update'){
                     confirm_msg = '<{$words.modify_confirm}>';
                }else{
                     confirm_msg = '<{$words.new_confirm}>';
                }
                
                Ext.Msg.confirm('<{$words.group_setting}>', confirm_msg , function(btn){ 
                        if(btn=='yes'){
                            if(panel_ct.action.getValue() == 'update') {
                                 panel_ct.groupname.enable();
                                 panel_ct.groupid.enable();
                            }
                            processAjax('<{$set_url}>',onLoadApply,FormPanel_group.getForm().getValues(true));  
                        }
                });
            } 
          } 
        }]
    }); 

	  
   /*************************************************************
     when click toolbar from [User Grid]
     @param object obj,Ext.toolbar.obj.id   
   **************************************************************/
    function toolbar_handle(obj){
        var selects = grid.getSelections(); 
        var rows = grid.getSelectionModel().getSelected();
        var group_search = tb_grouplist.items.get(1);
        if(group_search){
               group_search.setValue('');
               store_userlist.loadData(Data_userlist);   
        }
        switch(obj.act){
           case  'add': 
                processAjax('<{$get_url}>',setAdd_Form,'get_groupid=1');  
                Window_group.setTitle('<{$gwords.add}>');                     
           break;
           case 'edit':
              if(selects.length > 0){
                   processAjax('<{$get_url}>',setEdit_Form,'get_groupid=1&groupname='+encodeURIComponent(rows.get("groupname"))); 
                   Window_group.setTitle('<{$gwords.edit}>');
              }else{
                    Ext.Msg.alert('<{$words.group_setting}>', '<{$words.group_no_select}>');
              }           
           break;
           case 'remove':  
              if(selects.length > 0){  
                    Ext.Msg.confirm('<{$words.group_setting}>', '<{$words.delete_confirm}>' , function(btn){ 
                        if(btn=='yes'){  
                            processAjax('<{$set_url}>',onLoadForm,'action=delete&groupname='+encodeURIComponent(rows.get("groupname")));   
                        }
                    });  
              }else{
                 Ext.Msg.alert('<{$words.group_setting}>', '<{$words.group_no_select}>');
              } 
           break;
        }
    }
    
	  //**********************Toolbar******************************** 
    var tb = new Ext.Toolbar({
        items:[{ 
            text: '<{$gwords.add}>',
            iconCls: 'add',
            act:'add',
            handler:toolbar_handle
        },'-',{
            text: '<{$gwords.edit}>',
            iconCls: 'edit',
            act:'edit',
            handler:toolbar_handle
        },'-',{
            text: '<{$gwords.remove}>',
            iconCls: 'remove',
            act:'remove',
            handler:toolbar_handle
        }]
    });
     



    
    var store = new Ext.data.JsonStore({
        root: 'data',
        totalProperty: 'totalcount',
        idProperty: 'groupid',
        fields: [ {name: 'groupname'},{name: 'groupid'}],
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
        columns:[
            {header:'<{$words.group_id}>',width:80, dataIndex:'groupid',sortable: true},
            {header:'<{$words.groupname}>',width:300, dataIndex:'groupname',sortable: true}
        ],   
        frame:false, 
        loadMask:true,
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
            store_memberlist,
            store_userlist,
            store,
            Window_group
        );
    });
 
    store.load({params:{start:0, limit:<{$limit}>}});
    
    
</script>
