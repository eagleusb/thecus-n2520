<?php
require_once(INCLUDE_ROOT.'printer.class.php');

$gwords = $session->PageCode("global");
$words = $session->PageCode("printer");

$get_printer = new PRINTER_QUEUE();
$_printer_info = $get_printer->getPrinterInfo();

$btnDisabled = false;

if ($_printer_info['manufact'] == 'na')
    $btnDisabled = true;

$tpl->assign('gwords', json_encode($gwords));
$tpl->assign('words', json_encode($words));
$tpl->assign('btnDisabled', $btnDisabled);
$tpl->assign('printer_info', json_encode($_printer_info));
$tpl->assign('form_action','setmain.php?fun=setprinter');

unset($get_printer);

if($_REQUEST['update']==1){
    die(
        json_encode(
            array(
                'status'=>$_printer_info['status'],
                'manufact'=>$_printer_info['manufact'],
                'model'=>$_printer_info['model'],
                'btnDisabled'=>$btnDisabled
            )
        )
    );
}
?>
