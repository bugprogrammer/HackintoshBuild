#!/usr/bin/osascript

do shell script "spctl --master-disable" with prompt "开启安装软件未知来源需要授权" with administrator privileges

return "success"
