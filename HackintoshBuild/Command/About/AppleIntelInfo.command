#!/usr/bin/osascript

on run argv
    do shell script "chown -R root:wheel " & quoted form of (item 1 of argv) with prompt "查询系统信息需要授权" with administrator privileges
    do shell script "chmod -R 755 " & quoted form of (item 1 of argv) with prompt "查询系统信息需要授权" with administrator privileges
    do shell script "kextload " & quoted form of (item 1 of argv) with prompt "查询系统信息需要授权" with administrator privileges
    do shell script "sleep 5"
    do shell script "kextunload " & quoted form of (item 1 of argv) with prompt "查询系统信息需要授权" with administrator privileges
    do shell script "cat /tmp/AppleIntelInfo.dat" with prompt "查询系统信息需要授权" with administrator privileges
end run
