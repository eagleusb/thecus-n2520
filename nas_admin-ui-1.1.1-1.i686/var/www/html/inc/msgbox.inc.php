<?
class msgBox{
	var $msgButtons;
	var $msgPrompt;	
	var $msgTitle;
	var $msgIcon;
	var $msgLinks;
	var $s_st;
	function msgBox($prompt,$buttons,$title){
		switch($buttons){
			case "Fail" :
				$this->msgButtons=array("OK");
				$this->msgIcon="i";
				$this->s_st = "Fail";
				break;
			case "OKOnly" :
				$this->msgButtons=array("OK");
				$this->msgIcon="i";
				//$this->s_st = "Success";
				break;
			case "OKCancel":
				$this->msgButtons=array("OK","Cancel");
				$this->msgIcon="s";
				break;
			case "AbortRetryIgnore":
				$this->msgButtons=array("Abort","Retry","Ignore");
				$this->msgIcon="x";
				break;
			case "YesNoCancel":
				$this->msgButtons=array("Yes","No","Cancel");
				$this->msgIcon="s";
				break;
			case "YesNo":
				$this->msgButtons=array("Yes","No");
				$this->msgIcon="s";
				break;
			case "RetryCancel":
				$this->msgButtons=array("Retry","Cancel");
				$this->msgIcon="r";
				break;
		} // end switch
		
		// set the title
		$this->msgPrompt=$prompt;
		$this->msgTitle=$title;
	}
	//
	function makeLinks($linksArray){
		$this->msgLinks=$linksArray;
	}	

	function showMsg(){ 
		if($_SESSION['module_'.$_GET['Module']]!=''){
			require_once('/var/www/html/inc/modulestyle.class.php');
			$mod = new ModuleStyle($_SESSION['module_'.$_GET['Module']]);
			$mod->getCss(); 
			$mod->getHeader();
		} 

		echo "<meta http-equiv='content-type' content='text/html;charset=utf-8'>";
		//print_r($this->msgButtons);
		require_once("/var/www/html/function/conf/webconfig");
		$model=trim(shell_exec('/bin/cat /proc/thecus_io | awk -F: \'/CPUFLAG/{printf("%s", $2)}\''));
		if($model=="1"){
		  $model_name=$webconfig['product_no'].$webconfig['pro'];
                }else{
	          $model_name=$webconfig['product_no'];
                }
		echo "<script language=\"javascript\">";
		echo "document.title='".$webconfig['manufactur']." ".$model_name."';";
		echo "</script>"; 
		echo "<table width=\"60%\"  border=\"0\" align=\"center\" cellpadding=\"0\" cellspacing=\"0\" class=\"msg\">";
		echo "  <tr align=\"left\" valign=\"top\">";
		echo "	<td class=\"msgTitle\" colspan=\"3\" align=\"left\">".$this->msgTitle."</td>";
		echo "  </tr>";
		echo "  <tr>";
		echo "	<td width=\"55\" rowspan=\"2\" align=\"center\" valign=\"top\" span class=\"msgIcon\">".$this->msgIcon."</td>";
		echo "	<td colspan=\"2\" align=\"left\" valign=\"top\">"."<font size=\"3\">"."<b>".$this->s_st."</font>"."</b>"."</td>";
		echo "  </tr>";
		echo "  <tr>";
		echo "<td width=\"10\" height=\"24\"></td>";
		echo "<td align=\"left\" valign=\"top\">".$this->msgPrompt."</td>";
		echo "</tr>";
		echo "<tr align=\"center\" valign=\"top\" align=\"center\">";
		echo "<td colspan=\"3\">";
			for($idx=0;$idx<count($this->msgButtons);$idx++){
				echo "<span class=\"msgButton\">";
				echo "<a href=\"".$this->msgLinks[$idx]."\" class=\"msglinks\">";			
				echo $this->msgButtons[$idx];
				echo "</a>";
				echo "</span>";
				echo "&nbsp;";
			}
		echo "</td>";
		echo "  </tr>";
		echo "</table>";

		if($_SESSION['module_'.$_GET['Module']]!=''){ 
			$mod->getFooter();
		}
	}
}	
?>
<link rel="stylesheet" href="/pub/msgbox_style.css" type="text/css">
<?
#$links=array("abort.php","retry.php","ignore.php");
#$a=new msgBox("The user login failed","AbortRetryIgnore");
#$a->makeLinks($links);
#$a->showMsg();
?>
