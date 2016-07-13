/*
* public variables.
*/
var mainMask;  //loading mask.
var myMask;  //loading mask.
var systatus_refresh;
var monitor_reboot,monitor,chk_treemenu;
var baseFun='';
var monitor_sec=12;
var fwMask;
var altKey  = false;
var keyCode = 0; 
var rebootflag=0;  
var g_height =0; //page height 
var mod_lock = false; 
var change_role=0;
 

/*
* Find ClassName,return ElementID
* @param n string  
*/
function getElementsByClassName(n) { 
    var el = [],
      _el = document.getElementsByTagName('*');
    var _ary = n.split(','); 
    for (var j=0; j<_ary.length; j++ ) { 
        for (var i=0; i<_el.length; i++ ) { 
            if (_el[i].className == _ary[j] ) {
                el[el.length] = _el[i];
            }
        }
    }
    return el;
}


/*
* javascript trim 
*/
function trim(instr){
  instr = instr.replace(/^[\s]*/gi,"");
  instr = instr.replace(/[\s]*$/gi,"");
  return instr;
}  

/*
* hidden or visible UI,those object must name is "s" , used in power.tpl.
* @param choice string - checked status
* @param objname string - this obj is controled.
*/     
function Disable_Fn(choice,objname){
  var fn = document.getElementsByName(objname);
  if(choice){
    for(var i=0;i < fn.length;i++){
      for (var j=0;j <fn[i].childNodes.length;j++){
        if (fn[i].childNodes[j].nodeName == "TD"){
          for (var k=0;k <fn[i].childNodes[j].childNodes.length;k++){
            if ((fn[i].childNodes[j].childNodes[k].nodeName == "INPUT")||
              (fn[i].childNodes[j].childNodes[k].nodeName == "SELECT")||
              (fn[i].childNodes[j].childNodes[k].nodeName == "TEXTAREA")){
                 fn[i].childNodes[j].childNodes[k].disabled = false;
              fn[i].childNodes[j].childNodes[k].className="x-form-text x-form-field";
              }
          }
        }
      }
    }
  }
  else{
    for(var i=0;i < fn.length;i++){
      for (var j=0;j <fn[i].childNodes.length;j++){
        if (fn[i].childNodes[j].nodeName == "TD"){
          for (var k=0;k <fn[i].childNodes[j].childNodes.length;k++){
            if ((fn[i].childNodes[j].childNodes[k].nodeName == "INPUT")||
               (fn[i].childNodes[j].childNodes[k].nodeName == "SELECT")||
               (fn[i].childNodes[j].childNodes[k].nodeName == "TEXTAREA")){
              fn[i].childNodes[j].childNodes[k].disabled = true;
              fn[i].childNodes[j].childNodes[k].className="x-form-text x-form-field x-item-disabled";
              }
          }
        }
      }
    }
  }
}


/*
* remove spaces from a string.
* @param s string
* @returns a new string resulting from removing all space in this string.
*/
function replaceStr(s) { 
  return s.replace(/\n/g, ""); 
}


/*
* combining multiple POST variables into one variable
* @param data object
* @returns parameter after combine POST variables.
*/
function setParam(data){
  var param='';
  var len = data.length;
  for(var i=0;i<len;i++){
    var n = data[i].name;
    var t = data[i].type;
    var v = data[i].value;  
    var c = data[i].checked;  
    if((t=='textarea') || (t=='radio' && c ) || (t=='text') || (t=='select-one') || (t=='hidden') || (t=='checkbox'&& c) || (t=='password')  ){ 
      param+= n+'='+encodeURIComponent(v)+'&'; 
    }  
  } 
  return param;
} 

/*
* setting current page in element.purpose is lock page,not to change.
* @param currentpage string
*/
function setCurrentPage(currentpage){ 
  if(document.getElementById('currentpage')!=null)
          document.getElementById('currentpage').value=currentpage;
} 


/*
* send param used ajax framework.
* @param url string 
* @param fun function()
* @param data object
*/
function processAjax(url,fun,data,maskhide){
  if(data!=undefined){
      if(typeof(data)=='object')
          data = setParam(data); 
      if(maskhide!=undefined){
          new net.ContentLoader(false,url,fun,null,'POST',data);  
      }else{
          new net.ContentLoader(true,url,fun,null,'POST',data);  
      }
  }else{
      new net.ContentLoader(false,url+'&'+Math.round(Math.random()*999+1),fun);
  }
}



/*
* send param used Ext.Updater.
* @param url string
* @param fun parameter
*/
function processUpdater(url,fun){
    if ((typeof(TCode) != 'undefined') && TCode.desktop && TCode.desktop.Group && !/shortcut/.test(fun)) {
        TCode.desktop.Group.processUpdater(url,fun);
        return;
    }

  Ext.onReady(function(){
        Ext.Msg.hide();
        Ext.TaskMgr.stopAll();
        if(typeof(ExtDestroy)=='function'){
              ExtDestroy();
              var classBlack = getElementsByClassName('x-dd-drag-proxy x-dd-drop-nodrop,'+
                                                      'x-window-proxy,'+
                                                      'x-resizable-proxy x-unselectable,x-shadow,ext-el-mask');
              for (var i=0; i<classBlack.length; i++){
                   if(classBlack[i].className=='ext-el-mask'){
                           document.getElementById(classBlack[i].id).style.display='none';
                   }else{
                           classBlack[i].parentNode.removeChild(classBlack[i]);
                   }
              }
        }
        if(myMask)
             myMask.show();
        baseFun=fun;
        if(!Ext.get('content'))
           location.href='index.php';
        Ext.get('content').addClass('content-hide');
        Ext.get('content').getUpdater().update({
              timeout:180,
              url:url,
              scripts:true,
              callback:after_processUpdater,
              params:fun
        });
	    
  });
}
 
function after_processUpdater(res){
    var x = res.dom.innerHTML;                                                                                 
    var str = /"show":true/;                            
    var id = baseFun.substring(4,baseFun.length);                                                                                          
    //fsck rule                                                                                                                            
    if(id==''){                                                                                                                            
        if(myMask){                                                                                                                        
            myMask.hide();                                                                                                                 
        }                                                                                                                                  
    }else{                                                                                                                                 
        if(str.test(x)){                                                                                                                   
            if(x=='logout'){                                                                                                               
                location.href='/index.php';                                                                                                
            }                                                                                                                              
            var request = eval('('+x+')');                                                                                                 
            if (!request) {                                                                                                                
                Ext.get('content').removeClass('content-hide');
                return;                                                                                                                    
            }
            if (!request.show) {
                if (!request.fn  || request.fn === "") {                                                                                   
                    return;                                                                                                                
                }                                                                                                                          
                eval(request.fn);                                                                                                          
                return;                                                                                                                    
            };                                                                                                                             
            if(request.icon=='ProgressBar'){                                                                                               
                progress_bar(request.topic,request.message,request.interval,request.duration,request.button,request.fn,request.ifshutdown);
            }else{                                                                                           
                mag_box(request.topic,request.message,request.icon,request.button,request.fn,request.prompt);
            }                                         
        }else{                                        
            setCurrentPage(id);                       
        }                                             
    }                                                 
    if(myMask){                                       
        myMask.hide();                                
    }                                                 
}




/*
* show message_box.
* @param  topic string: maxbox title
* @param  message string: maxbox content
* @param  icon string: QUESTION,WARNING,ERROR,INFO
* @param  button string: OKCANCEL,YESNO,YESNOCANCEL,OK
* @param  fn string: execute action
* @param  prompt  boolean : true, false
*/
function mag_box(topic,message,icon,button,fn,prompt)
{
   Ext.Msg.show({
           title:topic,
           minWidth:300,
           msg:message,
           closable:false,
           buttons:eval('Ext.MessageBox.'+button),
           fn:function(btn){
               for(var key in fn)
                   if(btn==key)
                      eval(fn[key]);
           },
           icon:eval('Ext.MessageBox.'+icon),
           prompt:prompt
           });
}
                                                          
/*
* show progress bar.
* @param  topic string: maxbox title
* @param  message string: maxbox content
* @param  interval integer: 1
* @param  duration integer: 60
* @param  button string: OKCANCEL,YESNO,YESNOCANCEL,OK
* @param  fn string: execute action
*/
function progress_bar(topic,message,interval,duration,button,fn,ifshutdown)
{
	var winpb = new Ext.Window({
		modal: true,
		id: 'pbindow',
		width: 200,
		closable:false,
		title: topic,
		resizable:false,
		items: [{
			xtype:'label',
			text:message
		},{
			xtype: 'progress',
			id: 'pProgress',
			autoWidth: false,
			//text: 'Exporting data (0%)'
			text: '0'
		}],
		listeners: {
			show: function() {
				var progressBar1 = Ext.getCmp("pProgress");
				mainMask.hide();
				clearTimeout(monitor);
				Runner.run(progressBar1,  duration, function(){
					progressBar1.reset();
					progressBar1.updateText('Done, '+wait_msg);
					
                    if (ifshutdown==''){
                        rebootflag=1;
                        onReboot();
                    }else
                        progressBar1.updateText(ifshutdown);
				});
			}
		}
	});
	
	var Runner = function(){
		var f = function(v, pbar,  count, cb){
			return function(){
				if(v > count){
					cb();
				}else{
					var c=(count+1)-v;
					//pbar.updateProgress(c/count, 'Loading item ' + v + ' of '+count+'...');
					pbar.updateProgress(c/count, c);
					//alert("v/count="+(v/count));
				}
			};
		};
		return {
			run : function(pbar,  count, cb){
				//var ms = count*1000/count;
				var ms = interval*1000;
				for(var i = 1; i < (count+2); i++){
					setTimeout(f(i, pbar,  count, cb), i*ms);
				}
			}
		}
	}();
	winpb.show();
}
                                                          
                                                         
                                                       
function onReboot(){
	monitor_reboot = setTimeout("processAjax('/index.php?rb',onReboot)",3*1000); //load system config every 3 sec.
}
/*
* alert message
*/
function onLoadForm(){ 
  if(this.req.responseText=='logout'){
      location.href='/index.php';
  }
  var request = eval('('+this.req.responseText+')');  
	if (!request) return;
	if (!request.show) {
		if (!request.fn  || request.fn === "") {
			return;
		}
		eval(request.fn);
		return;
	};


    if(request.icon=='ProgressBar'){
      progress_bar(request.topic,request.message,request.interval,request.duration,request.button,request.fn,request.ifshutdown);
    }else{
      mag_box(request.topic,request.message,request.icon,request.button,request.fn,request.prompt);
    }
} 

/*
* load data.
*/
function onLoadPHP(){  
  var request = eval("("+replaceStr(this.req.responseText)+")");  
  if(request.currentpage==document.getElementById('currentpage').value){   
    document.getElementById('content').innerHTML=request.html;  
    var script=document.getElementById("script_Dynamic");  
    if (script!=null) {
      script.parentNode.removeChild(script); 
    }
    script=document.createElement("script"); 
    script.id = "script_Dynamic";
    script.text = request.js;  
    var head=document.getElementsByTagName("head")[0].appendChild(script);   
  }
} 


/*
* Language JumpMenu , used in index.tpl.
* @param targ string - target.
* @param selObj string - self object.
* @param restore string - if restore set true,else false.
*/
function language_jumpMenu(jumpurl,selObj){ //v3.0
  document.getElementById('ffKeyTrap').value='116';
  if (!TCode.desktop.Group.hidden && TCode.desktop.Group.current) {
    window.location = jumpurl + '?lang=' + selObj + '&current=' + TCode.desktop.Group.current.fun;
  } else {
    window.location = jumpurl + '?lang=' + selObj;
  }
}



/*
* closeSession
* @param evt int - event.  
*/
function closeSession(evt){ 
    evt = (evt) ? evt : event; 
    clickY  = evt.clientY;
    clickX  = evt.clientX;
    altKey  = evt.altKey;
    keyCode = evt.keyCode; 
    
    // Window Closing in FireFox
    if(!evt.clientY){  
        keyVals = document.getElementById('ffKeyTrap');  
        if(keyVals.value!='116'){
            // capturing ALT + F4 or close by "X"
            if(keyVals.value == 'true115' || keyVals.value == ''){
                location.href='logout.php';
            }
        }
 
    } else { 
     // Window Closing in IE   
          if(keyCode!=116){
            // capturing ALT + F4 or close by "X"
            if ((altKey == true && keyCode == 115) || clickY < 0){  
                location.href='logout.php';
            } else { 
                return void(0);
            } 
          }
    }
}
/*
* whatKey
* @param evt int - event.  
*/
function whatKey(evt){
    evt = (evt) ? evt : event;
    keyVals = document.getElementById('ffKeyTrap');
    altKey  = evt.altKey;
    keyCode = evt.keyCode;
    //ALT + F4 = close 
    if(altKey && keyCode == 115){
        keyVals.value = String(altKey) + String(keyCode);
    }
    //F5 = reload
    if(keyCode==116){
        keyVals.value = String(keyCode);
    }
}
 



/*
* event is used by programmers to kick-start their web applications.
window.onkeydown      = whatKey;
window.onbeforeunload = closeSession;  
*/
window.onload = function(){
  myMask = new Ext.LoadMask(document.getElementById('content-panel'), {msg:wait_msg+"..."}); 
  mainMask = new Ext.LoadMask(Ext.getBody(),{msg:wait_msg+"..."}); 
  mainMask.hide();
  TreeMenu.init(treeobj);
  Manual.init();
  detectPageHeight();
	setCurrentPage(currentpage);
    processUpdater('getmain.php','fun='+currentpage); 
	if(Ext.getCmp("Store_log")){
		Ext.getCmp("Store_log").load({params:{name:"popuplog"}});  
	}
	processAjax('getmain.php?fun=nasstatus',onloadSysConfig); 
	
	var fadeOutMask = function()
	{
		Ext.get('loading').remove();
		Ext.get('loading-mask').fadeOut({remove:true});   
	}
	if(Ext.get('loading')){  
		setTimeout(fadeOutMask,800);
		fadeOutMask = null; 
	}
}

Ext.EventManager.onWindowResize(function(){ 
  detectPageHeight();
})

/**
 * detect current page height
 */
function detectPageHeight() {
    // This function is not need any more
    return;
}
 
/*
*  monitor nasstatus,and create  treemenu
*/
function onloadSysConfig(){  
	if(this.req.responseText!=''){ 
		var req_root = eval("("+this.req.responseText+")"); 
		if(typeof req_root!=='object'){
			location.href='/adm/logout.php';
			return false;
		}
		var logcount = req_root.log;
		//var newscount = req_root.news; 
		if(logcount>0){
			Ext.getCmp('log_btn').addClass('t-log-more');
		}else{
			Ext.getCmp('log_btn').removeClass('t-log-more');
		}
		//if(newscount>0){
		//	Ext.getCmp('news_btn').addClass('t-news-more');
		//} else{ 
		//	Ext.getCmp('news_btn').removeClass('t-news-more');
		//}
		
	  /****************************************
	            NasStatus Monitor
	  *****************************************/ 
	switch( req_root.fan ) {
	case 'none':
		Ext.getCmp('t-fan-status').hide();
		Ext.getCmp('t-fan-status').removeClass('t-fan-status-inactive t-fan-status-active');
		break;
	case 'on':
		Ext.getCmp('t-fan-status').show();
		Ext.getCmp('t-fan-status').removeClass('t-fan-status-active');
		Ext.getCmp('t-fan-status').addClass('t-fan-status-inactive');
		break;
	case 'off':
		Ext.getCmp('t-fan-status').show();
		Ext.getCmp('t-fan-status').removeClass('t-fan-status-inactive');
		Ext.getCmp('t-fan-status').addClass('t-fan-status-active');
		break;
	default:
	}
	switch( req_root.ups ) {
	case 'none':
		Ext.getCmp('t-ups-status').hide();
		Ext.getCmp('t-ups-status').removeClass('t-ups-status-inactive t-ups-status-active');
		break;
	case 'on':
		Ext.getCmp('t-ups-status').show();
		Ext.getCmp('t-ups-status').removeClass('t-ups-status-active');
		Ext.getCmp('t-ups-status').addClass('t-ups-status-inactive');
		break;
	case 'off':
		Ext.getCmp('t-ups-status').show();
		Ext.getCmp('t-ups-status').removeClass('t-ups-status-inactive');
		Ext.getCmp('t-ups-status').addClass('t-ups-status-active');
		break;
	default:
	}
	switch( req_root.temp ) {
	case 'none':
		Ext.getCmp('t-temp-status').hide();
		Ext.getCmp('t-temp-status').removeClass('t-temp-status-inactive t-temp-status-active');
		break;
	case 'on':
		Ext.getCmp('t-temp-status').show();
		Ext.getCmp('t-temp-status').removeClass('t-temp-status-active');
		Ext.getCmp('t-temp-status').addClass('t-temp-status-inactive');
		break;
	case 'off':
		Ext.getCmp('t-temp-status').show();
		Ext.getCmp('t-temp-status').removeClass('t-temp-status-inactive');
		Ext.getCmp('t-temp-status').addClass('t-temp-status-active');
		break;
	default:
	}
	switch( req_root.raid ) {
	case 'none':
		Ext.getCmp('t-raid-status').removeClass('t-raid-status-inactive t-raid-status-active');
		break;
	case 'on':
		Ext.getCmp('t-raid-status').removeClass('t-raid-status-active');
		Ext.getCmp('t-raid-status').addClass('t-raid-status-inactive');
		break;
	case 'off':
		Ext.getCmp('t-raid-status').removeClass('t-raid-status-inactive');
		Ext.getCmp('t-raid-status').addClass('t-raid-status-active');
		break;
	default:
	}
	switch( req_root.disk ) {
	case 'none':
		Ext.getCmp('t-disk-status').removeClass('t-disk-status-inactive t-disk-status-active');
		break;
	case 'on':
		Ext.getCmp('t-disk-status').removeClass('t-disk-status-active');
		Ext.getCmp('t-disk-status').addClass('t-disk-status-inactive');
		break;
	case 'off':
		Ext.getCmp('t-disk-status').removeClass('t-disk-status-inactive');
		Ext.getCmp('t-disk-status').addClass('t-disk-status-active');
		break;
	default:
	}
	  if(req_root.modup.modupgrade_enabled=="1"){
		  if(req_root.raid=="on" && req_root.modup.mod_upgrade=="0" && mod_lock === false){  
				newModInstall.DATA = req_root.modup.mod_data; 
				newModInstall.init(req_root.modup.mod_form); 
				mod_lock = true;
		  } 
	  }
	  
	  HA.monitor(req_root.ha);  // monitor HA
		  


		  
	  /**
	  * Burning DVD .....
	  */
	  if(req_root.dvd !== null ){
           var progress = req_root.dvd.progress;
           var res = req_root.dvd.res;
           var msg = req_root.dvd.msg;
           var wording = req_root.dvd.wording;
           
           //dvd burning ...
           if(res!='102'){
           
               //show alert
               Ext.MessageBox.show({
                  title: wording[0],
                  msg: wording[1],
                  progressText: '0%',
                  width:300,
                  progress:true,
                  closable:false,
                  icon:'ext-mb-download',
                  buttons:Ext.Msg.CANCEL,
                  fn:function(){
		      if(typeof AjaxRequest !=='undefined')AjaxRequest.abort();
                      processAjax('setmain.php?fun=setdvd',onLoadForm,'ac=cancel');
                  }
              });
              
              //update progress bar
              if(progress){
                  Ext.MessageBox.updateProgress(progress/100, progress+'%');
                  Ext.MessageBox.updateText(msg);
              }
              
              //success alert
              if(progress == 100){
                  Ext.MessageBox.hide();
                  Ext.Msg.show({title:wording[2], msg:wording[3], icon:Ext.MessageBox.INFO, buttons:Ext.Msg.OK,fn:function(){
                      processAjax('setmain.php?fun=setdvd',onLoadForm,'ac=cancel');
                  }});
              }
                
           //error....
           }else{
               Ext.Msg.show({title:wording[2], msg:msg, icon:Ext.MessageBox.ERROR, buttons:Ext.Msg.OK,fn:function(){
                   processAjax('setmain.php?fun=setdvd',onLoadForm,'ac=cancel');
               }});
           }
		   
	  }

	  /****************************************
	           Update treemenu
	  *****************************************/  
	  var request = req_root.tree;
	  var size = request.length;
	  
	  //remove all treemenu
		for (var a = 0; a < size; a++) { 
			var node = Ext.getCmp("item_"+request[a].treeid).root;
			while (node.firstChild) {
				node.removeChild(node.firstChild);
			}
		} 
	 
	  	//create treemenu 
		for(var a=0;a<size;a++){  
			var node = Ext.getCmp("item_"+request[a].treeid).root.childNodes; 
                        if(request[a].detail){
                            for(var k=0;k<request[a].detail.length;k++){ 
				var newNode = new Ext.tree.TreeNode({
					text:request[a].detail[k].treename,
					id:request[a].detail[k].treeid,
					cateid:request[a].detail[k].cateid,
					catename:request[a].catename,
					fun:request[a].detail[k].fun,
					img:request[a].detail[k].img,
					expanded:true,
					iconCls:'treenode-icon'
				}); 
				if(request[a].detail[k].treeid!=''){ 
					//click handler 
					newNode.addListener('click',function(v){ 
						TreeMenu.setCurrentPage(false,v.attributes.fun,v.id,v.text,v.attributes.cateid,v.attributes.catename); 
					});    
					//right click handle (shortcut)
					newNode.addListener('contextmenu',function(node,e){ 
						shortcutRightClick(node.attributes.id,node.attributes.text,node); 
			  		});   
					// image
					newNode.attributes.icon=shortcut_imgpath1515+request[a].detail[k].img+'.gif';  
				}  
				Ext.getCmp("item_"+request[a].treeid).root.appendChild(newNode); 
				Ext.get('icon-nav-'+request[a].value).src="/theme/images/index/"+request[a].value+".gif"; 
                            } 
                        }
		}     
	}
  
  monitor = setTimeout("processAjax('getmain.php?fun=nasstatus',onloadSysConfig)",monitor_sec*1000); //load system config every 15 sec.
  if(mainMask){
  	mainMask.hide();  
  }
}  

/*
* Check if @str include not single byte char and return false.
* @str: [IN] input string
* @return: true or false
*/
function singleByteCheck(str)
{
	var len = str.length;
	for (var i = 0; i < len; i++) {
		if (str.charCodeAt(i) > 126 || str.charCodeAt(i) <= 32) {
			return false;
		}
	}
	return true;
}

/*
* patch, which fixes problem with 'change' event on RadioGroup
*/
Ext.override(Ext.form.RadioGroup, { 
    afterRender: function() {
        var group = this;
        this.items.each(function(field) {
            // Listen for 'check' event on each child item
            field.on("check", function(self, checked) {             
              // if checkbox is checked, then fire 'change' event on RadioGroup container
              if(checked)
                // Note, oldValue (third parameter in 'change' event listener) is not passed, 
                // because is not easy to get it
                group.fireEvent('change', group, self.getRawValue());
               
            });
        });       
        Ext.form.RadioGroup.superclass.afterRender.call(this)
    },
      getName: function() {
        return this.items.first().getName();
      },
    
      getValue: function() {
        var v;
    
        this.items.each(function(item) {
          v = item.getRawValue();
          return !item.getValue();
        });
    
        return v;
      },
    
      setDisableds: function(v,flag) {
        if(this.rendered){
    	      this.items.each(function(item) {
    	          if(item.getRawValue()==v)
    	      	       item.setDisabled(flag);
    	      });
        }else{
    	      for(k in this.items){ 
    	          if(this.items[k].inputValue==v) 
    	      	        this.items[k].disabled = flag; 
    	      }
    	}
      },
      
      setValue: function(v) {
        if(this.rendered)
    	      this.items.each(function(item) {
    	          item.setValue(item.getRawValue() == v);
    	      });
         else
    	      for(k in this.items) this.items[k].checked = this.items[k].inputValue == v;
      } 
});   


Ext.override(Ext.form.ComboBox,{
     autoSize : function(){
        if(!this.rendered){
            return;
        }
        if(!this.metrics){
            this.metrics = Ext.util.TextMetrics.createInstance(this.el);
        }
        var el = this.el;
        var v = el.dom.value + " ";
        var w = Math.min(this.growMax, Math.max(this.metrics.getWidth(v) +  10, this.growMin));
        this.el.setWidth(w);
        //resize the parent node as well so the layout doesnt get messed up
        Ext.get(this.el.dom.parentNode).setWidth(w+17); //17 is the width of the arrow
        this.fireEvent("autosize", this, w);

    }

});

    

Ext.override(Ext.Button,{
        setIcon: function(icon) {
            this.icon = icon;
            this.el.select('button').item(0).setStyle('background-image', 'url(' + this.icon + ')');
        }
}); 


Ext.form.SliderField = Ext.extend(Ext.Slider, {
	isFormField: true
	,setMsg:''
	,setZero:''
	,setV:''
	,onRender: function(){
		Ext.form.SliderField.superclass.onRender.apply(this, arguments);
		if (this.value == 0)
			v=this.setZero;
		else
			v=this.value+this.setMsg;
      this.nrField = this.el.createChild({
				//tag: 'input', type: 'text', name: this.name, value: v, readonly: 'readonly', style: 'position: relative; float:right; height:20px; left: 80px; margin-top:-20px; font-size:12px;width:60px;'
				tag: 'label', html: v, style: 'position: relative; float:right;height:20px; left: 120px; margin-top:-20px; font-size:12px;width:100px;'
			});
      this.nrField2 = this.el.createChild({
				tag: 'input', type: 'hidden', name: this.name, value: v, readonly: 'readonly', style: 'position: relative; float:right; height:20px; left: 80px; margin-top:-20px; font-size:12px;width:60px;'
				//tag: 'label', html: v, style: 'position: relative; float:right;height:20px; left: 80px; margin-top:-20px; font-size:12px;width:60px;'
			});
	}
	,setValue: function(v,v2) {
		if(this.maxValue && v > this.maxValue) v = this.maxValue;
		if(this.minValue && v < this.minValue) v = this.minValue;
        
		Ext.form.SliderField.superclass.setValue.apply(this, arguments);

		if (v == 0){
			this.nrField2.dom.value = this.setZero;
			this.nrField.dom.innerHTML = this.setZero;
		}else{
			if(this.setV!="" || (v2!=undefined && v2!="")){
				if(v2==null || v2==false) return;
				this.nrField.dom.innerHTML = v2 + this.setMsg;
				this.nrField2.dom.value = v2 + this.setMsg;
			}else{
				this.nrField2.dom.value = v + this.setMsg;
				this.nrField.dom.innerHTML = v + this.setMsg;
			}
		}
	}
	,markInvalid: Ext.emptyFn
	,clearInvalid: Ext.emptyFn
	,validate: function(){this.nrField.dom.disabled=false;this.nrField2.dom.disabled=false;return true;}
}); 

Ext.override(Ext.tree.TreeNode, {
	setIconCls: function(src,remove) { 
    var newCls = src; 
    var oldCls = remove; 
		this.attributes.iconCls = newCls;
		var iel = this.getUI().getIconEl();
		if (iel) {
			var el = Ext.get(iel);
			if (el) { 
      	el.removeClass(oldCls); 
      	el.addClass(newCls); 
			}
		}
	}
});

Ext.override(Ext.layout.BorderLayout.Region, {
    initAutoHide: Ext.layout.BorderLayout.Region.prototype.initAutoHide.createSequence(function(){
        this.panel.fireEvent('slideout', this.panel);
    }),
    afterSlideIn: Ext.layout.BorderLayout.Region.prototype.afterSlideIn.createSequence(function(){
        this.panel.fireEvent('slidein', this.panel);
    })
});


var close_all_layer = function(){ 
	//document.getElementById("shutdownid").className="tmenu tmenu_shutdown hidden";   
}  


Ext.clone = function(o, c, defaults){
    if(defaults){
        Ext.clone(o, defaults);
    }
    if(o && c && typeof c == 'object'){
        for(var p in c){
            if( typeof c[p] == "object" ) {
                o[p] = Ext.clone({}, c[p]);
            } else {
                o[p] = c[p];
            }
        }
    }
    return o;
};

Ext.override(Ext.data.Record, {
    set : function(name, value){
        if(Ext.encode(this.data[name]) == Ext.encode(value)){
            return;
        }
        this.dirty = true;
        if(!this.modified){
            this.modified = Ext.clone({}, this.data);
        }
        if(typeof this.modified[name] == 'undefined'){
            if( typeof this.data[name] == 'object' ) {
                this.modified[name] = Ext.clone({}, this.data[name]);
            } else {
                this.modified[name] = this.data[name];
            }
        }
        this.data[name] = value;
        if(!this.editing && this.store){
            this.store.afterEdit(this);
        }
    },
    
    beginEdit : function(){
        this.editing = true;
        this.modified = Ext.clone({}, this.data);
    },
    
    reject : function(silent){
        var m = this.modified;
        for(var n in m){
            if(typeof m[n] != "function"){
                this.data[n] = m[n];
            } else if ( typeof m[n] == "object") {
                this.data[n] = Ext.clone({}, m[n]);
            }
        }
        this.dirty = false;
        delete this.modified;
        this.editing = false;
        if(this.store && silent !== true){
            this.store.afterReject(this);
        }
    },
    
    getChanges : function(){
        var m = this.modified, cs = {};
        for(var n in m){
            if(m.hasOwnProperty(n) && (Ext.encode(m[n]) != Ext.encode(this.data[n]))){
                cs[n] = this.data[n];
            }
        }
        return cs;
    }
});
