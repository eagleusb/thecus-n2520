<?php
    // iap 2005.2.3
    /* borrowed from smbutility.class.php */
   /*
    function proc_run1($file,$rawin=''){
        $f=popen($file,'r');
        $lines=array();
        if (is_resource($f)){
            while (!feof($f)){
               $line=fgets($f);
               print "--> $line\n";
               array_push($lines,$line);
            }
            pclose($f);
        }
        return $lines;

       
    }
   */
    function proc_run($file,$rawin=''){
        /* $rawin will be put into STDIN */
        $desc=array(
           0=>array('pipe','r'),
           1=>array('pipe','w'),
           2=>array('pipe','w'));
        $f=proc_open($file,$desc,$pipes);
        $lines=array();
        if (is_resource($f)){
            if ($rawin){
               fwrite($pipes[0],$rawin);
               fflush($pipes[0]);
            }
            fclose($pipes[0]);
            while (!feof($pipes[1])){
               $line=fgets($pipes[1]);
               array_push($lines,$line);
            }
            fclose($pipes[1]);
            fclose($pipes[2]);
            proc_close($f);
        }
        return $lines;
    }
?>
