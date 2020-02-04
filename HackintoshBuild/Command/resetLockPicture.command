#!/usr/bin/osascript

do shell script "cd /Library/Caches/; if [ -e Desktop\\ Pictures ]; then\n rm -rf Desktop\\ Pictures\n fi" with administrator privileges

return "success"
