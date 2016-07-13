<div id="dvdContainer"></div>
<script language="javascript">
/**
 * dynamic load CSS
 */
var headID = document.getElementsByTagName("head")[0];
var newCss = document.createElement('link');
newCss.type = 'text/css';
newCss.rel = "stylesheet";
var rand = Math.random(999);
newCss.href = "<{$urlcss}>share.css?"+rand;
headID.appendChild(newCss);

Ext.namespace("TCode.DVD");

WORDS = <{$words}>;
TCode.DVD.Data = <{$obj}>;
TCode.DVD.FMText = {
    location:WORDS.location,
    required:WORDS.required,
    loading:WORDS.loading,
    select:WORDS.select,
    cancel:WORDS.cancel, 
    nofile:WORDS.nofile,
    view:WORDS.view,
    search:WORDS.search,
    search_tip:WORDS.search_tip,
    name:WORDS.name,
    size:WORDS.size,
    type:WORDS.type,
    list:WORDS.list,
    thumbimage:WORDS.thumbimage,
    sort:WORDS.sort
}


/**
 Destroy elements
*/
function ExtDestroy(){ 
    Ext.destroy(
        Ext.getCmp('dvdContainer'),
        Ext.getCmp('grid1'),
        Ext.getCmp('grid2'),
        Ext.getCmp('dupwin')
    );
    for(var obj in TCode.DVD){
        obj = null;
        delete obj;
    }
    TCode.DVD = null;
    delete TCode.DVD;
}


/**
* submit action
* @access public
*/
TCode.DVD.Fun = {
    
    /**
    * submit action
    * @access public
    * @param {object} params
    */
    action: function(params){
        Ext.Ajax.request({
            url:'setmain.php?fun=setdvd',
            params:params,
            success: function(response){
                var obj = Ext.decode(response.responseText);
                if(obj.result == '0'){
                    Ext.Msg.show({title:WORDS.error, msg:obj.msg, icon:Ext.MessageBox.ERROR, buttons:Ext.Msg.OK });
                }else{
                    monitor = setTimeout("processAjax('getmain.php?fun=nasstatus',onloadSysConfig)");
                }
            }
        });
    },
    
    
    /**
    * check duplicate name
    * @access public
    * @param {String} record name
    * @param {object} ext.getcmp
    * @return {Boolean} no more duplicate name return true , otherwise false
    */
    checkDup: function(name, el){
        var count = 0;
        var res = true;
        el.store.each(function(record){ 
            if(name == record.data.name){
                count++;
                if(count == 2){
                    res = false;
                    return false;
                }
            }
        });
        return res;        
    }, 
    
    /**
     * convert size
     * @param {Number} size
     * @returns {Object} size, type, original size
     */
    convert: function(size){
        var type = "KB";
        var csize;
        if(size<1024){
            csize = size;
        }else if(size<1048576){
            type = "MB";
            csize = Math.round((size/1024)*1000000)/1000000
        }else if(size<1073741824){
            csize = Math.round((size/[Math.pow(1024,2)])*1000000)/1000000
            type = "GB";
        }else{
            csize = Math.round((size/[Math.pow(1024,3)])*1000000)/1000000
            type = "TB";
        }
        csize = Math.round(csize*1000)/1000;
        return {"size":csize, "type":type, "org":size};
    },

    /**
     * general disc information 
     * @param {Object} original information format 
     * @param {Object} current page button 
     * @returns {String} disc information
     */
    generalInfo: function(obj, btn){
        var info = WORDS.none;
        var state = '';
        btn.setDisabled(true);
        btn.showConfirm = false;
        
        if(obj.type !== undefined ){
            switch(obj.status){
                case '0':
                    state = WORDS.status0;
                    btn.setDisabled(false);
                    break;
                case '1':
                    state = WORDS.status1;
                    btn.showConfirm = true; //show confirm alert
                    btn.setDisabled(false);
                    break;
                case '2':
                    state = WORDS.status2;
                    break;
                    
            }
            if(state!=''){
                info = obj.type + ' ('+state+')';
            }
        }
        if(obj.size !== undefined && obj.size != ''){
            info += ',　'+WORDS.discspace+':'+obj.size;
        }
        return info;
    },
    
    /**
    * detect disc and speed information
    * @access public
    * @param {Object} labelCom  label information element
    * @param {Object} speedCom  the speed combobox element
    * @param {Object} discCom  the disc combobox element
    * @param {Object} burnBtn  burn button
    * @param {Object} detectBtn  detect button
    * @param {Object} store  speed store
    */
    detect: function(labelCom, speedCom, discCom, burnBtn, detectBtn, store){
        var disc = discCom.getValue();
        speedCom.setDisabled(true);
        detectBtn.setDisabled(true);
        
        if(disc==''){
            labelCom.setValue(TCode.DVD.Fun.generalInfo('', burnBtn));
            speedCom.setValue('');
            detectBtn.setDisabled(false);
            return false;
        }
        labelCom.setValue(WORDS.loadinfo);
        Ext.Ajax.request({
            url:'setmain.php?fun=setdvd',
            params:{ ac:'getinfo', drive:discCom.getValue()},
            success: function(response){
                var obj = Ext.decode(response.responseText);
                labelCom.setValue(TCode.DVD.Fun.generalInfo(obj.info, burnBtn));
                store.loadData({speed:obj.speed});
                if(store.getCount() > 0){
                    speedCom.setValue(store.getAt(store.getCount()-1).get('value'));
                    speedCom.setDisabled(false);
                    detectBtn.setDisabled(false);
                }else{
                    detectBtn.setDisabled(false);
                    speedCom.setValue('');
                }
            }        
        });
        
    }
};


var storeSpeed2 =  new Ext.data.JsonStore({
    url: 'setmain.php?fun=setdvd',
    root:'speed',
    fields: ['display', 'value']
});

var storeSpeed3 =  new Ext.data.JsonStore({
    url: 'setmain.php?fun=setdvd',
    root:'speed',
    fields: ['display', 'value']
});


var storeDrive =  new Ext.data.JsonStore({
    url: 'setmain.php?fun=setdvd',
    root:'drive',
    fields: ['display', 'value']
});

//Ext.form.VTypes['labelVal'] = /[\*\_\:\\\;\'\/]/;
Ext.form.VTypes['labelVal'] = /^[0-9A-Za-z\-]{1,16}$/;
Ext.form.VTypes['labelText'] = WORDS.errorlabel;
Ext.form.VTypes['label'] = function(v){
    return  Ext.form.VTypes['labelVal'].test(v);
}

Ext.form.VTypes['sharenameVal'] = /[\\\/]/;
Ext.form.VTypes['sharenameText'] = WORDS.errorsharename;
Ext.form.VTypes['sharename'] = function(v){
    return !Ext.form.VTypes['sharenameVal'].test(v);
}

/**
 * DVD add burn data in the Grid
 * @extends Ext.tree.ColumnTree
 */
TCode.DVD.Grid = Ext.extend(Ext.tree.ColumnTree, {
//    autoHeight:true,
    height:250,
    frame:true,
    autoScroll:true,
    constructor: function(config){
        config = config || {};
        Ext.apply(this, config);
    },
    initComponent: function() {
        this.root = new Ext.tree.TreeNode({
            id:'0' ,
            text:WORDS.deflabelvalue,
            name:WORDS.deflabelvalue,
            iconCls:'discicon'
        });
        
        this.columns = [
            {
                header:WORDS.name,
                width:370, 
                dataIndex:'name'
            },
            {
                header:WORDS.path,
                width:300,
                dataIndex:'path'
            }
        ];
        this.tbar = new Ext.Toolbar({
            items:[{
                id:this.id+'_add',
                text:WORDS.add,
                iconCls:'add',
                scope:this,
                handler:this.add
            },{
                id:this.id+'_edit',
                text:WORDS.edit,
                iconCls:'edit',
                disabled:true,
                scope:this,
                handler:this.edit
            },{
                id:this.id+'_remove',
                text:WORDS.remove,
                iconCls:'remove',
                disabled:true,
                scope:this,
                handler:this.remove
            },{
                id:this.id+'_removeall',
                text:WORDS.remove_all,
                iconCls:'remove',
                disabled:true,
                scope:this,
                handler:this.removeall
            }]
        });
        this.bbar = new Ext.Toolbar({
            height:25,
            items:[
                {
                    id:this.id+'_load',
                    iconCls:'stop-icon',
                    text: WORDS.loading,
                    hidden:true
                },{
                    xtype:'label',
                    id:this.id+'_label',
                    total:0,
                    style:'font-size:12px;font-weight:bolder',
                    html:WORDS.total+": 0"
                }
            ]
        });
        TCode.DVD.Grid.superclass.initComponent.apply(this, arguments);
        this.on('click', this.rowSelect, this);
        /*
        this.sm = new Ext.grid.RowSelectionModel({
            singleSelect: false
        }); 
        this.on('afteredit', this.afterEdit, this);
        */
    },
    
    /**
     * rename that choose for burning data.
     * @function
     */
    edit: function(){
        
        //popup edit window
        new Ext.Window({
            id:'editwindow',
            title:WORDS.burn,
            width:300,
            height:140,
            resizable: false,
            border:false,
            frames:false,
            layout:'table',
            layoutConfig:{ columns:2 },
            bodyStyle:'padding:10px',
            modal:true,
            defaults:{ cellCls:'space_v'},
            buttonAlign:'center',
            items:[{
                    xtype:'label',
                    text:WORDS.rename+':',
                    style:'font-size:13px'
                },{xtype:'label'},{
                    id:'editname',
                    xtype:'textfield',
                    vtype:'sharename',
                    width:200,
                    value:this.selModel.getSelectedNode().attributes.name
                },{
                    xtype:'label',
                    style:'margin:2px 0px 0px 5px',
                    html:"<img src=\"/theme/images/icons/fam/icon-question.gif\" ext:qtip=\"<span>"+WORDS.faillabellen+"</span>\" />"
                }],
            buttons:[{
                    text: WORDS.apply,
                    scope: this,
                    handler: this.renameApply
                },{
                    text: WORDS.cancel,
                    handler: this.renameClose
                }]
        }).show();
    },
    
    
    /**
     * close rename window
     */
    renameClose: function(){
        Ext.getCmp('editwindow').close();
    },
    
    /**
     * click apply button in rename window
     */
    renameApply: function(){
        var node = this.selModel.getSelectedNode();
        if(node == null){
            node = this.root;
        }
        
        var editEl = Ext.getCmp('editname');
        var editname = editEl.getValue();
        
        // when edit name is root label name
        if(node.id=='0'){
            if(!Ext.form.VTypes.label(editname)|| editname==''){
                editEl.markInvalid (Ext.form.VTypes.labelText);
            }else{
                //rename success
                this.renameUpdate(node, editname, '');
            }
        }else{
            // valid name format
            if(!editEl.isValid() || editEl.getValue()==''){
                return false;
            }
            
            //2. check dupliate name in the same folder level
            var i=0, error=false;
            node.parentNode.cascade(function(nodeall){
                if(i!=0){
                    if(nodeall.attributes.name == editname && node.attributes.name!=editname){
                        editEl.markInvalid (WORDS.duporg);
                        error = true;
                        return false;
                    }
                }
                i++;
            });
            
            if(!error){
                //rename success
                this.renameUpdate(node, editname, node.parentNode.attributes.pname);
            }
        }
    },
    
    
    /**
     * update new name in column tree
     * @param {Object} node
     * @param {String} editname
     */
    renameUpdate: function(node,editname, pname){
        //update current node 
        node.attributes.text = node.attributes.name =editname;
        node.setText(editname);
        if(node.attributes.id!='0'){;
            node.attributes.pname = pname+'/'+editname;
        }else{
            node.attributes.pname = pname;
        }
        
        // update childnode pname
        var i=0;
        node.cascade(function(n){
            if(i>0 ){
                n.attributes.pname = n.parentNode.attributes.pname+'/'+n.attributes.name;
                n.attributes.dir = n.parentNode.attributes.pname;
            }
            i++;
        });
       
        //close window
        Ext.getCmp('editwindow').close();
    },
    
    /**
    * add
    * @access public
    * @param 
    */
    add: function(){  
        // open file manager window
        var fileManager = new Ext.ux.FileManager({
            url:'setmain.php?fun=setdvd&ac=getfiles',
            multiSelect:true,
            title: WORDS.titleadd,
            text:TCode.DVD.FMText
        });
        
        //select files...
        fileManager.on('selectfile',function(files){
            //select current node
            var node = this.selModel.getSelectedNode();
            if(node == null){
                node = this.root;
            }
            var list = [];
            var dup = [];
            for(var i=0;i<files.length;i++){
                var file = files[i]; 
                var path = file.get('url');
                var fname = file.get('text');
                var isFolder = file.get('isFolder');
                var iconCls, pname, dir;
                var obj = {};
                var iconCls = (isFolder) ? 'folder-close': 'list';
                
                if(node.attributes.pname != undefined){
                    pname = node.attributes.pname+'/'+fname;
                    dir = node.attributes.pname+"/";
                }else{
                    pname = fname;
                    dir = '';
                }
                
                obj.id = pname;
                obj.index = i;
                obj.dir = dir;
                obj.name = fname;
                obj.pname = pname;
                obj.isFolder = isFolder;
                obj.path = path;
                obj.iconCls = iconCls;
                
                node.cascade(function(nodeall){
                    if(nodeall.attributes.pname == pname){
                        dup.push({dir:dir, name:fname, index:obj.index});
                        return false;
                    }
                });
                list.push(obj);
            }
            if(dup.length>0){
                var dupwin = new Ext.Window(
                    {
                        id:'dupwin',
                        title:WORDS.burn,
                        width:500,
                        height:400,
                        resizable: false,
                        border:false,
                        frames:false,
                        autoScroll:true,
                        bodyStyle:'padding:10px',
                        layout:'table',
                        modal:true,
                        layoutConfig:{ columns:1 },
                        defaults:{ cellCls:'space_v'},
                        items:[
                            {
                                xtype:'label',
                                html:WORDS.path+':<span style="font-weight:bold">'+dup[0].dir+'</span><BR>'+WORDS.duptitle,
                                colspan:2
                            }
                        ],
                        buttons:[
                            {
                                text:WORDS.apply,
                                scope:this,
                                handler:function(){
                                    var res = true;
                                    var fixdata = '';
                                    for(var i in dup){
                                        if(typeof dup[i] == 'object'){
                                            var fixEl = Ext.getCmp('fix_'+dup[i].index);
                                            
                                            //1. check duplicate name at this page
                                            var c1 = 0;
                                            for(var j in dup){
                                                if(typeof dup[j] == 'object'){
                                                    if(Ext.getCmp('fix_'+dup[i].index).getValue() == Ext.getCmp('fix_'+dup[j].index).getValue()){
                                                        c1++;
                                                        if(c1 > 1){
                                                            Ext.getCmp('fix_'+dup[j].index).markInvalid (WORDS.duplocal);
                                                            res = false;
                                                            break;
                                                        }
                                                    }
                                                }
                                            }
                                            
                                            //2. check dupliate name in the same folder level
                                            node.cascade(function(nodeall){
                                                if(nodeall.attributes.pname == dup[i].dir+fixEl.getValue()){
                                                    fixEl.markInvalid (WORDS.duporg);
                                                    res = false;
                                                    return false;
                                                }
                                            });
                                            
                                            //3. check itself validate
                                            if(!fixEl.isValid()) { res = false;}
                                            
                                            if(!res){ continue; }
                                            
                                            list[dup[i].index].name = fixEl.getValue();
                                            list[dup[i].index].id = dup[i].dir+list[dup[i].index].name;
                                            list[dup[i].index].pname = dup[i].dir+list[dup[i].index].name;
                                        }
                                    }
                                    
                                    if(res){
                                        this.addNode(node, list);
                                        Ext.getCmp('dupwin').close();
                                    }
                                }
                            }
                        ]
                    }
                );
                
                for(var i in dup){
                    if(typeof dup[i] == 'object'){
                        dupwin.add(
                            new Ext.form.TextField(
                                {
                                    width:300,
                                    id:'fix_'+dup[i].index,
                                    value:dup[i].name,
                                    vtype:'sharename',
                                    allowBlank:false,
                                    maxLength:100
                                }
                            )
                        );
                    }
                }
                dupwin.show();
            }else{
                this.addNode(node, list);
            }
        },this); 
        fileManager.show();
    },
    
    
    /**
     * add new data or folder into grid content
     * @private
     * @param {Object} node
     * @param {Array} list
     */
    addNode: function(node, list){
        for(var i in list){
            if(typeof list[i] == 'object'){
                node.appendChild(
                    new Ext.tree.TreeNode(
                        {
                            id:list[i].pname,
                            iconCls:list[i].iconCls,
                            name:list[i].name.replace(/</g, '&lt;'),
                            pname:list[i].pname,
                            dir:list[i].dir,
                            isFolder:list[i].isFolder,
                            uiProvider:Ext.tree.ColumnNodeUI,
                            path:list[i].path
                         }
                    )
                );
            }
        }
        node.expand();
        
        Ext.getCmp(this.id+'_removeall').setDisabled(false);
        
        var data='';
        this.root.cascade(function(nodeall){
            if(nodeall.attributes.id!='0' ){
                data+=nodeall.attributes.path+"|";
            }
        })
                
        Ext.getCmp(this.id+'_load').setVisible(true);
        Ext.getCmp(this.id+'_label').setVisible(false);
        Ext.Ajax.request({
            url:'setmain.php?fun=setdvd',
            params:"ac=makesize&data="+data,
            success:this.renderSize,
            scope:this
        });
    },
    
    /**
     * counting pre-burn data size
     */
    renderSize: function(response){
        Ext.getCmp(this.id+'_load').setVisible(false);
        Ext.getCmp(this.id+'_label').setVisible(true);
        var size = Ext.decode(response.responseText);
        var el = Ext.getCmp(this.id+'_label');
        if(size){
            var sobj = TCode.DVD.Fun.convert(size);
            el.setText(WORDS.total+": "+sobj.size+' '+sobj.type);
        }else{
            el.setText(WORDS.total+': 0');
        }        
        el.total = size;
    },
    

    /**
    * row select
    * @access public
    * @param 
    */
    rowSelect: function(node){
        Ext.getCmp(this.id+'_edit').setDisabled(false);
        
        //remove button....
        // root folder, hide remove btn
        if(node.attributes.id == '0'){
            Ext.getCmp(this.id+'_remove').setDisabled(true);
            Ext.getCmp(this.id+'_add').setDisabled(false);
            return;
        }
        
        Ext.getCmp(this.id+'_remove').setDisabled(false);
        //add button....
        // folder
        if(node.attributes.isFolder){
            Ext.getCmp(this.id+'_add').setDisabled(false);
        // files
        }else{
            Ext.getCmp(this.id+'_add').setDisabled(true);
        }
    },
    
    /**
    * remove
    * @access public
    * @param {object} element
    */
    remove: function(el){
        //remove selection
        this.selModel.getSelectedNode().remove();
        this.selModel.clearSelections();
        
        var data='';
        this.root.cascade(function(nodeall){
            if(nodeall.attributes.id!='0' ){
                data+=nodeall.attributes.path+"|";
            }
        })
                
        Ext.getCmp(this.id+'_load').setVisible(true);
        Ext.getCmp(this.id+'_label').setVisible(false);
        Ext.Ajax.request({
            url:'setmain.php?fun=setdvd',
            params:"ac=makesize&data="+data,
            success:this.renderSize,
            scope:this
        });
            
        //disable remove
        el.setDisabled(true);
        Ext.getCmp(this.id+'_edit').setDisabled(true);
    },
    
    
    /**
    * remove all record
    * @access public
    * @param 
    */
    removeall: function(el){
        var node = this.root
        while(node.firstChild) {
            node.collapse();
            node.removeChild(node.firstChild);
        }
        this.selModel.clearSelections();
        el.setDisabled(true);
        Ext.getCmp(this.id+'_remove').setDisabled(true);
        Ext.getCmp(this.id+'_edit').setDisabled(true);
        Ext.getCmp(this.id+'_label').setText(WORDS.total+': 0');
        Ext.getCmp(this.id+'_label').total = 0;
    },
    
    /**                                                
    * get total size                                       
    * @access public                                                   
    * @return {number} size: size value                 
    */                                                        
    getTotalSize: function(){                        
        var el = Ext.getCmp(this.id+'_label');  
        return parseInt(el.total);                                                                                   
    }  
});


/**
* Data to Disc
*
* @class TCode.DVD.DataToDisc
* @extends Ext.Panel
*/
TCode.DVD.DataToDisc = Ext.extend(Ext.Panel, {
    frame:true,
    iconCls: 'data2disc',
    buttonAlign:'left',
    tabTip:WORDS.title_data2disc,
    autoHeight:true,
    initComponent: function() {
        this.buttons = [
            {
                iconCls: 'burn',
                id:'burn2',
                text:WORDS.burn,
                confirm:0,
                scope:this,
                style:'padding-top:10px',
                handler: this.burnClick
            }
        ];
        this.items = [
            {
                xtype:'label',
                style:'margin-top:20px;margin-left:10px;',
                text:WORDS.titleadd+':'
            },
            new TCode.DVD.Grid({id:'grid2'}),
            {
                layout:'form',
                labelWidth:200,
                style:'padding-top:10px',
                items:[
                    {
                        layout:'table',
                        style:'margin-left:-20px;',
                        layoutConfig:{columns:2},
                        items:[{
                                layout:'table',
                                defaults:{
                                    allowBlank:false,
                                    blankText:WORDS.blanktext
                                },
                                layoutConfig:{columns:2},
                                items:[{
                                    html: WORDS.drive,
                                    style:'margin-left:-10px;',
                                    width: 215
                                },{
                                    id:'comboDisc2',
                                    xtype:'combo',
                                    store:storeDrive,
                                    hideLabel:true,
                                    editable: false,
                                    valueField:'value',
                                    displayField:'display',
                                    mode: 'local',
                                    hideTrigger:false,  
                                    triggerAction: 'all',
                                    scope:this,
                                    listeners:{
                                        select: this.detect
                                    }
    
                                }]
                            },{
                                xtype:'button',
                                text:WORDS.detect,
                                style:'margin-left:10px;',
                                scope:this,
                                id:'detectBtn2',
                                disabled:true,
                                handler:this.detect
                        }]
                    },{
                        xtype:'textfield',
                        fieldLabel:WORDS.discinfo,
                        id:'labelInfo1',
                        cls:'labelText',
                        style:'border: 0px',
                        readOnly:true,
                        width:400,
                        disableKeyFilter:true
                    },{
                        id:'comboSpeed2',
                        xtype:'combo',
                        fieldLabel:WORDS.speed,
                        store:storeSpeed2,
                        labelStyle:'width:auto', 
                        editable: false,
                        valueField:'value',
                        displayField:'display',
                        allowBlank:false,
                        blankText:WORDS.blanktext,
                        mode: 'local',
                        hideTrigger:false,  
                        triggerAction: 'all'
                    },{
                        xtype:'checkbox',
                        id:'verify2',
                        fieldLabel:WORDS.verify,
                        value:WORDS.deflabelvalue
                    }]
            }
        ];
        TCode.DVD.DataToDisc.superclass.initComponent.call(this);
    },
    listeners:{
        render: function(){
            if(storeSpeed2.getCount() > 0){
                Ext.getCmp('comboSpeed2').setValue(storeSpeed2.getAt(storeSpeed2.getCount()-1).get('value'));
            }
            if(storeDrive.getCount() > 0){
                Ext.getCmp('comboDisc2').setValue(storeDrive.getAt(0).get('value'));
            }
        }
    },
    
    /**
    * detect
    * @access public
    * @param 
    */
    detect: function(){
        TCode.DVD.Fun.detect(Ext.getCmp('labelInfo1'), Ext.getCmp('comboSpeed2'), Ext.getCmp('comboDisc2'), Ext.getCmp('burn2'), Ext.getCmp('detectBtn2'), storeSpeed2);
    },
    
    
    /**
    * verify
    * @access public
    * @param 
    */
    burnClick: function() {
    
        //validate
        var data='';
        var errormsg = '';
        var total = Ext.getCmp('grid2').getTotalSize();
        
        if(total<=0){
            errormsg = WORDS.selectdata;
        }else if(Ext.getCmp('comboDisc2').getValue()=='' || Ext.getCmp('comboSpeed2').getValue()==''){
            errormsg = WORDS.enterdata;
        }
 
        Ext.getCmp('grid2').root.cascade(function(nodeall){
            if(nodeall.attributes.id!='0' ){
                var tmp = '"/'+nodeall.attributes.pname+'='+nodeall.attributes.path+'" ';
                tmp = tmp.replace(/^"\/\//,'"/');
                data += tmp;
            }
        })
        data = data.substr(0,(data.length-1));
        
        if(errormsg != ''){
            Ext.Msg.show({ title:WORDS.error, msg:errormsg, icon:Ext.MessageBox.ERROR, buttons:Ext.Msg.OK });
        }else{
            //return true is to show confirm message otherwise false
            if(Ext.getCmp('burn2').showConfirm === true){
                Ext.Msg.confirm(WORDS.burn, WORDS.confirmburn, function(btn){ if(btn == 'yes'){this.toBurn(data);}}, this);
            }else{
                this.toBurn(data);
            }
        }
    }, 
    
    /**
    * burn
    * @access public
    * @param {string} data: add items data
    */
    toBurn: function(data){    
        var verify = (Ext.getCmp('verify2').checked)?'1':'0';
        var label = Ext.getCmp('grid2').root.text;
        var drive = Ext.getCmp('comboDisc2').getValue();
        var speed = Ext.getCmp('comboSpeed2').getValue();
        var total = Ext.getCmp('grid2').getTotalSize();
        var params = {ac:'data2disc', drive:drive, label:label, speed:speed, data:data, verify:verify, totalsize:(total*1024)};
        TCode.DVD.Fun.action(params);
    }
});


/**
* ISO to Disc
*
* @class TCode.DVD.ISOToDisc
* @extends Ext.Panel
*/
TCode.DVD.ISOToDisc = Ext.extend(Ext.Panel, {
    frame:true,
    iconCls: 'iso2disc',
    buttonAlign:'left',
    tabTip:WORDS.title_iso2disc,
    initComponent: function() {
        this.buttons = [{
            iconCls: 'burn',
            text:WORDS.burn,
            scope:this,
            id:'burn3',
            confirm:0,
            style:'padding-top:10px',
            handler: this.burnClick
        }];
        this.items = [
            {
                layout:'table',
                layoutConfig:{columns:3},
                items:[{
                        html:WORDS.isofile+': ',
                        style:'margin-left:-10px',
                        width: 190
                    },{
                        layout:'form',
                        defaults:{
                            allowBlank:false,
                            blankText:WORDS.blanktext
                        },
                        items:[{
                            id:'txtISOFile',
                            xtype:'textfield',
                            hideLabel:true,
                            width:280
                        }]
                    },{
                        xtype:'button',
                        text:WORDS.browse+'...',
                        scope:this,
                        handler:this.browseClick
                    }]
            },{
                layout:'table',
                layoutConfig:{columns:3},
                items:[{
                        html:WORDS.drive+': ',
                        style:'margin-left:-10px',
                        width:190
                    },{
                        layout:'form',
                        defaults:{
                            allowBlank:false,
                            blankText:WORDS.blanktext
                        },
                        items:[{
                            id:'comboDisc3',
                            xtype:'combo',
                            store:storeDrive,
                            hideLabel:true,
                            editable: false,
                            valueField:'value',
                            displayField:'display',
                            mode: 'local',
                            hideTrigger:false,  
                            triggerAction: 'all',
                            scope:this,
                            listeners:{
                                select: this.detect
                            }
                        }]
                    },{
                        xtype:'button',
                        text:WORDS.detect,
                        disabled:true,
                        scope:this,
                        id:'detectBtn3',
                        handler:this.detect
                }]
            },{            
                layout:'form',
                labelWidth:180,
                defaults:{
                    allowBlank:false,
                    blankText:WORDS.blanktext
                },
                items:[
                    {
                        xtype:'textfield',
                        fieldLabel:WORDS.discinfo,
                        id:'labelInfo2',
                        cls:'labelText',
                        style:'border: 0px',
                        readOnly:true,
                        width:400, 
                        disableKeyFilter:true
                    },{
                        id:'comboSpeed3',
                        xtype:'combo',
                        fieldLabel:WORDS.speed,
                        store:storeSpeed3,
                        labelStyle:'width:auto', 
                        editable: false,
                        valueField:'value',
                        displayField:'display',
                        mode: 'local',
                        hideTrigger:false,  
                        triggerAction: 'all'
                    },{
                        xtype:'checkbox',
                        id:'verify3',
                        fieldLabel:WORDS.verify,
                        value:WORDS.deflabelvalue
                    }
                ]
            }
        ];    
        TCode.DVD.ISOToDisc.superclass.initComponent.call(this);
    },
    
    listeners:{
        render: function(){
            if(storeSpeed3.getCount() > 0){
                Ext.getCmp('comboSpeed3').setValue(storeSpeed3.getAt(storeSpeed3.getCount()-1).get('value'));
            }
            if(storeDrive.getCount() > 0){
                Ext.getCmp('comboDisc3').setValue(storeDrive.getAt(0).get('value'));
            }
        }
    },
    
    /**
    * detect
    * @access public
    * @param 
    */
    detect: function(){
        TCode.DVD.Fun.detect(Ext.getCmp('labelInfo2'), Ext.getCmp('comboSpeed3'), Ext.getCmp('comboDisc3'), Ext.getCmp('burn3'), Ext.getCmp('detectBtn3'), storeSpeed3);
    },
    
    
    /**
    * click browse button of ISO file
    * @access public
    * @param 
    */
    browseClick: function() {
        // open file manager window
        var fileManager = new Ext.ux.FileManager({
            url:'setmain.php?fun=setdvd&ac=getfiles',
            onlydir:'0',
            extension:'iso',
            title: WORDS.isodir,
            singleSelect:true,
            multiSelect:false,
            text:TCode.DVD.FMText
        });
        fileManager.on('selectfile',function(files){
            Ext.getCmp('txtISOFile').setValue(files[0].data.url);
        },this); 
        fileManager.show();
    },
    
    /**
    * verify
    * @access public
    * @param 
    */
    burnClick: function() {
    
        //validate
        if(!Ext.getCmp('txtISOFile').isValid() || Ext.getCmp('comboDisc3').getValue()=='' || Ext.getCmp('comboSpeed3').getValue()==''){
            Ext.Msg.show({ title:WORDS.error, msg:WORDS.enterdata, icon:Ext.MessageBox.ERROR, buttons:Ext.Msg.OK });
        }else{
            if(Ext.getCmp('burn3').showConfirm === true){
                Ext.Msg.confirm(WORDS.burn, WORDS.confirmburn, function(btn){ if(btn == 'yes'){ this.toBurn();}}, this);
            }else{
                this.toBurn();
            }
        }        
    },
    
    /**
    * burn
    * @access public
    */
    toBurn: function(){    
        var verify = (Ext.getCmp('verify3').checked)?'1':'0';
        var iso = Ext.getCmp('txtISOFile').getValue();
        var drive = Ext.getCmp('comboDisc3').getValue();
        var speed = Ext.getCmp('comboSpeed3').getValue();
        var params = {ac:'iso2disc', drive:drive, iso:iso, speed:speed, verify:verify};
        TCode.DVD.Fun.action(params);
    }
});


/**
* Disc to ISO
*
* @class TCode.DVD.DiscToISO
* @extends Ext.Panel
*/
TCode.DVD.DiscToISO = Ext.extend(Ext.Panel, {
    frame:true,
    iconCls: 'disc2iso',
    buttonAlign:'left',
    tabTip:WORDS.title_disc2iso,
    initComponent: function() {
        this.buttons = [
            {
                iconCls: 'burn',
                text:WORDS.burn,
                handler: this.burnClick
            }
        ];
        this.items = [
            {
                layout:'form',
                labelWidth:110,
                items:[{
                    id:'comboDisc4',
                    xtype:'combo',
                    store:storeDrive,
                    fieldLabel:WORDS.drive,
                    editable: false,
                    valueField:'value',
                    displayField:'display',
                    mode: 'local',
                    hideTrigger:false,  
                    triggerAction: 'all',
                    allowBlank:false,
                    blankText:WORDS.blanktext
                }]
            },{
                layout:'table',
                layoutConfig:{
                    columns:2
                },
                items:[{
                        layout:'form',
                        items:[{
                            id:'txtISOPath4',
                            xtype:'textfield',
                            fieldLabel:WORDS.isodir,
                            labelStyle:'margin-left:-10px',
                            allowBlank:false,
                            blankText:WORDS.blanktext,
                            width:280
                        }]
                    },{
                        xtype:'button',
                        text:WORDS.browse+'...',
                        scope:this,
                        handler:this.browseClick
                }]
            },{
                layout:'form',
                items:[{
                        xtype:'textfield',
                        fieldLabel:WORDS.isoname,
                        id:'txtISOName4',
                        labelStyle:'width:110px;margin-bottom:10px',
                        value:TCode.DVD.Data.def_isoname,
                        allowBlank:false,
                        blankText:WORDS.blanktext,
                        selectOnFocus:true
                }]
            }
        ];
        TCode.DVD.DiscToISO.superclass.initComponent.call(this);
    },
    
    listeners:{
        render: function(){
            if(storeDrive.getCount() > 1){
                Ext.getCmp('comboDisc4').setValue(storeDrive.getAt(1).get('value'));
            }
        }
    },
    
    /**
    * click browse button
    * @access public
    * @param 
    */
    browseClick: function() {
        var selectDirectory = new Ext.ux.TreePanel({
            url:'setmain.php?fun=setdvd&ac=getfolder',
            target: Ext.getCmp('txtISOPath4'),
            title: WORDS.isodir
        });
        selectDirectory.show();
    },
    
    /**
    * burn
    * @access public
    * @param 
    */
    burnClick: function() {
        //validate
        if(!Ext.getCmp('txtISOPath4').isValid() || !Ext.getCmp('txtISOName4').isValid() || Ext.getCmp('comboDisc4').getValue()==''){
            Ext.Msg.show({ title:WORDS.error, msg:WORDS.enterdata, icon:Ext.MessageBox.ERROR, buttons:Ext.Msg.OK });
        }else{
            var iso = Ext.getCmp('txtISOPath4').getValue()+'/'+Ext.getCmp('txtISOName4').getValue();
            var drive = Ext.getCmp('comboDisc4').getValue();
            var params = {ac:'disc2iso', drive:drive, iso:iso};
            TCode.DVD.Fun.action(params);
        }
    }
});



/**
* Data to ISO
*
* @class TCode.DVD.DataToISO
* @extends Ext.Panel
*/
TCode.DVD.DataToISO = Ext.extend(Ext.Panel, {
    frame:true,
    iconCls: 'data2iso',
    buttonAlign:'left',
    tabTip:WORDS.title_data2iso,
    initComponent: function() {
        this.buttons = [
            {
                iconCls: 'burn',
                text:WORDS.burn,
                handler: this.burnClick
            }
        ];
        this.items = [
            {
                xtype:'label',
                text:WORDS.titleadd+':'
                
            },
            new TCode.DVD.Grid({id:'grid1'}),
            {
                style:'padding-top:10px;',
                layout:'table',
                layoutConfig:{
                    columns:2
                },
                items:[{
                        layout:'form',
                        items:[{
                            id:'txtISOPath1',
                            xtype:'textfield',
                            fieldLabel:WORDS.isodir,
                            labelStyle:'margin-left:-10px',
                            allowBlank:false,
                            blankText:WORDS.blanktext,
                            width:280
                        }]
                    },{
                        xtype:'button',
                        text:WORDS.browse+'...',
                        scope:this,
                        handler:this.browseClick
                }]
            },{
                layout:'form',
                defaults:{
                    allowBlank:false,
                    blankText:WORDS.blanktext
                },
                items:[{
                        xtype:'textfield',
                        id:'txtISOName1',
                        fieldLabel:WORDS.isoname,
                        labelStyle:'width:110px',
                        value:TCode.DVD.Data.def_isoname,
                        selectOnFocus:true
                }]
            }
            
        ];
        TCode.DVD.DataToISO.superclass.initComponent.call(this);
    },
    
    /**
    * click browse button
    * @access public
    * @param 
    */
    browseClick: function() {
        
        // open file manager window
        var fileManager = new Ext.ux.FileManager({
            url:'setmain.php?fun=setdvd&ac=getfiles',
            onlydir:'1',
            title: WORDS.isodir,
            singleSelect:true,
            multiSelect:false,
            text:TCode.DVD.FMText
        });
        fileManager.on('selectfile',function(files){
            Ext.getCmp('txtISOPath1').setValue(files[0].data.url);
        },this); 
        fileManager.show();
    },
    
    /**
    * burn
    * @access public
    * @param 
    */
    burnClick: function() {
    
        //validate
        var errormsg = '';
        var total = Ext.getCmp('grid1').getTotalSize();
        var data = '';
            
        if(total <= 0){
            errormsg = WORDS.selectdata;
        }else if(!Ext.getCmp('txtISOPath1').isValid() || !Ext.getCmp('txtISOName1').isValid()){
            errormsg = WORDS.enterdata;
        }
        

        Ext.getCmp('grid1').root.cascade(function(nodeall){
            if(nodeall.attributes.id!='0' ){
                data += '"/'+nodeall.attributes.pname+'='+nodeall.attributes.path+'" ';
            }
        })
        data = data.substr(0,(data.length-1));
        
        if(errormsg != ''){
            Ext.Msg.show({ title:WORDS.error,  msg:errormsg,  icon:Ext.MessageBox.ERROR,  buttons:Ext.Msg.OK });
        }else{
            var label = Ext.getCmp('grid1').root.text;
            var iso = Ext.getCmp('txtISOPath1').getValue()+'/'+Ext.getCmp('txtISOName1').getValue();
            var params = {ac:'data2iso', iso:iso, label:label, data:data, totalsize:(total*1024)};
            TCode.DVD.Fun.action(params);
        }
    }
});






/**
* DVD Container
*
* @class TCode.DVD.Container
* @extends Ext.TabPanel
*/
TCode.DVD.Container = Ext.extend(Ext.TabPanel, {
    
    /**
     * constructor
     * @param {object} config
     */
    constructor: function(config){
        config = config || {};
        Ext.applyIf(config, {
            renderTo:'dvdContainer',
            plain: true,
            style: 'margin: 10px;',
            id:'dvdContainer',
            border:false,
            deferredRender:false,
            activeTab: 0
        });
        TCode.DVD.Container.superclass.constructor.call(this, config);
    },
    
    initComponent: function() {
        this.items = [
            new TCode.DVD.DataToDisc(),
            new TCode.DVD.ISOToDisc(),
            new TCode.DVD.DataToISO()
            //new TCode.DVD.DiscToISO()
        ];
        TCode.DVD.Container.superclass.initComponent.call(this);
    },
    
    listeners: {
        render: function(){
            if(TCode.DVD.Data.drive !== null ){
                storeDrive.loadData({drive:TCode.DVD.Data.drive});
            }
            
            Ext.getCmp('comboSpeed2').setValue('');
            Ext.getCmp('comboSpeed3').setValue('');
            Ext.getCmp('labelInfo1').setValue(TCode.DVD.Fun.generalInfo('', Ext.getCmp('burn2')));
            Ext.getCmp('labelInfo2').setValue(TCode.DVD.Fun.generalInfo('', Ext.getCmp('burn3')));
        }
    }
});


Ext.onReady(function(){
    Ext.QuickTips.init();
    new TCode.DVD.Container();
});
</script>
