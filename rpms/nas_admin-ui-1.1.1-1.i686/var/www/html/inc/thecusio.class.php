<?
class THECUSIO{
  var $ledname;
  var $action;
  function THECUSIO(){
  }
  function setLED($ledname,$action){
    $strExec="echo '".$ledname." ".$action."' > /proc/thecus_io";
    shell_exec($strExec);
  }
}
?>
