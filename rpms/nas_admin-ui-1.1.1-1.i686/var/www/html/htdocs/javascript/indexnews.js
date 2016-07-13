/**
* IndexNews  class
* Index alert immediate news
* 
* @author Heidi 
*
* @property object  [HTMLInputElement] dom_log  
* @property object  [HTMLInputElement] dom_news 
* @property object  [HTMLInputElement] dom_menubtn  
* @property object  [HTMLInputElement] dom_menulayout 
* @property object  [HTMLInputElement] dom_menucount  
* @property string menuname: current selected menu name.(log/news) 
* @property boolean isIE : check browser is 'IE' return true, otherwise false.
*
* @method init(): initialized function.
* @method onclickNewsBtn(name): click immediate news name, (log/news).
* @method onloadNewsList(): showing immediate news list.
* @method hideLayout(): hide index news layout.
*    
*/
var IndexNews = function(){ 
	var dom_log
	var dom_news;   
	var dom_menubtn;
	var dom_menulayout;
	var dom_menucount; 
	var menuname; 
	var isIE = false;   
	return {   
		/**
		* initialized
		* 
		*/
		init:function(){
			dom_news = Ext.getCmp('news_btn');
			dom_news.on('click', function(){
				TreeMenu.setCurrentPage(treenews[0])
			});
			
			dom_log = Ext.getCmp('log_btn');
			dom_log.on('click', function(){
				TreeMenu.setCurrentPage(treelog[0])
			});
		}, 
		
		/**
		* onclickNewsBtn
		* @param string name: immediate news name, (log/news)
		*/
		onclickNewsBtn:function(name){
		},
		
		/**
		* onloadNewsList
		* 
		*/
		onloadNewsList:function(){
		},
		 
		
		/**
		* hideLayout
		* 
		*/
		hideLayout:function(e){   
			var targ
			if (!e) var e = window.event
			if (e.target) targ = e.target
			else if (e.srcElement) targ = e.srcElement 

			if(dom_menulayout){
				if(targ.id!="news_ul"  && targ.id!="log_ul" && targ.className!="li_none"){  
						dom_menulayout.className = "hidden";
						dom_menubtn.className="";  
				}
			} 
		} 
		
 
	}
}();