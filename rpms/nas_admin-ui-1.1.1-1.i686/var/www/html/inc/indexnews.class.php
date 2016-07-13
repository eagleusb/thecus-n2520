<?php  
/**
 * IndexNews class
 * @author Heidi
 * 
 * @property string $log_path: data log path
 * 
 * @method showRecord($name,$showcount): show immediate record
 * @method getLogID($eventid):get logid information
 * @method PopupLog(): popup error log in first load page.
 * @method setCountZero($name): setting immediate count zero
 * @method getCount($name): get immediate count 
 */
class IndexNews extends sqlitedb{
	var $log_path;
	var $lang;
	var $error_path;
	
	public function __construct()
	{   
		$this->lang = $_SESSION['lang'];
		if (NAS_DB_KEY==1)
		{
		  $strExec="ls -l /raid/sys | awk '{print $11}' | awk -F'/' '{print $2}'";
		  $master_raid=trim(shell_exec($strExec));
		  $vg_name="vg".trim(substr($master_raid,4,1));
		  $strExec="mount | grep \"/dev/${vg_name}/syslv\" | grep rw | wc -l";
		  $this->log_path =(shell_exec($strExec)==0)?"/var/log":"/raid/sys";
		}elseif (NAS_DB_KEY==2){
		  $strExec="/bin/mount | /bin/grep md[0-9] | /bin/grep -c rw";                                                                                                                                                                               
		  $this->log_path=(shell_exec($strExec)==0)?"/var/log":"/raid/sys";                                                                                                                                                                                 
		  $strExec="/bin/mount | /bin/grep sdaaa4 | /bin/grep -c rw";                                                                                                                                                                                
		  $this->log_path=(shell_exec($strExec)==0)?$this->log_path:"/syslog";      
                  $this->log_path="/syslog";
		}
		parent::db_open($this->log_path."/online_register.db");  
		$this->error_path = $this->log_path."/error_dist";
	}

	public function __destruct()
	{ 
		unset($this->db);   
	} 
	 
	/**
	 * IndexNews::showRecord
	 * @param string name: log/news
	 * @param int showcount: showing how many news log/new 
	 * @return array
	 */
	public function showRecord($name,$showcount){  
		$list = array();
		switch($name){
			case "log": 
				$listall = (file_exists($this->error_path))?shell_exec("cat ".$this->error_path):0;
				if($listall){
					$ary = explode("\n",$listall);
					$count = count($ary)-1;  
					while($count-->=1){ 
						$data = explode(" : ",$ary[$count],2); 
						$data = explode("|",$data[1]); 
						array_push($list,$data[0]);
					} 
				}
			break;
			case "news":    
				if($this->table_exists("online_register")){
					$sql = "select online4 from online_register where online1=0"; 
					$ary=$this->runSQLAry($sql); 
					$count = count($ary);  
					$limit = ($showcount>$count)?1:$count-$showcount;  
					while($count-->=$limit){     
						if(!empty($ary[$count]['online4'])){
							array_push($list,$ary[$count]["online4"]);
						}
					} 
				}
			break; 
		} 
		$this->setCountZero($name);
		return $list;
		
	}  
	
	/**
	 * get logid information
	 * @param {number} eventid: event id
	 * @return logid , otherwise false.
	 */
	public function getLogID($eventid){  
		if($eventid){
			parent::db_open(LANG_DB);  
			$sql = "select logid from eventlog  where  eventid=".$eventid;    
			$row=$this->runSQLAry($sql);  
			return $row[0]["logid"];  
		}else{
			return false;
		}
	}  
	/**
	 * popup error log in first load page.
	 * @return array.
	 */
	public function PopupLog(){  
		parent::db_open(LANG_DB);  
		$logary = array();
		$listall = (file_exists($this->error_path))?shell_exec("cat ".$this->error_path):0;
		if($listall){
			$list = array();
			$ary = explode("\n",$listall);
			$count = count($ary)-1;  
			while($count-->=1){  
				$txt = $ary[$count];
				$f_pos = strpos($txt,":"); 
				if($f_pos !== 3){
					continue;
				} 
				$time_len = 19; 
				$eventid = substr($txt,0,$f_pos);  
				$postdate = substr($txt,$f_pos+2,$time_len);   
				$title = substr($txt,(strlen($eventid)+$time_len+2),strlen($txt));  
				$logid = $this->getLogID($eventid);  
				array_push($list,array('title'=> $title,'postdate'=>$postdate,'logid'=>$logid));  
			}
			$logary = array("topics"=>$list); 
		} 
		return $logary; 
	}  
	
	
	/**
	 * IndexNews::setCountZero
	 * @param string name: log/news 
	 */
	public function setCountZero($name){ 
		switch($name){
			case "log":  
				if(file_exists($this->error_path)){
					shell_exec("rm ".$this->error_path);  
				}
			break;
			case "news": 
				$sql = "update online_register set online1=1"; 
				$this->exec($sql);  
			break; 
		} 
	} 
	
	/**
	 * IndexNews::getCount
	 * @param string name: log/news 
	 * @return int
	 */
	public function getCount($name){
		$total = 0;
		switch($name){
			case "log": 
				if(file_exists($this->error_path)){
					$total = shell_exec("cat ".$this->error_path."|wc -l");
				}else{
					$total = 0;
				} 
			break;
			case "news":
				if($this->table_exists("online_register")){
					$sql = "select count(*) as count from online_register where online1=0"; 
					$ary=$this->runSQLAry($sql); 
					if($ary){
						$total =$ary[0]["count"];     
					}else{
						$total =0;
					} 
				} 
			break; 
		}
		return $total; 
	} 
} 

?>
