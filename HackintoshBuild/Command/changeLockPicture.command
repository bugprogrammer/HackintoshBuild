#!/bin/bash

userUUID=$(dscl . read /Users/$(whoami) | grep GeneratedUID | awk '{print $NF}')
cd /Library/Caches/
if [ ! -e Desktop\ Pictures ]; then
    mkdir -p Desktop\ Pictures/$userUUID
fi
cd Desktop\ Pictures/$userUUID
cp -f $1 lockscreen.png

echo "success"
