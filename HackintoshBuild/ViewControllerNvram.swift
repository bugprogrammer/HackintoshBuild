//
//  ViewControllerNvram.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2020/1/27.
//  Copyright © 2020 bugprogrammer,Arabaku. All rights reserved.
//

import Cocoa

class ViewControllerNvram: NSViewController {

    @IBOutlet weak var refreshButton: NSButton!
    @IBOutlet var nvramTextView: NSTextView!
    @IBOutlet weak var nvramTableView: NSTableView!
    
    var nvramInfo:String = ""
    var keysArr:[String] = []
    
    let taskQueue = DispatchQueue.global(qos: .background)
    let lock = NSLock()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshButton.image = NSImage(named: "refresh.png")
        refreshButton.bezelStyle = .recessed
        refreshButton.isBordered = false
        runBuildScripts("nvramKeys",[])
        nvramTableView.target = self
        nvramTableView.action = #selector(tableViewClick(_:))
    }
    
    @IBAction func Refresh(_ sender: Any) {
        runBuildScripts("nvramKeys",[])
    }
    func runBuildScripts(_ shell: String, _ arguments: [String]) {
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
                        if shell == "nvramKeys" {
                            self.keysArr =  self.nvramInfo.components(separatedBy:"\n")
                            if self.keysArr.last == "" {
                                self.keysArr.removeLast()
                            }
                            if self.keysArr.first == "" {
                                self.keysArr.removeFirst()
                            }
                            self.nvramTableView.reloadData()
                            self.runBuildScripts("nvramValues", [self.keysArr[0]])
                        }
                        else {
                            self.nvramTextView.string = self.nvramInfo
                        }
                        self.lock.unlock()
                    })
                }
                self.taskOutPut(task)
                task.launch()
                task.waitUntilExit()
            }
        }
    }
    
    func taskOutPut(_ task: Process) {
        self.nvramInfo = ""
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading , queue: nil) { notification in
            let output = outputPipe.fileHandleForReading.availableData
            if output.count > 0 {
                outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
                let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
                let previousOutput = self.nvramInfo
                let nextOutput = previousOutput + outputString
                self.nvramInfo = nextOutput
            }
        }
    }
    
    @objc func tableViewClick(_ sender:AnyObject) {
        if nvramTableView.selectedRow != -1 {
            runBuildScripts("nvramValues", [keysArr[nvramTableView.selectedRow]])
        }
    }

}

extension ViewControllerNvram: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return keysArr.count
    }
    
}

extension ViewControllerNvram: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, shouldTrackCell cell: NSCell, for tableColumn: NSTableColumn?, row: Int) -> Bool {
        return true
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if tableColumn != nil {
            let identifier = tableColumn!.identifier.rawValue
            switch identifier {
            case "value":
                let textField = NSTextField()
                textField.cell = VerticallyCenteredTextFieldCell()
                textField.stringValue = self.keysArr[row]
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
