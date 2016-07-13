<?php
    /* default is success */
    class TaskRunner{
        function TaskRunner($topic,$code=false){
            if (!$code) $code=$topic;
            $this->topic="<span name=\"_ML\" id=\"_ML\" code=\"$code\">$topic</span>";
            $this->errcode=false;
            $this->mesg=false;
            $this->buttons=array('links'=>array());
            $this->extra=array();
            $this->title="";
        }
        function Extra($tag){
            array_push($this->extra,$tag);
        }
        function Error($errcode){
            $this->errcode=$errcode;
        }
        function Result($errcode){
            /* Alias of "Error" */
            return $this->Error($errcode);
        }
        function OK($link){
            $this->buttons['OK']=1;
            array_push($this->buttons['links'],$link);
        }
        function Cancel($link){
            $this->buttons['Cancel']=1;
            array_push($this->buttons['links'],$link);
        }
//Below hubert_add on 2005.04.14
        function Yes($link){
            $this->buttons['Yes']=1;
            array_push($this->buttons['links'],$link);
        }
        function No($link){
            $this->buttons['No']=1;
            array_push($this->buttons['links'],$link);
        }
        function Mesg($mesg){
            $this->mesg=$mesg;
        }
        function MsgTitle($title){
            $this->title=$title;
        }
        function Message($mesg){
            $this->mesg=$mesg;
        }
//Above hubert_add on 2005.04.14
        function Finish(){
           /* Only the following combinations are valid */
           /* OK, OKCancel, AbortRetryIgnore, YesNoCancel, YesNo, RetryCancel */
            $names=array('OK','Cancel','Yes','No','Abort','Retry','Ignore');
            $bt='';
            foreach($names as $name){
                if (isset($this->buttons[$name])) $bt=$bt.$name;
            }
            if ($bt=='' || $bt=='OK') $bt='OKOnly';
            $buttons=array('type'=>$bt,'links'=>$this->buttons['links']);
            return array($this->errcode,$this->topic,$this->mesg,$buttons, join($this->extra),$this->title);
        }
    }
?>

