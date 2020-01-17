//
//  ViewController.swift
//  HackintoshBuild
//
//  Created by wbx on 2020/1/5.
//  Copyright © 2020 wbx. All rights reserved.
//

import Cocoa

class ViewControllerBuild: NSViewController {
    
    @IBOutlet var buildText: NSTextView!
    @IBOutlet var stopButton: NSButton!
    
    @IBOutlet var progressBar: NSProgressIndicator!
    
    @IBOutlet var buildButton: NSButton!
    @IBOutlet weak var pluginsView: NSTableView!
    
    @IBOutlet var buildLocation: NSPathControl!
    
    @IBOutlet weak var proxyTextField: NSTextField!
    
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
        "NVMeFix"
    ]

    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        stopButton.isEnabled = false
        progressBar.isHidden = true
        
        proxyTextField.placeholderString = "http://127.0.0.1:xxxx"
        proxyTextField.stringValue = ""
        proxyTextField.resignFirstResponder()
        
        self.pluginsView.reloadData()
    }
    
    var isRunning = false
    var buildTextPipe: Pipe!
    var buildTask: Process!
    var itemsArr: [String] = []
    var itemsSting: String = ""
    
    @IBAction func startBuild(_ sender: Any) {
        
        if let buildURL = buildLocation.url {
            var arguments: [String] = []
            
            stopButton.isEnabled = true
            progressBar.isHidden = false
            buildText.string = ""
            buildButton.isEnabled = false
            progressBar.startAnimation(self)
            itemsSting = itemsArr.joined(separator: ",")
            arguments.append(buildURL.path)
            arguments.append(itemsSting)
            arguments.append(proxyTextField.stringValue)

            runBuildScripts(arguments)
            MyLog(arguments)
        } else {
            let alert = NSAlert()
            alert.messageText = "请先选择存储位置！"
            alert.runModal()
        }
            
    }
    
    @IBAction func stopBuild(_ sender: Any) {
        stopButton.isEnabled = false
        progressBar.isHidden = true
        if isRunning {
            self.progressBar.doubleValue = 0.0
            buildTask.terminate()
        }
    }
    
    @IBAction func CheckClicked(_ sender: NSButton) {
        
        switch sender.state {
        case .on:
            itemsArr.append(String(pluginsView.row(for: sender)))
        case .off:
            itemsArr = itemsArr.filter{$0 != String(pluginsView.row(for: sender))}
        case .mixed:
            MyLog("mixed")
        default: break
        }
        MyLog(itemsArr)
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func runBuildScripts(_ arguments: [String]) {
        isRunning = true
        let taskQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        taskQueue.async {
            if let path = Bundle.main.path(forResource: "Hackintosh_build", ofType:"command") {
                self.buildTask = Process()
                self.buildTask.launchPath = path
                self.buildTask.arguments = arguments
                self.buildTask.terminationHandler = { task in
                    DispatchQueue.main.async(execute: {
                        self.stopButton.isEnabled = false
                        self.buildButton.isEnabled = true
                        self.progressBar.isHidden = true
                        self.progressBar.stopAnimation(self)
                        self.progressBar.doubleValue = 0.0
                        self.isRunning = false
                    })
                }
                self.buildOutPut(self.buildTask)
                self.buildTask.launch()
                self.buildTask.waitUntilExit()
            }
        }
    }
    
    func buildOutPut(_ task:Process) {
        buildTextPipe = Pipe()
        task.standardOutput = buildTextPipe
        buildTextPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: buildTextPipe.fileHandleForReading , queue: nil) {
            notification in
            let output = self.buildTextPipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
            DispatchQueue.main.async(execute: {
                let previousOutput = self.buildText.string
                let nextOutput = previousOutput + "\n" + outputString
                self.buildText.string = nextOutput
                let range = NSRange(location:nextOutput.count,length:0)
                self.buildText.scrollRangeToVisible(range)
                self.progressBar.increment(by: 1.9)
            })
            self.buildTextPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        }
    }

}

extension ViewControllerBuild: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return pluginsList.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return pluginsList[row]
    }
    
}
