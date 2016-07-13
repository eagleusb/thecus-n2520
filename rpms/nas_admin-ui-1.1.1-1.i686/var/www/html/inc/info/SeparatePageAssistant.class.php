<?
define("DATE_LEN", 10);
//"provide File Format Separate Page Assistant"
class SeparatePageAssistant{
	var $file_name;
	var $page_size;
	var $file_max_size = 1024;
	var $file_max_percent = 0.8;
	var $sorting_order = false;

	function SeparatePageAssistant($file_name, $page_size, $sorting_order){
		$this->file_name = $file_name;
		$this->page_size = $page_size;
                // remove -- MARK --
		if (is_array($this->file_name)){
			foreach($this->file_name as $v){
				if(file_exists($v))
				$count+=filesize($v);
			}
		}
		
		if ($sorting_order!=''){
			$this->sorting_order = $sorting_order;
		}
	}
	
	function getFileSize(){
		if (is_array($this->file_name)){
			$count = 0;
			foreach($this->file_name as $v){
				if(file_exists($v))$count+=filesize($v);
			}
			return $count;
		}else{
			if(file_exists($v))
			return filesize($this->file_name);
			else
			return 0;
		}
	}
	
	function getFileLines(){
		if (is_array($this->file_name)){
			$count = 0;
			foreach($this->file_name as $v){
				if(file_exists($v)){
				  $file = file($v);
				  $count += count($file);
				}
			}
			return $count;
		}else{
			if(file_exists($this->file_name)){
			  $file = file($this->file_name);
			  return count($file);
			}
			else return 0;
		}
	}

	function getTotalPageCount(){
		return ceil(floatval($this->getFileLines())/$this->page_size);
	}

	function parseLogFileToAry($filename) {
		$lines = file($filename);
		$new_lines = array();
		foreach ($lines as $v) {
			$line_sep = explode(" ", $v, 2);
			if (count($line_sep) == 0) {
				continue;
			}
			if (strlen($line_sep[0]) == DATE_LEN) {
				array_push($new_lines, $v);
			} else {
				array_push($new_lines, $line_sep[1]);
			}
		}
		return $new_lines;
	}

	function getPage($page_no){
		if (is_array($this->file_name)){
			$file = array();
			foreach($this->file_name as $v){
				if(file_exists($v)){
					if (($v == "/var/log/error") || ($v == "/raid/sys/error") || ($v == "/syslog/error")) {
						$f = $this->parseLogFileToAry($v);
					} else {
						$f = file($v);
					}
					$file = array_merge($file, $f);
				}
			}
			
			$file = $this->sortByDate($file);
			$result = array();
			$total_page_count = $this->getTotalPageCount();
			if ($page_no <= 0){
				return array();
			}else{
				$start = ($page_no - 1 ) * $this->page_size ;
				$result = array_slice($file,$start,$this->page_size);
				return $result;
			}
		}else{
			if(file_exists($this->file_name)){
			  $file = file($this->file_name);
			  $file = $this->sortByDate($file);
			  $result = array();
			  $total_page_count = $this->getTotalPageCount();
			
			  if ($page_no <= 0){
			  	  return array();
			  }else{
				  $start = ($page_no - 1 ) * $this->page_size ;
				  $result = array_slice($file,$start,$this->page_size);
				  return $result;
			  }
            }
			else return array();
		}
	}
	
	function sortByDate($file){
		//print "sort by date :".$this->sorting_order.":";
		// sorting by date+time+file_line
		$sort_array = array();
		foreach($file as $k=>$v){
			$key = strtotime(substr($v,0,6));
			$key = $key.substr($v,8,7).$k;
			//echo $key."<br>";
			//echo $key."\n";
			//echo substr($v,7,8)."\n";
			$sort_array[$key] = $v;
		}
		$file = $sort_array;
		if ($this->sorting_order){
			//print $this->sorting_order;
			sort($file);
			$file = array_reverse($file);
		}else{
			//print $this->sorting_order;
			sort($file);
		}
		return $file;
	}


	function truncateHalfByLine(){
		if (is_array($this->file_name)){
			echo 'This method is not support that filename is array type !!!';
		}else{
			if($this->getFileSize() >= ($this->file_max_size * $this->file_max_percent)){
				//echo $this->getFileSize()."\n";
				if(file_exists($this->file_name)){
				  $content = file($this->file_name); 
				  $result = array_slice($content,($this->getFileLines()/2),$this->getFileLines());
				  $handle = fopen($this->file_name,'w'); 
				  foreach($result as $v){
					  fwrite($handle, $v);
				  }
				  fclose($handle);
                }
			}
		}
	}


	function truncateHalf(){
		if (is_array($this->file_name)){
			echo 'This method is not support that filename is array type !!!';
		}else{
			if($this->getFileSize() >= $this->file_max_size){
				$handle = fopen($this->file_name,'r+'); 
				$content = file($this->file_name); 
				$result = array_reverse($content);
				foreach($result as $v){
					fwrite($handle, $v);
				}
				ftruncate($handle,($this->file_max_size/2)); 
				fclose($handle);

				$handle = fopen($this->file_name,'r+'); 
				$content = file($this->file_name); 
				$result = array_reverse($content);
				foreach($result as $v){
					fwrite($handle, $v);
				}
				fclose($handle);
			}
		}
	}


}

/* test main 
$x = new SeparatePageAssistant("SeparatePageAssistant.class.php", 10);
print "getFileSize:".$x->getFileSize()." bytes \n";
print "getFileLines:".$x->getFileLines()."\n";
print "getTotalPageCount:".$x->getTotalPageCount()."\n";
print_r($x->getPage(6));
*/
//$list = array('/var/log/error','/var/log/warning','/var/log/information');
//$spa = new SeparatePageAssistant("/var/log/error", 10, true);

?>
