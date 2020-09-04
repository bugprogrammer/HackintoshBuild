//
//  ViewControllerUpdate.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2020/2/29.
//  Copyright © 2020 bugprogrammer. All rights reserved.
//

import Cocoa
import Alamofire

class KextsObject: InBaseObject {

    @IBOutlet weak var refreshButton: NSButton!
    @IBOutlet weak var tableview: NSTableView!
    @IBOutlet weak var downloadPath: NSPathControl!
    @IBOutlet weak var downloadButton: NSButton!
    @IBOutlet weak var openButton: NSButton!
    @IBOutlet weak var selectAllButton: NSButton!
    @IBOutlet weak var proxyTextField: NSTextField!
    
    let taskQueue = DispatchQueue.global(qos: .default)
    var task: Process!

    var output: String = ""
    let lock = NSLock()
    var flag: Int = 0
    var pathDownload: String = ""
    var itemsArr: [String] = []
    var itemFlag: [Int] = []
    var isStart: Bool = false
    var selectAll: Bool = false
    var downloadProgress: Double = 0.0
    var isDownloading: Bool = false
    
    let queueDownload : OperationQueue = {
        let que : OperationQueue = OperationQueue()
        que.maxConcurrentOperationCount = 1
        return que
    }()
    
    let queueLatest : OperationQueue = {
        let que : OperationQueue = OperationQueue()
        que.maxConcurrentOperationCount = 1
        return que
    }()
    
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let open = MyAsset.open1.image
        open.isTemplate = true
        openButton.image = open
        openButton.bezelStyle = .recessed
        openButton.isBordered = false
        openButton.isEnabled = false
        openButton.toolTip = "打开下载目录"
        
        tableview.tableColumns.forEach { (column) in
            column.headerCell.alignment = .center
        }
        
        if let downloadURL = UserDefaults.standard.url(forKey: "downloadURL") {
            if FileManager.default.fileExists(atPath: downloadURL.path) {
                downloadPath.url = downloadURL
                pathDownload = downloadURL.path
                tableview.reloadData(forRowIndexes: IndexSet([Int](0..<kexts.count)), columnIndexes: [3])
                if FileManager.default.fileExists(atPath: downloadURL.path + "/Kexts") {
                    openButton.isEnabled = true
                }
            }
        }
        
        proxyTextField.placeholderString = "http://127.0.0.1:xxxx"
        proxyTextField.delegate = self
        proxyTextField.refusesFirstResponder = true
        
        let downloadAll = MyAsset.downloadAll.image
        downloadAll.isTemplate = true
        let shuaxin = MyAsset.refresh.image
        shuaxin.isTemplate = true
        refreshButton.image = MyAsset.refresh.image
        refreshButton.bezelStyle = .recessed
        refreshButton.isBordered = false
        refreshButton.toolTip = "刷新"
        downloadButton.image = downloadAll
        downloadButton.bezelStyle = .recessed
        downloadButton.isBordered = false
        downloadButton.toolTip = "下载"
    }
    
    override func willAppear(_ noti: Notification) {
        super.willAppear(noti)
        
        let index = noti.object as! Int
        if index != 3 { return }
        proxyTextField.stringValue = proxy ?? ""
        if !once { return }
        once = false
        
        runBuildScripts("kextscurrentVersion", ["Lilu"])
        refreshButton.isEnabled = false
        downloadButton.isEnabled = false
        selectAllButton.isEnabled = false
    }
    
    @objc func checkClicked(_ sender: NSButton) {
        selectAllButton.state = .off
        switch sender.state {
        case .on:
            itemsArr.append(getURL(tableview.row(for: sender)))
            itemFlag.append(tableview.row(for: sender))
        case .off:
            itemsArr = itemsArr.filter{$0 != getURL(tableview.row(for: sender))}
            itemFlag = itemFlag.filter{$0 != tableview.row(for: sender)}
        case .mixed:
            MyLog("mixed")
        default: break
        }
        if !itemsArr.isEmpty && !pathDownload.isEmpty {
            downloadButton.isEnabled = true
        }
        else {
            downloadButton.isEnabled = false
        }
        if itemsArr.count == kexts.count {
            selectAllButton.state = .on
        }
        MyLog(itemsArr)
        MyLog(itemFlag)
    }
    
    @IBAction func selectAllButtonDidClicked(_ sender: NSButton) {
        switch sender.state {
        case .on:
            itemsArr = []
            itemFlag = []
            selectAll = true
            tableview.reloadData(forRowIndexes: IndexSet([Int](0..<self.kexts.count)), columnIndexes: [0])
            for i in 0..<kexts.count {
                itemsArr.append(getURL(i))
                itemFlag.append(i)
            }
            MyLog(itemsArr)
        case .off:
            selectAll = false
            itemsArr = []
            itemFlag = []
            tableview.reloadData(forRowIndexes: IndexSet([Int](0..<self.kexts.count)), columnIndexes: [0])
        default:
            break
        }
        if !itemsArr.isEmpty && !pathDownload.isEmpty {
            downloadButton.isEnabled = true
        }
        else {
            downloadButton.isEnabled = false
        }
    }
    
    @IBAction func downloadPath(_ sender: NSPathControl) {
        if let downloadURL = downloadPath.url {
            UserDefaults.standard.set(downloadURL, forKey: "downloadURL")
            pathDownload = downloadURL.path
            tableview.reloadData(forRowIndexes: IndexSet([Int](0..<kexts.count)), columnIndexes: [3])
            if FileManager.default.fileExists(atPath: downloadURL.path + "/Kexts") {
                openButton.isEnabled = true
            }
            if !itemsArr.isEmpty {
                downloadButton.isEnabled = true
            }
            else {
                downloadButton.isEnabled = false
            }
        }
    }
    
    @IBAction func resfreshButtonDidClicked(_ sender: Any) {
        selectAllButton.state = .off
        selectAll = false
        isStart = false
        flag = 0
        refreshButton.isEnabled = false
        downloadButton.isEnabled = false
        selectAllButton.isEnabled = false
        currentVersion = []
        Lastest = []
        itemFlag = []
        itemsArr = []
        
        tableview.reloadData()
        runBuildScripts("kextscurrentVersion", ["Lilu"])
    }
        
    @IBAction func setProxy(_ sender: Any) {
        UserDefaults.standard.set(proxyTextField.stringValue, forKey: "proxy")
    }
    
    @IBAction func downloadButtonDidClicked(_ sender: NSButton) {
        //Lilu-1.4.2-RELEASE.zip
        UserDefaults.standard.set(proxyTextField.stringValue, forKey: "proxy")
        downloadButton.isEnabled = false
        refreshButton.isEnabled = false
        selectAllButton.isEnabled = false
        proxyTextField.isEnabled = false
        downloadPath.isEnabled = false
        isDownloading = false
        isStart = true
        if FileManager.default.isWritableFile(atPath: pathDownload) {
            downloadKexts(itemsArr)
        }
        else {
            let alert = NSAlert()
            alert.messageText = "所选目录不可写"
            alert.runModal()
            downloadButton.isEnabled = true
            proxyTextField.isEnabled = true
            downloadPath.isEnabled = true
        }
    }
    
    func downloadKexts(_ list: [String]){
        downloadProgress = 0.0
        self.tableview.reloadData(forRowIndexes: IndexSet([Int](0..<kexts.count)), columnIndexes: [0,4])
        let filemanager = FileManager.default
        if !filemanager.fileExists(atPath: self.pathDownload + "/Kexts") {
            try! filemanager.createDirectory(atPath: self.pathDownload + "/Kexts", withIntermediateDirectories: true,
            attributes: nil)
        }
        var first: Bool = true
        
        for i in 0..<list.count {
            if filemanager.fileExists(atPath: self.pathDownload + "/Kexts/" + list[i].components(separatedBy: "/").last!) {
                try! filemanager.removeItem(atPath: self.pathDownload + "/Kexts/" + list[i].components(separatedBy: "/").last!)
            }
            let semaphore = DispatchSemaphore(value: 0)
            let op : BlockOperation = BlockOperation { [weak self] in
                let destination: DownloadRequest.Destination = { _, _ in
                    let fileURL = URL(fileURLWithPath: self!.pathDownload + "/Kexts/" + list[i].components(separatedBy: "/").last!)
                    
                    return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
                }

                AF.download(list[i], to: destination).downloadProgress { progress in
                    self!.isDownloading = true
                    self?.downloadProgress = progress.fractionCompleted
                    self!.tableview.reloadData(forRowIndexes: [self!.itemFlag[i]], columnIndexes: [0,4])
                }.responseData { response in
                    debugPrint(response)
                    switch response.result {
                    case .success(_):
                        self!.openButton.isEnabled = true
                        self?.downloadProgress = 1
                        self!.tableview.reloadData(forRowIndexes: [self!.itemFlag[i]], columnIndexes: [0,4])
                        if i == list.count - 1 {
                            self!.downloadButton.isEnabled = true
                            self!.refreshButton.isEnabled = true
                            self!.selectAllButton.isEnabled = true
                            self!.proxyTextField.isEnabled = true
                            self!.downloadPath.isEnabled = true
                            
                            if self!.Lastest.count == self!.kexts.count {
                                self!.refreshButton.isEnabled = true
                                self!.selectAllButton.isEnabled = true
                            }
                            self!.isStart = false
                            self!.tableview.reloadData(forRowIndexes: IndexSet([Int](0..<self!.kexts.count)), columnIndexes: [0,4])
                        }
                    case .failure(_):
                        if first {
                            let alert = NSAlert()
                            alert.messageText = "下载失败，请重试"
                            alert.runModal()
                            first = false
                            self!.downloadProgress = 0.0
                            self!.isStart = false
                            self!.tableview.reloadData(forRowIndexes: IndexSet([Int](0..<self!.kexts.count)), columnIndexes: [0,4])
                            self!.downloadButton.isEnabled = true
                            self!.refreshButton.isEnabled = true
                            self!.selectAllButton.isEnabled = true
                            self!.proxyTextField.isEnabled = true
                            self!.downloadPath.isEnabled = true
                            if self!.Lastest.count == self!.kexts.count {
                                self!.refreshButton.isEnabled = true
                                self!.selectAllButton.isEnabled = true
                            }
                        }
                    }
                    semaphore.signal()
                }
                semaphore.wait()
            }
            
            queueDownload.addOperation(op)
        }
    }
    
    func getLatest(_ list: [String]) {
        for i in 0..<list.count {
            let semaphore = DispatchSemaphore(value: 0)
            let op : BlockOperation = BlockOperation { [weak self] in
                let headers: HTTPHeaders = [
                    "Accept": "application/json"
                ]

                AF.request(list[i] + "/releases/latest", method: .get, headers: headers).validate().responseJSON { response in
                    switch response.result {
                        case .success(let dict):
                            self!.Lastest.append(((dict as! NSDictionary)["tag_name"] as! String).replacingOccurrences(of: "v", with: "").replacingOccurrences(of: "V", with: ""))
                            self!.tableview.reloadData(forRowIndexes: [i], columnIndexes: [0,3])
                            if i == self!.url.count - 1 {
                                self!.refreshButton.isEnabled = true
                                self!.selectAllButton.isEnabled = true
                            }
                        case .failure(_):
                            self!.Lastest.append("网络错误")
                            self!.tableview.reloadData(forRowIndexes: [i], columnIndexes: [0,3])
                            if i == self!.url.count - 1 {
                                self!.refreshButton.isEnabled = true
                                self!.selectAllButton.isEnabled = true
                            }
                        }
                    semaphore.signal()
                }
                semaphore.wait()
            }
            queueLatest.addOperation(op)
        }
    }
    
    func getURL(_ row: Int) -> String {
        var downloadURL: String = ""
        
        if "BT4LEContinuityFixup".contains(kexts[row]) {
            downloadURL = url[row] + "/releases/download/v" + Lastest[row] + "/" + kexts[row] + "-" + Lastest[row] + "-RELEASE.zip"
        }
        else if kexts[row] == "RealtekRTL8111" {
            downloadURL = url[row] + "/releases/download/v" + Lastest[row] + "/" + kexts[row] + "-V" + Lastest[row] + ".zip"
        }
        else if kexts[row] == "AtherosE2200Ethernet" {
            downloadURL = url[row] + "/releases/download/" + Lastest[row] + "/" + kexts[row] + "-V" + Lastest[row] + ".zip"
        }
        else if kexts[row] == "MacProMemoryNotificationDisabler" {
            downloadURL = url[row] + "/releases/download/v" + Lastest[row] + "/" + "MPMND" + "-v" + Lastest[row] + "-Release.zip"
        }
        else if "acidanthera_WhateverGreen bugprogrammer_WhateverGreen".contains(kexts[row]) {
            downloadURL = url[row] + "/releases/download/" + Lastest[row] + "/" + "WhateverGreen" + "-" + Lastest[row] + "-RELEASE.zip"
        }
        else {
            downloadURL = url[row] + "/releases/download/" + Lastest[row] + "/" + kexts[row] + "-" + Lastest[row] + "-RELEASE.zip"
        }
        //tableview.reloadData(forRowIndexes: IndexSet([Int](0..<kexts.count)), columnIndexes: [3])
        return downloadURL
    }
    
    @IBAction func openButtonDidClicked(_ sender: NSButton) {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: pathDownload + "/Kexts")
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
                            self.output = self.output.replacingOccurrences(of: "Executing: /usr/bin/kmutil showloaded", with: "")
                            self.flag = self.flag + 1
                            if self.output == "" {
                                self.currentVersion.append("未安装")
                            }
                            else {
                                self.currentVersion.append(self.output.components(separatedBy: "\n").first!)
                            }
                            self.tableview.reloadData(forRowIndexes: [self.flag-1], columnIndexes: [2])
                            if self.flag < self.kexts.count {
                                self.runBuildScripts("kextscurrentVersion", [self.kexts[self.flag]])
                            }
                            if self.flag == self.kexts.count {
                                self.getLatest(self.url)
                            }
                        }
                        self.lock.unlock()
                    })
                }
                self.taskOutPut(task,shell)
                task.launch()
                task.waitUntilExit()
            }
        }
    }
    
    func taskOutPut(_ task:Process, _ shell: String) {
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

extension KextsObject: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return kexts.count
    }
}

extension KextsObject: NSTextFieldDelegate {
    
    func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            proxy = textField.stringValue
        }
    }
    
}

extension KextsObject: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, shouldTrackCell cell: NSCell, for tableColumn: NSTableColumn?, row: Int) -> Bool {
        return true
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 19
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
                
                if Lastest.count >= row + 1 && !isStart {
                    if itemFlag.contains(row) {
                        MyLog(itemFlag)
                        button.state = .on
                    }
                    button.isEnabled = true
                }
                else {
                    if itemFlag.contains(row) {
                        button.state = .on
                    }
                    button.isEnabled = false
                }

                if selectAll {
                    button.state = .on
                }
            return button
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
            case "status":
                var view = NSView()
                
                if isDownloading {
                    if downloadProgress < 1 {
                        let progress = NSProgressIndicator()
                        progress.style = .spinning
                        progress.controlSize = NSControl.ControlSize(rawValue: 5)!
                        progress.sizeToFit()
                        progress.isHidden = false

                        progress.isIndeterminate = false
                        progress.minValue = 0
                        progress.maxValue = 1
                        progress.doubleValue = downloadProgress
                        
                        view = progress
                    } else {
                        if itemFlag.contains(row) {
                            let button = NSButton()
                            button.image = MyAsset.complate.image
                            button.bezelStyle = .recessed
                            button.isBordered = false
                            view = button
                        }
                    }
                    
                    return view
                }
            default:
                return nil
            }
        }
        return nil
    }
}
