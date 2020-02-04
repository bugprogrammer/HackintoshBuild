#!/usr/bin/osascript

do shell script "mount -uw / && killall Finder" with administrator privileges

return "success"
