#!/bin/bash

arr=($(kextstat | grep -v com.apple | awk {'print $6,$7'} | grep -v Name))

for(( i=0;i<${#arr[@]};i+=2)) do
    echo -n ${arr[i]##*.} && echo -n " " && echo ${arr[i+1]}
done;
