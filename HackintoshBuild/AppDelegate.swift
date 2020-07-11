//
//  AppDelegate.swift
//  HackintoshBuild
//
//  Created by wbx on 2020/1/5.
//  Copyright © 2020 wbx. All rights reserved.
//

import Cocoa

//@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var window: NSWindow!
    
    let taskQueue = DispatchQueue.global(qos: .default)
    public var isSIPStatusEnabled: Bool? = nil
    var outputPipe: Pipe!
    var sipStatusOutPut: String = ""
    
    @IBOutlet weak var toolBar: NSToolbar!
    @IBOutlet weak var mainTabView: NSTabView!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        runSIPScripts("sipStatus", [], "")
        toolBar.selectedItemIdentifier = NSToolbarItem.Identifier(rawValue: "0")
        
        window.center()
        
        if let width = UserDefaults.standard.value(forKey: "windowSizeWidth") as? CGFloat, let height = UserDefaults.standard.value(forKey: "windowSizeHeight") as? CGFloat  {
            let size = CGSize(width: width, height: height)
            window.setContentSize(size)
            beforeSize = size
        } else {
            window.setContentSize(minSizeForNormal)
        }
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
                    self.isSIPStatusEnabled = true
                } else {
                    MyLog("SIP status: disabled.")
                    self.isSIPStatusEnabled = false
                }
            }
        }
    }

    @IBAction func toolBarDidClicked(_ sender: NSToolbarItem) {
        let index = Int(sender.itemIdentifier.rawValue)!
        
        // 两页需要设置最小值
        // 如果用户已经拖的比这个值大了，就不管了
        // 需要记忆用户拉的大小
        if (index != 6) && (index != 9) {
            window.minSize = minSizeForNormal
            if !isFullScreen && !willFullScreen && !willExitFullScreen {
                window.setContentSize(beforeSize)
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

extension AppDelegate: NSWindowDelegate {
    
    func windowDidEndLiveResize(_ notification: Notification) {
        if isFullScreen || willFullScreen || willExitFullScreen { return }
        
        if let identifier = toolBar.selectedItemIdentifier?.rawValue {
            if let index = Int(identifier) {
                if (index != 6) && (index != 9) {
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
                if (index != 6) && (index != 9) {
                    window.setContentSize(beforeSize)
                }
            }
        }
    }
    
}

