//
//  ViewControllerOther.swift
//  HackintoshBuild
//
//  Created by 刘靖禹 on 2020/1/17.
//  Copyright © 2020 Arabaku. All rights reserved.
//

import Cocoa

class ViewControllerOther: NSViewController {
    
    @IBOutlet var output: NSTextView!
    @IBOutlet var progressBar: NSProgressIndicator!
    
    var task:Process!
    var outputPipe:Pipe!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        progressBar.isHidden = true
    }
    
    @IBAction func unlockSLE(_ sender: Any) {
        
        output.string = ""
        progressBar.isHidden = true
        
        if #available(OSX 10.15, *) {
            runBuildScripts("unlockSLE", "SLE解锁成功")
        }

        else {
            let alert = NSAlert()
            alert.messageText = "系统版本低于10.15，无需解锁"
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
        let taskQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        taskQueue.async {
            if let path = Bundle.main.path(forResource: shell, ofType:"command") {
                self.task = Process()
                self.task.launchPath = path
                self.task.terminationHandler = { task in
                    DispatchQueue.main.async(execute: {
                        self.progressBar.isHidden = true
                        self.progressBar.stopAnimation(self)
                        self.progressBar.doubleValue = 0.0
                        let alert = NSAlert()
                        alert.messageText = alertText
                        alert.runModal()
                    })
                }
                self.taskOutPut(self.task)
                self.task.launch()
                self.task.waitUntilExit()
            }
        }
    }
    
    func taskOutPut(_ task:Process) {
        outputPipe = Pipe()
        task.standardOutput = outputPipe
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading , queue: nil) {
            notification in
            let output = self.outputPipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
            DispatchQueue.main.async(execute: {
                let previousOutput = self.output.string
                let nextOutput = previousOutput + "\n" + outputString
                self.output.string = nextOutput
                let range = NSRange(location:nextOutput.count,length:0)
                self.output.scrollRangeToVisible(range)
                self.progressBar.increment(by: 1.9)
            })
            self.outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        }
    }
    
}
