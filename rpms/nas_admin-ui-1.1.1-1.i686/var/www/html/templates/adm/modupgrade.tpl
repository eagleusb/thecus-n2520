/**
 * new module install model
 * 
 * @property MOD_WIN 
 * @property data
 * 
 * @method init
 * @method handleOK
 * @method handleDetect
 * @method handleInstall
 * @method handleBeginEnabled
 * @method handleEnabled
 * @method getForm
 * 
 */
var newModInstall = (function(){ 
	
	// new module install window object
	var MOD_WIN;  
	
	// load module list , data type is string
	var DATA; 
	
	// form name list
	var FORM_LIST = [];
	var FORM = "";
	
	
	var REMIND_CHK = {};
	var REMIND_EL = {};
	var STATUS;
	this.monitor_install = null;
	
	/**
	 * handler button OK
	 * @access private
	 */
	function _handleOK()
	{  
		clearTimeout(this.monitor_install); 
		if(newModInstall.REMIND_CHK.checked){  
			processAjax('getmain.php?fun=modupgrade&ac=no_remind'); 
		}
		Ext.getCmp("newmod_win").hide();  
	}
	
	/**
	 * handler button install
	 * @access private
	 */
	function _handleInstall()
	{ 
		//general parameter
		var param = "";
		var inputs = document.getElementsByTagName("input");
		for(var i =0;i<inputs.length;i++){
			if(inputs[i].type=="checkbox"){
				if(inputs[i].name=="modname[]" && inputs[i].checked){ 
					param+="&modname[]="+encodeURIComponent(inputs[i].value);
				}
			}
		}
		
		// doing install
		if(param!=""){ 
			newModInstall.REMIND_CHK.checked=true;
			newModInstall.getForm("loading"); 
		    var pbarInstall = new Ext.ProgressBar({
		        id:'pbarInstall',
		        width:300,
		        renderTo:'pbarInstall'
		    });
			Ext.fly('pbarInstalltext').update('Download'); 
			pbarInstall.updateProgress(0.4);   
			this.monitor_install = processAjax('setmain.php?fun=modupgrade&ac=install'+param,_handleBeginEnabled);
		 
		}else{ 
			Ext.Msg.alert("<{$gwords.warning}>","<{$mwords.select_confirm}>");
		} 	
	}
	 
	
	/**
	 * handler button detect
	 * @access private
	 */
	function _handleDetect()
	{ 
		var request = eval('('+this.req.responseText+')');  
		if(request.success=="1"){ 
			newModInstall.DATA = request.mod_data;
			newModInstall.getForm("install");
		}else{
			newModInstall.getForm("fail"); 
		}
	}
	
	/**
	 * handler begin enable, update progress bar and status
	 * @access private
	 */
	function _handleBeginEnabled()
	{    
		if(MOD_WIN.isVisible()){  
			Ext.getCmp("pbarInstall").updateProgress(0.8); 
			Ext.fly('pbarInstalltext').update('Enable module');
			processAjax('setmain.php?fun=modupgrade&ac=enable',_handleEnabled);  
		}  
	}
	
	/**
	 * handler enable
	 * @access private
	 */
	function _handleEnabled()
	{ 
		if(MOD_WIN.isVisible()){  
			Ext.getCmp("pbarInstall").updateProgress(1); 
			setTimeout(function(){ 
				newModInstall.getForm("success");
				newModInstall.REMIND_EL.style.display = "none";    
			},1000);
		}  
	}
	
	/**
	 * load data
	 * @access private
	 * @param {String} mod_data
	 */
	function _loadModuleData(mod_data){
		// create data reader
		var reader = new Ext.data.ArrayReader({}, [, {
			name: 'Name'
		}, {
			name: 'DisplayName'
		}, {
			name: 'Version'
		}, {
			name: 'url'
		}]);
		
		// create store
		var mod_store = new Ext.data.Store({
			reader: reader
		}); 
		
		//create gridpanel
		var mod_grid = new Ext.grid.GridPanel({
			id: 'grid',
			width: 400,
			height: 160,
			store: mod_store,
			frame: false,
			renderTo: "newmod-form-install-list",
			columns: [
			{
				id: "id",
				header: "",
				width: 30,
				dataIndex: 'Name',
				renderer: function(value, obj, thisobj){
					return "<input type='checkbox' name='modname[]' id='modname[]' value='" + value + "," + thisobj.data['DisplayName'] + "," + thisobj.data['url'] + "'  checked />";
				}
			}, {
				id: 'name',
				header: '<{$gwords.name}>',
				width: 180,
				dataIndex: 'DisplayName'
			}, {
				id: 'version',
				header: "<{$gwords.version}>",
				width: 180,
				dataIndex: 'Version'
			}]
		});
		
		
		// parser data to store load
		if (!mod_data || mod_data.length <= 0) {
			mod_store.loadData('');
		}
		else {
			var dataAry = mod_data.split("|");
			var dataAry_len = dataAry.length;
			var data = [];
			var j = 0;
			for (var i = 0; i < (dataAry_len); i++) {
				var mod_ary = dataAry[i].split(",");
				if (mod_ary) {
					var name = mod_ary[0];
					var displayname = mod_ary[1];
					var version = mod_ary[2];
					var url = mod_ary[3];
					if (name != "") {
						data[j] = new Array(j, name, displayname, version, url);
						j++;
					}
				}
			}
			mod_store.loadData(data);
		}
	}
	
	
	return { 
		/**
		 * Initialization new model install 
		 * @access public
		 * @param {String} form name
		 */
		init:function(formname)
		{
			this.STATUS = "";
			this.FORM = formname;
			this.FORM_LIST = [
							"cd",
							"detect",
							"install",
							"fail",
							"success",
							"loading"
							];
			this.REMIND_CHK = Ext.getDom("no_remind");
			this.REMIND_EL = Ext.getDom("remind");
			
			this.REMIND_CHK.checked = false;
			this.REMIND_EL.style.display = "block";
			
			var _this = this;
			MOD_WIN = new Ext.Window({
				id:"newmod_win",
				modal:true,
				applyTo: "newmod-win",
				closable: false,
				plain: true,
				layout: 'fit',
				width: 600,
				height: 350,
				items: new Ext.Panel({
					applyTo: "newmod-panel",
					border: false,
					deferredRender: false 
				}),
				buttons: [{
					text: "<{$gwords.ok}>",
					handler: _handleOK
				}, {
					text: "<{$gwords.install}>",
					handler:_handleInstall
				}, {
					text: "<{$mwords.detect_btn}>",
					handler: function(){ 
						_this.getForm("detect");
						processAjax('setmain.php?fun=modupgrade&ac=detect',_handleDetect); 
					}
				}, {
					text: "<{$gwords.cancel}>",
					handler: _handleOK
				}, {
					text: "<{$gwords.closewindow}>",
					handler: function(){   
						processAjax('setmain.php?fun=modupgrade&ac=no_remind',function(){
							location.reload();
						}); 
						Ext.getCmp("newmod_win").hide(); 
					}
				}]
			}); 
			
			if(this.FORM !== ""){
				this.getForm(this.FORM);
			}
		},
	  
		/**
		 * Display form
		 * @access public
		 * @param {String} name
		 */
		getForm:function(formname)
		{   
			// popup window
			if(MOD_WIN.isVisible()){ 
				MOD_WIN.toFront();
			}else{  
				MOD_WIN.show();
			}  
			
			// hide all form
			var btn_total = 5; 
			var list = this.FORM_LIST;  
			for(var i in list){ 
				if(typeof list[i] == "string"){  
					if(Ext.getDom("newmod-form-"+list[i])){
						Ext.getDom("newmod-form-"+list[i]).style.display = "none";  
					} 
				}
			} 
			
			// hide all button
			for(var i=0;i<btn_total;i++){
				MOD_WIN.buttons[i].hide();
			}			 
			
			//show specific form
		 	Ext.getDom("newmod-form-"+formname).style.display = "block"; 
			
			//show specific button and layout
			switch(formname){
				case "loading": 
					//hide remind checkbox
					Ext.getDom("remind").style.display = "none";  
					MOD_WIN.buttons[3].show();  
					break;
				case "success": 
					MOD_WIN.buttons[4].show();  
					break;
				case "cd": 
					MOD_WIN.buttons[0].show();  
					break;
				case "detect":   
					MOD_WIN.buttons[3].show();  
					break;
				case "install":   
					MOD_WIN.buttons[1].show();  
					MOD_WIN.buttons[3].show();
					
					// loading data 
					_loadModuleData(this.DATA);
					break;
				case "fail": 
					MOD_WIN.buttons[0].show(); 
					MOD_WIN.buttons[2].show();
					break;  
			}  
		}
		 
	}  
})();
  