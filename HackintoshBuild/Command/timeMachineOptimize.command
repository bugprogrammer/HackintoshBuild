#!/usr/bin/osascript

do shell script "sysctl debug.lowpri_throttle_enabled=0" with administrator privileges

return "success"
