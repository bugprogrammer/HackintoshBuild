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
    let gfxutil = Bundle.main.path(forResource: "gfxutil", ofType: "", inDirectory: "tools")
    let taskQueue = DispatchQueue.global(qos: .default)
    let lock = NSLock()

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
        self.output = ""
            taskQueue.async {
                if let path = Bundle.main.path(forResource: shell, ofType:"command") {
                    var massa: Int32 = 0
                    var slave: Int32 = 0
                    var tt: termios = termios()
                    openpty(&massa, &slave, nil, &tt, nil)
                    
                    let task = Process()
                    task.launchPath = path
                    task.arguments = arguments
                    task.environment = ["PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:"]
                    
                    let outputPipe = Pipe()
                    outputPipe.fileHandleForReading.readabilityHandler = { handle in
                        let data = handle.readDataToEndOfFile()
                        if data.count > 0 {
                            let outputString = String(data: data, encoding: String.Encoding.utf8) ?? ""
                            OperationQueue.main.addOperation { [weak self] in
                                guard let `self` = self else { return }
                                self.lock.lock()
                                let previousOutput = self.output
                                let nextOutput = previousOutput + outputString
                                self.output = nextOutput
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
                                self.lock.unlock()
                            }
                        } else if (data.count == 0 && !task.isRunning) {
                            handle.readabilityHandler = nil
                        }
                    }

                    // Fake tty:
                    task.standardInput = FileHandle(fileDescriptor: slave)
                    task.standardOutput = outputPipe
                    task.standardError = outputPipe
                    task.launch()
    //                task.waitUntilExit()
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

