#!/bin/sh
product=$1
pwd=`pwd`

modellist(){
  echo "N10850"
  echo "N12000PRO"
  echo "N12000"
  echo "N12000V"
  echo "N16000PRO"
  echo "N16000V"
  echo "N2800"
  echo "N4800"
  echo "N5800"
  echo "N6850"
  echo "N8850"
  echo "N8900PRO"
  echo "N8900"
  echo "N8900V"
}

if [ "${product}" != "" ];then
  list=${product}
else
  list=`modellist`
fi

echo -e "${list}" | \
while read product
do
  rm -rf ${pwd}/${product}
  mkdir ${pwd}/${product}
  tar zxvfp ${pwd}/default.N16000.tar.gz -C ${pwd}/${product}/

  cd ${pwd}/${product}/etc/
  for file in HOSTNAME manifest.txt hosts
  do
    cat ${file} | awk "{gsub(\"N16000\",\"${product}\");print \$0}" > ${file}.bak
    mv ${file}.bak ${file}
  done

  cd ${pwd}/${product}/etc/httpd/conf/
  for file in httpd.conf ssl.conf
  do
    cat ${file} | awk "{gsub(\"N16000\",\"${product}\");print \$0}" > ${file}.bak
    mv ${file}.bak ${file}
  done

  cd ${pwd}/${product}/etc/cfg/
  file=conf.dump
  sqlite conf.db ".dump" > ${file}
  cat ${file} | awk "{gsub(\"N16000\",\"${product}\");print \$0}" > ${file}.bak
  cat ${file}.bak | sqlite conf.db.bak
  mv conf.db.bak conf.db
  rm -f ${file} ${file}.bak

  cd ${pwd}/${product}
  tar zcvfp ../default.${product}.tar.gz .

  cd ${pwd}
  rm -rf ${pwd}/${product}
done
