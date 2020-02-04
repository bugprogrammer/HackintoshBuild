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
    @IBOutlet weak var efiTableView: NSTableView!
    @IBOutlet var progressBar: NSProgressIndicator!    
    @IBOutlet var efiOutPut: NSTextView!
    @IBOutlet var efiStartButton: NSButton!
    @IBOutlet var efiStopButton: NSButton!
    @IBOutlet weak var proxyTextField: NSTextField!
    
    let taskQueue = DispatchQueue.global(qos: .background)
    let lock = NSLock()
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        efiStopButton.isEnabled = false
        progressBar.isHidden = true
        
        proxyTextField.placeholderString = "http://127.0.0.1:xxxx"
        proxyTextField.stringValue = ""
        proxyTextField.refusesFirstResponder = true
        
        if let efiLocation = UserDefaults.standard.url(forKey: "efiLocation") {
            if FileManager.default.fileExists(atPath: efiLocation.path) {
                self.efiLocation.url = efiLocation
            }
        }
        
        self.efiTableView.reloadData()
    }
    
    var isRunning = false
    var efiTextPipe: Pipe!
    var efiTask: Process!
    var itemsArr: [String] = []
    var itemsSting: String = ""
        
    @IBAction func efiStart(_ sender: Any) {
        if let efiURL = efiLocation.url {
            UserDefaults.standard.set(efiURL, forKey: "efiLocation")
            
            var arguments: [String] = []
            
            efiStopButton.isEnabled = true
            progressBar.isHidden = false
            efiOutPut.string = ""
            efiStartButton.isEnabled = false
            progressBar.startAnimation(self)
            itemsSting = itemsArr.joined(separator: ",")
            arguments.append(efiURL.path)
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
        
    @IBAction func efiStop(_ sender: Any) {
        efiStartButton.isEnabled = true
        efiStopButton.isEnabled = false
        progressBar.isHidden = true
        
        if isRunning  {
            self.progressBar.doubleValue = 0.0
            efiTask.terminate()
        }
    }
        
    @IBAction func selected(_ sender: NSButton) {
        switch sender.state {
        case .on:
            itemsArr.append(efiList[efiTableView.row(for: sender)])
        case .off:
            itemsArr = itemsArr.filter{$0 != efiList[efiTableView.row(for: sender)]}
        case .mixed:
            MyLog("mixed")
        default:break
        }
        MyLog(itemsArr)
    }
    
    func runBuildScripts(_ arguments: [String]) {
        isRunning = true
        let taskQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        taskQueue.async {
            if let path = Bundle.main.path(forResource: "getEFI", ofType:"command") {
                let efiTask = Process()
                efiTask.launchPath = path
                efiTask.arguments = arguments
                efiTask.terminationHandler = { task in
                DispatchQueue.main.async(execute: { [weak self] in
                    guard let `self` = self else { return }
                    self.lock.lock()
                        self.efiStopButton.isEnabled = false
                        self.efiStartButton.isEnabled = true
                        self.progressBar.isHidden = true
                        self.progressBar.stopAnimation(self)
                        self.progressBar.doubleValue = 0.0
                        self.isRunning = false
                    self.lock.unlock()
                    })
                }
                self.efiOutPut(efiTask)
                efiTask.launch()
                efiTask.waitUntilExit()
            }
        }
    }
    
    func efiOutPut(_ task:Process) {
        efiTextPipe = Pipe()
        task.standardOutput = efiTextPipe
        efiTextPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: efiTextPipe.fileHandleForReading , queue: nil) {
            notification in
            let output = self.efiTextPipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
            DispatchQueue.main.async(execute: {
                let previousOutput = self.efiOutPut.string
                let nextOutput = previousOutput + "\n" + outputString
                self.efiOutPut.string = nextOutput
                let range = NSRange(location:nextOutput.count,length:0)
                self.efiOutPut.scrollRangeToVisible(range)
                self.progressBar.increment(by: 1.9)
            })
            self.efiTextPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        }
    }
}

extension ViewControllerEFI: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return efiList.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return efiList[row]
    }
    
}
