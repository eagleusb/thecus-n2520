<?    
    global $HTTP_SERVER_VARS ;
    require_once('../../../../function/conf/localconfig.php');
    require_once(WEBCONFIG);
    require_once(INCLUDE_ROOT.'sqlitedb.class.php');
    $db=new sqlitedb();
//    $db->connect();

    $hostname = $db->getvar("nic1_hostname","");
    $db->db_close();
    unset($db);
//    echo $hostname."    ".$HTTP_SERVER_VARS['HTTP_HOST']."  ".$webconfig['product_no']."  ".$webconfig['pro'];
//    exit;
    header("Content-Type: application/octet-stream");
    header("Content-Disposition: attachment; filename=Publish.reg");

    $lines[] = 'Windows Registry Editor Version 5.00';
    $lines[] = '';
    if(strstr($_SERVER["HTTP_USER_AGENT"], "NT 6.0") || strstr($_SERVER["HTTP_USER_AGENT"], "NT 6.1")){
    	$lines[] = '[HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\PublishingWizard\\InternetPhotoPrinting\\Providers\\'.$webconfig['product_no'].$webconfig['pro'].'_Gallery_'.$hostname.']';
    }else{
    	$lines[] = '[HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\PublishingWizard\\PublishingWizard\\Providers\\'.$webconfig['product_no'].$webconfig['pro'].'_Gallery_'.$hostname.']';
    }
    $lines[] = '"displayname"="'.$webconfig['product_no'].$webconfig['pro'].' Photo Gallery - '.$hostname.'"';
    $lines[] = '"description"="'.$webconfig['product_no'].$webconfig['pro'].' Photo Gallery Wizard"';
    $lines[] = '"href"="' . "http://" . $HTTP_SERVER_VARS['HTTP_HOST'] . '/usr/gallery/XPublish/?cmd=publish"';
    $lines[] = '"icon"="' . "http://" . $HTTP_SERVER_VARS['HTTP_HOST'] . '/usr/gallery/img/logo.ico"';
    print join("\r\n", $lines);
    print "\r\n";
    exit;
?>
