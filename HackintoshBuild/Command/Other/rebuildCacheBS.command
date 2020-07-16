#!/usr/bin/osascript

do shell script "echo \"正在解锁系统分区写权限\""
do shell script "mount -uw / && killall Finder" with prompt "重建缓存需要授权" with administrator privileges
do shell script "echo \"解锁系统分区写权限成功\""

do shell script "echo \"修复权限重建缓存中,请稍后！\""

do shell script "chown -v -R root:wheel /System/Library/Extensions > /dev/null" with prompt "重建缓存需要授权" with administrator privileges
do shell script "touch /System/Library/Extensions > /dev/null" with prompt "重建缓存需要授权" with administrator privileges
do shell script "chmod -v -R 755 /System/Library/Extensions > /dev/null" with prompt "重建缓存需要授权" with administrator privileges
do shell script "chmod -v -R 755 /Library/Extensions > /dev/null" with prompt "重建缓存需要授权" with administrator privileges
do shell script "chown -v -R root:wheel /Library/Extensions > /dev/null" with prompt "重建缓存需要授权" with administrator privileges
do shell script "touch /Library/Extensions > /dev/null" with prompt "重建缓存需要授权" with administrator privileges
do shell script "kmutil install --update-all > /dev/null" with prompt "重建缓存需要授权" with administrator privileges
do shell script "kcditto > /dev/null" with prompt "重建缓存需要授权" with administrator privileges

return "success"
