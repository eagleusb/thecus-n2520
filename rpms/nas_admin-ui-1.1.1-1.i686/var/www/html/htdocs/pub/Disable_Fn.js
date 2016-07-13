<!--
/*hidden or visible UI,those object must name is "s"*/
function Disable_Fn(e,s){
	var fn = document.getElementsByName(s);
	if(e){
		for(var i=0;i < fn.length;i++){
			for (var j=0;j <fn[i].childNodes.length;j++){
				if (fn[i].childNodes[j].nodeName == "TD"){
					for (var k=0;k <fn[i].childNodes[j].childNodes.length;k++){
						if ((fn[i].childNodes[j].childNodes[k].nodeName == "INPUT")||
						    (fn[i].childNodes[j].childNodes[k].nodeName == "SELECT")||
						    (fn[i].childNodes[j].childNodes[k].nodeName == "TEXTAREA"))
							fn[i].childNodes[j].childNodes[k].disabled = false;
					}
				}
			}
		}
	}
	else{
		for(var i=0;i < fn.length;i++){
			for (var j=0;j <fn[i].childNodes.length;j++){
				if (fn[i].childNodes[j].nodeName == "TD"){
					for (var k=0;k <fn[i].childNodes[j].childNodes.length;k++){
						if ((fn[i].childNodes[j].childNodes[k].nodeName == "INPUT")||
						    (fn[i].childNodes[j].childNodes[k].nodeName == "SELECT")||
						    (fn[i].childNodes[j].childNodes[k].nodeName == "TEXTAREA"))
							fn[i].childNodes[j].childNodes[k].disabled = true;
					}
				}
			}
		}
	}
}

-->
