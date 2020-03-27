#!/usr/bin/osascript

do shell script "mount -uw / && killall Finder" with prompt "解锁SLE需要授权" with administrator privileges

return "success"
