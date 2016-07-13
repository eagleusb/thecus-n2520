#!/bin/sh

#===================================================
#    Varable Defined
#===================================================
ConfDb="/etc/cfg/conf.db"
Sqlite="/opt/bin/sqlite" 
PYTHON="/usr/bin/python"
thumbnail_python="/img/bin/thumbnail.py"

#################################################
##       Function Define
#################################################
check_raid(){
    sys_path=`/bin/ls -l /raid/sys | awk -F' ' '{printf $11}'`
    data_path=`/bin/ls -l /raid/data | awk -F' ' '{printf $11}'`
    if [ "$sys_path" == "" ] || [ "$data_path" == "" ];
    then
        echo "Your Master RAID link is not exist"
        exit 1
    fi
}

check_env(){

    ## Check sysconf
    thumbnail_conf=`/img/bin/check_service.sh thumbnail`
    [ "${thumbnail_conf}" == "0" ] && exit 0

    ## Check RAID
    check_raid
}

find_graph_ext(){
    path="$1"

    cd "${path}"
    find . -maxdepth 1 \( -iname '*.jpg' -o  -iname '*.bmp' -o -iname '*.jpeg' -o -iname '*.gif' -o -iname '*.png' -o -iname '*.tif' -o -iname '*.tiff' \) -type f | grep -v '/\.' | awk -F './' '{print $2}'
}

get_one_conf_data(){
    local fField="$1"
    local fDefVal="$2"
    local fVal            #field value
    local fCount=`${Sqlite} ${ConfDb} "select count(v) from conf where k='${fField}'"` #match field count

    if [ "${fCount}" == "0" ];then
        fVal="${fDefVal}"
    else
        fVal=`${Sqlite} ${ConfDb} "select v from conf where k='${fField}'"`
    fi
    echo "${fVal}"
}

scan_thumbnail(){

    local source_folder="$1"
    local lock_file="${source_folder}/.thumbnail.lock"

    ## Check source folder is exist?
    [ ! -d "${source_folder}" ] && exit 1

    ## Get thumbnail DB conf
    thumbnail_enable=`get_one_conf_data "thumbnail" "1"`
    ## Check thumbnail service enable
    [ "${thumbnail_enable}" == "0" ] && exit 0

    ## Check is other process are access the same folder
    [ -f "${lock_file}" ] && exit 0
    ## Else create lock_file
    touch ${lock_file}

    ## Start produce thumbnail
    local tmp_dir="${source_folder}/.thumbnail"
    local old_list="${source_folder}/.thumbnail_old"
    local new_list="${source_folder}/.thumbnail_new"
    local add_list="${source_folder}/.thumbnail_add"
    local del_list="${source_folder}/.thumbnail_del"

    ## Get current grahp file list
    find_graph_ext "${source_folder}" | sort > "${new_list}"

    ## Already make thumbnail before
    if [ -d "${tmp_dir}" ];then
        find_graph_ext "${tmp_dir}" | sort > "${old_list}"
        ## (1) Find new grapg files
        diff "${new_list}" "${old_list}" | grep "^<" | sed 's/^< //g'  > "${add_list}"
        cat "${add_list}" | while read filename;
        do
            [ -f "${source_folder}/${filename}" ] && ${PYTHON} ${thumbnail_python} "${source_folder}/${filename}" 
        done
        ## (2) Remove not exist files
        diff "${new_list}" "${old_list}" | grep "^>" | sed 's/^> //g'  > "${del_list}"
        cat "${del_list}" | while read filename;
        do
            rm -f "${tmp_dir}/${filename}"
        done
        ## (3) Find modified graph files
    ## Never make thumbnail , 
    else
        cat "${new_list}" | while read filename;
        do
            ${PYTHON} ${thumbnail_python} "${source_folder}/${filename}"
        done
    fi

    ## Del unused files at the end
    rm -f "${lock_file}" "${old_list}" "${new_list}" "${add_list}" "${del_list}"
}

clean_thumbnail(){

    ## Get mdlist
    local md_list=`cat /proc/mdstat | awk '/^md6[0-9] :/{print substr($1,3)}' | sort -u`
    if [ "${md_list}" == "" ];then
        md_list=`cat /proc/mdstat | awk -F: '/^md[0-9] :/{print substr($1,3)}' | sort -u`
    fi

    for md in $md_list;
    do
        if [ -d "/raid$md/" ];then
            find "/raid$md/data" -iname ".thumbnail" -type d -exec rm -rf {} \;
        fi
    done
}


#################################################
##      Main code
#################################################
check_env

case "$1"
in
    scan)
        scan_thumbnail "$2"
        ;;
    clean)
        clean_thumbnail
        ;;
    *)
        echo "Usage :"
        echo "   scan : $0 sacn [Folder Name]"
        echo "  clean : $0 clean"
        ;;
esac

