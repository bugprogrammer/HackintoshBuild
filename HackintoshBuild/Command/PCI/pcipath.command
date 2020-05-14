#!/bin/bash

BDF=$2
arr=(`echo $BDF | tr ',' ' '`)
for i in ${arr[*]}; do
    "$1" | grep $i | awk '{$1=""; $2="";print $0}' | sed 's/^[ \t]*//g'
done;
