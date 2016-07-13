/**
* TreeMenu class
* 
* @author Heidi 
*
* @property object g_tree : current tree value.
* @property object g_treeall : all of tree list object.
* @property object load 
* @property object [HTMLInputElement] dom_searchtree,dom_searchtxt,dom_nav
* @property boolean isIE : check browser is 'IE' return true, otherwise false.
* @property float during : when pass onkeyup then submit data during every sec.
* @property number timeoutid : timeout ID
*
* @method init(treeobj : initialized function.
* @method getValue() : get g_tree value.
* @method setValue(obj) : set g_tree value.
* @method search(msg) : search treemenu.
* @method clearSearchLayout() :  clean search dom layout.
* @method buildSearchLayout() :  build search dom layout.
* @method addSearchNode(value) :  add each dom node in current search layout.
* @method setCurrentPage(treeobj, fun, treeid, treename, cateid, catename):  setting current point page as record.
* @method getCurrentPage(treeall, find):  getting current point page as record.
* @method NavigatorIndex():  navigator home link.
* 
*/
var TreeMenu = function(){  
	var g_tree = {};	
	var g_treeall = {};
	var load;
	var dom_nav;
	var tree_store = new Ext.data.JsonStore({
		fields: ['cateid', 'catename', 'desc', 'fun', 'title', 'treeid']
	});
	var tree_window = new Ext.Window({
		closable: false,
		frame: false,
		resizable: false,
		autoScroll: true,
		shadow: false,
		cls: 'tmenu tmenu_search',
		items: {
			xtype: 'dataview',
			store: tree_store,
			tpl: new Ext.XTemplate(
				'<table style="padding-left: 5px;">',
					'<tpl for=".">',
						'<tr class="x-editable">',
							'<td valign="top"><img style="float:left" width="40" height="40" src="/theme/images/shortcut/80x80/{fun}.png"></td>',
							'<td><span>',
								'<div style="font-weight: bold">{title}</div>',
								'<div>{desc}</div>',
							'</span></td>',
						'</tr>',
					'</tpl>',
				'</table>'
			),
			autoHeight: true,
			multiSelect: false,
			overClass:'x-view-over',
			itemSelector:'tr.x-editable',
			emptyText: 'No images to display',
			listeners: {
				click: function (dv, index, node, e) {
					dv.ownerCt.hide();
					var metadata = dv.store.getAt(index).data;
					TreeMenu.setCurrentPage(
						false,
						metadata.fun,
						metadata.treeid,
						metadata.title,
						metadata.cateid,
						metadata.catename
					);
				}
			}
		}
	});
	tree_window.show();
	tree_window.hide();
	
	Ext.getBody().on('click', function(){ TreeMenu.clearSearchLayout(); });
	//tree_window.show();
	// when keyup then submit data during 0.5 sec 
	var during = 0.5;		
	var timeoutid; 
	
	return {   
		/**
		* initialized
		* 
		*/
		init:function(treeobj){
			load=this;  
			g_treeall = treeobj;
			dom_nav = document.getElementById("nav");
			/*
			if(navigator.userAgent.indexOf('MSIE')>-1){
				isIE = true; 
				dom_searchtxt.attachEvent("onkeyup",function(){TreeMenu.search(dom_searchtxt.value)});
			}else{ 
				dom_searchtxt.addEventListener("keyup",function(){TreeMenu.search(dom_searchtxt.value)},false); 
			}
			*/
		},
		
		/**
		* get g_tree value
		*/
		getValue:function(){ 
			return g_tree;
		},
		
		/**
		* set g_tree value
		* @param object obj:
		*/
		setValue:function(obj){ 
			g_tree = obj;
		},
		
		/**
		* onkeyup trigger to search
		* @param string msg:
		*/
		search:function(msg){  
			if(msg==""){
				this.clearSearchLayout();
			}   
			if(timeoutid){
				clearTimeout(timeoutid);
			} 
			var functioname="processAjax('getmain.php?fun=treemenu',TreeMenu.buildSearchLayout,'&ac=search&searchmsg="+msg+"',false);";
			
			//every 0.5 sec. 
			timeoutid = setTimeout(functioname,during*100); 
		}, 
		

		/**
		* draw search tree layout
		* 
		*/
		buildSearchLayout:function() {
			if( tree_window.rendered === true ) {
				tree_window.hide();
			}
			
			load.clearSearchLayout();
			if(this.req){
				var v = eval('('+this.req.responseText+')');
				if( v.length > 0 ) {
					var h = Ext.get('content-panel').getHeight() - 1;
					tree_store.loadData(v);
					tree_window.setHeight(h);
					tree_window.show();
					tree_window.el.setStyle('top', '');
					tree_window.el.setStyle('left', '');
				}
			}
		}, 


		/**
		* clean search tree layout
		* 
		*/
		clearSearchLayout:function(){
			tree_window.hide();
		},
	
		/**
		* add search tree htmlinputelement node
		* @param obj value:
		*/
		addSearchNode:function(value){   
			var fun = value.fun; 			//link function name (image)
			var treename= value.title;		//tree name
			var desc = value.desc;			//description 
			var cateid= value.cateid;		//categorize ID
			var catename = value.catename;	//categorized name
			var treeid= value.treeid;   
			if(isIE){
				var a= document.createElement("<a href=\"javascript:void(0)\" onclick=\"TreeMenu.setCurrentPage(false,'"+fun+"','"+treeid+"','"+treename+"','"+cateid+"','"+catename+"')\"/>");
			}else{	 
				var a = document.createElement("a");
				a.setAttribute("href","javascript:void(0)");
				a.setAttribute("onclick","TreeMenu.setCurrentPage(false,'"+fun+"','"+treeid+"','"+treename+"','"+cateid+"','"+catename+"')");
			}
			var tmenu_record = document.createElement("div");
			tmenu_record.className="tmenu_record";
		
			//create image 
			if(isIE){
				var img = document.createElement("<img style=\"float:left;margin-right:10\" src=\"/theme/images/shortcut/80x80/"+fun+".png\" width=40 height=40 />");
			}else{
				var img = document.createElement("img");
				img.setAttribute("style", "float:left;margin-right:10");
				img.src="/theme/images/shortcut/80x80/"+fun+".png";
				img.width="40";
				img.height="40";
		
			}
		
			//create title
			var tmenu_title = document.createElement("div");
			var title = document.createTextNode(treename);
			tmenu_title.className="tmenu_title";
			tmenu_title.appendChild(title);
		
			//create description
			var tmenu_desc = document.createElement("div");
			if(desc==""){
				tmenu_desc.style.height="22px";
			}
			var desc = document.createTextNode(desc);
			tmenu_desc.className="tmenu_desc";
			tmenu_desc.appendChild(desc);
		
			//build div node 
			tmenu_record.appendChild(img);
			tmenu_record.appendChild(tmenu_title);
			tmenu_record.appendChild(tmenu_desc);
			a.appendChild(tmenu_record);
			document.getElementById("searchtree").appendChild(a);
		},
	
		/**
		* Setting value of current page
		* @param obj treeobj = {fun : link function,
		*			treeid: tree ID,
		*			treename: tree's name,
		*			cateid: categorize's ID,
		*			catename:categorize's name }
		* @param string fun:link function
		* @param number treeid:tree ID
		* @param string treename: tree's name
		* @param number cateid: categorize's ID
		* @param string catename:categorize's name
		*/
		setCurrentPage:function(treeobj,fun,treeid,treename,cateid,catename){
			this.clearSearchLayout();
			Ext.getCmp('searchtxt').setValue();
			g_tree = {};
			if(typeof treeobj == "object"){
				g_tree = treeobj;  
			}else if (fun && treeid && treename && cateid && catename){
				g_tree.fun = fun;
				g_tree.treeid = treeid;
				g_tree.treename = treename;
				g_tree.cateid = cateid;
				g_tree.catename = catename; 
			}else{
				return;
			}
			//dom_nav.innerHTML= g_tree.catename+" &#62; "+g_tree.treename; 
				
			Manual.set(1,g_tree.treeid);		 
			processUpdater('/adm/getmain.php','fun='+g_tree.fun);  
			//Ext.getCmp("tree_"+g_tree.cateid).expand();  
		},

		/**
		* getting value of current page
		* 
		* @param object treeall : all of tree list object. 
		* @param string find: find 'fun' name of tree list.
		* 
		* @return obj treeobj = {fun : link function,
		*			treeid: tree ID,
		*			treename: tree's name,
		*			cateid: categorize's ID,
		*			catename:categorize's name }
		*/
		getCurrentPage:function(treeall,find){   
			for(var i in treeall){
				if(typeof treeall[i]=='object'){
					var coo = this.getCurrentPage(treeall[i],find);
					if(coo){  
						return coo; 
					}
				}else if(i=="fun" && treeall[i].toString() === find){  
					var oo = {};
					oo.treename=treeall["treename"];
					oo.treeid=treeall["treeid"]; 
					oo.cateid=treeall["cateid"]; 
					oo.catename=treeall["catename"]; 
					oo.fun=find;  
					return oo;
				} 
			} 
		},  

		/**
		* go to home (shortcut)
		* 
		*/
		NavigatorIndex:function(){ 
			g_tree = {};
			Manual.set('','');
			processUpdater('getmain.php','fun=shortcut');
			document.getElementById("nav").innerHTML=""; 
		}
	}
}();

