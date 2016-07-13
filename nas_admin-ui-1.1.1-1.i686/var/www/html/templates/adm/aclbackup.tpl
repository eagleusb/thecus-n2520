<form name="restore_tmp" id="restore_tmp" method="post">
<input type=hidden name="restore_data" id="restore_data" value="">
</form>

<script language="javascript">
var acl_fs=<{$aclbackup_raid_fs}>;
var process_lock;
var pid;
Ext.form.FileUploadField = Ext.extend(Ext.form.TextField,  {
    /**
     * @cfg {String} buttonText The button text to display on the upload button (defaults to
     * 'Browse...').  Note that if you supply a value for {@link #buttonCfg}, the buttonCfg.text
     * value will be used instead if available.
     */
    buttonText: 'Browse...',
    /**
     * @cfg {Boolean} buttonOnly True to display the file upload field as a button with no visible
     * text field (defaults to false).  If true, all inherited TextField members will still be available.
     */
    buttonOnly: false,
    /**
     * @cfg {Number} buttonOffset The number of pixels of space reserved between the button and the text field
     * (defaults to 3).  Note that this only applies if {@link #buttonOnly} = false.
     */
    buttonOffset: 3,
    /**
     * @cfg {Object} buttonCfg A standard {@link Ext.Button} config object.
     */

    // private
    readOnly: true,

    /**
     * @hide
     * @method autoSize
     */
    autoSize: Ext.emptyFn,

    // private
    initComponent: function(){
        Ext.form.FileUploadField.superclass.initComponent.call(this);

        this.addEvents(
            /**
             * @event fileselected
             * Fires when the underlying file input field's value has changed from the user
             * selecting a new file from the system file selection dialog.
             * @param {Ext.form.FileUploadField} this
             * @param {String} value The file value returned by the underlying file input field
             */
            'fileselected'
        );
    },

    // private
    onRender : function(ct, position){
        Ext.form.FileUploadField.superclass.onRender.call(this, ct, position);

        this.wrap = this.el.wrap({cls:'x-form-field-wrap x-form-file-wrap'});
        this.el.addClass('x-form-file-text');
        this.el.dom.removeAttribute('name');

        this.fileInput = this.wrap.createChild({
            id: this.getFileInputId(),
            name: this.name||this.getId(),
            cls: 'x-form-file',
            tag: 'input',
            type: 'file',
            size: 1
        });

        var btnCfg = Ext.applyIf(this.buttonCfg || {}, {
            text: this.buttonText
        });
        this.button = new Ext.Button(Ext.apply(btnCfg, {
            renderTo: this.wrap,
            cls: 'x-form-file-btn' + (btnCfg.iconCls ? ' x-btn-icon' : '')
        }));

        if(this.buttonOnly){
            this.el.hide();
            this.wrap.setWidth(this.button.getEl().getWidth());
        }

        this.fileInput.on('change', function(){
            var v = this.fileInput.dom.value;
            this.setValue(v);
            this.fireEvent('fileselected', this, v);
        }, this);
    },

    // private
    getFileInputId: function(){
        return this.id+'-file';
    },

    // private
    onResize : function(w, h){
        Ext.form.FileUploadField.superclass.onResize.call(this, w, h);

        this.wrap.setWidth(w);

        if(!this.buttonOnly){
            var w = this.wrap.getWidth() - this.button.getEl().getWidth() - this.buttonOffset;
            this.el.setWidth(w);
        }
    },

    onDisable: function(){
        Ext.form.FileUploadField.superclass.onDisable.call(this);
        this.doDisable(true);
    },

    onEnable: function(){
        Ext.form.FileUploadField.superclass.onEnable.call(this);
        this.doDisable(false);
    },

    // private
    doDisable: function(disabled){
        this.fileInput.dom.disabled = disabled;
        this.button.setDisabled(disabled);
    },

    // private
    preFocus : Ext.emptyFn,

    // private
    getResizeEl : function(){
        return this.wrap;
    },

    // private
    getPositionEl : function(){
        return this.wrap;
    },

    // private
    alignErrorIcon : function(){
        this.errorIcon.alignTo(this.wrap, 'tl-tr', [2, 0]);
    }

});
Ext.reg('fileuploadfield', Ext.form.FileUploadField);

/**
 *  disable content panel load Mask
 *
 * @param none
 */
function disable_loadMask(){
    if (Ext.getCmp("content-panel").loadMask){
         Ext.getCmp("content-panel").loadMask.hide();
         delete Ext.getCmp("content-panel").loadMask;
         Ext.getCmp("content-panel").loadMask=null;
    }
}

Ext.onReady(function(){
    Ext.QuickTips.init();
    
    /**
     *  after execute downlaod, will execute alert msg or download file
     *
     * @param none
     */
    function onAclDownload(){
        var request = eval('('+this.req.responseText+')');
        var result=request.result;
        var msg=request.msg;
        var icon=request.icon;
        var mdnum=request.mdnum;

        if (result == 0){
            window.open('../adm/getmain.php?fun=d_aclbackup&mdnum='+mdnum,'_self');
        }else{
            mag_box("<{$words.aclbackup_title}>",msg,icon,'OK','','');
        }
    }

    /**
     *  mask content-panel body
     *
     * @param none
     */
    function newloadMask(){
        Ext.getCmp("content-panel").loadMask = new Ext.LoadMask(
            Ext.getCmp("content-panel").body,
            {msg:"<{$words.aclbackup_restoring}>"}
        );
        Ext.getCmp("content-panel").loadMask.show();
    }

    /**
     *  when acl restore , check does fininsh
     *
     * @param none
     */
    function check_restore_result(){
        var request = eval('('+this.req.responseText+')');
        var result=request.result;
        var lock=request.lock;
        var msg=request.msg;
        var icon=request.icon;

        
        if (lock == 1){
            pid=setTimeout(function(){
                processAjax('<{$getform_action}>&do_act=check_lock',check_restore_result);
            },3000);
        }else{
            disable_loadMask();
            mag_box("<{$words.aclbackup_title}>",msg,icon,'OK','','');
        }
    
    }

    function share_name(value){
        return decodeURIComponent(value); 
    }
    
    /**
     *  alert restore result or wait result
     *
     * @param none
     */
    function execute_restore_result(){
        var request = eval('('+this.req.responseText+')');
        var result=request.result;
        var msg=request.msg;
        var icon=request.icon;
    
        if (result == 0){
            Window_folder.hide();
            newloadMask();
            pid=setTimeout(function(){
                processAjax('<{$getform_action}>&do_act=check_lock',check_restore_result);
            },3000);
        }else{
            mag_box("<{$words.aclbackup_title}>",msg,icon,'OK','','');
            Window_folder.hide();
        }
    }

    /**
     *  execute acl restore
     *
     * @param none
     */
    function restore(){
        var seltext='';
        sels = grid.getSelectionModel().getSelections(); 
        Ext.Msg.confirm("<{$words.aclbackup_title}>","<{$gwords.confirm}>",function(btn){
            if(btn=='yes') 
            {
                if(sels.length==0){
                    Ext.Msg.show({
                        title:"<{$words.aclbackup_title}>",
                        msg: "<{$words.no_select_file}>",
                        buttons: Ext.Msg.OK,
                        icon: Ext.MessageBox.ERROR
                    });          
                    return 0;
                 }  
                
                for( var i = 0; i < sels.length; i++ ) {
                    seltext += decodeURIComponent(sels[i].get('share_name')) + String.fromCharCode(10);
                }
                document.getElementById('restore_data').value=Ext.util.JSON.encode(seltext);
                processAjax('<{$form_action}>',execute_restore_result,document.getElementById('restore_tmp'));
            }
        });
    }
    
    /**
     *  This is backup/enable radio object
     *
     * @param none
     */
    var aclbackup_radiogroup = new Ext.form.RadioGroup({
        xtype: 'radiogroup',
        width:300,
        columns: 2,
        fieldLabel: "<{$words.acl_field}>",
        listeners: {change:{fn:function(obj,chk)
                               {
                                   if ( chk == '1'){
                                       Ext.getCmp("form-file").setDisabled(true);
                                       Ext.getCmp("_recursive").setDisabled(true);
                                       Ext.getCmp("_apply").setText("<{$gwords.apply}>");
                                   }else{
                                       Ext.getCmp("form-file").setDisabled(false);
                                       Ext.getCmp("_recursive").setDisabled(false);
                                       Ext.getCmp("_apply").setText("<{$gwords.next}>");
                                   }
                                }
                            }
                    },
        items: [
                   {boxLabel: "<{$words.backup}>", name: '_aclradio', inputValue: 1 , checked:true},
                   {boxLabel: "<{$words.restore}>", name: '_aclradio', inputValue: 0}
                ]
    });

    /**
     *  This is raid information store object
     *
     * @param none
     */
    var raid_store = new Ext.data.SimpleStore({
        fields: <{$aclbackup_raid_fields}>,
        data: <{$aclbackup_raid_data}>
    });

    /**
     *  This is raid information combox object
     *
     * @param none
     */
    var raid_combo = new Ext.form.ComboBox({
        xtype: 'combo',
        name: '_raid',
        hiddenName: '_raid_selected',
        fieldLabel: "<{$words.acl_raid}>",
        mode: 'local',
        store: raid_store,
        displayField: 'display',
        valueField: 'value',
        readOnly: true,
        typeAhead: true,
        selectOnFocus:true,
        triggerAction: 'all',
        listWidth:100,
        value:'<{$raid_first}>',
        listeners: {select:{fn:function( comboBox ,record,index )
                               {
                                   document.getElementById('fs_desp').innerHTML="<div><{$words.fs}>:"+acl_fs[index]+"</div>";
                               }
                           }
                    }
    });

    /**
     *  This is display UI form panel object
     *
     * @param none
     */
    var fp = TCode.desktop.Group.addComponent({
        xtype: 'form',
        frame: false,
        fileUpload: true,
        labelWidth: 110,
        autoWidth: 'true',
        
        items: [{
                    xtype:'fieldset',
                    title: "<{$words.aclbackup_title}>",
                    autoHeight: true,
                    layout: 'form',
                    buttonAlign: 'left',
                    autoWidth:'true',
                    items: [
                        aclbackup_radiogroup,
                        {
                            items: [{
                                layout: 'column',
                                border: false,
                                items:[{
                                    columnWidth: '.35',
                                    layout: 'form',
                                    items:raid_combo
                                },{
                                    columnWidth: '.35',
                                    layout: 'form',
                                    xtype:'panel',
                                    id:'fs_desp',
                                    html:"<{$words.fs}>:"
                                }]
                            }]
                        },{
                            xtype: 'fileuploadfield',
                            id: 'form-file',
                            fieldLabel: "<{$gwords.upload}>",
                            emptyText: '',
                            autoWidth: 'true',
                            name: 'config-path',
                            disabled: true,
                            buttonCfg: {
                                text: '  ',
                                iconCls: 'upload-icon'
                            }
                        },{
                           items: [{
                                   layout: 'column',
                                   border: false,
                                   items:[{
                                       columnWidth: '.9',
                                       layout: 'form',
                                       items:[{
                                           xtype: "checkbox",
                                           hideLabel: false,
                                           fieldLabel:"<{$words.recursive}>",
                                           boxLabel: "( <{$words.rec_desp}> )",
                                           id: "_recursive",
                                           name: "_recursive",
                                           value: ""
                                       }]
                                    }]
                            }]
                        }
                    ],
                    buttons: [{
                        text: "<{$gwords.apply}>",
                        id:'_apply',
                        handler: function(){
                            if(fp.getForm().isValid()){
                                if(aclbackup_radiogroup.getValue()=="1"){
                                    if(raid_combo.getValue()!=""){
                                        processAjax('<{$form_action}>',onAclDownload,fp.getForm().getValues(true));
                                    }
                                }else{
                                    if (Ext.getCmp('form-file').getEl().dom.value != ''){
                                        fp.getForm().submit({
                                            url: 'setmain.php?fun=setaclbackup&do_act=upload',
                                            waitMsg: 'Uploading your config...',
                                            scope: Window_folder,
                                            success: Window_folder.success,
                                            failure:Window_folder.fail
                                       }, this);
                                    }else{
                                        mag_box("<{$words.aclbackup_title}>","<{$words.select_file}>",'WARNING','OK','','');
                                    }
                                }
                            }
                        }
                    }]
            },{  /*====================================================================
                        * Description
                  *====================================================================*/
                xtype:'fieldset',
                title: "<{$gwords.description}>",
                autoHeight: true,
                items: [{
                           html:"<li><{$words.raid_limit}></li><li><{$words.raid_restore_limit}></li><{if $nas_key=="1"}><li><{$words.acl_zfs_limit}></li><{/if}><li><{$words.usbhdd_limit}></li><li><{$words.share_limit}></li><li><{$words.stackable_limit}></li>"
                       }]
           }]
    });
    fp.on('beforedestroy', function() {
        //aclbackup_radiogroup.destroy();
        raid_store.destroy();
        //raid_store.destroy();
        //raid_combo.destroy();
        folder_store.destroy();
        //folder_search.destroy();
        //tbar.destroy();
        //grid.destroy();
        //folder.destroy();
        Window_folder.destroy();
        if(pid !=null && pid !="")
            clearTimeout(pid);
        disable_loadMask();
    });

    /**
     *  This is folder list store object
     *
     * @param none
     */
    var folder_store = new Ext.data.SimpleStore({
        fields: <{$aclbackup_folder_fields}>
    });

    /**
     *  when folder_store load data , do thing
     *
     * @param none
     */
    folder_store.on('load', function( obj,record,opt ){
        setTimeout(function(){ 
          if (obj.getCount()!=0){
             sm.selectAll();
          }
        },1);
    });

    /**
     *  This is folder search text field
     *
     * @param none
     */
    var folder_search=new Ext.form.TextField({
        width:100,
        value:'',
        enableKeyEvents:true
    });

    /**
     *  folder_search text field , event keyup do thing
     *
     * @param none
     */
    folder_search.on({'keyup':{
                         fn:function( obj,event ){
                             var count=folder_store.getTotalCount();
                             var i;
                             
                             for(i=0;i<count;i++){
                                 if(folder_store.getAt(i).get('share_name').search(eval("/"+obj.getValue()+"/i")) == 0){
                                     grid.getView().focusRow(count);
                                     grid.getView().focusRow(i);
                                     break;
                                 }
                             }

                             if (i==count)
                                 grid.getView().focusRow(0);
                         },
                         delay:1000
                       }
    });

    /**
     *  This is folder grid tool bar
     *
     * @param none
     */
    var tbar =new Ext.Toolbar({
        items:["<{$gwords.search}>:",folder_search
        ]
    });

    /**
     *  This is folder grid check box selection
     *
     * @param none
     */
    var sm = new Ext.grid.CheckboxSelectionModel({
        header:'<div unselectable="on" class="x-grid3-hd-inner x-grid3-hd-checker x-grid3-hd-checker-on"><div class="x-grid3-hd-checker"> </div><img src="../theme/images/s.gif" class="x-grid3-sort-icon"></div>',
        width:20
    });

    /**
     *  This is folder grid
     *
     * @param none
     */
    var grid = new Ext.grid.GridPanel({
        disableSelection:false,
        store:folder_store,
        enableHdMenu:false,
        height:300,
        width:472,

        cm: new Ext.grid.ColumnModel([
            sm,
            {header: "<{$gwords.folder_name}>", width:425, sortable: true, dataIndex: 'share_name', renderer: share_name}
        ]),
        sm:sm,
        tbar:tbar
    });

    /**
     *  This is folder grid row deselect do thing
     *
     * @param none
     */
    grid.getSelectionModel().on('rowdeselect',function(thisobj,rowindex,record){
                                    grid.getColumnModel().setColumnHeader(0,'<div class="x-grid3-hd-checker"> </div>');
                               });  

    /**
     *  This is folder grid row select do thing
     *
     * @param none
     */
    grid.getSelectionModel().on('rowselect',function(thisobj,rowindex,record){
                                    if(thisobj.getCount() == grid.store.getCount())
                                        grid.getColumnModel().setColumnHeader(0,'<div style="" unselectable="on" class="x-grid3-hd-inner x-grid3-hd-checker x-grid3-hd-checker-on"><div class="x-grid3-hd-checker"> </div><img src="../theme/images/s.gif" class="x-grid3-sort-icon"/></div>');
                                });

     /**
     *  This is folder form
     *
     * @param none
     */
    var folder = new Ext.FormPanel({
        frame: false,
        width: 500,
        height: 400,
        buttonAlign: 'left',
        frame: true  ,
        items: [grid,
        {
            xtype:'label',
            id:'uuid_no',
            style:'color:red',
            hidden:true,
            text:"*<{$words.acl_uuid_not_match}>"
        }],

        buttons: [{
                     text: "<{$words.restore}>",
                     id:'_restore',
                     handler: restore
                 }]
    });

    /**
     *  This is folder window
     *
     * @param none
     */
    var Window_folder= new Ext.Window({
        title:"<{$words.aclbackup_title}>",
        closable:true,
        closeAction:'hide',
        width: 500,
        height:400,
        resizable : false,
        maximized : false,
        layout: 'fit',
        modal: true ,
        draggable:false,
        items:[folder]
    });

    /**
     *  folder window show do thing
     *
     * @param none
     */
    Window_folder.on('show', function(){
        this.folder_list = this.folder_list || {};
        folder_store.loadData(this.folder_list);
        if(this.uuid==""){
            Ext.getCmp("uuid_no").hide();
        }else{
            Ext.getCmp("uuid_no").show();
        }
    });
    
    /**
     *  folder window hide do thing
     *
     * @param none
     */
    Window_folder.on('hide', function(){
        folder_search.setValue('');
    });

    /**
     *  get folder list success do thing
     *
     * @param none
     */
    Window_folder.success=function(fp, o){
       o.response.responseText = o.response.responseText || '{}';
       var request = eval('('+o.response.responseText+')');
       this.folder_list = request.msg.folder_list || {};

       this.uuid=request.msg.uuid;
       this.show();
    };

    /**
     *  get folder list fail do thing
     *
     * @param none
     */
    Window_folder.fail=function(fp, o){
        mag_box("<{$words.aclbackup_title}>",o.result.msg,o.result.icon,'OK','','');
    };


    document.getElementById('fs_desp').innerHTML="<div><{$words.fs}>:"+acl_fs[0]+"</div>";
    Ext.getCmp("form-file").setDisabled(true);
    Ext.getCmp("_recursive").setDisabled(true);

    if("<{$lock}>"=="1"){
        newloadMask();
        pid=setTimeout(function(){
            processAjax('<{$getform_action}>&do_act=check_lock',check_restore_result);
        },3000);
    }
    
    fp.de
});

</script>
