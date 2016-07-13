<?php
    include_once('../../inc/conf.class.php');
    Class GetConfig{
		var $prefix;
		function GetConfig($prefix){
			$this->prefix=$prefix;
		}
		function getContent(){
			$conf=new Configure();
			$entries=$conf->get($this->prefix);
			$config= array();
			foreach($entries as $v){
					if($key=="")$key = $v["k"];
					if($value=="")$value = $v["v"];
					if ($key!='' && $value!=''){
						$config[$key]=$value;
						$key='';
						$value='';
					}
			}
			return $config;
		}
	}
?>