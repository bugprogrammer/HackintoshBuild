#!/bin/bash

cd "$1"
proxy=$2
if [ $proxy!='' ]; then
export http_proxy=$proxy
export https_proxy=$proxy
fi
selectList=$3
selectedArray=(`echo $selectList | tr ',' ' '`)
for i in ${selectedArray[*]}; do
    zipname=${i##*/}
    dirname=${zipname%%-*}
    curl -OLs $i && unzip -o $zipname -d $dirname > /dev/null && rm *.zip > /dev/null
    if [[ $i =~ "/acidanthera/WhateverGreen" ]]; then
        mv $dirname acidanthera_$dirname
        echo acidanthera_$dirname
    elif [[ $i =~ "/bugprogrammer/WhateverGreen" ]]; then
        mv $dirname bugprogrammer_$dirname
        echo bugprogrammer_$dirname
    elif [[ $i =~ "MacProMemoryNotificationDisabler" ]]; then
        echo "MacProMemoryNotificationDisabler"
    else
        echo $dirname
    fi
done;
