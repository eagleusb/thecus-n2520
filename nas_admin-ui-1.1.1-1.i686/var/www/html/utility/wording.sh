#!/bin/sh

tables=("cz de es en fr it ja ko pl pt ru tr tw zh")
others=("eventlog ha_ctrl_tree ha_hide_tree m_cz m_de m_es m_en m_fr m_it m_ja m_ko m_pl m_pt m_ru m_tr m_tw m_zh manual_categorize treemenu treemenu_sysconfig")

sqlite="/usr/bin/sqlite"
db="/var/www/html/language/language.db"

if [ "$DB" != "" ]; then
    db=$DB
fi

mode="list"
if [ "$MODE" != "" ]; then
    mode=$MODE
fi

sql_import() {
    lines=1
    echo "BEGIN TRANSACTION;"
    while read line
    do
        if [ "$line" != "" ]; then
            unset LANG
            unset FUN
            unset VAL
            unset MSG
            LANG=(`echo "$line" | sed "s/\([^|]*\)|\([^|]*\)|\([^|]*\)|\([^|]*\)|\(.*\)/\1/g"`)
            FUN=`echo "$line" | sed "s/\([^|]*\)|\([^|]*\)|\([^|]*\)|\([^|]*\)|\(.*\)/\3/g"`
            VAL=`echo "$line" | sed "s/\([^|]*\)|\([^|]*\)|\([^|]*\)|\([^|]*\)|\(.*\)/\4/g"`
            MSG=`echo "$line" | sed "s/\([^|]*\)|\([^|]*\)|\([^|]*\)|\([^|]*\)|\(.*\)/\5/g"`
            MSG=`echo "$MSG" | sed "s/'/''/g"`
            
            if [ "$LANG" == "all" ]; then
                LANG=(${tables[@]})
            fi
            
            if [ "$FUN" == "" ] && [ "$VAL" == "" ]; then
                echo "(Error)Line:$lines > $line" >&2
                exit 1
            fi
    
            for L in "${LANG[@]}"; do
                echo "INSERT INTO $L VALUES('', '$FUN', '$VAL', '$MSG');"
            done
        fi
        lines=`expr $lines + 1`
    done
    echo "COMMIT;"
}

import() {
    if [ $# -ne 2 ]; then
        echo "Usage: $0 import [dat|sql] [file]"
        exit 1
    fi

    if [ "$1" != "dat" ] && [ "$1" != sql ]; then
        echo "Usage: $0 import [dat|sql] [file]"
        exit 1
    fi

    if [ $1 == "dat" ]; then
        sql_import < $2 | $sqlite $db
    fi
    
    if [ $1 == "sql" ]; then
        $sqlite $db ".read $2"
    fi
}

sql_insert() {
    LANG=($LANG)
    echo "BEGIN TRANSACTION;"
    for L in "${LANG[@]}"; do
        echo "INSERT INTO $L VALUES('', '$FUN', '$VAL', '$MSG');"
    done
    echo "COMMIT;"
}

insert(){
    echo ""
    if [ $# -ne 4 ]; then
        echo "Usage: $0 insert [language] [function] [value] [msg]"
        exit 1
    fi

    export LANG=$1
    if [ "$1" == "all" ]; then
        export LANG=${tables[@]}
    fi

    export FUN=$2
    export VAL=$3
    export MSG=`echo $4 | sed "s/'/''/g"`

    sql_insert | $sqlite $db
    sql_query | $sqlite $db
}

sql_delete() {
    LANG=($LANG)
    echo "BEGIN TRANSACTION;"
    for L in "${LANG[@]}"; do
        echo "DELETE FROM $L WHERE $L.function LIKE '$FUN' AND $L.value LIKE '$VAL' AND $L.msg LIKE '$MSG';"
    done
    echo "COMMIT;"
}

delete(){
    echo ""
    if [ $# -eq 0 ]; then
        echo "Usage: $0 delete [language] {function} {value} {msg}"
        exit 1
    fi
    
    export LANG=$1
    if [ "$1" == "all" ]; then
        export LANG=${tables[@]}
    fi

    export FUN=$2
    if [ "$FUN" == "" ]; then
        export FUN="%"
    fi

    export VAL=$3
    if [ "$VAL" == "" ]; then
        export VAL="%"
    fi

    export MSG=$4
    if [ "$MSG" == "" ]; then
        export MSG="%"
    fi

    sql_query | $sqlite $db

    echo ""
    
    read -p "Are you sure to delete those data?(y/N)" confirm

    if [ "$confirm" != "Y" -a "$confirm" != "y" ]; then
        echo "[CANCEL] $0 delete cancel"
        exit 0
    fi

    sql_delete | $sqlite $db
}

sql_query() {
    LANG=($LANG)
    echo ".mode $mode"
    echo "BEGIN TRANSACTION;"
    for L in "${LANG[@]}"; do
        echo "SELECT '$L' as 'lang', * FROM $L"
        echo "WHERE $L.function LIKE '$FUN' AND $L.value LIKE '$VAL' AND $L.msg LIKE '$MSG'"
        echo "ORDER BY function ASC, value ASC;"
    done
    echo "COMMIT;"
}

query(){
    echo ""
    if [ $# -eq 0 ]; then
        echo "Usage: $0 query [language] {function} {value} {msg}"
        exit 1
    fi

    export LANG=$1
    if [ "$1" == "all" ]; then
        export LANG=${tables[@]}
    fi

    export FUN=$2
    if [ "$FUN" == "" ]; then
        export FUN="%"
    fi

    export VAL=$3
    if [ "$VAL" == "" ]; then
        export VAL="%"
    fi

    export MSG=$4
    if [ "$MSG" == "" ]; then
        export MSG="%"
    fi

    if [ "$mode" == "insert" ]; then
        sql_query | $sqlite $db | sed "s/INSERT INTO table VALUES('\([^']*\)',/INSERT INTO \1 VALUES(/g"
    else
        sql_query | $sqlite $db
    fi
}

sql_dump(){
echo ".mode insert"
case "$1" in
    lang)
        echo "SELECT * from $2"
        echo "ORDER BY function, value;"
    ;;
    *)
        echo "SELECT * from $1;"
    ;;
esac
}

dump(){
    echo "[Sorting]"
    echo "BEGIN TRANSACTION;" > /tmp/.language.sql
    $sqlite $db ".schema" >> /tmp/.language.sql
    
    for L in ${tables[@]} ; do
        sql_dump lang $L | $sqlite $db | sed "s/INSERT INTO table VALUES/INSERT INTO $L VALUES/g"  >> /tmp/.language.sql
    done
    
    for T in ${others[@]} ; do
        sql_dump $T | $sqlite $db | sed "s/INSERT INTO table VALUES/INSERT INTO $T VALUES/g"  >> /tmp/.language.sql
    done
    
    echo "COMMIT;" >> /tmp/.language.sql
    
    echo "[Rebuilding]"
    $sqlite /tmp/.tmp.db ".read /tmp/.language.sql"
    
    echo "[Dump `pwd`/language.sql]"
    $sqlite /tmp/.tmp.db ".dump" > language.sql
    
    rm /tmp/.tmp.db
    rm /tmp/.language.sql
}

sql_count(){
    LANG=($LANG)
    echo "BEGIN TRANSACTION;"
    for L in "${LANG[@]}"; do
        echo "SELECT '$L', count(*) FROM $L;"
    done
    echo "COMMIT;"
}

count(){
    export LANG=$1
    if [ "$1" == "" -o "$1" == "all" ]; then
        export LANG=${tables[@]}
    fi

    sql_count | $sqlite $db
}

sql_missed(){
    LANG=($LANG)
    for L in "${LANG[@]}"; do
        echo "SELECT '$L', A.* from $1 A"
        echo "LEFT JOIN $L B ON A.function = B.function AND A.value = B.value"
        echo "WHERE B.value ISNULL;"
    done
}

missed(){
    if [ "$1" == "" ]; then
        echo "Usage: $0 missed [base language] {language}"
        exit 0;
    fi
    
    export LANG=$2
    if [ "$2" == "" -o "$2" == "all" ]; then
        export LANG=${tables[@]}
    fi

    sql_missed $1 | $sqlite $db

    exit 0
}

sql_dup(){
    LANG=($LANG)
    for L in "${LANG[@]}"; do
        echo "SELECT '$L', '', S.function 'function', S.value 'value', S.msg 'msg'"
        echo "FROM $L S, ("
        echo "    SELECT function, value"
        echo "    FROM $L"
        echo "    GROUP BY function, value"
        echo "    HAVING count(*) > 1"
        echo ") D"
        echo "WHERE S.function = D.function AND S.value = D.value"
        echo "ORDER BY S.function, S.value;"
    done
}

dup(){
    export LANG=$1
    if [ "$1" == "" -o "$1" == "all" ]; then
        export LANG=${tables[@]}
    fi

    sql_dup | $sqlite $db
}

sql_notrans() {
    echo "SELECT '$1', A.* FROM $1 A, en B"
    echo "WHERE A.function == B.function AND A.value == B.value AND A.msg == B.msg"
    echo "ORDER BY A.function, A.value;"
}

notrans(){
    mkdir notrans > /dev/null 2>&1
    
    for L in ${tables[*]}; do
        if [ "$L" != "en" ]; then
            echo "[Analyze `pwd`/notrans/$L.dat]"
            sql_notrans $L | $sqlite $db > notrans/$L.dat
        fi
    done
}

case "$1" in
    import)
    import "${@:2:$#}"
    exit 0;
    ;;
    insert)
    insert "${@:2:$#}"
    exit 0;
    ;;
    delete)
    delete "${@:2:$#}"
    exit 0;
    ;;
    query)
    query "${@:2:$#}"
    exit 0;
    ;;
    dump)
    dump "${@:2:$#}"
    exit 0;
    ;;
    count)
    count "${@:2:$#}"
    exit 0;
    ;;
    missed)
    missed "${@:2:$#}"
    exit 0;
    ;;
    dup)
    dup "${@:2:$#}"
    exit 0;
    ;;
    notrans)
    notrans
    exit 0;
    ;;
    *)
    echo ""
    echo "Optional: DB (The default db file is /var/www/html/language/language.db)"
    echo "Optional: MODE (The default mode is list)"
    echo ""
    echo "Usage: {DB=language.db} {MODE=line|column|insert|list|html} $0 [import|insert|delete|query|dump]"
    echo "  import [dat|sql] [file]"
    echo "  insert [language] [function] [value] [msg]"
    echo "  delete [language] {function} {value} {msg}"
    echo "  query [language] {function} {value} {msg}"
    echo "  count {language}"
    echo "  missed [base language] {language}"
    echo "  dup {language}"
    echo "  notrans"
    echo "  dump"
    echo ""
    echo "language support: cz de es en fr it ja ko pl pt ru tr tw zh : all"
    echo ""
    exit 0
esac


