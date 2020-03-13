#!/bin/bash

path=$1
url=$2
version=$3
name=$4

cd $path

curl -OL $url/releases/download/$version/$name && unzip -o $name -d ${url##*/} && rm *.zip
if [[ $url =~ "/acidanthera/WhateverGreen" ]]; then
   mv ${url##*/} acidanthera-${url##*/}
elif [[ $url =~ "/bugprogrammer/WhateverGreen" ]]; then
   mv ${url##*/} bugprogrammer-${url##*/}
fi
