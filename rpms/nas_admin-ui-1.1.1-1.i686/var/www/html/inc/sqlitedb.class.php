<?php
//require_once('localconfig.php');
error_reporting(0);
 
if (!function_exists("sqlite_escape_string")){
  function sqlite_escape_string($sql_string){
    $db=new PDO("sqlite:/dev/null");
    $result=$db->quote($sql_string);
    unset($db);
    return substr($result, 1, -1);
  }
}
  
/*
example:

Get value from conf.db by key 'admin_lang', if vlaue is empty, set value = 'en':
  $db = new sqlitedb();
  $this->lang = $db->getvar('admin_lang','en');
  unset($db);
                          
Set conf.db value = 'en' where key = 'admin_lang':
        $db=new sqlitedb();
        $db->setvar('admin_lang','en');
        unset($db);

Get 'index' page 'en' word array: 
  $ldb=new sqlitedb($db,$lang);
  $word_array=$ldb->runSQLAry("select value,msg from en where function='index'");
  unset($ldb);
*/
 
class sqlitedb{
  const DB='/etc/cfg/conf.db'; 
  const TABLE="conf";
  var $db,$_db,$table,$query;
  var $sqlite_version=SQLITE_VERSION;

  function __construct($db_name=self::DB,$table_name=self::TABLE,$sqlite_ver=SQLITE_VERSION){
	if(!file_exists($db_name)){
		$name = basename($db_name);
		$dir = "/tmp/db/";
		if(!is_dir($dir)){
			mkdir($dir);
		}
		$db_name=$dir.$name;
	}
                $this->sqlite_version=$sqlite_ver;
    $this->db_open($db_name);
    return $this->table_selected($table_name);
  }

  function __destruct()
  {
     if ($this->db) $this->db_close();
  }

  function db_open($db_name=self::DB){
    if ($this->db){
      if ($this->_db == $db_name){
        return 1;
      }else{
        $this->db_close();
      }
    }
    $this->_db=$db_name;
    if ($this->sqlite_version==2){
      $this->db = new SQLiteDatabase($this->_db);
   }else{
          $this->db=new PDO('sqlite:'.$this->_db);
     }
    return 1;
  }

  function table_selected($table_name=self::TABLE){
    if ($this->table_exists($table_name)){
      $this->table=$table_name;
      return 1;
    }else{
      //echo("No table '$table_name' can be selected from db '$this->_db' !!<BR>");
      return 0;
    }
  }  

  function table_exists($table_name) {
    $table_name=sqlite_escape_string($table_name);
    $rs=false;
    /* counts the tables that match the name given  */
    $strSQL="SELECT * FROM sqlite_master WHERE type='table' AND name='$table_name'";
          $query = $this->db->query($strSQL);
    /* returns true or false  */
          if ($query)
            $rs=true;
          return $rs;
  }
      
  function getvar($varname,$default_value="") {
    $rs = false;
    if (!$this->db) $this->db_open();
    $varname=sqlite_escape_string($varname);
    $strSQL="select v from ".$this->table." where k='" . $varname ."'";
    $rs = $this->db->query($strSQL)->fetchall();
    $rows = count($rs);
    $getval = trim($rs[0][v]);
    if ($rows<=0) {
      $strSQL="insert into ".$this->table." (v,k) values ('" . $default_value . "','" . $varname . "')";
      if ($this->sqlite_version==2)
        $this->db->queryExec($strSQL);
      else
        $this->db->exec($strSQL);
      //$this->db->query($strSQL)->fetch();
      $getval=$default_value;
    }
    if ($getval=="") $getval=$default_value;
    return $getval;
  }

	function setvar($varname,$value) {
		$rs = false;
		if (!$this->db) $this->db_open();
		$varname=sqlite_escape_string($varname);
		$value=sqlite_escape_string($value);
		$strSQL="select v from ".$this->table." where k='" . $varname . "'";
		$rs = $this->db->query($strSQL)->fetchall();
		if (count($rs) <= 0) {
			$this->db_insert($this->table, "k,v", "'$varname','$value'");
		} else {
			$this->db_update($this->table, "v='$value'", "where k='$varname'"); 
		}
		
		return $rs;
	}


  
  function db_runSQL($cmd){
    $strSQL=$cmd; 
    $rs = $this->db->query($strSQL)->fetchall();
    if (is_bool($rs)){
      return $rs;
    }else{
      return sqlite_fetch_single($rs);
    }
  } 
 
  function db_get_single_value($table_name,$select_column,$where){
     if (!$this->db) $this->db_open();
     $strSQL="select $select_column from ".$table_name." $where"; 
     $this->query = $this->db->query($strSQL); 
     if($this->query){
        $row=$this->query->fetch();
        return $row[0];
     }
     return "";
  } 
  
  function db_set($columns,$value) {  
    if (!$this->db) $this->db_open();  
    $strSQL="insert into ".$this->table." ($columns) values ($value)"; 
      if ($this->sqlite_version==2)
        $this->db->queryExec($strSQL);
      else
        $this->db->exec($strSQL); 
  } 
  function db_getall($table_name) { 
    if (!$this->db) $this->db_open();
    if(empty($table_name))$table_name=$this->table;
    $strSQL="select * from ".$table_name;  
    $rs = $this->db->query($strSQL)->fetchall();
    $rows = count($rs); 
    if ($rows<=0) {
      return 0;
    }
    return $rs;  
  } 
  function db_update($table_name,$set,$where){  
    if (!$this->db) $this->db_open(); 
    $strSQL="update ".$table_name." set $set $where";  
    if ($this->sqlite_version==2)
        $rs =$this->db->queryExec($strSQL);
    else
        $rs =$this->db->exec($strSQL); 
    if($rs==""){
      return 0;
    }
    return 1;
  }   
  function db_insert($table,$columns,$values){
    if (!$this->db) $this->db_open(); 
    $strSQL="insert into ${table}(${columns}) values(${values})"; 
    if ($this->sqlite_version==2)
        $rs =$this->db->queryExec($strSQL);
    else
        $rs =$this->db->exec($strSQL);  
    if($rs==""){
      return 0;//failed
    }
    return 1;//success
  }
  
//enian 2009 3 31
  function db_delete($table_name,$where){
    if (!$this->db) $this->db_open();
    $strSQL="select * from $table_name $where";
    //echo $strSQL;
    $rs = $this->db->query($strSQL);
    if($rs==""){
      return 0;
    }
    $strSQL="delete from $table_name $where";
    //echo $strSQL;
    if ($this->sqlite_version==2)
      $rs=$this->db->queryExec($strSQL);
    else
      $rs=$this->db->exec($strSQL);
    
    if ($rs==""){
      return 0;//failed
    }
    return 1;//success
  }

  function db_get_count($table_name) {
    $strSQL="select count(*) from $table_name";
    $rs = $this->db->query($strSQL);
    $rows = count($rs);
    $count = $rs->fetch();
    if ($rows<=0) {
      $count[0]=0;
      return $count[0];
    }
    return $count;
  }
  function db_get_folder_info($table_name,$columns,$where) {
    $strSQL="select $columns from $table_name $where";
    //echo $strSQL."<br>";
    //exit;
    $rs = $this->db->query($strSQL);
    $rows = count($rs);
    $get_info = $rs->fetchall();
    if ($rows<=0) {
      return 0;
    }
    return $get_info;
  }
  
//end enian
        function runSQL($strSQL) {
                if (!$this->db) $this->db_open();
                $this->query = $this->db->query($strSQL);
		if($this->query)
                	return $this->query->fetch();
		else
			return "";
        }

        function runPrepare($strSQL) {
                if (!$this->db) $this->db_open();
                return $this->query = $this->db->query($strSQL);
        }

        function runNext() {
          $rs = false;
          if ($this->query){
            $rs = $this->query->fetch();
          }
                return $rs;
        }

        function runSQLAry($strSQL) {
                if (!$this->db) $this->db_open();
                if($result = $this->db->query($strSQL)){
                	return $result->fetchall();
                }
                return false;
        }
  
        function exec($strSQL) {

    if (!$this->db) $this->db_open();
    if ($this->sqlite_version==2)
      return $this->db->queryExec($strSQL);
    else
      return $this->db->exec($strSQL);
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
		$strExec="$sqlite $this->_db \".schema $table\"";
		$schema=explode(" ",shell_exec($strExec));
		$column_exist="0";
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
				$strExec="$sqlite $this->_db \".dump $table\"";
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
				$strExec="$sqlite $this->_db \"drop table $table\"";
				shell_exec($strExec);
				$strExec="$sqlite $this->_db \".read /tmp/tmp.db\"";
				shell_exec($strExec);
			}
		}
	}



  function db_close() {
    unset($this->db);
  }
}
 
?>
