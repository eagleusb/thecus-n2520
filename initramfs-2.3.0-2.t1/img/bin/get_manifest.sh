#!/bin/sh
. /img/bin/functions

init_env(){
    mountpath="/mnt"
    d_conf="${mountpath}/d_conf"
    MANIFEST="manifest.txt"
    VERSION="version"
    tmprpm="/dev/shm/rpm"

    # get BOODEV, OS_RPMS, OS_FLAGS parameters by get_nvm_device()
    get_nvm_device
}

get_manifest(){
    if [ ! -d "${mountpath}" ];then
        mkdir ${mountpath}
    fi

    if [ -n "${OS_RPMS}" ];then
        /bin/mount -o ro -t $NVM_FS ${OS_RPMS} ${mountpath}
        if [ -f ${d_conf}/${MANIFEST} ] && [ -f ${d_conf}/${VERSION} ] && [ -d ${d_conf}/conf ];then
            cp ${d_conf}/${MANIFEST} /etc/
            cp ${d_conf}/${VERSION} /etc/
            cp -rf ${d_conf}/conf /img/bin/
        else
            /bin/mount -o remount,rw ${OS_RPMS} ${mountpath}
            /img/bin/gen_chroot.sh ${tmprpm} create

            MODEL_CONF=`ls ${mountpath}/nas_*-conf-*.rpm`
            if [ -n "${MODEL_CONF}" ];then
                rpm -ivh -r ${tmprpm} --nodeps ${MODEL_CONF}
            else
                rpm -ivh -r ${tmprpm} --nodeps ${mountpath}/nas_img-bin-*.rpm
            fi

            rpm -ivh -r ${tmprpm} --nodeps ${mountpath}/fwver-*.rpm
            model=`cat /proc/thecus_io | awk '/MODELNAME/{print $2}'`

            if [ ! -d "${d_conf}" ];then
                mkdir -p "${d_conf}"
            fi
            cp ${tmprpm}/img/bin/default_cfg/${model}/etc/${MANIFEST} /etc
            cp ${tmprpm}/img/bin/default_cfg/${model}/etc/${MANIFEST} ${d_conf}
            cp -rf ${tmprpm}/img/bin/conf /img/bin
            cp -rf ${tmprpm}/img/bin/conf ${d_conf}
            cp ${tmprpm}/etc/${VERSION} /etc
            cp ${tmprpm}/etc/${VERSION} ${d_conf}
            sync
            /img/bin/gen_chroot.sh ${tmprpm} clean
        fi
        umount ${mountpath}
    fi
}

init_env
get_manifest
