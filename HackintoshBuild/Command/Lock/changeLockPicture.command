#!/usr/bin/osascript

on run argv
    set userUUID to do shell script "(dscl . read /Users/$(whoami) | grep GeneratedUID | awk '{print $NF}')"
    do shell script "cd /Library/Caches/; if [ ! -e Desktop\\ Pictures ]; then\n mkdir -p Desktop\\ Pictures/" & quoted form of userUUID & "\n fi" with prompt "替换锁屏壁纸需要授权" with administrator privileges
    do shell script "sudo chown -R _securityagent /Library/Caches/Desktop\\ Pictures"  with prompt "替换锁屏壁纸需要授权" with administrator privileges
    do shell script "sudo chown -R $(whoami) /Library/Caches/Desktop\\ Pictures"  with prompt "替换锁屏壁纸需要授权" with administrator privileges
    do shell script "cd /Library/Caches/Desktop\\ Pictures/" & quoted form of userUUID & "; cp -f " & quoted form of (item 1 of argv) & " lockscreen.png" with prompt "替换锁屏壁纸需要授权" with administrator privileges
    return "success"
end run
