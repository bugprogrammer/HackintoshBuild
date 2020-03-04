#!/bin/bash

system_profiler SPHardwareDataType | sed -e '1,4d' | sed 's/^[ \t]*//g' | sed -e '$d'
echo "Board-ID:"$(ioreg -c IOPlatformExpertDevice | awk '/board-id/ {print $4}' | awk -F '\"' '{print $2}')
echo "DRM仿冒ID(shiki):"$(ioreg -c IOPlatformExpertDevice | awk '/hwdrm-id/ {print $4}' | awk -F '\"' '{print $2}')
echo "核显ig-platform-id:"$(ioreg -c IOPCIDevice | awk '/AAPL,ig-platform-id/ {print $7}' | awk -F '\<' '{print $2}' | awk -F '\>' '{print $1}')
system_profiler SPSoftwareDataType | sed -e '1,4d' | sed 's/^[ \t]*//g' | sed -e '$d' | sed -e '$d'
system_profiler SPDisplaysDataType | sed -e '1,4d' | sed -e '2d'| sed 's/^[ \t]*//g' | head -n 10
