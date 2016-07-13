<?php
   require_once('../../../../inc/conf.class.php');
   $conf=new Configure();
   $fields=array('allset_name','allset_desp');
   header('Content-Type: application/x-javascript');
   echo "var _sysinfo={}\n";
   foreach ($fields as $field){
       $entries=$conf->get("$field");
       foreach ($entries as $entry){
           $v=$entry['v'];
           str_replace($v,'\\\'','\'');
           echo "_sysinfo['{$entry['k']}']='$v'\n";
       }
   }
?>
