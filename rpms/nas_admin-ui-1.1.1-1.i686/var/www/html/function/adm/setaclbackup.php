<?
$words = $session->PageCode("aclbackup");
$backupcmd=IMG_BIN."/acl_backup.sh";
$action=$_POST["_aclradio"]?"backup":"restore";
$mdnum=$_POST["_raid_selected"];
$do_act=$_REQUEST["do_act"];
$restorelist=json_decode(stripslashes($_POST["restore_data"]),TRUE); 
$rec=$_POST["_recursive"]?"1":"0";

    /**
     *  Get this raid Status
     *
     * @param $backupcmd : aclbackup command
     * @param $action : action
     * @param $mdnum : md num
     *
     * @return: return result
     *        
     */
function get_raid_status($backupcmd,$action,$mdnum){
    $cmd=sprintf("%s 'get_raid_status' '%s' '%s'",$backupcmd,$action,$mdnum);
    $raid_result=trim(shell_exec($cmd));
    list($result, $action, $icon, $word_key, $raid_name, $para1) = explode("|", $raid_result);
    return array("result" => $result,
                 "action" => $action,
                 "icon"   => $icon,
                 "word_key" => $word_key,
                 "raid_name" => $raid_name,
                 "para1" => $para1
                 );
}

// backup action
if ($action == 'backup'){
    $result=get_raid_status($backupcmd,$action,$mdnum);
    $msg=sprintf($words[$result['word_key']],$result['raid_name'],$result['para1']);
    die(json_encode(array('result'=>$result['result'],'icon'=>strtoupper($result['icon']),'msg'=>$msg,'mdnum'=>$mdnum)));
//restore action
}elseif($action == 'restore'){
    $result=get_raid_status($backupcmd,$action,$mdnum);

    //upload restore bin file
    if ($do_act == "upload"){
        if ($result['result'] == "0"){
            $cmd=sprintf("%s 'get_upload_path'",$backupcmd);
            $upload_path=trim(shell_exec($cmd));
            unlink($upload_path);
            move_uploaded_file($_FILES['config-path']['tmp_name'],$upload_path);
            $cmd=sprintf("%s 'get_match_folder' '%s' '%s'",$backupcmd,$mdnum,$rec);
            $match_result=shell_exec($cmd);
            $result_ary=explode("\n",$match_result);            

            if ("$result_ary[0]" == "0"){   //$result_ary[0] => success or fail (0/1)
                for($i=2;$i<count($result_ary);$i++){
                    if ($result_ary[$i] != ""){
                        $folder_list[]=array($i-2,rawurlencode($result_ary[$i]));
                    }
                }

                die(json_encode(array(
                    'success' => true,
                    'msg' => array(
                                   'uuid'=> $result_ary[1],
                                   'folder_list'=>$folder_list
                    )
                )));
            }else{
                list($result, $action, $icon, $word_key, $raid_name, $para1) = explode("|", $result_ary[1]);
                $msg=sprintf($words[$word_key],$raid_name,$para1);
                echo '{failure:true, file:'.json_encode($_FILES['config-path']['name']).', icon:'.json_encode(strtoupper($icon)).', msg:'.json_encode($msg).'}';
                exit;
            }
        }else{
            $msg=sprintf($words[$result['word_key']],$result['raid_name'],$result['para1']);
            echo '{failure:true, file:'.json_encode($_FILES['config-path']['name']).', icon:'.json_encode(strtoupper($result['icon'])).', msg:'.json_encode($msg).'}';
            exit;
        }
    //restore raid acl
    }else{
        if ($result['result'] == "0"){
            $cmd=sprintf("%s 'get_restore_file_path'",$backupcmd);
            $restore_file=trim(shell_exec($cmd));
            $fp=fopen($restore_file, "w");
            
            if ($fp != null){
                fwrite($fp, $restorelist);
                $cmd=sprintf("%s 'restore' &",$backupcmd);
                shell_exec($cmd);
                die(json_encode(array('result'=>0)));
            }else{
                $msg=sprintf($words['acl_restore_no_conf'],'','restore');
                die(json_encode(array('result'=>1,'icon'=>'ERROR','msg'=>$msg)));
            }
        }else{
            $msg=sprintf($words[$result['word_key']],$result['raid_name'],$result['para1']);
            die(json_encode(array('result'=>$result[0],'icon'=>strtoupper($result['icon']),'msg'=>$msg,'mdnum'=>$mdnum)));
        }
    }
}
?>
