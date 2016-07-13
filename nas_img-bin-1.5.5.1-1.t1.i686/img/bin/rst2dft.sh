#!/bin/sh
echo "Reset to factory default value ....."
echo RESET_PIC > /proc/thecus_io
/img/bin/resetDefault.sh
