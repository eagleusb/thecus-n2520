<?php
require_once("info/lvminfo.class.php");
require_once("foo.class.php");
//===============================================================
//  
//	By hubert_huang@thecus.com on 2005/01/10
//
//	definition:
//	LVM base class
//	Just use basic command, nothing special
//
//	$lvm=new lvm();
//	$lvm->vgscan($exec=FALSE);
//	$lvm->pvcreate($disk,$exec=FALSE);
//	$lvm->vgcreate($vgname,$diskarr,$exec=FALSE);
//	$lvm->lvcreate($size,$lvname,$vgname,$exec=FALSE);
//	$lvm->mke2fs($vgname,$lvname,$exec=FALSE);
//	$lvm->lvremove($devpath,$exec=FALSE);
//	$lvm->lvresize($devpath,$resize,$exec=FALSE);
//	$lvm->execute($cmd);
//
//===============================================================
//	# lvcreate -L 200M -n tt01_snap --snapshot /dev/rootvg/tt01
//	  device-mapper ioctl cmd 9 failed: Invalid argument
//	  Couldn't load device 'rootvg-tt01_snap'.
//	  Problem reactivating origin tt01
//	# lvremove /dev/rootvg/tt01
//	  Can't remove logical volume "tt01" under snapshot
//===============================================================
//# lvcreate -L 100M --snapshot -n hh01_snap01 /dev/rootvg/hh01
//  device-mapper ioctl cmd 9 failed: Invalid argument
//  Couldn't load device 'rootvg-hh01_snap01'.
//  Problem reactivating origin hh01
//# lvcreate -L 100M --snapshot -n hh01_snap02 /dev/rootvg/hh01
//  device-mapper ioctl cmd 6 failed: Invalid argument
//  Couldn't resume device 'rootvg-hh01_snap01'
//  Aborting. Failed to activate snapshot exception store. Remove new LV and retry.

class lvm extends foo {
	const pvscan_bin="/sbin/pvscan";
	const vgscan_bin="/sbin/vgscan";
	const vgcreate_bin="/sbin/vgcreate";
	const vgremove_bin="/sbin/vgremove";
	const vgchange_bin="/sbin/vgchange";
	const pvcreate_bin="/sbin/pvcreate";
	const pvremove_bin="/sbin/pvremove";
	const lvcreate_bin="/sbin/lvcreate";
	const mke2fs_bin="/sbin/mke2fs";
	const lvremove_bin="/sbin/lvremove";
	const lvextend_bin="/sbin/lvextend";
	const lvreduce_bin="/sbin/lvreduce";
	const resize2fs_bin="/sbin/resize2fs";//
	const pvdisplay_bin="/sbin/pvdisplay";
	const lvdisplay_bin="/sbin/lvdisplay";
	const e2fsck_bin="/sbin/e2fsck";
	const error_pattern="'\(fail\|invalid\|error\|fatal\|segment.*fault\)'";// "Segmentation fault";
	const default_extent=4;
	public static $extent=FALSE;

	//===========================================================
	//	IF success will print on console, $output=1
	//	IF fail will print on console, $output=0
	//===========================================================

	//===========================================================
	//	method to do vgscan command
	//===========================================================
	public function pvscan($exec=FALSE) {
		$cmd=self::pvscan_bin." 2>&1 | grep -i ".self::error_pattern;
		if(self::debug){print $cmd;flush();print "\n<hr>\n";}
		$res=($exec)?self::execute($cmd,FAIL_WILL_PRINT_ON_CONSOLE):$cmd;
		return $res;
	}

	//===========================================================
	//	method to do vgscan command
	//===========================================================
	public function vgscan($exec=FALSE) {
		//$cmd=self::vgscan_bin." 2>&1 | grep -i 'found volume group'";
		$cmd=self::vgscan_bin." 2>&1 | grep -i ".self::error_pattern;
		if(self::debug){print $cmd;flush();print "\n<hr>\n";}
		$res=($exec)?self::execute($cmd,FAIL_WILL_PRINT_ON_CONSOLE):$cmd;
		return $res;
	}

	//===========================================================
	//	method to create a PV
	//===========================================================
	public function pvcreate($disk,$exec=FALSE) {
		//tpl:/sbin/pvcreate /dev/md0
		//ERROR:Can't initialize physical volume "/dev/md0" of volume group "rootvg" without -ff
		$disk="/dev/".$disk;
		$cmd=self::pvcreate_bin." ".$disk." 2>&1 | grep -i 'success.* create'";
		if(self::debug){print $cmd;flush();print "\n<hr>\n";}
		$res=($exec)?self::execute($cmd,SUCCESS_WILL_PRINT_ON_CONSOLE):$cmd;
		return $res;
	}

	//===========================================================
	//	method to create a PV
	//===========================================================
	public function pvremove($disk,$exec=FALSE) {
		//tpl:
		$disk="/dev/".$disk;
		$cmd=self::pvremove_bin." ".$disk." 2>&1";
		if(self::debug){print $cmd;flush();print "\n<hr>\n";}
		$res=($exec)?self::execute($cmd,SUCCESS_WILL_PRINT_ON_CONSOLE):$cmd;
		return $res;
	}

	//===========================================================
	//	method to create a PV
	//===========================================================
	public function all_pvremove($exec=FALSE) {
		//pvremove `pvscan | grep PV | awk '{print $2}'`
		$cmd=self::pvremove_bin." `".self::pvscan_bin." | grep PV | awk '{print \$2}'` 2>&1 | grep 'successfully wiped'";
		if(self::debug){print $cmd;flush();print "\n<hr>\n";}
		$res=($exec)?self::execute($cmd,SUCCESS_WILL_PRINT_ON_CONSOLE):$cmd;
		return $res;
	}

	//===========================================================
	//	method to do vgcreate, remember $diskarr must be an array 
	//===========================================================
	public function vgcreate($vgname,$diskarr,$exec=FALSE) {
		//tpl:/sbin/vgcreate rootvg /dev/md0 /dev/md1
		//ERROR:  /dev/rootvg: already exists in filesystem
		if(!is_array($diskarr)) return -2;
		$devarr="";
		foreach($diskarr as $disk) {
			$disk="/dev/".$disk." ";
			$devarr.=$disk;
		}
		$cmd=self::vgcreate_bin." ".$vgname." ".$devarr." 2>&1 | grep -i 'success.* create'";
		if(self::debug){print $cmd;flush();print "\n<hr>\n";}
		$res=($exec)?self::execute($cmd,SUCCESS_WILL_PRINT_ON_CONSOLE):$cmd;
		return $res;
	}

	//===========================================================
	//	method to do vgcreate, remember $diskarr must be an array 
	//===========================================================
	public function vgchange($vgname,$exec=FALSE) {
		//tpl:
		$cmd=self::vgchange_bin." -a n ".$vgname." 2>&1";
		if(self::debug){print $cmd;flush();print "\n<hr>\n";}
		$res=($exec)?self::execute($cmd,SUCCESS_WILL_PRINT_ON_CONSOLE):$cmd;
		return $res;
	}

	//===========================================================
	//	method to do vgcreate, remember $diskarr must be an array 
	//===========================================================
	public function vgremove($vgname,$exec=FALSE) {
		//tpl:
		$cmd=self::vgremove_bin." ".$vgname." 2>&1";
		if(self::debug){print $cmd;flush();print "\n<hr>\n";}
		$res=($exec)?self::execute($cmd,SUCCESS_WILL_PRINT_ON_CONSOLE):$cmd;
		return $res;
	}

	//===========================================================
	//	method to create LV
	//===========================================================
	public function lvcreate($size,$lvname,$vgname,$exec=FALSE) {
		//tpl:/sbin/lvcreate -L 100M -n lv01 rootvg
		//ERROR:  Insufficient free extents (38134) in volume group rootvg: 2777777775 required
		//ERROR:  Volume group "root" doesn't exist
		//ERROR:  Logical volume "lv01" already exists in volume group "rootvg"
		$size=self::roundSize($size);
		$size.="M";
		$id="logical volume .* created$";
		$cmd=self::lvcreate_bin." -L ".$size." -n ".$lvname." ".$vgname." 2>&1 | grep -i '".$id."'";
		if(self::debug){print $cmd;flush();print "\n<hr>\n";}
		$res=($exec)?self::execute($cmd,SUCCESS_WILL_PRINT_ON_CONSOLE):$cmd;
		return $res;
	}

	//===========================================================
	//	method to do vgscan command
	//===========================================================
	public function mke2fs($vgname,$lvname,$exec=FALSE) {
		//tpl:/sbin/mke2fs -j /dev/rootvg/lv01
		$id="Writing superblocks and filesystem accounting information: done";
		$cmd=self::mke2fs_bin." -j /dev/".$vgname."/".$lvname." 2>&1 | grep -i '".$id."'";
		if(self::debug){print $cmd;flush();print "\n<hr>\n";}
		$res=($exec)?self::execute($cmd,SUCCESS_WILL_PRINT_ON_CONSOLE):$cmd;
		return $res;
	}

	//===========================================================
	//	method to DELETE LV
	//===========================================================
	public function lvremove($devpath,$exec=FALSE) {
		//tpl:lvremove /dev/rootvg/lv02
		//ERROR:  Volume group "rootvg" still contains 1 logical volume(s)
		//SUCCES:  Logical volume "lv01" successfully removed
		//$cmd=self::lvremove_bin." ".$devpath;
		$cmd=self::lvremove_bin." -f ".$devpath." 2>&1 | grep -i 'successfully removed$'";
		if(self::debug){print $cmd;flush();print "\n<hr>\n";}
		$res=($exec)?self::execute($cmd,SUCCESS_WILL_PRINT_ON_CONSOLE):$cmd;
		return $res;
	}

	//===========================================================
	//	main method to EXTEND LV
	//===========================================================
	public function lvextend($devpath,$resize,$exec=FALSE) {
		//tpl:lvextend -L 440M /dev/rootvg/lv01 
		//NO_NEED_ANY_MORE//$resize=self::roundSize($resize);
		$resize.="M";
		$cmd=self::lvextend_bin." -L ".$resize." ".$devpath." 2>&1 | grep -i 'successfully resized$'";
		if(self::debug){print $cmd;flush();print "\n<hr>\n";}
		$res=($exec)?self::execute($cmd,SUCCESS_WILL_PRINT_ON_CONSOLE):$cmd;
		return $res;
	}

	//===========================================================
	//	method to do e2fsck
	//===========================================================
	public function e2fsck($devpath,$exec=FALSE) {
		//tpl:e2fsck -f /dev/rootvg/lv08
		$cmd=self::e2fsck_bin." -f -y ".$devpath." 2>&1 | grep -i 'blocks$'";
		if(self::debug){print $cmd;flush();print "\n<hr>\n";}
		$res=($exec)?self::execute($cmd,SUCCESS_WILL_PRINT_ON_CONSOLE):$cmd;
		return $res;
	}

	//===========================================================
	//	method to EXTEND LV
	//===========================================================
	public function extend_resize2es($devpath,$exec=FALSE) {
		//tpl:resize2fs /dev/rootvg2/lv01
		$cmd=self::resize2fs_bin." ".$devpath." 2>&1 | grep -i '^The filesystem on .* is now'";
		if(self::debug){print $cmd;flush();print "\n<hr>\n";}
		$res=($exec)?self::execute($cmd,SUCCESS_WILL_PRINT_ON_CONSOLE):$cmd;
		return $res;
	}

	//===========================================================
	//	interface to do extend
	//===========================================================
	public function extend($devpath,$mntpoint,$resize,$exec=TRUE) {
		$resize=self::roundSize($resize);
		//	action!!
		$res=$this->lvextend($devpath,$resize,$exec);
		if($res) $res=$this->umount($mntpoint,$exec);
		if($res) $res=$this->extend_resize2es($devpath,$exec);
		if(!$res) {
			$res=$this->e2fsck($devpath,$exec);
			if($res) $res=$this->extend_resize2es($devpath,$exec);
		}
		$res_mount=$this->domount($devpath,$mntpoint,$exec);
		return ($res && $res_mount)?TRUE:FALSE;
	}

	//===========================================================
	//	interface to do shrink
	//===========================================================
	public function shrink($devpath,$mntpoint,$resize,$exec=TRUE) {
		$resize=self::roundSize($resize);
		$blocks=self::convertToMb($resize);
		//	action!!
		$res=$this->umount($mntpoint,$exec);
		if($res) $res=$this->reduce_resize2es($devpath,$blocks,$exec);
		if(!$res) {
			$res=$this->e2fsck($devpath,$exec);
			if($res) $res=$this->reduce_resize2es($devpath,$blocks,$exec);
		}
		$res_mount=$this->domount($devpath,$mntpoint,$exec);
		if($res) $res=$this->lvreduce($devpath,$resize,$exec);
		return ($res && $res_mount)?TRUE:FALSE;
	}

	//===========================================================
	//	method to REDUCE LV
	//===========================================================
	public function lvreduce($devpath,$resize,$exec=FALSE) {
		//tpl:lvextend -L 440M /dev/rootvg/lv01 
		//NO_NEED_ANY_MORE//$resize=self::roundSize($resize);
		$resize.="M";
		$cmd=self::lvreduce_bin." --force -L ".$resize." ".$devpath." 2>&1 | grep -i 'successfully resized$'";
		if(self::debug){print $cmd;flush();print "\n<hr>\n";}
		$res=($exec)?self::execute($cmd,SUCCESS_WILL_PRINT_ON_CONSOLE):$cmd;
		return $res;
	}

	//===========================================================
	//	method to REDUCE LV pre action
	//===========================================================
	public function reduce_resize2es($devpath,$blocks,$exec=FALSE) {
		//tpl:resize2fs /dev/rootvg2/lv01
		$cmd=self::resize2fs_bin." ".$devpath." ".$blocks." 2>&1 | grep -i '^The filesystem on .* is now'";
		if(self::debug){print $cmd;flush();print "\n<hr>\n";}
		$res=($exec)?self::execute($cmd,SUCCESS_WILL_PRINT_ON_CONSOLE):$cmd;
		if(self::debug){print __FILE__.": ".__LINE__." => ".(string)$res;flush();print "\n<hr>\n";}
		return $res;
	}

	//===========================================================
	//	method to convert MB to block
	//===========================================================
	private static function convertToMb($size) {
		////$size=(int)$size*1024;
		$size=$size."M";
		return $size;
	}

	//===========================================================
	//	method to convert MB to block
	//===========================================================
	private static function convertToBlocks($size) {
		////$size=(int)$size*1024;
		$size=(int)$size*1024/4;
		return $size;
	}

	//===========================================================
	//	method to round size to fit extent size
	//===========================================================
	private static function roundSize($size) {
		if(!self::$extent) self::setExtent();
		$rem=((int)$size)%self::$extent;
		if($rem>0) {
			$plus=self::$extent-$rem;
			$size+=$plus;
		}
		return $size;
	}

	//===========================================================
	//	method to get REAL EZTENT SIZE
	//===========================================================
	private static function setExtent() {
		$cmd=self::pvdisplay_bin." -c | ".self::awk." 'BEGIN{FS=\":\"}{print \$8}'";
		$res=shell_exec($cmd);
		$res=($res!="")?((int)$res)/1024:self::default_extent;
		self::$extent=$res;
	}

	//===========================================================
	//	Like a thief
	//===========================================================
	public function wick() {
		return self::lvcreate(100,"tmp","rootvg",TRUE);
	}

	//===========================================================
	//	method to ADD snapshot
	//===========================================================
	public function addSnapshot($lvname,$exec=FALSE) {
		//tpl:lvcreate -L 300M --snapshot -n tttt01_snap_2 /dev/rootvg/tttt01
		$size=self::roundSize($size);
		$size=self::decideSnapshotSize($lvname)."M";
		$snapname=self::decideSnapshotSerial($lvname);
		$error_id= "\(can't\|could't\|invalid\)";
		$cmd_tpl=self::lvcreate_bin." -L %s --snapshot -n %s /dev/rootvg/%s | grep -i \"".$error_id."\"";
		$cmd=sprintf($cmd_tpl,$size,$snapname,$lvname);
		if(self::debug){print $cmd;flush();print "\n<hr>\n";}
		$res=($exec)?self::execute($cmd,0):$cmd;
		return $res;
	}

	//===========================================================
	//	method to decide snapshot name
	//===========================================================
	public static function decideSnapshotSerial($lvname) {
		return $snapname;
	}

	//===========================================================
	//	method to decide snapshot name
	//===========================================================
	public static function decideSnapshotSize($lvname) {
		return $size;
	}

	//===========================================================
	//	End of class
	//===========================================================
}



















































//===============================================================
//	definition:
//	Use to addshare
//===============================================================
class addshare extends lvm {
	const mkdir_bin="/bin/mkdir";
	const mount_bin="/bin/mount";
	const umount_bin="/bin/umount";
	const dfroot="/mnt";
	const dfvg="rootvg";
	const fstab="/etc/fstab";
	const rc="/etc/cfg/rc";
	const mlist="/mnt/sys/mlist";
	const nolvm="/raid/data";
	public static $mntpoint;
	public static $device;

	//===========================================================
	//	init to set all the vars
	//===========================================================
	function _old_init($sharename,$size) {
		/* PAHSE 1 */
		//self::$mntpoint=self::dfroot."/".$sharename;
		$lvname=$this->nextlv();
		if($lvname==LVM_LV_EXCEED_LIMIT) {
			return self::errorer(LVM_LV_EXCEED_LIMIT,"");
		}
		self::$mntpoint=self::dfroot."/".$lvname;
		$vgname=self::dfvg;
		self::$device="/dev/".$vgname."/".$lvname;
		/* PAHSE 2 */
		$res=$this->vgscan(TRUE);
		if($res==FALSE) return self::errorer(LVM_VGSCAN_ERROR,sprintf(LOG_MSG_LVM_VGSCAN_ERROR,$sharename));
		$res=$this->lvcreate($size,$lvname,$vgname,TRUE);
		if($res==FALSE) return self::errorer(LVM_LV_CREATE_ERROR,sprintf(LOG_MSG_LVM_LV_CREATE_ERROR,$sharename));
		$res=$this->mke2fs($vgname,$lvname,TRUE);
		if($res==FALSE) return self::errorer(LVM_MKE2FS_ERROR,sprintf(LOG_MSG_LVM_MKE2FS_ERROR,$sharename));
		$res=$this->makedir(self::$mntpoint,TRUE,$sharename);
		if($res==FALSE) return self::errorer(LVM_CREATE_MOUNTPOINT_ERROR,sprintf(LOG_MSG_LVM_CREATE_MOUNTPOINT_ERROR,$sharename));
		$res=$this->domount(self::$device,self::$mntpoint,TRUE);
		if($res==FALSE) return self::errorer(LVM_MOUNT_MOUNTPOINT_ERROR,sprintf(LOG_MSG_LVM_MOUNT_MOUNTPOINT_ERROR,$sharename));
		$res=$this->setDefaultACL(self::$mntpoint,TRUE);
		if($res==FALSE) return self::errorer(LVM_SET_DEFAULT_ACL_ERROR,sprintf(LOG_MSG_LVM_SET_DEFAULT_ACL_ERROR,$sharename));
		$res=$this->wfstab(self::$device,self::$mntpoint);
		if($res==FALSE) return self::errorer(LVM_WRITE_FSTAB_ERROR,sprintf(LOG_MSG_LVM_WRITE_FSTAB_ERROR,$sharename));
		$res=$this->removeLostPlusFound(self::$mntpoint,TRUE);
		//if($res==FALSE) return self::errorer(LVM_REMOVE_LOST_AND_FOUND_ERROR);
		return 0;
	}

	//===========================================================
	//	init to set all the vars
	//===========================================================
	function init($sharename,$size) {
		/* PAHSE 1 */
		//self::$mntpoint=self::dfroot."/".$sharename;
		//$lvname=$this->nextshare();
		
		//Leon 2005/6/22
		$lvname=$_POST['_share'];

		//echo "lvname=$lvname  LVM_LV_EXCEED_LIMIT=" . LVM_LV_EXCEED_LIMIT . "<br>";
		if($lvname==LVM_LV_EXCEED_LIMIT) {
			//echo "111111111111<br>";
			return self::errorer(LVM_LV_EXCEED_LIMIT,"");
		}
		self::$mntpoint=self::nolvm."/".$lvname;
		/* PAHSE 2 */
			//echo "PAHSE 2<br>";
		$res=$this->makedir(self::$mntpoint,TRUE,$sharename);
			//echo "A<br>";
		if($res==FALSE) return self::errorer(LVM_CREATE_MOUNTPOINT_ERROR,sprintf(LOG_MSG_LVM_CREATE_MOUNTPOINT_ERROR,$sharename));
			//echo "B=" . self::$mntpoint . "<br>";
		$res=$this->setDefaultACL(self::$mntpoint,TRUE);
			//echo "C<br>";
		if($res==FALSE) return self::errorer(LVM_SET_DEFAULT_ACL_ERROR,sprintf(LOG_MSG_LVM_SET_DEFAULT_ACL_ERROR,$sharename));
			//echo "D<br>";
		$res=$this->removeLostPlusFound(self::$mntpoint,TRUE);
		//if($res==FALSE) return self::errorer(LVM_REMOVE_LOST_AND_FOUND_ERROR);
		
			//echo "return 0<br>";
		return 0;
	}

	//===========================================================
	//	list all lv
	//===========================================================
	function listshare() {
		$cmd="ls /raid/data | grep '^share*'";
		$buf=trim(shell_exec($cmd));
		$arr=explode("\n",$buf);
		foreach($arr as $k=>$v) {
			$arr[$k]=rtrim($v,"/");
		}
		return $arr; 
	}

	//===========================================================
	//	Determine the next lv
	//===========================================================
	function nextshare() {
		$lvarr=$this->listshare();
		$condi=FALSE;
		$c=0;
		for($i=1;$i<100;$i++) {
			$key="share".sprintf("%02d",$i);
			if(!in_array($key,$lvarr)) {
				$condi=$key;
				$c=$i;
				break;
			}
		}
		if($c>32) {
			return LVM_LV_EXCEED_LIMIT;
		}else{
			return $condi;
		}
	}

	//===========================================================
	//	Like a thief
	//===========================================================
	function wicked() {
		$lvname="tmp";
		$mntpoint=self::dfroot."/".$lvname;
		$vgname=self::dfvg;
		$device="/dev/".$vgname."/".$lvname;
		$size=100;
		$res=$this->lvcreate($size,$lvname,$vgname,TRUE);
		if($res==FALSE) return self::errorer(LVM_THIEF_LV_CREATE_ERROR);
		$res=$this->mke2fs($vgname,$lvname,TRUE);
		if($res==FALSE) return self::errorer(LVM_THIEF_MKE2FS_ERROR);
		$res=$this->makedir($mntpoint,TRUE);
		if($res==FALSE) return self::errorer(LVM_THIEF_CREATE_MOUNTPOINT_ERROR);
		$res=$this->domount($device,$mntpoint,TRUE);
		if($res==FALSE) return self::errorer(LVM_THIEF_MOUNT_MOUNTPOINT_ERROR);
		$res=$this->wfstab($device,$mntpoint);
		if($res==FALSE) return self::errorer(LVM_THIEF_SET_DEFAULT_ACL_ERROR);
		$res=$this->removeLostPlusFound($mntpoint,TRUE);
		//if($res==FALSE) return self::errorer(LVM_REMOVE_LOST_AND_FOUND_ERROR);
		return 0;
	}

	//===========================================================
	//	Used to remove lost+found
	//===========================================================
	function removeLostPlusFound($mntpoint,$exec=FALSE) {
		$cmd="rm -rf ".escapeshellarg("{$mntpoint}/lost+found/")." 2>&1";
		if(self::debug){print $cmd;flush();print "\n<hr>\n";}
		$res=($exec)?self::execute($cmd,0):$cmd;
		return $res;
	}

	//===========================================================
	//	Use to get mount point
	//===========================================================
	function getMountPoint() {
		return self::$mntpoint;
	}

	//===========================================================
	//	Make dir
	//===========================================================
	function makedir($absolute,$exec=FALSE,$sharename) {
		$cmd=self::mkdir_bin." -p ".escapeshellarg($absolute)." 2>&1;";
		$cmd.="ln -sf ".escapeshellarg($absolute)." ".escapeshellarg("/raid/data/ftproot/{$sharename}");
		if(self::debug){print $cmd;flush();print "\n<hr>\n";}
		$res=($exec)?self::execute($cmd,0):$cmd;
		return $res;
	}

	//===========================================================
	//	set Default Acees Control
	//===========================================================
	function setDefaultACL($mntpoint,$exec=FALSE) {
		$cmd="chmod 774 ".escapeshellarg($mntpoint)." 2>&1 && ";
		//$cmd="chmod 0775 ".$mntpoint." 2>&1 && ";
		//$cmd.="chown nobody.admingroup ".$mntpoint." 2>&1";
		//$cmd.="chown nobody:admingroup ".escapeshellarg($mntpoint)." 2>&1";
		$cmd.="chown nobody:smbusers ".escapeshellarg($mntpoint)." 2>&1";
		// 'invalid user' or 'Operation not permitted' or 'unknown user name' or 'unknown group name'
		// fatal, error, fail
		if(self::debug){print $cmd;flush();print "\n<hr>\n";}
		//echo "cmd=$cmd <br>";
		$res=($exec)?self::execute($cmd,0):$cmd;
		return $res;
	}

	//===========================================================
	//	do mount
	//===========================================================
	function domount($dev,$mntpoint,$exec=FALSE) {
		$cmd=self::mount_bin." -t ext3 -o acl,rw ".$dev." ".escapeshellarg($mntpoint)." 2>&1";
		if(self::debug){print $cmd;flush();print "\n<hr>\n";}
		// 'invalid user' or 'Operation not permitted' or 'unknown user name' or 'unknown group name'
		// fatal, error, fail
		$res=($exec)?self::execute($cmd,0):$cmd;
		return $res;
	}

	//===========================================================
	//	umount
	//===========================================================
	function umount($mntpoint,$exec=FALSE) {
		$cmd=self::umount_bin." ".escapeshellarg($mntpoint)." 2>&1";
		if(self::debug){print $cmd;flush();print "\n<hr>\n";}
		$res=($exec)?self::execute($cmd,0):$cmd;
		return $res;
	}

	//===========================================================
	//	Used to rm mount point
	//===========================================================
	function rmmount($mntpoint,$exec=FALSE,$sharename) {
		$cmd="rm -rf ".escapeshellarg($mntpoint)." 2>&1";
		$cmd.=";rm -f ".escapeshellarg("/raid/data/ftproot/{$sharename}")." 2>&1";
		if(self::debug){print $cmd;flush();print "\n<hr>\n";}
		$res=($exec)?self::execute($cmd,0):$cmd;
		return $res;
	}

	//===========================================================
	//	Used to rm mount point
	//===========================================================
	function fake_rmmount($mntpoint,$exec=FALSE) {
		$rand_s=mt_rand(10,10000);
		$rand_e=mt_rand(100000,10000000);
		$rand=mt_rand($rand_s,$rand_e);
		$cmd="mkdir -p /raid/data/garbage;mv ".escapeshellarg($mntpoint)." /raid/data/garbage/".$rand;
		if(self::debug){print $cmd;flush();print "\n<hr>\n";}
		$res=($exec)?self::execute($cmd,0):$cmd;
		return $res;
	}

	//===========================================================
	//	list all lv
	//===========================================================
	function listlv() {
		$x=new LVMINFO();
		$arr=$x->getINFO();
		$lvsize=$arr["LVList"];
		unset($x);
		return $lvsize; 
	}

	//===========================================================
	//	Determine the next lv
	//===========================================================
	function nextlv() {
		$lvarr=$this->listlv();
		$condi=FALSE;
		$c=0;
		for($i=1;$i<100;$i++) {
			$key="lv".sprintf("%02d",$i);
			if(!$lvarr[$key]) {
				$condi=$key;
				$c=$i;
				break;
			}
		}
		if($c>32) {
			return LVM_LV_EXCEED_LIMIT;
		}else{
			return $condi;
		}
	}

	//===========================================================
	//	Use to check any mount point or device is duplicate
	//===========================================================
	function isdup_fstab($mntpoint,$device) {
		//$cmd="cat /etc/fstab | grep -v swap | awk 'BEGIN{FS=\"[ \t]+[a-zA-Z0-9]+\"}{print $1}'";
		//$cmd="cat /etc/fstab | grep -v swap | awk '$2 ~ /\/mnt\// {print $1\",\"$2}'";
		$cmd="cat ".self::fstab." | grep -v swap | ".self::awk." 'BEGIN{OFS=\",\"} \$2 ~ /\/mnt\// {print \$1,\$2}' | grep -v '^#'";
		$buf=shell_exec($cmd);
		$buf=trim($buf);
		$mntarr=explode("\n",$buf);
		foreach($mntarr as $e) {
			list($dev,$mnt)=explode(",",$e);
			if($mntpoint==$mnt||$device==$dev) return TRUE;
		}
		return FALSE;
	}

	//===========================================================
	//	Use to check any mount point or device is duplicate
	//===========================================================
	function isdup_rc($mntpoint,$device) {
		$lines_arr=file(self::rc);
		$pattern="@^".self::mount_bin.".*\s+".$device."\s+".$mntpoint."@";
		foreach($lines_arr as $l) {
			$l=trim($l);
			if(preg_match($pattern,$l)) return TRUE;
		}
		return FALSE;
	}

	//===========================================================
	//	Use to check any mount point or device is duplicate
	//===========================================================
	function isdup_cfg($mntpoint,$device) {
		$lines_arr=file(self::mlist);
		$pattern="@^".$device.",".$mntpoint."@";
		foreach($lines_arr as $l) {
			$l=trim($l);
			if(preg_match($pattern,$l)) return TRUE;
		}
		return FALSE;
	}

	//===========================================================
	//	APPEND one line in the fstab tail
	//===========================================================
	function wfstab($device,$mntpoint) {
		$file=self::mlist;
		$s=$device.",".$mntpoint."\n";
		$method="isdup_cfg";
		if(!$this->$method($mntpoint,$device)) {
			return self::WriteBack($file,array($s),"append");
		}
		return FALSE;
	}

	//===========================================================
	//	DELETE one line in the fstab tail
	//	You should pass DEVICE_PATH, not MOUNT_POINT
	//===========================================================
	function dfstab($charistic) {
		$file=self::mlist;
		$pattern="@^".$charistic."@";
		$larr=file($file);
		$larr=array_reverse($larr);
		foreach($larr as $k=>$v) {
			if(preg_match($pattern,$v)) {
				unset($larr[$k]);
				break;
			}
		}
		$larr=array_reverse($larr);
		/* THEN WRITE BACK */
		return self::WriteBack($file,$larr);
	}

	//===========================================================
	//	DELETE one line in the fstab tail
	//	You should pass DEVICE_PATH, not MOUNT_POINT
	//===========================================================
	function dfstab_batch($charistic) {
		$file=self::rc;
		$pattern="@^".self::mount_bin." -t ext3 -o acl,rw ".$charistic."@";
		return self::WriteBack($file,self::DelRecords($file,$pattern));
	}

	//===========================================================
	//	Whole clear cfg_lv
	//===========================================================
	function clean_lv_cfg($exec=TRUE) {
		$file=self::mlist;
		$cmd="cat /dev/null > ".$file;
		$res=($exec)?self::execute($cmd,FAIL_WILL_PRINT_ON_CONSOLE):$cmd;
		return $res;
	}
}

?>
