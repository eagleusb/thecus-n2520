<?php


/**
 * Response-class to be used from serverside-function, add static behaviors and
 * data to set/change and return the behavior with getString()
 * @since 0.9.2 new static function isCallback
 */
class TinyAjaxBehavior
{
	private $mUtf8 = false;
	
	function __construct($UTF8 = true) {
		$this->mUtf8 = $UTF8;
	}

	private $behavior = "";

	/**
	 * Adds behavior to return to callback javascript
	 * 
	 * @param Tab-behavior $behavior as string from Tab::getBehavior()
	 */
	function add($behavior){
		if($this->behavior != "") {
			$this->behavior .= "~";
		}

		$first = true;
		foreach($behavior as $val) {

			if(!$first) {
				$this->behavior .= "|";
			} else {
				$first = false;
			}
			
			$val = str_replace("|", "!!pipe!!", $val);
			$val = str_replace("~", "!!tilde!!", $val);
			
			//echo "this->mUtf8=" . $this->mUtf8 . "<br>";
			if(!$this->mUtf8) {
				//echo "encode .. <br>";
				$val = utf8_encode($val);
			}
			
			$this->behavior .= $val;
			
		}
	}

	
	/**
	 * Checks if it's a AJAX callback, this allows callback functions
	 * to be used both with TinyAjax and regular serverside code.
	 * If it's a callback return behavior, otherwise return result
	 *
	 * @return boolean true if it's a AJAX callback, false if not
	 */
	public static final function isCallback() {
		return (isset($_GET['rs']) || isset($_POST['rs']));
	}
	
	/**
	 * Returns all behaviors to execute as a string to javascript callback
	 *
	 * @return string Behaviors
	 */
	function getString() { return $this->behavior; }
}


/**
 *	Abstract TinyAjaxBehavior-class which defines behaviors
 *  Subclasses need to implement getScript and static getBehavior
 * @since 2006-01-18 changed $mDrawn to boolean from array, array not needed
 * @since 2006-01-18 getScript protected and static getBehavior implemented (can't be abstract static :-( )
 */
abstract class Tab{

	private $mDrawn = false;

	abstract protected function getScript();

	public static function getBehavior() { 
		return ""; 
	}
	
	public final function getFunctionName(){
		return get_class($this);
	}
	

	public function getJavaScript()
	{
		return $this->getScript();
	}

	
}



class TabAlert extends Tab
{
	protected function getScript(){
		return "function " . get_class() . "(data){
			alert(data[1]);
		}
		";
	}

	public static function getBehavior($data) {
		return array(get_class(), $data);
	}
}

class TabSetValue extends Tab
{
	protected function getScript(){

		$html = "function " . get_class($this) . "(data){";
		$html .= " document.getElementById(data[1]).value = decodeSpecialChars(data[2]);\n}\n";

		return $html;
	}

	public static function getBehavior($form_id, $data) {
		return array(get_class(), $form_id, $data);
	}
}

class TabInnerHtml extends Tab
{
	protected function getScript(){

		return "function " . get_class($this) . "(data){
	document.getElementById(data[1]).innerHTML = decodeSpecialChars(data[2]);\n}\n";
	}

	public static function getBehavior($form_id, $data) {
		return array(get_class() , $form_id,  $data);
	}
}

class TabInnerHtmlPrepend extends Tab
{
	protected function getScript(){

		return "function " . get_class($this) . "(data){
	document.getElementById(data[1]).innerHTML = decodeSpecialChars(data[2]) + document.getElementById(data[1]).innerHTML;\n}\n";
	}

	public static function getBehavior($form_id, $data) {
		return array(get_class(), $form_id, $data);
	}
}
class TabInnerHtmlAppend extends Tab
{
	protected function getScript(){

		return "function " . get_class($this) . "(data){
	document.getElementById(data[1]).innerHTML = document.getElementById(data[1]).innerHTML + decodeSpecialChars(data[2]);\n}\n";
	}

	public static function getBehavior($form_id, $data) {
		return array(get_class(), $form_id, $data);
	}
}

class TabAddOption extends Tab
{
	protected function getScript(){

		return "function " . get_class($this) . "(data){
	if(data[1]=='candidates'){
	  var candidates = document.getElementById('candidates');
	  var deny = document.getElementById('deny');
	  var readonly = document.getElementById('readonly');
	  var writable = document.getElementById('writable');
	  var deny_exist=0;
	  var readonly_exist=0;
	  var writable_exist=0;
	  var limit=data[6];
	  //var limit=10;
	  var count=candidates.length;
	  //alert (data[7]+'=='+data[2]);
	  var name=decodeSpecialChars(data[3]);
	  for(var i=0;i<deny.length;i++){
    	    var option=deny.options;
	    var role=option[i].getAttribute('role');
	    //alert (deny[i].text+'=='+name);
	    if(deny[i].text==name && role==data[5]){
	      deny_exist=1;
	      break;
	    }else{
	      deny_exist=0;
	    }
	  }
	  for(var i=0;i<readonly.length;i++){
    	    var option=readonly.options;
	    var role=option[i].getAttribute('role');
	    if(readonly[i].text==name && role==data[5]){
	      readonly_exist=1;
	      break;
	    }else{
	      readonly_exist=0;
	    }
	  }
	  for(var i=0;i<writable.length;i++){
    	    var option=writable.options;
	    var role=option[i].getAttribute('role');
	    if(writable[i].text==name && role==data[5]){
	      writable_exist=1;
	      break;
	    }else{
	      writable_exist=0;
	    }
	    //alert (writable[i].text);
	    //alert (decodeSpecialChars(data[3]));
	  }
	  //alert (decodeSpecialChars(data[3]));
	}else{
	  var goto_default=1;
	}
	//alert (deny_exist+'=='+readonly_exist+'=='+writable_exist);
	if(deny_exist==0 && readonly_exist==0 && writable_exist==0 && count<limit){
	//if(deny_exist==0 && readonly_exist==0 && writable_exist==0){
	  var sel = document.getElementById(data[1]);
	  //alert (decodeSpecialChars(data[3]));
	  var opt = sel.options[sel.options.length] = new Option(name, decodeSpecialChars(data[2]), true, false);
	  opt.setAttribute('role',data[5]);
	  if(data[5]=='local_group') opt.style.color='#ff0000';
	  if(data[5]=='local_user') opt.style.color='#336600';
	  if(data[5]=='ad_group') opt.style.color='#0000ff';
	  if(data[5]=='ad_user') opt.style.color='#996633';
	}else{
	  if(goto_default==1){
	    var sel = document.getElementById(data[1]);
	    var opt = sel.options[sel.options.length] = new Option(decodeSpecialChars(data[3]), decodeSpecialChars(data[2]), true, false);
	  }
	}
	//alert (count);
	if(data[7]==data[2] && count>=limit){
	  var alert_msg=data[8].replace(/\\\\n/,'\\n');
	  alert (alert_msg);
	}
	if(data[4] != 0)
		sel.selectedIndex = sel.options.length-1;\n}\n";
	}

	public static function getBehavior($element_id, $id, $value, $select_it = 0, $role, $limit ,$last_id, $alert_msg) {
		$select_it ? 1 : 0;
		return array(get_class(), $element_id, $id, $value, $select_it, $role, $limit, $last_id, $alert_msg);
	}

}

class TabClearOptions extends Tab
{
	protected function getScript(){

		return "function " . get_class($this) . "(data){
	var sel = document.getElementById(data[1]);
	sel.options.length = 0;\n}\n";
	}

	public static function getBehavior($element_id) {
		return array(get_class(), $element_id);
	}

}

class TabGetOptions extends Tab
{
	protected function getScript(){

		return "function " . get_class($this) . "(data){
	var sel = document.getElementById(data[1]);
	alert (sel[0].text);
	return sel[0].text;
	//for(var i=0;i<sel.length;i++){
	//  alert (sel[i].text);
	//}
	}\n";
	}

	public static function getBehavior($element_id) {
		return array(get_class(), $element_id);
	}

}

class TabRemoveFirstOption extends Tab
{
        protected function getScript(){
        
		return "function " . get_class($this) . "(data){
			var sel = document.getElementById(data[1]);
			sel.options[0] = null;
                                   
		}\n";
	}
                                                   
	public static function getBehavior($element_id) {
		return array(get_class(), $element_id);
	}
                                                                      
}

class TabRemoveSelectedOption extends Tab
{
	protected function getScript(){

		return "function " . get_class($this) . "(data){
	var sel = document.getElementById(data[1]);
	sel.options[sel.options.selectedIndex] = null;
		
	}\n";
	}

	public static function getBehavior($element_id) {
		return array(get_class(), $element_id);
	}

}



class TabSetWindowFocus extends Tab
{
	protected function getScript(){
		return "function " . get_class($this) . "(data){\n\twindow.focus();\n}\n";
	}

	public static function getBehavior() {
		return array(get_class());
	}

}

class TabSetBackgroundColor extends Tab 
{
	protected function getScript(){

		return "function " . get_class($this) . "(data){
	var o = document.getElementById(data[1]);
	if(o){
		var col = data[2];
		o.style.backgroundColor = col;
			}\n}\n";
	}

	public static function getBehavior($element_id, $color) {
		return array(get_class(), $element_id, $color);
	}
	
}

class TabRedirect extends Tab 
{
	protected function getScript(){
		return "function " . get_class($this) . "(data){ " 
				. "\n\t document.location = data[1]; \n\t }\n";
	}
		
	public static function getBehavior($location) {
		return array(get_class(), $location);
	}
	
}


class TabEval extends Tab 
{
	protected function getScript(){
		return "function " . get_class($this) . "(data){ 
		 //alert(data[1]);
		 eval(data[1]); \n\t }\n";
	}
		
	public static function getBehavior($scriptName) {
		return array(get_class(), $scriptName);
	}
	
}

// Class for change multiple propertys
class ChgDisabled extends Tab
{
   protected function getScript() {
      
      ob_start();
      
      echo "function " . get_class($this) . "(data){
	if (data[2] == 'true'){
      		document.getElementById(data[1]).disabled=true;
	}else{
      		document.getElementById(data[1]).disabled=false;
	}
      }\n";
      
      return ob_get_clean();      
   }
   
   public static function getBehavior($element_id,$value) {
      return array(get_class(), $element_id,$value);
   }
}

class ChgMultiDisabled extends Tab
{
   protected function getScript() {
      
      ob_start();
      
      echo "function " . get_class($this) . "(data){
	var item=document.getElementsByName(data[1]);
	for(i=0;i<item.length;i++){
	  if (data[2] == 'true'){
	    item[i].disabled=true;
	  }else{
	    item[i].disabled=false;
	  }
	}
      }\n";
      
      return ob_get_clean();      
   }
   
   public static function getBehavior($element_id,$value) {
      return array(get_class(), $element_id,$value);
   }
}

class ChgMultiHidden extends Tab
{
   protected function getScript() {
      
      ob_start();
      
      echo "function " . get_class($this) . "(data){
      		var item=document.getElementsByName(data[1]);
      		//for(var c=0;c<item.length;c++){
      		//	if(c == data[2]){
				var n=data[2]
      				if(data[3] == 'true'){
      					item[n].style.visibility='hidden';
      					item[n].style.position='absolute';
      					item[n].style.display='none';
      				}else{
      					item[n].style.visibility='';
      					item[n].style.position='';
      					item[n].style.display='';
      				}
      		//	}
      		//}
      }\n";
      
      return ob_get_clean();      
   }
   
   public static function getBehavior($element_id,$num,$value) {
      return array(get_class(), $element_id,$num,$value);
   }
}

class ChgHidden extends Tab
{
   protected function getScript() {
      
      ob_start();
      
      echo "function " . get_class($this) . "(data){
      		var item=document.getElementById(data[1]);
      		if(data[2] == 'true'){
      			item.style.visibility='hidden';
      			item.style.position='absolute';
			item.style.display='none';
      		}else{
      			item.style.visibility='';
      			item.style.position='';
			item.style.display='';
      		}
      }\n";
      
      return ob_get_clean();      
   }
   
   public static function getBehavior($element_id,$value) {
      return array(get_class(), $element_id,$value);
   }
}

class ChgSrc extends Tab
{
   protected function getScript() {
      
      ob_start();
      
      echo "function " . get_class($this) . "(data){
      		var item=document.getElementById(data[1]);
 		item.src=data[2];
      }\n";
      
      return ob_get_clean();      
   }
   
   public static function getBehavior($element_id,$value) {
      return array(get_class(), $element_id,$value);
   }
}

class SetMutiTagItem extends Tab
{
   protected function getScript() {
      
      ob_start();
      
      echo "function " . get_class($this) . "(data){
      		var item=document.getElementsByName(data[1]);
      		var n=data[2];
      		if(data[3]=='checked'){
      			item[n].checked=data[4];
      		}
      }\n";
      
      return ob_get_clean();      
   }
   
   public static function getBehavior($element_id,$num,$option,$value) {
      return array(get_class(), $element_id,$num,$option,$value);
   }
}

class SetStyle extends Tab
{
   protected function getScript() {
      
      ob_start();
      
      echo "function " . get_class($this) . "(data){
      		var item=document.getElementById(data[1]);
      		if(data[2] == 'background'){
      			item.style.background=data[3];
      		}
      }\n";
      
      return ob_get_clean();      
   }
   
   public static function getBehavior($element_id,$option,$value) {
      return array(get_class(), $element_id,$option,$value);
   }
}

?>
