//
//  AppDelegate.swift
//  HackintoshBuild
//
//  Created by wbx on 2020/1/5.
//  Copyright © 2020 wbx. All rights reserved.
//

import Cocoa
import GitHubUpdates

//@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSToolbarItemValidation {
    
    @IBOutlet weak var window: NSWindow!
    
    let taskQueue = DispatchQueue.global(qos: .default)
    var outputPipe: Pipe!
    var sipStatusOutPut: String = ""
    var snapshotOutPut: String = ""
    var lastIndex = 0
    
    @IBOutlet weak var toolBar: NSToolbar!
    @IBOutlet weak var mainTabView: NSTabView!
    @IBOutlet weak var inTabView: NSTabView!
    @IBOutlet weak var subTabView: NSTabView!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        if #available(OSX 11.0, *) {
            minSizeForNormal = NSSize(width: 1100, height: 700)
            toolBar.displayMode = .iconAndLabel
        }
        
        let updater = GitHubUpdater()
        updater.user = "bugprogrammer"
        updater.repository = "HackintoshBuild"
        updater.checkForUpdatesInBackground()
        
        runSIPScripts("sipStatus", [], "")
        
        window.minSize = minSizeForNormal
        if let width = UserDefaults.standard.value(forKey: "windowSizeWidth") as? CGFloat, let height = UserDefaults.standard.value(forKey: "windowSizeHeight") as? CGFloat  {
            let size = CGSize(width: width, height: height)
            beforeSize = size
            if beforeSize.width * beforeSize.height < minSizeForNormal.width * minSizeForNormal.height {
                window.setContentSize(minSizeForNormal)
            } else {
                window.setContentSize(beforeSize)
                MyLog(beforeSize)
            }
        } else {
            window.setContentSize(minSizeForNormal)
        }
        
        // NSToolbar 适配深色和浅色模式
        for item in toolBar.items {
            item.image?.isTemplate = true
        }
        
        toolBar.selectedItemIdentifier = NSToolbarItem.Identifier(rawValue: "0")
        inTabView.selectTabViewItem(at: 0)
        window.center()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        UserDefaults.standard.set(beforeSize.width, forKey: "windowSizeWidth")
        UserDefaults.standard.set(beforeSize.height, forKey: "windowSizeHeight")
        runTerminateScripts("exit", [UserDefaults.standard.string(forKey: "OStmp") ?? ""])
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func runTerminateScripts(_ shell: String,_ arguments: [String]) {
        taskQueue.async {
            if let path = Bundle.main.path(forResource: shell, ofType:"command") {
                let task = Process()
                task.launchPath = path
                task.arguments = arguments
                task.environment = ["PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:"]
                task.launch()
                task.waitUntilExit()
            }
        }
    }
    
    
    
    func runSIPScripts(_ shell: String,_ arguments: [String], _ alertText: String) {
        AraHUDViewController.shared.showHUDWithTitle("正在整理必要信息", onView: window.contentView)
        taskQueue.async {
            if let path = Bundle.main.path(forResource: shell, ofType:"command") {
                let task = Process()
                task.launchPath = path
                task.arguments = arguments
                task.environment = ["PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:"]
                task.terminationHandler = { task in
                    DispatchQueue.main.async(execute: { [weak self] in
                        guard let `self` = self else { return }
                        self.runSnapshotScripts("Snapshot", [], "")
                    })
                }
                self.taskOutPut(task)
                task.launch()
                task.waitUntilExit()
                task.terminationHandler = { task in
                    DispatchQueue.main.async {
                        AraHUDViewController.shared.hideHUD()
                    }
                }
            }
        }
    }
    
    func runSnapshotScripts(_ shell: String,_ arguments: [String], _ alertText: String) {
        AraHUDViewController.shared.showHUDWithTitle("正在整理必要信息", onView: window.contentView)
        taskQueue.async {
            if let path = Bundle.main.path(forResource: shell, ofType:"command") {
                let task = Process()
                task.launchPath = path
                task.arguments = arguments
                task.environment = ["PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:"]
                self.taskOutPutSnapshot(task)
                task.launch()
                task.waitUntilExit()
                task.terminationHandler = { task in
                    DispatchQueue.main.async {
                        AraHUDViewController.shared.hideHUD()
                    }
                }
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
    
    func taskOutPutSnapshot(_ task:Process) {
        self.snapshotOutPut = ""
        outputPipe = Pipe()
        task.standardOutput = outputPipe
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading, queue: nil) { [weak self] notification in
            guard let `self` = self else { return }
            let output = self.outputPipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
            let previousOutput = self.snapshotOutPut
            let nextOutput = previousOutput + outputString
            self.snapshotOutPut = nextOutput

            if self.snapshotOutPut.replacingOccurrences(of: "\n", with: "") == "enabled" {
                MyLog("Snapshot status: enabled.")
                isSnapshotStatusEnabled = true
            } else {
                MyLog("Snapshot status: disabled.")
                isSnapshotStatusEnabled = false
            }
        }
    }
    
    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        var status: Bool = true
        if MyTool.isAppleSilicon() {
            if item.label == "NVRAM" || item.label == "安装Kexts" {
                status = false
            } else {
                status = true
            }
        }
        
        return status
    }

    @IBAction func toolBarDidClicked(_ sender: NSToolbarItem) {
        if AraHUDViewController.shared.isShowing {
            toolBar.selectedItemIdentifier = NSToolbarItem.Identifier(rawValue: String(lastIndex))
            return
        }
        
        let index = Int(sender.itemIdentifier.rawValue)!
        lastIndex = index
        // 两页需要设置最小值
        // 如果用户已经拖的比这个值大了，就不管了
        // 需要记忆用户拉的大小
        if (index != 6) {
            window.minSize = minSizeForNormal
            if !isFullScreen && !willFullScreen && !willExitFullScreen {
                if beforeSize.width * beforeSize.height < minSizeForNormal.width * minSizeForNormal.height {
                    window.setContentSize(minSizeForNormal)
                }
                else {
                    window.setContentSize(beforeSize)
                }
            }
        } else {
            window.minSize = minSizeForBig
            if (window.contentView!.bounds.width < minSizeForBig.width) || (window.contentView!.bounds.height < minSizeForBig.height) {
                window.setContentSize(minSizeForBig)
            }
        }
        
        self.mainTabView.selectTabViewItem(at: index)
        NotificationCenter.default.post(name: NSNotification.Name.TapChanged, object: index)
    }
}

extension AppDelegate: NSTabViewDelegate {
    func tabView(_ tabView: NSTabView, shouldSelect tabViewItem: NSTabViewItem?) -> Bool {
        if AraHUDViewController.shared.isShowing {
            return false
        }
        
        return true
    }
    
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        guard let identifier = tabViewItem?.identifier as? String else { return }
        let index = Int(identifier)!
        NotificationCenter.default.post(name: NSNotification.Name.InTapChanged, object: index)
    }
}

extension AppDelegate: NSWindowDelegate {
    
    func windowDidEndLiveResize(_ notification: Notification) {
        if isFullScreen || willFullScreen || willExitFullScreen { return }
        
        if let identifier = toolBar.selectedItemIdentifier?.rawValue {
            if let index = Int(identifier) {
                if (index != 6) {
                    beforeSize = window.contentView!.bounds.size
                }
            }
        }
    }
    
    func windowWillEnterFullScreen(_ notification: Notification) {
        willFullScreen = true
    }
    
    func windowWillExitFullScreen(_ notification: Notification) {
        willExitFullScreen = true
    }

    func windowDidEnterFullScreen(_ notification: Notification) {
        isFullScreen = true
        willFullScreen = false
    }
    
    func windowDidExitFullScreen(_ notification: Notification) {
        isFullScreen = false
        willExitFullScreen = false
        
        if let identifier = toolBar.selectedItemIdentifier?.rawValue {
            if let index = Int(identifier) {
                if (index != 6) {
                    window.setContentSize(beforeSize)
                }
            }
        }
    }
    
}

