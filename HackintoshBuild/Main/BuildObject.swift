//
//  ViewController.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2020/1/5.
//  Copyright © 2020 bugprogrammer. All rights reserved.
//

import Cocoa

class BuildObject: OutBaseObject {
    
    @IBOutlet var buildText: NSTextView!
    @IBOutlet weak var stopButton: NSButton!
    @IBOutlet weak var buildButton: NSButton!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var pluginsView: NSTableView!
    @IBOutlet weak var buildLocation: NSPathControl!
    @IBOutlet weak var logsLocation: NSPathControl!
    @IBOutlet weak var proxyTextField: NSTextField!
    @IBOutlet weak var selectAllButton: NSButton!
    
    let taskQueue = DispatchQueue.global(qos: .default)
    let alert = NSAlert()
    var selectAll: Int = 0
    var isRunning: Bool = false
    var kextPath: String = ""
    var logsPath: String = ""
    
    let toolspath = Bundle.main.path(forResource: "nasm", ofType: "", inDirectory: "tools")
    
    let pluginsList: [String] = [
        "OpenCore",
        "Lilu",
        "AirportBrcmFixup",
        "AppleALC",
        "ATH9KFixup",
        "CPUFriend",
        "HibernationFixup",
        "RTCMemoryFixup",
        "VirtualSMC",
        "WhateverGreen",
        "IntelMausi",
        "AtherosE2200Ethernet",
        "RTL8111",
        "LucyRTL8125Ethernet",
        "NVMeFix",
        "VoodooPS2",
        "VoodooI2C",
        "RestrictEvents"
    ]
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        isRunning = resetStatus(isRunning: false)
        let imagebuild = NSImage(named: "NSTouchBarPlayTemplate")
        imagebuild?.isTemplate = true
        buildButton.image = imagebuild
        buildButton.isBordered = false
        buildButton.bezelStyle = .recessed
        buildButton.toolTip = "编译"
        
        let imagestop = NSImage(named: "NSTouchBarRecordStopTemplate")
        imagestop?.isTemplate = true
        stopButton.image = imagestop
        stopButton.isBordered = false
        stopButton.bezelStyle = .recessed
        stopButton.toolTip = "停止"
        
        proxyTextField.placeholderString = "http://127.0.0.1:xxxx"
        proxyTextField.delegate = self
        proxyTextField.refusesFirstResponder = true
        
        if let kextLocation = UserDefaults.standard.url(forKey: "kextLocation") {
            if FileManager.default.fileExists(atPath: kextLocation.path) {
                self.buildLocation.url = kextLocation
                kextPath = kextLocation.path
            }
        }
        
        if let logsURL = UserDefaults.standard.url(forKey: "logBuild") {
            if FileManager.default.fileExists(atPath: logsURL.path) {
                self.logsLocation.url = logsURL
                logsPath = logsURL.path
            }
        }
        
        self.pluginsView.reloadData()
    }
    
    override func willAppear(_ noti: Notification) {
        super.willAppear(noti)
        
        let index = noti.object as! Int
        if index != 1 { return }
        proxyTextField.stringValue = proxy ?? ""
        if !once { return }
        once = false
    }
    
    var buildTask: Process!
    var itemsArr: [String] = []
    var itemsSting: String = ""
    
    private func resetStatus(isRunning: Bool) -> Bool {
        if isRunning {
            stopButton.isEnabled = true
            progressBar.isHidden = false
            buildText.string = ""
            buildButton.isEnabled = false
            progressBar.startAnimation(self)
            buildLocation.isEnabled = false
            logsLocation.isEnabled = false
            proxyTextField.isEnabled = false
            selectAllButton.isEnabled = false
        } else {
            stopButton.isEnabled = false
            buildButton.isEnabled = true
            progressBar.stopAnimation(self)
            progressBar.doubleValue = 0.0
            progressBar.isHidden = true
            buildLocation.isEnabled = true
            logsLocation.isEnabled = true
            proxyTextField.isEnabled = true
            selectAllButton.isEnabled = true
        }
        return isRunning
    }
    
    @IBAction func setBuildPath(_ sender: Any) {
        if let buildURL = buildLocation.url {
            UserDefaults.standard.set(buildURL, forKey: "kextLocation")
            kextPath = buildURL.path
        }
    }
    
    @IBAction func setProxy(_ sender: Any) {
        UserDefaults.standard.set(proxyTextField.stringValue, forKey: "proxy")
    }
        
    @IBAction func setLog(_ sender: Any) {
        if let logsURL = logsLocation.url {
            UserDefaults.standard.set(logsURL, forKey: "logBuild")
            logsPath = logsURL.path
        }
    }
    
    @IBAction func startButtonDidClicked(_ sender: NSButton) {
        UserDefaults.standard.set(proxyTextField.stringValue, forKey: "proxy")
        if kextPath != "" {
            var arguments: [String] = []
            itemsSting = itemsArr.joined(separator: ",")
            if kextPath.contains(" ") || !FileManager.default.isWritableFile(atPath: kextPath) {
                alert.messageText = "所选目录不可写或存在空格"
                alert.runModal()
            } else {
                arguments.append(kextPath)
                arguments.append(itemsSting)
                arguments.append(proxyTextField.stringValue)
                arguments.append(logsPath)
                arguments.append(toolspath!)
                    
                if itemsSting != "" {
                    runBuildScripts(arguments)
                }
                else {
                    alert.messageText = "未选择任何条目"
                    alert.runModal()
                }
            }
            MyLog(arguments)
        } else {
            alert.messageText = "请先选择存储位置！"
            alert.runModal()
        }
    }
    
    @IBAction func stopButtonDidClicked(_ sender: NSButton) {
        if buildTask.suspend() {
            buildTask.terminate()
        }
    }
    
    @objc func checkClicked(_ sender: NSButton) {
        selectAllButton.state = .off
        switch sender.state {
        case .on:
            itemsArr.append(String(pluginsView.row(for: sender)))
        case .off:
            itemsArr = itemsArr.filter{$0 != String(pluginsView.row(for: sender))}
        case .mixed:
            MyLog("mixed")
        default: break
        }
        if itemsArr.count == pluginsList.count {
            selectAllButton.state = .on
        }
        MyLog(itemsArr)
    }
    
    @IBAction func seleceAllButtonDidClicked(_ sender: NSButton) {
        switch sender.state {
        case .on:
            itemsArr = []
            selectAll = 1
            pluginsView.reloadData()
            for i in 0..<pluginsList.count {
                itemsArr.append(String(i))
            }
        case .off:
            selectAll = 0
            pluginsView.reloadData()
            itemsArr = []
        case .mixed:
            MyLog("mixed")
        default:
            break
        }
        MyLog(itemsArr)
    }
    
    func runBuildScripts(_ arguments: [String]) {
        self.isRunning = self.resetStatus(isRunning: true)
        pluginsView.reloadData(forRowIndexes: IndexSet([Int](0..<pluginsList.count)), columnIndexes: [0])
        taskQueue.async {
            if let path = Bundle.main.path(forResource: "Hackintosh_build", ofType:"command") {
                self.buildTask = Process()
                self.buildTask.launchPath = path
                self.buildTask.arguments = arguments
                self.buildTask.environment = ["PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:"]
                self.buildTask.terminationHandler = { task in
                    DispatchQueue.main.async(execute: { [weak self] in
                        guard let `self` = self else { return }
                        self.isRunning = self.resetStatus(isRunning: false)
                        self.pluginsView.reloadData(forRowIndexes: IndexSet([Int](0..<self.pluginsList.count)), columnIndexes: [0])
                    })
                }
                self.buildOutPut(self.buildTask)
                self.buildTask.launch()
                self.buildTask.waitUntilExit()
            }
        }
    }
    
    func buildOutPut(_ task: Process) {
        let buildTextPipe = Pipe()
        task.standardOutput = buildTextPipe
        buildTextPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: buildTextPipe.fileHandleForReading , queue: nil) { notification in
            let output = buildTextPipe.fileHandleForReading.availableData
            if output.count > 0 {
                buildTextPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
                let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
                DispatchQueue.main.async(execute: {
                    let previousOutput = self.buildText.string
                    let nextOutput = previousOutput + "\n" + outputString
                    self.buildText.string = nextOutput
                    let range = NSRange(location:nextOutput.count, length:0)
                    self.buildText.scrollRangeToVisible(range)
                    self.progressBar.increment(by: 1.9)
                })
            }
        }
    }

}

extension BuildObject: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return pluginsList.count
    }
}

extension BuildObject: NSTextFieldDelegate {
    
    func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            proxy = textField.stringValue
            NotificationCenter.default.post(name: NSNotification.Name("proxyChanged"), object: nil)
        }
    }
    
}

extension BuildObject: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, shouldTrackCell cell: NSCell, for tableColumn: NSTableColumn?, row: Int) -> Bool {
        return true
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if tableColumn != nil {
            let identifier = tableColumn!.identifier.rawValue
            switch identifier {
            case "check":
                let button = NSButton()
                button.setButtonType(.switch)
                button.bezelStyle = .inline
                button.title = ""
                button.alignment = .right
                button.target = self
                button.action = #selector(checkClicked(_:))
                if isRunning {
                    if itemsArr.contains(String(row)) {
                        button.state = .on
                    }
                    button.isEnabled = false
                }
                else {
                    if itemsArr.contains(String(row)) {
                        button.state = .on
                    }
                    button.isEnabled = true
                }
                
                if selectAll == 1 {
                    button.state = .on
                }
                return button
            case "items":
                let textField = NSTextField()
                textField.cell = VerticallyCenteredTextFieldCell()
                textField.stringValue = self.pluginsList[row]
                textField.alignment = .left
                textField.isBordered = false
                return textField
            default:
                return nil
            }
        }
        return nil
    }
    
}

