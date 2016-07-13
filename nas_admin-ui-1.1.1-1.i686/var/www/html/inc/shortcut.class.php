<?php 
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
/**
* ShortCut Class  My favorite 
*/	 
class ShortCut extends sqlitedb{
	var $message;		//error message
	var $result; 		//true:success , false:fail 
	var $lang;  
	
	/**
	* ShortCut constructor
	* @var message : error message
	* @var result: success true ,otherwise false
	* @var limit: get from webconfig
	*/	
	function ShortCut(){
		require_once(WEBCONFIG);
		$this->message='';
		$this->result=true; 
		$this->limit = 9999;//$webconfig['shortcut_limit'];
		$this->lang = $_SESSION['lang'];
		parent::db_open(LANG_DB);
		parent::table_selected('shortcut');
	} 
 
	/**
	* add shortcut
	* @param string $treeid
	*/	
	public function add($treeid){
		if(!$this->find($treeid)){
			parent::db_open(LANG_DB);
			parent::table_selected('shortcut');
			$row = $this->db_get_folder_info($this->table,'max(sortid) as max_sortid','');
			$sortid =1;
			if($row[0]['max_sortid']!=''){
				$sortid = (int)$row[0]['max_sortid']+1; 
			} 
			// Query shortcut name by treeid
			$shortcutname = $this->id2shortcut($treeid);
			//add language.db> shortcut table
			$this->result= $this->db_insert('shortcut','shortcutname,sortid',"'$shortcutname',$sortid");
 			$this->offset();
 			
			//add /etc/cfg/shortcut.db> shortcut table
			parent::db_open(SYSTEM_DB_ROOT."shortcut.db");
			parent::table_selected('shortcut');
			$this->result= $this->db_insert('shortcut','shortcutname,sortid',"'$shortcutname',$sortid");
 			$this->offset();
			
		}else{ 
	    		$this->message="duplicate shortcut";
	    		$this->result=false;
		}
	}

	/**
	* remove shortcut
	*/
	public function remove($treeid){
		//remove language.db> shortcut table
		parent::db_open(LANG_DB);
		parent::table_selected('shortcut');
		// Query shortcut name by treeid
		$shortcutname = $this->id2shortcut($treeid);

		$this->result= $this->db_delete($this->table,"where shortcutname='$shortcutname'");
		
		//remove /etc/cfg/shortcut.db> shortcut table
		parent::db_open(SYSTEM_DB_ROOT."shortcut.db");
		parent::table_selected('shortcut');
		$this->result= $this->db_delete($this->table,"where shortcutname='$shortcutname'");
	}  

	/**
	* sorting shortcut
	* @param string $source_treeid: source treeid
	* @param string $target_treeid: target treeid
	*/
	public function sort($source_treeid,$target_treeid){
		$source_sortid=$this->find($source_treeid);
		$target_sortid=$this->find($target_treeid);
		// Query shortcut name by treeid
                $source_shortcutname = $this->id2shortcut($source_treeid);
                $target_shortcutname = $this->id2shortcut($target_treeid);

		if($source_sortid!='' && $target_sortid!=''){
			//sort language.db> shortcut table
			parent::db_open(LANG_DB);
			parent::table_selected('shortcut');
			$this->db_update($this->table,"sortid=$target_sortid","where shortcutname='$source_shortcutname'");
			$this->db_update($this->table,"sortid=$source_sortid","where shortcutname='$target_shortcutname'");
			
			//sort /etc/cfg/shortcut.db> shortcut table
			parent::db_open(SYSTEM_DB_ROOT."shortcut.db");
			parent::table_selected('shortcut');
			$this->db_update($this->table,"sortid=$target_sortid","where shortcutname='$source_shortcutname'");
			$this->db_update($this->table,"sortid=$source_sortid","where shortcutname='$target_shortcutname'");
		}  
	}

	/**
	* get shortcut 
	* @return shortcut array.
	*/
	public function getlist(){  
		$sql ="SELECT l.msg AS treename,t.treeid AS treeid,t.fun AS fun,t.fun AS img,t.cateid AS cateid,t.status AS status FROM shortcut s ".
				"INNER JOIN treemenu t ON s.shortcutname=t.value ".
				"INNER JOIN ".$this->lang." l ON t.value=l.value ".
				"ORDER BY s.sortid DESC LIMIT 0,".$this->limit;
		$result =$this->runSQLAry($sql); 
		$i=0; 
		foreach($result as $key=>$row)
		{ 
			if($row["status"]=="0"){
				$this->remove($row["treeid"]);
				unset($result[$i]);
				continue;
			}
			if(preg_match("/num=(?<num>\w+)/i", $row["fun"], $matches)){ 
				$result[$i]["treename"].=" ".$matches["num"];
				$result[$i]["img"]="tengb";
			}
			$sql2 = "SELECT l.msg AS catename FROM ".$this->lang." l ".
					"INNER JOIN treemenu t ON l.value=t.value ".
					"WHERE t.treeid=".$row["cateid"];
			$result2 =$this->runSQLAry($sql2);  
			if(is_array($result2) && count($result2)>0){ 
				$result[$i]["catename"] =$result2[0]["catename"];
			} 
			$i++;
		}    
		return $result;  
		  
	} 
	
	/**
	* find shortcut
	* @param string $treeid 
	* @return sortid if find, otherwise false.
	*/
	public function find($treeid){ 
		// Query shortcut name by treeid
		$shortcutname = $this->id2shortcut($treeid);
		$row = $this->db_get_folder_info($this->table,'sortid',"where shortcutname='$shortcutname'");
		if($row[0]['sortid']!=''){
			return $row[0]['sortid'];
		} 
	} 

	/**
	* offset shortcut range 1~12
	* shortcut limit was adjustment by webconfig.
	*/
	private function offset(){
	    $row = $this->db_get_folder_info($this->table,'sortid',"order by sortid desc limit 1 offset ".$this->limit);
	    if($row[0]['sortid']!=''){
			$this->db_delete($this->table,"where sortid<=".$row[0]['sortid']); 
	    }
	} 

	/**
	* Query which shortcut name mapping
	* by treeid
	*/
	private function id2shortcut($treeid){
		$sql ="SELECT value FROM treemenu WHERE treeid=$treeid";
                $shortcutname =$this->runSQLAry($sql);
		return $shortcutname[0]["value"];
	}
 
}

?>




