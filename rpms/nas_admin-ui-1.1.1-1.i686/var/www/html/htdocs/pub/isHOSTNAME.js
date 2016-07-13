<!--
	function isHOSTNAME(s){
		var s = typeof(s.value) != 'undefined' ? s.value : s;
		hostname = trim(s);

		if(hostname == ''){
			return false;
		}

		for(var i=0;i<hostname.length;i++){			
			var tmp = hostname.charCodeAt(i);
			if(!((tmp == 45)||(tmp >= 48 && tmp <= 57)||(tmp >= 65 && tmp <= 90)||(tmp >= 97 && tmp <= 122))){
				return false;
			}
		}
		return true;
	}
-->
