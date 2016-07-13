<?php  
require_once("session.php");
Class LoginProcess
{ 
	
	function login($loginid,$pass){
		global $session,$form;
		$retval = $session->login($loginid,$pass);

		if (!$retval) {							// Login failed 
			$_SESSION['value_array'] = $_REQUEST;
			$_SESSION['error_array'] =  $form->getErrorArray(); 
		} 
	}
}; 
$logproc = new LoginProcess;  


		
// =============================== BEGIN HERE ==================================
if (!$session->logged_in && isset($_REQUEST['username'])) {
	$logproc->login($_REQUEST['username'],$_REQUEST['password']); 
} 
 

if($session->checkLogin() == true) {
	 $ary = array(
			'success'=>true,
			'data'=>array(
					'loginid'=>$session->loginid,
					'lang'=>$session->lang
				)
			);
}else{
	 $ary = array(
			'success'=>false 
			); 
}					 
echo json_encode($ary); 
?>