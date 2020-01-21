#!/bin/bash

echo -e '\n正在获取Bugprogrammer的Hackintosh仓库，请稍后:'
echo '-------------------------------------'

url=$1
cd $url
dir=hackintosh_EFI
if [ -e $dir ]; then
    rm -rf $dir
fi
mkdir -p $dir/Release
mkdir -p $dir/Sources
cd $dir/Sources

proxy=$3
if [ $proxy!='' ]; then
export http_proxy=$proxy
export https_proxy=$proxy
fi

git clone https://github.com/bugprogrammer/hackintosh.git

cd hackintosh

nameList=${2}
nameArr=(`echo $nameList | tr ',' ' '`)

for i in ${nameArr[*]}; do
    mkdir ../../Release/$i
    git checkout $i
    cp -Rf * ../../Release/$i
done;

open $url/$dir/Release
