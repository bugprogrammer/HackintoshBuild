#!/usr/bin/osascript

on run argv
    do shell script "chown -R root:wheel " & quoted form of (item 1 of argv) with administrator privileges
    do shell script "chmod -R 755 " & quoted form of (item 1 of argv) with administrator privileges
    do shell script "kextload " & quoted form of (item 1 of argv) with administrator privileges
    do shell script "sleep 5"
    do shell script "cat /tmp/AppleIntelInfo.dat" with administrator privileges
end run
