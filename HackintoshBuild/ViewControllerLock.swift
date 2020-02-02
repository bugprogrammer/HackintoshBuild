//
//  ViewControllerLock.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2020/1/31.
//  Copyright © 2020 bugprogrammer. All rights reserved.
//

import Cocoa

class ViewControllerLock: NSViewController {
    
    @IBOutlet weak var replaceButton: NSButton!
    @IBOutlet weak var resetButton: NSButton!
    @IBOutlet weak var lockImageView: NSImageView!
    @IBOutlet weak var locationImage: NSPathControl!
    @IBOutlet weak var sipLabel: NSTextField!
    var task: Process!
    var sipStatus: String = ""
    
    let taskQueue = DispatchQueue.global(qos: .background)
    let lock = NSLock()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        sipStatus = UserDefaults().string(forKey: "sipStatus") ?? ""
        if sipStatus == "SIP已关闭" {
            sipLabel.textColor = NSColor.green
            sipLabel.stringValue = "SIP已关闭"
            replaceButton.isEnabled = false
            resetButton.isEnabled = true
        }
        else {
            sipLabel.textColor = NSColor.red
            sipLabel.stringValue = "SIP未关闭,请先关闭SIP"
            replaceButton.isEnabled = false
            resetButton.isEnabled = false
        }
    }
    
    func selectedImage(_ url: String) -> Bool {
        let url = NSURL(fileURLWithPath: url)
        if url.pathExtension!.uppercased() == "PNG" {
            let image: NSImage = NSImage(contentsOf: url as URL)!
            lockImageView.image = image
            return true
        }
        else {
            lockImageView.image = NSImage()
            if self.sipStatus == "SIP已关闭" {
                self.replaceButton.isEnabled = false
                self.resetButton.isEnabled = true
            }
            else {
                self.replaceButton.isEnabled = false
                self.resetButton.isEnabled = false
            }
            let alert = NSAlert()
            alert.messageText = "请选择PNG格式图片"
            alert.runModal()
            return false
        }
    }
    
    @IBAction func showPicture(_ sender: Any) {
        if let urlImage = locationImage.url {
            let isPNG = selectedImage(urlImage.path)
            if self.sipStatus == "SIP已关闭" && isPNG {
                replaceButton.isEnabled = true
                resetButton.isEnabled = true
            }
            MyLog(urlImage.path)
        }
    }
    
    @IBAction func Replace(_ sender: Any) {
        if let urlImage = locationImage.url {
            MyLog(urlImage.path)
            runBuildScripts("changeLockPicture", [urlImage.path], "替换完成")
        }
    }
    
    @IBAction func Reset(_ sender: Any) {
        runBuildScripts("resetLockPicture", [], "重置完成")
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
                        let alert = NSAlert()
                        alert.messageText = alertText
                        alert.runModal()
                        self.lock.unlock()
                    })
                }
                task.launch()
                task.waitUntilExit()
            }
        }
    }
    
}
