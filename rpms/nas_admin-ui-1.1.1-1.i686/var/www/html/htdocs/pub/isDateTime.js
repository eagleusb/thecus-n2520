<!--
    function isDateTime(s){
	var s = s.split(' ');
	var dates = s[0].split('/');
	var times = s[1].split(':');
	if(dates.length != 3 || s.length != 2 || times.length != 3)
	    return false;
	for(var i=0;i<3;i++){
	    if(!checknum(dates[i]) || !checknum(times[i]))
		return false;
	}
	var year = parseInt(dates[0]);var mon = parseInt(dates[1]);var day = parseInt(dates[2]);
	var hour = parseInt(times[0]);var min = parseInt(times[1]);var sec = parseInt(times[2]);

	if(year < 1900 || year > 2040)
	    return false;
	if(mon < 1 || mon > 12)
	    return false;
	if(day < 1 || day > 31)
	    return false;

	if(hour < 0 || hour > 23)
	    return false;
	if(min < 0 || min > 59)
	    return false;
	if(sec < 0 || sec > 59)
	    return false;

	if(mon == 4 || mon == 6 || mon == 9 || mon == 11){
	    if(day >30)
		return false;
	}

	if(mon == 2){
	    if(year % 4 == 0){
		if(day > 29)
		    return false;
	    }
	    else{
		if(day > 28)
		    return false;
	    }
	}

	return true;
    }

    function checknum(s){
        for(var j=0;j<s.length;j++){
            var tmp = s.charCodeAt(j);
            if(tmp <= 47 || tmp >= 58)
                return false;
        }
        return true;
    }
-->
