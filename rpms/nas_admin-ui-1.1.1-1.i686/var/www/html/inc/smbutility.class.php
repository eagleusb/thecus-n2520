<?php
    class SambaUtility{
        var $cmd;
        var $authoption;
        function SambaUtility($cmd,$authoption){
            $this->cmd=$cmd;
            $this->authoption=$authoption;
        }
        function execute($option){
            $file=$this->cmd." $option ".$this->authoption;
            return $this->run($file);
        }
        function run($file,$rawin=''){
            require_once('../../inc/proc.class.php');
            return proc_run($file,$rawin);

            /* $rawin will be put into STDIN */ 
            $desc=array(
                 0=>array('pipe','w'),
                 1=>array('pipe','r'),
                 2=>array('pipe','r'));
            $f=proc_open($file,$desc,$pipes);
            $lines=array();
            if (is_resource($f)){
                if ($rawin){
                   fwrite($pipes[0],$rawin);
                }
                fclose($pipes[0]);
                while (!feof($pipes[1])){
                    $line=fgets($pipes[1]);
                    print "->$line\n";
                    array_push($lines,$line);
                }
                fclose($pipes[1]);
                $return_value=proc_close($f);
                if ($return_value){
                    print "Error code returned $return_value"; 
                };
                //print "r->($return_value)";
            }
            else{
                print "Error get local user";
            }
            return $lines;
        }
    }
?>
