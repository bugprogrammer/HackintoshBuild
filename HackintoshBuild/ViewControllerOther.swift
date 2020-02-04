//
//  ViewControllerOther.swift
//  HackintoshBuild
//
//  Created by 刘靖禹 on 2020/1/17.
//  Copyright © 2020 Arabaku. All rights reserved.
//

import Cocoa

class ViewControllerOther: NSViewController {
    
    @IBOutlet weak var sipLable: NSTextField!
    @IBOutlet var output: NSTextView!
    @IBOutlet var progressBar: NSProgressIndicator!
    @IBOutlet weak var unclockButton: NSButton!
    @IBOutlet weak var rebuildButton: NSButton!
    @IBOutlet weak var spctlButton: NSButton!
    
    let taskQueue = DispatchQueue.global(qos: .background)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        progressBar.isHidden = true
        spctlButton.isEnabled = true
        guard let enabled = isSIPStatusEnabled else {
            sipLable.textColor = NSColor.red
            sipLable.stringValue = "SIP 状态未知"
            unclockButton.isEnabled = false
            rebuildButton.isEnabled = false
            return
        }
        if enabled {
            sipLable.textColor = NSColor.red
            sipLable.stringValue = "SIP 未关闭，请先关闭 SIP"
            unclockButton.isEnabled = false
            rebuildButton.isEnabled = false
        } else {
            sipLable.textColor = NSColor.green
            sipLable.stringValue = "SIP 已关闭"
            unclockButton.isEnabled = true
            rebuildButton.isEnabled = true
        }
    }
    
    @IBAction func unlockSLE(_ sender: Any) {
        
        output.string = ""
        progressBar.isHidden = true
        
        if #available(OSX 10.15, *) {
            runBuildScripts("unlockSLE", "SLE 解锁成功")
        } else {
            let alert = NSAlert()
            alert.messageText = "系统版本低于 10.15，无需解锁"
            alert.runModal()
        }
    }
    
    @IBAction func rebuildCache(_ sender: Any) {
        progressBar.isHidden = false
        output.string = ""
        self.progressBar.startAnimation(self)
        
        runBuildScripts("rebuildCache", "修复权限以及重建缓存成功")
    }
    
    @IBAction func spctl(_ sender: Any) {
        output.string = ""
        progressBar.isHidden = true
        
        runBuildScripts("spctl", "已开启未知来源安装")
    }
    
    func runBuildScripts(_ shell: String,_ alertText: String) {
        AraHUDViewController.shared.showHUDWithTitle(title: "正在进行中")
        taskQueue.async {
            if let path = Bundle.main.path(forResource: shell, ofType:"command") {
                let task = Process()
                task.launchPath = path
                task.terminationHandler = { task in
                    DispatchQueue.main.async(execute: { [weak self] in
                        guard let `self` = self else { return }
                        self.progressBar.isHidden = true
                        self.progressBar.stopAnimation(self)
                        self.progressBar.doubleValue = 0.0
                        AraHUDViewController.shared.hideHUD()
                        
                        let alert = NSAlert()
                        if self.output.string.contains("success") {
                            alert.messageText = alertText
                        } else {
                            alert.messageText = "操作失败"
                        }
                        alert.runModal()
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
                MyLog(outputString)
                DispatchQueue.main.async(execute: {
                    let previousOutput = self.output.string
                    let nextOutput = previousOutput + "\n" + outputString
                    self.output.string = nextOutput
                    let range = NSRange(location:nextOutput.count,length:0)
                    self.output.scrollRangeToVisible(range)
                    self.progressBar.increment(by: 1.9)
                })
            }
        }
    }
    
}
