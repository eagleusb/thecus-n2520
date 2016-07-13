<?php
define('RC_MODULE_PATH', '/img/bin/rc/rc.module');
define('RC_AUTOMODULE_PATH', '/img/bin/rc/rc.automodule');
/**
 * Module class
 * @author Enian
 * 
 * @property	 nas_type : type in this nas
 * @property	 nas_producer : producer in this nas
 * @property	 nas_version : new FW in this nas
 * @property	 nas_fw_type : Fw model in this nas
 * @property	 module_db_path : module db path
 * @property	 tmp_db_path : tmep module db path 
 * @property	 db : module db
 * @property	 old_db : temp module db before parse
 * @property	 upgrade_flag : execute install or upgrade flag
 * @property	 fail_flag : install fail flag
 * @property	 mod_name : module name
 * @property	 log_path : module log file
 * @property	 tmp_log_path : tmep log file
 * @property	 gid : module item gid
 * @property	 lock_flag : module lock flag
 * @property	 shellcmd : execute module action shell
 * @property	 tmp_error_msg : enable error log file
 * @method lock_exist(): module is lock or not
 * @method create_lock($type): create module lock flag and set module action type
 * @method set_msg($log): set log msg
 * @method upload_file($file): upload module file
 * @method set_mod_name($module_name): set module name and log path
 * @method copy_del_db(): backup old module.db and delete releated module data
 * @method parser_rdf(): parser rdf file
 * @method set_basic_msg(): set module name and version msg, when install
 * @method compare_ver($val1,$val2): compare val1 and val2
 * @method check_install_type(): check install type is install or upgrade and version is ok
 * @method check_mac(): check nas mac is ok for module
 * @method check_nas_type($tag): check nas type or protol is ok for module defined
 * @method check_nas_version(): check nas version is ok for module defined
 * @method check_nas(): execute check nas version , type for module defined
 * @method check_depend_module(): check depend module in module defined
 * @method compare_conf(): check module defined item 
 * @method execute_install(): execute install shell script
 * @method restore(): recover old db 
 * @method execute_uninstall(): execute uninstall shell script
 * @method execute_enable(): execute uninstall shell script
 */
class Module {
	var $nas_type;
	var $nas_producer;
	var $nas_version;
	var $nas_fw_type;
	var $module_db_path,$tmp_db_path;
	var $db,$old_db;
	var $upgrade_flag,$fail_flag;
	var $mod_name;
	var $log_path,$tmp_log_path;
	var $word,$gword;
	var $gid;
	var $lock_flag;
	var $shellcmd;
	var $tmp_error_msg;
	var $folder_name;
	var $tmp_backup;
	var $tmp_path;
	var $tmp_item_file;
  
	function __construct($word,$gword, $shellcmd=RC_MODULE_PATH){
		$this->nas_type=trim(shell_exec('/img/bin/check_service.sh module_type'));
		$this->nas_producer=trim(shell_exec('awk \'/producer/{print $2}\' /etc/manifest.txt'));
		$this->nas_version=trim(shell_exec('cat /etc/version'));
		$this->nas_fw_type=strtoupper(trim(shell_exec("cat /proc/thecus_io | awk -F':' '/^MODELNAME:/{print $2}'")));
		if (NAS_DB_KEY==2){
			$this->nas_fw_type=$this->nas_type;
		}
		$this->module_db_path= MODULE_ROOT.'cfg/module.db';
		$this->tmp_backup=MODULE_TMP.'/tmp_backup';
		$this->tmp_path='/var/tmp/tmp_module';
		$this->tmp_db_path=$this->tmp_backup.'/module.db';			
		$this->upgrade_flag=0;
		$this->fail_flag=0;		
		$this->tmp_log_path=$this->tmp_path.'/tmp_module_log.txt';
		$this->tmp_error_msg=$this->tmp_path."/enable_error";
		$this->tmp_item_file=$this->tmp_path."/module_item";
		$this->word=$word;
		$this->gword=$gword;
		$this->lock_flag=$this->tmp_path."/module.lock";
		$this->shellcmd=$shellcmd;
		$this->mod_name="";
		if (!file_exists($this->tmp_path)){
			@mkdir($this->tmp_path,0755,true);
		}
	}

	function __destruct(){
		if ($this->db) {
			$this->db->db_close();
			unset($this->db);
		}
	}

	/**
	 * Module::lock_exist
	 * @param none
	 * @return 1 or 0 (exist or not exist)
	 */
	function lock_exist(){
		$ret=1;

		if (file_exists($this->lock_flag)){
			$ret=0;
		}

		return $ret;
	}

	/**
	 * Module::create_lock($type)
	 * @param 0/1 (install,uninstall/enable,disable)
	 * @return none
	 */
	function create_lock($type){
		unlink($this->tmp_log_path);
		unlink($this->tmp_error_msg);
		shell_exec("echo \"".$type."\" > ".$this->lock_flag);
	}

	/**
	 * Module::set_msg($log)
	 * @param $log: want to set message
	 * @return none
	 */
	function set_msg($log,$show_time=true){
		if ($show_time)		
			$now_time=date('Y/m/d H:i:s').": ";
		else
			$now_time="";
		shell_exec("echo '".$now_time.$log."' >> ".$this->tmp_log_path);
	}

	/**
	 * Module::upload_file($file)
	 * @param $file: file object path
	 * @return module name
	 */
	function upload_file($file){
//		shell_exec("echo \"2\" > ".$this->lock_flag);
		unlink(MODULE_TMP."module.app");
		unlink(MODULE_TMP."module.tgz");
		if (file_exists(MODULE_TMP."module"))
			shell_exec("rm -rf '".MODULE_TMP."module'");

		$tmp_file="/tmp/module_enc";
		$ret=move_uploaded_file($file, MODULE_TMP.'module.app');
		if ($ret){
			$str="hexdump ".MODULE_TMP."module.app | head -1 | awk '$1~/0000000/&&$2~/8b1f/{print 1}'";
		
			shell_exec($str." > ".$tmp_file);
			$is_enc=file($tmp_file);
			unlink($tmp_file);
			if ( trim($is_enc[0]) != "1"){
				shell_exec('des -D -k AppModule ' . MODULE_TMP . 'module.app ' . MODULE_TMP . 'module.tgz');
			}else{
				rename(MODULE_TMP."module.app",MODULE_TMP."module.tgz");
			}

			$mod_name = substr(trim(shell_exec('tar ztf ' . MODULE_TMP . 'module.tgz | head -1')),0,-1);

			if (substr($mod_name,0,2)=="./")
				$mod_name=substr($mod_name,2);
		
			shell_exec('cd ' . MODULE_TMP . ' ;tar zxvf module.tgz ; mv `tar ztf ./module.tgz | head -1` module');
		}else{
			$module="";	
		}
		shell_exec("echo \"0\" > ".$this->lock_flag);
		return $mod_name;
	}

	/**
	 * Module::set_mod_name($module_name)
	 * @param $module_name: module name
	 * @return none
	 */
	function set_mod_name($module_name){
		$folder_name=explode("\n",shell_exec("awk -F'[<>/:]' '/md:Key/{print $4}' ".MODULE_TMP."module/Configure/install.rdf"));
	  if ($folder_name[0] != ""){
	  	$this->mod_name=$folder_name[0];
	  }else{
		  $this->mod_name=$module_name;
		}
		$this->log_path=MODULE_ROOT.$this->mod_name.'/log.txt';
		return $this->mod_name;
	}

	/**
	 * Module::copy_del_db()
	 * @param none
	 * @return none
	 */
	function copy_del_db(){
		$this->db = new sqlitedb($this->module_db_path,'module');
		if (!file_exists($this->tmp_backup)){
			@mkdir($this->tmp_backup,0755,true);
		}
		copy($this->module_db_path,$this->tmp_db_path);
		$this->old_db=new sqlitedb($this->tmp_db_path,'module');
		$rs_ins="delete from mod where module = '".$this->mod_name."'";
		$this->db->runSQL($rs_ins);
		$rs_ins="delete from module where name = '".$this->mod_name."'";
		$this->db->runSQL($rs_ins);
	}
	
	/**
	 * Module::parser_rdf()
	 * @param none
	 * @return none
	 */
	function parser_rdf($base=""){
		require_once(INCLUDE_ROOT.'class_rdf_parser.php');
		if ($base == "")
			$base=MODULE_TMP . "module/Configure/install.rdf";
		$statements=0;
		
		$input = fopen($base,"rb");
		$rdf=new Rdf_parser();
		$rdf->rdf_parser_create( NULL );
		$rdf->rdf_set_user_data( $statements );
		$rdf->rdf_set_statement_handler( "install_statement_handler" );
		if(file_exists($base)){ 
			while(!feof($input))
			{ 
				$buf .= fread( $input, 8192 );
				$rdf->rdf_parse( $buf, strlen($buf), feof($input) ); 
			}
		}else{
			$this->set_msg($this->word['conf_not_exist']);
			$this->fail_flag=1;
		} 	
			
		/* close file. */
		fclose( $input );
		$rdf->rdf_parser_free();	 
	} 
	
	/**
	 * Module::set_basic_msg()
	 * @param none
	 * @return none
	 */
	function set_basic_msg(){
		$rs_ins=sprintf("select object from mod where module = '%s' and predicate = 'Name'",$this->mod_name);
		$name=$this->db->runSQL($rs_ins); 
		$msg=sprintf($this->word['module_name_msg'],$name[0]);
		$this->set_msg($msg,false);
		$rs_ins=sprintf("select object from mod where module = '%s' and predicate = 'Version'",$this->mod_name);
		$version=$this->db->runSQL($rs_ins);
		$msg=sprintf($this->word['module_version_msg'],$version[0]);
		$this->set_msg($msg,false);
	}

	/**
	 * Module::compare_ver($var1,$var2)
	 * @param $var1:Comparative value
	 *				$var2:Comparative value
	 * @return 0/1 (success/fail)
	 */
	function compare_ver($var1,$var2){
		$ret=0;
		preg_match('/([0-9]+)\.([0-9]+)\.([0-9]+)/',$var1,$matches);
		preg_match('/([0-9]+)\.([0-9]+)\.([0-9]+)/',$var2,$matches1);
										
		if( ($matches[1]*1000000+$matches[2]*1000+$matches[3] < $matches1[1]*1000000+$matches1[2]*1000+$matches1[3]) ) {
			$this->fail_flag=1;
			$ret=1;
		}
		return $ret;
	}



  function check_key_type(){
		$pattern='^[0-9a-zA-Z_]*$';		
		if (!ereg($pattern,$this->mod_name)){
			$this->set_msg($this->word['key_not_match']);
			$this->fail_flag=1;
		}
  }
	/**
	 * Module::check_install_type()
	 * @param none
	 * @return 0/1 (success/fail)
	 */
	function check_install_type(){
		$ret=0;
		if (($this->mod_name != '') && (file_exists(MODULE_ROOT .$this->mod_name))){
			$rs_ins=sprintf("select object from mod where module = '%s' and predicate = 'Version'",$this->mod_name);
			$old_version=$this->old_db->runSQL($rs_ins);
			unset($this->old_db);
			$rs_ins=sprintf("select object from mod where module = '%s' and predicate = 'Version'",$this->mod_name);
			$new_version=$this->db->runSQL($rs_ins);
			$ret=$this->compare_ver($new_version[0],$old_version[0]);
			if($ret=="1"){				
				$msg=sprintf($this->word['lower_version'],$new_version[0],$old_version[0]);
				$this->set_msg($msg);
			}else{
				if (file_exists(MODULE_TMP."module/Shell/upgrade.sh")){
					$this->upgrade_flag=1;
					$this->set_msg($this->word['upgrade_start']);
				}else{
					$this->set_msg($this->word['install_start']);
				}
			}
		}else{
			$this->set_msg($this->word['install_start']);
		}
		
		return $ret;
	}

	/**
	 * Module::check_mac()
	 * @param none
	 * @return none
	 */
	function check_mac(){
		$ret=0;
		$rs_ins=sprintf("select object from mod where module = '%s' and predicate = 'MacStart'",$this->mod_name);
		$mac_start=$this->db->runSQL($rs_ins);
		$rs_ins=sprintf("select object from mod where module = '%s' and predicate = 'MacEnd'",$this->mod_name);
		$mac_end=$this->db->runSQL($rs_ins);
		if ( $mac_start[0] != "" ){
			$wan_mac=trim(shell_exec("ifconfig eth0|grep HWaddr|awk '{print $5}'"));
			if( $wan_mac < $mac_start[0]){
				$ret=1;
			}
		}
		if ( $mac_end[0] != ""){
			$wan_mac=trim(shell_exec("ifconfig eth0|grep HWaddr|awk '{print $5}'"));
			if( $wan_mac > $mac_end[0]){
				 $ret=1;
			}			
		}
		if ($ret==1){
			if ($mac_start[0] == "") 
				$mac_start[0]="*";
			if($mac_end[0] == "")
				$mac_end[0]="*";
		
			$this->set_msg($this->word['out_of_mac']);
			$this->fail_flag=1;
		}
	}

	/**
	 * Module::check_nas_type($tag)
	 * @param tag name
	 * @return 0/1 (success/fail)
	 */
	function check_nas_type($tag){
		$ret=1;
		$rs_ins=sprintf("select gid from mod where module = '%s' and predicate = '%s'",$this->mod_name,$tag);
		$has_tag=$this->db->runSQL($rs_ins);
		if ($has_tag[0] == ""){
			$ret=0;
		}else{
			if ( $tag=="NasType" ){
				$tag_type=$this->nas_type;
				$msg=$this->word['install_fail_nomatch'];
			}else{
				$tag_type=$this->nas_fw_type;
				$msg=sprintf($this->word['fw_model_fail_nomatch'],$this->nas_fw_type);
			}
      $rs_ins=sprintf("select gid from mod where module = '%s' and predicate = '%s' and upper(object) = '%s'",$this->mod_name,$tag,$tag_type);
			$this->gid=$this->db->runSQL($rs_ins);
			if ( $this->gid[0] == "" ){
			 	$this->set_msg($msg);
				$this->fail_flag=1;
				$ret=0;
			}
		}
		return $ret;
	}

	/**
	 * Module::check_nas_version()
	 * @param tag name
	 * @return none
	 */
	function check_nas_version(){
		$ret=0;
		$rs_ins=sprintf("select object from mod where module = '%s' and gid = '%s' and predicate = 'NasVersion'",$this->mod_name,$this->gid[0]);		
		$inas_version=$this->db->runSQLAry($rs_ins);		
		preg_match('/OS(\d+)\.build_(\d+)/',$this->nas_version,$matches);
		preg_match('/OS(\d+)\.build_(\d+)/',$inas_version[0]['object'],$matches1);
		if (($matches[1]*1000+$matches[2] < $matches1[1]*1000+$matches1[2]) ) {
			$this->fail_flag=1;
			$ret=1;
		}

		if ($ret=="1"){
			$msg=sprintf($this->word['version_nomatch'],$inas_version[0]['object']);
			$this->set_msg($msg);
		}
	}

	/**
	 * Module::check_nas()
	 * @param none
	 * @return none
	 */
	function check_nas(){
		$rs_ins=sprintf("select gid from mod where module = '%s' and predicate = 'NasProtol'",$this->mod_name);
		$nasprotol_tag=$this->db->runSQLAry($rs_ins);
		if ( count($nasprotol_tag) != 0 ){
			$ret=$this->check_nas_type("NasProtol");
			if ( $ret == "1"){
				$this->check_nas_version();
			}			
		}else{
			if (NAS_DB_KEY==2){
				$ret=$this->check_nas_type("NasType");
				if ( $ret == "1"){
					$this->check_nas_version();
				}
			}			
		}		
	}

	/**
	 * Module::check_depend_module()
	 * @param none
	 * @return none
	 */
	function check_depend_module(){
		$rs_ins=sprintf("select gid,object from mod where module = '%s' and predicate = 'DependName'",$this->mod_name);		
		$msg="";
		$depend_ary=$this->db->runSQLAry($rs_ins);
		$depend_count= count($depend_ary);
		if( $depend_count != 0){
			for($i=0;$i < $depend_count;$i++){
				#$rs_ins="select module,gid from mod where module = '".$depend_ary[$i]['object']."'";
				$rs_ins=sprintf("select module,gid from mod where module = '%s'",$depend_ary[$i]['object']);
				$in_mod=$this->db->runSQLAry($rs_ins);
	 			$rs_ins=sprintf("select object from mod where module = '%s' and gid = '%s' and predicate = 'DependVer'",$this->mod_name,$depend_ary[$i]['gid']);
	 			$need_mod_ver=$this->db->runSQLAry($rs_ins);
	 			$rs_ins=sprintf("select object from mod where module = '%s' and gid = '%s' and predicate = 'DependUrl'",$this->mod_name,$depend_ary[$i]['gid']);
			 	$url=$this->db->runSQLAry($rs_ins);
			 	$url_msg="";
				if($url[0]['object']!=""){
					$url_msg="(".$url[0]['object'].")";
				}

				if (count($in_mod) != 0){
					$rs_ins=sprintf("select object from mod where module = '%s' and gid = '%s' and predicate = 'Version'",$in_mod[0]['module'],$in_mod[0]['gid']);					
					$in_mod_ver=$this->db->runSQLAry($rs_ins);
					$ret=$this->compare_ver(trim($in_mod_ver[0]['object']),trim($need_mod_ver[0]['object']));

					if ($ret==1){ 				 
						$msg=sprintf($this->word['depend_version_nomatch'],$depend_ary[$i]['object'],$need_mod_ver[0]['object'],$url_msg);
	 					$this->set_msg($msg);
						$this->fail_flag=1;
					}
				}else{
					$this->fail_flag=1;
					$msg=sprintf($this->word['no_depend_mod'],$depend_ary[$i]['object'],$need_mod_ver[0]['object'],$url_msg);
	 				$this->set_msg($msg);
				}
			}
		}
		return $msg;
	}

	/**
	 * Module::compare_conf()
	 * @param none
	 * @return 0/1(ok/fail)
	 */
	function compare_conf(){
		$this->check_key_type();
		$this->check_mac();
		$this->check_nas();
		$this->check_depend_module();
		return $this->fail_flag;
	}

	/**
	 * Module::execute_install()
	 * @param none
	 * @return none
	 */	
	function execute_install(){
		if($this->upgrade_flag == 1){
	 		shell_exec($this->shellcmd." 'update' '".$this->mod_name."' > /dev/null 2>&1 &");
		}else{
			shell_exec($this->shellcmd." 'install' '".$this->mod_name."' > /dev/null 2>&1 &");	
		}
	}

	/**
	 * Module::restore()
	 * @param none
	 * @return none
	 */
	function restore(){
		if($this->upgrade_flag == 1){
			$this->set_msg($this->word['upgrade_fail']);
		}else{
			$this->set_msg($this->word['install_fail']);
		}
		shell_exec($this->shellcmd." 'restore' '".$this->mod_name."' > /dev/null 2>&1 &");
	}

	/**
	 * Module::execute_uninstall($undata)
	 * @param $undata : want uninstall module index
	 * @return none
	 */
	function execute_uninstall($undata){
		$tmp_undata_file="/tmp/module_item";
		shell_exec("echo '".$undata."' > ".$this->tmp_item_file);
		shell_exec($this->shellcmd." 'uninstall' > /dev/null 2>&1 &");
	}
	
	/**
	 * Module::execute_enable($undata)
	 * @param $undata : want uninstall module index
	 * @return none
	 */
	function execute_enable($undata){
		shell_exec("echo '".$undata."' > ".$this->tmp_item_file);
		shell_exec($this->shellcmd." 'enable' > /dev/null 2>&1 &");
	}

	function del_lock(){
		unlink($this->lock_flag);
	}
	
	// the function is for UI monitor
	function check_status($post, $get) {
		$status_type = ($post["status_type"]!="")?trim($post["status_type"]):trim($get["status_type"]);
		$check_lock = ($post["check_lock"]!="")?trim($post["check_lock"]):trim($get["check_lock"]);
		$mod_lock_flag = "";
		$mod_status = "";
	
		$mod_lock_flag = file_get_contents($this->lock_flag);
		$mod_lock_flag = str_replace("\n","",$mod_lock_flag);
		
		if ($mod_lock_flag == "2") { // If mod_lock_flag is 2, that means that file is uploading, mod_status is empty.
			$mod_status = "";
		} else { // If mod_lock_flag is not 2, check_lock rule is for UI monitor
			if ($check_lock == "yes") {
				// check if module has been locked by MODULE_RC_PROC
				// if no lock, remove module.lock and tmp_module_log.txt files
				$result = shell_exec("/bin/ps www | grep \"".RC_MODULE_PATH."\" |grep -v grep");
				if ($result == "") {
					$result = shell_exec("/bin/ps www | grep \"".RC_AUTOMODULE_PATH."\" |grep -v grep");
					if ($result == "") {
						shell_exec("rm -rf \"".$this->lock_flag."\"");
						shell_exec("rm -rf \"".$this->tmp_log_path."\"");
					}
				}
			}
			switch ($status_type) {
			case "0":	// install/uninstall
				$mod_status = shell_exec("cat ".$this->tmp_log_path);
				break;
			case "1":	// enable/disable
				$mod_status = shell_exec("cat ".$this->tmp_error_msg);
				break;
			case "2": // Last status
				$mod_name = ($post["module_name"]!="")?trim($post["module_name"]):trim($get["module_name"]);
				$mod_status = shell_exec("cat /raid/data/module/".$mod_name."/log.txt");
				$mod_lock_flag = "";
				break;
			default:
				$mod_lock_flag = "";
				$mod_status = "";
			}
		}
		
		return array(
			'mod_status'=>$mod_status,
			'mod_lock_flag'=>$mod_lock_flag
		);
	}
	
	function get_lock_type () { // 0: install/uninstall, 1: enable/disable
		exec("cat ".$this->lock_flag, $out, $ret);
		if ($ret == 1) {
			return "";
		}
		return $out[0];
	}
}
?>

