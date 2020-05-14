#!/bin/bash

cd "$1"

if [ ! -e "OpenCoreVersions" ]; then
    git clone https://github.com/bugprogrammer/OpenCoreVersions.git > /dev/null
    cd "OpenCoreVersions"
else
    cd "OpenCoreVersions"
    git pull origin master > /dev/null
fi
rm README.md
ls -v -r
