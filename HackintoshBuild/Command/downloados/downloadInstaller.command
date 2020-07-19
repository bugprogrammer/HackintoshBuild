#!/bin/bash

cd $1
url=$2
version=$3
if [ -e "$1/macOSInstaller/installer" ]; then
    rm -rf "macOSInstaller/installer"
fi
mkdir "macOSInstaller/installer"
cd "macOSInstaller/installer"

if [ "$version" != " 10.16" ]; then
    echo "正在下载AppleDiagnostics.dmg"
    curl -OL# ${url%/*}/AppleDiagnostics.dmg
    echo "正在下载AppleDiagnostics.chunklist"
    curl -OL# ${url%/*}/AppleDiagnostics.chunklist
    echo "正在下载BaseSystem.dmg"
    curl -OL# ${url%/*}/BaseSystem.dmg
    echo "正在下载BaseSystem.chunklist"
    curl -OL# ${url%/*}/BaseSystem.chunklist
    echo "正在下载InstallInfo.plist"
    curl -OL# ${url%/*}/InstallInfo.plist
    echo "正在下载InstallESDDmg.pkg"
    curl -OL# ${url%/*}/InstallESDDmg.pkg
else
    echo "正在下载InstallInfo.plist"
    curl -OL# ${url%/*}/InstallInfo.plist
    echo "正在下载UpdateBrain.zip"
    curl -OL# ${url%/*}/UpdateBrain.zip
    echo "正在下载MajorOSInfo.pkg"
    curl -OL# ${url%/*}/MajorOSInfo.pkg
    echo "正在下载Info.plist"
    curl -OL# ${url%/*}/Info.plist
    echo "正在下载InstallAssistant.pkg"
    curl -OL# ${url%/*}/InstallAssistant.pkg
    echo "正在下载BuildManifest.plist"
    curl -OL# ${url%/*}/BuildManifest.plist
fi

echo "下载完成"
