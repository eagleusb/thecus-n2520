#!/bin/sh
 
MODELNAME=`awk '/^MODELNAME/{print $2}' /proc/thecus_io`
traycount=`awk '/^MAX_TRAY/{print $2}' /proc/thecus_io`

clearvar() {
	MAXVAR=$1
	varindex=1
	while [ $varindex -le $MAXVAR ]
	do
		VARLIST[$varindex]="_"
		varindex=$[varindex+1]
	done
}

##Fail , will set var to index number
setvar() {
	varindex=$1
	varvalue=$2
	VARLIST[$varindex]=$varvalue
}

dumpvar() {
	MAXVAR=$1
	varindex=1
	strvar=""
	while [ $varindex -le $MAXVAR ]
	do
		thevar=${VARLIST[$varindex]}
		strvar="$strvar$thevar"
		varindex=$[varindex+1]
	done
	echo "$strvar"
}

talktolcm() {
  /img/bin/pic.sh LCM_MSG "" "$1"
}

function disk_check(){
  talktolcm "HD I/O Test"
  disk_list=`cat /proc/scsi/scsi|awk  '/Thecus:/{FS=" ";printf("%s:%s\n",$2,$3)}'|awk -F: '{if (($2<='${traycount}')&&($2>0)) {printf("%d,",$2)}}'`
  disks=`cat /proc/scsi/scsi|awk  '/Thecus:/{FS=" ";printf("%s:%s\n",$2,$3)}'|awk -F: '{if (($2<='${traycount}')&&($2>0)) {printf("%d\n",$2)}}'|wc -l|awk '{printf("%d\n",$1)}'`
  if [ $disks -eq "$traycount" ];
  then
    scantray=1
    while [ $scantray -le $traycount ]
    do
      echo "S_LED ${scantray} 2" > /proc/thecus_io
      strExec="cat /proc/scsi/scsi | awk -F: '/Tray:${scantray} /&&/Model/{print substr(\$5,0,length(\$5)-3)}' | awk -F' ' '{print \$1}'"
      HD_Model=`eval "$strExec"`
      talktolcm "HD[${scantray}] ${HD_Model} Pass"
      setvar ${scantray} "0"
      scantray=$[scantray+1]
      sleep 1
    done
  else
    scantray=1
    while [ $scantray -le $traycount ]
    do
      echo "S_LED ${scantray} 2" > /proc/thecus_io
      strExec="cat /proc/scsi/scsi|awk  '/Thecus:/&&/Tray:$scantray /'|wc -l"
      ddisk=`eval "$strExec"`
      if [ $ddisk -eq 0 ];
      then
        talktolcm "HD[${scantray}] FAIL"
        setvar ${scantray} "_"
      else
        strExec="cat /proc/scsi/scsi | awk -F: '/Tray:${scantray} /&&/Model/{print substr(\$5,0,length(\$5)-3)}' | awk -F' ' '{print \$1}'"
        HD_Model=`eval "$strExec"`
        talktolcm "HD[${scantray}] ${HD_Model} PASS"
        if [ ${scantray} -lt 10 ];
        then
          setvar ${scantray} "${scantray}"
        else
          setvar ${scantray} "`expr ${scantray} - 10`"
        fi
      fi
      scantray=$[scantray+1]
      sleep 1
    done
    talktolcm "HD I/O Test Fail"
  fi
}

i=0
while [ $i != $MAX_TRAY ]
do
  i=`expr $i + 1`
  sleep 1
  echo "S_LED ${i} 2" > /proc/thecus_io
done

echo "Buzzer 1" > /proc/thecus_io
sleep 1
echo "Buzzer 0" > /proc/thecus_io
clearvar $traycount
disk_check
echo "Buzzer 1" > /proc/thecus_io
sleep 5
echo "Buzzer 0" > /proc/thecus_io
RVAR=`dumpvar $traycount`
talktolcm "HD info: $RVAR"

