#!/usr/bin/osascript

#on run argv
#    do shell script "diskutil mount /dev/" & quoted form of (item 1 of argv) & " 2>&1" with administrator privileges
#end run
u=$(nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:boot-path | sed 's/.*GPT,\([^,]*\),.*/\1/')
if [ "$u" != "" ]; then
    do shell script "diskutil mount $u" with administrator privileges
fi

