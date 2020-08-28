#!/usr/bin/osascript

on run argv
    set AppleScript's text item delimiters to ","
    set kexts to every text item of (item 1 of argv)
    
    log "正在解锁系统分区写权限"
    do shell script "mount -uw / && killall Finder" with prompt "安装 Kexts 需要授权" with administrator privileges
    log "解锁系统分区写权限成功"
    
    repeat with kext in kexts
        set AppleScript's text item delimiters to "/"
        set kextlist to every text item of kext
        set kextname to get item -1 of kextlist
        log "正在安装 " & kextname & " 中"
        do shell script "cd /System/Library/Extensions/; if [ -e " & quoted form of kextname & " ]; then\n rm -rf " & quoted form of kextname & "\n fi" with prompt "重命名kexts需要授权" with administrator privileges
        do shell script "cp -Rf " & quoted form of kext & " /System/Library/Extensions/" with prompt "安装 Kexts 需要授权" with administrator privileges
    end repeat
    
    log "修复权限重建缓存中，请稍后！"
    do shell script "chown -v -R root:wheel /System/Library/Extensions > /dev/null" with prompt "重建缓存需要授权" with administrator privileges
    do shell script "touch /System/Library/Extensions > /dev/null" with prompt "重建缓存需要授权" with administrator privileges
    do shell script "chmod -v -R 755 /System/Library/Extensions > /dev/null" with prompt "重建缓存需要授权" with administrator privileges
    do shell script "chmod -v -R 755 /Library/Extensions > /dev/null" with prompt "重建缓存需要授权" with administrator privileges
    do shell script "chown -v -R root:wheel /Library/Extensions > /dev/null" with prompt "重建缓存需要授权" with administrator privileges
    do shell script "touch /Library/Extensions > /dev/null" with prompt "重建缓存需要授权" with administrator privileges
    do shell script "kextcache -i / > /dev/null > /dev/null" with prompt "重建缓存需要授权" with administrator privileges
end run
