HackintoshBuild
===============

基于 Swift 开发的 Hackintosh 综合工具，让萌新们更容易实现 Hackintosh 构建以及系统信息查询。

#### 软件功能
- 查询系统各项信息
- 编译最新引导、驱动
- 获取常见机型 EFI
- 挂载 ESP 分区
- 更换登录壁纸
- 查询白苹果 IOReg 信息
- 注入显卡优化补丁
- macOS 镜像下载
- 文件差异对比
- 其他小功能

#### 食用方法
- **安装 Xcode 以及命令行工具**
- 下载或编译 HackintoshBuild.app，拖入应用程序

#### 鸣谢列表
- Apple 的 macOS 操作系统
- bdmesg 工具用于查询 Clover 相关信息（编译 Clover 源码获得）
- [dspci](https://github.com/MuntashirAkon/DPCIManager) 工具用于查询 pci 设备列表
- [gfxutil](https://github.com/acidanthera/gfxutil) 工具用于查询 pci 设备路径
- macserial 工具用于生成序列号等信息（已合并到 OpenCore）
- [AppleIntelInfo](https://github.com/Piker-Alpha/AppleIntelInfo) 用于获取 CPU、IGPU 频率等信息
- 网友stevezhengshiqi 提供VoodooI2C以及VoodooPS2编译思路
