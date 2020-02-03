#!/bin/bash

diskutil list | grep EFI

u=$(nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:boot-path | sed 's/.*GPT,\([^,]*\),.*/\1/')
if [ "$u" != "" ]; then
    echo $(diskutil info $u | grep 'Device Identifier' | awk '{print $NF}')
fi
