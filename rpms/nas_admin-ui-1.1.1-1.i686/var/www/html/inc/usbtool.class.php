<?
//"provide disk information"
class USBTOOL {
	function ejectusb($usbdisk) {
		$usbdisk="sd" . $usbdisk;
		$strexec="/img/bin/eject_usb.sh $usbdisk >/dev/null 2>&1";
		exec($strexec,$out,$eject_ret);
		$strExec="sleep 2";
		shell_exec($strExec);
		return $eject_ret;
	}
}
?>
