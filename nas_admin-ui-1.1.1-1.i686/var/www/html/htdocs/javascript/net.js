var net = new Object();
net.READY_STATE_UNINITIALIZED = 0;
net.READY_STATE_LOADING = 1;
net.READY_STATE_LOADED = 2;
net.READY_STATE_INTERACTIVE = 3;
net.READY_STATE_COMPLETE = 4; 

/*--- content loader object for cross-browser requests ---*/
net.ContentLoader=function(mask,url,onload,onerror,method,params,contentType){
  this.browser=navigator.appName;
  this.req=null;
  this.mask=mask;
  this.url=url;
  this.params=params; 
  this.onload=(onload) ? onload :this.defaultLoad;
  this.onerror=(onerror) ? onerror : this.defaultError;
  this.loadXMLDoc(url,method,params,contentType);
}

net.ContentLoader.prototype={
 loadXMLDoc:function(url,method,params,contentType){
  if (!method){
    method="GET";
  }
  if (!contentType && method=="POST"){
    contentType='application/x-www-form-urlencoded';
  }
  if (window.XMLHttpRequest){
    this.req=new XMLHttpRequest();  
  } else if (window.ActiveXObject){
    this.req=new ActiveXObject("Microsoft.XMLHTTP");
  } 
  if (this.req){
    if(this.mask)mainMask.show();
    try{
      var loader=this;
      this.req.onreadystatechange=function(){
        loader.onReadyState.call(loader);
      }
      this.req.open(method,url,true);
      if (contentType){
        this.req.setRequestHeader('Content-Type', contentType);
      }
      this.req.send(params);
    }catch (err){
      this.onerror.call(this);
    }
  }
 },

 onReadyState:function(){
  var req=this.req;
  var ready=req.readyState;
  if (ready==net.READY_STATE_COMPLETE){
	if( Ext.get('t-net-status') ) {
	  Ext.get('t-net-status').removeClass('t-net-status-active');
	  Ext.get('t-net-status').addClass('t-net-status-inactive');
	}
    var httpStatus=req.status;
    if (httpStatus==200 || httpStatus==0){
      this.onload.call(this);
      //in FireFox disconnect
	  if(httpStatus==0 && req.responseText==''){
		
	  }else{
		if(rebootflag=='1'){
			location.href='index.php';
			rebootflag=0;
		}
	  }
    }else{
      if(rebootflag=='1'){
      	onReboot();
      }
      this.onerror.call(this);
    }
	
    if(this.mask){
  	   mainMask.hide();
	   if (fwMask) {
	   	  fwMask.show();
	   }
    }
  }
 }, 
 defaultError:function(){
      if( Ext.get('t-net-status') ) {
		Ext.get('t-net-status').addClass('t-net-status-active');
	  }
      //if IE disconnect,setTimeout will not runing ,so if browser is IE,then add setTimeout to trace network.
      if(this.browser=='Microsoft Internet Explorer'){
          monitor = setTimeout("processAjax('getmain.php?fun=nasstatus',onloadSysConfig)",monitor_sec*1000); 
          if(rebootflag=='1'){
              onReboot();
          }
      } 
 },
 defaultLoad:function(){
	return false; 
 }
 
}


