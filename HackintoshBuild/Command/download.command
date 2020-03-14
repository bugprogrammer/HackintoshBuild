#!/bin/bash

path=$1
url=$2
version=$3
name=$4

cd $path

curl -OL $url/releases/download/$version/$name && unzip -o $name -d ${url##*/} && rm *.zip
if [[ $url =~ "/acidanthera/WhateverGreen" ]]; then
   mv ${url##*/} acidanthera_${url##*/}
elif [[ $url =~ "/bugprogrammer/WhateverGreen" ]]; then
   mv ${url##*/} bugprogrammer_${url##*/}
elif [[ $url =~ "RTL8111_driver_for_OS_X" ]]; then
   mv ${url##*/} RealtekRTL8111
fi
