<!--
    function isURL(s){
	var s = typeof(s.value) != 'undefined' ? s.value : s;
        url_value = s.replace(/ /g,'');
        url_value = url_value.replace(/\r\n/g,"\t");
        url_value = url_value.replace(/\n/g,"\t");
        url_value = url_value.replace(/\r/g,"\t");
        var multi_url = url_value.split("\t");

	for(var i=0;i<multi_url.length;i++){
	    if(multi_url[i].substr(0,1) == '.' || multi_url[i].substr(multi_url[i].length-1,1) == '.')
	       return false;
	    for(var fqdn=0;fqdn<multi_url[i].length;fqdn++){
	        var tmp = multi_url[i].charCodeAt(fqdn);
	        if(!((tmp >= 47 && tmp <= 58)||(tmp == 45)||(tmp == 46)||(tmp == 95)||(tmp >= 65 && tmp <= 90)||(tmp >= 97 && tmp <= 122))){
		    return false;
	        }
	    }
	}
	return true;
    }
-->
