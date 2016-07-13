<?php
    function ML_addTag($w,$code,$hidden=0){
       if ($hidden) $hidden=" class=\"hidden\"";
       else $hidden='';
       return "<span id=\"_ML\" name=\"_ML\" code=\"$code\"$hidden>$w</span>";
    }
?>
