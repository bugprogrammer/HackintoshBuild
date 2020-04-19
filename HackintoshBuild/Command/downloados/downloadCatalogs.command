#!/bin/bash

cd $1
if [ -e "$1/macOSInstaller/catalogs" ]; then
    rm -rf "macOSInstaller/catalogs"
fi
mkdir -p "macOSInstaller/catalogs"
cd "macOSInstaller/catalogs"
curl -o catalogs.plist $2
