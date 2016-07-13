<!--
	function isAccount(s){
		var s = typeof(s.value)=='undefined' ? s : s.value;
		for(var account=0;account<s.length;account++){
			var tmp_index = s.charCodeAt(account);
			if(tmp_index == 47 || tmp_index == 32){
				return false;
			}
			if(tmp_index >= 58 && tmp_index <= 64){
				return false;
			}
			if(tmp_index >= 91 && tmp_index <= 93){
				return false;
			}
			if(tmp_index >= 42 && tmp_index <= 44){
				return false;
			}
		}
		return true;
	}
-->
