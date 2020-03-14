//
//  ViewControllerUpdate.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2020/2/29.
//  Copyright © 2020 bugprogrammer. All rights reserved.
//

import Cocoa

class ViewControllerUpdate: NSViewController {

    @IBOutlet weak var refreshButton: NSButton!
    @IBOutlet weak var tableview: NSTableView!
    @IBOutlet weak var downloadPath: NSPathControl!
    @IBOutlet weak var downloadAllButton: NSButton!
    @IBOutlet weak var openButton: NSButton!
    
    let taskQueue = DispatchQueue.global(qos: .background)
    let downloadGroup = DispatchGroup()
    var output: String = ""
    let lock = NSLock()
    var flag: Int = 0
    var isRunning: [Bool] = []
    var isDownloadAll: Bool = false
    var isRefresh: Bool = false
    var pathDownload: String = ""
    
    let kexts: [String] = [
        "Lilu",
        "AirportBrcmFixup",
        "AppleALC",
        "BT4LEContinuityFixup",
        "CPUFriend",
        "HibernationFixup",
        "NoTouchID",
        "RTCMemoryFixup",
        "VirtualSMC",
        "acidanthera_WhateverGreen",
        "bugprogrammer_WhateverGreen",
        "IntelMausi",
        "AtherosE2200Ethernet",
        "RealtekRTL8111",
        "NVMeFix",
        "MacProMemoryNotificationDisabler"
    ]
    
    let url: [String] = [
        "https://github.com/acidanthera/Lilu",
        "https://github.com/acidanthera/AirportBrcmFixup",
        "https://github.com/acidanthera/AppleALC",
        "https://github.com/acidanthera/BT4LEContinuityFixup",
        "https://github.com/acidanthera/CPUFriend",
        "https://github.com/acidanthera/HibernationFixup",
        "https://github.com/al3xtjames/NoTouchID",
        "https://github.com/acidanthera/RTCMemoryFixup",
        "https://github.com/acidanthera/VirtualSMC",
        "https://github.com/acidanthera/WhateverGreen",
        "https://github.com/bugprogrammer/WhateverGreen",
        "https://github.com/acidanthera/IntelMausi",
        "https://github.com/Mieze/AtherosE2200Ethernet",
        "https://github.com/Mieze/RTL8111_driver_for_OS_X",
        "https://github.com/acidanthera/NVMeFix",
        "https://github.com/IOIIIO/MacProMemoryNotificationDisabler"
    ]
    
    var currentVersion: [String] = []
    var Lastest: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshButton.image = NSImage(named: "refresh.png")
        refreshButton.bezelStyle = .recessed
        refreshButton.isBordered = false
        refreshButton.isEnabled = false
        refreshButton.toolTip = "刷新"
        downloadAllButton.image = NSImage(named: "downloadAll.png")
        downloadAllButton.isBordered = false
        downloadAllButton.bezelStyle = .recessed
        downloadAllButton.isEnabled = false
        downloadAllButton.toolTip = "下载全部"
        openButton.image = NSImage(named: "open-1x.png")
        openButton.bezelStyle = .recessed
        openButton.isBordered = false
        openButton.isEnabled = false
        openButton.toolTip = "打开下载目录"
        
        tableview.tableColumns.forEach { (column) in
            column.headerCell.alignment = .center
        }
        isRunning = Array(repeating: false, count: kexts.count)
        MyLog(isRunning)
        
        if let downloadURL = UserDefaults.standard.url(forKey: "downloadURL") {
            if FileManager.default.fileExists(atPath: downloadURL.path) {
                downloadPath.url = downloadURL
                pathDownload = downloadURL.path
                tableview.reloadData(forRowIndexes: IndexSet([Int](0..<kexts.count)), columnIndexes: [3])
                openButton.isEnabled = true
            }
        }
        
        runBuildScripts("kextscurrentVersion", ["Lilu"])
    }
        
    @IBAction func downloadPath(_ sender: NSPathControl) {
        if let downloadURL = downloadPath.url {
            UserDefaults.standard.set(downloadURL, forKey: "downloadURL")
            pathDownload = downloadURL.path
            tableview.reloadData(forRowIndexes: IndexSet([Int](0..<kexts.count)), columnIndexes: [3])
            openButton.isEnabled = true
            if Lastest.count == kexts.count {
                downloadAllButton.isEnabled = true
            }
        }
    }
    
    @IBAction func Resfresh(_ sender: Any) {
        flag = 0
        refreshButton.isEnabled = false
        downloadAllButton.isEnabled = false
        currentVersion = []
        Lastest = []
        
        tableview.reloadData()
        runBuildScripts("kextscurrentVersion", ["Lilu"])
    }
    
    @objc func downloads(_ sender: NSButton) {
        //Lilu-1.4.2-RELEASE.zip
        let row = tableview.row(for: sender)
        isDownloadAll = false
        if Lastest[row] == "网络错误" {
            downloadAllButton.isEnabled = false
            isRunning[row] = true
            isRefresh = true
            flag = url.count - 1
            runBuildScripts("kextLastest", [url[row]])
            tableview.reloadData(forRowIndexes: IndexSet([Int](0..<kexts.count)), columnIndexes: [3])
        }
        else {
            downloadUpdate(row, pathDownload)
        }
    }
    
    @IBAction func downloadsAll(_ sender: NSButton) {
        isDownloadAll = true
        
        downloadUpdate(0, pathDownload)
    }
    
    func downloadUpdate(_ row: Int, _ path: String) {
        refreshButton.isEnabled = false
        downloadAllButton.isEnabled = false
        isRunning[row] = true
        if "BT4LEContinuityFixup RTCMemoryFixup".contains(kexts[row]) {
            runBuildScripts("download", [path, url[row], "v" + Lastest[row], kexts[row] + "-" + Lastest[row] + "-RELEASE.zip"])
        }
        else if kexts[row] == "RealtekRTL8111" {
            runBuildScripts("download", [path, url[row], "v" + Lastest[row], kexts[row] + "-V" + Lastest[row] + ".zip"])
        }
        else if kexts[row] == "AtherosE2200Ethernet" {
            runBuildScripts("download", [path, url[row], Lastest[row], kexts[row] + "-V" + Lastest[row] + ".zip"])
        }
        else if kexts[row] == "MacProMemoryNotificationDisabler" {
            runBuildScripts("download", [path, url[row], "v" + Lastest[row], "MPMND" + "-v" + Lastest[row] + "-Release.zip"])
        }
        else if "acidanthera_WhateverGreen bugprogrammer_WhateverGreen".contains(kexts[row]) {
            runBuildScripts("download", [path, url[row], Lastest[row], "WhateverGreen" + "-" + Lastest[row] + "-RELEASE.zip"])
        }
        else {
            runBuildScripts("download", [path, url[row], Lastest[row], kexts[row] + "-" + Lastest[row] + "-RELEASE.zip"])
        }
        tableview.reloadData(forRowIndexes: IndexSet([Int](0..<kexts.count)), columnIndexes: [3])
    }
    
    @IBAction func open(_ sender: Any) {
        runBuildScripts("openFinder", [pathDownload])
    }
    
    func runBuildScripts(_ shell: String,_ arguments: [String]) {
        self.output = ""
        taskQueue.async {
            if let path = Bundle.main.path(forResource: shell, ofType:"command") {
                let task = Process()
                task.launchPath = path
                task.arguments = arguments
                task.environment = ["PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:"]
                task.terminationHandler = { task in
                    DispatchQueue.main.async(execute: { [weak self] in
                        guard let `self` = self else { return }
                        self.lock.lock()
                        if shell == "kextscurrentVersion" {
                            self.flag = self.flag + 1
                            if self.output == "" {
                                self.currentVersion.append("未安装")
                            }
                            else {
                                self.currentVersion.append(self.output.components(separatedBy: "\n").first!)
                            }
                            self.tableview.reloadData(forRowIndexes: [self.flag-1], columnIndexes: [1])
                            if self.flag < self.kexts.count {
                                self.runBuildScripts("kextscurrentVersion", [self.kexts[self.flag]])
                            }
                            if self.flag == self.kexts.count {
                                self.flag = 0
                                self.runBuildScripts("kextLastest", [self.url[self.flag]])
                            }
                        }
                        else if shell == "kextLastest" {
                            if !self.isRefresh {
                                self.flag = self.flag + 1
                                if self.output == "" {
                                    self.Lastest.append("网络错误")
                                }
                                else {
                                    self.Lastest.append(self.output.components(separatedBy: "\n").first!)
                                }
                                MyLog(self.Lastest)
                                self.tableview.reloadData(forRowIndexes: [self.flag-1], columnIndexes: [2,3])
                                if self.flag < self.url.count {
                                    self.runBuildScripts("kextLastest", [self.url[self.flag]])
                                }
                                if self.flag == self.url.count {
                                    self.refreshButton.isEnabled = true
                                    if self.pathDownload != "" && !self.Lastest.contains("网络错误") {
                                        self.downloadAllButton.isEnabled = true
                                    }
                                    self.flag = 0
                                }
                                self.tableview.reloadData(forRowIndexes: IndexSet([Int](0..<self.kexts.count)), columnIndexes: [3])
                            }
                            else {
                                if self.output == "" {
                                    self.Lastest[self.url.firstIndex(of: arguments[0])!] = "网络错误"
                                }
                                else {
                                    self.Lastest[self.url.firstIndex(of: arguments[0])!] = self.output.components(separatedBy: "\n").first!
                                }
                                self.isRefresh = false
                                if self.pathDownload != "" && !self.Lastest.contains("网络错误") {
                                    self.downloadAllButton.isEnabled = true
                                }
                                self.isRunning[self.url.firstIndex(of: arguments[0])!] = false
                                self.tableview.reloadData(forRowIndexes: IndexSet([Int](0..<self.kexts.count)), columnIndexes: [2,3])
                            }
                        }
                        else if shell == "download" {
                            self.isRunning[self.url.firstIndex(of: arguments[1])!] = false
                            MyLog(self.url.firstIndex(of: arguments[1])!)
                                                        
                            if self.isDownloadAll {
                                self.flag = self.flag + 1
                                if self.flag < self.kexts.count {
                                    self.downloadUpdate(self.flag, self.pathDownload)
                                }
                            }
                            
                            if self.flag == self.kexts.count {
                                self.isDownloadAll = false
                            }
                            
                            if self.isDownloadAll == false && self.Lastest.count == self.kexts.count {
                                self.downloadAllButton.isEnabled = true
                                self.refreshButton.isEnabled = true
                            }
                            self.tableview.reloadData(forRowIndexes: IndexSet([Int](0..<self.kexts.count)), columnIndexes: [3])
                        }
                        self.lock.unlock()
                    })
                }
                if shell != "download" {
                     self.taskOutPut(task)
                }
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
                    let nextOutput = previousOutput + outputString
                    self.output = nextOutput
                })
            }
        }
    }
    
}

extension ViewControllerUpdate: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return kexts.count
    }
}

extension ViewControllerUpdate: NSTableViewDelegate {
    
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
                textField.stringValue = self.kexts[row]
                textField.alignment = .left
                textField.isBordered = false
            return textField
            case "currentversion":
                let textField = NSTextField()
                textField.cell = VerticallyCenteredTextFieldCell()
                textField.stringValue = ""
                if currentVersion.count >= row + 1 {
                    MyLog(self.currentVersion)
                    textField.stringValue = self.currentVersion[row]
                }
                textField.alignment = .center
                textField.isBordered = false
            return textField
            case "lastest":
                let textField = NSTextField()
                textField.cell = VerticallyCenteredTextFieldCell()
                textField.stringValue = ""
                if Lastest.count >= row + 1 {
                    textField.stringValue = self.Lastest[row]
                }
                textField.alignment = .center
                textField.isBordered = false
            return textField
            case "download":
                var view = NSView()
                if isRunning != [] && isRunning[row] == false {
                        let button = NSButton()
                        button.action = #selector(downloads(_:))
                        button.bezelStyle = .recessed
                        button.isBordered = false
                        button.image = NSImage(named: "download.png")
                        if pathDownload != "" && Lastest.count >= row + 1 && Lastest[row] != "" && Lastest[row] != "网络错误" && isDownloadAll == false && !isRunning.contains(true) {
                            button.isEnabled = true
                        }
                        else if Lastest.count >= row + 1 && Lastest[row] == "网络错误" {
                            button.image = NSImage(named: "refresh-2x.png")
                            if Lastest.count == kexts.count && !isRunning.contains(true) {
                                button.isEnabled = true
                            }
                            else {
                                button.isEnabled = false
                            }
                        }
                        else {
                            button.isEnabled = false
                        }
                        button.alignment = .center
                        view = button as NSView
                }
                else {
                    let progress = NSProgressIndicator()
                    progress.style = .spinning
                    progress.startAnimation(self)
                    view = progress as NSView
                }
            return view
            default:
                return nil
            }
        }
        return nil
    }
}
