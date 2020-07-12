//
//  ViewControllerPCI.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2020/3/28.
//  Copyright © 2020 bugprogrammer. All rights reserved.
//

import Cocoa

class PCIObject: InBaseObject {
    
    struct Info: Codable {
        let Name: String
        let Vendor: String
    }
    struct ID: Codable {
        let VendorID: String
        let DeviceID: String
    }
    struct Class: Codable {
        let ClassName: String
    }
    struct PCI: Codable {
        let Info: Info
        let ID: ID
        let BDF: String
        let Class: Class
    }
    var pci: [PCI]?
    var output: String = ""
    let gfxutil = Bundle.main.path(forResource: "gfxutil", ofType: "", inDirectory: "tools")
    let dspci = Bundle.main.path(forResource: "dspci", ofType: "", inDirectory: "tools")
    let taskQueue = DispatchQueue.global(qos: .default)
    let lock = NSLock()
    let keys: [String] = ["供应商id", "设备id", "供应商名称", "设备类型", "设备名称", "ioreg地址", "设备地址"]
    var value: [String] = []
    var ioregArr: [String] = []
    var devicepathArr: [String] = []
    var BDF: String = ""

    @IBOutlet weak var refreshButton: NSButton!
    @IBOutlet weak var ioregTextField: NSTextField!
    @IBOutlet weak var pciTableView: NSTableView!
    @IBOutlet weak var infoTableView: NSTableView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        refreshButton.isBordered = false
        refreshButton.bezelStyle = .recessed
        let image = NSImage(named: "NSRefreshFreestandingTemplate")
        image?.isTemplate = true
        image?.size = CGSize(width: 20, height: 20)
        refreshButton.image = image
        refreshButton.target = self
        refreshButton.action = #selector(refresh)
        refreshButton.toolTip = "刷新 PCI 信息"
        pciTableView.tableColumns.forEach { (column) in
            column.headerCell.alignment = .left
        }
        pciTableView.target = self
        pciTableView.action = #selector(tableViewClick(_:))
        pciTableView.doubleAction = #selector(tableViewDoubleClick(_:))
    }
    
    override func willAppear(_ noti: Notification) {
        super.willAppear(noti)
        
        let index = noti.object as! Int
        if index != 4 { return }
        if !once { return }
        once = false
        
        var arguments: [String] = []
        arguments.append(dspci!)
        MyLog(arguments)
        runBuildScripts("dspci", arguments)
    }
    
    @objc func tableViewClick(_ sender: AnyObject) {
        value = ["0x" + pci![pciTableView.selectedRow].ID.VendorID.uppercased(), "0x" + pci![pciTableView.selectedRow].ID.DeviceID.uppercased(), pci![pciTableView.selectedRow].Info.Vendor, pci![pciTableView.selectedRow].Class.ClassName, pci![pciTableView.selectedRow].Info.Name, ioregArr[pciTableView.selectedRow], devicepathArr[pciTableView.selectedRow]]
        infoTableView.reloadData()

    }
    
    @objc func refresh() {
        value = []
        pciTableView.reloadData()
        infoTableView.reloadData()
        ioregTextField.stringValue = ""
        var arguments: [String] = []
        arguments.append(dspci!)
        runBuildScripts("dspci", arguments)
    }
    
    @objc func tableViewDoubleClick(_ sender: AnyObject) {
        if pciTableView.selectedRow != -1 {
            let pasteBoard = NSPasteboard.general
            pasteBoard.clearContents()
            pasteBoard.setString(devicepathArr[pciTableView.selectedRow], forType: .string)
            ioregTextField.stringValue = devicepathArr[pciTableView.selectedRow]
            let alert = NSAlert()
            alert.messageText = "已复制到剪贴板"
            alert.runModal()
        }
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
                        //if data.count > 0 {
                            let outputString = String(data: data, encoding: String.Encoding.utf8) ?? ""
                            OperationQueue.main.addOperation { [weak self] in
                                guard let `self` = self else { return }
                                self.lock.lock()
                                let previousOutput = self.output
                                let nextOutput = previousOutput + outputString
                                self.output = nextOutput
                                if shell == "dspci" {
                                    if let jsonData = (self.output as NSString).data(using: String.Encoding.utf8.rawValue) {
                                        self.pci = try? JSONDecoder().decode([PCI].self, from: jsonData as Data)
                                        self.pci = self.pci!.sorted(by: { $0.BDF < $1.BDF })
                                        MyLog(self.pci)
                                        for i in 0..<self.pci!.count {
                                            self.BDF.append(self.pci![i].BDF)
                                            if i != self.pci!.count - 1 {
                                                self.BDF.append(",")
                                            }
                                        }
                                        MyLog(self.BDF)
                                        var arguments: [String] = []
                                        arguments.append(self.gfxutil!)
                                        arguments.append(self.BDF)
                                        self.runBuildScripts("pcipath", arguments)
                                    }
                                }
                                
                                if shell == "pcipath" {
                                    MyLog(self.output)
                                    var pathArr = self.output.components(separatedBy: "\n")
                                    if pathArr.first == "" {
                                        pathArr.removeFirst()
                                    }
                                    if pathArr.last == "" {
                                        pathArr.removeLast()
                                    }
                                    for path in pathArr {
                                        var FinalArr = path.components(separatedBy: " = ")
                                        if FinalArr.first == "" {
                                            FinalArr.removeFirst()
                                        }
                                        if FinalArr.last == "" {
                                            FinalArr.removeLast()
                                        }
                                        self.ioregArr.append(FinalArr[0].replacingOccurrences(of: "\n", with: ""))
                                        self.devicepathArr.append(FinalArr[1].replacingOccurrences(of: "\n", with: ""))
                                    }
                                    self.pciTableView.reloadData()
                                }
                                
                                self.lock.unlock()
                            }
                            if (!task.isRunning) {
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

extension PCIObject: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == self.pciTableView {
            return pci?.count ?? 0
        }
        else {
            return keys.count
        }
    }

}

extension PCIObject: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, shouldTrackCell cell: NSCell, for tableColumn: NSTableColumn?, row: Int) -> Bool {
        return true
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 19
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        if tableView == self.pciTableView {
            if tableColumn != nil {
                let identifier = tableColumn!.identifier.rawValue
                switch identifier {
                case "vid":
                    let textField = NSTextField()
                    textField.cell = VerticallyCenteredTextFieldCell()
                    textField.stringValue = "0x" + self.pci![row].ID.VendorID.uppercased()
                    textField.alignment = .left
                    textField.isBordered = false
                return textField
                case "pid":
                    let textField = NSTextField()
                    textField.cell = VerticallyCenteredTextFieldCell()
                    textField.stringValue = "0x" + self.pci![row].ID.DeviceID.uppercased()
                    textField.alignment = .left
                    textField.isBordered = false
                return textField
                case "vendor":
                    let textField = NSTextField()
                    textField.cell = VerticallyCenteredTextFieldCell()
                    textField.stringValue = self.pci![row].Info.Vendor
                    textField.alignment = .left
                    textField.isBordered = false
                return textField
                case "type":
                    let textField = NSTextField()
                    textField.cell = VerticallyCenteredTextFieldCell()
                    textField.stringValue = self.pci![row].Class.ClassName
                    textField.alignment = .left
                    textField.isBordered = false
                    return textField
                case "model":
                    let textField = NSTextField()
                    textField.cell = VerticallyCenteredTextFieldCell()
                    textField.stringValue = self.pci![row].Info.Name
                    textField.alignment = .left
                    textField.isBordered = false
                    return textField
                case "ioreg":
                    let textField = NSTextField()
                    textField.cell = VerticallyCenteredTextFieldCell()
                    textField.stringValue = self.ioregArr[row]
                    textField.alignment = .left
                    textField.isBordered = false
                    return textField
                case "devicepath":
                    let textField = NSTextField()
                    textField.cell = VerticallyCenteredTextFieldCell()
                    textField.stringValue = self.devicepathArr[row]
                    textField.alignment = .left
                    textField.isBordered = false
                    return textField

                default:
                    return nil
                }
            }
            return nil
        }
        else {
            if tableColumn != nil {
                let identifier = tableColumn!.identifier.rawValue
                switch identifier {
                case "keys":
                    if value != [] {
                        let textField = NSTextField()
                            textField.cell = VerticallyCenteredTextFieldCell()
                            textField.stringValue = self.keys[row]
                            textField.alignment = .left
                            textField.isBordered = false
                        return textField
                    }
                case "values":
                    if value != [] {
                        let textField = NSTextField()
                            textField.cell = VerticallyCenteredTextFieldCell()
                            textField.stringValue = self.value[row]
                            textField.alignment = .left
                            textField.isBordered = false
                        return textField
                    }
                default:
                    return nil
                }
            }
            return nil
        }

    }
}
