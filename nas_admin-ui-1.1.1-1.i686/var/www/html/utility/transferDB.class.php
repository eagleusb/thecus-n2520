<?
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
class transDB{
	var $old_db="/etc/www/language/old_language.db";
	var $new_db="/etc/www/language/language.db";
	var $language=array("cz","de","en","es","fr","it","ja","ko","pl","pt","ru","tr","tw","zh");
	//var $language=array("en");

	function trans_once($old_function,$old_value,$new_function,$new_value){
		//echo "${old_function} , ${old_value} , ${new_function} , ${new_value}<br>";
		//echo $this->old_db."<br>";
		foreach($this->language as $lang){
			$old_db=new sqlitedb($this->old_db,$lang);
			$query="select value,msg from ${lang} where function=\"${old_function}\" and value=\"${old_value}\"";
			$rs=$old_db->runSQLAry($query);
			$old_db->db_close();
			//echo "<pre>";
			//print_r($rs);
			foreach($rs as $itemArray){
				$value=$itemArray["value"];
				$msg=$itemArray["msg"];
				//echo "value = ${value} || msg = ${msg}<br>";
				//echo $this->new_db."<br>";
				$new_db=new sqlitedb($this->new_db,$lang);
				$cmd="select * from ${lang} where function=\"${new_function}\" and value=\"${value}\" and msg=\"${msg}\"";
				$row=$new_db->runSQLAry($cmd);
				//$query2=$database->queryExec($cmd);
				//echo "${cmd}<br>";
				//echo "row = $row<br>";
				//echo count($row)."<br>";
				if(count($row)=="0"){
					$cmd="select * from ${lang} where function=\"${new_function}\" and msg=\"${msg}\"";
					$row=$new_db->runSQLAry($cmd);
					//echo count($row);
					$cmd="select * from ${lang} where function=\"global\" and msg=\"${msg}\"";
					$row2=$new_db->runSQLAry($cmd);
					//echo count($row2);
					//$cmd="select * from ${lang} where msg=\"${msg}\";";
					//$row3=$new_db->runSQLAry($cmd);
					//echo count($row3);
					if(count($row)=="0" && count($row2)=="0" && count($row3)=="0"){
						$cmd="insert into ${lang} (function,value,msg) values (\"${new_function}\",\"${new_value}\",\"${msg}\")";
						echo "${cmd}<br>";
						$new_db->runSQLAry($cmd);
						//echo $query3."<br>";
					}
				}
				//echo "#################################################################<br>";
				$new_db->db_close();
			}
		}
	}

	function trans_bat($old_function,$new_function){
		//echo "${old_function} , ${new_function}<br>";
		//echo $this->old_db."<br>";
		foreach($this->language as $lang){
			//$handle=sqlite_open($this->old_db);
			$old_db=new sqlitedb($this->old_db,$lang);
			$query="select value,msg from ${lang} where function=\"${old_function}\"";
			$rs=$old_db->runSQLAry($query);
			$old_db->db_close();
			//echo "<pre>";
			//print_r($rs);
			foreach($rs as $itemArray){
				$value=$itemArray["value"];
				$msg=$itemArray["msg"];
				//echo "value = ${value} || msg = ${msg}<br>";
				//echo $this->new_db."<br>";
				$new_db=new sqlitedb($this->new_db,$lang);
				$cmd="select * from ${lang} where function=\"${new_function}\" and value=\"${value}\" and msg=\"${msg}\"";
				$rs=$new_db->runSQLAry($cmd);
				//echo "${cmd}<br>";
				//echo "row = $row<br>";
				//echo count($row)."<br>";
				if(count($rs)=="0"){
					$cmd="select * from ${lang} where function=\"global\" and msg=\"${msg}\"";
					$row=$new_db->runSQLAry($cmd);
					//$cmd="select * from ${lang} where msg=\"${msg}\";";
					//$row2=$new_db->runSQLAry($cmd);
					//if(count($row)=="0" && count($row2)=="0"){
					if(count($row)=="0"){
						$cmd="insert into ${lang} (function,value,msg) values (\"${new_function}\",\"${value}\",\"${msg}\")";
						echo "${cmd}<br>";
						//$query3=$database->queryExec($cmd);
						$new_db->runSQLAry($cmd);
						//echo $query3."<br>";
					}
				}
				//echo "#################################################################<br>";
				$new_db->db_close();
			}
		}
	}
}

?>
