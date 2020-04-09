#!/bin/bash

ioreg -w 0 -n AppleEFINVRAM | sed -n -E "/^[ \|]+[ ]+(\".*)$/s//\1/p;" | sort -f | sed 's/"//g' | sed 's/<//' | sed 's/\(.*\)>/\1/' | sed 's/ = /:/g'
