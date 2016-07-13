<?
//For RAID BASIC variable
$mddisk="/dev/md".$md_num;
$mdname="md".$md_num;
if (NAS_DB_KEY == '1'){
	$swapname="md0";
	$swapdisk="/dev/md0";
}else{
	$swapname="md10";
	$swapdisk="/dev/md10";
}
?>