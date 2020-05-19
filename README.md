# HackintoshBuild

# 基于Swift开发的Hackintosh综合工具

为了萌新们更容易实现Hackintosh构建以及系统信息查询，特开发HackintoshBuild工具，基于Swift。开源地址为：https://github.com/bugprogrammer/HackintoshBuild。 请安装Xcode以及命令行工具后食用。

鸣谢列表

* Apple的macOS操作系统
* bdmesg工具用于查询Clover相关信息(编译Clover源码获得)
* dspci工具用于查询pci设备列表(https://github.com/MuntashirAkon/DPCIManager)
* gfxutil工具用于查询pci设备路径(https://github.com/acidanthera/gfxutil)
* macserial工具用于生成序列号等信息(已合并到OpenCore)
* AppleIntelInfo.kext用于获取CPU、IGPU频率等信息(https://github.com/Piker-Alpha/AppleIntelInfo)
