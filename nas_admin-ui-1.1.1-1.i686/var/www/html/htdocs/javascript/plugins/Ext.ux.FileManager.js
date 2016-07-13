/**
* @fileoverview File Manager Extension have created an extension based on Ext JS to select files from the server
* @author Crysfel (http://www.quizzpot.com/2009/06/file-manager-extension/)
* @modify by Heidi 
*
* Example:
*  var fileManager = new Ext.ux.FileManager({
*      url:'setmain.php?fun=setdvd&ac=getfiles',
*      multiSelect:true,
*      title: WORDS.titleadd,
*      text:{
*          location:WORDS.location,
*          required:WORDS.required,
*          loading:WORDS.loading,
*          select:WORDS.select,
*          cancel:WORDS.cancel, 
*          nofile:WORDS.nofile
*      }
*  });
*  
*  TODO: search textfield specific verify
*/

Ext.ns('Ext.ux');

/*
* File explorer window
* 
* @class Ext.ux.FileManager
* @extends Ext.Window
* @access public
*/
var FileManagerViewType = 1; // 1 is dataview, 2 is grid
Ext.ux.FileManager = Ext.extend(Ext.Window,{
    layout: 'border',
    width: 630,
    height:500,
    resizable: false,
    url: '/',
    multiSelect: false,
    singleSelect:false,
    onlydir:'0',
    extension:'',
    modal: true,
    params: {},
    root: '/',
    text: TCode.ux.WORDS,
    
    initComponent: function(){
        if(Ext.isEmpty(this.url)){
            throw this.text.required;
        }
        this.tbar = [
            {
                xtype:'tbfill'
            },{
                iconCls:'view',
                xtype:'tbbutton',
                text:this.text.view,
                scope:this,
                menu:[
                    {scope:this, text:this.text.thumbimage, handler:this.clickThumbMenu},
                    {scope:this, text:this.text.list, handler:this.clickListMenu}
                ]
            },'-',{
                xtype: 'box',
                cls:'search',
                autoEl: {
                    tag: 'div'
                }
            },{
                xtype:'label',
                html:this.text.search
            },':',{
                id:'search',
                xtype:'textfield',
                width:180,
                enableKeyEvents:true,
                emptyText: this.text.search_tip,
                listeners:{
                    scope:this,
                    //delay:200,
                    specialkey: function(f,e){
                        if (e.getKey() == e.ENTER) {
                            this.searchKeyUp(f);
                        }
                    },
                    render: function() {
                        this.el.hover(function(){
                            if( this.tip ) {
                                return;
                            }
                            this.tip = new Ext.ToolTip({
                                target: this.items.get(5).el,
                                html: TCode.ux.WORDS.search_tip
                            });
                        },function(){
                            delete this.tip;
                        },this.topToolbar);
                    }
                }
            }
         ];
        
        this.nav = new Ext.tree.TreePanel({
            region: 'west',
            width:180,
            collapsible: true,
            split: true,
            margins     : '3 0 3 3',
            cmargins    : '3 3 3 3',
            dataUrl: this.url,
            autoScroll: true
        });
        
        
        this.nav.getLoader().on("beforeload", function(treeLoader, node) {
            if(node.attributes.url=== undefined){
                node.attributes.url = '/';
            }
            treeLoader.baseParams = Ext.apply(treeLoader.baseParams, {
                    path:node.attributes.url,
                    onlydir:this.onlydir,
                    extension:this.extension
            });
        },this);
        var rootNode = new Ext.tree.AsyncTreeNode({
            text: this.text.file,
            draggable:false
        });
        this.nav.setRootNode(rootNode);
        
        this.filesStore = new Ext.data.JsonStore({
            url: this.url,
            fields: ['text','url','mainCls','isFolder','id'],
            root: 'files',
            source:[],
            scope:this,
            listeners:{
                load:function(store, record, opt){
                    Ext.getCmp('search').setValue("");
                    this.source = [];
                    for(var i in record){
                        if(typeof record[i] === 'object'){
                            this.source.push(record[i]);
                        }
                    }
                    
                }
            }
        });

        this.tpl = new Ext.XTemplate(
           '<tpl for=".">',
               '<div class="thumb-wrap" title="{text}" ext:qtip="{text}">',
                '<div class="thumb {mainCls}"></div>',
                '<p>{[values.text.replace(/</g,"&lt;")]}</p></div>',
           '</tpl>',
           '<div class="x-clear"></div>'
        );
        
        this.dataview = new Ext.DataView({
                store: this.filesStore,
                tpl: this.tpl,
                hidden:true,
                autoHeight:true,
                multiSelect: this.multiSelect,
                singleSelect: this.singleSelect,
                overClass:'x-view-over',
                itemSelector:'div.thumb-wrap',
                emptyText: this.text.nofile
        });
        
        this.grid = new Ext.grid.GridPanel({
                store: this.filesStore,
                hidden:true,
                height:385,
                width:410,
                border:false,
                stripeRows:true,
                viewConfig:{
                    emptyText:this.text.nofile
                },
                sm:new Ext.grid.RowSelectionModel({singleSelect:this.singleSelect}),
                columns:[
                    { header: '', sortable:true, width:30, menuDisabled:true, renderer:this.gridRenderRow, dataIndex: 'isFolder' },
                    { header: 'name', sortable:true, width:360, menuDisabled:true, dataIndex: 'text'}
                ]
        });
        
        this.filesStore.load({
            params:{
                path: this.root,
                isForMainPanel: true,
                onlydir:this.onlydir,
                extension:this.extension
            }
        });
        

        this.main = new Ext.Panel({
            region: 'center',
            margins   : '3 3 3 0',
            autoScroll: true,
            items: [this.dataview, this.grid]
        });
        
        this.items = [this.nav, this.main];
        
        this.buttons = [
            {text:this.text.select, handler: this.openFile, scope:this},
            {text:this.text.cancel, handler: this.cancel, scope:this}
        ];
        
        Ext.ux.FileManager.superclass.initComponent.apply(this, arguments);
        
        this.nav.on('click',this.clickNode,this);
        this.dataview.on('dblclick',this.dblclick,this);
        this.grid.on('rowdblclick',this.dblclick,this);
        this.filesStore.on('beforeload',function(){this.body.mask(this.text.loading);},this);
        this.filesStore.on('load',function(){
            if(this.body !== undefined){
                this.body.unmask();
            }
        },this);
        
        this.addEvents('selectfile');
    },
    
    gridRenderRow: function(value){
        if(value == true){
            return "<img src='/theme/images/default/tree/folder.gif' />";
        }else{
            return "<img src='/theme/images/default/tree/leaf.gif' />";
        }
    },
    
    clickThumbMenu: function(){
        FileManagerViewType = 1;
        this.grid.setVisible(false);
        this.dataview.setVisible(true);
    },
    
    clickListMenu: function(){
        FileManagerViewType = 2;
        this.grid.setVisible(true);
        this.dataview.setVisible(false);
    },
    
    /**
     * search text field on Key up
     * @param {Object} search text
     */
    searchKeyUp: function(v){
        this.filesStore.removeAll();
        var storerecord = Ext.data.Record.create(['text','url','mainCls','isFolder','id']);
        var data = this.filesStore.source;
        var regex = new RegExp(eval('/'+v.getValue()+'/i'));
        for(var i in data){
            if(typeof data[i] =='object'){
                if(v.getValue()=='' || data[i].data.text.match(regex)){
                    var record = new storerecord({
                        'text':data[i].data.text,
                        'url':data[i].data.url,
                        'mainCls':data[i].data.mainCls,
                        'isFolder':data[i].data.isFolder,
                        'id':data[i].data.id
                        });
                    this.filesStore.add(record);
                }
            }
        }
        this.filesStore.commitChanges();
        Ext.getCmp('search').focus();
    },
    
    /**
     * render layout
     */
    onRender: function(){
        Ext.ux.FileManager.superclass.onRender.apply(this, arguments);
        this.nav.getRootNode().expand();
        var mainview = this.getViewType();
        mainview.setVisible(true);
    },
    
    /**
     * click node
     * @param {Object} node
     * @param {Object} event
     */
    clickNode: function(node,event){
        this.nav.getRootNode().expand();
        var n = this.nav.getNodeById(node.attributes.id);
        if(!Ext.isEmpty(n)){
            n.expand();
        }
        
        this.filesStore.load({
            params: Ext.apply(this.params,{
                path: node.attributes.url,
                isForMainPanel:true,
                onlydir:this.onlydir,
                extension:this.extension
            }),
            scope:this
        });
        
        if(this.nav.getRootNode().id === node.id){
            this.path = '/';
        }else{	
            this.path = node.attributes.url;
        }
    },
        
    dblclick: function(dataview,index,html,event){
            var item = dataview.store.getAt(index);
            if(item.get('isFolder')){
                var node = this.nav.getNodeById(item.get('id'));
                if(!Ext.isEmpty(node)){
                    node.expand();
                    node.select();
                }
                this.clickNode({attributes:{url:item.get('url'),id:item.get('id')}});
            }else{
                this.openFile();
            }
    },
        
    cancel: function(){
        this.close(); 
    },
    
    openFile: function(){
        var mainview = this.getViewType();
        var files = this.getSelectedRecord(mainview);
        if(files.count>0){
            this.fireEvent('selectfile',files.selection);
            this.close();
        }
    },
    
    getSelectedRecord: function(mainview){
        var selection;
        var count=0;
        if(FileManagerViewType == 1){
            selection = mainview.getSelectedRecords();
            count = mainview.getSelectionCount();
        }else{
            var sm = mainview.getSelectionModel();
            count = sm.getCount();
            selection = sm.getSelections();
        }
        return {selection:selection, count:count}
    },
    
    getViewType: function(){
        if(FileManagerViewType == 1){
            return this.dataview;
        }else{
            return this.grid;
        }
    }
});

Ext.reg('tcodefilemanager', Ext.ux.FileManager);
