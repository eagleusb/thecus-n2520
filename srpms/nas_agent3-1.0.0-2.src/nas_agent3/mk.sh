#!/bin/bash
APP="agent3"
WORKPATH=`pwd`
cd ${WORKPATH}
make clean
make CC=gcc CFLAGS="-L/opt/lib -I/opt/include -L/opt/sqlite/lib"
strip ./dist/Debug/GNU-Linux-x86/agent3
echo "################################################################"
echo "#         Compiler ${APP} success"
echo "################################################################"
