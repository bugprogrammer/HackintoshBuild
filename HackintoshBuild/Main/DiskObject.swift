//
//  ViewControllerDisk.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2020/1/22.
//  Copyright © 2020 bugprogrammer. All rights reserved.
//

import Cocoa

class DiskObject: OutBaseObject {
    
    class DiskInfoObject {
        var name: String
        var type: String
        var size: String
        var bsd: String
        var isMounted: Bool
        var isBoot: String
        
        init(name: String, type: String, size: String, bsd: String, isMounted: Bool, isBoot: String) {
            self.name = name
            self.type = type
            self.size = size
            self.bsd = bsd
            self.isMounted = isMounted
            self.isBoot = isBoot
        }
    }
    
    var diskInfoObject: [DiskInfoObject] = []
        
    @IBOutlet weak var diskTableView: NSTableView!
    @IBOutlet weak var refreshButton: NSButton!
    
    let bdmesg = Bundle.main.path(forResource: "bdmesg", ofType: "", inDirectory: "tools")
    
    var diskInfo:String = ""
    var arrayPartition:[String] = []
    var index: Int = 0
    let taskQueue = DispatchQueue.global(qos: .default)
    var flag: Int = 0
    
    override func willAppear(_ noti: Notification) {
        super.willAppear(noti)
        
        let index = noti.object as! Int
        if index != 3 { return }
        
        if !once { return }
        once = false
        
        let image = MyAsset.refresh.image
        image.isTemplate = true
        refreshButton.image = image
        refreshButton.isEnabled = false
        arrayPartition = []
        diskInfoObject = []
        diskTableView.reloadData()
        runBuildScripts("diskInfo", [bdmesg!])
        diskTableView.tableColumns.forEach { (column) in
            column.headerCell.alignment = .center
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        refreshButton.toolTip = "刷新 EFI 列表"
    }
    
    @IBAction func refreshDidClicked(_ sender: NSButton) {
        refreshButton.isEnabled = false
        arrayPartition = []
        diskInfoObject = []
        diskTableView.reloadData()
        runBuildScripts("diskInfo",[bdmesg!])
    }
    
    func runBuildScripts(_ shell: String,_ arguments: [String]) {
        AraHUDViewController.shared.showHUD()
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
                            MyLog(self.diskInfo)
                            self.arrayPartition = self.diskInfo.components(separatedBy:"\n")
                            if self.arrayPartition.last == "" {
                                self.arrayPartition.removeLast()
                            }
                            if self.arrayPartition.first == "" {
                                self.arrayPartition.removeFirst()
                            }
                            
                            for i in 0 ..< self.arrayPartition.count {
                                var diskFinal = self.arrayPartition[i].components(separatedBy: ":")
                                if diskFinal.count == 6 {
                                    diskFinal.append("")
                                }
                                diskFinal = self.arrTools(diskFinal, 3, 4)
                                self.diskInfoObject.append(DiskInfoObject(
                                    name: diskFinal[0],
                                    type: diskFinal[1],
                                    size: diskFinal[2],
                                    bsd: diskFinal[3],
                                    isMounted: diskFinal[4].lowercased() != "no",
                                    isBoot: diskFinal[5])
                                )
                                MyLog(diskFinal)
                            }
                            self.diskTableView.reloadData()
                        } else if shell == "diskMount" {
                            let alert = NSAlert()
                            if self.diskInfo.contains("mounted") {
                                alert.messageText = "EFI 挂载成功"
                                self.diskInfoObject[self.index].isMounted = true
                                self.diskTableView.reloadData()
                            } else {
                                alert.messageText = "EFI 挂载失败"
                            }
                            alert.runModal()
                        }
                        else if shell == "diskUnmount" {
                            let alert = NSAlert()
                            if self.diskInfo.contains("unmounted") {
                                alert.messageText = "EFI 卸载成功"
                                self.diskInfoObject[self.index].isMounted = false
                                self.diskTableView.reloadData()
                            } else {
                                alert.messageText = "EFI 卸载失败"
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
    
    func arrTools(_ arr: [String], _ i: Int, _ j: Int) -> [String] {
        var arr = arr
        arr[i-1] = arr[i-1] + " " + arr[j-1]
        arr = arr.filter{$0 != arr[j-1]}
        return arr
    }
}

extension DiskObject: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return diskInfoObject.count
    }
    
}

extension DiskObject: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, shouldTrackCell cell: NSCell, for tableColumn: NSTableColumn?, row: Int) -> Bool {
        return true
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if tableColumn != nil {
            let identifier = tableColumn!.identifier.rawValue
            switch identifier {
            case "icon":
                let image = MyAsset.NSToolbarItem_Disk.image
                image.isTemplate = true
                return NSImageView(image: image)
            case "name":
                let textField = NSTextField()
                textField.cell = VerticallyCenteredTextFieldCell()
                textField.stringValue = self.diskInfoObject[row].name
                textField.alignment = .center
                textField.isBordered = false
                return textField
            case "type":
                let textField = NSTextField()
                textField.cell = VerticallyCenteredTextFieldCell()
                textField.stringValue = self.diskInfoObject[row].type
                textField.alignment = .center
                textField.isBordered = false
                return textField
            case "state":
                let textField = NSTextField()
                textField.cell = VerticallyCenteredTextFieldCell()
                textField.stringValue = self.diskInfoObject[row].isMounted ? "已挂载" : "未挂载"
                textField.alignment = .center
                textField.isBordered = false
                return textField
            case "size":
                let textField = NSTextField()
                textField.cell = VerticallyCenteredTextFieldCell()
                textField.stringValue = self.diskInfoObject[row].size
                textField.alignment = .center
                textField.isBordered = false
                return textField
            case "bsd":
                let textField = NSTextField()
                textField.cell = VerticallyCenteredTextFieldCell()
                textField.stringValue = self.diskInfoObject[row].bsd
                textField.alignment = .center
                textField.isBordered = false
                return textField
            case "boot":
                let button = NSButton()
                button.setButtonType(.radio)
                button.bezelStyle = .inline
                button.title = ""
                button.alignment = .right
                if self.diskInfoObject[row].isBoot == "当前引导分区" {
                    button.state = .on
                }
                else {
                    button.isHidden = true
                }
                return button
            case "mount":
                let button = NSButton()
                button.target = self
                button.action = #selector(mountButtonAction(_:))
                button.bezelStyle = .recessed
                button.isBordered = false
                if !self.diskInfoObject[row].isMounted {
                    let image = MyAsset.mount.image
                    image.isTemplate = true
                    button.image = image
                    button.toolTip = "挂载当前 EFI 分区"
                }
                else {
                    let image = MyAsset.unmount.image
                    image.isTemplate = true
                    button.image = image
                    button.toolTip = "卸载当前 EFI 分区"
                }
                button.tag = self.diskInfoObject[row].isMounted ? 1 : 0
                return button
            case "open":
                let button = NSButton()
                button.target = self
                button.action = #selector(openButtonAction(_:))
                button.bezelStyle = .recessed
                button.isBordered = false
                let image = MyAsset.open.image
                image.isTemplate = true
                button.image = image
                button.tag = self.diskInfoObject[row].isMounted ? 1 : 0
                if !self.diskInfoObject[row].isMounted {
                    button.isEnabled = false
                }
                button.toolTip = "打开当前 EFI 分区"
                return button
            default:
                return nil
            }
        }
        return nil
    }
    
    @objc func mountButtonAction(_ sender: NSButton) {
        index = diskTableView.row(for: sender)
        refreshButton.isEnabled = false
        
        if sender.tag == 0 {
            runBuildScripts("diskMount", [diskInfoObject[index].bsd])
        } else {
            runBuildScripts("diskUnmount", [diskInfoObject[index].bsd])
        }
    }
    
    @objc func openButtonAction(_ sender: NSButton) {
        index = diskTableView.row(for: sender)
        refreshButton.isEnabled = false
        
        if sender.tag == 0 {
            let alert = NSAlert()
            alert.messageText = "未挂载，无法打开"
            alert.runModal()
        } else {
            runBuildScripts("openEFI", [diskInfoObject[index].bsd])
        }
    }
}
