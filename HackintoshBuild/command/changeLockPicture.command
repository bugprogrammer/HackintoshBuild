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

sudo mount -uw / && killall Finder
echo "SLE解锁成功"

userUUID=$(dscl . read /Users/$(whoami) | grep GeneratedUID | awk '{print $NF}')
cd /Library/Caches/
if [ ! -e Desktop\ Pictures ]; then
    mkdir -p Desktop\ Pictures/$userUUID
fi
cd Desktop\ Pictures/$userUUID
cp -f $1 lockscreen.png
