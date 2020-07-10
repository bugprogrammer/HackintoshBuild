#!/bin/bash

u=$(nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:boot-path | sed 's/.*GPT,\([^,]*\),.*/\1/')
a=$("$1" | grep SelfDevicePath | awk -F\\ '{print $NF}' | awk -F, '{print $3}')
if [ "$u" != "" ]; then
    boot=$(diskutil info $u | grep 'Device Identifier' | awk '{print $NF}')
fi
if [ "$a" != "" ]; then
    boot=$(diskutil info $a | grep 'Device Identifier' | awk '{print $NF}')
fi
arr=($(diskutil list | grep EFI | awk {'print $NF'}))
for element in ${arr[@]}
do
# 磁盘名
echo -n $(diskutil info ${element%s*} | grep 'Device / Media Name' | awk -F: {'print $2'} | sed 's/^[ \t]*//g'):
# 分区类型
echo -n $(diskutil info $element | grep 'Partition Type' | awk {'print $3'} | sed 's/^[ \t]*//g'):
# 分区容量 1
echo -n $(diskutil info $element | grep 'Disk Size' | awk {'print $3'} | sed 's/^[ \t]*//g'):
# 分区容量 2
echo -n $(diskutil info $element | grep 'Disk Size' | awk {'print $4'} | sed 's/^[ \t]*//g'):
# 标识符
echo -n $element:
if [ $boot == $element ]; then
    echo -n $(diskutil info ${element} | grep 'Mounted' | awk -F: {'print $2'} | sed 's/^[ \t]*//g'):
    echo "当前引导分区"
else
    echo $(diskutil info ${element} | grep 'Mounted' | awk -F: {'print $2'} | sed 's/^[ \t]*//g')
fi
done
