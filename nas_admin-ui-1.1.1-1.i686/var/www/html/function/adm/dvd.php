<?php
/**
* get wording
*/
$words = $session->PageCode("dvd");
$words['apply'] = $gwords['apply'];
$words['add'] = $gwords['add'];
$words['remove'] = $gwords['remove'];
$words['name'] = $gwords['name'];
$words['size'] = $gwords['size'];
$words['select'] = $gwords['select'];
$words['cancel'] = $gwords['cancel']; 
$words['blanktext'] = $gwords['blanktext']; 
$words['error'] = $gwords['error']; 
$words['remove_all'] = $gwords['remove_all'];
$words['status'] = $gwords['status'];
$words['search'] = $gwords['search'];
$words['type'] = $gwords['type'];
$words['edit'] = $gwords['edit'];

/**
* get drive name...
*/
$drive = array();
array_push($drive, array('display'=> "---------------".$gwords['select']."---------------", 'value'=>''));
$p = popen(IMG_BIN.'/burn_cd.sh check', 'r');
while(!feof($p)){
    $line = fgets($p, 4096);
    list($name, $type, $dev) = explode("|", $line);
    if(!empty($name)){
        array_push($drive, array('display'=> "$name $type", 'value'=>trim($dev)));
    }
}
pclose($p);
$res = array( "drive"=>$drive,  "def_isoname"=>'images.iso' );


/**
* display
*/
$tpl->assign("words",json_encode($words));
$tpl->assign("obj",json_encode($res));
?>
