<?
/*
	$ini = new inifile($INI_PATH[,FALSE]);
	$ini->set_key($SECTION,$KEY,$VALUE);
	$ini->del_key($SECTION,$KEY);
	$ini->del_sec($SECTION);
	$VALUE = $ini->get_key($SECTION,$KEY[,$DEFAULT_VALUE]);
	$ALL_SECTIONS_ARR=$ini->enum_sections();
	$ALL_KEYS_ARR=$ini->enum_keys($SECTION));
	print $ini->listall();
*/
class inifile
  {
  public $filename;
  public $selfstat;
  public $selfstatsec = "This File";
  //var $uselockfile = TRUE;
  public $uselockfile = FALSE;
  public $lockfile;

  function inifile($filename,$selfstat = FALSE)
    {
    $this->selfstat = $selfstat;
    $this->filename = $filename;
    $this->lockfile = $filename.".lock";

    if ((!file_exists($this->filename)) && (!$this->file_test()))
      {
      return FALSE;
      }
    }

  function enum_sections()
    {
    $retw = array();
    if ($ifile = @file($this->filename))
      {
      foreach ($ifile as $vValue)
        {
        if (ereg("^[ \t]*\[[^]]*\].*",$vValue))
          {
          $secexist = FALSE;
          $buf = trim(ereg_replace("[ \t]*\[*([^]]*)\].*","\\1",$vValue));
          for ($i = 0;$i < count($retw);$i++)
            {
            if ($buf == $retw[$i])
              {
              $secexist = TRUE;
              }
            }
          if (!$secexist)
            {
            $retw[count($retw)] = $buf;
            }
          }
        }
      }
    return $retw;
    }

  function enum_keys($Section)
    {
    $retw = array();
    $secfound = FALSE;

    $SEC = preg_quote($Section);

    if ($ifile = @file($this->filename))
      {
      foreach ($ifile as $vValue)
        {
        $vValue=ereg_replace("(\n|\r)","",$vValue);
        if (ereg("^[ \t]*\[[^]]*\].*$",$vValue))
          {
          $secfound = FALSE;
          }
        if (ereg("^[ \t]*\[".$SEC."\].*$",$vValue))
          {
          $secfound = TRUE;
          }
        if (ereg('^[ \t]*[^;]+=.*$',$vValue))
          {
          if ($secfound)
            {
            $keyexist = FALSE;
            $buf = ereg_replace("[ \t]*(.*)[ \t]*=.*","\\1",$vValue);
            for ($i=0;$i<count($retw);$i++)
              {
              if ($buf == $retw[$i])
                {
                $keyexist = TRUE;
                }
              }
            if (!$keyexist)
              {
              $retw[count($retw)] = $buf;
              }
            }
          }
        }
      }
    return $retw;
    }

  function get_key($section,$keyname,$default=FALSE)
    {
    $retw = $default;
    $secfound = FALSE;
    $SEC = preg_quote($section);
    $KEY = preg_quote($keyname);

    if ($ifile = @file($this->filename))
      {
      foreach ($ifile as $vValue)
        {
        if (ereg("^[ \t]*\[[^]]*\].*$",$vValue))
          {
          $secfound = FALSE;
          }
        if (ereg("^[ \t]*\[".$SEC."\].*$",$vValue))
          {
          $secfound = TRUE;
          }
        if (ereg("^[ \t]*".$KEY."[ \t]*=.*$",$vValue))
          {
          if ($secfound)
            {
            $buf =  ereg_replace("^.*".$KEY."[ \t]*=(.*)$","\\1",$vValue);
            $buf = ereg_replace("(\n|\r)*","",$buf);
            $retw = trim($buf);
            return $retw;
            }
          }
        }
      }
    return $retw;
    }

  function set_key($section,$keyname,$NewValue)
    {
    global $HTTP_SERVER_VARS;
    $retw = FALSE;
    $secstart = FALSE;
    $secend   = FALSE;
    $outbuf = array();
    $i=0;
    $done = FALSE;
    $SEC = preg_quote($section);
    $KEY = preg_quote($keyname);

    $this->write_lockfile();

    if ($ifile = @file($this->filename))
      {
      foreach ($ifile as $vValue)
        {
        $i = $i + 1;
        $buf = ereg_replace("(\n|\r)*","",$vValue);
        //echo "0 buf=$buf <br>";
        $outbuf[count($outbuf)] = $buf;
        if (!$done)
          {
          //echo "01 buf=$buf  ereg=" . ereg("\[[^]]*\].*\$",$buf) . " <br>";
          if ($i==1) {
          	$check_section=ereg("\[[^]]*\].*\$",$buf);
          } else {
          	$check_section=ereg("^[ \t]*\[[^]]*\].*\$",$buf);
          }
          //echo "[" . $i . "]check_section=" . $check_section . "<br>";
          if ($check_section) // Section found
            {
            //echo "1 buf=$buf <br>";
            if ($secstart)
              {
							$outbuf[count($outbuf)-1] = $keyname." = ".$NewValue."\n".$outbuf[count($outbuf)-1];
							$done = TRUE;
              $secstart = FALSE;
              $secend = TRUE;
            //echo "11 buf=$buf <br>";
              }
            }          	
          if ($i==1) {
          	$check_ssection=ereg("\[".$SEC."\].*\$",$buf);
          } else {
          	$check_ssection=ereg("^[ \t]*\[".$SEC."\].*\$",$buf);
          }
          if ($check_ssection) // Specified Section found
            {
            //echo "2 buf=$buf <br>";
            $secstart = TRUE;
            $secend = FALSE;
            }
          if (ereg("^[ \t]*".$KEY."[ \t]*=.*\$",$buf) && $secstart) // Key Found
            {
            /* */
            //echo "3 buf=$buf <br>";
            $outbuf[count($outbuf)-1] = $keyname." = ".$NewValue;
            $secstart = FALSE;
            $done = TRUE;
            continue;
            /* */
            }
          if ($secstart && $secend)
            {
            //echo "4 buf=$buf <br>";
            $outbuf[count($outbuf)] = $keyname." = ".$NewValue;
            $secstart = FALSE;
            $secend = FALSE;
            $done = TRUE;
            continue;
            }
          if ($i == count($ifile))
            {
            //echo "5 buf=$buf <br>";
            if ($secstart)
              {
            //echo "6 buf=$buf <br>";
              $outbuf[count($outbuf)] = $keyname." = ".$NewValue;
              $secstart = FALSE;
              $secend = FALSE;
              $done = TRUE;
              continue;
              }
            else
              {
            //echo "7 buf=$buf <br>";
              $outbuf[count($outbuf)] = "\n[".$section."]";
              $outbuf[count($outbuf)] = $keyname." = ".$NewValue;
              }
            }
          }
        }
      }
    if (count($outbuf) == 0)
      {
      //$outbuf[0] = "[".$section."]";
	  $outbuf[0] = "\n[".$section."]";
      $outbuf[1] = $keyname." = ".$NewValue;
      }
    $retw = $this->write_array_to_file($outbuf);

    $this->delete_lockfile();

    if ($this->selfstat)
      {
      $this->selfstat = FALSE;
      $this->set_key($this->selfstatsec,"Last Modified",date("m.d.Y,H:i:s"));
      $this->set_key($this->selfstatsec,"Last Modified By",$HTTP_SERVER_VARS["SCRIPT_FILENAME"]);
      $this->set_key($this->selfstatsec,"Last Modification","Section: \"".$section."\"; Key: \"".$keyname."\" has been set");
      $this->selfstat = TRUE;
      }
    return $retw;
    }

  function write_array_to_file($WArray)
    {
    $retw = FALSE;
    if ($ofile = @fopen($this->filename,'w'))
      {
      foreach ($WArray as $vValue)
        {
        $buf = $vValue."\n";
        //echo "buf=" . $buf . "<br>";
        @fputs($ofile,$buf,strlen($buf));
        }
      @fclose($ofile);
      $retw = TRUE;
      }
    return $retw;
    }
    
  function del_keyline($keyname)
    {
    global $HTTP_SERVER_VARS;
    $retw = FALSE;
    $secstart = FALSE;
    $secend   = FALSE;
    $outbuf = array();
    $i=0;
    $done = false;

    $this->write_lockfile();

    if ($ifile = @file($this->filename)) {
      for ($i=0;$i<count($ifile);$i++){
        $ifile[$i] = ereg_replace("(\n|\r)*","",$ifile[$i]);
        $ifile[$i] = ereg_replace("(\n|\r)*","",$ifile[$i]);
        $pos=false;
        $pos=strpos(" " . $ifile[$i],$keyname);
        //echo "keyname=$keyname pos=" . $pos . "  ifile=" . $ifile[$i] . "<br>";
        if (!$pos) {
          $outbuf[count($outbuf)] = $ifile[$i];
        }
      }
    	$retw = $this->write_array_to_file($outbuf);
    }

    $this->delete_lockfile();

    if ($this->selfstat)
      {
      $this->selfstat = FALSE;
      $this->set_key($this->selfstatsec,"Last Modified",date("m.d.Y,H:i:s"));
      $this->set_key($this->selfstatsec,"Last Modified By",$HTTP_SERVER_VARS["SCRIPT_FILENAME"]);
      $this->set_key($this->selfstatsec,"Last Modification","AFP Folder  \"".$foldername."\"  has been deleted");
      $this->selfstat = TRUE;
      }
    return $retw;
    }

    
  function mod_keyline($old_key,$new_key)
    {
    global $HTTP_SERVER_VARS;
    $retw = FALSE;
    $secstart = FALSE;
    $secend   = FALSE;
    $outbuf = array();
    $i=0;
    $done = false;

    $this->write_lockfile();

    if ($ifile = @file($this->filename)) {
      for ($i=0;$i<count($ifile);$i++){
        $ifile[$i] = ereg_replace("(\n|\r)*","",$ifile[$i]);
        $ifile[$i] = ereg_replace("(\n|\r)*","",$ifile[$i]);
        $pos=false;
        $pos=strpos(" " . $ifile[$i],$old_key);
        //echo "keyname=$keyname pos=" . $pos . "  ifile=" . $ifile[$i] . "<br>";
        if (!$pos) {
          $outbuf[count($outbuf)] = $ifile[$i];
        } else {
        	$outbuf[count($outbuf)] = $new_key;
        }
      }
    	$retw = $this->write_array_to_file($outbuf);
    }

    $this->delete_lockfile();

    if ($this->selfstat)
      {
      $this->selfstat = FALSE;
      $this->set_key($this->selfstatsec,"Last Modified",date("m.d.Y,H:i:s"));
      $this->set_key($this->selfstatsec,"Last Modified By",$HTTP_SERVER_VARS["SCRIPT_FILENAME"]);
      $this->set_key($this->selfstatsec,"Last Modification","AFP Folder  \"".$foldername."\"  has been deleted");
      $this->selfstat = TRUE;
      }
    return $retw;
    }

  function add_keyline($keyname)
    {
    global $HTTP_SERVER_VARS;
    $retw = FALSE;
    $secstart = FALSE;
    $secend   = FALSE;
    $outbuf = array();
    $i=0;
    $duplicate=0;
    $done = false;

    $this->write_lockfile();
		//echo $this->filename;
		
		
    if (!($ifile = @file($this->filename))) {
    	$filelink=readlink($this->filename);
    	//echo "filelink=$filelink <br>";
    	if ($filelink) {
    		$strexec="echo \"\" > " . $filelink;
    		shell_exec($strexec);
    		$ifile = @file($this->filename);
    	} else {
    		$strexec="echo \"\" > " . $this->filename;
    		shell_exec($strexec);
    		$ifile = @file($this->filename);
    	}
  	}
    if ($ifile) {
    	//echo "111111<br>";
      for ($i=0;$i<count($ifile);$i++){
        $ifile[$i] = ereg_replace("(\n|\r)*","",$ifile[$i]);
        $ifile[$i] = ereg_replace("(\n|\r)*","",$ifile[$i]);
        $pos=false;
        $pos=strpos(" " . $ifile[$i],$keyname);
       // echo "FOLDER=$FOLDER pos=" . $pos . "  ifile=" . $ifile[$i] . "<br>";
        if (!$pos) {
          $outbuf[count($outbuf)] = $ifile[$i];
        } else $duplicate++;
      }
      //$outbuf_count=count($outbuf);
      //echo "duplicate=" . $duplicate . " count(outbuf)=" . $outbuf_count . "<br>";
      //if ($duplicate<=0) $outbuf[$outbuf_count] = $keyname;
      $outbuf[$outbuf_count] = $keyname;
      //echo "<br>111 $outbuf <br>";
      
    	$retw = $this->write_array_to_file($outbuf);
    }
   //echo "ifile $ifile <br>filename=" . $this->filename;

    $this->delete_lockfile();

    if ($this->selfstat)
      {
      $this->selfstat = FALSE;
      $this->set_key($this->selfstatsec,"Last Modified",date("m.d.Y,H:i:s"));
      $this->set_key($this->selfstatsec,"Last Modified By",$HTTP_SERVER_VARS["SCRIPT_FILENAME"]);
      $this->set_key($this->selfstatsec,"Last Modification","AFP Folder  \"".$foldername."\"  has been added");
      $this->selfstat = TRUE;
      }
    return $retw;
    }

  function del_key($section,$keyname)
    {
    global $HTTP_SERVER_VARS;
    $retw = FALSE;
    $secstart = FALSE;
    $secend   = FALSE;
    $outbuf = array();
    $i=0;
    $done = false;
    $SEC = preg_quote($section);
    $KEY = preg_quote($keyname);

    $this->write_lockfile();

    if ($ifile = @file($this->filename))
      {
      for ($i=0;$i<count($ifile);$i++)
        {
        $ifile[$i] = ereg_replace("(\n|\r)*","",$ifile[$i]);
        $ifile[$i] = ereg_replace("(\n|\r)*","",$ifile[$i]);
        if (ereg("^[ \t]*\[[^]]*\].*\$",$ifile[$i])) // Section found
          {
          if ($secstart)
            {
            $secstart = FALSE;
            $secend = TRUE;
            }
          }
        if (ereg("^[ \t]*\[".$SEC."\].*\$",$ifile[$i])) // Specified Section found
          {
          $secstart = TRUE;
          $secend = FALSE;
          }
        if (ereg("^[ \t]*".$KEY."[ \t]*=.*\$",$ifile[$i]) && $secstart) // Key Found
          {
          continue;
          }
        else
          {
          $outbuf[count($outbuf)] = $ifile[$i];
          }
        }
      }
    $retw = $this->write_array_to_file($outbuf);

    $this->delete_lockfile();

    if ($this->selfstat)
      {
      $this->selfstat = FALSE;
      $this->set_key($this->selfstatsec,"Last Modified",date("m.d.Y,H:i:s"));
      $this->set_key($this->selfstatsec,"Last Modified By",$HTTP_SERVER_VARS["SCRIPT_FILENAME"]);
      $this->set_key($this->selfstatsec,"Last Modification","Section: \"".$section."\"; Key: \"".$keyname."\" has been deleted");
      $this->selfstat = TRUE;
      }
    return $retw;
    }

  function del_sec($section)
    {
    global $HTTP_SERVER_VARS;
    $retw = FALSE;
    $secstart = FALSE;
    $secend   = FALSE;
    $outbuf = array();
    $SEC = preg_quote($section);

    $this->write_lockfile();

    if ($ifile = @file($this->filename))
      {
      for ($i=0;$i<count($ifile);$i++)
        {
        $ifile[$i] = ereg_replace("(\n|\r)*","",$ifile[$i]);
        $ifile[$i] = ereg_replace("(\n|\r)*","",$ifile[$i]);
        if (ereg("^[ \t]*\[[^]]*\].*\$",$ifile[$i])) // Section found
          {
          if ($secstart)
            {
            $secstart = FALSE;
            $secend = TRUE;
            }
          }
        if (ereg("^[ \t]*\[".$SEC."\].*\$",$ifile[$i])) // Specified Section found
          {
          $secstart = TRUE;
          $secend = FALSE;
          }
        if (!$secstart)
          {
          $outbuf[count($outbuf)] = $ifile[$i];
          }
        }
      }
    $retw = $this->write_array_to_file($outbuf);

    $this->delete_lockfile();

    if ($this->selfstat)
      {
      $this->selfstat = FALSE;
      $this->set_key($this->selfstatsec,"Last Modified",date("m.d.Y,H:i:s"));
      $this->set_key($this->selfstatsec,"Last Modified By",$HTTP_SERVER_VARS["SCRIPT_FILENAME"]);
      $this->set_key($this->selfstatsec,"Last Modification","Section \"".$section."\" has been deleted");
      $this->selfstat = TRUE;
      }
    return $retw;
    }
  function listall()
    {
    $retw = FALSE;
    $tarr = $this->enum_sections();
    foreach ($tarr as $vValue)
      {
      $retw .= "[".$vValue."]"."\n";
      $t1arr = $this->enum_keys($vValue);
      foreach ($t1arr as $vvValue)
        {
        $this->get_key($vValue,$vvValue);
        $retw .= $vvValue." = ".$this->get_key($vValue,$vvValue)."\n";
        }
      }
    return $retw;
    }

  function file_test()
    {
    global $HTTP_SERVER_VARS;
    $retw = FALSE;
    if ($fp = @fopen($this->filename,"w"))
      {
      @fclose($fp);
      @unlink($this->filename);
      if ($this->selfstat)
        {
        $this->set_key($this->selfstatsec,"Original Filename",$this->filename);
        $this->set_key($this->selfstatsec,"Creator",$HTTP_SERVER_VARS["SCRIPT_FILENAME"]);
        $this->set_key($this->selfstatsec,"Creation Date",date("d.m.Y,H:i:s"));
        }
      $retw = TRUE;
      }
    return $retw;
    }
  function write_lockfile()
    {
	return true;
    if ($this->uselockfile)
      {
      if (file_exists($this->lockfile))
        {
        $EX = TRUE;
        }
      else
        {
        $EX = FALSE;
        }
      while ($EX)
        {
        $res = file_exists($this->lockfile);
        if (!$res) { $EX = FALSE; }
        if ($res) { break; }
        }
      $fp = @fopen($this->lockfile,"w");
      @fclose($fp);
      }
    $retw = TRUE;
    return $retw;
    }
  function delete_lockfile()
    {
	return true;
    if ($this->uselockfile)
      {
      @unlink($this->lockfile);
      }
    }
  }
?>
