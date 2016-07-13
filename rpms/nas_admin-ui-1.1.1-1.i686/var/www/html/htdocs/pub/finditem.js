<!--
/*
    傳回在select Object中，value與t相同的option index，s為select object

    若無相對映的值，則傳回0
*/

    function finditem(s,t){
	for(var i=0;i<s.options.length;i++){
	    if(s.options[i].value == t)
		return i;
	}
	return 0;
    }

-->
