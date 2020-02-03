#!/bin/bash

authPass=$(/usr/bin/osascript <<EOT
  tell application "System Events"
    activate
    repeat
      display dialog "本程序需要管理员权限，请输入密码:" ¬
        default answer "" ¬
        with title "$dialogTitle" ¬
        with hidden answer ¬
        buttons {"Continue"} default button 1
      if the button returned of the result is "Continue" then
        set pswd to text returned of the result
        set usr to short user name of (system info)
        try
          do shell script "echo test" user name usr password pswd with administrator privileges
            return pswd
            exit repeat
        end try
      end if
    end repeat
  end tell
EOT
)

sudo () {
    /bin/echo $authPass | /usr/bin/sudo -S "$@"
}

echo "正在解锁系统分区写权限"
sudo mount -uw / && killall Finder
echo "解锁系统分区写权限成功"

echo "修复权限重建缓存中,请稍后！"
sudo chown -v -R root:wheel /System/Library/Extensions > /dev/null
sudo touch /System/Library/Extensions > /dev/null
sudo chmod -v -R 755 /Library/Extensions > /dev/null
sudo chown -v -R root:wheel /Library/Extensions > /dev/null
sudo touch /Library/Extensions > /dev/null
sudo kextcache -i / > /dev/null > /dev/null
