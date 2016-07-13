<form name="isomount_tmp" id="isomount_tmp" method="post">
<input type=hidden name="umount_iso_data" id="umount_iso_data" value="">
<input type=hidden name="root" id="root" value="">
<input type=hidden name="unmount_all_flag" id="unmount_all_flag" value="">
<input type=hidden name="expand_folder" id="expand_folder" value="">
</form>

<script text="text/javascript">
var isomount_count=<{$isomount_count}>;
var now_loc=0;//record now is pop window
var sels,before_path='';

/*
* when have any action ,isomount grid will update.
* @param act: now is unmount or add iso mount
* @returns none.
*/
function update_grid_data(act){
  var str='',tmp_str,path_depth=0,search_flag;

  if(now_loc==0){
    now_grid.store.load({params:{start:0, limit:<{$limit1}>}});
    now_grid.getColumnModel().setColumnHeader(0,'<div class="x-grid3-hd-checker"> </div>');
  }else{
    now_grid.getColumnModel().setColumnHeader(0,'<div class="x-grid3-hd-checker"> </div>');
    now_grid.store.load({params:{start:0, limit:<{$limit}> ,roots:share_folder.getValue()}});      
    if(act==1){
      tmp_str = isomount.iso_path.getValue().split("/");

      for(var i=1;i<tmp_str.length-1;i++){
       str=str+tmp_str[i];
       if(i!=tmp_str.length-2){
         str=str+"/";
         path_depth++;
       }  
      }

      if(path_depth==0){
        before_path=document.getElementById('expand_folder').value;
        tree.collapseAll();
        tree.getRootNode().expand();
      }else{  
        tree.getNodeById(str).collapse();
        tree.getNodeById(str).expand();
      }   
      
      isomount.iso_path.setValue('');
      isomount.mount_path.setValue('');
    }
    
    if(act==3){
      tree.collapseAll();
      tree.getRootNode().expand(); 
/*        if(document.getElementById('unmount_all_flag').value==1){
          tree.collapseAll();
          tree.getRootNode().expand();        
        }else{
          if(document.getElementById('expand_folder').value== tree.getRootNode().id){
            tree.collapseAll();
            tree.getRootNode().expand();   
          }else{
            tmp_str=document.getElementById('expand_folder').value.split("/");
            str=tmp_str[0];
            for(var i=1;i<tmp_str.length-1;i++){
              str=str+"/";
              str=str+tmp_str[i];
              search_flag=document.getElementById('umount_iso_data').value.indexOf(str,0);
              if(search_flag!=-1){
                eval("tree.getNodeById('"+str+"').collapse()");
                eval("tree.getNodeById('"+str+"').expand()");
              }
            }            
          }  
//            eval("tree.getNodeById('"+tmp_str+"').collapse()");
//            eval("tree.getNodeById('"+tmp_str+"').expand()");
      }*/
    }
  }
}


/*
* show reslut after execute unmount iso.
* @returns none.
*/
function execute_unmount_iso_result(){
  var request = eval('('+this.req.responseText+')');    
 
  if(request.show){
    mag_box(request.topic,request.message,request.icon,request.button,request.fn,request.prompt);
  }    
}
  
/*
* execute unmount iso.
* @returns none.
*/  
function unmount_iso(){
  var seltext='';
  document.getElementById('unmount_all_flag').value=0;         
  sels = now_grid.getSelectionModel().getSelections();
/*    if(now_loc==1){
      sels = isomount_table_grid.getSelectionModel().getSelections();
      now_grid = isomount_table_grid;
    }else{
      sels = isomount_grid.getSelectionModel().getSelections();
      now_grid=isomount_grid;
    }
*/    
  Ext.Msg.confirm("<{$words.isomount_title}>","<{$words.check_unmount}>",function(btn){
    if(btn=='yes') 
    {
      if(sels.length==0){
        Ext.Msg.show({
         title:'<{$words.isomount_title}>',
         msg: '<{$words.no_select_file}>',
         buttons: Ext.Msg.OK,
         icon: Ext.MessageBox.ERROR
        });          
        return 0;
      }  
      for( var i = 0; i < sels.length; i++ ) {
        seltext += sels[i].get('point') + String.fromCharCode(26);
      }
      seltext = seltext.substring(0,(seltext.length-1));   
      //document.getElementById('umount_iso_data').value=escape(seltext).replace(/\+/g,String.fromCharCode(27));
      document.getElementById('umount_iso_data').value=encodeURIComponent(seltext);
      processAjax('setmain.php?fun=setunmountiso',execute_unmount_iso_result,document.getElementById('isomount_tmp'));
    }  
  });
}

/*
* execute unmount all iso.
* @returns none.
*/
function unmount_all_iso(){
  document.getElementById('unmount_all_flag').value=1;


  Ext.Msg.confirm("<{$words.isomount_title}>","<{$words.check_unmount_all}>",function(btn){
    if(btn=='yes') 
    {
      processAjax('setmain.php?fun=setunmountiso',execute_unmount_iso_result,document.getElementById('isomount_tmp'));
    } 
  });
}

/*
* show result after execute add a iso mount.
* @returns none.
*/
function execute_add_isomount_result(){
  var request = eval('('+this.req.responseText+')');
  var tmp_str,str="";
  if(request.show){
    mag_box(request.topic,request.message,request.icon,request.button,request.fn,request.prompt);
  }  
}
  
/*
* execute add a iso point.
* @returns none.
*/    
function add_isomount(){
  Ext.Msg.confirm("<{$words.isomount_title}>","<{$words.check_mount}>",function(btn){
    if(btn=='yes'){
      //processAjax('setmain.php?fun=setaddisomount',execute_add_isomount_result,iso_mount_panel.getForm().getValues(true)+"&root_folder="+escape(share_folder.getValue()).replace(/\+/g,String.fromCharCode(27)));
      processAjax('setmain.php?fun=setaddisomount',execute_add_isomount_result,iso_mount_panel.getForm().getValues(true)+"&root_folder="+encodeURIComponent(share_folder.getValue()));
    }
  });
  isomount_grid.storeReload();
}  

//share folder info  
var share_folder_store=new Ext.data.JsonStore({
  fields: ['value','display'],
  data:<{$share_folder}>
});

//select share folder combox
var share_folder =  new Ext.form.ComboBox({
  store: share_folder_store,
  valueField :"value",
  displayField:"display",
  mode: 'local',
  forceSelection: true,
  editable: false,
  triggerAction: 'all',
  hiddenName:'_folder',
  hideLabel:true,
  listWidth:300,
//    value:'<{$f_folder_name}>',
  width:80    
});

//listwidth  auto expand to max width
/*  share_folder.on('expand', function( comboBox ){
    comboBox.list.setWidth( 'auto' );
    if (!window.ActiveXObject)
        comboBox.innerList.setWidth( 'auto' );
  }, this, { single: true });
*/

//when share folder will select , will pop this folder window
share_folder.on('select', function( comboBox ,record,index ){
  now_loc=1;
  now_grid = isomount_table_grid;
  document.getElementById('root').value=comboBox.getValue();
  update_grid_data(0);
  now_grid.getBottomToolbar().paramNames={start:'start', limit:'limit', roots:comboBox.getValue()};
  Window_iso.show();
  iso_filter_checkbox.setValue(true);
  tree.collapseAll();
  tree.getSelectionModel().clearSelections();
  tree.getRootNode().id=comboBox.getValue();
  tree.getRootNode().setText(comboBox.getValue());
  tree.getRootNode().expand();  
});


/*var share_form = new Ext.FormPanel({
//    width:100, 
  method: 'POST',
  waitMsgTarget : true,
  hideBorders:false,
  items: [share_folder]
}); 
*/

/*
* create a grid.
* @param value: grid id
* @param width: grid width
* @param height: grid height
* @param autoheight: grid autoheight
* @param col1: col 1 width
* @param col2: col 2 width
* @param col3: col 3 width
* @param pagesize: grid show data size in per page
* @returns Ext.grid.GridPanel
*/
function create_iso_mount_grid(value,width,height,autoheight,col1,col2,col3,pagesize){
  store = new Ext.data.JsonStore({
    root: 'topics',
    totalProperty: 'totalcount',
    remoteSort: true,
    url:'<{$url}>',
    fields: ['point','iso','size']
  });

  store.setDefaultSort('point', 'Desc');
   
  var pagingBar = new Ext.PagingToolbar({
    pageSize: pagesize,
    store: store,
    displayInfo: true,
    displayMsg: '<{$words.page_range}> {0} - {1} <{$gwords.page2}> {2}',
    emptyMsg: "<{$words.no_data}>",
    beforePageText:"<{$gwords.page1}>",
    afterPageText:"<{$gwords.page2}> {0} <{$gwords.page3}> "
  });

  var iso_tbar =new Ext.Toolbar({
    items :[{
             text:'<{$gwords.unmount}>',
             iconCls:'remove',
             <{if $isomount_count==0}>
             disabled:true,
             <{/if}>              
             handler:unmount_iso
           }/*, '-',{
             text:'<{$gwords.unmount_all}>',
             iconCls:'option',
             <{if $isomount_count==0}>
             disabled:true,
             <{/if}>
             handler:unmount_all_iso
           }*/]
  });

  var sm = new Ext.grid.CheckboxSelectionModel();
  var isomount_grid = new Ext.grid.GridPanel({
//    el:'log',
    width:width,
    height:height,
    autoHeight:autoheight,
    store: store,
    trackMouseOver:false,
    disableSelection:true,
    loadMask: true,
      
   // grid columns
    columns:[sm,{
               header: '<{$words.isomounted_path}>',
               dataIndex: 'point',
               width: col1,
               sortable: true
             },{
               header: '<{$words.iso_path}>',
               dataIndex: 'iso',
               width: col2,
               sortable: true
            },{
               header: '<{$words.iso_size}>',
               dataIndex: 'size',
               width: col3,
               sortable: true
            }
           ],
    sm:sm,
    tbar:iso_tbar,
     // paging bar on the bottom
    bbar: pagingBar
  });
  
  isomount_grid.storeReload = function(){
   store.reload();
  };
  
  return isomount_grid;
}

var isomount_grid=create_iso_mount_grid(1,754,330,false,325,325,75,<{$limit1}>);

//check record is empty if empty top toolbar will not use
isomount_grid.getStore().on('load',function(obj,records){    
  if(records=='') 
    isomount_grid.getTopToolbar().setDisabled(true);
  else 
    isomount_grid.getTopToolbar().enable();
});   

//show isomount first page table 
var isomount_table = new Ext.Panel({
  layout:'table',
  name:'share_folder_table',
  defaults: {
      // applied to each contained panel
      bodyStyle:'padding:5px'
  },
  layoutConfig: {
      // The total column count must be specified here
      columns: 1
  },
  items: [{    
            height:30,      
            items:[share_folder]
          }/*,{
            width:500,
            height:30,
            items:[share_select]
          }*/,{
           //  colspan: 2,
            items:[isomount_grid]
          }]
}); 

//show isomount page 
var isomount_panel = TCode.desktop.Group.addComponent({
  xtype: 'panel',
  items: [
    {
      xtype:'fieldset', 
      title:'<{$words.isomount_title}>',
      autoHeight:true,
      defaultType: 'table',
      collapsed: false,   
      items:[isomount_table]
    },{
            xtype:'fieldset', 
            height:50,
            title:'<{$gwords.description}>',            
            items:[{
                    //style:'margin-top:0px',
                    html:'&nbsp;<{$isomount_desp}>'            
                  }]
          
    }]
});
isomount_panel.on('beforedestroy',function(){
    isomount = {};
    delete isomount;
    share_folder_store.destroy();
    //loader
    Window_iso.destroy();
});

//iso filter checbox to check will show outside of iso file
var iso_filter_checkbox=new Ext.form.Checkbox({
  fieldLabel: '<{$words.iso_Filter}>',
  boxLabel: '<{$words.iso_Filter}>',
  name: 'ISO_filter'
});

//folder tree top toolbar   
var iso_tree_tbar=new Ext.Toolbar({
  items :[iso_filter_checkbox]
});

var isomount = {};
function onComponentReady(ct) {
    if (ct.cname) {
        isomount[ct.cname] = ct;
    }
}
//iso mount point input info form  
var iso_mount_panel=new Ext.FormPanel({
 width: 278,
 height:128,
 method: 'POST',
 waitMsgTarget : true,
//     height:30,
 frame:true,
 labelWidth:80,
 defaults: {
     listeners: {
         render: onComponentReady
     }
 },
 buttonAlign :'left',
 items: [{
            xtype:'textfield',
            cname:'iso_path',
            name:'iso_path',
            width:180,
            style:'margin-top:1px',            
            fieldLabel: '<{$words.file_selected}>'
           },{
            xtype:'textfield',
            cname:'mount_path',
            name:'mount_path',
            width:180,
            fieldLabel: '<{$words.mount_as}>'
           }],
   buttons : [{
              text : '<{$gwords.add}>',
              disabled : false,
              handler : function() {
                if (iso_mount_panel.getForm().isValid()) {
                  add_isomount();
                } 
              }
           }]
}); 

//share folder tree loader
var loader=new Ext.tree.TreeLoader({
   //   preloadChildren : true ,
      dataUrl: '<{$url_iso_add}>'+iso_filter_checkbox.getValue()
});

//share folder tree
var tree = new Ext.tree.TreePanel({
    useArrows:true,
    autoScroll:true,
    animate:true,
    enableDD:false,
    containerScroll: true,
    selModel : new Ext.tree.MultiSelectionModel(),
    frame : true,
    singleExpand : true,
    // auto create TreeLoader        
    loader:loader,
    tbar:iso_tree_tbar,
    height:350,
    border:true,
    root: {
        nodeType: 'async',
        text: '<{$f_folder_name}>',
        draggable:false,
        id:'<{$f_folder_name}>'
    }
});

//when tree click will change iso_path value
tree.on('click',function(node,el){
  //var isomount.iso_path='',tmp_path,file_level;
  if(!node.hasChildNodes()){
    isomount.iso_path.setValue('/'+node.id);
  }else{
    isomount.iso_path.setValue('');
  }
});
    
//when iso_filter_checkbox will checked ,tree will reexpaned
iso_filter_checkbox.on('check',function(obj,newvalue){
   tree.loader.dataUrl='<{$url_iso_add}>'+newvalue;
   //loader.load(tree.getRootNode());    
   tree.collapseAll();
   tree.getRootNode().expand();
 });    

//before tree expand node will reload folder data
tree.on('beforeexpandnode',function(node){     
   loader.load(node);
   document.getElementById('expand_folder').value=node.id;
   isomount.iso_path.setValue('');
});

//before tree collapse node will clear expand_folder record
tree.on('beforecollapsenode',function(node){     
  document.getElementById('expand_folder').value='';
});

/*   tree.on("append",function(root, parentNode, node, index){
     var tmp_str,str;
     tmp_str=before_path.split("/");
     str=tmp_str[0];
     for(var i=1;i<tmp_str.length;i++){
       str=str+"/";
       str=str+tmp_str[i];
       if (node.id == str){          
          node.expand();
          break;
       }
     }

   }
);*/

/*   tree.on('expandnode',function(node){       
     document.getElementById('expand_folder').value=node.id;     
   });
*/

var isomount_table_grid=create_iso_mount_grid(2,575,355,false,240,240,70,<{$limit}>)
//check record is empty if empty top toolbar will not use
isomount_table_grid.getStore().on('load',function(obj,records){    
  if(records=='') 
    isomount_table_grid.getTopToolbar().setDisabled(true);
  else 
    isomount_table_grid.getTopToolbar().enable();
});

var info_height;
if(Ext.isIE){
  info_height= 385;
  tree_height= 505;
  window_height=575;
}else{
  info_height= 405;
  tree_height= 515;
  window_height=565;
}
var folders = String.format('<{$words.top_50_folders}>', '<{$isomount}>')
var files = String.format('<{$words.top_50_files}>', '<{$isomount}>')
//when select share folder ,and iso table will show
var iso_table = new Ext.Panel({
   layout:'table',
   frame:true,
   height:530,
   
   layoutConfig: {
      // The total column count must be specified here
      columns: 2
   },
   defaults: {
      // applied to each contained panel
      //bodyStyle:'padding:0px'
   },

   items:[{ 
            rowspan: 2,
            xtype:'fieldset', 
            title:'<{$words.current_dir}>',       
            height:tree_height,
            width:300,
            defaultType: 'table',
            collapsed: false,
            defaults: {
      // applied to each contained panel
              bodyStyle:'padding:0px'
           },
            items:[tree,iso_mount_panel]
           },{
            xtype:'fieldset', 
            title:'<{$words.information}>',
            height:info_height,
            width:600,
            defaultType: 'table',
            collapsed: false,
            style:'margin-left:5px;',
            items:isomount_table_grid                    
           },{
            xtype:'fieldset', 
            style:'margin-left:5px',
            title:'<{$gwords.description}>',
            width:600,
            height:100,
            items:[{html:"<{$words.Table_desp}><br>"+folders+"<br>"+files+"<br><{$words.manually_path}>"}]
           }]
 
 
});  

//windows pop
var Window_iso= new Ext.Window({  
  title:'<{$words.Table_title}>',
  closable:true,
  closeAction:'hide',
  width: 935,
  height:window_height,
  layout: 'fit',  
  plain: true ,
  modal: true , 
  draggable:false,
  items: iso_table 
});



Window_iso.on("hide",function(obj,value){
  now_loc=0;    
  now_grid=isomount_grid;
  document.getElementById('root').value='';
  update_grid_data(0);
  isomount.iso_path.setValue('');
  before_path='';
});    
      
      
isomount_grid.store.load({params:{start:0, limit:<{$limit1}>}});
isomount_grid.getSelectionModel().on('rowdeselect',function(thisobj,rowindex,record){
                                                     isomount_grid.getColumnModel().setColumnHeader(0,'<div class="x-grid3-hd-checker"> </div>');
                                     });  
isomount_grid.getSelectionModel().on('rowselect',function(thisobj,rowindex,record){
                                                   if(thisobj.getCount() == isomount_grid.store.getCount())
                                                     isomount_grid.getColumnModel().setColumnHeader(0,'<div style="" unselectable="on" class="x-grid3-hd-inner x-grid3-hd-checker x-grid3-hd-checker-on"><a href="#" class="x-grid3-hd-btn"/><div class="x-grid3-hd-checker"> </div><img src="../theme/images/s.gif" class="x-grid3-sort-icon"/></div>');
                                     });                                            
isomount_table_grid.getSelectionModel().on('rowdeselect',function(thisobj,rowindex,record){
                                                           isomount_table_grid.getColumnModel().setColumnHeader(0,'<div class="x-grid3-hd-checker"> </div>');                                             
                                           });
                                                
isomount_table_grid.getSelectionModel().on('rowselect',function(thisobj,rowindex,record){
                                                         if(thisobj.getCount() == isomount_table_grid.store.getCount())
                                                           isomount_table_grid.getColumnModel().setColumnHeader(0,'<div style="" unselectable="on" class="x-grid3-hd-inner x-grid3-hd-checker x-grid3-hd-checker-on"><a href="#" class="x-grid3-hd-btn"/><div class="x-grid3-hd-checker"> </div><img src="../theme/images/s.gif" class="x-grid3-sort-icon"/></div>');
                                           });  
var now_grid=isomount_grid;
</script>
