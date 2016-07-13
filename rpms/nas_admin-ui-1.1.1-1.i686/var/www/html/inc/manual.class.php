<?php
/**
 * Manual class 
 * @author Heidi Sep,2010
 * 
 * @method ManualList($msg) : list all of manual.
 * @method ManualList_EventLog(): list of eventlog manual.
 * @method ManualContent($isTree,$id) :search for manual of special function.
 * 
 */
class Manual extends sqlitedb
{
    var $lang;    //current language
    
    public function __construct()
    { 
        $this->lang =  $_SESSION["lang"];
        parent::db_open(LANG_DB); 
    }

    public function __destruct()
    { 
        unset($this->db);
    }
    
    /**
     * Manual::ManualList 
     * list all of manual.
     * @return array ,otherwise false
     */
    public function ManualList($msg)
    {  
        $sql=     "SELECT t.fun as fun,t.treeid AS treeid,l.msg AS title,m.desc AS desc  FROM treemenu t ".
                "INNER JOIN ".$this->lang." l ON l.value=t.value ".
                "INNER JOIN  m_".$this->lang." m ON m.mid=t.treeid ".
                "WHERE l.function='index' AND t.cateid>0 AND status=1 AND m.cid=1";
        if($msg!=""){
            $sql.=" AND (m.desc like '%$msg%' OR m.content like '%$msg%')";
        }
        $row =$this->runSQLAry($sql);
        
        $list=array();
        $len = count($row);
        for ($i=0; $i<$len; $i++){
            $item = array("fun"=>$row[$i]['fun'],
                          0=>$row[$i]['fun'],
                        "title"=>$row[$i]['title'],
                        1=>$row[$i]['title'],
                        "treeid"=>$row[$i]['treeid'],
                        2=>$row[$i]['treeid'],
                        "desc"=>$row[$i]['desc'],
                        3=>$row[$i]['desc']);
            if(preg_match("/".$msg."/i", $row[$i]['title'])){
                array_unshift($list,$item);
            }else{
                array_push($list,$item);
            }
        }
        if($row){ 
            return $list;
        }else{
            return false;
        } 
    }

    /**
     * Manual::ManualList_EventLog 
     * list of eventlog manual
     * @return array ,otherwise false
     */
    public function ManualList_EventLog()
    {  
        $sql=     "SELECT m.desc as desc, mt.id as logid FROM m_".$this->lang." m WHERE m.cid=2";
        $row =$this->runSQLAry($sql);
        if($row){ 
            return $row;
        }else{
            return false;
        } 
    }
    
    /**
     * Manual::ManualContent 
     * search for manual of special function.
     * @param cid : manual categorize ID (values==> 1: TreeMenu, 2: Event Log, 3: Other Help)
     * @param id : maybe was treeid, logid or otherid.
     * @return array ,otherwise false
     */
    public function ManualContent($cid,$id)
    {   
        if($cid!="" && $id!=""){
            $man_ary = array();
            $sql = "SELECT content, desc FROM m_".$this->lang." m WHERE m.cid=$cid AND m.mid=$id";
            $row =$this->runSQLAry($sql);
            if($row){
                $man_ary["content"] = $row[0]["content"]; 
                $man_ary["title"] = $row[0]["desc"]; 
            } 
            
            if($cid=="1"){
                $sql=   "SELECT l.msg AS msg FROM ".$this->lang." l ".
                        "INNER JOIN treemenu t ON t.value=l.value ".
                        "WHERE t.treeid=$id";
                $row =$this->runSQLAry($sql);
                if($row){ 
                    $man_ary["title"] = $row[0]["msg"]; 
                }  
            }
            return $man_ary;
            
        } 
        return false;
    }
     
     
} 
?>
