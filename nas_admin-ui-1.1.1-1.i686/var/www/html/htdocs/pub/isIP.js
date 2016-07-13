<!--
    function isIP(ipsubnet){
	ip_value = ipsubnet.value;
	ip_value1 = ip_value.replace(/ /g,'');
	if(ip_value1 != ip_value)
		return false;
	ip_value = ip_value.replace(/\r\n/g,"\t");
	ip_value = ip_value.replace(/\n/g,"\t");
	ip_value = ip_value.replace(/\r/g,"\t");
	var multi_ip = ip_value.split("\t");

	for(var i=0;i<multi_ip.length;i++){
	    if(multi_ip[i] == '')
		continue;
	    var ip_subnet = multi_ip[i].split('/');
            var bytes = ip_subnet[0].split('.')

            if(bytes.length != 4 || ip_subnet.length > 2)
       	        return false
 
	    for(var j=0;j<ip_subnet[0].length;j++){
                tmp = ip_subnet[0].charCodeAt(j);
            	if(tmp <= 47 || tmp >= 58){
                    if(tmp != 46){
                       return false 
                    }
            	}
            }
	    if(ip_subnet.length == 2){
                for(var j=0;j<ip_subnet[1].length;j++){
               	    tmp = ip_subnet[1].charCodeAt(j);
               	    if(tmp <= 47 || tmp >= 58){
                        return false 
                    }
            	}
	    	if(ip_subnet[1] > 32 || ip_subnet[1] < 1)
	            return false
	    }

            for(var j=0;j<4;j++){
                tmp = parseInt(bytes[j])
				tmp2 = bytes[j].length;
            	if((tmp > 255 || tmp < 0) || (tmp2 >= 4 || tmp2 <= 0))
                    return false 
	    }
	}
        return true 
    }

-->
