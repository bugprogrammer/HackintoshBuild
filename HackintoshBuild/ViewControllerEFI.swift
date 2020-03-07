//
//  ViewControllerEFI.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2020/1/17.
//  Copyright © 2020 bugprogrammer. All rights reserved.
//

import Cocoa

class ViewControllerEFI: NSViewController {

    @IBOutlet var efiLocation: NSPathControl!
    @IBOutlet weak var logsLocation: NSPathControl!
    @IBOutlet weak var efiTableView: NSTableView!
    @IBOutlet var progressBar: NSProgressIndicator!
    @IBOutlet var efiOutPut: NSTextView!
    @IBOutlet var efiStartButton: NSButton!
    @IBOutlet var efiStopButton: NSButton!
    @IBOutlet weak var proxyTextField: NSTextField!
    @IBOutlet weak var selectAllButton: NSButton!
    
    let taskQueue = DispatchQueue.global(qos: .background)
    let alert = NSAlert()
    var selectAll: Int = 0
    
    let efiList: [String] = [
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
        
        if let efiLocation = UserDefaults.standard.url(forKey: "efiLocation") {
            if FileManager.default.fileExists(atPath: efiLocation.path) {
                self.efiLocation.url = efiLocation
            }
        }
        
        self.efiTableView.reloadData()
    }
    
    var efiTask: Process!
    var itemsArr: [String] = []
    var itemsSting: String = ""
        
    private func resetStatus(isRunning: Bool) {
        if isRunning {
            efiStopButton.isEnabled = true
            progressBar.isHidden = false
            efiOutPut.string = ""
            efiStartButton.isEnabled = false
            progressBar.startAnimation(self)
        } else {
            efiStopButton.isEnabled = false
            efiStartButton.isEnabled = true
            progressBar.stopAnimation(self)
            progressBar.doubleValue = 0.0
            progressBar.isHidden = true
        }
    }
    
    @IBAction func efiStart(_ sender: Any) {
        UserDefaults.standard.set(proxyTextField.stringValue, forKey: "proxy")
        if let efiURL = efiLocation.url {
            UserDefaults.standard.set(efiURL, forKey: "efiLocation")
            var arguments: [String] = []
            itemsSting = itemsArr.joined(separator: ",")
            arguments.append(efiURL.path)
            arguments.append(itemsSting)
            arguments.append(proxyTextField.stringValue)
            arguments.append(logsLocation.url?.path ?? "")
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
        
    @IBAction func efiStop(_ sender: Any) {
        if efiTask.suspend() {
            efiTask.terminate()
        }
    }
    
    @IBAction func selected(_ sender: NSButton) {
        selectAllButton.state = .off
        switch sender.state {
        case .on:
            itemsArr.append(efiList[efiTableView.row(for: sender)])
        case .off:
            itemsArr = itemsArr.filter{$0 != efiList[efiTableView.row(for: sender)]}
        case .mixed:
            MyLog("mixed")
        default:break
        }
        if itemsArr.count == efiList.count {
            selectAllButton.state = .on
        }
        MyLog(itemsArr)
    }
    
    @IBAction func SelectAll(_ sender: NSButton) {
        switch sender.state {
        case .on:
            itemsArr = []
            selectAll = 1
            efiTableView.reloadData()
            for i in 0..<efiList.count {
                itemsArr.append(efiList[i])
            }
        case .off:
            selectAll = 0
            efiTableView.reloadData()
            itemsArr = []
        case .mixed:
            MyLog("mixed")
        default:
            break
        }
        MyLog(itemsArr)
    }
    
    func runBuildScripts(_ arguments: [String]) {
        self.resetStatus(isRunning: true)
        taskQueue.async {
            if let path = Bundle.main.path(forResource: "getEFI", ofType:"command") {
                self.efiTask = Process()
                self.efiTask.launchPath = path
                self.efiTask.arguments = arguments
                self.efiTask.environment = ["PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:"]
                self.efiTask.terminationHandler = { task in
                    DispatchQueue.main.async(execute: { [weak self] in
                        guard let `self` = self else { return }
                        self.resetStatus(isRunning: false)
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

extension ViewControllerEFI: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return efiList.count
    }
}

extension ViewControllerEFI: NSTableViewDelegate {
    
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
                button.action = #selector(selected(_:))
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

extension ViewControllerEFI: NSTextFieldDelegate {
    
    func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            proxy = textField.stringValue
        }
    }
    
}

