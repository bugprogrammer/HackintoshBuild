#!/bin/bash

echo -e '\n正在获取Bugprogrammer的Hackintosh仓库，请稍后:'
echo '-------------------------------------'

url=$1
cd "$url"
dir=hackintosh_EFI
if [ -e "$dir" ]; then
    rm -rf "$dir"
fi
mkdir -p $dir/Release
mkdir -p $dir/Sources
cd "$dir/Sources"

proxy=$3
if [ $proxy!='' ]; then
export http_proxy=$proxy
export https_proxy=$proxy
fi

if [[ "$4" == "" ]]; then
    logs=/dev/null
else
    if [ -e "$4/efi.log" ]; then
        rm -f "$4/efi.log"
    fi
    logs="$4/efi.log"
fi

git clone https://github.com/bugprogrammer/hackintosh.git >> "$logs"

cd hackintosh

nameList=${2}
nameArr=(`echo $nameList | tr ',' ' '`)

for i in ${nameArr[*]}; do
    mkdir ../../Release/$i
    echo "正在获取"$i"的EFI"
    git checkout $i >> "$logs"
    cp -Rf * ../../Release/$i
done;

if [[ "$4" != "" ]]; then
    open "$4/efi.log"
fi
open "$url/$dir/Release"
