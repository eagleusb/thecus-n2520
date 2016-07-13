<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');

$words = $session->PageCode("printer");

class PRINTER_QUEUE{
  function getPrinterInfo(){
    global $words;

    // Joey 2006/03/07 Printer status
    $lp_path="/sys/bus/usb/drivers/usblp/";
    $dir=dir($lp_path);
    $dir->rewind();
    $file=$dir->read(); // dir = "."
    $file=$dir->read(); // dir = ".."

    // no printer detected
    $str_status='no_printer';
    $str_manufact='na';
    $str_model='na';

    while ($file=$dir->read()){ // printer online
      if (($file == 'module') || ($file == 'bind') || ($file == 'unbind') || ($file == 'new_id' )){
        continue;
      }
    
      $str_status='online';
      $lpfile=$lp_path . $file;
      
      if (is_link($lpfile)) {
        $lp_real_path='/sys' . substr(readlink($lpfile),11);
      } 
      else {
        $lp_real_path=$lp_path;
      }

      $saved_path=getcwd(); // save current working path
      chdir($lp_real_path);
      chdir("..");
      $lp_real_path=getcwd();
      $manufact_path=$lp_real_path.'/manufacturer';
      $product_path=$lp_real_path.'/product';
      $str_manufact="";
      $str_model="";
    
      if (file_exists($manufact_path)) {
        $file=fopen($manufact_path,"r");
        //using trim() to del the control character.
        $str_manufact=trim(fread($file,64));
        fclose($file);
      }

      if (file_exists($product_path)) {
        $file=fopen($product_path,"r");
        $str_model=trim(fread($file,64));
        fclose($file);
      }
      
      chdir($saved_path); // restore current working path
          
      if (($str_manufact=="") || ($str_model=="")) {
        $str_status='no_printer';
        $str_manufact='na';
        $str_model='na';
        continue;
      }

      break;
    }
  
    $dir->close();

    $status_array['status']=$str_status;
    $status_array['manufact']=$str_manufact;
    $status_array['model']=$str_model;

    return $status_array;
  }

  function getSizeUnit($num){
    $unit_map=array(0=>'Bytes',1=>'KB',2=>'MB',3=>'GB',4=>'TB');
    $unit=0;
  
    while($num>=1024){
      $num=$num/1024;
      $unit++;
    }
  
    return number_format($num, 1, '.', '')." ".$unit_map[$unit];
  }

  function get_Queue_list(){
    $queue_list=explode("\n",shell_exec("/usr/bin/lpq -a "));
    $queue_cnt=0;
    $i=0;
    $flag_first_line=0;
    $queue_list_limit=10;

    foreach($queue_list as $line){
      if($flag_first_line==0){
        $flag_first_line=1;
  
        continue;
      }
                                
      if(trim($line) != ""){
        $queue_entry=explode("\t",$line);
        $queue_array[$i]=array();
        $queue_array[$i]['rank']=trim($queue_entry[0]);
        $queue_array[$i]['owner']=trim($queue_entry[1]);
        $queue_array[$i]['job']=trim($queue_entry[2]);
        $queue_array[$i]['file']=trim($queue_entry[3]);
        $i++;
      }
  
      if($i>=$queue_list_limit){
        break;
      }
    }

    return $queue_array;
  }

  function delete_job($task_id){
    shell_exec("/usr/bin/cancel ".$task_id);
  }

  function get_html(){
    global $words;

    $queue_array=$this->get_Queue_list();
    $queue_cnt=count($queue_array);

    $table_start="";
    $queue_index="";
    $table_end="";
  
    for( $i=0 ; $i < $queue_cnt ; $i++){
      if($i==0){
        $table_start="<div class='block_03'>";
        $table_start.="<table width='640' cellspacing=1>";
        $table_start.="<tr><td colspan=4><div class='step'><div class='step_title'>".
                       $words['printer_queue_list'].
                       "</div></div></td></tr>";

        $table_start.="<tr height='40'>
                         <th width='10%'><center></th>
                         <th width='10%'><center>".$words['rank']."</th>
                         <th width='20%'><center>".$words['owner']."</th>
                         <th width='60%'><center>".$words['file']."</th>
                       </tr>";
      }

      $delete_href="";
      if($queue_array[$i]['rank'] != "active"){
        $delete_href='<a href="javascript:chk_confirm('.$queue_array[$i]['job'].')">
                        <img src="../images/delete.png" alt="'.$words["delete"].'" border=
                      </a>';
      }

      $queue_index.="<tr height='40'>
                       <td><center>".$delete_href."</td>
                       <td><center>".$queue_array[$i]['rank']."</td>
                       <td><center>".$queue_array[$i]['owner']."</td>
                       <td>".$queue_array[$i]['file']."</td>
                     </tr>";

      if($i== ($queue_cnt-1)){
        $table_end="</table></div>";
        break;
      }
    }

    $queue_html=$table_start.$queue_index.$table_end;
    return $queue_html;
  }
}//END of Class: PRINTER_QUEUE

?>
