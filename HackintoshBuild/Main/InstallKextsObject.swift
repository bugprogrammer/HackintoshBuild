//
//  InstallKextsObject.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2020/7/29.
//  Copyright © 2020 bugprogrammer. All rights reserved.
//

import Cocoa

class InstallKextsObject: OutBaseObject {
    @IBOutlet weak var dragDropView: DragDropView!
    @IBOutlet weak var sipLabel: NSTextField!
    @IBOutlet weak var snapshotLabel: NSTextField!
    @IBOutlet weak var textField: NSTextField!
    
    let taskQueue = DispatchQueue.global(qos: .default)
    
    override func willAppear(_ noti: Notification) {
        super.willAppear(noti)
        
        let index = noti.object as! Int
        if index != 9 { return }
        if !once { return }
        once = false
        
        let sip = sipStatus()
        
        dragDropView.backgroundColor = NSColor(named: "ColorGray")
        dragDropView.acceptedFileExtensions = ["kext"]
        dragDropView.usedArrowImage = false
        dragDropView.setup({ (file) in
            if sip {
                var url = file.absoluteString.replacingOccurrences(of: "file://", with: "")
                url = url.replacingOccurrences(of: "\n", with: "")
                url.remove(at: url.index(before: url.endIndex))
                MyLog(url)
                self.runBuildScripts("kextsInstaller", [url])
            } else {
                let alert = NSAlert()
                alert.messageText = "sip 或快照未解锁，不能安装 Kexts"
                alert.runModal()
            }
        }) { (files) in
            if sip {
                var kexts: String = ""
                for file in files {
                    var url = file.absoluteString.replacingOccurrences(of: "file://", with: "")
                    url = url.replacingOccurrences(of: "\n", with: "")
                    url.remove(at: url.index(before: url.endIndex))
                    kexts.append(url + ",")
                }
                if kexts.last == "," {
                    kexts.removeLast()
                }
                MyLog(kexts)
                self.runBuildScripts("kextsInstaller", [kexts])
            } else {
                let alert = NSAlert()
                alert.messageText = "sip 或快照未解锁，不能安装 Kexts"
                alert.runModal()
            }
        }
    }
    
    func sipStatus() -> Bool {
        var status: Bool = false
        guard let sipEnabled = isSIPStatusEnabled else {
            sipLabel.textColor = NSColor.red
            sipLabel.stringValue = "SIP 状态未知"
            status = false
            return status
        }
        if #available(OSX 10.16, *) {
            guard let snapshotEnabled = isSnapshotStatusEnabled else {
                snapshotLabel.textColor = NSColor.red
                snapshotLabel.stringValue = "快照 状态未知"
                status = false
                return status
            }
            if sipEnabled && !snapshotEnabled {
                sipLabel.textColor = NSColor.red
                sipLabel.stringValue = "SIP 未关闭，请先关闭 SIP"
                snapshotLabel.textColor = NSColor(named: "ColorGreen")
                snapshotLabel.stringValue = "快照 已删除"
                status = false
            }
            else if !sipEnabled && snapshotEnabled {
                sipLabel.textColor = NSColor(named: "ColorGreen")
                sipLabel.stringValue = "SIP 已关闭"
                snapshotLabel.textColor = NSColor.red
                snapshotLabel.stringValue = "快照 未删除，请先删除 快照"
                status = false
            }
            else if sipEnabled && snapshotEnabled {
                sipLabel.textColor = NSColor.red
                sipLabel.stringValue = "SIP 未关闭，请先关闭 SIP"
                snapshotLabel.textColor = NSColor.red
                snapshotLabel.stringValue = "快照 未删除，请先删除 快照"
                status = false
            }
            else {
                sipLabel.textColor = NSColor(named: "ColorGreen")
                sipLabel.stringValue = "SIP 已关闭"
                snapshotLabel.textColor = NSColor(named: "ColorGreen")
                snapshotLabel.stringValue = "快照 已删除"
                status = true
            }
        } else {
            if sipEnabled {
                sipLabel.textColor = NSColor.red
                sipLabel.stringValue = "SIP 未关闭，请先关闭 SIP"
                snapshotLabel.stringValue = ""
                status = false
            } else {
                sipLabel.textColor = NSColor(named: "ColorGreen")
                sipLabel.stringValue = "SIP 已关闭"
                snapshotLabel.stringValue = ""
                status = true
            }
        }
        return status
    }
    
    func runBuildScripts(_ shell: String, _ arguments: [String]) {
        AraHUDViewController.shared.showHUD()
        taskQueue.async {
            if let path = Bundle.main.path(forResource: shell, ofType:"command") {
                let task = Process()
                task.launchPath = path
                task.arguments = arguments
                MyLog(arguments)
                task.environment = ["PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:"]
                task.terminationHandler = { _ in
                    DispatchQueue.main.async {
                        AraHUDViewController.shared.hideHUD()
                    }
                }
                //self.taskOutPut(task)
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
                    let previousOutput = self.textField.stringValue
                    let nextOutput = previousOutput + outputString
                    self.textField.stringValue = nextOutput
                })
            }
        }
    }
}

extension DragDropView {

    var backgroundColor: NSColor? {
        get {
            if let colorRef = self.layer?.backgroundColor {
                return NSColor(cgColor: colorRef)
            } else {
                return nil
            }
        }
        set {
            self.wantsLayer = true
            self.layer?.backgroundColor = newValue?.cgColor
        }
    }
}

