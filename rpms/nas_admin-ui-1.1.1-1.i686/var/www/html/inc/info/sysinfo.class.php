<?php
//'provide sys information'
include_once("INFO.base.php");
class SYSINFO extends INFO{
	function parse(){
		$this->uptime();
	}

	function uptime() {
		//global $text;
		$fd = fopen('/proc/uptime', 'r');
		$ar_buf = explode(' ', fgets($fd, 4096));
		fclose($fd);

		$sys_ticks = trim($ar_buf[0]);

		$min = $sys_ticks / 60;
		$hours = $min / 60;
		$days = floor($hours / 24);
		$hours = floor($hours - ($days * 24));
		$min = floor($min - ($days * 60 * 24) - ($hours * 60));
		$this->content["Days"]=$days;
		$this->content["Hours"]=$hours;
		$this->content["Min"]=$min;
		/*
		if ($days != 0) {
		  $result = "$days " . $text['days'] . " ";
		} 

		if ($hours != 0) {
		  $result .= "$hours " . $text['hours'] . " ";
		} 
		$result .= "$min " . $text['minutes'];
		$this->content["UpTime"]=$result;
		*/
  } 

}
/* test main 
$x = new CPUINFO();
print_r($x->getINFO());
*/
?>
