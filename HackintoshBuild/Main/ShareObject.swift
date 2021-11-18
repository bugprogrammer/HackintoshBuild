//
//  ViewControllerEFI.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2020/1/17.
//  Copyright © 2020 bugprogrammer. All rights reserved.
//

import Cocoa

class ShareObject: OutBaseObject {
    
    @IBOutlet weak var efiLocation: NSPathControl!
    @IBOutlet weak var logsLocation: NSPathControl!
    @IBOutlet weak var efiTableView: NSTableView!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet var efiOutPut: NSTextView!
    @IBOutlet weak var efiStartButton: NSButton!
    @IBOutlet weak var efiStopButton: NSButton!
    @IBOutlet weak var proxyTextField: NSTextField!
    @IBOutlet weak var selectAllButton: NSButton!
    
    let taskQueue = DispatchQueue.global(qos: .default)
    let alert = NSAlert()
    var selectAll: Int = 0
    var isRunning: Bool = false
    var sharePath: String = ""
    var logsPath: String = ""
    
    let efiList: [String] = [
        "Z490-AORUS-ELETE+10900K+RX5700XT",
        "ASRock-Z390-itx+9900K+Vega56",
        "ASRock-Z390-itx+9900K+rx5700XT",
        "H110+8100+hd7850",
        "Lenovo-yoga-720-13ikb-7200u",
        "P751dm2",
        "ThinkPad-S1-2017",
        "ThinkPad-S1-2018",
        "Z370A+8700K+Vega+sm961",
        "Z370n+8700K+Vega+sm961",
        "asus-n550jv-bcm94352hmb",
        "dell-7000"
    ]
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        isRunning = resetStatus(isRunning: false)
        let imagebuild = NSImage(named: "NSTouchBarPlayTemplate")
        imagebuild?.isTemplate = true
        efiStartButton.image = imagebuild
        efiStartButton.isBordered = false
        efiStartButton.bezelStyle = .recessed
        efiStartButton.toolTip = "获取EFI"
        
        let imagestop = NSImage(named: "NSTouchBarRecordStopTemplate")
        imagestop?.isTemplate = true
        efiStopButton.image = imagestop
        efiStopButton.isBordered = false
        efiStopButton.bezelStyle = .recessed
        efiStopButton.toolTip = "停止"
        
        proxyTextField.placeholderString = "http://127.0.0.1:xxxx"
        proxyTextField.delegate = self
        proxyTextField.refusesFirstResponder = true
        
        if let efiLocation = UserDefaults.standard.url(forKey: "efiLocation") {
            if FileManager.default.fileExists(atPath: efiLocation.path) {
                self.efiLocation.url = efiLocation
                sharePath = efiLocation.path
            }
        }
        
        if let logsURL = UserDefaults.standard.url(forKey: "logShair") {
            if FileManager.default.fileExists(atPath: logsURL.path) {
                self.logsLocation.url = logsURL
                logsPath = logsURL.path
            }
        }
        self.efiTableView.reloadData()
    }
    
    override func willAppear(_ noti: Notification) {
        super.willAppear(noti)
        
        let index = noti.object as! Int
        if index != 2 { return }
        proxyTextField.stringValue = proxy ?? ""
        if !once { return }
        once = false
    }
    
    var efiTask: Process!
    var itemsArr: [String] = []
    var itemFlag: [String] = []
    var itemsSting: String = ""
        
    private func resetStatus(isRunning: Bool) -> Bool {
        if isRunning {
            efiStopButton.isEnabled = true
            progressBar.isHidden = false
            efiOutPut.string = ""
            efiStartButton.isEnabled = false
            progressBar.startAnimation(self)
            efiLocation.isEnabled = false
            logsLocation.isEnabled = false
            proxyTextField.isEnabled = false
            selectAllButton.isEnabled = false
        } else {
            efiStopButton.isEnabled = false
            efiStartButton.isEnabled = true
            progressBar.stopAnimation(self)
            progressBar.doubleValue = 0.0
            progressBar.isHidden = true
            efiLocation.isEnabled = true
            logsLocation.isEnabled = true
            proxyTextField.isEnabled = true
            selectAllButton.isEnabled = true
        }
        return isRunning
    }
        
    @IBAction func setSharePath(_ sender: Any) {
        if let efiURL = efiLocation.url {
            UserDefaults.standard.set(efiURL, forKey: "efiLocation")
            sharePath = efiURL.path
        }
    }
        
    @IBAction func setLogsPath(_ sender: Any) {
        if let logsURL = logsLocation.url {
            UserDefaults.standard.set(logsURL, forKey: "logShair")
            logsPath = logsURL.path
        }
    }
        
    @IBAction func setProxy(_ sender: Any) {
        UserDefaults.standard.set(proxyTextField.stringValue, forKey: "proxy")
    }
    
    @IBAction func startButtonDidClicked(_ sender: NSButton) {
        UserDefaults.standard.set(proxyTextField.stringValue, forKey: "proxy")
        if sharePath != "" {
            var arguments: [String] = []
            itemsSting = itemsArr.joined(separator: ",")
            if FileManager.default.isWritableFile(atPath: sharePath) {
                arguments.append(sharePath)
                arguments.append(itemsSting)
                arguments.append(proxyTextField.stringValue)
                arguments.append(logsPath)
                if itemsSting != "" {
                    runBuildScripts(arguments)
                }
                else {
                    alert.messageText = "未选择任何条目"
                    alert.runModal()
                }
            }
            else {
                alert.messageText = "所选目录不可写"
                alert.runModal()
            }
            
            MyLog(arguments)
        } else {
            alert.messageText = "请先选择存储位置！"
            alert.runModal()
        }
    }
        
    @IBAction func stopButtonDidClicked(_ sender: NSButton) {
        if efiTask.suspend() {
            efiTask.terminate()
        }
    }
    
    @objc func selected(_ sender: NSButton) {
        selectAllButton.state = .off
        switch sender.state {
        case .on:
            itemsArr.append(efiList[efiTableView.row(for: sender)])
            itemFlag.append(String(efiTableView.row(for: sender)))
        case .off:
            itemsArr = itemsArr.filter{$0 != efiList[efiTableView.row(for: sender)]}
            itemFlag = itemFlag.filter{$0 != String(efiTableView.row(for: sender))}
        case .mixed:
            MyLog("mixed")
        default:break
        }
        if itemsArr.count == efiList.count {
            selectAllButton.state = .on
        }
        MyLog(itemsArr)
    }
    
    @IBAction func selectAllButtonDidClicked(_ sender: NSButton) {
        switch sender.state {
        case .on:
            itemsArr = []
            itemFlag = []
            selectAll = 1
            efiTableView.reloadData()
            for i in 0..<efiList.count {
                itemsArr.append(efiList[i])
            }
        case .off:
            itemsArr = []
            itemFlag = []
            selectAll = 0
            efiTableView.reloadData()
        case .mixed:
            MyLog("mixed")
        default:
            break
        }
        MyLog(itemsArr)
    }
    
    func runBuildScripts(_ arguments: [String]) {
        self.isRunning = self.resetStatus(isRunning: true)
        efiTableView.reloadData(forRowIndexes: IndexSet([Int](0..<efiList.count)), columnIndexes: [0])
        taskQueue.async {
            if let path = Bundle.main.path(forResource: "getEFI", ofType:"command") {
                self.efiTask = Process()
                self.efiTask.launchPath = path
                self.efiTask.arguments = arguments
                self.efiTask.environment = ["PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:"]
                self.efiTask.terminationHandler = { task in
                    DispatchQueue.main.async(execute: { [weak self] in
                        guard let `self` = self else { return }
                        self.isRunning = self.resetStatus(isRunning: false)
                        self.efiTableView.reloadData(forRowIndexes: IndexSet([Int](0..<self.efiList.count)), columnIndexes: [0])
                    })
                }
                self.efiOutPut(self.efiTask)
                self.efiTask.launch()
                self.efiTask.waitUntilExit()
            }
        }
    }
    
    func efiOutPut(_ task: Process) {
        let efiTextPipe = Pipe()
        task.standardOutput = efiTextPipe
        efiTextPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: efiTextPipe.fileHandleForReading , queue: nil) { notification in
            let output = efiTextPipe.fileHandleForReading.availableData
            if output.count > 0 {
                efiTextPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
                let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
                DispatchQueue.main.async(execute: {
                    let previousOutput = self.efiOutPut.string
                    let nextOutput = previousOutput + "\n" + outputString
                    self.efiOutPut.string = nextOutput
                    let range = NSRange(location:nextOutput.count, length:0)
                    self.efiOutPut.scrollRangeToVisible(range)
                    self.progressBar.increment(by: 1.9)
                })
            }
        }
    }
}

extension ShareObject: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return efiList.count
    }
}

extension ShareObject: NSTableViewDelegate {
    
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
                button.action = #selector(selected(_:))
                if isRunning {
                    if itemFlag.contains(String(row)) {
                        button.state = .on
                    }
                    button.isEnabled = false
                }
                else {
                    if itemFlag.contains(String(row)) {
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
                textField.stringValue = self.efiList[row]
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

extension ShareObject: NSTextFieldDelegate {
    
    func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            proxy = textField.stringValue
            NotificationCenter.default.post(name: NSNotification.Name.ProxyChanged, object: nil)
        }
    }
    
}

