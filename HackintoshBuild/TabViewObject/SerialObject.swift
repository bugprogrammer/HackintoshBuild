//
//  ViewControllerSerial.swift
//  HackintoshBuild
//
//  Created by wbx on 2020/4/28.
//  Copyright © 2020 bugprogrammer. All rights reserved.
//

import Cocoa

class SerialObject: InBaseObject {

    @IBOutlet weak var MedolList: NSPopUpButton!
    @IBOutlet weak var refreshButton: NSButton!
    @IBOutlet weak var tableview: NSTableView!
    
    let medolsurl = Bundle.main.path(forResource: "models", ofType: "txt", inDirectory: "tools")
    let macserialurl = Bundle.main.path(forResource: "macserial", ofType: nil, inDirectory: "tools")
    let taskQueue = DispatchQueue.global(qos: .default)
    
    var medolArr: [String] = []
    var output: String = ""
    var keysArr: [String] = ["机型", "序列号", "MLB", "UUID"]
    var valuesArr: [String] = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        refreshButton.isBordered = false
        refreshButton.bezelStyle = .recessed
        let image = NSImage(named: "NSRefreshFreestandingTemplate")
        image?.isTemplate = true
        image?.size = CGSize(width: 64, height: 64)
        refreshButton.image = image
        refreshButton.target = self
        refreshButton.action = #selector(refresh)
        refreshButton.toolTip = "生成新的序列号信息"
        tableview.target = self
        tableview.doubleAction = #selector(tableViewDoubleClick)
        MedolList.target = self
        MedolList.action = #selector(getMacSerial)
        getMedolsList(medolsurl!)
    }
    
    override func willAppear(_ noti: Notification) {
        super.willAppear(noti)
        
        let index = noti.object as! Int
        if index != 5 { return }
        var arguments: [String] = []
        arguments.append(macserialurl!)
        arguments.append(medolArr[0])
        runBuildScripts("macserial", arguments)
        if !once { return }
        once = false
    }
    
    func getMedolsList(_ models: String) {
        do {
            let file = try String(contentsOfFile: models)
            medolArr = file.components(separatedBy: "\n")
            MedolList.addItems(withTitles: medolArr)
        } catch let error {
            MyLog("Fatal Error: \(error.localizedDescription)")
        }
    }
    
    @objc func refresh() {
        var arguments: [String] = []
        arguments.append(macserialurl!)
        arguments.append(medolArr[MedolList.indexOfSelectedItem])
        
        runBuildScripts("macserial", arguments)
    }
    
    @objc func tableViewDoubleClick() {
        if tableview.selectedRow != -1 {
            let pasteBoard = NSPasteboard.general
            pasteBoard.clearContents()
            pasteBoard.setString(valuesArr[tableview.selectedRow], forType: .string)
            let alert = NSAlert()
            alert.messageText = "已复制" + keysArr[tableview.selectedRow] + "到剪贴板"
            alert.runModal()
        }
    }
    
    @objc func getMacSerial() {
        var arguments: [String] = []
        arguments.append(macserialurl!)
        arguments.append(medolArr[MedolList.indexOfSelectedItem])
        
        runBuildScripts("macserial", arguments)
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
                         MyLog(self.output)
                            self.valuesArr = self.output.components(separatedBy: " | ")
                            if self.valuesArr.first == "" {
                                self.valuesArr.removeFirst()
                            }
                            if self.valuesArr.last == "" {
                                self.valuesArr.removeLast()
                            }
                            MyLog(self.valuesArr)
                            self.tableview.reloadData()
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
                DispatchQueue.main.async(execute: {
                    let previousOutput = self.output
                    let nextOutput = previousOutput + outputString
                    self.output = nextOutput
                })
            }
        }
    }
}

extension SerialObject: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return valuesArr.count
    }
}

extension SerialObject: NSTableViewDelegate {

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
                textField.stringValue = self.keysArr[row]
                textField.alignment = .left
                textField.isBordered = false
                return textField
            case "values":
                let textField = NSTextField()
                textField.cell = VerticallyCenteredTextFieldCell()
                textField.stringValue = self.valuesArr[row]
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
