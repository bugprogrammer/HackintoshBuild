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
    @IBOutlet weak var dragDropView: DragDropView!
    @IBOutlet weak var textFiled: NSTextField!
    
    let taskQueue = DispatchQueue.global(qos: .default)
    var output: String = ""
    var imageURL: URL!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        replaceButton.isEnabled = false
        resetButton.isEnabled = true
        lockImageView.isHidden = true
        
        dragDropView.backgroundColor = NSColor(named: "ColorGray")
        dragDropView.acceptedFileExtensions = ["png"]
        dragDropView.usedArrowImage = false
        dragDropView.setup({ (file) in
            self.lockImageView.isHidden = false
            self.dragDropView.backgroundColor = NSColor.clear
            self.textFiled.isHidden = true
            self.selectedImage(file)
            self.imageURL = file
        }) { (files) in
            let alert = NSAlert()
            alert.messageText = "只支持拖入一张壁纸"
            alert.runModal()
        }
    }
    
    func selectedImage(_ url: URL) {
        let image: NSImage = NSImage(contentsOf: url)!
        image.size = lockImageView.frame.size
        lockImageView.imageScaling = .scaleAxesIndependently
        lockImageView.image = image
        replaceButton.isEnabled = true
    }
    
    @IBAction func replaceButtonDidClicked(_ sender: Any) {
        MyLog(imageURL.absoluteString.replacingOccurrences(of: "file://", with: ""))
        runBuildScripts("changeLockPicture", [imageURL.absoluteString.replacingOccurrences(of: "file://", with: "")], "替换完成")
    }
    
    @IBAction func resetButtonDidClicked(_ sender: Any) {
        runBuildScripts("resetLockPicture", [], "重置完成")
    }
    
    func runBuildScripts(_ shell: String,_ arguments: [String], _ alertText: String) {
        output = ""
        taskQueue.async {
            if let path = Bundle.main.path(forResource: shell, ofType:"command") {
                let task = Process()
                task.launchPath = path
                task.arguments = arguments
                task.environment = ["PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:"]
                task.terminationHandler = { task in
                    DispatchQueue.main.async(execute: {
                        let alert = NSAlert()
                        if self.output.contains("success") {
                            alert.messageText = alertText
                        } else {
                            alert.messageText = "操作失败"
                        }
                        alert.runModal()
                        self.dragDropView.backgroundColor = NSColor(named: "ColorGray")
                        self.lockImageView.isHidden = true
                        self.textFiled.isHidden = false
                        self.replaceButton.isEnabled = false
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
