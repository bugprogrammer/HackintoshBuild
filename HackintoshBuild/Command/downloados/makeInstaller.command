#!/bin/bash

isfolder=false
isbase=false

cd "$1/macOSInstaller/installer"

if [ ! -e InstallAssistant.pkg ]; then
    chmod a+x BaseSystem.dmg
    chmod a+x BaseSystem.chunklist
    chmod a+x InstallInfo.plist
    chmod a+x InstallESDDmg.pkg
    chmod a+x AppleDiagnostics.dmg
    chmod a+x AppleDiagnostics.chunklist

    $(hdiutil attach BaseSystem.dmg 2>&1 >/dev/null)

    FOLDERS=(/Volumes/*)
    for folder in "${FOLDERS[@]}"; do
        if [[ -d "$folder" && "$folder" =~ "Base System" ]]; then
            basePath="$folder"
            isfolder=true
        fi
    done

    for file in "$basePath/"*; do
        if [[ $file == *.app ]]; then
            let index=${#name_array[@]}
            name_array[$index]="${file##*/}"
            isbase=true
        fi
    done
    
    if [[ "$isfolder" = false || "$isbase" = false ]]; then
        echo "failed"
        exit 1
    fi
    
    installAppName=${name_array[0]}

    cp -Rf "$basePath/$installAppName" .

    $(hdiutil detach "$basePath" 2>&1 >/dev/null)

    if [ ! -d "${installAppName}/Contents/SharedSupport" ]; then
        mkdir -p "${installAppName}/Contents/SharedSupport"
    fi

    cp -Rf BaseSystem.dmg "${installAppName}/Contents/SharedSupport"
    cp -Rf BaseSystem.chunklist "${installAppName}/Contents/SharedSupport"
    cp -Rf InstallInfo.plist "${installAppName}/Contents/SharedSupport"
    cp -Rf AppleDiagnostics.dmg "${installAppName}/Contents/SharedSupport"
    cp -Rf AppleDiagnostics.chunklist "${installAppName}/Contents/SharedSupport"
    cp -Rf InstallESDDmg.pkg "${installAppName}/Contents/SharedSupport/InstallESD.dmg"

    sed -i "" 's/<string>InstallESDDmg.pkg<\/string>/<string>InstallESD.dmg<\/string>/g' "${installAppName}/Contents/SharedSupport/InstallInfo.plist"
    sed -i "" '30,33d' "${installAppName}/Contents/SharedSupport/InstallInfo.plist"
    sed -i "" 's/<string>com.apple.pkg.InstallESDDmg<\/string>/<string>com.apple.dmg.InstallESD<\/string>/g' "${installAppName}/Contents/SharedSupport/InstallInfo.plist"
    sed -i "" 's/InstallESDDmg.pkg/InstallESD.dmg/g' "${installAppName}/Contents/SharedSupport/InstallInfo.plist"

    if [ -d "/Applications/${installAppName}" ]; then
        rm -rf "/Applications/${installAppName}"
    fi
    mv -f "${installAppName}" /Applications
fi

rm -rf "$1/macOSInstaller"
