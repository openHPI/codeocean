#!/bin/bash

touch execute.log
echo "[" `date +"%F %H:%M:%S"` "] received command from codeocean" >> execute.log

python /download.py http://docker:4001/v2/keys/$1

eval $2
exit $?
