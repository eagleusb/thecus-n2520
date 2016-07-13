<?php
/**
 * Treemenu class
 * @author Heidi
 * 
 * @property string lang: language
 * 
 * @method Search(searchmsg): search treemenu record
 * @method SearchByFun(fun): search treemenu by function name
 * @method getTreeMenuList(): list all of treemenu record
 * @method detectTreeMenu(): Detect to update treemenu, check "/var/tmp/www/change_tree" value.
 */

class Treemenu extends sqlitedb
{
    var $lang;
    
    public function __construct()
    { 
        $this->lang = $_SESSION["lang"];
        parent::db_open(LANG_DB);
    }

    public function __destruct()
    { 
        unset($this->db);  
          
    } 

    /**
     * Treemenu::Search
     * @param string searchmsg 
     * @return array 
     */
    public function Search($searchmsg)
    { 
        $list = array();
        if($searchmsg!=""){
            // TODO: Rollback following code when language.db has full online help.
            $sql = "select distinct t.fun as fun, t.treeid as treeid, t.cateid as cateid,g.msg as gmsg ,m.desc as desc ,g2.msg as g2msg from m_".$this->lang." m ".
                    "inner join treemenu t on m.mid=t.treeid  ".
                    "inner join ".$this->lang." g on g.value=t.value ".
                    "inner join treemenu t2 on t.cateid=t2.treeid ".
                    "inner join ".$this->lang." g2 on g2.value=t2.value ".
                    "where g.function='index' and t.status=1 and m.cid=1 and ( m.desc like '%$searchmsg%' or g.msg like '%$searchmsg%' or m.content like '%$searchmsg%') ".
                    " order by g.msg";
            $result =$this->runSQLAry($sql);
            $len = count($result);
            $i=0;   
            while($i<$len && $len>=1 ){  
                $desc = ($_SESSION['lang']!='ja')?$result[$i]['desc']:"";
                $item = array("fun"=>$result[$i]['fun'],
                        "title"=>$result[$i]['gmsg'],
                        "treeid"=>$result[$i]['treeid'],
                        "cateid"=>$result[$i]['cateid'],
                        "catename"=>$result[$i]['g2msg'],
                        "desc"=>$desc);
                if(preg_match("/".$searchmsg."/i", $result[$i]['gmsg'])){
                    array_unshift($list,$item);
                }else{
                    array_push($list,$item);
                }
                $i++;
            }
        }
        return $list;
    }


    /**
     * Treemenu::SearchByFun
     * @param string fun: function name
     * @return array , otherwise false
     */
    public function SearchByFun($fun)
    {  
        if($fun!=""){
            $sql = "select t.fun as fun,t.treeid as treeid,t.cateid as cateid,l.msg as treename,l2.msg as catename,t.status as status from treemenu t ".
                    "inner join treemenu t2 on t.cateid=t2.treeid ".
                    "inner join ".$this->lang." l on t.value=l.value ".
                    "inner join ".$this->lang." l2 on l2.value=t2.value ".
                    "where t.status=1 and t.fun = '".$fun."' and l.function='index' and l2.function='index' ";
             $row =$this->runSQLAry($sql);
            $len = count($row);
            if($len>0){
                return $row; 
            } 
        } 
        return false;
    }
    
    /**
     * Treemenu::getTreeMenuList 
     * @return array ,otherwise false
     */
    public function getTreeMenuList()
    { 
        $sql_format= " SELECT ".$this->lang.".msg as %s  FROM treemenu t" .
                     " INNER JOIN  ".$this->lang.
                     " ON t.value=".$this->lang.".value".
                     " WHERE ".$this->lang.".function='index' AND t.status=1 AND t.cateid=%d  ORDER BY  treeid"; 
        
        $sql = sprintf($sql_format, " catename, t.value AS value, t.treeid AS treeid,t.cateid AS cateid","0");
        $result =$this->runSQLAry($sql);
        $len = count($result);         
        $i=0;
        while($i<$len){  
            $sql2 = sprintf($sql_format, " treename, t.fun AS fun,t.fun as img,t.treeid AS treeid,t.cateid AS cateid  ",$result[$i]["treeid"]);
            $result2 =$this->runSQLAry($sql2);
            $result[$i]["count"]=count($result2);
            if($result[$i]["count"]){
                $j=0;
                foreach($result2 as $key=>$value){
                    if(preg_match("/num=(?<num>\w+)/i", $value["fun"], $matches)){
                        $result2[$j]["treename"].=" ".$matches["num"];
                        $result2[$j]["img"]="tengb";
                    }
                    $j++;
                }
                $result[$i]["detail"]=$result2;
            }  
            $i++;
        }
        
        if(!$result){
            return false;
        }else{  
            return $result;
        }
    } 
      
    
    /**
     * Detect to update treemenu, check "/var/tmp/www/change_tree" value.
     * change_tree value=1 ==> update tree and return tree list.
     * change_tree value=0 ==> not updated return false.
     * 
     * @return tree success ,otherwise false.
     * 
     */
    public function detectTreeMenu(){   
        $flag = trim(shell_exec("cat ".CHANGE_TREE." 2>/dev/null"));
        if($flag=="1"){ 
            shell_exec("echo '0' > ".CHANGE_TREE);
            return true;
        }else{
            return false;
        } 
    }
     
} 
 
?>
