#!/usr/bin/osascript

do shell script "spctl --master-disable" with administrator privileges

return "success"
