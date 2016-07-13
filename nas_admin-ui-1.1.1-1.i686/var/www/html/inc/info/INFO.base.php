<?
// information mechanism common interface
class INFO{
	var $content = array();
	var $raid_name;
        var $mddisk;
        var $mdname;
        var $vg_name;
        var $raid_folder;
    function INFO($raid){
    		return "1";
		//$this->raid_name=$raid;
		//$this->parse();
	}

	function parse(){
		echo "prepare for override\n";
	}

	function getINFO($num="1"){
		$this->md_num=$num;
		$this->raid_name=$raid;
		$this->mdname="md".$num;
		$this->mddisk="/dev/md".$num;
		if (NAS_DB_KEY == '1'){
			$this->raid_folder="raid".($num-1);
			$this->vg_name="vg".($num-1);
			$this->zfspoolname="zfspool".($num-1);
		}else{
			$this->raid_folder="raid".($num);
			$this->vg_name="md".($num);
			$this->zfspoolname="zfspool".($num);
		}
		$this->data_lvname=$this->vg_name."-lv0";
		$this->usb_lvname=$this->vg_name."-lv1";
		$this->sys_lvname=$this->vg_name."-syslv";
		$this->CapacityUnit=" GB";
		$this->parse();
		return $this->content;
	}
	
	//\n¡B\t¡B'kB' replace by empty string
    function filter($s){
		$pattern = array("\n","\t","kB");
		for ($i=0;$i<count($pattern);$i++){
			$s=str_replace($pattern[$i],"",$s);
		}
		return trim($s);
	}
}
?>
