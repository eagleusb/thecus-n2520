#!/bin/sh
init_env(){
    PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"
    . /img/bin/function/stamps.list

    act="$1"
    interval=30
    try_count=0    
    pidfile_n="/tmp/pidfile_n"
    pidfile_o="/tmp/pidfile_o"
    monitor_pid=""

	[ "${act}" == "shutdown" ] &&\
		SHUTDOWN_CMD="poweroff" || SHUTDOWN_CMD="reboot"

    shutdown_para=""
    if [ "`/sbin/reboot --help 2>&1 | grep BusyBox`" == "" ];then
        shutdown_para="-n -d --no-wall"
    fi
}

pid_rc(){
    rc_list="`ps | grep '[/]img/bin/rc/rc.' | grep -v 'rc.pkg' | grep -v 'rc.module' | awk '{print $1}'`"
    if [ "${rc_list}" != "" ];then
        echo "${rc_list}"     
    fi
    
    opt_list="`ps | grep '[/]opt' | grep 'shell/module.rc stop' | awk '{print $1}'`"
    if [ "${opt_list}" != "" ];then
        echo "${opt_list}"     
    fi

    mod_list="`ps | grep '[/]raid/data/module/cfg/module.rc/' | grep 'rc stop' | awk '{print $1}'`"
    if [ "${mod_list}" != "" ];then
        echo "${mod_list}"     
    fi
}

kill_pid(){
    try_count=0
    pid_o="`cat ${pidfile_o}`"
    cat ${pidfile_n} | \
    while read pid
    do
        pid_exist=`echo ${pid_o} | grep "^${pid}"`
        if [ "${pid_exist}" != "" ];then
            if [ "${pid}" != "${monitor_pid}" ];then
                monitor_pid="${pid}"   
            fi
            
            try_count=$((${try_count} + 1))
            case "${try_count}" in
                "1")
                    kill -15 ${pid}
                    ;;
                "2")
                    kill -9 ${pid}
                    ;;
                "3")
                    eval $SHUTDOWN_CMD -f ${shutdown_para}
                    ;;
            esac
            
            return
        fi
    done    
}

main(){
    sleep 15
    while [ 1 ]
    do
        pid_rc > ${pidfile_n}
        
        if [ "`cat ${pidfile_n}`" == "" ] && [ "`ps | grep '[/]img/bin/service stop'`" == "" ];then
            while [ ! -f "/tmp/sysdown" ] && [ -f "/var/lock/upgrade.lock" ]
            do
                sleep 5
            done

            # Set timeout as 2min for waiting shutdown processes.
            # DO NOT use 'sleep 120' directly to avoid sleep process
            # preempting problem on single core environment.
            for x in `seq 1 120`;do
                sleep 1
            done
            # if RAID has not stopped after 2min, means we need force
            # to shutdown.
            [ ! -f "$STAMP_RAID_STOP" ] &&\
                eval $SHUTDOWN_CMD -f ${shutdown_para}
        fi    
        
        kill_pid
        mv ${pidfile_n} ${pidfile_o}
        sleep ${interval} 
    done   
}

init_env "$1"
main
