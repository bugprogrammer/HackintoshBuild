#!/bin/bash

osascript <<EOF
do shell script "echo \"正在解锁系统分区写权限\""
do shell script "mount -uw / && killall Finder" with prompt "安装Kexts需要授权" with administrator privileges
do shell script "echo \"解锁系统分区写权限成功\""
EOF

kextsList=$1
kextsArray=(`echo $kextsList | tr ',' ' '`)
for i in ${kextsArray[*]}; do
echo "正在安装"$i"中"
osascript <<EOF
do shell script "cp -rf $i /System/Library/Extensions" with prompt "安装Kexts需要授权" with administrator privileges
EOF
done;

echo "修复权限重建缓存中,请稍后！"

osascript <<EOF

do shell script "chown -v -R root:wheel /System/Library/Extensions > /dev/null" with prompt "重建缓存需要授权" with administrator privileges
do shell script "touch /System/Library/Extensions > /dev/null" with prompt "重建缓存需要授权" with administrator privileges
do shell script "chmod -v -R 755 /System/Library/Extensions > /dev/null" with prompt "重建缓存需要授权" with administrator privileges
do shell script "chmod -v -R 755 /Library/Extensions > /dev/null" with prompt "重建缓存需要授权" with administrator privileges
do shell script "chown -v -R root:wheel /Library/Extensions > /dev/null" with prompt "重建缓存需要授权" with administrator privileges
do shell script "touch /Library/Extensions > /dev/null" with prompt "重建缓存需要授权" with administrator privileges
do shell script "kmutil install --update-all > /dev/null" with prompt "重建缓存需要授权" with administrator privileges
do shell script "kcditto > /dev/null" with prompt "重建缓存需要授权" with administrator privileges
EOF
