<?php
//"provide raid information"
include_once("INFO.base.php");
class LVMINFO extends INFO{
    var $lv_list = array();
    
		var $mddisk="/dev/md1";
		var $mdname="md1";
		var $swapname="md0";
		var $swapdisk="/dev/md0";

	function parse(){
		$this->getTotalCapacity();
		$this->getUsedCapacity();
		$this->getEmptyCapacity();
		

	}

	function getEmptyCapacity(){
		$this->content["EmptyCapacity(MB)"] = $this->content["TotalCapacity(MB)"] - $this->content["UsedCapacity(MB)"];
	}


	function getUsedCapacity(){
		$cmd="lvscan | awk 'BEGIN{FS=\"\\\\[|\\\\]\"}{print $2}'";
		$content = shell_exec($cmd);
		$f = explode("\n",$content);
		//$f = file("tmp");
		
		$cmd="lvscan | awk 'BEGIN{FS=\"/|\\\\[\" }{print $4}'";
		$content = shell_exec($cmd);
		$f2 = explode("\n",$content);
		//$f2 = file("tmp2");
		
		
		$total = 0.0;
		foreach ($f as $k=>$v){
			$v = explode(" ",$v);
			$capacity= $v[0];
			$unit= $v[1];
			$capacity =  $this->unitConversion($capacity, $unit);
			
			$lv_name = substr(trim($f2[$k]), 0, strlen(trim($f2[$k]))-1);
			$this->lv_list[$lv_name] = intval($capacity);
			//print($lv_name)."\n";
			
			$total += $capacity;
		}
		//print $total."\n"; 
		$this->content["UsedCapacity(MB)"] = $total;
		$this->content["LVList"] = $this->lv_list;
	}

	function getTotalCapacity(){
		$cmd="vgdisplay rootvg 2>&1 | grep -i 'vg size' | awk '{print $3,$4}'";
		$content = shell_exec($cmd);
		$s = explode(" ",$content);
		$total_capacity = trim($s[0]);
		$unit = trim($s[1]);
		$total_capacity =  $this->unitConversion($total_capacity, $unit);
		$this->content["TotalCapacity(MB)"] = $total_capacity;
	}

	function _old_getTotalCapacity(){
		$cmd="pvscan " . $this->mddisk . " |awk  '{print $3,$4}'";
		$content = shell_exec($cmd);
		$f = explode("\n",$content);
		//$f = file("tmp");
		$s = $f[1];
		$s = explode(" ",$s);
		$total_capacity = floatval(substr(trim($s[0]),1,strlen(trim($s[0]))));
		$unit = substr(trim($s[1]),0,strlen(trim($s[1]))-1);
		//print $total_capacity."\n";
		//print $unit."\n";
		$total_capacity =  $this->unitConversion($total_capacity, $unit);
		$this->content["TotalCapacity(MB)"] = $total_capacity;
	}

	function unitConversion($total_capacity, $unit){
		$unit= $this->filter($unit);
		if ($unit == "GB"){
			$total_capacity = $total_capacity * 1024;
		}else if ($unit == "TB"){
			$total_capacity = $total_capacity * 1024 * 1024;
		}else if ($unit == "MB"){
			$total_capacity = $total_capacity;
		}
		return $total_capacity;
	}

}
/* test main 
$x = new LVMINFO();
print_r($x->getINFO());
*/
?>
