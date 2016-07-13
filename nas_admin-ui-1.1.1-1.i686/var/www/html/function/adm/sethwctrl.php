<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'function.php');
get_sysconf();

$db=new sqlitedb();
$count = $sysconf['gpiocount'];
for($i=1;$i<=$count;$i++){
    $gpio = $_POST['gpio'.$i];
    $db->setvar("gpio".$i, $gpio);
    
    if($gpio=='1'){
	//write (output)
        shell_exec("echo 0 0 GPIO 1 $i 0 > /var/tmp/oled/pipecmd");
    }else{
	//read (input)
        shell_exec("echo 0 0 GPIO 0 $i > /var/tmp/oled/pipecmd");
    }
    
}
unset($db);
die(json_encode(array("success"=>true)));
?>
