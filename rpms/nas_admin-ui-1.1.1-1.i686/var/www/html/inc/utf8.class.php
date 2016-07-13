<?php

function utf8_isValidChar($inputStr, $start = 0)
{
    $size = strlen($inputStr);
    if($size <=0 || $start < 0 || $size <= $start) return 0;

    $inOrd = ord($inputStr{$start});
    $us = 0;
    if($inOrd <= 0x7F) { //0xxxxxxx
        return 1;
    } else if($inOrd >= 0xC0 && $inOrd <= 0xDF ) { //110xxxxx 10xxxxxx
        $us = 2;
    } else if($inOrd >= 0xE0 && $inOrd <= 0xEF ) { //1110xxxx 10xxxxxx 10xxxxxx
        $us = 3;
    } else if($inOrd >= 0xF0 && $inOrd <= 0xF7 ) { //11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
        $us = 4;
    } else if($inOrd >= 0xF8 && $inOrd <= 0xFB ) { //111110xx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
        $us = 5;
    } else if($inOrd >= 0xFC && $inOrd <= 0xFD ) { //1111110x 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
        $us = 6;
    } else
        return -1;

    if($size - $start < $us)
        return -1;

    for($i=1; $i<$us; $i++)
    {
        $od = ord($inputStr{$start+$i}); 
        if($od <0x80 || $od > 0xBF)
            return -1;
    }
    return $us;
}

function utf8_substr($inputStr, $start, $length = -1, $ignore_error = true)
{
    if($start<0 || $length == 0)
        return false;
    //discard preg_split function. it consumes too much system resource when it tries to split a big string to pieces
    //$rawArr = preg_split('//',$inputStr,-1, PREG_SPLIT_NO_EMPTY); 
    //find start
    $si = 0;
    $si_single = 0;
    while($si < $start)
    {
        $hm = utf8_isValidChar($inputStr, $si_single);
        if($hm == -1)
        {
            //ignore invalid character?
            if(!$ignore_error)
                return false;
            //array_shift is very slow
            //array_shift($rawArr); 
            $si++;
            $si_single++;
        }
        else if($hm == 0)
        {
            //$start is bigger than the utf8_length of inputString
            return false;
        }
        else
        {
            //for($i=0; $i<$hm; $i++) array_shift($rawArr);
            $si++;
            $si_single += $hm;
        }
    }
    if($length < 0)
        //return implode('', $rawArr);
        return substr($inputStr, $si_single);
    $retArr = array();
    $li = 0;
    while($li < $length)
    {
        $hm = utf8_isValidChar($inputStr, $si_single);
        if($hm == -1)
        {
            if(!$ignore_error)
                return false;
            $retArr[] = '?'; 
            //array_shift($rawArr);
            $li++;
            $si_single++;
        }
        else if($hm == 0)
        {
            //end of string
            return implode('', $retArr);
        }
        else
        {
            //for($i=0; $i<$hm; $i++) $retArr[] = array_shift($rawArr);
            for($i=0; $i<$hm; $i++) $retArr[] = $inputStr{$si_single++};
            $li++;
        }
    }
    return implode('', $retArr);
}

function utf8_strlen($inputStr, $ignore_error = true)
{
    //$rawArr = preg_split('//',$inputStr,-1, PREG_SPLIT_NO_EMPTY); 
    $len = 0;
    $si_single = 0;
    while(($hm = utf8_isValidChar($inputStr, $si_single)) != 0)
    {
        if($hm == -1)
        {
            if(!$ignore_error)
                return -1;
            //array_shift($rawArr);
            $si_single++;
        }
        else
            //for($i=0; $i<$hm; $i++) array_shift($rawArr);
            $si_single += $hm;
        $len++;
    }
    return $len;
}

function utf8_proportion($inputStr)
{
    //$rawArr = preg_split('//',$inputStr,-1, PREG_SPLIT_NO_EMPTY); 
    //$rawLen = count($rawArr);
    $rawLen = strlen($inputStr);
    if($rawLen == 0)
        return 100;
    $validChars = 0;
    $si_single = 0;
    while(($hm = utf8_isValidChar($inputStr, $si_single)) != 0)
    {
        if($hm == -1)
        {
            //array_shift($rawArr);
            $si_single++;
            continue;
        }
        //for($i=0; $i<$hm; $i++) array_shift($rawArr);
        $validChars += $hm;
        $si_single += $hm;
    }
    if($validChars == $rawLen)
        return 100;
    else
        return (int)($validChars*100.0/$rawLen);
}

function utf8_filename_format($str){
	$i=0;
        $j=0;
        $len  =  strlen($str);
        $cp='';

        for($i=0;$i<$len;$i++)  {
                $ss = substr($str,$i,1);
                $sbit  =  ord($ss);
                if($sbit  <  128)  {
                        $cp .= substr($str,$i,1);
                }elseif($sbit  >  191  &&  $sbit  <  224)  {
                        $cp .= substr($str,$i,2);
                        $i++;
                        $j++;
               }elseif($sbit  >  223  &&  $sbit  <  240)  {
                        $cp .= substr($str,$i,3);
                        $i+=2;
                        $j++;
                }elseif($sbit  >  239  &&  $sbit  <  248)  {
                        $cp .= substr($str,$i,4);
                        $i+=3;
                        $j++;
                }
                $j++;

                if ($j > 30){
                        $cp .= '<br>&nbsp;';
                        $j=0;
                }
        }
        return $cp;
}

?>
