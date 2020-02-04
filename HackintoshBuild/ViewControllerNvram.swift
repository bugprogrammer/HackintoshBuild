//
//  ViewControllerNvram.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2020/1/27.
//  Copyright © 2020 bugprogrammer. All rights reserved.
//

import Cocoa

class ViewControllerNvram: NSViewController {

    @IBOutlet var nvramTextView: NSTextView!
    @IBOutlet weak var nvramTableView: NSTableView!
    
    var nvramInfo:String = ""
    var keysArr:[String] = []
    var flag:Int = 0
    
    let taskQueue = DispatchQueue.global(qos: .background)
    let lock = NSLock()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        runBuildScripts("nvramKeys",[])
        nvramTableView.target = self
        nvramTableView.action = #selector(tableViewClick(_:))
    }
    
    func runBuildScripts(_ shell: String, _ arguments: [String]) {
        taskQueue.async {
            if let path = Bundle.main.path(forResource: shell, ofType:"command") {
                let task = Process()
                task.launchPath = path
                task.arguments = arguments
                task.terminationHandler = { task in
                    DispatchQueue.main.async(execute: { [weak self] in
                        guard let `self` = self else { return }
                        self.lock.lock()
                        if self.flag == 0 {
                            self.keysArr =  self.nvramInfo.components(separatedBy:"\n")
                            if self.keysArr.last == "" {
                                self.keysArr.removeLast()
                            }
                            if self.keysArr.first == "" {
                                self.keysArr.removeFirst()
                            }
                            self.nvramTableView.reloadData()
                            self.flag = 1
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
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return keysArr[row]
    }
    
}
