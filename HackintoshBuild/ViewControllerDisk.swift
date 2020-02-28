//
//  ViewControllerDisk.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2020/1/22.
//  Copyright © 2020 bugprogrammer. All rights reserved.
//

import Cocoa

class ViewControllerDisk: NSViewController {
        
    @IBOutlet weak var diskTableView: NSTableView!
    @IBOutlet weak var refreshButton: NSButton!
    
    var diskInfo:String = ""
    var arrayPartition:[String] = []
    var mount:String = ""
    
    let taskQueue = DispatchQueue.global(qos: .background)
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        refreshButton.isEnabled = false
        arrayPartition = []
        diskTableView.reloadData()
        runBuildScripts("diskInfo",[])
        diskTableView.target = self
        diskTableView.doubleAction = #selector(tableViewDoubleClick(_:))
    }
    
    @IBAction func Refresh(_ sender: Any) {
        refreshButton.isEnabled = false
        arrayPartition = []
        diskTableView.reloadData()
        runBuildScripts("diskInfo",[])
    }
    func runBuildScripts(_ shell: String,_ arguments: [String]) {
        AraHUDViewController.shared.showHUDWithTitle(title: "正在进行中")
        taskQueue.async {
            if let path = Bundle.main.path(forResource: shell, ofType:"command") {
                let task = Process()
                task.launchPath = path
                task.arguments = arguments
                task.environment = ["PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:"]
                task.terminationHandler = { task in
                    DispatchQueue.main.async(execute: { [weak self] in
                        guard let `self` = self else { return }
                        AraHUDViewController.shared.hideHUD()
                        if shell == "diskInfo" {
                            self.arrayPartition = self.diskInfo.components(separatedBy:"\n")
                            if self.arrayPartition.last == "" {
                                self.arrayPartition.removeLast()
                            }
                            if self.arrayPartition.first == "" {
                                self.arrayPartition.removeFirst()
                            }
                            
                            for i in 0..<self.arrayPartition.count-1 {
                                if self.arrayPartition[i].components(separatedBy: " ").last == self.arrayPartition.last {
                                    self.arrayPartition[i].append("      当前引导分区")
                                    self.mount = self.arrayPartition.last!
                                }
                            }
                            if !self.arrayPartition.last!.contains(" ") {
                                self.arrayPartition.removeLast()
                            }
                            MyLog(self.diskInfo)
                            self.diskTableView.reloadData()
                        } else {
                            let alert = NSAlert()
                            if self.diskInfo.contains("mounted") {
                                alert.messageText = "EFI 挂载成功"
                            } else {
                                alert.messageText = "EFI 挂载失败"
                            }
                            alert.runModal()
                        }
                        self.refreshButton.isEnabled = true
                    })
                }
                self.taskOutPut(task)
                task.launch()
                task.waitUntilExit()
            }
        }
    }
    
    func taskOutPut(_ task:Process) {
        diskInfo = ""
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading, queue: nil) { notification in
            let output = outputPipe.fileHandleForReading.availableData
            if output.count > 0 {
                outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
                let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
                DispatchQueue.main.async(execute: {
                    let previousOutput = self.diskInfo
                    let nextOutput = previousOutput + outputString
                    self.diskInfo = nextOutput
                })
            }
        }
    }
    
    @objc func tableViewDoubleClick(_ sender:AnyObject) {
        if diskTableView.selectedRow != -1 && diskTableView.selectedRow % 2 != 0 {
            refreshButton.isEnabled = false
            let arrayMount = arrayPartition[diskTableView.selectedRow].components(separatedBy:" ")
            if arrayMount.last! == "当前引导分区" {
                runBuildScripts("diskMount", [mount])
            }
            else {
                runBuildScripts("diskMount", [arrayMount.last!])
            }
        }
    }
}

extension ViewControllerDisk: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return arrayPartition.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return arrayPartition[row]
    }
    
}
