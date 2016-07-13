<style type="text/css" media="all">
.x-btn td.x-btn-left, .x-btn td.x-btn-right {padding: 0; font-size: 1px; line-height: 1px;}
.x-btn td.x-btn-center {padding:0 5px; vertical-align: middle;}
        .x-form-file-wrap {
	    position: relative;
	    height: 22px;
	}
	.x-form-file-wrap .x-form-file {
		position: absolute;
		right: 0;
		-moz-opacity: 0;
		filter:alpha(opacity: 0);
		opacity: 0;
		z-index: 2;
	    height: 22px;
	}
	.x-form-file-wrap .x-form-file-btn {
		position: absolute;
		right: 0;
		z-index: 1;
	}
	.x-form-file-wrap .x-form-file-text {
	    position: absolute;
	    left: 0;
	    z-index: 3;
	    color: #777;
	}
        .upload-icon {
            background: url('<{$urlimg}>icons/fam/image_add.png') no-repeat 0 0 !important;
        }

        #fi-button-msg {
            border: 2px solid #ccc;
            padding: 5px 10px;
            background: #eee;
            margin: 5px;
            float: left;
        }
</style>

<div id="moduleform"></div> 

<script language="javascript">

// if "Thecus" is in the module's displayName, then this module is system module and user_system=1. Otherwiese, user_system=0.
var user_system=0;
var install_type = '';
var modname = '';
var modurl = '';
var status_time_id = "";


function ExtDestroy(){ 
    Ext.destroy(
        Ext.getCmp('firstGridDropTarget'),
        Ext.getCmp('destGridDropTarget')
    );  
}

Ext.form.FileUploadField = Ext.extend(Ext.form.TextField,  {
    /**
     * @cfg {String} buttonText The button text to display on the upload button (defaults to
     * 'Browse...').  Note that if you supply a value for {@link #buttonCfg}, the buttonCfg.text
     * value will be used instead if available.
     */
    buttonText: 'Browse...',
    /**
     * @cfg {Boolean} buttonOnly True to display the fil    e upload field as a button with no visible
     * text field (defaults to false).  If true, all inherited TextField members will still be available.
     */
    buttonOnly: false,
    
    buttonHidden: false,
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

        if(this.buttonHidden){
            this.button.hide();
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

// shared reader
var reader = new Ext.data.ArrayReader({}, [
    {name: 'Id'}
   ,{name: 'Name'}
   ,{name: 'DisplayName'}
   ,{name: 'Version'}
   ,{name: 'Description'}
   ,{name: 'Enable'}
   ,{name: 'mode'}
   ,{name: 'ui'}
]);

// create the data store
var store = new Ext.data.Store({
	reader: reader
});

returnAutoModuleData("<{$moduleData}>");

// check if there is any progress running
check_module_progress();

function check_module_progress () {
	status_type = "<{$lock_type}>";
	module_name = "";
	if (status_type !== "") {
		reloadStatus("no");
	}
}

function returnAutoModuleData(moduleData){
	if (!moduleData || moduleData.length <= 0) {
		store.loadData('');
	} else {
		var folderData = new Array();
		folderData = moduleData.split(",");

		var folderData2 = new Array();
		var c=8;
		for (i=0; i<(folderData.length/c); i++) {
			folderData2[i] = new Array(folderData[i*c], folderData[i*c+1], folderData[i*c+2], folderData[i*c+3], folderData[i*c+4], folderData[i*c+5],folderData[i*c+6],folderData[i*c+7]);
		}
		store.loadData(folderData2);
	}
}

//id=SVN
function insertNode(id) { 
    var newNode = new Ext.tree.TreeNode({
        text:id,
        id:id,
        leaf:true,
        iconCls:'treenode-icon',
        listeners:{
            click:function(){  
               window.open("module.php?Module="+id);
               // changePageModule(id,'module','');
            }
        }
                                                   
    });
    var nodeflag = (user_system=='1')?1:2;
    Ext.getCmp('tree_mudule').root.childNodes[nodeflag].expand();
    Ext.getCmp('tree_mudule').root.childNodes[nodeflag].appendChild(newNode);
}
function removeNode(id){
    var nodeflag = (user_system=='1')?1:2;
    Ext.getCmp('tree_mudule').root.childNodes[nodeflag].expand();
    var node = Ext.getCmp('tree_mudule').root.childNodes[nodeflag].childNodes;
    for(var i=0;i<node.length;i++){
        if(node[i].id==id){
            node[i].remove();
        }
    }
}

function returnModuleData(){
	var request = eval('('+this.req.responseText+')');

	if (request.msg == '') {
		returnAutoModuleData(request.moduleData2);
	} else {
		msg('<{$words.module_title}>', request.msg);
	}
}
    
    var msg = function(title, msg){
        Ext.Msg.show({
            title: title, 
            msg: msg,
            minWidth: 200,
            modal: true,
            icon: Ext.Msg.INFO,
            buttons: Ext.Msg.OK
        });
    };

    function DespForm(){
        Window_Modesp.show();
        myMask.hide();
        var request = eval('('+this.req.responseText+')');
        Ext.getDom('desp_name').value=request.name;
        Ext.getDom('desp_version').value=request.version;
        Ext.getDom('desp_description').value=request.description;
        Ext.getDom('desp_size').value=request.size;
        Ext.getDom('desp_authors').value=request.authors;
        Ext.getDom('desp_web').value=request.web;
        Ext.getDom('desp_license').value=request.license;
        Ext.getDom('desp_acknowledgments').value=request.acknowledgments;
    }

function smart_display(moduleName){
	processAjax('setmain.php?fun=setauto_module_desp&module='+moduleName,DespForm);
}

function check_lock(type, mod_name, url, display_name) {
	myMask.hide();
	install_type = type;
	Ext.getCmp("modname").setValue(mod_name);
	Ext.getCmp("display_name").setValue(display_name);
	modurl = url;
	Ext.getCmp("prefix").setValue('check_lock');
	processAjax('<{$form_action}>',install,Ext.getCmp("fpModule").getForm().getValues(true));
}

function install(){
//	myMask.hide();
	var request = eval('('+this.req.responseText+')');
	if (!request) return;
	if (request.lock) {
		Ext.Msg.alert('<{$words.module_title}>','<{$words.lock_warn}>');
		return;
	}

	var fp=Ext.getCmp("fpModule");
	if (install_type == 'online') {
		Ext.getCmp('modurl').setValue(modurl);
	}

	if(fp.getForm().isValid()){
		if (install_type == 'online') {
			Ext.getCmp("prefix").setValue('install_air');
			tmpmsg='<{$words.install_online}>';
		} else {
			Ext.getCmp("prefix").setValue('install_hdd');
			tmpmsg='<{$words.install_ondisk}>';
		}
		titlemsg=tmpmsg.replace('%s',Ext.getCmp("modname").getValue());
		form_action2 = '<{$form_action}>';
		Ext.Msg.confirm('<{$words.module_title}>',titlemsg,function(btn){
			if(btn=='yes'){
				processAjax(form_action2,'',fp.getForm().getValues(true));
				reloadStatus("yes");
			}
		});
	}
}

function reloadStatus(check_lock_flag) {
	processAjax('getmain.php?fun=auto_module&action=status&module_name=' + Ext.getCmp("modname").getValue() + '&status_type=0&check_lock=' + check_lock_flag,onLoadModStatus);
}

function renderStatus() {
	var status_win = new Ext.Window({
		id: "automod_status_win",
		title: "<{$words.install_uninstall_win_title}>",
		closable:false,
		closeAction:'hide',
		width: 550,
		height: 400,
		modal: true,
		resizable:false,
		layout: "fit",
		hideLabel: true,
		items: [{
			xtype: "textarea",
			id: "automod_status",
			name: "automod_status"
		}],
		buttons: [{
			id:'btn_automod_stauts_ok',
			text:'<{$gwords.ok}>',
			handler: function(){
				status_win.hide();
			}
		}]
	});
	status_win.on("hide", function () {
		Ext.getCmp("automod_status").setValue("");
		status_type = "";
		module_name = "";
	});
	
	return status_win;
}

function onLoadModStatus() {
	if(TCode.desktop.Group.page!='auto_module'){
		clearTimeout(status_time_id);
		return;
	}

	var request = eval('('+this.req.responseText+')');
	if (!request) return;

	var status_win = Ext.getCmp("automod_status_win")?Ext.getCmp("automod_status_win"):renderStatus();

	if (!status_win.isVisible()) {
		status_time_id = setTimeout("reloadStatus(\'no\')", 1000);
		Ext.getCmp("automod_status").setValue('<{$gwords.wait_msg|}>');
		Ext.getCmp("btn_automod_stauts_ok").setDisabled(true);
		status_win.show();
		return;
	}
	
	Ext.getCmp("btn_automod_stauts_ok").setDisabled(true);
	Ext.getCmp("automod_status").setValue(request.mod_status);

	// reload module status by mod_lock_flag value
	if (request.mod_lock_flag !== "") {
		if (!Ext.getCmp("btn_automod_stauts_ok").disabled) {
			Ext.getCmp("btn_automod_stauts_ok").setDisabled(true);
		}
		status_time_id = setTimeout("reloadStatus(\'no\')", 3000);
	} else {
		if (Ext.getCmp("btn_automod_stauts_ok").disabled) {
			Ext.getCmp("btn_automod_stauts_ok").setDisabled(false);
		}
		returnAutoModuleData(request.moduleData);
	}
}

    function remove_module(modname,realname){
        myMask.hide();
        var fp=Ext.getCmp("fpModule");
        var prefix=Ext.getCmp("prefix");
        Ext.getCmp('modname').setValue(modname);
        
        if(fp.getForm().isValid()){
	            prefix.setValue('remove_mod');
                
                tmpmsg='<{$words.remove_module}>';
                titlemsg=tmpmsg.replace('%s',realname);

                form_action2 = '<{$form_action}>';
			    
                Ext.Msg.confirm('<{$words.module_title}>',titlemsg,function(btn){
                    if(btn=='yes'){
                        processAjax(form_action2,returnModuleData,fp.getForm().getValues(true));
                    }
                });
        }
    }
    
    var Despfp = new Ext.FormPanel({
        frame: true
        ,labelWidth: 110
        //,fileUpload: true
        ,autoWidth: 'true'
        //,renderTo:'moduleform'
        ,bodyStyle: 'padding:0 10px 0;'
        
        ,items: [
            {
                layout: 'column'
                ,border: false
                ,defaults: { columnWidth: '.5' ,border: false }
            }
	    ,{
		xtype:'fieldset'
		,title: '<{$gwords.description}>'
		,autoHeight: true
		,layout: 'form'
		,buttonAlign: 'left'
		,items: [
		    {
			xtype: 'textfield'
			,name: 'desp_name'
			,id: 'desp_name'
			,fieldLabel: 'Name'
			,width: '470'
			,readOnly: true
		    }
		    ,{
			xtype: 'textfield'
			,name: 'desp_version'
			,id: 'desp_version'
			,fieldLabel: 'Version'
			,width: '470'
			,readOnly: true
		    }
		    ,{
			xtype: 'textfield'
			,name: 'desp_description'
			,id: 'desp_description'
			,fieldLabel: 'Description'
			,width: '470'
			,readOnly: true
		    }
		    ,{
			xtype: 'textfield'
			,name: 'desp_size'
			,id: 'desp_size'
			,fieldLabel: 'Size'
			,width: '470'
			,readOnly: true
		    }
		    ,{
			xtype: 'textfield'
			,name: 'desp_authors'
			,id: 'desp_authors'
			,fieldLabel: 'Authors'
			,width: '470'
			,readOnly: true
		    }
		    ,{
			xtype: 'textfield'
			,name: 'desp_web'
			,id: 'desp_web'
			,fieldLabel: 'Web Site'
			,width: '470'
			,readOnly: true
		    }
		    ,{
			xtype: 'textarea'
			,name: 'desp_license'
			,id: 'desp_license'
			,fieldLabel: 'License'
			,width: '470'
			,readOnly: true
		    }
		    ,{
			xtype: 'textarea'
			,name: 'desp_acknowledgments'
			,id: 'desp_acknowledgments'
			,fieldLabel: 'Acknowledgments'
			,width: '470'
			,readOnly: true
		    }
		]
        }]
    });

    var Window_Modesp= new Ext.Window({
          title:'<{$words.module_title}>'
          ,closable:true
          ,closeAction:'hide'
          ,width: 670
          ,height:400
          ,layout: 'fit'
          ,modal: true
	  ,draggable: false
	  ,resizable: false
          ,items: Despfp
    });

function install_warn_alert(msg) {
	Ext.Msg.alert('<{$words.module_title}>',msg);

}

Ext.onReady(function(){
	Ext.QuickTips.init();

	// turn on validation errors beside the field globally
	Ext.form.Field.prototype.msgTarget = 'side';

	var prefix = new Ext.form.Hidden({id: 'prefix', name: 'prefix', value: 'module'});
	var modname = new Ext.form.Hidden({id: 'modname', name: 'modname', value: 'modname'});
	var modurl = new Ext.form.Hidden({id: 'modurl', name: 'modurl', value: 'modurl'});
	var displa_yname = new Ext.form.Hidden({id: 'display_name', name: 'display_name', value: ''});

	var xg = Ext.grid;
	
	var sm2 = new xg.CheckboxSelectionModel();
	
	var grid_module = new xg.GridPanel({
		id:'button-grid',
		store: store,
		cm: new xg.ColumnModel([{
			header: '<{$gwords.installed}>', 
			width:80, 
			sortable: true, 
			dataIndex: 'mode',
			renderer: function(value,obj,thisobj) {
				var ver_dev = thisobj.data['mode'].split("|");
				if (ver_dev[0] == '0.0.0') {
					return '<{$words.not_installed}>';
				}else{
					return ver_dev[0];
				}
			}
		},{
			id:'name',
			header: '<{$gwords.name}>', 
			sortable: true, 
			dataIndex: 'DisplayName', 
			width: 120
		},{
			header: '<{$gwords.version}>', 
			sortable: true, 
			dataIndex: 'Version', 
			width: 60
		},{
			header: '<{$gwords.description}>', 
			dataIndex: 'Description', 
			width: 150,
			renderer: function(value,obj,thisobj) {
				var locate = thisobj.data['ui'].split("|");
				if (locate[0] == 'Disk') {
					return String.format('<a href="javascript:void(0);" onclick="javascript:myMask.show();smart_display(\'{0}\');">&nbsp;{1}</a>', thisobj.data['Name'], value);
				}else{
					return '&nbsp;' + thisobj.data['Description'];
				}
			}
		},{
			header: '<{$gwords.location}>', 
			sortable: true, 
			dataIndex: 'ui', 
			width: 80,
			renderer: function(value,obj,thisobj) {
				var locate = thisobj.data['ui'].split("|");
				return locate[0];
			}
		},{
			header: '<{$gwords.document}>', 
			dataIndex: 'ui', 
			width: 80,
			renderer: function(value,obj,thisobj) {
				var link = thisobj.data['ui'].split("|");
				var ret="";
				if (link[0]=='Disk'){
					//ret=link[0]+link[1]+link[2]+link[3];
					var get_fdurl='getmain.php?fun=readfd';
					get_guide=get_fdurl+'&type=guide&name='+thisobj.data['Name'];
					get_note =get_fdurl+'&type=note&name='+thisobj.data['Name'];
					if (link[2] != "") {
						ret = String.format(' <a title="<{$words.hint_user_guide}>" href="javascript:void(0);"  onclick="window.open(\'{0}\',\'\');" > <Img src="<{$urlimg}>icons/fam/user.gif" align="absmiddle"> </a>', get_guide);
					}
					if (link[3] != "") {
						ret = ret + String.format('&nbsp;&nbsp;<a title="<{$words.hint_release_note}>" href="javascript:void(0);"  onclick="window.open(\'{0}\',\'\');" > <img src="<{$urlimg}>/icons/fam/icon-info.gif" align="absmiddle"> </a> ', get_note);
					}
				}else{
					if (link[2] != ""){
						ret=String.format(' <a title="<{$words.hint_user_guide}>" href="javascript:void(0);"  onclick="window.open(\'{2}\',\'\');" > <Img src="<{$urlimg}>icons/fam/user.gif" align="absmiddle"> </a>',link[0],link[1],link[2],link[3]);
					}
					if (link[3] != ""){
						ret=ret + String.format('&nbsp;&nbsp;<a title="<{$words.hint_release_note}>" href="javascript:void(0);"  onclick="window.open(\'{3}\',\'\');" > <img src="<{$urlimg}>/icons/fam/icon-info.gif" align="absmiddle"> </a> ',link[0],link[1],link[2],link[3]);
					}
				}
				return ret;
			}
		},{
			header: '<{$gwords.action}>', 
			dataIndex: '', 
			id: 'action', 
			width: 90,
			renderer:  function(value,obj,thisobj) {
				var link = thisobj.data['ui'].split("|");
				var ver_dev = thisobj.data['mode'].split("|");
				var ver_ary1=ver_dev[0].split(".");
				var ver_ary2=thisobj.data['Version'].split(".");
				if(ver_ary1[1] === undefined)
					ver_ary1[1]=0;
				if(ver_ary2[1] === undefined)
					ver_ary2[1]=0;
				if(ver_ary1[2] === undefined)
					ver_ary1[2]=0;	
				if(ver_ary2[2] === undefined)
					ver_ary2[2]=0;
				var ver_ary1int=parseInt(ver_ary1[0]*10000)+parseInt(ver_ary1[1]*100)+parseInt(ver_ary1[2]);
				var ver_ary2int=parseInt(ver_ary2[0]*10000)+parseInt(ver_ary2[1]*100)+parseInt(ver_ary2[2]);
				var key_word="",version_word="";
				var install_warn_msg = "";
				var install_warn_title = "";
				var install_warn_link = "";

				if (link[0]=='Disk'){
					if (ver_ary1int < ver_ary2int) {
						if (ver_dev[2] > 0 && ver_dev[3] >0) {
							return String.format('<a  title="<{$words.hint_inst_ondisk}>" href="javascript:void(0);" onclick="javascript:myMask.show(); check_lock(\'disk\',\'{0}\',\'\',\'{1}\');"> <Img src="<{$urlimg}>icons/fam/image_add.png" align="absmiddle"></a> &nbsp;&nbsp;&nbsp;&nbsp; <a title="<{$words.hint_remove_disk}>" href="javascript:void(0);" onclick="javascript:myMask.show(); remove_module(\'{0}\',\'${1}\');"> <img src="<{$urlimg}>/default/layout/panel-close.gif" align="absmiddle"></a> ', thisobj.data['Name'], thisobj.data['DisplayName']);
						} else {
							if (ver_dev[3] == 0){
								install_warn_msg = "<{$words.key_not_match}>";
							}
							if (ver_dev[2] == 0){
								if (install_warn_msg.length > 0) {
									install_warn_msg += "<br>";
								}
								install_warn_msg += "<{$words.hint_need_version}>";
							}
							if (install_warn_msg.length > 0) {
								install_warn_title = "<{$words.unable_install_msg}>";
							}
							install_warn_link = '<a title="' + install_warn_title + '" href=\"javascript:void(0);" onclick="install_warn_alert(\''+ install_warn_msg +'\')"> <Img src="<{$urlimg}>icons/fam/icon-warning.gif" align="absmiddle"></a> &nbsp;';
							
							return String.format(install_warn_link+'&nbsp;&nbsp; <a title="<{$words.hint_remove_disk}>" href="javascript:void(0);" onclick="javascript:myMask.show(); remove_module(\'{0}\',\'{1}\');"> <img src="<{$urlimg}>/default/layout/panel-close.gif" align="absmiddle"></a> ', thisobj.data['Name'],thisobj.data['DisplayName']);
						}
					}else{
						return String.format('<a title="<{$words.hint_remove_disk}>" href="javascript:void(0);" onclick="javascript:myMask.show(); remove_module(\'{0}\',\'{1}\');"> <img src="<{$urlimg}>/default/layout/panel-close.gif" align="absmiddle"></a> ' ,thisobj.data['Name'],thisobj.data['DisplayName']);
					}
				}else{//online
					if (ver_ary1int < ver_ary2int) {
						if (ver_dev[2] > 0) {
							return String.format('<a  title="<{$words.hint_inst_online}>" href="javascript:void(0);" onclick="javascript:myMask.show(); check_lock(\'online\', \'{0}\',\'{1}\', \'{2}\');"> <Img src="<{$urlimg}>icons/fam/image_add.png" align="absmiddle"></a>', thisobj.data['Name'], link[1], thisobj.data['DisplayName']);
						}else {
							return String.format('<a  title="<{$words.hint_need_version}>" href="javascript:void(0);" onclick="install_warn_alert(\'<{$words.need_version}>\')"> <Img src="<{$urlimg}>icons/fam/icon-warning.gif" align="absmiddle"></a>');
						}
					}
				}
			}
		}]),
		sm: sm2,
		viewConfig: {
			forceFit:true
		},
		width:650,
		height:350,
		frame:false,
		title:'',
		iconCls:'icon-grid'
	});

	var fp = new Ext.FormPanel({
		frame: false,
		labelWidth: 110,
		fileUpload: true,
		id: 'fpModule',
		autoWidth: 'true',
		renderTo:'moduleform',
		style: 'margin: 10px;',
		items: [
			{
				layout: 'column',
				border: false,
				defaults: { columnWidth: '.5' ,border: false }
			},
			prefix,
			modname,
			modurl,
			displa_yname,
			{
				layout: 'column'
				,buttonAlign: 'left'
				,width:650
				,defaults:{
					layout:'form'
					,border:false
					,style:'padding: 2px'
				}
				,items:[ {
					columnWidth:0.65
					,items:[ {
						x:0
						,y:0
						,xtype: 'fileuploadfield'
						,name: 'module_package'
						,id: 'insert_btn'
						,emptyText: ''
						,fieldLabel: '<{$words.module_package}>'
						,width:'auto'
						,buttonCfg: {
							text: ''
							,iconCls: 'upload-icon'
						}
					} ]
				} ,{
					columnWidth:0.15
					,items:[ {
						xtype:'button'
						,text:'<{$gwords.upload}>'
						,handler: function(){
							if(fp.getForm().isValid()){
								if (Ext.getCmp('insert_btn').getEl().dom.value != ''){
									Ext.Msg.confirm('<{$words.module_title}>','<{$words.upload_module_confirm}>',function(btn){
										if(btn=='yes'){
											prefix.setValue('upload');
											fp.getForm().submit({
												url: 'setmain.php?fun=setauto_module'
												,waitMsg: '<{$words.upgradeing_module}>'
												,success: function(fp, o){
													processAjax('<{$form_action}>',returnModuleData);
												}
												,failure: function(fp, o){ 
													msg('<{$words.settingTitle}>', o.result.msg);
												}
											});
										}
									});
								}
							}
						}
					} ]
				} ,{
					columnWidth:0.2
					,items:[ {
						xtype:'button'
						,text:'<{$gwords.rescan}>'
						,handler: function(){
							if(fp.getForm().isValid()){
								Ext.Msg.confirm('<{$words.module_title}>','<{$words.rescan_confirm}>',function(btn){
									if(btn=='yes'){
										prefix.setValue('rescan');
										fp.getForm().submit({
											url: 'setmain.php?fun=setauto_module'
											,waitMsg: '<{$words.rescan_list}>'
											,success: function(fp, o){
												modname.setValue(o.result.newmodule);
												processAjax('<{$form_action}>',returnModuleData);
											}
											,failure: function(fp, o){ 
												msg('<{$words.settingTitle}>', o.result.msg);
											}
										})
									}
								});
							}
						}
					} ]
				} ]
			}, {
				xtype:'fieldset'
				,x: 0
				,y: 30
				,title: '<{$words.module_list}>'
				,autoHeight: true
				,layout: 'form'
				,items: grid_module
			}
		]
	});
});


</script>
