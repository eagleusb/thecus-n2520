#!/bin/sh

if [ -d /raid/sys ]; then
    db=/raid/sys/history.db
elif [ -d /raidsys/0 ]; then
    db=/raidsys/0/history.db
else
    exit 0
fi

sqlite=/usr/bin/sqlite
TT=(`date "+%Y %m %d %H"`)
YY=${TT[0]}
MM=${TT[1]}
DD=${TT[2]}
HH=${TT[3]}
nowHour="$YY-$MM-$DD $HH:00"
nowDay="$YY-$MM-$DD 00:00"
nowMonth="$YY-$MM-01 00:00"

initial(){
    echo "BEGIN TRANSACTION;"
    echo "CREATE TABLE h (t TIMESTAMP, k STRING, v FLOAT);"
    echo "CREATE INDEX hidx ON h(t,k);"
    echo "CREATE TABLE ht (t TIMESTAMP, k STRING, v FLOAT);"
    echo "CREATE TABLE d (t TIMESTAMP, k STRING, v FLOAT);"
    echo "CREATE INDEX didx ON d(t,k);"
    echo "CREATE TABLE dt (t TIMESTAMP, k STRING, v FLOAT);"
    echo "CREATE TABLE m (t TIMESTAMP, k STRING, v FLOAT);"
    echo "CREATE INDEX midx ON m(t,k);"
    echo "CREATE TABLE mt (t TIMESTAMP, k STRING, v FLOAT);"
    echo "COMMIT;"
}

if [ ! -f $db ]; then
    initial | $sqlite $db
fi

compute(){
    ## Read all data into memory
    i=0
    while read line && [[ "$line" ]]
    do
        input[$i]=$line
        i=$(($i+1))
    done
    unset line
    
    if [ ${#input[*]} -eq 0 ]; then
        exit 1
    fi
    
    ## Read all SQLite result to hash
    i=0
    hts=(`$sqlite $db "select strftime('%Y-%m-%d-%H',t), k, v from ht"`)
    while [ $i -lt ${#hts[*]} ]
    do
        ts=(`echo ${hts[$i]} | sed 's/[-|]/ /g'`)
        eval `echo HTS_${ts[4]}=${ts[5]}`
        i=$(($i+1))
    done
    
    echo "BEGIN TRANSACTION;"
    
    sqlHour="${ts[0]}-${ts[1]}-${ts[2]} ${ts[3]}:00"
    if [ "$sqlHour" != "$nowHour" ]; then
        echo "DELETE FROM ht WHERE k = 'c';"
        echo "INSERT INTO h SELECT * FROM ht;"
        echo "DELETE FROM ht;"
    fi
    
    sqlDay="${ts[0]}-${ts[1]}-${ts[2]} 00:00"
    if [ "$sqlDay" != "$nowDay" ]; then
        echo "DELETE FROM dt WHERE k = 'c';"
        echo "INSERT INTO d SELECT * FROM dt;"
        echo "DELETE FROM dt;"
    else
        i=0
        dts=(`$sqlite $db "select k, v from dt"`)
        while [ $i -lt ${#dts[*]} ]
        do
            ds=(`echo ${dts[$i]} | sed 's/[|]/ /g'`)
            eval `echo DTS_${ds[0]}=${ds[1]}`
            i=$(($i+1))
        done
        unset ds
        unset i
    fi
    
    sqlMonth="${ts[0]}-${ts[1]}-01 00:00"
    if [ "$sqlMonth" != "$nowMonth" ]; then
        echo "DELETE FROM mt WHERE k = 'c';"
        echo "INSERT INTO m SELECT * FROM mt;"
        echo "DELETE FROM mt;"
        
        ## Remove all data over 1 year
        echo "DELETE FROM h WHERE date(t, '+1 years') < date('$YY-$MM-01');"
        echo "DELETE FROM d WHERE date(t, '+1 years') < date('$YY-$MM-01');"
        echo "DELETE FROM m WHERE date(t, '+1 years') < date('$YY-$MM-01');"
    else
        i=0
        mts=(`$sqlite $db "select k, v from mt"`)
        while [ $i -lt ${#mts[*]} ]
        do
            ms=(`echo ${mts[$i]} | sed 's/[|]/ /g'`)
            eval `echo MTS_${ms[0]}=${ms[1]}`
            i=$(($i+1))
        done
        unset ms
        unset i
    fi
    
    unset ts
    unset hts
    
    ## Computing
    i=0
    while [ $i -lt ${#input[*]} ]
    do
        is=(${input[$i]})
        k=${is[0]}
        kv=`echo ${is[1]} | awk '{printf("%.1f",$1)}'`
        hv=`eval echo '$HTS_'$k`
        hc=`eval echo '$HTS_c'`
        if [ "$sqlHour" != "$nowHour" -o "$hv" == "" ]; then
            hv=$kv
            echo "INSERT INTO ht VALUES('$nowHour', '$k', $hv);"
            if [ $i -eq 0 ]; then
                echo "INSERT INTO ht VALUES('$nowHour', 'c', 1);"
            fi
        else
            hv=`echo $kv $hv $hc | awk '{printf("%.1f", ($1 + $2 * $3) / ($3 + 1))}'`
            hc=`echo $hc | awk '{printf("%d", ($1+1))}'`
            echo "UPDATE ht SET v = $hv WHERE k = '$k';"
            echo "UPDATE ht SET v = $hc WHERE k = 'c';"
        fi
        
        dv=`eval echo '$DTS_'$k`
        dc=`eval echo '$DTS_c'`
        if [ "$dv" == "" ]; then
            dv=$kv
            echo "INSERT INTO dt VALUES('$nowHour', '$k', $dv);"
            if [ $i -eq 0 ]; then
                echo "INSERT INTO dt VALUES('$nowHour', 'c', 1);"
            fi
        else
            dv=`echo $kv $dv $dc | awk '{printf("%.1f", ($1 + $2 * $3) / ($3 + 1))}'`
            dc=`echo $dc | awk '{printf("%d", ($1+1))}'`
            echo "UPDATE dt SET v = $dv WHERE k = '$k';"
            echo "UPDATE dt SET v = $dc WHERE k = 'c';"
        fi
        
        mv=`eval echo '$MTS_'$k`
        mc=`eval echo '$MTS_c'`
        if [ "$mv" == "" ]; then
            mv=$kv
            echo "INSERT INTO mt VALUES('$nowHour', '$k', $mv);"
            if [ $i -eq 0 ]; then
                echo "INSERT INTO mt VALUES('$nowHour', 'c', 1);"
            fi
        else
            mv=`echo $kv $mv $mc | awk '{printf("%.1f", ($1 + $2 * $3) / ($3 + 1))}'`
            mc=`echo $mc | awk '{printf("%d", ($1+1))}'`
            echo "UPDATE mt SET v = $mv WHERE k = '$k';"
            echo "UPDATE mt SET v = $mc WHERE k = 'c';"
        fi
        
        i=$(($i+1))
    done
    
    echo "COMMIT;"
}
#compute
cmd=`compute`
echo "$cmd" | $sqlite $db

exit 1
