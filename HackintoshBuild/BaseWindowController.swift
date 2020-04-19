//
//  BaseWindowController.swift
//  HackintoshBuild
//
//  Created by 刘靖禹 on 2020/1/17.
//  Copyright © 2020 Arabaku. All rights reserved.
//

import Cocoa
import GitHubUpdates

public var isSIPStatusEnabled: Bool? = nil
public var proxy: String? = UserDefaults.standard.string(forKey: "proxy")
public var isMoved: Bool = false

class BaseWindowController: NSWindowController {
    
    lazy var infoVC: TabViewControllerInfo = {
        return MyTool.getViewControllerFromMain(TabViewControllerInfo.self)
    }()

    lazy var buildVC: ViewControllerBuild = {
        return MyTool.getViewControllerFromMain(ViewControllerBuild.self)
    }()
    
    lazy var EFIVC: ViewControllerEFI = {
        return MyTool.getViewControllerFromMain(ViewControllerEFI.self)
        
    }()
    
    lazy var diskVC: ViewControllerDisk = {
        return MyTool.getViewControllerFromMain(ViewControllerDisk.self)
    }()
    
    lazy var nvramVC: ViewControllerNvram = {
        return MyTool.getViewControllerFromMain(ViewControllerNvram.self)
    }()
    
    lazy var lockVC: ViewControllerLock = {
        return MyTool.getViewControllerFromMain(ViewControllerLock.self)
    }()
    
    lazy var ioregVC: ViewControllerIoreg = {
        return MyTool.getViewControllerFromMain(ViewControllerIoreg.self)
    }()
    
    lazy var gpuVC: ViewControllerGPU = {
        return MyTool.getViewControllerFromMain(ViewControllerGPU.self)
    }()
    
    lazy var osVC: ViewControllerOS = {
        return MyTool.getViewControllerFromMain(ViewControllerOS.self)
    }()
    
    lazy var otherVC: ViewControllerOther = {
        return MyTool.getViewControllerFromMain(ViewControllerOther.self)
    }()
    
    lazy var payVC: ViewControllerPay = {
        return MyTool.getViewControllerFromMain(ViewControllerPay.self)
    }()
    
    let infoIdentifier = NSToolbarItem.Identifier(rawValue: "bugprogrammer.HackintoshBuild.NSToolbarItem.infoIdentifier")
    let buildIdentifier = NSToolbarItem.Identifier(rawValue: "bugprogrammer.HackintoshBuild.NSToolbarItem.buildIdentifier")
    let efiIdentifier = NSToolbarItem.Identifier(rawValue: "bugprogrammer.HackintoshBuild.NSToolbarItem.efiIdentifier")
    let diskIdentifier = NSToolbarItem.Identifier(rawValue: "bugprogrammer.HackintoshBuild.NSToolbarItem.diskIdentifier")
    let nvramIdentifier = NSToolbarItem.Identifier(rawValue: "bugprogrammer.HackintoshBuild.NSToolbarItem.nvramIdentifier")
    let lockIdentifier = NSToolbarItem.Identifier(rawValue: "bugprogrammer.HackintoshBuild.NSToolbarItem.lockIdentifier")
    let ioregIdentifier = NSToolbarItem.Identifier(rawValue: "bugprogrammer.HackintoshBuild.NSToolbarItem.ioregIdentifier")
    let gpuIdentifier = NSToolbarItem.Identifier(rawValue: "bugprogrammer.HackintoshBuild.NSToolbarItem.gpuIdentifier")
    let osIdentifier = NSToolbarItem.Identifier(rawValue: "bugprogrammer.HackintoshBuild.NSToolbarItem.osIdentifier")
    let otherIdentifier = NSToolbarItem.Identifier(rawValue: "bugprogrammer.HackintoshBuild.NSToolbarItem.otherIdentifier")
    let payIdentifier = NSToolbarItem.Identifier(rawValue: "bugprogrammer.HackintoshBuild.NSToolbarItem.payIdentifier")
    
    lazy var toolBar: NSToolbar = {
        let toolBar = NSToolbar(identifier: "bugprogrammer.HackintoshBuild.NSToolbar.MyToolbar")
        toolBar.displayMode = .iconAndLabel
        toolBar.sizeMode = .default
        toolBar.delegate = self
        return toolBar
    }()
    
    let taskQueue = DispatchQueue.global(qos: .default)
    var outputPipe: Pipe!
    var sipStatusOutPut: String = ""
    
    override func windowDidLoad() {
        super.windowDidLoad()
        let updater = GitHubUpdater()
        updater.checkForUpdatesInBackground()
        updater.user = "bugprogrammer"
        updater.repository = "HackintoshBuild"
        
        self.window?.toolbar = toolBar
        toolBar.selectedItemIdentifier = infoIdentifier
        self.window?.contentViewController = infoVC
        self.window?.setContentSize(NSSize(width: 790, height: 630))
        self.window?.styleMask.remove(.resizable)

        runBuildScripts("sipStatus", [], "")
    }
    
    func runBuildScripts(_ shell: String,_ arguments: [String], _ alertText: String) {
        taskQueue.async {
            if let path = Bundle.main.path(forResource: shell, ofType:"command") {
                let task = Process()
                task.launchPath = path
                task.arguments = arguments
                task.environment = ["PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:"]
                self.taskOutPut(task)
                task.launch()
                task.waitUntilExit()
            }
        }
    }
    
    func taskOutPut(_ task:Process) {
        self.sipStatusOutPut = ""
        outputPipe = Pipe()
        task.standardOutput = outputPipe
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading, queue: nil) { [weak self] notification in
            guard let `self` = self else { return }
            let output = self.outputPipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
            let previousOutput = self.sipStatusOutPut
            let nextOutput = previousOutput + outputString
            self.sipStatusOutPut = nextOutput
            /** Arabaku fixed.*/
            let pattern: String = ".*enabled.*"
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let matches = regex.matches(in: self.sipStatusOutPut, options: [], range: NSMakeRange(0, self.sipStatusOutPut.count))
                if matches.count == 1 && matches[0].range.location != NSNotFound {
                    MyLog("SIP status: enabled.")
                    isSIPStatusEnabled = true
                } else {
                    MyLog("SIP status: disabled.")
                    isSIPStatusEnabled = false
                }
            }
        }
    }

}

extension BaseWindowController: NSToolbarDelegate {
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [infoIdentifier, buildIdentifier, efiIdentifier, diskIdentifier, nvramIdentifier, lockIdentifier, ioregIdentifier, gpuIdentifier, osIdentifier, otherIdentifier, payIdentifier]
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [infoIdentifier, buildIdentifier, efiIdentifier, diskIdentifier, nvramIdentifier, lockIdentifier, ioregIdentifier, gpuIdentifier, osIdentifier, otherIdentifier, payIdentifier]
    }
    
    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [infoIdentifier, buildIdentifier, efiIdentifier, diskIdentifier, nvramIdentifier, lockIdentifier, ioregIdentifier, gpuIdentifier, osIdentifier, otherIdentifier, payIdentifier]
    }
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        var toolbarItem: NSToolbarItem? = NSToolbarItem(itemIdentifier: itemIdentifier)
        switch itemIdentifier {
        case infoIdentifier:
            toolbarItem?.label = "系统详情"
            toolbarItem?.paletteLabel = "系统详情"
            toolbarItem?.toolTip = "系统详情"
            let image = MyAsset.NSToolbarItem_Info.image
            image.isTemplate = true
            toolbarItem?.image = image
            break
            
        case buildIdentifier:
            toolbarItem?.label = "编译"
            toolbarItem?.paletteLabel = "编译"
            toolbarItem?.toolTip = "编译一些常用的引导/驱动"
            let image = MyAsset.NSToolbarItem_Build.image
            image.isTemplate = true
            toolbarItem?.image = image
            break
            
        case efiIdentifier:
            toolbarItem?.label = "常见机型EFI分享"
            toolbarItem?.paletteLabel = "常见机型EFI分享"
            toolbarItem?.toolTip = "常见机型EFI分享"
            let image = MyAsset.NSToolbarItem_EFI.image
            image.isTemplate = true
            toolbarItem?.image = image
            break
            
        case diskIdentifier:
            toolbarItem?.label = "EFI分区挂载"
            toolbarItem?.paletteLabel = "EFI分区挂载"
            toolbarItem?.toolTip = "EFI分区挂载"
            let image = MyAsset.NSToolbarItem_Disk.image
            image.isTemplate = true
            toolbarItem?.image = image
            break
            
        case nvramIdentifier:
            toolbarItem?.label = "NVRAM信息"
            toolbarItem?.paletteLabel = "NVRAM信息"
            toolbarItem?.toolTip = "NVRAM信息"
            let image = MyAsset.NSToolbarItem_Nvram.image
            image.isTemplate = true
            toolbarItem?.image = image
            break
            
        case lockIdentifier:
            toolbarItem?.label = "更换登录壁纸"
            toolbarItem?.paletteLabel = "更换登录壁纸"
            toolbarItem?.toolTip = "更换登录壁纸"
            let image = MyAsset.NSToolbarItem_Lock.image
            image.isTemplate = true
            toolbarItem?.image = image
            break
            
        case ioregIdentifier:
            toolbarItem?.label = "白苹果ioreg信息"
            toolbarItem?.paletteLabel = "白苹果ioreg信息"
            toolbarItem?.toolTip = "白苹果ioreg信息"
            let image = MyAsset.NSToolbarItem_Ioreg.image
            image.isTemplate = true
            toolbarItem?.image = image
            break
            
        case gpuIdentifier:
            toolbarItem?.label = "显卡优化"
            toolbarItem?.paletteLabel = "显卡优化"
            toolbarItem?.toolTip = "显卡优化"
            let image = MyAsset.NSToolbarItem_GPU.image
            image.isTemplate = true
            toolbarItem?.image = image
            break
            
        case osIdentifier:
            toolbarItem?.label = "镜像下载"
            toolbarItem?.paletteLabel = "镜像下载"
            toolbarItem?.toolTip = "镜像下载"
            let image = MyAsset.NSToolbarItem_OS.image
            image.isTemplate = true
            toolbarItem?.image = image
            break
            
        case otherIdentifier:
            toolbarItem?.label = "其他小功能"
            toolbarItem?.paletteLabel = "其他小功能"
            toolbarItem?.toolTip = "其他一些可能需要的东西"
            let image = MyAsset.NSToolbarItem_Other.image
            image.isTemplate = true
            toolbarItem?.image = image
            break
            
        case payIdentifier:
            toolbarItem?.label = "关于捐赠"
            toolbarItem?.paletteLabel = "关于捐赠"
            toolbarItem?.toolTip = "酌情捐赠"
            let image = MyAsset.NSToolbarItem_Pay.image
            image.isTemplate = true
            toolbarItem?.image = image
            break
            
        default:
            toolbarItem = nil
            break
        }
        
        toolbarItem?.target = self
        toolbarItem?.action = #selector(toolbarItemDidTapped(_:))
        return toolbarItem
    }
     
    @objc func toolbarItemDidTapped(_ item: NSToolbarItem) {
        switch item.itemIdentifier {
        case infoIdentifier:
            self.window?.contentViewController = infoVC
            self.window?.setContentSize(NSSize(width: 790, height: 630))
            break
        case buildIdentifier:
            self.window?.contentViewController = buildVC
            self.window?.setContentSize(NSSize(width: 790, height: 630))
            break
        case efiIdentifier:
            self.window?.contentViewController = EFIVC
            self.window?.setContentSize(NSSize(width: 790, height: 630))
            break
        case diskIdentifier:
            self.window?.contentViewController = diskVC
            self.window?.setContentSize(NSSize(width: 790, height: 630))
            break
        case nvramIdentifier:
            self.window?.contentViewController = nvramVC
            self.window?.setContentSize(NSSize(width: 790, height: 630))
            break
        case lockIdentifier:
            self.window?.contentViewController = lockVC
            self.window?.setContentSize(NSSize(width: 790, height: 630))
            break
        case ioregIdentifier:
            self.window?.contentViewController = ioregVC
            self.window?.setContentSize(NSSize(width: 1200, height: 630))
            break
        case gpuIdentifier:
            self.window?.contentViewController = gpuVC
            self.window?.setContentSize(NSSize(width: 790, height: 630))
            break
        case osIdentifier:
            self.window?.contentViewController = osVC
            self.window?.setContentSize(NSSize(width: 790, height: 630))
            break
        case otherIdentifier:
            self.window?.contentViewController = otherVC
            self.window?.setContentSize(NSSize(width: 790, height: 630))
            break
        case payIdentifier:
            self.window?.contentViewController = payVC
            self.window?.setContentSize(NSSize(width: 790, height: 630))
            break
        default:
            break
        }
    }
}
