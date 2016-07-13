
    /**************************************
       search for group list,if keyup,then search grouplist array.And store load.
       @param array obj , grouplist array
    ***************************************/
    function searchGrid(obj,dataobj){ 
          var regexp = new RegExp(obj.getValue(), 'i');
          var searchAry = new Array(); 
          var size = dataobj.length;
          for (var loop=0; loop < size; loop++) {
               if(regexp.test(dataobj[loop][1])){
                    var searchItem = new Array();
                    searchItem.push(dataobj[loop][0]);
                    searchItem.push(dataobj[loop][1]);
                    searchAry.push(searchItem); 
               }
          }  
          return eval(searchAry);
    }
      
    
    