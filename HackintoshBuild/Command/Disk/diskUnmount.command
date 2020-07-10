#!/usr/bin/osascript

on run argv
    do shell script "diskutil unmount /dev/" & quoted form of (item 1 of argv) & " 2>&1"
end run
