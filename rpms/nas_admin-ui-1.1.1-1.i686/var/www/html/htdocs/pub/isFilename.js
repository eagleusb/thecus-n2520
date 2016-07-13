<!--
    function isFilename(s){
		var s = typeof(s.value)=='undefined' ? s : s.value;
		var sharename_length = 0;
		if(s.replace(/ /g,"")=="")
			return false;
		for(var filename=0;filename<s.length;filename++){
			var tmp_index = s.charCodeAt(filename);
			//alert("[" + tmp_index + "]  " + s.charCodeAt(filename));
	        if(tmp_index < 128)
	            sharename_length ++;
			else if(tmp_index >= 128 && tmp_index <= 256)
				sharename_length += 2;
			else
				sharename_length += 3;
		    if(tmp_index == 34 || tmp_index == 42 || tmp_index == 47 || tmp_index == 58 || tmp_index == 60 || 
			   tmp_index == 62 || tmp_index == 63 || tmp_index == 92 || tmp_index == 124){
				return false;
		    }
		}
		if(sharename_length > 255){
	        return false;
	    }
		return true;
    }
-->
