<?
require_once(INCLUDE_ROOT.'function.php');
require_once(INCLUDE_ROOT.'sqlitedb.class.php');

$db=new sqlitedb();

$gwords = $session->PageCode("global");
$words = $session->PageCode("disclaimer");

//$disclaimer_enabled=trim($_GET["disclaimer_enabled"]);
if($_GET["disclaimer_enabled"]=="true"){
	$disclaimer_enabled="1";	
}else{
	$disclaimer_enabled="0";	
}
$db->setvar("disclaimer_enabled",$disclaimer_enabled);
$_SESSION["disclaimer_flag"]="1";
header ("Location:/index.php");


die(
	json_encode(
		array(
			$_GET,$disclaimer_enabled
		)
	)
);
?>
