<?
class dbtool{
  var $db;
  var $database;
	
  function connect(){
    $this->db=sqlite_open('/etc/cfg/conf.db');
    //sqlite_exec($this->db,'create table conf(k varchar,v varchar);');
  }
      
  function db_getvar($varname,$default_value) {
    $strSQL="select v from conf where k='" . $varname . "'";
    $rs = sqlite_query($this->db,$strSQL);
    $rows = sqlite_num_rows($rs);
    $getval = trim(sqlite_fetch_single($rs));
    if ($rows<=0) {
      $strSQL="insert into conf (v,k) values ('" . $default_value . "','" . $varname . "')";
      //echo "strSQL=$strSQL <br>";
      $rs = sqlite_query($this->db,$strSQL);
      $getval=$default_value;
    }
    if ($getval=="") $getval=$default_value;
    return $getval;
  }

  function db_setvar($varname,$value) {
    $strSQL="select v from conf where k='" . $varname . "'";
    $rs = sqlite_query($this->db,$strSQL);
    $rows = sqlite_num_rows($rs);
    if ($rows<=0) {
      $strSQL="insert into conf (v,k) values ('" . $value . "','" . $varname . "')";
      $rs = sqlite_query($this->db,$strSQL);
    }else{
      $strSQL="update conf set v='" . $value . "' where k='" . $varname . "'";
      $rs = sqlite_query($this->db,$strSQL);
    }
  }

  function db_close() {
    sqlite_close($this->db);
  }
}

class db_tool2{
  var $db;
	
  function db_connect($database){
    $this->db=sqlite_open($database);
    $this->database=$database;
    //sqlite_exec($this->db,'create table conf(k varchar,v varchar);');
  }
 
  function db_get_count($table_name) {
    $strSQL="select count(*) from $table_name";
    $rs = sqlite_query($this->db,$strSQL);
    $rows = sqlite_num_rows($rs);
    $count = sqlite_fetch_single($rs);
    if ($rows<=0) {
      return 0;
    }
    return $count;
  }
  
  function db_getall($table_name) {
    $strSQL="select * from $table_name";
    //echo $strSQL."<br>";
    $rs = sqlite_query($this->db,$strSQL);
    $rows = sqlite_num_rows($rs);
    $getall = sqlite_fetch_all($rs);
    //echo "<pre>";
    //print_r($getall);
    //exit;
    if ($rows<=0) {
      return 0;
    }
    return $getall;
  }
 
  function db_get_folder_info($table_name,$columns,$where) {
    $strSQL="select $columns from $table_name $where";
    //echo $strSQL."<br>";
    //exit;
    $rs = sqlite_query($this->db,$strSQL);
    $rows = sqlite_num_rows($rs);
    $get_info = sqlite_fetch_all($rs);
    if ($rows<=0) {
      return 0;
    }
    return $get_info;
  }
  
  function db_insert($table,$columns,$values){
    $strSQL="insert into ${table}(${columns}) values(${values})";
    //echo $strSQL;
    //exit;
    $rs = sqlite_query($this->db,$strSQL);
    if($rs==""){
      return 0;//failed
    }
    return 1;//success
  }
  
  function db_update($table,$set,$where){
    $strSQL="update $table set $set $where";
    //echo "${strSQL}<br>";
    $rs = sqlite_query($this->db,$strSQL);
    if($rs==""){
      return 0;
    }
    return 1;
  }
  
  function db_delete($table_name,$where){
    $strSQL="select * from $table_name $where";
    //echo $strSQL;
    $rs = sqlite_query($this->db,$strSQL);
    if($rs==""){
      return 0;
    }
    $strSQL="delete from $table_name $where";
    //echo $strSQL;
    $rs = sqlite_query($this->db,$strSQL);
    if ($rs==""){
      return 0;//failed
    }
    return 1;//success
  }
  
  function db_get_single_value($table,$select_column,$where){
    $strSQL="select $select_column from $table $where";
    $rs = sqlite_query($this->db,$strSQL);
    $rows = sqlite_num_rows($rs);
    $get_value = trim(sqlite_fetch_single($rs));
    //echo $strSQL."<br>value=$get_value<br>";
    return $get_value;
  }
  
  function db_runSQL($cmd){
    $strSQL=$cmd;
    $rs = sqlite_query($this->db,$strSQL);
    if (is_bool($rs)){
      return $rs;
    }else{
      return sqlite_fetch_single($rs);
    }
  }
  
  function db_alter($table,$column,$default){
    $sqlite="/usr/bin/sqlite";
    $strExec="$sqlite $this->database \".schema $table\"";
    $schema=explode(" ",shell_exec($strExec));
    $old_schema=trim($schema[2]);
    $len=strlen($old_schema);
    $schema_tmp="";
    $lock="1";
    for($i=0;$i<$len;$i++){
      if($old_schema[$i]==chr(41)){
        break;
      }
      if($lock=="0"){
        $schema_tmp.=$old_schema[$i];
      }
      if($old_schema[$i]==chr(40)){
        $lock="0";
      }
    }
    //echo "tmp = $schema_tmp<br>";
    $test_column="0";
    $schema_array=explode(",",$schema_tmp);
    foreach($schema_array as $v){
      if($v!=""){
        if($v==$column){
          $test_column="1";
          break;
        }
      }
    }
    //echo "test_column = $test_column";
    if($test_column=="0"){
      $new_schema=$schema_tmp.",${column}";
      //echo "new = $new_schema<br>";
      $strExec="$sqlite $this->database \".dump $table\"";
      $dump=shell_exec($strExec);
      $dump_array=explode("\n",$dump);
      for($i=0;$i<count($dump_array);$i++){
        if(preg_match("/create/",$dump_array[$i])){
          $dump_array[$i]="create table ${table}(${new_schema});";
        }
        if(preg_match("/INSERT INTO/",$dump_array[$i])){
          $query_array=explode(" ",$dump_array[$i]);
          //echo "<pre>";
          //print_r($query_array);
          $query_lock="1";
          $query_tmp="";
          for($j=0;$j<strlen($query_array[3]);$j++){
            if($query_array[3][$j]==chr(41)){
              break;
            }
            if($query_lock=="0"){
              $query_tmp.=$query_array[3][$j];
            }
            if($query_array[3][$j]==chr(40)){
              $query_lock="0";
            }
          }
          //echo "query = $query_tmp<br>";
          $new_query="VALUES(${query_tmp},'$default');";
          $dump_array[$i]=str_replace($query_array[3],$new_query,$dump_array[$i]);
          $dump_array[$i]=str_replace($table,$table."(${new_schema})",$dump_array[$i]);
        }
      }
      $new_dump=implode("\n",$dump_array);
      //echo "$new_dump";
      $strExec="echo \"${new_dump}\" > /tmp/tmp.db";
      shell_exec($strExec);
      $strExec="$sqlite $this->database \"drop table $table\"";
      shell_exec($strExec);
      $strExec="$sqlite $this->database \".read /tmp/tmp.db\"";
      shell_exec($strExec);
    }
  }
    function db_alter2($table,$column,$default){
  	//echo "Use Alter function<br>";
  	$sqlite="/usr/bin/sqlite";
	$strExec="$sqlite $this->database \".schema $table\"";
	$schema=explode(" ",shell_exec($strExec));
	$column_exist="0";
	//echo "<pre>";
	//print_r($schema);
	if(trim($schema[2])==$table){
		foreach($schema as $key=>$v){
			if($v!=""){
				if($key>2){
					$old_schema.=trim($v)." ";
				}
			}
		}
		$old_schema=substr($old_schema,1,strlen($old_schema)-4);
		//echo $old_schema."<br>";
		$schema_array=explode(",",$old_schema);
		foreach($schema_array as $item){
			if($item!=""){
				//echo $item."==".$column."<br>";
				if(preg_match("/${column}/",$item)){
					$column_exist="1";
					break;
				}
			}
		}
		//echo $column_exist."<br>";
		if($column_exist=="0"){
			//echo "create new column<br>";
			$new_schema=$old_schema.",${column} DEFAULT '${default}'";
			//echo $new_schema."<br>";
			$strExec="$sqlite $this->database \".dump $table\"";
			$dump=shell_exec($strExec);
			$dump_array=explode("\n",$dump);
			//print_r($dump_array);
			for($i=0;$i<count($dump_array);$i++){
				if(preg_match("/create/",$dump_array[$i])){
					$dump_array[$i]="create table ${table} (${new_schema});";
				}
				if(preg_match("/INSERT INTO/",$dump_array[$i])){
					$old_insert=substr(trim($dump_array[$i]),0,strlen(trim($dump_array[$i]))-2);
					$dump_array[$i]=${old_insert}.",'".$default."');";
				}
			}
			//print_r($dump_array);
			$new_db=implode("\n",$dump_array);
			//print_r($new_db);
			$strExec="echo \"${new_db}\" > /tmp/tmp.db";
			shell_exec($strExec);
			$strExec="$sqlite $this->database \"drop table $table\"";
			shell_exec($strExec);
			$strExec="$sqlite $this->database \".read /tmp/tmp.db\"";
			shell_exec($strExec);
		}
	}
  }
  function db_close() {
    sqlite_close($this->db);
  }
}
?>
