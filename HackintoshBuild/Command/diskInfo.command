#!/bin/bash

u=$(nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:boot-path | sed 's/.*GPT,\([^,]*\),.*/\1/')
if [ "$u" != "" ]; then
    boot=$(diskutil info $u | grep 'Device Identifier' | awk '{print $NF}')
fi
arr=($(diskutil list | grep EFI | awk {'print $NF'}))
#echo "数组的元素为: ${arr[*]}"
for element in ${arr[@]}
do
echo -n $(diskutil info ${element%s*} | grep 'Device / Media Name' | awk -F: {'print $2'} | sed 's/^[ \t]*//g'):
echo -n $(diskutil info ${element} | grep 'Partition Type' | awk -F: {'print $2'} | sed 's/^[ \t]*//g'):
echo -n $(diskutil info ${element} | grep 'Mounted' | awk -F: {'print $2'} | sed 's/^[ \t]*//g'):
echo -n $(diskutil info ${element} | grep 'Disk Size' | awk -F: {'print $2'} | sed 's/^[ \t]*//g') | awk 'BEGIN{ORS=""}{print $1,$2;}'
if [ $boot == $element ]; then
    echo -n :$element:
    echo "当前引导分区"
else
    echo :$element
fi
done
