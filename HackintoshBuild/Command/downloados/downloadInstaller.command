#!/bin/bash

cd $1
if [ -e "$1/macOSInstaller/installer" ]; then
    rm -rf "macOSInstaller/installer"
fi
mkdir "macOSInstaller/installer"
cd "macOSInstaller/installer"
echo "正在下载AppleDiagnostics.dmg"
curl -OL# $2/AppleDiagnostics.dmg
echo "正在下载AppleDiagnostics.chunklist"
curl -OL# $2/AppleDiagnostics.chunklist
echo "正在下载BaseSystem.dmg"
curl -OL# $2/BaseSystem.dmg
echo "正在下载BaseSystem.chunklist"
curl -OL# $2/BaseSystem.chunklist
echo "正在下载InstallInfo.plist"
curl -OL# $2/InstallInfo.plist
echo "正在下载InstallESDDmg.pkg"
curl -OL# $2/InstallESDDmg.pkg

echo "下载完成"
