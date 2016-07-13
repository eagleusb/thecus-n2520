<?php
require_once("session.php");

/**
* Validation class for validation of misc strings
*/
class validate extends Session{
  var $errmsg;
  var $gwords;

  /**
        * Regular expressions for postcode of the following countries
        **/
  var $pattern_ip='^([0-9]{1,3}\.){3}[0-9]{1,3}$';
  var $pattern_ip_nfs='[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/[0-9]{1,2}';
  var $pattern_url='^(http|ftp)://(www\.)?.+\.(com|net|org)$';
  var $pattern_simple_url = '^[0-9a-zA-Z_\.\/:\-]*$';
  
  var $pattern_general = '^([0-9a-zA-Z_\-])*$';
  
  var $pattern_username   = '/[\/\ :;<=>?@\[\]\\\\*\+\,]/';
  var $pattern_sharefolder   = '/[\[\]\!\`\'\"\/\*:<>?\\\|#]/';
  var $pattern_groupname   = '/[\ \\\!\"\#\%\$\&\'\(\)\*\/:;<=>?@\[\]\^\{\|\}\~\,]/';
  var $pattern_nsynctaskname   = '/[\*\"\/\:<>?\\\|`\[\]\{\}\$\.\(\)\^\+\-]/';
  
  var $pattern_domainname = '^([0-9a-zA-Z_\.\-])*$';
  var $pattern_hostname   = '^[0-9a-zA-Z_\-]{0,15}$';
  var $pattern_ha_hostname   = '^[a-zA-Z][-a-zA-Z0-9]{0,15}$';
  
  var $pattern_realm = '^[0-9a-zA-Z_\.\/\-]*$';
  var $pattern_iscsi_targetname = '^[0-9a-z\-]{0,12}$';
  var $pattern_iscsi_username = '^[0-9a-zA-Z]{0,12}$';
  var $pattern_iscsi_password = '^[0-9a-zA-Z]{12,16}$';
  var $pattern_stackablefolder = '^[0-9a-z]{0,60}$';
  var $pattern_ignore_filename = '/[\*\"\/\:<>?\\\|]/';
  var $pattern_iqnname = '^([0-9a-zA-Z_:\.\-])*$';
  
    //These ports are used by other services in the NAS.
    var $used_port = array(2000, 3689, 8080, 11000);  

  /**
  * The constructor of the validation class. 
  * Get global words array in $gwords.
  */  
  function validate(){
          $this->gwords = parent::PageCode('global');
  }

  /**
        * in_system_folder
  * @param string , The searched value.
  * @return boolean, return TRUE  if it is found in the array, FALSE otherwise.
  */  
  function in_system_folder($find){
    $system_folder=array('_module_folder_','_nas_module_source_','_p2p_download_','sys','tmp','lost+found','ftproot','dlnamedia','module','_sys_tmp','nsync','usbhdd','usbcopy','itunes_music','_nas_picture_','_nas_piczza_');
    if (NAS_DB_KEY == '1'){
       array_push($system_folder,'naswebsite');
    }else{
       array_push($system_folder,'nas_public','data','stackable','esatahdd','snapshot'); 
    }
    $recycle_folder='_nas_recycle_'; 
    if (strncmp(strtolower($find),$recycle_folder,strlen($recycle_folder))==0){ 
          return 1 ; 
    }else{
          $result = array_search(strtolower($find),$system_folder); 
          return ($result!=NULL && $result!==false);
    }
  }
  
  function hide_system_folder($find){
    return false;
  }
  

  /**
  * Validates the string if it consists of alphabetical chars
  * @param int $num_chars the number of chars in the string
  * @param string $behave defines how to check the string: min, max or exactly number of chars
  * @return true is valid ,else false.
  */  
  function alpha($num_chars,$behave,$str){
    if($behave=="min"){
      $pattern="^[a-zA-Z]{".$num_chars.",}$";
    }else if ($behave=="max"){
      $pattern="^[a-zA-Z]{0,".$num_chars."}$";
    }else if ($behave=="exactly"){
      $pattern="^[a-zA-Z]{".$num_chars.",".$num_chars."}$";
    }
    return ereg($pattern,$str);
  }
  
  /**
  * Validates the string if it consists of lowercase alphabetical chars
  * @param int $num_chars the number of chars in the string
  * @param string $behave defines how to check the string: min, max or exactly number of chars
  * @return true is valid ,else false.
  */  
  function alpha_lowercase($num_chars,$behave,$str){
    if($behave=="min"){
      $pattern="^[a-z]{".$num_chars.",}$";
    }else if ($behave=="max"){
      $pattern="^[a-z]{0,".$num_chars."}$";
    }else if ($behave=="exactly"){
      $pattern="^[a-z]{".$num_chars.",".$num_chars."}$";
    }
    return ereg($pattern,$str);
    
  }
  /**
  * Validates the string if it consists of uppercase alphabetical chars
  * @param int $num_chars the number of chars in the string
  * @param string $behave defines how to check the string: min, max or exactly number of chars
  * @return true is valid ,else false.
  */  
  function alpha_uppercase($num_chars,$behave,$str){
    if($behave=="min"){
      $pattern="^[A-Z]{".$num_chars.",}$";
    }else if ($behave=="max"){
      $pattern="^[A-Z]{0,".$num_chars."}$";
    }else if ($behave=="exactly"){
      $pattern="^[A-Z]{".$num_chars.",".$num_chars."}$";
    }
    return ereg($pattern,$str);
    
  }
  
  /**
  * Validates the string if it consists of numeric chars
  * @param int $num_chars the number of chars in the string
  * @param string $behave defines how to check the string: min, max or exactly number of chars
  * @return true is valid ,else false.
  */  
  function numeric($num_chars,$behave,$str){
    if($behave=="min"){
      $pattern="^[0-9]{".$num_chars.",}$";
    }else if ($behave=="max"){
      $pattern="^[0-9]{0,".$num_chars."}$";
    }else if ($behave=="exactly"){
      $pattern="^[0-9]{".$num_chars.",".$num_chars."}$";
    }
    return ereg($pattern,$str);
  }
  
  /**
  * Validates the string if it consists of alphanumerical chars
  * @param int $num_chars the number of chars in the string
  * @param string $behave defines how to check the string: min, max or exactly number of chars
  * @return true is valid ,else false.
  */    
  function alpha_numeric($num_chars,$behave,$str){
    if($behave=="min"){
      $pattern="^[0-9a-zA-Z]{".$num_chars.",}$";
    }else if ($behave=="max"){
      $pattern="^[0-9a-zA-Z]{0,".$num_chars."}$";
    }else if ($behave=="exactly"){
      $pattern="^[0-9a-zA-Z]{".$num_chars.",".$num_chars."}$";
    }
    return ereg($pattern,$str);
  }



  /**
  * Validates the string if its a valid ip address or string '*'
  * @return true is valid ,else false.
  */  
  function ip_address_nfs($str){
          $return = false;
          if($str=='*')return true;
    if(ereg($this->pattern_ip_nfs,$str)){
                       $return = true;
                 $mask = explode("/", $str);
                 if($mask[1]!='')
                         if($mask[1]<0 || $mask[1]>32) $return = false;
                       $str=$mask[0];
               }else{
            $return  = ereg($this->pattern_ip,$str);
                }
               $tmp = explode(".", $str);
               if($return){
                      foreach($tmp as $sub){
                            if($sub<0 || $sub>=256) $return = false;
                        }
                }
               $this->errmsg = $this->gwords['truncate_error'];
               return $return;
  }
  
  /**
  * Validates the string if its a valid ip address
  * @return true is valid ,else false.
  */  
  function ip_address($str){
          $return = false;
    $return  = ereg($this->pattern_ip,$str);
               $tmp = explode(".", $str);
               if($return){
                      foreach($tmp as $sub){
                           if($sub<0 || $sub>=256) $return = false;
                      }
                }
               $this->errmsg = $this->gwords['truncate_error'];
               return $return;
  }

  /**
  * Validates the string if its a valid ipv6 address
  * @return true is valid ,else false.
  */  
  function ipv6_address($str) {
    $pattern1 = '([A-Fa-f0-9]{1,4}:){7}[A-Fa-f0-9]{1,4}';
    $pattern2 = '[A-Fa-f0-9]{1,4}::([A-Fa-f0-9]{1,4}:){0,5}[A-Fa-f0-9]{1,4}';
    $pattern3 = '([A-Fa-f0-9]{1,4}:){2}:([A-Fa-f0-9]{1,4}:){0,4}[A-Fa-f0-9]{1,4}';
    $pattern4 = '([A-Fa-f0-9]{1,4}:){3}:([A-Fa-f0-9]{1,4}:){0,3}[A-Fa-f0-9]{1,4}';
    $pattern5 = '([A-Fa-f0-9]{1,4}:){4}:([A-Fa-f0-9]{1,4}:){0,2}[A-Fa-f0-9]{1,4}';
    $pattern6 = '([A-Fa-f0-9]{1,4}:){5}:([A-Fa-f0-9]{1,4}:){0,1}[A-Fa-f0-9]{1,4}';
    $pattern7 = '([A-Fa-f0-9]{1,4}:){6}:[A-Fa-f0-9]{1,4}';
 
    $full = "/^($pattern1)$|^($pattern2)$|^($pattern3)$|^($pattern4)$|^($pattern5)$|^($pattern6)$|^($pattern7)$/";
 
    if(!preg_match($full, $str))
      return (false); // is not a valid IPv6 Address
 
    return (true);
  }

  /**
  * To get complete IPv6 address string , MUST verify the string is IPv6 address first
  * @return string IPv6 complete adress 
  * example: get_complete_ipv6_addr("200:1:22:333:4444:5:6:777") return 020000010022033344440005000607777
  */  
  function get_complete_ipv6_addr($ipv6_addr) {
    $complete_ipv6_addr = '';
    $ipv6_array = explode(':', $ipv6_addr);
    $zero_field = 8 - sizeof($ipv6_array);
    if ($zero_field > 0) {
      $index = array_keys($ipv6_array, '');
      for ($i = 0; $i < $zero_field + 1; $i++)
        $ipv6_array[$index[0]] .= '0000';
    }
    for ($i = 0; $i < sizeof($ipv6_array); $i++) {
      $zero = 4 - strlen($ipv6_array[$i]);
      if ($zero > 0) { 
	$insert = str_repeat('0', $zero);
	$ipv6_array[$i] = substr_replace($ipv6_array[$i], $insert, 0, 0);
      }
      $complete_ipv6_addr .= $ipv6_array[$i];
    }
    return $complete_ipv6_addr;
  }

  /**
  * Compare two IPv6 address prefix 
  * @return true is the same, false is different  
  */  
  function compare_ipv6_prefix($ip1, $ip2, $length) {
    $ip1c = $this->get_complete_ipv6_addr($ip1);
    $ip2c = $this->get_complete_ipv6_addr($ip2);
    $ch_len = (int)$length / 4;

    if (substr($ip1c, 0, $ch_len) == substr($ip2c, 0, $ch_len))
      return (true);
    else
      return (false);
  }

  /**
  * Validates Prefix Length
  * @return true is valid ,else false.
  */  
  function ipv6_prefix($length) {
    $len = (int)$length;
    return $len > 0 && $len % 4 == 0 && $len <= 128;
  }
 
  /**
  * Validates the string if its a valid URL
  * @return true is valid ,else false.
  */  
  function url($str){
    return ereg($this->pattern_url,$str);
  }
  
  /**
  * Validates the string if its a valid simple URL without http://|ftp://
  * @return true is valid ,else false.
  */  
  function is_simple_url($str){
    return ereg($this->pattern_simple_url,$str);
  }
  
  /**
  * Validates the string if its a valid char 
  * @return true is valid ,else false.
  */  
  function general($str){
    return ereg($this->pattern_general,$str);
  }
  
  /**
  * limit string length. 
  * @return true is valid ,else false.
  */  
  function limitstrlen($min,$max,$str){
          $len = iconv_strlen($str, 'utf-8');
          if($len<$min) return false;
          if($len>$max) return false;
          return true;
  }
  
  /**
  * limit blank string. 
  * @return true is valid ,else false.
  */  
  function limitblank($str,$middle=false){
          $len = strlen($str);
          $result = true;
          $middle_blank=0;
          for($i=0;$i<$len;$i++){
             if(ord($str[$i])==32){
                if($i==0){
                   $result = false;
                    break;
                }else if($i==($len-1)){
                   $result = false;
                    break;
                }else if($middle && $middle_blank>0){
                   $result = false;
                    break;
                }
                $middle_blank++;   
             }else
                      $middle_blank=0;
          }
          return $result;
  }
  
  
  
  function check_string($mode,$str){
      $len = iconv_strlen($str, 'utf-8');
             for($c=0;$c<$len;$c++){
         $substr=ord($str[$c]);
               if($mode == "ip"){
                    if($substr == 46){
                       continue;
                    }
                }
                if(($substr < 48 || $substr > 57) && ($substr < 65 || $substr > 90) && ($substr < 97 || $substr > 122) && $substr != 45 && $substr != 95){
                   return 1;
                }
           }
           return 0;
        }
  
  /**
  * Validates the string if it consists of single byte chars
  * @return true is valid ,else false.
  */  
  function singlebyte($str){
          for($i=0;$i<strlen($str);$i++){
             if(ord($str[$i])>126 || ord($str[$i])<=32){
               return false;
               break;   
             }
          }
          return true;
  }
  
  
  /**
  * Check Nsync Task Name valid the string if it consists of format chars
  * @param string $str -  string has been validated. 
  * @return true is valid ,else false.
  */    
  function check_nsynctaskname($str){
          if(!$this->limitstrlen(0,60,$str))
              return false;
          preg_match($this->pattern_nsynctaskname, $str, $matches);
          return !$matches[0];
  }
  /**
  * Check Group Name valid the string if it consists of format chars
  * @param string $str -  string has been validated. 
  * @return true is valid ,else false.
  */    
  function check_groupname($str){
          if(!$this->limitstrlen(0,64,$str))
              return false;
          preg_match($this->pattern_groupname, $str, $matches);
          return !$matches[0];
  }
  
  /**
  * Check Realm valid the string if it consists of format chars
  * @param string $str -  string has been validated. 
  * @return true is valid ,else false.
  */    
  function check_realm($str){
          if(!$this->singlebyte($str))
             return false;
          return ereg($this->pattern_realm,$str);
  }
  
  /**
  * Check iSCSI Target Name valid the string if it consists of format chars
  * @param string $str -  string has been validated. 
  * @return true is valid ,else false.
  */    
  function check_iscsi_targetname($str){
          if(!$this->singlebyte($str))
             return false;
          return ereg($this->pattern_iscsi_targetname,$str);
  }
  
  /**
  * Check iSCSI UserName valid the string if it consists of format chars
  * @param string $str -  string has been validated. 
  * @return true is valid ,else false.
  */    
  function check_iscsi_username($str){
          if(!$this->singlebyte($str))
             return false;
          return ereg($this->pattern_iscsi_username,$str);
  }
  
  /**
  * Check iSCSI Password valid the string if it consists of format chars
  * @param string $str -  string has been validated. 
  * @return true is valid ,else false.
  */    
  function check_iscsi_password($str){
          return ereg($this->pattern_iscsi_password,$str);
  }
  
  /**
  * Check Stackable Folder valid the string if it consists of format chars
  * @param string $str -  string has been validated. 
  * @return true is valid ,else false.
  */    
  function check_stackablefolder($str){
          $words = parent::PageCode('addshare');
          if(!$this->singlebyte($str)){
             $this->errmsg= $words['folder_error'];
             return false;
          }   
          if(!$this->limitstrlen(0,60,$str)){
              $this->errmsg= $words['folder_error'];
              return false;
          }
          if(!$this->limitblank($str,true)){
              $this->errmsg= $words['ERROR_SHARENAME_BLANK'];
              return false;
          }
/*
          if(in_array(strtolower($str),array('sys','tmp','lost+found','ftproot','dlnamedia','module','itunes_music'))){
              $this->errmsg= $words['stop_create_folder'];
              return false; 
          }
*/
                if(!ereg($this->pattern_general,$str)){
              $this->errmsg= $words['folder_error'];
              return false;
          }
          return true;
  }
  
  
  /**
  * Check Domain Name valid the string if it consists of format chars
  * @param string $str -  string has been validated. 
  * @return true is valid ,else false.
  */    
  function check_domainname($str){
          if(!$this->singlebyte($str))
             return false;
          return ereg($this->pattern_domainname,$str);
  }
  
  /**
  * Check Work Group valid the string if it consists of format chars
  * @param string $str -  string has been validated. 
  * @return true is valid ,else false.
  */    
  function check_workgroup($str){
          if(!$this->singlebyte($str))
             return false;
          return ereg($this->pattern_hostname,$str);
  }
  
  /**
  * Check Host Name valid the string if it consists of format chars
  * @param string $str -  string has been validated. 
  * @return true is valid ,else false.
  */    
  function check_hostname($str){
            if($str=="" || !$this->singlebyte($str))
             return false;
          return ereg($this->pattern_hostname,$str);
  }  
    
  /**
  * Check HA Hostname valid the string if it consists of format chars
  * @param string $str -  string has been validated. 
  * @return true is valid ,else false.
  */      
  function check_ha_hostname($str){
          if($str=="" || !$this->singlebyte($str))
             return false;
          return ereg($this->pattern_ha_hostname,$str);
  }
    
  /**
  * Check UserName valid the string if it consists of format chars
  * @param string $str -  string has been validated. 
  * @return true is valid ,else false.
  */    
  function check_username($str){
          if(in_array($str,array('root','ftp','admin','sshd','nobody'))){
               return false; 
          }
          if (!$this->limitstrlen(0,64,$str))
               return false; 

          preg_match($this->pattern_username, $str, $matches);
          return !$matches[0];
  }
  /**
  * Check Share folder name  valid the string if it consists of format chars
  * @param string $str -  string has been validated. 
  * @return true is valid ,else false.
  */    
  function check_sharefolder($str){
          $words = parent::PageCode('addshare');
          if(!$this->limitstrlen(0,60,$str)){
              $this->errmsg= $words['folder_error'];
              return false;
          }
          if(!$this->limitblank($str,true)){
              $this->errmsg= $words['folder_error'];
              return false;
          }
                if($this->in_system_folder($str)){
              $this->errmsg= $words['stop_create_folder'];
              return false; 
          }
          preg_match($this->pattern_sharefolder, $str, $matches);
          if($matches){
              $this->errmsg= $words['folder_error'];
              return false;
          }
          return true;
  }
  
  /**
  * Check Quota Limit  valid the string if it consists of format chars
  * @param string $str -  string has been validated. 
  * @return true is valid ,else false.
  */    
  function check_quota_limit($str){
          $words = parent::PageCode('addshare');
          if($str<0){
              $this->errmsg= $words['quota_range_error'];
              return false;
          }
          if(!$this->numeric(0,'min',$str)){
              $this->errmsg= $words['quota_format_error'];
              return false;
          }
          return true;
  }
    
  /**
  * Check System Description valid the string if it consists of format chars
  * @param string $str -  string has been validated. 
  * @return true is valid ,else false.
  */    
  function check_sys_desc($str){
               return $this->limitstrlen(0,255,$str);
  }
  
  /**
  * Check Admin Password valid the string if it consists of format chars
  * @param string $str -  string has been validated. 
  * @return true is valid ,else false.
  */    
  function check_adminpwd($str){
               if(!$this->singlebyte($str) || !$this->limitstrlen(4,16,$str))
                 return false;
               else
                 return true;
  }
  
  /**
  * Check User Password valid the string if it consists of format chars
  * @param string $str -  string has been validated. 
  * @return true is valid ,else false.
  */    
  function check_userpwd($str){
               if(!$this->singlebyte($str) || !$this->limitstrlen(4,16,$str))
                 return false;
               else
                 return true;
  }
  
  /**
  * Check RAID ID valid the string if it consists of format chars
  * @param string $str -  string has been validated. 
  * @return true is valid ,else false.
  */    
  function check_raid_id($str){
          if(!$this->singlebyte($str))
             return false;
          return ereg($this->pattern_iscsi_username,$str);
  }
  
  /**
  * Check Share Folder Description valid the string if it consists of format chars
  * @param string $str -  string has been validated. 
  * @return true is valid ,else false.
  */    
  function check_sharefolder_desc($str){
          return $this->limitstrlen(0,60,$str);
  }

  /**
  * Check the EMail valid the string if it consists of format chars
  * @param string $str -  string has been validated. 
  * @return true is valid ,else false.
  */    
    function check_email($str){
        $emailStr = str_replace(" ", "", $str);
        $emailStr = explode("@", $emailStr);
    
        if (count($emailStr) != 2)
            return false;

        for ($i=0; $i<2; $i++){
            if(!$this->is_simple_url($emailStr[$i]))
                return false;
        }

        return true;
    }


  /**
  * Check the string if it is empty beside the blank
  * @param string $str -  string has been validated. 
  * @return true is valid ,else false.
  */    
    function check_empty($str){
        $str = str_replace(" ", "", $str);
    
        return ($str == '');
    }


  /**
  * Check the string if it consists of format Port
  * @param string $str -  string has been validated. 
  * @return true is valid ,else false.
  */    
    function check_port($str){
        $port = str_replace(" ", "", $str);

        for ($i=0;$i<strlen($port);$i++){
            $tmp = ord(substr($port, $i));
        
            if(($tmp <= 47 || $tmp >= 58))
                return false;
        }

        $tmp = intval($port);
        if($tmp < 1 || $tmp > 65535)
            return false;
    
        return true;
    }

  /**
  * Check the string if it consists of the used Port
  * @param string $str -  string has been validated. 
  * @return true is valid ,else false.
  */    
    function check_used_port($str){
        $port = str_replace(" ", "", $str);

        foreach ($this->used_port as $value)
        {
            if ($port == $value)
                return true;
        }
        
        return false;
    }
    
  /**
  * Check isomount folder name  valid the string if it consists of format chars
  * @param string $str -  string has been validated. 
  * @return true is valid ,else false.
  */      
  function check_isomountfolder($str){
          if(!$this->check_sharefolder($str)){
              return false;
          }
          return true;
  }
  
  /**
  * Check folder or file name valid the string if it consists of format chars , it don't show on UI
  * @param string $str -  string has been validated. 
  * @return true is valid ,else false.
  */      
  function check_ignore_file($str){
          preg_match($this->pattern_ignore_filename, $str, $matches);
          if($matches){             
              return false;
          }
          return true;
  } 

	/**
	* Check IQN Name valid the string if it consists of format chars
	* @param string $str -  string has been validated. 
	* @return true is valid ,else false.
	*/		
	function check_iqnname($str){
	        if(!$this->singlebyte($str))
	           return false;
	        return ereg($this->pattern_iqnname,$str);
	}

}
$validate = new validate();
?>
