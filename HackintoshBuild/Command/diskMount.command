#!/usr/bin/osascript

on run argv
    do shell script "diskutil mount /dev/" & quoted form of (item 1 of argv) & " 2>&1" with administrator privileges
end run
