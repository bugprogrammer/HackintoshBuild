//
//  ViewControllerPCI.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2020/3/28.
//  Copyright © 2020 bugprogrammer. All rights reserved.
//

import Cocoa

class ViewControllerPCI: NSViewController {
    
    class PCI {
        var vid: String = ""
        var pid: String = ""
        var ioreg: String = ""
        var devicepath: String = ""
        
        init(_ vid: String, _ pid: String, _ ioreg: String, _ devicepath: String) {
            self.vid = vid
            self.pid = pid
            self.ioreg = ioreg
            self.devicepath = devicepath
        }
    }
    var pci: [PCI] = []
    var output: String = ""
    var pciArray: [String] = []
    let gfxutil = Bundle.main.path(forResource: "gfxutil", ofType: "")
    let taskQueue = DispatchQueue.global(qos: .default)

    @IBOutlet weak var pciTableView: NSTableView!
    @IBOutlet var pciTextView: NSTextView!
    @IBOutlet var copyTextView: NSTextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pciTableView.tableColumns.forEach { (column) in
            column.headerCell.alignment = .left
        }
        runBuildScripts("pci", [gfxutil!])
        pciTableView.target = self
        pciTableView.action = #selector(tableViewClick(_:))
        pciTableView.doubleAction = #selector(tableViewDoubleClick(_:))
    }
    
    @objc func tableViewClick(_ sender: AnyObject) {
        pciTextView.string = ""
        pciTextView.string.append("供应商id" + "\t" + "\t" + pci[pciTableView.selectedRow].vid + "\n")
        pciTextView.string.append("设备id" + "\t" + "\t" + pci[pciTableView.selectedRow].pid + "\n")
        pciTextView.string.append("ioreg地址" + "\t" + "\t" + pci[pciTableView.selectedRow].ioreg + "\n")
        pciTextView.string.append("设备地址" + "\t" + "\t" + pci[pciTableView.selectedRow].devicepath)
    }
    
    @objc func tableViewDoubleClick(_ sender: AnyObject) {
        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.setString(pci[pciTableView.selectedRow].devicepath, forType: .string)
        copyTextView.string = pci[pciTableView.selectedRow].devicepath
        let alert = NSAlert()
        alert.messageText = "已复制到剪贴板"
        alert.runModal()
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
                        if shell == "pci" {
                            MyLog(self.output)
                            self.pciArray = self.output.components(separatedBy: "\n")
                            if self.pciArray.last == "" {
                                self.pciArray.removeLast()
                            }
                            if self.pciArray.first == "" {
                                self.pciArray.removeFirst()
                            }
                            for item in self.pciArray {
                                let pciFinal = item.trimmingCharacters(in: .whitespaces).components(separatedBy: " ")
                                self.pci.append(PCI("0x" + pciFinal[0].uppercased(), "0x" + pciFinal[1].uppercased(), pciFinal[2], pciFinal[3]))
                            }
                            self.pciTableView.reloadData()
                        }
                    })
                }
                self.taskOutPut(task)
                task.launch()
                task.waitUntilExit()
            }
        }
    }
    
    func taskOutPut(_ task:Process) {
        output = ""
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading, queue: nil) { notification in
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

extension ViewControllerPCI: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return pci.count
    }
}

extension ViewControllerPCI: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, shouldTrackCell cell: NSCell, for tableColumn: NSTableColumn?, row: Int) -> Bool {
        return true
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if tableColumn != nil {
            let identifier = tableColumn!.identifier.rawValue
            switch identifier {
            case "vid":
                let textField = NSTextField()
                textField.cell = VerticallyCenteredTextFieldCell()
                textField.stringValue = self.pci[row].vid
                textField.alignment = .left
                textField.isBordered = false
            return textField
            case "pid":
                let textField = NSTextField()
                textField.cell = VerticallyCenteredTextFieldCell()
                textField.stringValue = self.pci[row].pid
                textField.alignment = .left
                textField.isBordered = false
            return textField
            case "ioreg":
                let textField = NSTextField()
                textField.cell = VerticallyCenteredTextFieldCell()
                textField.stringValue = self.pci[row].ioreg
                textField.alignment = .left
                textField.isBordered = false
                return textField
            case "devicepath":
                let textField = NSTextField()
                textField.cell = VerticallyCenteredTextFieldCell()
                textField.stringValue = self.pci[row].devicepath
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

