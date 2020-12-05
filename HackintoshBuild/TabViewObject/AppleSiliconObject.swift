//
//  AppleSiliconObject.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2020/12/3.
//  Copyright © 2020 bugprogrammer. All rights reserved.
//

import Cocoa

class AppleSiliconObject: InBaseObject {
    
    class Applications {
        var name: String
        var arch: String
        var version: String
        
        init(name: String, arch: String, version: String) {
            self.name = name
            self.arch = arch
            self.version = version
        }
    }
    
    var applications: [Applications] = []
    
    @IBOutlet weak var refresh: NSButton!
    @IBOutlet weak var tableview: NSTableView!
    
    let taskQueue = DispatchQueue.global(qos: .default)
    var output: String = ""
    var mainDict: NSDictionary = [:]
    var dictArray: NSArray = []
    
    override func willAppear(_ noti: Notification) {
        super.willAppear(noti)
        
        let index = noti.object as! Int
        if index != 7 { return }
        if !once { return }
        once = false
        let image = MyAsset.refresh.image
        image.isTemplate = true
        refresh.image = image
        refresh.isBordered = false
        refresh.bezelStyle = .recessed
        refresh.isEnabled = false
        runBuildScripts("AppleSilicon")
    }
    
    @IBAction func refresh(_ sender: Any) {
        refresh.isEnabled = false
        applications = []
        tableview.reloadData()
        runBuildScripts("AppleSilicon")
    }
    
    func runBuildScripts(_ shell: String) {
        self.output = ""
        AraHUDViewController.shared.showHUD()
        taskQueue.async {
            if let path = Bundle.main.path(forResource: shell, ofType:"command") {
                let task = Process()
                task.launchPath = path
                task.environment = ["PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:"]
                task.terminationHandler = { task in
                    DispatchQueue.main.async(execute: { [weak self] in
                        guard let `self` = self else { return }
                        AraHUDViewController.shared.hideHUD()
                        var appArray = self.output.replacingOccurrences(of: " ", with: "").components(separatedBy: "\n")
                        if appArray.first == "" {
                            appArray.removeFirst()
                        }
                        if appArray.last == "" {
                            appArray.removeLast()
                        }
                        for i in stride(from: 0, to: appArray.count - 4, by: 4) {
                            if appArray[i+3].components(separatedBy: ":").first != "version" {
                                appArray.insert("无", at: i+3)
                            }
                        }
                        for item in appArray {
                            MyLog(item + "\n")
                        }
                        MyLog(appArray.count)
                        for i in stride(from: 0, to: appArray.count - 4, by: 4) {
                            if appArray[i+2] != "obtained_from:apple" {
                                self.applications.append(Applications(name: appArray[i].components(separatedBy: ":").last!, arch: appArray[i+1].components(separatedBy: ":").last!, version: appArray[i+3].components(separatedBy: ":").last!))                                
                            }
                        }
                        self.tableview.reloadData()
                        self.refresh.isEnabled = true
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
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading, queue: nil) { notification in
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

extension AppleSiliconObject: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return applications.count
    }
}

extension AppleSiliconObject: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, shouldTrackCell cell: NSCell, for tableColumn: NSTableColumn?, row: Int) -> Bool {
        return true
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if tableColumn != nil {
            let identifier = tableColumn!.identifier.rawValue
            switch identifier {
            case "name":
                let textField = NSTextField()
                textField.cell = VerticallyCenteredTextFieldCell()
                textField.stringValue = self.applications[row].name
                textField.alignment = .left
                textField.isBordered = false
                return textField
            case "version":
                let textField = NSTextField()
                textField.cell = VerticallyCenteredTextFieldCell()
                textField.stringValue = self.applications[row].version
                textField.alignment = .left
                textField.isBordered = false
                return textField
            case "type":
                let textField = NSTextField()
                textField.cell = VerticallyCenteredTextFieldCell()
                switch self.applications[row].arch {
                case "arch_arm_i64":
                    textField.stringValue = "通用"
                case "arch_i64":
                    textField.stringValue = "Intel"
                case "arch_ios":
                    textField.stringValue = "IOS"
                case "arch_arm":
                    textField.stringValue = "仅Apple芯片"
                case "arch_other":
                    textField.stringValue = "不确定"
                default:
                    textField.stringValue = "不确定"
                }
                textField.alignment = .left
                textField.isBordered = false
                return textField
            case "result":
                let button = NSButton()
                button.setButtonType(.radio)
                button.bezelStyle = .inline
                button.title = ""
                button.alignment = .right
                if self.applications[row].arch == "arch_arm_i64" || self.applications[row].arch == "arch_arm" || self.applications[row].arch == "arch_ios" {
                    button.state = .on
                    button.bezelColor = .green
                }
                else {
                    button.isHidden = true
                }
                return button
            default:
                return nil
            }
        }
        return nil
    }
    
}
