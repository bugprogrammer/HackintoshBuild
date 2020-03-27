#!/usr/bin/osascript

do shell script "cd /Library/Caches/; if [ -e Desktop\\ Pictures ]; then\n rm -rf Desktop\\ Pictures\n fi" with prompt "重置锁屏壁纸需要授权" with administrator privileges

return "success"
