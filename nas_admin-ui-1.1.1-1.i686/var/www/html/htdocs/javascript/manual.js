/**
* Manual class
* 
* @author Heidi 
*
* @property object  [HTMLInputElement] dom_manual  
* @property object  [HTMLInputElement] dom_manual_menu 
* @property object  [HTMLInputElement] dom_manual_close  
* @property object  [HTMLInputElement] dom_iframe 
* @property object  [HTMLInputElement] dom_tab_global 
* @property object  [HTMLInputElement] dom_tab_special 
* @property boolean isIE : check browser is 'IE' return true, otherwise false.
*
* @method init(): initialized function.
* @method searchManual(msg): search menual.
* @method showMenu(): show manual menu.
* @method hideMenu(): hide manual menu. 
* @method set(cid,id): click manual left tab button  
* @method cleanSearchInput(isClean): clean search text value.
* 
*/
var Manual = function(){   
	var dom_manual,dom_manual_menu,dom_manual_close,dom_iframe,dom_tab_global,dom_tab_special; 
	var isIE = false; 
	var timeoutid_manual;
	var during = 1;		
	var current_manual_page = {};
	return {   
		/**
		* initialized
		* 
		*/
		init:function(){  
			dom_manual_menu = Ext.get('manual_menu');
			dom_manual_close = document.getElementById("manual_close");
			dom_iframe = document.getElementById('iframe_manual'); 
			dom_tab_global = document.getElementById("tab_global"); 
			dom_tab_special = document.getElementById('tab_special'); 
			dom_manual_search = document.getElementById('manual_search'); 
			
			
			
			if(navigator.userAgent.indexOf('MSIE')>-1){
				isIE = true;  
				dom_manual_close.attachEvent("onmousedown",Manual.hideMenu);
				dom_tab_global.attachEvent("onmousedown",function(){Manual.set('','')});
				
			}else{  
				dom_manual_close.addEventListener("mousedown",Manual.hideMenu,false); 
				dom_tab_global.addEventListener("mousedown",function(){Manual.set('','')},false);
			} 
		},

		/**
		 * Manual search
		 * @param string msg: search wording
		*/
		searchManual:function(msg){   
			if(timeoutid_manual){
				clearTimeout(timeoutid_manual);
			}  
			var functioname="document.getElementById('iframe_manual').src='/adm/manual.php?searchmsg="+msg+"'";
			
			//every 0.5 sec. 
			timeoutid_manual = setTimeout(functioname,during*100); 
		},  
		
		/**
		* showMenu  
		*/
		showMenu:function(){
			var h = Ext.get('content-panel').getHeight();
			Ext.get('iframe_manual').setHeight(h - 55);
			dom_manual_menu.addClass("show");
		}, 
		
		/**
		* hideMenu 
		*/
		hideMenu:function(){  
			dom_manual_menu.removeClass("show");
		},  
		
		/**
		* set 
		* @param string cid: manual table cid
		* @param string id: manual table id (treeid/logid/..)
		*/
		set:function(cid,id){    
			var isClean;
			if(id!="" && cid!=""){
				dom_iframe.src="/adm/manual.php?id="+id+"&cid="+cid; 
				dom_tab_global.className = "tab_white";
				dom_tab_special.className = "tab_gray";  
				isClean=true; 
				current_manual_page = {"cid":cid,"id":id};
			}else{
				dom_iframe.src='/adm/manual.php';
				dom_tab_global.className = "tab_gray";
				dom_tab_special.className = "tab_white";  
				isClean=false; 
				document.getElementById('tab_special').innerHTML="<a href=\"javascript:void(0)\" onmousedown=\"Manual.set("+current_manual_page.cid+","+current_manual_page.id+")\">"+document.getElementById('tab_special').innerHTML+"</a>";;  
			} 
			this.cleanSearchInput(isClean);
			  
		},  
		
		
		/**
		 * clean search text value
		 * @param {boolean} isClean
		 */
		cleanSearchInput:function(isClean){
			if(isClean){
				if(dom_manual_search){
					dom_manual_search.style.display='none';
				}
			}else{
				dom_manual_search.style.display='block';   
			}
		}
 
	}
}();

 

