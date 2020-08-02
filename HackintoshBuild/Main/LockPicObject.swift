//
//  ViewControllerLock.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2020/1/31.
//  Copyright © 2020 bugprogrammer,Arabaku. All rights reserved.
//

import Cocoa

class LockPicObject: OutBaseObject {
    
    @IBOutlet weak var replaceButton: NSButton!
    @IBOutlet weak var resetButton: NSButton!
    @IBOutlet weak var lockImageView: NSImageView!
    @IBOutlet weak var locationImage: NSPathControl!
    
    let taskQueue = DispatchQueue.global(qos: .default)
    var output: String = ""
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        replaceButton.isEnabled = false
        resetButton.isEnabled = true
    }
    
    func selectedImage(_ url: String) -> Bool {
        let url = NSURL(fileURLWithPath: url)
        if url.pathExtension!.uppercased() == "PNG" {
            let image: NSImage = NSImage(contentsOf: url as URL)!
            lockImageView.image = image
            return true
        } else {
            lockImageView.image = NSImage()
            replaceButton.isEnabled = false
            let alert = NSAlert()
            alert.messageText = "请选择 PNG 格式图片"
            alert.runModal()
            return false
        }
    }
    
    @IBAction func showPicture(_ sender: Any) {
        if let urlImage = locationImage.url {
            let isPNG = selectedImage(urlImage.path)
            if isPNG {
                replaceButton.isEnabled = true
                resetButton.isEnabled = true
            }
        }
    }
    
    @IBAction func replaceButtonDidClicked(_ sender: Any) {
        if let urlImage = locationImage.url {
            MyLog(urlImage.path)
            runBuildScripts("changeLockPicture", [urlImage.path], "替换完成")
        }
    }
    
    @IBAction func resetButtonDidClicked(_ sender: Any) {
        runBuildScripts("resetLockPicture", [], "重置完成")
    }
    
    func runBuildScripts(_ shell: String,_ arguments: [String], _ alertText: String) {
        output = ""
        AraHUDViewController.shared.showHUD()
        taskQueue.async {
            if let path = Bundle.main.path(forResource: shell, ofType:"command") {
                let task = Process()
                task.launchPath = path
                task.arguments = arguments
                task.environment = ["PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:"]
                task.terminationHandler = { task in
                    DispatchQueue.main.async(execute: {
                        AraHUDViewController.shared.hideHUD()
                        let alert = NSAlert()
                        if self.output.contains("success") {
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
                DispatchQueue.main.async(execute: {
                    let previousOutput = self.output
                    let nextOutput = previousOutput + "\n" + outputString
                    self.output = nextOutput
                })
            }
        }
    }
    
}
