<?
function check_url_attack($value,$redirect){
  require_once("/var/www/html/htdocs/setlang/lang.html");
  $words = PageCode('security');
  $check_string="[;|`&<>]";
  //echo "value=$value<BR>";
  //echo "redir=$redirect<BR>";
  if(preg_match("/$check_string/i",$value)){
    require_once("/var/www/html/inc/msgbox.inc.php");
    $a=new msgBox($words["url_warning"],"OKOnly",$words["warning"]);
    $url=$redirect;
    $a->makeLinks(array($url));
    echo "<html><head></head><body>".$a->showMsg()."</body></heml>";
    //echo "waring";
    exit;
  }else{
    //echo "save";
  }
}

function check_auth($session){
  //print_r($session);
  if($session["username"]==""){
     header('Location: /unauth.htm');
     exit;
  }
}

function check_admin($session){
  if(!$session["loginid"]){
     die("<script>location.href='/adm/index.php';</script>");
     exit;
  }
}
?>
