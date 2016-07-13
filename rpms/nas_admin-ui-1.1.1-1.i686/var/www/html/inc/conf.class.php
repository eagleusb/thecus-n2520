<?php
   class Configure{
       public $db;
       function connect(){
            $this->db=sqlite_open('/etc/cfg/conf.db');
            //sqlite_exec($this->db,'create table conf(k varchar,v varchar);');
       }
       function toArray($entries){
            $data=array();
            foreach($entries as $entry){
                $data[$entry['k']]=$entry['v'];
            }
            return $data;
       }
	   /*return sqlite data assoc array*/
       function getDictionary($prefix){
            return $this->toArray($this->get($prefix));
       }
       function get($prefix){
            /* key starts with $prefix */
            if (!$this->db) $this->connect();
            $prefix=sqlite_escape_string($prefix);
            $res=sqlite_query("select * from conf where k like '$prefix%'",$this->db);
            if (!$res) return flase;
            return sqlite_fetch_all($res,SQLITE_ASSOC);
       }
       function set($k,$v){
            if (!$this->db) $this->connect();
            $k=sqlite_escape_string($k);
            $v=sqlite_escape_string($v);
            $res=sqlite_query("select * from conf where k='$k'",$this->db);
            if (!$res) return false; // failed to request database
            if (sqlite_has_more($res)){
                $res=sqlite_exec("update conf set v='$v' where k='$k'",$this->db);
                return 'update';
            }
            else{
                $res=sqlite_exec("insert into conf values('$k','$v')",$this->db);
                return 'insert';
            }
            return $res;
       }
       function del($k){
            if (!$this->db) $this->connect();
            $k=sqlite_escape_string($k);
            $res=sqlite_exec("delete from conf where k='$k'",$this->db);
            return "($res)";
       }
   }
?>
