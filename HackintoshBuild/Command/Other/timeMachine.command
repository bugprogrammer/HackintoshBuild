#!/usr/bin/osascript

on run argv
    do shell script "sysctl debug.lowpri_throttle_enabled=" & quoted form of (item 1 of argv) with prompt "时光机器满速/还原需要授权" with administrator privileges
    return "success"
end run
