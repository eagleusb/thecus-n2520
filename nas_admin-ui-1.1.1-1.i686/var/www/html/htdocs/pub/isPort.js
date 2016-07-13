<!--
    function isPort(s){
	//alert("s1=" + s);
	var s = s.value.replace(/ /,'');
	//alert("s2=" + s);
	for(j=0;j<s.length;j++){
	    var tmp = s.charCodeAt(j);
	    if((tmp <= 47 || tmp >= 58))
		return false;
	}

	var tmp = parseInt(s);
	if(tmp < 1 || tmp > 65535)
	    return false;
	return true;
    }

-->
