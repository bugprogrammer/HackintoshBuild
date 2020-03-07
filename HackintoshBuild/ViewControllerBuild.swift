//
//  ViewController.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2020/1/5.
//  Copyright © 2020 bugprogrammer. All rights reserved.
//

import Cocoa

class ViewControllerBuild: NSViewController {
    
    @IBOutlet var buildText: NSTextView!
    @IBOutlet var stopButton: NSButton!
    
    @IBOutlet var progressBar: NSProgressIndicator!
    
    @IBOutlet var buildButton: NSButton!
    @IBOutlet weak var pluginsView: NSTableView!
    
    @IBOutlet var buildLocation: NSPathControl!
    @IBOutlet weak var logsLocation: NSPathControl!
    
    @IBOutlet weak var proxyTextField: NSTextField!
    
    @IBOutlet weak var selectAllButton: NSButton!
    let taskQueue = DispatchQueue.global(qos: .background)
    let alert = NSAlert()
    var selectAll: Int = 0
    
    let toolspath = Bundle.main.path(forResource: "nasm", ofType: "")
    
    let pluginsList: [String] = [
        "Clover(时间较长)",
        "OpenCore",
        "n-d-k-OpenCore",
        "AppleSupportPkg",
        "Lilu",
        "AirportBrcmFixup",
        "AppleALC",
        "ATH9KFixup",
        "BT4LEContinuityFixup",
        "CPUFriend",
        "HibernationFixup",
        "NoTouchID",
        "RTCMemoryFixup",
        "SystemProfilerMemoryFixup",
        "VirtualSMC",
        "acidanthera_WhateverGreen",
        "bugprogrammer_WhateverGreen",
        "IntelMausiEthernet",
        "AtherosE2200Ethernet",
        "RTL8111",
        "NVMeFix",
        "MacProMemoryNotificationDisabler"
    ]
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        proxyTextField.stringValue = proxy ?? ""
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resetStatus(isRunning: false)
        
        proxyTextField.placeholderString = "http://127.0.0.1:xxxx"
        proxyTextField.delegate = self
        proxyTextField.refusesFirstResponder = true
        
        if let kextLocation = UserDefaults.standard.url(forKey: "kextLocation") {
            if FileManager.default.fileExists(atPath: kextLocation.path) {
                self.buildLocation.url = kextLocation
            }
        }
        self.pluginsView.reloadData()
    }
    
    var buildTask: Process!
    var itemsArr: [String] = []
    var itemsSting: String = ""
    
    private func resetStatus(isRunning: Bool) {
        if isRunning {
            stopButton.isEnabled = true
            progressBar.isHidden = false
            buildText.string = ""
            buildButton.isEnabled = false
            progressBar.startAnimation(self)
        } else {
            stopButton.isEnabled = false
            buildButton.isEnabled = true
            progressBar.stopAnimation(self)
            progressBar.doubleValue = 0.0
            progressBar.isHidden = true
        }
    }
    
    @IBAction func startBuild(_ sender: Any) {
        UserDefaults.standard.set(proxyTextField.stringValue, forKey: "proxy")
        if let buildURL = buildLocation.url {
            UserDefaults.standard.set(buildURL, forKey: "kextLocation")
                var arguments: [String] = []
                itemsSting = itemsArr.joined(separator: ",")
                arguments.append(buildURL.path)
                arguments.append(itemsSting)
                arguments.append(proxyTextField.stringValue)
                arguments.append(logsLocation.url?.path ?? "")
                arguments.append(toolspath!)
                
                if itemsSting != "" {
                    runBuildScripts(arguments)
                }
                else {
                    alert.messageText = "未选择任何条目"
                    alert.runModal()
                }
                MyLog(arguments)
        } else {
            alert.messageText = "请先选择存储位置！"
            alert.runModal()
        }
            
    }
    
    @IBAction func stopBuild(_ sender: Any) {
        if buildTask.suspend() {
            buildTask.terminate()
        }
    }
    
    @IBAction func CheckClicked(_ sender: NSButton) {
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
    
    @IBAction func SelectAll(_ sender: NSButton) {
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
    
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func runBuildScripts(_ arguments: [String]) {
        self.resetStatus(isRunning: true)
        taskQueue.async {
            if let path = Bundle.main.path(forResource: "Hackintosh_build", ofType:"command") {
                self.buildTask = Process()
                self.buildTask.launchPath = path
                self.buildTask.arguments = arguments
                self.buildTask.environment = ["PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:"]
                self.buildTask.terminationHandler = { task in
                    DispatchQueue.main.async(execute: { [weak self] in
                        guard let `self` = self else { return }
                        self.resetStatus(isRunning: false)
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

extension ViewControllerBuild: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return pluginsList.count
    }
}

extension ViewControllerBuild: NSTextFieldDelegate {
    
    func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            proxy = textField.stringValue
        }
    }
    
}

extension ViewControllerBuild: NSTableViewDelegate {
    
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
                button.action = #selector(CheckClicked(_:))
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

