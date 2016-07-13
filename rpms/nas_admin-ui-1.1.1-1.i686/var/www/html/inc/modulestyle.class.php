<?php
class ModuleStyle{
     var $tpl;
     var $modname;
     var $styledir;
     var $styledir_public;
     var $headerdir;
     var $footerdir;
     function ModuleStyle($modname){
           require_once('/var/www/html/inc/inittemplate.php');
           global $tpl;
           $this->tpl=$tpl;
           $this->modname=$modname;
           $this->styledir=MODULE_ROOT.$modname.'/www/style.css';
           $this->styledir_public='/theme/css/css_module.css';
           $this->headerdir=MODULE_ROOT.$modname.'/www/header.php';
           $this->footerdir=MODULE_ROOT.$modname.'/www/footer.php';
     }
     function getCss(){
     	   echo "<html><head>";
           if(is_file($this->styledir)){
                echo "<link rel='stylesheet' type='text/css' href='".$this->styledir."' />";      
           }else{
                echo "<link rel='stylesheet' type='text/css' href='".$this->styledir_public."' />";      
           }
     }
     function getHeader(){
     	   echo "</head><body>";
           if(is_file($this->headerdir)){
                require_once($this->headerdir);
           }else{
                $html=$this->tpl->fetch('adm/module_header.tpl');
                echo $html;
           }
     }
     function getFooter(){
           if(is_file($this->footerdir)){
                require_once($this->footerdir);
           }else{
                $html=$this->tpl->fetch('adm/module_footer.tpl');
                echo $html;
           }
     }

}

?>
