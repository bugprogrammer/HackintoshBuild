//
//  BaseWindowController.swift
//  HackintoshBuild
//
//  Created by 刘靖禹 on 2020/1/17.
//  Copyright © 2020 Arabaku. All rights reserved.
//

import Cocoa

class BaseWindowController: NSWindowController {

    let buildIdentifier = NSToolbarItem.Identifier(rawValue: "bugprogrammer.HackintoshBuild.NSToolbarItem.buildIdentifier")
    let efiIdentifier = NSToolbarItem.Identifier(rawValue: "bugprogrammer.HackintoshBuild.NSToolbarItem.efiIdentifier")
    let diskIdentifier = NSToolbarItem.Identifier(rawValue: "bugprogrammer.HackintoshBuild.NSToolbarItem.diskIdentifier")
    let nvramIdentifier = NSToolbarItem.Identifier(rawValue: "bugprogrammer.HackintoshBuild.NSToolbarItem.nvramIdentifier")
    let lockIdentifier = NSToolbarItem.Identifier(rawValue: "bugprogrammer.HackintoshBuild.NSToolbarItem.lockIdentifier")
    let otherIdentifier = NSToolbarItem.Identifier(rawValue: "bugprogrammer.HackintoshBuild.NSToolbarItem.otherIdentifier")
    
    let taskQueue = DispatchQueue.global(qos: .background)
    let lock = NSLock()
    var task: Process!
    var outputPipe: Pipe!
    var sipStatus: String = ""
    
    override func windowDidLoad() {
        super.windowDidLoad()
        setupToolbar()
        runBuildScripts("sipStatus", [], "")
    }
    
    func runBuildScripts(_ shell: String,_ arguments: [String], _ alertText: String) {
        taskQueue.async {
            if let path = Bundle.main.path(forResource: shell, ofType:"command") {
                let task = Process()
                task.launchPath = path
                task.arguments = arguments
                task.terminationHandler = { task in
                    DispatchQueue.main.async(execute: { [weak self] in
                        guard let `self` = self else { return }
                        self.lock.lock()
                        
                            if self.sipStatus.contains("enabled") {
                                self.sipStatus = "SIP未关闭,请先关闭SIP"
                            }
                            else {
                                self.sipStatus = "SIP已关闭"
                            }
                            
                        UserDefaults().setValue(self.sipStatus, forKey: "sipStatus")

                        self.lock.unlock()
                    })
                }
                self.taskOutPut(task)
                task.launch()
                task.waitUntilExit()
            }
        }
    }
    
    func taskOutPut(_ task:Process) {
        self.sipStatus = ""
        outputPipe = Pipe()
        task.standardOutput = outputPipe
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading , queue: nil) {
            notification in
            let output = self.outputPipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
                DispatchQueue.main.async(execute: {
                    let previousOutput = self.sipStatus
                    let nextOutput = previousOutput + outputString
                    self.sipStatus = nextOutput
                })
        }
    }
    
    func setupToolbar() {
        let toolBar = NSToolbar(identifier: "bugprogrammer.HackintoshBuild.NSToolbar.MyToolbar")
//        toolBar.allowsUserCustomization = false
//        toolBar.autosavesConfiguration = false
        toolBar.displayMode = .iconAndLabel
        toolBar.sizeMode = .default
        toolBar.delegate = self
        toolBar.selectedItemIdentifier = buildIdentifier
        self.window?.toolbar = toolBar // retain
    }

}

extension BaseWindowController: NSToolbarDelegate {
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [buildIdentifier, efiIdentifier, diskIdentifier, nvramIdentifier, lockIdentifier, otherIdentifier]
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [buildIdentifier, efiIdentifier, diskIdentifier, nvramIdentifier, lockIdentifier, otherIdentifier]
    }
    
    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [buildIdentifier, efiIdentifier, diskIdentifier, nvramIdentifier, lockIdentifier, otherIdentifier]
    }
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        var toolbarItem: NSToolbarItem? = NSToolbarItem(itemIdentifier: itemIdentifier)
        switch itemIdentifier {
        case buildIdentifier:
            toolbarItem?.label = "编译"
            toolbarItem?.paletteLabel = "编译"
            toolbarItem?.toolTip = "编译一些常用的引导/驱动"
            toolbarItem?.image = MyAsset.NSToolbarItem_Build.image
            break
            
        case efiIdentifier:
            toolbarItem?.label = "常见机型EFI分享"
            toolbarItem?.paletteLabel = "常见机型EFI分享"
            toolbarItem?.toolTip = "常见机型EFI分享"
            toolbarItem?.image = MyAsset.NSToolbarItem_EFI.image
            break
            
        case diskIdentifier:
            toolbarItem?.label = "EFI分区挂载"
            toolbarItem?.paletteLabel = "EFI分区挂载"
            toolbarItem?.toolTip = "EFI分区挂载"
            toolbarItem?.image = MyAsset.NSNSToolbarItem_Disk.image
            break
            
        case nvramIdentifier:
            toolbarItem?.label = "NVRAM信息"
            toolbarItem?.paletteLabel = "NVRAM信息"
            toolbarItem?.toolTip = "NVRAM信息"
            toolbarItem?.image = MyAsset.NSNSToolbarItem_Nvram.image
            break
            
        case lockIdentifier:
            toolbarItem?.label = "更换登录壁纸"
            toolbarItem?.paletteLabel = "更换登录壁纸"
            toolbarItem?.toolTip = "更换登录壁纸"
            toolbarItem?.image = MyAsset.NSNSToolbarItem_Lock.image
            break
            
        case otherIdentifier:
            toolbarItem?.label = "其他小功能"
            toolbarItem?.paletteLabel = "其他小功能"
            toolbarItem?.toolTip = "其他一些可能需要的东西"
            toolbarItem?.image = MyAsset.NSToolbarItem_Other.image
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
        case buildIdentifier:
            self.window?.contentViewController = MyTool.getViewControllerFromMain(ViewControllerBuild.self)
            break
        case efiIdentifier:
            self.window?.contentViewController = MyTool.getViewControllerFromMain(ViewControllerEFI.self)
            break
        case diskIdentifier:
            self.window?.contentViewController = MyTool.getViewControllerFromMain(ViewControllerDisk.self)
            break
        case nvramIdentifier:
            self.window?.contentViewController = MyTool.getViewControllerFromMain(ViewControllerNvram.self)
            break
        
        case lockIdentifier:
            self.window?.contentViewController = MyTool.getViewControllerFromMain(ViewControllerLock.self)
            break
        case otherIdentifier:
            self.window?.contentViewController = MyTool.getViewControllerFromMain(ViewControllerOther.self)
            break
        default:
            break
        }
    }
}
