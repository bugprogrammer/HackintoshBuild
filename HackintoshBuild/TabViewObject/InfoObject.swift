//
//  ViewControllerInfo.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2020/2/29.
//  Copyright © 2020 bugprogrammer. All rights reserved.
//

import Cocoa

class InfoObject: InBaseObject {
    
    class Info {
        var key: String = ""
        var value: String = ""
        
        init(_ key: String, _ value: String) {
            self.key = key
            self.value = value
        }
    }

    var outputArr: [String] = []
    var output: String = ""
    var info: [Info] = []
    
    
    @IBOutlet weak var infoTableView: NSTableView!
    
    let taskQueue = DispatchQueue.global(qos: .default)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if MyTool.isAppleSilicon() {
            runBuildScripts("systeminfo", ["Apple Silicon"])
        } else {
            runBuildScripts("systeminfo", ["Intel"])
        }
    }
    
    func convert(_ str: String) -> String {
        var hexStr: String = ""
        let arr = Array(str)
        for index in stride(from: arr.count-1, to: 0, by: -2) {
            hexStr.append(arr[index-1])
            hexStr.append(arr[index])
        }
        return hexStr.uppercased()
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
                        self.outputArr = self.output.components(separatedBy: "\n")
                        
                        if self.outputArr.first!.isEmpty {
                            self.outputArr.removeFirst()
                        }
                        if self.outputArr.last!.isEmpty {
                            self.outputArr.removeLast()
                        }
//                        MyLog(self.outputArr)
                        for infoStr in self.outputArr {
                            var flag: Bool = false
                            var infoArr = infoStr.components(separatedBy: ":")
                            if infoArr[0] == "核显 ig-platform-id" && infoArr[1] != "" {
                                infoArr[1] = "0x" + self.convert(infoArr[1])
                            } else if infoArr [0] == "Processor Name" {
                                infoArr[1] = self.getProcessorName()
                            }
                            for item in self.info {
                                if item.key.replacingOccurrences(of: " ", with: "").uppercased() == infoArr[0].replacingOccurrences(of: " ", with: "").uppercased() {
                                    flag = true
                                }
                            }
                            if !flag {
                                self.info.append(Info(NSLocalizedString(infoArr[0].trimmingCharacters(in: .whitespaces), comment: ""),NSLocalizedString(infoArr[1].trimmingCharacters(in: .whitespaces), comment: "")))
                            }
                        }
                        
                        self.infoTableView.reloadData()
                    })
                }
                self.taskOutPut(task)
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
                let previousOutput = self.output
                let nextOutput = previousOutput + outputString
                self.output = nextOutput
            }
        }
    }
    
    func getProcessorName() -> String {
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        var buffer = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &buffer, &size, nil, 0)
        return String(cString: buffer)
    }
}

extension InfoObject: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return info.count
    }
    
}

extension InfoObject: NSTableViewDelegate {
    
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
            case "keys":
                let textField = NSTextField()
                textField.cell = VerticallyCenteredTextFieldCell()
                textField.stringValue = self.info[row].key
                textField.alignment = .left
                textField.isBordered = false
            return textField
            case "values":
                let textField = NSTextField()
                textField.cell = VerticallyCenteredTextFieldCell()
                textField.stringValue = self.info[row].value
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
