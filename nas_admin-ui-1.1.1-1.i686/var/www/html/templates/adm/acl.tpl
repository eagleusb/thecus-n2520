
 
var acl_node;
var recursive_checked = true;
var dd_key=false;

function checkbox_recursive(obj){
  recursive_checked = obj.checked;
}

function acl_popup(node){      
       acl_node= node;  
       if(!window_acl.isVisible()){
            window_acl.setTitle('<{$awords.settingTitle}>: ' + node.attributes.share);
            window_acl.show(); 
       }
    
       processAjax('<{$acl_url}>', onLoad_acl, '&action=getacl&access=1&path='+node.attributes.path+'&share='+node.attributes.share+'&md='+node.attributes.md_num);  
       
       if (node.attributes.usb=='1') {
			document.getElementById('recursive').disabled=true;
			recursive_checked=false;
	   } else {
			document.getElementById('recursive').disabled=false;
		}
       document.getElementById('recursive').checked=recursive_checked;
} 
function onLoad_acl(){
   var request = eval('('+this.req.responseText+')'); 
   if(!document.getElementById('recursive').disabled)
        document.getElementById('recursive').checked=(request.recursive=='0')?false:true;
   
   checkbox_recursive(document.getElementById('recursive'));
   acl_store.loadData(request.data);
   store_deny.loadData(request.access.deny);
   store_readonly.loadData(request.access.readonly);
   store_writable.loadData(request.access.writable);
   Ext.getCmp('_deny').setValue(request.access.value_deny);
   Ext.getCmp('_readonly').setValue(request.access.value_readonly);
   Ext.getCmp('_writable').setValue(request.access.value_writable);
}
//sync
function sync_acl(node){
     Ext.Msg.confirm('<{$awords.settingTitle}>', "<{$awords.sync_confirm}>" , function(btn){ 
         if(btn=='yes'){  
             processAjax('<{$acl_url}>', onLoad_acl, '&action=sync&access=1&path='+acl_node.attributes.path+'&share='+acl_node.attributes.share+'&md='+acl_node.attributes.md_num);  
             acl_combo.setValue('local_group');
             if(Ext.getCmp('acl_search_txt'))Ext.getCmp('acl_search_txt').setValue(''); 
         }
     });
  
}  


{//acl_apply 
function acl_apply(){ 
       var recursive='';
       var node = tree.getSelectionModel().getSelectedNode();  
       var deny_v = Ext.getCmp('_deny').getValue();
       var readonly_v = Ext.getCmp('_readonly').getValue();
       var writable_v = Ext.getCmp('_writable').getValue();  
       var param='&action=setacl&checkvalue='+deny_v+'^'+readonly_v+'^'+writable_v; 
       if(recursive_checked){
       	  recursive="&recursive=1";
       }
       param+='&search_type='+
              '&path='+node.attributes.path+
              '&share='+node.attributes.share+
              '&md='+node.attributes.md_num+recursive;  
       processAjax('getmain.php?fun=acl',onLoadForm,param);   
} 
function onLoad_acl_apply(){ 
    window_acl.hide(); 
};
}


{//acl search
function search_acl(){     
     var node = tree.getSelectionModel().getSelectedNode();    
     var deny_v = Ext.getCmp('_deny').getValue();
     var readonly_v = Ext.getCmp('_readonly').getValue();
     var writable_v = Ext.getCmp('_writable').getValue();  
     var param = '&action=search'+
                 '&search_type='+acl_combo.value+
                 '&search_name='+Ext.getCmp('acl_search_txt').getValue()+
                 '&path='+node.attributes.path+
                 '&share='+node.attributes.share+
                 '&checkvalue='+deny_v+readonly_v+writable_v+
                 '&md='+node.attributes.md_num;
     processAjax('<{$acl_url}>', onLoad_acl_search, param);  
}
function onLoad_acl_search(){ 
   var request = eval('('+this.req.responseText+')'); 
   if(request.error){ 
        mag_box('<{$gwords.warning}>',request.errormsg,'WARNING','OK');
   }else{
     acl_store.loadData(request.data); 
   }
}

}

{//acl_combo
    var aclcombo_store = new Ext.data.SimpleStore({
      	fields: <{$combo_fields}>,
      	data: <{$acl_combo_value}>
    });
    var acl_combo = new Ext.form.ComboBox({
         width:100,
         mode: 'local',
         store: aclcombo_store,
         displayField: 'display',
         valueField: 'value',
         readOnly: true, 
         selectOnFocus:true, 
         triggerAction: 'all' 
    }); 
    acl_combo.setValue('<{$acl_combo}>'); 
}   
 // toolbar   
 {
    var bb_desc = new Ext.Toolbar({
        items:[{
            xtype:'label',
              html:"<div style='height:22px;' ><span style='color:red' ><{$awords.localGroup}></span>&nbsp;&nbsp;|&nbsp;&nbsp;<span style='color:green'><{$awords.localUser}></span><{if ($winad=='1')}>&nbsp;&nbsp;|&nbsp;&nbsp;<span style='color:#0000ff'><{$awords.adGroup}></span>&nbsp;&nbsp;|&nbsp;&nbsp;<span style='color:#ff6600'><{$awords.adUser}></span></div>"<{else}></div>"<{/if}>
        }]
    });
    
    var tb_acl = new Ext.Toolbar({
        items:[{
            xtype:'textfield',
            id:'acl_search_txt'
        },' ',acl_combo,' ',{
            text: '<{$gwords.search}>',
            iconCls: 'option',
            handler:search_acl
        }],
        listeners: {
            render: function (ct) {
                    if (Ext.isIE) {
                        ct.setHeight(25);
                    }
            }
        }
    });
    
    var tb_deny = new Ext.Toolbar({
        id:'tb_deny',
        items:[{  
            iconCls: 'add',
            id:'tb_deny_add',
            mode:'deny',
            disabled:true,
            handler:tb_access
        },'-',{ 
            iconCls: 'remove',
            id:'tb_deny_remove',
            mode:'deny',
            disabled:true,
            handler:tb_access
        }]
    });
    var tb_readonly = new Ext.Toolbar({
        id:'tb_readonly',
        items:[{  
            iconCls: 'add',
            id:'tb_readonly_add',
            disabled:true,
            mode:'readonly',
            handler:tb_access
        },'-',{ 
            iconCls: 'remove',
            id:'tb_readonly_remove',
            disabled:true,
            mode:'readonly',
            handler:tb_access
        }]
    });         
    var tb_writable = new Ext.Toolbar({
        id:'tb_writable',
        items:[{  
            iconCls: 'add',
            id:'tb_writable_add',
            disabled:true,
            mode:'writable',
            handler:tb_access
        },'-',{ 
            iconCls: 'remove',
            id:'tb_writable_remove',
            mode:'writable',
            disabled:true,
            handler:tb_access
        }]
    }); 
}    

  function draw_color(v,cellmata,record,rowIndex){
      var namecolor="<span style='color:";
      var mode = record.data['mode'];
      //alert(mode+','+record.data['type']+','+record.data['id']+','+record.data['name']); 
      switch(mode){
          case 'local_group':
          namecolor+="red'>";
          break; 
          case 'local_user':
          namecolor+="green'>";          
          break; 
          case 'ad_group':
          namecolor+="blue'>";          
          break; 
          case 'ad_user':
          namecolor+="#FF6600'>"; 
          break; 
          default:
          namecolor+="black'>";  
      }
     return namecolor+=v+"</span>";
  }
    var acl_cols =[
        {dataIndex: 'id',hidden:true},
        {header: 'Name',  sortable: true, dataIndex: 'name',renderer:draw_color,menuDisabled:true},
        {dataIndex: 'type',hidden:true},
        {dataIndex: 'mode',hidden:true}
	  ];  
	  
	  { // store
    var acl_store = new Ext.data.JsonStore({
        fields: ['id','name','type','mode'] ,
        listeners : { 
            load: function(){ 
                 Ext.getCmp('tb_deny_add').setDisabled(true);
                 Ext.getCmp('tb_readonly_add').setDisabled(true);
                 Ext.getCmp('tb_writable_add').setDisabled(true); 
            },
            remove:function(){
                 dd_key=true;   
            }
        }
    });   
    var store_deny = new Ext.data.JsonStore({
        id:'store_deny', 
        fields: ['id','name','type','mode']
    });  
    var store_readonly = new Ext.data.JsonStore({
        id:'store_readonly', 
        fields: ['id','name','type','mode']
    });  
    var store_writable = new Ext.data.JsonStore({
        id:'store_writable', 
        fields: ['id','name','type','mode']
    }); 
  }  
 
  { //grid
     //Style for IE
     var ie_chkbox_style = '';
     (function (){
         if (Ext.isIE) {
             ie_chkbox_style = "style='height: 10px'";
         }
     })();
     var acl_grid = new Ext.grid.GridPanel({
        title: "<label><input type='checkbox' name='recursive' id='recursive' value='1' checked='true' onclick='checkbox_recursive(this)' "+ ie_chkbox_style +"/>&nbsp;<{$awords.recursive}></label>",
        tbar             : tb_acl,
        ddGroup          : 'dropgroup_target',  
        store            : acl_store,
        columns          : acl_cols, 
        stripeRows       : true,
        cls              : 'acl_win_header',
	enableDragDrop   : true,
	width:350,
        viewConfig: {
            forceFit:true 
        },
        listeners: {  
            rowclick: function(grid, rowIndex, e){ 
                 Ext.getCmp('tb_deny_add').setDisabled(false);
                 Ext.getCmp('tb_readonly_add').setDisabled(false);
                 Ext.getCmp('tb_writable_add').setDisabled(false);
                 //var record = grid.getStore().getAt(rowIndex);
                 //selectedCategory = record.data.name; 
                  dd_key=false; 
            }  ,
            mouseover:function(){
              dd_key=false; 
            }
        }
    }); 
     delete ie_chkbox_style;
    
     var grid_deny = new Ext.grid.GridPanel({
        id               :'grid_deny',  
        ddGroup          : 'dropgroup_source',
        tbar             : tb_deny,
        store            : store_deny,
        columns          : acl_cols, 
        stripeRows       : true,
        cls              : 'acl_win_header',
	enableDragDrop   : true,
	width:170,
        viewConfig: {
            forceFit:true 
        },
        listeners: { 
            rowclick: function(grid, rowIndex, e){ 
                 Ext.getCmp('tb_deny_remove').setDisabled(false); 
            }
        }
    });
    
     var grid_readonly = new Ext.grid.GridPanel({
        id               :'grid_readonly',  
        ddGroup          : 'dropgroup_source',
        tbar             : tb_readonly,
        store            : store_readonly,
        columns          : acl_cols, 
        stripeRows       : true,
        cls              : 'acl_win_header',
	enableDragDrop   : true,
	width:170,
        viewConfig: {
            forceFit:true 
        },
        listeners: { 
            rowclick: function(grid, rowIndex, e){ 
                 Ext.getCmp('tb_readonly_remove').setDisabled(false); 
            }
        }
    });
    
     var grid_writable = new Ext.grid.GridPanel({
        id               :'grid_writable',  
	ddGroup          : 'dropgroup_source',
        tbar             : tb_writable,
        store            : store_writable,
        columns          : acl_cols, 
        stripeRows       : true,
        cls              : 'acl_win_header',
	enableDragDrop   : true,
	width:156,
        viewConfig: {
            forceFit:true 
        },
        listeners: { 
            rowclick: function(grid, rowIndex, e){ 
                 Ext.getCmp('tb_writable_remove').setDisabled(false); 
            }
        }
    });
}        
      
   
    
    
 function tb_access(v){  
    var modes = v.mode;    
    Ext.getCmp(v.id).setDisabled(true); 
    
    //remove
    if(v.id!='tb_deny_add' && v.id!='tb_readonly_add' && v.id!='tb_writable_add'){ 
        var grids = Ext.getCmp('grid_'+modes);
        var stores = Ext.getCmp('store_'+modes);
        var rows = grids.getSelectionModel().getSelections();  
        
        for(var i =0;i<rows.length;i++){ 
             var findrow = rows[i].get('id')+'~'+rows[i].get('mode')+'|';
             var access_obj = 	Ext.getCmp('_'+modes).getValue();
             var tmp = access_obj.replace(findrow,'');
             Ext.getCmp('_'+modes).setValue(tmp);   
        		 acl_store.add(rows[i]); 
             switch(modes){
         	   	    case 'deny':store_deny.remove(rows[i]); break;
         	   	    case 'readonly':store_readonly.remove(rows[i]); break; 
         	   	    case 'writable':store_writable.remove(rows[i]); break; 
             }
        } 
    //add
    }else{
        var grids = acl_grid;
        var stores = acl_store;
        var rows = grids.getSelectionModel().getSelections();  
        for(var i =0;i<rows.length;i++){
             var findrow = rows[i].get('id')+'~'+rows[i].get('mode')+'|';
             var access_obj = 	Ext.getCmp('_'+modes).getValue();
             var tmp = access_obj+findrow+'|';
             Ext.getCmp('_'+modes).setValue(tmp);  
        		 acl_store.remove(rows[i]); 
             switch(modes){
         	   	    case 'deny':store_deny.add(rows[i]); break;
         	   	    case 'readonly':store_readonly.add(rows[i]); break; 
         	   	    case 'writable':store_writable.add(rows[i]); break; 
             }
        } 
    }
 }
 
 
 //dragdrop    
 function DropDrag_ACL(){  
    var drop_source = new Ext.dd.DropTarget(acl_grid.getView().el.dom.childNodes[0].childNodes[1], {
          id         :'drop_source',
          ddGroup    : 'dropgroup_source',
          copy       : true,
          notifyDrop : function(ddSource, e, data){
            function addRow(record, index, allItems) {
                    var foundItem = acl_store.findBy(function(r){ return r.get('id')+r.get('mode') == record.data.id+record.data.mode; }); 
                    
                    var tmp='';
                    var access_obj = 	Ext.getCmp('_'+record.data.type).getValue();
                    var search = access_obj.split('|'); 
                    for(var i =0;i<search.length;i++){
                      	 if(search[i]!=record.data.id+'~'+record.data.mode && search[i]!=''){
                      					    tmp+=search[i]+'|'; 
                      	 }
                    }   
                    Ext.getCmp('_'+record.data.type).setValue(tmp);  
                    Ext.getCmp('tb_'+record.data.type+'_remove').setDisabled(true); 
                    if (foundItem  == -1) {
                        	acl_store.add(record);  
                     }
                    ddSource.grid.store.remove(record); 
            } 
            Ext.each(ddSource.dragData.selections ,addRow);
            return(true);
          }
    }); 	
    
    var drop_target_deny = new Ext.dd.DropTarget(grid_deny.getView().el.dom.childNodes[0].childNodes[1], {
           id         :'drop_target_deny',
           ddGroup    : 'dropgroup_target',
           copy       : true,
           notifyDrop : function(ddSource, e, data){
               if(!dd_key){
               function addRow(record, index, allItems) { 
                     var foundItem = store_deny.findBy(function(r){ return r.get('id')+r.get('mode') == record.data.id+record.data.mode; });
                      			if(foundItem==-1 && record!=null && record.data!=null){ 
                                      var alldata = record.data.id+'~'+record.data.mode;
                      			    Ext.getCmp('_deny').setValue(Ext.getCmp('_deny').getValue()+alldata+"|");
                      			    record.data.type='deny';
                          		    store_deny.add(record);  
                      			}
                          	ddSource.grid.store.remove(record);   
                }
                Ext.each(ddSource.dragData.selections ,addRow);
                return(true);
              }
           }
      });   
    
    var drop_target_readonly = new Ext.dd.DropTarget(grid_readonly.getView().el.dom.childNodes[0].childNodes[1], {
           id         :'drop_target_readonly',
           ddGroup    : 'dropgroup_target',
           copy       : true,
           notifyDrop : function(ddSource, e, data){
               if(!dd_key){
               function addRow(record, index, allItems) { 
                     var foundItem = store_readonly.findBy(function(r){ return r.get('id')+r.get('mode') == record.data.id+record.data.mode; });
                      			if(foundItem==-1 && record!=null && record.data!=null){ 
                                      var alldata = record.data.id+'~'+record.data.mode;
                      			    Ext.getCmp('_readonly').setValue(Ext.getCmp('_readonly').getValue()+alldata+"|");
                      			    record.data.type='readonly';
                          		    store_readonly.add(record);   
                          	}
                          	ddSource.grid.store.remove(record);   
                }
                Ext.each(ddSource.dragData.selections ,addRow);
                return(true);
              }
           }
      });   
    var drop_target_writable = new Ext.dd.DropTarget(grid_writable.getView().el.dom.childNodes[0].childNodes[1], {
           id         :'drop_target_writable',
           ddGroup    : 'dropgroup_target',
           copy       : true,
           notifyDrop : function(ddSource, e, data){
               if(!dd_key){
               function addRow(record, index, allItems) { 
                     var foundItem = store_writable.findBy(function(r){ return r.get('id')+r.get('mode') == record.data.id+record.data.mode; });
                      			if(foundItem==-1 && record!=null && record.data!=null){ 
                                      var alldata = record.data.id+'~'+record.data.mode;
                      			    Ext.getCmp('_writable').setValue(Ext.getCmp('_writable').getValue()+alldata+"|");
                      			    record.data.type='writable';
                          		    store_writable.add(record);    
                      			}
                        	ddSource.grid.store.remove(record);   
                }
                Ext.each(ddSource.dragData.selections ,addRow);
                return(true);
              }
           }
      });   
             
             
  }      
  
var panel_acl = new Ext.Panel({
    layout:'column', 
    frame:false,
    border:false,
    //width:855,
    autoWidth:true,
    defaults:{bodyStyle:'padding:0px;border-width:0px'},
    items: [{ 
          width:350,
          defaults:{height:405}, 
          items:[acl_grid] 
      },{
          width:170,
          title:'<{$gwords.deny}>',
          defaults:{height:380}, 
          items:[grid_deny]
      },{
          width:170,
          title:'<{$gwords.readonly}>',
          defaults:{height:380},
          items:[grid_readonly]
      },{
          width:156,
          title:'<{$gwords.writable}>',
          defaults:{height:380},
          items:[grid_writable]
      },{
        xtype:'hidden',
        id:'_deny',
        value:''        
      },{
        xtype:'hidden',
        id:'_readonly',
        value:''        
      },{
        xtype:'hidden',
        id:'_writable',
        value:''        
      }]
});

     var window_acl = new Ext.Window({ 
      closable:true,
      closeAction:'hide',
      width: 860,
      height:500, 
      title:'<{$awords.settingTitle}>',
      draggable:true,
      layout: 'fit',  
      modal: true ,  
      items: [panel_acl],
      buttonAlign:'left' , 
      bbar: bb_desc,
      buttons:[
        <{if ($winad=='1')}>
            { text: '<{$nwords.sync}>',handler:sync_acl},
        <{/if}>
        { text: '<{$gwords.apply}>',handler:acl_apply}] 
    });  
     window_acl.on(
        'show',function(){ 
             var ww = (document.body.clientWidth-865)/2;
             var hh = (document.body.clientHeight-500)/2;
             window_acl.setPagePosition(ww,hh);
             acl_combo.setValue('local_group');
             if(Ext.getCmp('acl_search_txt'))Ext.getCmp('acl_search_txt').setValue(''); 
             DropDrag_ACL();
            
         }
     );

