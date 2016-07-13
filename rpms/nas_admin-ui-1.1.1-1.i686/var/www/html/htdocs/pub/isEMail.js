<!--
    function isEMail(s){
	var s = s.value.replace(/ /,'');
	var tmp1 = s.split('@');

	if(tmp1.length != 2)
	    return false;

	for(var account=0;account<2;account++){
	    if(!isURL(tmp1[account]))
		return false;
	}

	return true;
    }
-->
