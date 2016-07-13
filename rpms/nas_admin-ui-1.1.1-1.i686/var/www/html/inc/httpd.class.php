<?php
class Httpd {
	//var $http_config_file = '/etc/httpd/inc/info/httpd.conf';
	//var $ssl_config_file = '/etc/httpd/inc/info/ssl.conf';
	var $http_config_file = '/etc/httpd/conf/httpd.conf';
	var $ssl_config_file = '/etc/httpd/conf/ssl.conf';

	function Httpd($http, $ssl) {
		$this->process($http ,$this->http_config_file);
		$this->process($ssl ,$this->ssl_config_file);
		$this->processVirtualHost($http ,$this->http_config_file);
		$this->processVirtualHost($ssl ,$this->ssl_config_file);
		//shell_exec('/usr/bin/apachectl restart > /dev/null 2>&1');
		//shell_exec('/usr/local/apache2/bin/apachectl stop');
		//shell_exec('/usr/local/apache2/bin/apachectl startssl');
	}

	function process($setup, $filename){
		$content = file($filename);
		$count = 0;
		foreach($content as $k=>$v) {
			if(ereg('(^#Listen|^Listen)', $v)){
				$result = explode(":",$content[$k]);
				$url = str_replace("#","",$result[0]);
				if ($count == 0){
					$content[$k]=$setup->nic0.$url.":".$setup->port."\n";
				}else{
					$content[$k]=$setup->nic1.$url.":".$setup->port."\n";
				}
				$count+=1;
			}
		}
		$this->writeToFile($filename, $content);
	}
	
	function processVirtualHost($setup, $filename){
		$content = file($filename);
		foreach($content as $k=>$v) {
			if(ereg('<VirtualHost', $v)){
			//if(ereg('(^\<VirtualHost)', $v)){
				$result = explode(":",$content[$k]);
				$url = $result[0];
				$content[$k]=$url.":".$setup->port.">\n";
				$count+=1;
				//print $content[$k];
			}
		}
		$this->writeToFile($filename, $content);
	}

	function writeToFile($filename, $content){
	   $handle = fopen($filename, 'w+');
	   foreach($content as $k=>$v) {
	   		fwrite($handle, $v);
	   }
	   fclose($handle);
	}

}

class HttpSetup{
	var $port=80;
	var $nic0='';
	var $nic1='';
	function HttpSetup($port, $nic0, $nic1){
		$this->port = $port;
		if ($nic0){
			$this->nic0 = '';
		}else{
			$this->nic0 = '#';
		}
		if ($nic1){
			$this->nic1 = '';
		}else{
			$this->nic1 = '#';
		}
	}
}

class SSLSetup{
	var $port=443;
	var $nic0='';
	var $nic1='';
	function SSLSetup($port, $nic0, $nic1){
		$this->port = $port;
		if ($nic0){
			$this->nic0 = '';
		}else{
			$this->nic0 = '#';
		}
		if ($nic1){
			$this->nic1 = '';
		}else{
			$this->nic1 = '#';
		}
	}
}

/* test main 
$http = new HttpSetup(8081,true,false);
$ssl = new SSLSetup(446,true,false);
$test = new Httpd($http, $ssl);
*/
?>
