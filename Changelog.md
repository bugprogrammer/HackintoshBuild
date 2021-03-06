HackintoshBuild Changelog
=========================

#### v4.1
- 参照开源方案 https://github.com/DigiDNA/Silicon MIT License.重构"本机app适配Apple Silicon情况"模块
- Apple Silicon Macs关于本机不显示Board id、drm仿冒id、核显id等条目

#### v4.0
- 适配Apple Silicon Macs
- 新增"本机app适配Apple Silicon情况"模块
- 按照硬件架构区分可用功能
- UI适配Big Sur风格

#### v3.2
- 适配macOS Big Sur RC2镜像下载

#### v3.1
- 适配MacKernelSDK，修复编译功能以及每日构建功能
- 编译模块新增VoodooI2C、VoodooPS2以及RTL8125

#### v3.0
- 重构 UI，适配 Big Sur
- 支持 AMD CPUs
- 优化编译流程，修复找不到 xcodebuild 导致编译失败
- 修复 EFI 分区挂载在某些情况下显示错误
- 编译模块以及EFI获取模块新增log路径存储
- 编译模块新增环境详细校验
- 更换锁屏壁纸模块改用拖拽方案
- 镜像下载模块重构，显示下载进度，增强容错
- 文件对比模块重构(需要安装xcode)
- 新增Kexts下载模块
- 新增每日构建下载模块(利用azure pipeline每8小时自动编译Hackintosh全家桶)
- 新增快照检测
- 显卡优化更改为kext方案
- Big Sur下禁用AppleIntelInfo功能
- Kexts下载模块重构，新增进度显示
- PCI信息模块新增应用内更新pci.ids数据库
- 序列号生成模块新增应用内更新SMBIOS数据库

#### v2.1
- 适配最新 OpenCore 编译
- 添加 Z490 ELITE EFI
- 更新 pci.ids

#### v2.0
- 重构 PCI 信息列表（基于 pci.ids）
- 新增序列号生成
- 新增 OpenCore 版本一览（ChangeLog 以及配置模板）
- 新增文件差异对比

#### v1.9
- 更新 mtoc 版本以适配最新 OpenCore
- 新增镜像下载模块（官方服务器）

#### v1.8
- 适配最新 OC 编译
- 提升 NVRAM XML 格式兼容性
- 新增 PCI 设备信息
- 新增显卡性能优化（感谢 xjn 提供数据）

#### v1.7
- 修复 NVRAM 模块随机闪退
- NVRAM 模块重构，新增 values 高亮格式化
- 适配系统亮色/暗色切换（无需退出软件）

#### v1.6
- 编译模块：新增全选，新增初始环境判断，增强兼容性，修复低版本 Xcode 无法编译
- EFI 获取模块：新增全选
- EFI 挂载：全功能重构，新增 Clover 环境下，判断当前引导分区
- 新增关于本机，获取本机信息
- 新增 Kexts 下载
- 新增路径空格以及写权限判断
- 修复部分 Clover 用户闪退

#### v1.5
- UI 继续优化，禁用全屏模式以及缩放
- bug 清理

#### v1.4
- 编译模块以及 EFI 获取模块新增日志存储
- EFI 分区挂载模块新增磁盘名称显示以及刷新分区列表
- NVRAM 读取模块新增刷新 keys
- 新增系统详情功能，获取 kexts、aml、efi 文件情况，读取详细信息，获取本地 Clover、OC 版本号
- 新增白苹果 iOReg 信息读取
- 1.4 版本起，支持自动检测更新
- UI适配（感谢 Arabaku）
- 新增捐赠模块（全凭自愿）

#### v1.3
- 登录壁纸替换适配 10.15.4 Beta 版本
- 新增 HTTP 代理记忆
- 新增时光机器满速运行以及还原默认功能

#### v1.2
- 新增 EFI 分区挂载功能并显示当前引导分区
- 新增 NVRAM 信息读取功能
- 新增更换登录壁纸功能（可用来解决系统更新后，自定义桌面壁纸和登录壁纸不同步问题）
- 解决大量遗留 bug

#### v1.1
- 最低支持 macOS 版本为 10.13
- 新增窗口管理
- 新增检查更新
- 新增 HTTP 代理设置
- 新增保存上次存储路径
- 新增 bugprogrammer 维护的常见机型EFI列表获取
- 新增解锁 10.15.x read-only
- 新增重建缓存功能
- 新增开启未知来源安装软件

#### v1.0
- 基本编译功能
- 选择存储路径
