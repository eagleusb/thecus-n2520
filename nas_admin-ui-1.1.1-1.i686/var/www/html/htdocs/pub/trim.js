<!--
function ltrim(arg){
	var arg = typeof(arg.value)=='undefined' ? arg : arg.value;
	var tmp="";
	var flag=false;
	for(var i=0;i<arg.length;i++){
	TmpValue=arg.substr(i,1);
	TmpCode=TmpValue.charCodeAt(0);
	if(TmpCode!=32){flag=true;}
	if(flag){tmp+=TmpValue;}
	}
return tmp;
}
function rtrim(arg){
	var arg = typeof(arg.value)=='undefined' ? arg : arg.value;
	var tmp="";
	var flag=false;
	var stopper=arg.length;
	var len;
	for(var i=0;i<stopper;i++){
	TmpValue=arg.substr(stopper-1-i,1);
	TmpCode=TmpValue.charCodeAt(0);
		if(TmpCode!=32){flag=true;}
		if(flag){len=stopper-i;i=stopper;}
	}
	tmp=arg.substr(0,len);
return tmp;
}
function trim(arg){
	var arg = typeof(arg.value)=='undefined' ? arg : arg.value;
	tmp=ltrim(arg);
	tmp=rtrim(tmp);
return tmp;
}
//-->