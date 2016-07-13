#!/bin/sh
PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"
get_progress(){
  file=$1
  if [ -f "${file}" ];then
    sed -r '$!N;$!D;s/|\n/-->/g;s/-->$/\n/g;s/-->.*-->//g;s/( [0-9]*) *([0-9]*%)/\1(Bytes) \2/g' "${file}"
  fi
}

get_local_progress(){
  file=$1
  if [ -f "${file}" ];then
     info=`tail -10 "$file"`
#    tail -10 "$1" | sed -r '$!N;$!D;s/|\n/-->/g;s/-->$/\n/g;s/-->.* to-check=(.*)\).*-->/ files_count:\1 /g;s/( [0-9]*) *([0-9]*%)/\1(Bytes) \2/g'
     count=`echo -e "$info" | awk '/ to-check=/{print NR}' | tail -1`
     if [ "$count" != "" ];then
#         echo -e "$info" | awk '{if(NR=="'$count'") printf("%s(Bytes) %s %s %s <br>",$5,$6,$7,$8)}'
         echo -e "$info" | awk '{if(NR=="'$(($count-1))'") print $0}'
         echo -e "$info" | awk '{if(NR=="'$count'") printf("<br>%s(Bytes) %s %s %s <br>",$(NF-5),$(NF-4),$(NF-3),$(NF-2))}'
         count1=`echo -e "$info" | awk -F'xfer#' '{if(NR=="'$count'") print $2}' | awk '{print substr($1,0,length($1)-1)}'`
         count2=`echo -e "$info" | awk -F'to-check=' '{if(NR=="'$count'") print $2}' | awk -F'/' '{print substr($2,0,length($2-1))}'`
         echo "file count : ${count1}/${count2}"
     else
         echo -e "${info}" |sed -r '$!N;$!D;s/|\n/-->/g;s/-->$/\n/g;s/-->.*-->//g;s/( [0-9]*) *([0-9]*%)/\1(Bytes) \2/g' "${file}"
     fi
  fi 
}

case "$1" in
  get_progress)
    get_progress $2
    ;;
  get_local_progress)
    get_local_progress $2
    ;;
  *)
    echo "Usage: {get_progress}" >&2
    exit 1
  ;;
esac


