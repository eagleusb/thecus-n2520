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
var status_time_id = "";
var module_mask = null;
var status_type = ""; // 0: install/uninstall, 1:enable/disable, 2: last_stauts
var check_lock = "no";
var action_url = "";

function ExtDestroy(){ 
    Ext.destroy(
        Ext.getCmp('firstGridDropTarget'),
        Ext.getCmp('destGridDropTarget'),
		destroyStatusWin(Ext.getCmp("module_status_win"))
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
	,{name: 'homepage'}
	,{name: 'rdf_version'}
	,{name: 'show'}
	,{name: 'publish'}
]);

// create the data store
var store = new Ext.data.Store({
	reader: reader
});
returnModuleData('<{$moduleData}>');

function returnModuleData(moduleData){
	if (!moduleData || moduleData.length <= 0) {
		store.loadData('');
	} else {
		var folderData = new Array();
		folderData = moduleData.split(String.fromCharCode(27));

		var folderData2 = new Array();
		var c=12;
		for (i=0; i<(folderData.length/c); i++) {
			folderData2[i] = new Array(folderData[i*c], folderData[i*c+1], folderData[i*c+2], folderData[i*c+3], folderData[i*c+4], folderData[i*c+5],folderData[i*c+6],folderData[i*c+7],folderData[i*c+8],folderData[i*c+9],folderData[i*c+10],folderData[i*c+11]);
		}
		store.loadData(folderData2);
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
	processAjax('setmain.php?fun=setmodule_desp&module='+moduleName,DespForm);
}
function rendererModuleLink(value,obj,thisobj) {
	var version_link = "";
	if (!checkModuleVersion(thisobj.data["rdf_version"])) {
		version_link = '<a href="javascript:void(0);" onmousedown="Manual.showMenu();Manual.set(3,1);"><img src=\"/theme/images/icons/fam/icon-warning.gif\" style="float:left" /></a>';
	}
	var isEnabled = thisobj.data['Enable']=="No"?false:true; 
	if(isEnabled){
		return String.format(version_link + '<div style="float:left;padding-right:8px" ><a href="javascript:void(0);" class="module_link" onclick="javascript:myMask.show();gotoModulePage(\'{0}\',\'{1}\',\'{2}\');">{3}</a></div>',thisobj.data['Name'],thisobj.data['ui'],thisobj.data['homepage'],thisobj.data['DisplayName']);
	}else{
		return String.format(version_link + '<div style="float:left;padding-right:8px" >&nbsp;{0}</div>',value);
	}
}

function ReloadShowValue(){
	var request = eval('('+this.req.responseText+')');
	if (!request) return;
  returnModuleData(request.moduleData);
}

function rendererModuleShow(value,obj,thisobj){
	var check_value=false;
	var icon_id=thisobj.data['Id']+"_icon";

	if(thisobj.data["publish"]=='1'){
		if(thisobj.data["show"]=='1'){
			check_value=true;
		}
		Ext.lib.Event.onAvailable(icon_id, function(){
	    var show_id=icon_id+'_show';
	  	var check_box = new Ext.form.Checkbox({
	  	id:show_id,
	  	fieldLabel: '',
	  	labelSeparator: '',
	  	checked:check_value,
	  	listeners: {
	  		check:{
	  			fn:function(check,newvalue)
	  			{
	  				processAjax('getmain.php?fun=module',ReloadShowValue,'action=changeshow&mod_name='+thisobj.data['Name']+'&newval='+newvalue);
	  			}
	  		}
	  	},
	  	renderTo:icon_id
	  	});
	  });
	}
	return '<div id="'+icon_id+'"></div>';  
}

function checkModuleVersion (mod_rdf_version) {
	if (!mod_rdf_version || mod_rdf_version === "") {
		return false;
	}
	var rdf_version_arr = "<{$rdf_version}>".split(".");
	var mod_rdf_version_arr = mod_rdf_version.split(".");
	for (var i = 0; i < 3; i++) { // 3: version array length
		if (rdf_version_arr[i] > mod_rdf_version_arr[i]) {
			return false;
		}
	}
	return true;
}

function gotoModulePage(moduleName,ui,homepage){
	var inMenu =-1;
	if (homepage != "") {
		var menu_footer = "Status,Storage,Network,Accounts,System,Nomenu";
		inMenu = menu_footer.search(homepage);
	}
	if(ui=='Thecus' || inMenu=='0'){
		window.open("getform.html?Module="+moduleName);
	}else{ 
		window.open("/modules/"+moduleName+'/'+homepage);
	}
	myMask.hide();
}

function moduleUninstall () {
	var request = eval('('+this.req.responseText+')');
	if (!request) return;
	
	if (request.lock == "yes") {
		Ext.Msg.alert('<{$words.module_title}>','<{$words.lock_warn}>');
		return;
	}
	Ext.getCmp("prefix").setValue('uninstall');
	processAjax(action_url, reloadStatus,Ext.getCmp("fpModule").getForm().getValues(true));
	status_type = "0";	// 0: install/uninstall
	check_lock = "no";
}

function uninstall_module(module_num, mod_name){
	myMask.hide();
	var fp=Ext.getCmp("fpModule");
	
	if(fp.getForm().isValid()){
		Ext.getCmp("modname").setValue(mod_name);
		Ext.getCmp("prefix").setValue('check_lock');
		
		Ext.Msg.confirm('<{$words.module_title}>','<{$words.uninstall_confirm}>',function(btn){
			if(btn=='yes'){
				action_url = '<{$form_action}>' + "&check_" + module_num + "=1";
				processAjax('<{$form_action}>',moduleUninstall,fp.getForm().getValues(true));
			}
		});
	}
}

function moduleEnableDisable() {
	var request = eval('('+this.req.responseText+')');
	if (!request) return;
	
	if (request.result == "fail") {
		module_mask.hide();
		module_mask = null;
		Ext.Msg.alert('<{$words.module_title}>',request.msg);
		return;
	}
	check_lock = "no";
	reloadStatus();
}

function enable_disable(module_num, enable, mod_name, displayName,mode,ui){
	var fp=Ext.getCmp("fpModule");
	var prefix=Ext.getCmp("prefix");
	Ext.getCmp('modname').setValue(mod_name);
	if (ui.indexOf("Thecus")==-1 || mode.indexOf("Admin")==-1) {
		user_system = 0;
	} else {
		user_system = 1;
	}

	if(fp.getForm().isValid()){
		if (enable=='No'){
			prefix.setValue('enable');
			titlemsg='<{$words.enable_confirm}>';
		}else if (enable=='Yes'){
			prefix.setValue('disable');
			titlemsg='<{$words.disable_confirm}>';
		}
	
		Ext.Msg.confirm('<{$words.module_title}>',titlemsg,function(btn){
			if(btn=='yes'){
				status_type = "1";	// 1: enable/disable
				if (module_mask === null) {
					module_mask = new Ext.LoadMask(Ext.getBody(), {msg:"<{$words.enable_disable_msg}>"});
					module_mask.show();
				}
				form_action2 = '<{$form_action}>' + "&check_" + module_num + "=1";
				processAjax(form_action2,moduleEnableDisable,fp.getForm().getValues(true), false);
			}
		});
	}
}

var Despfp = new Ext.FormPanel({
	frame: true
	,labelWidth: 110 
	,autoWidth: 'true' 
	,bodyStyle: 'padding:0 10px 0;'
	
	,items: [
	{
		layout: 'column'
		,border: false
		,defaults: { columnWidth: '.5' ,border: false }
	},{
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
		},{
			xtype: 'textfield'
			,name: 'desp_version'
			,id: 'desp_version'
			,fieldLabel: 'Version'
			,width: '470'
			,readOnly: true
		},{
			xtype: 'textfield'
			,name: 'desp_description'
			,id: 'desp_description'
			,fieldLabel: 'Description'
			,width: '470'
			,readOnly: true
		},{
			xtype: 'textfield'
			,name: 'desp_size'
			,id: 'desp_size'
			,fieldLabel: 'Size'
			,width: '470'
			,readOnly: true
		},{
			xtype: 'textfield'
			,name: 'desp_authors'
			,id: 'desp_authors'
			,fieldLabel: 'Authors'
			,width: '470'
			,readOnly: true
		},{
			xtype: 'textfield'
			,name: 'desp_web'
			,id: 'desp_web'
			,fieldLabel: 'Web Site'
			,width: '470'
			,readOnly: true
		},{
			xtype: 'textarea'
			,name: 'desp_license'
			,id: 'desp_license'
			,fieldLabel: 'License'
			,width: '470'
			,readOnly: true
		},{
			xtype: 'textarea'
			,name: 'desp_acknowledgments'
			,id: 'desp_acknowledgments'
			,fieldLabel: 'Acknowledgments'
			,width: '470'
			,readOnly: true
		}]
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

function renderStatus() {
	var status_win = new Ext.Window({
		id: "module_status_win",
		title: "<{$words.module_title}>",
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
			id: "mod_status",
			name: "mod_status"
		}],
		buttons: [{
			id:'btn_mod_stauts_ok',
			text:'<{$gwords.ok}>',
			handler: function(){
				status_win.hide();
			}
		}]
	});
	status_win.on("hide", function () {
		Ext.getCmp("mod_status").setValue("");
		status_type = "";
	});
	
	return status_win;
}

function destroyStatusWin(status_win) {
	if (status_win) {
		status_win.destroy();
		status_win = null;
	}
}

function onLoadModStatus() {
	check_lock = "no";
	var show_win = false;
	var title = "";
	if(TCode.desktop.Group.page!='module'){
		clearTimeout(status_time_id);
		return;
	}

	var request = eval('('+this.req.responseText+')');
	if (!request) return;
	
	var status_win = Ext.getCmp("module_status_win");
	if (!status_win) {
		status_win = renderStatus();
	}
	
	switch (status_type) {
	case "0":	// install/uninstall
		if (!status_win.isVisible()) {
			show_win = true;
		}
		title = "<{$words.install_uninstall_win_title}>";
		Ext.getCmp("btn_mod_stauts_ok").setDisabled(true);
		Ext.getCmp("mod_status").setValue(request.mod_status);
		break;
	case "1":	// enable/disable
		title = "<{$words.enable_disable_win_title}>";
		break;
	case "2":	// last status
		show_win = true;
		title = "<{$words.last_status_win_title}>".replace('%s',Ext.getCmp("modname").getValue());
		Ext.getCmp("mod_status").setValue(request.mod_status);
		break;
	default:
		title = "<{$words.module_title}>";
	}
	status_win.setTitle(title);
	
	// reload module status by mod_lock_flag value
	if (request.mod_lock_flag == "2") { // 0: install/uninstall, 1: enable/disable, 2: upload file
		Ext.getCmp("mod_status").setValue('<{$words.upload_file_msg}>');
		status_time_id = setTimeout("reloadStatus()", 3000);
		Ext.getCmp("btn_mod_stauts_ok").setDisabled(true);
		if (!status_win.isVisible()) {
			status_win.show();
		}
		return;
	} else if (request.mod_lock_flag !== "") { // module is still locked ==> keep monitoring
		if (!Ext.getCmp("btn_mod_stauts_ok").disabled) {
			Ext.getCmp("btn_mod_stauts_ok").setDisabled(true);
		}
		status_time_id = setTimeout("reloadStatus()", 1500);
		
	} else {
		if (status_type == "0" && (request.mod_status ===null || request.mod_status === "") && !status_win.isVisible()) { // install/uninstall and log is still empty ==> wait log ready for 1 sec
			Ext.getCmp("mod_status").setValue('<{$gwords.wait_msg}>');
			status_time_id = setTimeout("reloadStatus()", 1000);
			Ext.getCmp("btn_mod_stauts_ok").setDisabled(true);
			status_win.show();
			return;
		} else if (status_type == "1" && module_mask !== null) {
			module_mask.hide();
			module_mask = null;
			if (request.mod_status && request.mod_status !== "") {
				Ext.getCmp("mod_status").setValue(request.mod_status);
				show_win = true;
			}
		}
		if (Ext.getCmp("btn_mod_stauts_ok").disabled) {
			Ext.getCmp("btn_mod_stauts_ok").setDisabled(false);
		}
		returnModuleData(request.moduleData);
	}
	if (show_win) {
		status_win.show();
	}
}

function showLastStatus(mod_name) {
	status_type = "2"; // last_status
	Ext.getCmp("modname").setValue(mod_name);
	check_lock = "no";
	reloadStatus();
}

function reloadStatus() {
	// If it is not last_status type, no need module_name parameter.
	var module_name = "";
	if (status_type == "2") {
		module_name = Ext.getCmp("modname").getValue();
	}
	processAjax('getmain.php?fun=module&action=status&module_name=' + module_name + '&status_type=' + status_type + '&check_lock=' + check_lock,onLoadModStatus);
}

function check_module_progress () {
	status_type = "<{$lock_type}>";
	Ext.getCmp("modname").setValue("");
	if (status_type !== "") {
		check_lock = "yes";
		reloadStatus();
	}
}

function moduleInstall() {
	var request = eval('('+this.req.responseText+')');
	if (!request) return;
	
	if (request.result == "fail") {
		Ext.Msg.alert('<{$words.module_title}>','<{$words.lock_warn}>');
		return;
	}
	Ext.getCmp("prefix").setValue('install');
	Ext.getCmp("modname").setValue("");
	Ext.getCmp("fpModule").getForm().submit({
		url: '<{$form_action}>'
	}, this);
	status_type = "0";
	check_lock = "no";
	reloadStatus();
}

Ext.onReady(function(){
	Ext.QuickTips.init();

	// turn on validation errors beside the field globally
	Ext.form.Field.prototype.msgTarget = 'side';

	var prefix = new Ext.form.Hidden({id: 'prefix', name: 'prefix', value: 'module'});
	var modname = new Ext.form.Hidden({id: 'modname', name: 'modname', value: ''});

	var xg = Ext.grid;

	var sm2 = new xg.CheckboxSelectionModel();

	// check if there is any progress running
	check_module_progress();

	var grid_module = new xg.GridPanel({
		id:'button-grid'
		,store: store
		,cm: new xg.ColumnModel([
			{header: '<{$gwords.enable}>', width:50, sortable: true, dataIndex: 'Enable'}
			,{header: '<{$gwords.type}>',id:'modulemode', width: 60, sortable: true, dataIndex: 'mode' }
			,{header: '<{$gwords.name}>',id:'displayname', sortable: true, dataIndex: 'DisplayName', width: 190 ,renderer: rendererModuleLink}
			,{header: '<{$gwords.version}>', sortable: true, dataIndex: 'Version'}
			,{header: '<{$gwords.description}>', dataIndex: 'Description', width: 120
				,renderer:  function(value,obj,thisobj) {
					return String.format('<a href="javascript:void(0);" onclick="javascript:myMask.show();smart_display(\'{0}\');">&nbsp;{1}</a>',thisobj.data['Name'],value);
				}
			}
			,{header: '<{$words.module_status}>'
				,renderer: function (value,obj,thisobj) {
					return String.format('<div align=center><a href="javascript:void(0);" onclick="showLastStatus(\'{0}\');"><img src="<{$urlimg}>/icons/fam/icon-info.gif"></a></div>', thisobj.data['Name']);
				}
			}
			,{header: '<{$gwords.action}>', dataIndex: '', id: 'action', width: 90
				,renderer:  function(value,obj,thisobj) {
					if (thisobj.data['Enable']== 'No')
						return String.format('<a  title="Enable Module" href="javascript:void(0);" onclick="enable_disable(\'{0}\',\'{1}\',\'{2}\',\'{3}\',\'{4}\',\'{5}\');"><img src="<{$urlimg}>/default/grid/page-next.gif" align="absmiddle"></a> &nbsp;&nbsp;&nbsp; <a title="Uninstall Module" href="javascript:void(0);" onclick="javascript:myMask.show();uninstall_module(\'{0}\', \'{2}\');"><img src="<{$urlimg}>/default/layout/panel-close.gif" align="absmiddle"></a>',thisobj.data['Id'],thisobj.data['Enable'], thisobj.data['Name'], thisobj.data['DisplayName'],thisobj.data['mode'],thisobj.data['ui']);
					else if (thisobj.data['Enable']== 'Yes')
						return String.format('<a title="Disable Module" href="javascript:void(0);" onclick="enable_disable(\'{0}\',\'{1}\',\'{2}\',\'{3}\',\'{4}\',\'{5}\');"><img src="<{$urlimg}>/default/sizer/square.gif" align="absmiddle"></a> &nbsp;&nbsp;&nbsp; <a title="Uninstall Module" href="javascript:void(0);" onclick="javascript:myMask.show();uninstall_module(\'{0}\', \'{2}\');"><img src="<{$urlimg}>/default/layout/panel-close.gif" align="absmiddle"></a>',thisobj.data['Id'],thisobj.data['Enable'], thisobj.data['Name'], thisobj.data['DisplayName'],thisobj.data['mode'],thisobj.data['ui']);
				}
			}
			<{if $module_login == "1"}>
			,{
			  header: '<{$words.login_show}>'
				,renderer: rendererModuleShow
			}
			<{/if}>
		])
		,sm: sm2
		,viewConfig: {
			forceFit:true
		}
		,width:700
		,height:300
		,frame:false
		,title:''
		,iconCls:'icon-grid'
	});

	var fp = new Ext.FormPanel({
		frame: false
		,labelWidth: 110
		,fileUpload: true
		,id: 'fpModule'
		,autoWidth: 'true'
		,renderTo:'moduleform'
		,style: 'margin: 10px;'
		,items: [
			{
				layout: 'column'
				,border: false
				,defaults: { columnWidth: '.5' ,border: false }
			},
			prefix,
			modname,
			{
				layout: 'column',
				buttonAlign: 'left',
				width: 700,
				defaults:{
					layout:'form',
					border:false,
					style: 'padding: 2px;'
				},
				items:[
					{
						columnWidth:0.8,
						items:[{
							x:0,
							y:0,
							xtype: 'fileuploadfield',
							name: 'module_package',
							id: 'insert_btn',
							emptyText: '',
							fieldLabel: '<{$words.install_title}>',
							width:'auto',
							buttonCfg: {
								text: '',
								iconCls: 'upload-icon'
							}
						}]
					},{
						columnWidth:0.2,
						items:[{
							xtype:'button',
							text:'<{$gwords.install}>',
							handler: function(){
								if(fp.getForm().isValid()){
									if (Ext.getCmp('insert_btn').getEl().dom.value != ''){
										Ext.Msg.confirm('<{$words.module_title}>','<{$words.install_confirm}>',function(btn){
											if(btn=='yes'){
												prefix.setValue("getlock");
												processAjax('<{$form_action}>' + '&lock_type=2',moduleInstall,Ext.getCmp("fpModule").getForm().getValues(true));
											}
										});
									}
								}
							}
						}]
					}
				]
			},{
				xtype:'fieldset',
				title: '<{$words.module_title}>',
				autoHeight: true,
				layout: 'form',
				items: grid_module
			},
			{
				xtype:'fieldset',
				title: '<{$gwords.description}>',
				autoHeight: true,
				layout: 'form',
				items: [
				    {
				        xtype:'label',
				        html: '<{$words.app_center_desc}>' + ':<a style="color: blue; margin: 5px;" target="_blank" href="http://www.thecus.com/sp_app_center.php">http://www.thecus.com/sp_app_center.php</a>'
				    }
				]
			}
		]
	});
});


</script>
