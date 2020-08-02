//
//  ViewControllerAppleIntelInfo.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2020/2/29.
//  Copyright © 2020 bugprogrammer. All rights reserved.
//

import Cocoa

class AppleIntelInfoObject: InBaseObject {

    @IBOutlet weak var refreshButton: NSButton!
    @IBOutlet var outputInfo: NSTextView!
    @IBOutlet weak var sipLabel: NSTextField!
    
    var output: String = ""
    let taskQueue = DispatchQueue.global(qos: .default)
    let url = Bundle.main.path(forResource: "AppleIntelInfo", ofType: "kext", inDirectory: "tools")
    
    override func willAppear(_ noti: Notification) {
        super.willAppear(noti)
        
        let index = noti.object as! Int
        if index != 2 { return }
        if !once { return }
        once = false
        
        guard let enabled = isSIPStatusEnabled else {
            sipLabel.textColor = NSColor.red
            sipLabel.stringValue = "SIP 状态未知，无法使用本功能"
            refreshButton.isEnabled = false
            return
        }
        if enabled {
            sipLabel.textColor = NSColor.red
            sipLabel.stringValue = "SIP 未关闭，无法使用本功能"
            refreshButton.isEnabled = false
        } else {
            sipLabel.textColor = NSColor(named: "ColorGreen")
            sipLabel.stringValue = "SIP 已关闭"
            refreshButton.isEnabled = true
        }
        
        refreshButtonDidClicked(nil)
    }
    
    override func awakeFromNib() {
        let image = NSImage(named: "NSRefreshFreestandingTemplate")
        image?.size = CGSize(width: 64.0, height: 64.0)
        image?.isTemplate = true
        refreshButton.image = image
        refreshButton.bezelStyle = .recessed
        refreshButton.isBordered = false
        refreshButton.toolTip = "刷新 AppleIntelInfo 信息"
    }
    
    @IBAction func refreshButtonDidClicked(_ sender: NSButton?) {
        if MyTool.isAMDProcessor() {
            let alert = NSAlert()
            alert.messageText = "AMD CPU 无法使用本功能"
            alert.runModal()
            refreshButton.isEnabled = false
            return
        }
        
        if #available(OSX 10.16, *) {
            let alert = NSAlert()
            alert.messageText = "macOS Big Sur无法使用本功能"
            alert.runModal()
            refreshButton.isEnabled = false
            return
        }
        
        guard let enabled = isSIPStatusEnabled else { return }
        if !enabled {
            outputInfo.string = ""
            refreshButton.isEnabled = false
            runBuildScripts("AppleIntelInfo", [url!])
        }
    }
    
    func runBuildScripts(_ shell: String,_ arguments: [String]) {
        self.output = ""
        AraHUDViewController.shared.showHUD()
        taskQueue.async {
            if let path = Bundle.main.path(forResource: shell, ofType:"command") {
                let task = Process()
                task.launchPath = path
                task.arguments = arguments
                task.environment = ["PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:"]
                task.terminationHandler = { task in
                DispatchQueue.main.async(execute: { [weak self] in
                    guard let `self` = self else { return }
                    if !self.output.isEmpty {
                        self.outputInfo.string = self.output
                    }
                    else {
                        let alert = NSAlert()
                        alert.messageText = "获取AppleIntelInfo信息失败"
                        alert.runModal()
                    }
                    self.refreshButton.isEnabled = true
                    AraHUDViewController.shared.hideHUD()
                })
                }
                self.taskOutPut(task)
                task.launch()
                task.waitUntilExit()
            }
        }
    }
    
    func taskOutPut(_ task:Process) {
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading , queue: nil) { notification in
            let output = outputPipe.fileHandleForReading.availableData
            if output.count > 0 {
                outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
                let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
                DispatchQueue.main.async(execute: {
                    let previousOutput = self.output
                    let nextOutput = previousOutput + outputString
                    self.output = nextOutput
                })
            }
        }
    }
    
}
