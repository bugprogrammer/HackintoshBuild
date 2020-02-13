#!/bin/bash

#diskutil list | grep EFI

arr=($(diskutil list | grep EFI | awk {'print $NF'}))
#echo "数组的元素为: ${arr[*]}"
for element in ${arr[@]}
do
diskutil info ${element%s*} | grep 'Device / Media Name' | awk -F: {'print $2'} | sed 's/^[ \t]*//g'
diskutil list | grep $element | awk -F: {'print $2'} | sed 's/^[ \t]*//g'
done

u=$(nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:boot-path | sed 's/.*GPT,\([^,]*\),.*/\1/')
if [ "$u" != "" ]; then
    echo $(diskutil info $u | grep 'Device Identifier' | awk '{print $NF}')
fi
