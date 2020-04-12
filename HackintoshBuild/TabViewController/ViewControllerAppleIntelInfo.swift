//
//  ViewControllerAppleIntelInfo.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2020/2/29.
//  Copyright © 2020 bugprogrammer. All rights reserved.
//

import Cocoa

class ViewControllerAppleIntelInfo: NSViewController {

    @IBOutlet weak var refreshButton: NSButton!
    var output: String = ""
    @IBOutlet var outputInfo: NSTextView!
    let taskQueue = DispatchQueue.global(qos: .default)
    let url = Bundle.main.path(forResource: "AppleIntelInfo", ofType: "kext", inDirectory: "tools")
    @IBOutlet weak var sipLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshButton.isEnabled = false
        let image = MyAsset.refresh1.image
        image.isTemplate = true
        refreshButton.image = image
        refreshButton.bezelStyle = .recessed
        refreshButton.isBordered = false
        
        guard let enabled = isSIPStatusEnabled else {
            sipLabel.textColor = NSColor.red
            sipLabel.stringValue = "SIP 状态未知"
            return
        }
        if enabled {
            sipLabel.textColor = NSColor.red
            sipLabel.stringValue = "SIP 未关闭，请先关闭 SIP"
        } else {
            sipLabel.textColor = NSColor(named: "ColorGreen")
            sipLabel.stringValue = "SIP 已关闭"
            runBuildScripts("AppleIntelInfo", [url!])
        }
    }
    
    @IBAction func Refresh(_ sender: Any) {
        outputInfo.string = ""
        refreshButton.isEnabled = false
        runBuildScripts("AppleIntelInfo", [url!])
    }
    
    func runBuildScripts(_ shell: String,_ arguments: [String]) {
        self.output = ""
        AraHUDViewController.shared.showHUDWithTitle(title: "正在进行中")
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
