/**
* Shortcut javascript function 
*/
// shortcut variables
var select_shortcut='';
var select_node;  
var select_treename;
var shortcut_imgpath='/theme/images/shortcut/';
var shortcut_imgpath1515=shortcut_imgpath+'15x15/';  

/**
* shortcutRightClick 
* when user right click on menu tree than handle this function. 
* @param string treeid
* @param string treename
* @param object node: tree node object 
*/ 
function shortcutRightClick(treeid,treename,node){
	select_node = node;
	select_treeid = treeid;  
	select_treename = treename;  
	processAjax("getmain.php?fun=shortcut",showShortCutMenu,"ac=find&treeid="+select_treeid,false); 
}
  

/**
* showShortCutMenu
* handler after right click, showing buttion status(add/remove)
*/
function showShortCutMenu(){
	var node = select_node;
	var request = eval('('+this.req.responseText+')'); 
	node.select();  
	ctMenu.show(node.ui.getAnchor()); 
 
	Ext.getCmp('ct_add').setDisabled(false);
	Ext.getCmp('ct_remove').setDisabled(false);  
	if(request.find){ 
		Ext.getCmp('ct_add').setDisabled(true);
	}else{
		Ext.getCmp('ct_remove').setDisabled(true); 
	}  
}


/**
* showShortCutMenu_action
* handle after click from contentmenu add/remove
*/
function showShortCutMenu_action(){
  if(document.getElementById('currentpage').value=='shortcut') {
  	TreeMenu.NavigatorIndex();  
  }
}


/**
* Shortcut_nav_add
* click add header shortcut icon button.
*/
function Shortcut_nav_add(word_title,word_action)
{
	var tree = TreeMenu.getValue();
	if(tree.treename!=undefined){
		processAjax("setmain.php?fun=setshortcut",showShortCutMenu_action,"ac=add&treeid="+tree.treeid,false);
		Ext.bubble.msg(word_title,word_action+"\""+tree.treename+"\"");
	};
}

/**
* Shortcut_nav_del
* click remove header shortcut icon button.
*/
function Shortcut_nav_del(word_title,word_action)
{
	var tree = TreeMenu.getValue();
	if(tree.treename!=undefined){
		processAjax("setmain.php?fun=setshortcut",showShortCutMenu_action,"ac=remove&treeid="+tree.treeid,false);
		Ext.bubble.msg(word_title,word_action+" \""+tree.treename+"\"");  
	}
}


 