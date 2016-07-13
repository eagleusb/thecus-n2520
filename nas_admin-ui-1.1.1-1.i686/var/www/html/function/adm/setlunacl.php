<?
require_once(INCLUDE_ROOT.'validate.class.php');
include_once(INCLUDE_ROOT.'info/raidinfo.class.php');
$words = $session->PageCode("raid");
$gwords = $session->PageCode("global");

$init_iqn=strtolower($_POST["iqn_name"]);
$o_init_iqn=$_POST["target_iqn"];
$type = $_POST["now_add_id"];
$fn = array('ok'=>'execute_success("1")');

$raid = new RAIDINFO();
$md_array=$raid->getMdArray();

if ($type=="acl_add"){
  if($init_iqn=="" || !$validate->check_iqnname($init_iqn))
	 return  MessageBox(true,$words['lun_acl'],$words["iqn_error"],'ERROR');
	
  foreach($md_array as $md_id){
    $strExec="/usr/bin/sqlite /raid".$md_id."/sys/smb.db \"select * from lun_acl where init_iqn='". $init_iqn."'\"";
    $result=shell_exec($strExec);
      
    if ($result != ""){
      return  array("show"=>true,
                    "topic"=>$words['lun_acl'],
                    "message"=>$words["lun_setacl_duplicate"],
                    "icon"=>'ERROR',
                    "button"=>'OK',
                    "fn"=>$fn,
                    "prompt"=>'');
    }
  }

  foreach($md_array as $md_id){
    $strExec="/usr/bin/sqlite /raid".$md_id."/sys/smb.db \"select name from lun\"";
    $result=shell_exec($strExec);
  
    $lunname=preg_split("/[\s\n]/",$result, -1, PREG_SPLIT_NO_EMPTY);
    foreach($lunname as $target){
      $lun_id="radio_".$target;
      $lun_priv=$_POST[$lun_id];
        
      $col="init_iqn, lunname, privilege";
      $values="'" . $init_iqn . "','" . $target . "','" . $lun_priv . "'";
      $strExec="/usr/bin/sqlite /raid".$md_id."/sys/smb.db \"insert into lun_acl (".$col .") values(".$values.")\"";
      shell_exec($strExec);
      
      $strExec="/img/bin/rc/rc.iscsi add_acl $init_iqn '$md_id' $target";
      shell_exec($strExec);
    }
  }
}elseif ($type=="acl_delete"){    
  foreach($md_array as $md_id){
    $strExec="/usr/bin/sqlite /raid".$md_id."/sys/smb.db \"select name from lun\"";
    $result=shell_exec($strExec);
  
    $lunname=preg_split("/[\s\n]/",$result, -1, PREG_SPLIT_NO_EMPTY);
    foreach($lunname as $target){
      $strExec="/img/bin/rc/rc.iscsi del_acl $o_init_iqn '$md_id' $target";
      shell_exec($strExec);
    }

    $strExec="/usr/bin/sqlite /raid".$md_id."/sys/smb.db \"delete from lun_acl where init_iqn='". $o_init_iqn."'\"";
    shell_exec($strExec);
  }
}elseif ($type=="acl_modify"){    
  foreach($md_array as $md_id){
    $strExec="/usr/bin/sqlite /raid".$md_id."/sys/smb.db \"select name from lun\"";
    $result=shell_exec($strExec);
  
    $lunname=preg_split("/[\s\n]/",$result, -1, PREG_SPLIT_NO_EMPTY);
    foreach($lunname as $target){
      $lun_id="radio_".$target;
      $lun_priv=$_POST[$lun_id];

      $strExec="/usr/bin/sqlite /raid".$md_id."/sys/smb.db \"select privilege from lun_acl where init_iqn='". $o_init_iqn."' and lunname='". $target ."'\"";
      $privilege=trim(shell_exec($strExec));
      
      if ($privilege==""){  
        $col="init_iqn, lunname, privilege";
        $values="'" . $o_init_iqn . "','" . $target . "','" . $lun_priv . "'";
        $strExec="/usr/bin/sqlite /raid".$md_id."/sys/smb.db \"insert into lun_acl (".$col .") values(".$values.")\"";
        shell_exec($strExec);
        $strExec="/img/bin/rc/rc.iscsi add_acl $o_init_iqn '$md_id' $target";
        shell_exec($strExec);
      }else{
        if ($privilege!=$lun_priv){
          $strExec="/img/bin/rc/rc.iscsi del_acl $o_init_iqn '$md_id' $target";
          shell_exec($strExec);
        
          $strExec="/usr/bin/sqlite /raid".$md_id."/sys/smb.db \"update lun_acl set privilege='" . $lun_priv ."' where init_iqn='". $o_init_iqn."' and lunname='". $target ."'\"";
          shell_exec($strExec);
          
          $strExec="/img/bin/rc/rc.iscsi add_acl $o_init_iqn '$md_id' $target";
          shell_exec($strExec);
        }
      }
    }
  }
}

return  array("show"=>true,
              "topic"=>$words['lun_acl'],
              "message"=>$words["lun_setacl_success"],
              "icon"=>'INFO',
              "button"=>'OK',
              "fn"=>$fn,
              "prompt"=>'');
?>
