#!/bin/sh
DUAL_DOM_FLAG_DIR=/tmp/dual_dom_logfs
DUAL_DOM_FLAG_FILE=$DUAL_DOM_FLAG_DIR/dual_dom
FACTORY_FLAG_FILE=$DUAL_DOM_FLAG_DIR/FACTORY
DOM_B_DD_FLAG_FILE=$DUAL_DOM_FLAG_DIR/DOMB_DD_FLAG
DOM_B_CMD=`cat /proc/partitions |grep sdaab`
CONTANT=""
DIR_FLAG=""
DIRTY_FLAG=""
FACTORY_FLAG=""
HDB2_MOUNT_FLAG=`mount |grep sdaab2`
i=0

if [ ! -d $DUAL_DOM_FLAG_DIR ]; then
    mkdir $DUAL_DOM_FLAG_DIR
else
    DIR_FLAG=1;
fi

if [ -n "$DOM_B_CMD" ] && [ -z "$HDB2_MOUNT_FLAG" ]; then
    mount /dev/sdaab2 $DUAL_DOM_FLAG_DIR -o rw,noatime > /dev/null 2>&1
else 
    if [ -z $DIR_FLAG ]; then
        rm -rf $DUAL_DOM_FLAG_DIR
    fi
    exit 1
fi

if [ ! -e $DUAL_DOM_FLAG_FILE ]; then
    touch $DUAL_DOM_FLAG_FILE
fi

DIRTY_FLAG=`cat $DUAL_DOM_FLAG_FILE | cut -b 1`
FACTORY_FLAG=`cat $DUAL_DOM_FLAG_FILE | cut -b 2`

if [ "set" = "$1" ] || [ "SET" = "$1" ]; then
    if [ "dirty" = "$2" ] || [ "DIRTY" = "$2" ]; then
        if [ "0" = "$3" ] || [ "1" = "$3" ]; then
            CONTANT="$3${FACTORY_FLAG}"
            
            if [ "0" = "$3" ] && [ -e $DOM_B_DD_FLAG_FILE ]; then
                rm -rf $DOM_B_DD_FLAG_FILE
            fi
        fi
    elif [ "factory" = "$2" ] || [ "FACTORY" = "$2" ]; then
        if [ "0" = "$3" ] || [ "1" = "$3" ]; then
            CONTANT="${DIRTY_FLAG}$3"
        fi
    fi    
    
    while [ $i -lt 1022 ];
    do
        CONTANT="${CONTANT}0"
        i=$(($i+1))
    done
    
    echo $CONTANT > $DUAL_DOM_FLAG_FILE
elif [ "get" = "$1" ] || [ "GET" = "$1" ]; then
    if [ "dirty" = "$2" ] || [ "DIRTY" = "$2" ]; then
        echo "$DIRTY_FLAG"
    elif [ "factory" = "$2" ] || [ "FACTORY" = "$2" ]; then
        echo "$FACTORY_FLAG"
    fi    
fi

sync;sync;sync

if [ -n "$DOM_B_CMD" ]; then
    umount $DUAL_DOM_FLAG_DIR
fi

if [ -z $DIR_FLAG ]; then
    rm -rf $DUAL_DOM_FLAG_DIR
fi
