<?
//'provide cpu information'
include_once("INFO.base.php");
class CPUINFO extends INFO{
	function parse(){
	   $this->content["CPUSpeed"]=400;
	   $cpu_usage = $this->getCpuUsage();
	   //print_r($cpu_usage);
	   $this->content["CPULoading"]=100-ceil($cpu_usage["idle"]);
	}

/**
* array getStat(string $_statPath)
*
* reads the /proc/stat file and parses out the pertinant information
*
* This function is meant to work in conjunction with getCpuUsage.  $_statPath should contain the
* path to stat (typicly /proc/stat)
*
* Returns an array of timings on success, false on failure
**/

 

function getStat($_statPath)
{
    if (trim($_statPath) == '')
    {
        $_statPath = '/proc/stat';
    }

    if (!is_readable($_statPath))
    {
        return false;
    }

    $stat = file($_statPath);

    if (substr($stat[0], 0, 3) == 'cpu')
    {
        $parts = explode(" ", preg_replace("!cpu +!", "", $stat[0]));
    }
    else
    {
        return false;
    }

    $return = array();
    $return['user'] = $parts[0];
    $return['nice'] = $parts[1];
    $return['system'] = $parts[2];
    $return['idle'] = $parts[3];
    return $return;
}

/**
* array getCpuUsage([string $_startpath])
*
* Returns an array of percentages representing the various CPU usage states
*
* The optional $_statPath variable should only be set if the stat file does not exist
* in /proc/stat
*
* Returns an array of percentages on success, terminates the script on failure
**/

function getCpuUsage($_statPath = '/proc/stat')
{
    $time1 = $this->getStat($_statPath) or die("getCpuUsage(): couldn't access STAT path or STAT file invalid\n");
    sleep(1);
    $time2 = $this->getStat($_statPath) or die("getCpuUsage(): couldn't access STAT path or STAT file invalid\n");

    $delta = array();

    foreach ($time1 as $k=>$v)
    {
        $delta[$k] = $time2[$k] - $v;
    }

    $deltaTotal = array_sum($delta);

    $percentages = array();

    foreach ($delta as $k=>$v)
    {
        $percentages[$k] = round(@($v / $deltaTotal) * 100, 2);
    }
    return $percentages;
}

}


/* test main 
$x = new CPUINFO();
print_r($x->getINFO());
*/
?>
