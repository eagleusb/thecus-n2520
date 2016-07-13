<?php
//if using function processAjax(), don't include these php-pages. 
if (isset($_REQUEST["processAjax"]))
{
	require_once('../conf/localconfig.php');
    require_once(INCLUDE_ROOT.'sqlitedb.class.php');
    require_once(INCLUDE_ROOT.'inittemplate.php');
	require_once(INCLUDE_ROOT.'session.php');
	require_once(INCLUDE_ROOT.'publicfun.php');
}

//echo $_GET['module'],'<br>';
    
$module_db_path= MODULE_ROOT . "cfg/premod.db";
//echo $module_db_path,'<br>';
if (file_exists($module_db_path)) {
    $db = new sqlitedb($module_db_path, 'module');
    list($mod_name,$mod_version,$mod_description,$mod_enable,$mod_update_url) = $db->runSQL('select * from module where name = "'.$_GET['module'].'"');
    
    //echo $mod_name,$mod_version,$mod_description,$mod_enable,$mod_update_url,'<br>';

    $mod_rs = "select object from mod where module = '$mod_name' and predicate = 'Authors'";
    $mod_authors = $db->runSQL($mod_rs);

    $mod_rs = "select object from mod where module = '$mod_name' and predicate = 'WebUrl'";
    $mod_web_url = $db->runSQL($mod_rs);

    $mod_rs = "select object from mod where module = '$mod_name' and predicate = 'Thanks'";
    $mod_thanks_ary = $db->runSQLAry($mod_rs);
        
    foreach ($mod_thanks_ary as $ary){
        $mod_thanks .= $ary[0]."\n";
    }
        
    $mod_thanks = trim($mod_thanks);
    unset($db);
}

$module_copy_path = '/raid/data/module/.module/' . $mod_name . '/Configure/license.txt';

if (file_exists($module_copy_path)){
        $mod_copy=file_get_contents($module_copy_path);
}

$mod_size=shell_exec('du -hc "/raid/data/module/.module/'.$mod_name.'" | awk \'/total/{printf "%sB\n",$1}\'');

die(json_encode(array('name'=>$mod_name,
                      'version'=>$mod_version,
                      'description'=>$mod_description,
                      'size'=>$mod_size,
                      'authors'=>$mod_authors[0],
                      'web'=>$mod_web_url[0],
                      'license'=>$mod_copy,
                      'acknowledgments'=>$mod_thanks
)));

?>

