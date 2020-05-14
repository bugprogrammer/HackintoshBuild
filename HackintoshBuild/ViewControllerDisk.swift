//
//  ViewControllerDisk.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2020/1/22.
//  Copyright © 2020 bugprogrammer. All rights reserved.
//

import Cocoa

class ViewControllerDisk: NSViewController {
    
    class DiskInfoObject {
        var name: String = ""
        var type: String = ""
        var volume: String = ""
        var size: String = ""
        var bsd: String = ""
        var mounted: String = ""
        var isboot: String = ""
        
        init(_ name: String, _ type: String, _ volume: String, _ size: String, _ bsd: String, _ mounted: String, _ isboot: String) {
            self.name = name
            self.type = type
            self.volume = volume
            self.size = size
            self.bsd = bsd
            self.mounted = mounted
            self.isboot = isboot
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        let image = NSImage(named: "NSRefreshFreestandingTemplate")
        image?.size = CGSize(width: 64.0, height: 64.0)
        image!.isTemplate = true
        refreshButton.image = image
        refreshButton.bezelStyle = .recessed
        refreshButton.isBordered = false
        refreshButton.toolTip = "刷新EFI列表"
        if flag == 0 {
            refreshButton.isEnabled = false
            arrayPartition = []
            diskInfoObject = []
            diskTableView.reloadData()
            runBuildScripts("diskInfo",[bdmesg!])
            diskTableView.tableColumns.forEach { (column) in
                column.headerCell.alignment = .center
            }
            flag = 1
        }
    }
    
    @IBAction func Refresh(_ sender: Any) {
        refreshButton.isEnabled = false
        arrayPartition = []
        diskInfoObject = []
        diskTableView.reloadData()
        runBuildScripts("diskInfo",[bdmesg!])
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
                            MyLog(self.diskInfo)
                            self.arrayPartition = self.diskInfo.components(separatedBy:"\n")
                            if self.arrayPartition.last == "" {
                                self.arrayPartition.removeLast()
                            }
                            if self.arrayPartition.first == "" {
                                self.arrayPartition.removeFirst()
                            }
                            
                            for i in 0..<self.arrayPartition.count {
                                var diskFinal = self.arrayPartition[i].components(separatedBy: ":")
                                if diskFinal.count < 8 {
                                    if diskFinal.count == 6 {
                                        diskFinal.insert("", at: 2)
                                    }
                                    diskFinal.append("")
                                }
                                MyLog(diskFinal)
                                diskFinal = self.arrTools(diskFinal, 4, 5)
                                self.diskInfoObject.append(DiskInfoObject(diskFinal[0],diskFinal[1],diskFinal[2],diskFinal[3],diskFinal[4],NSLocalizedString(diskFinal[5], comment: ""),diskFinal[6]))
                                MyLog(diskFinal.count)
                                MyLog(diskFinal)
                            }
                            self.diskTableView.reloadData()
                        } else if shell == "diskMount" {
                            let alert = NSAlert()
                            if self.diskInfo.contains("mounted") {
                                alert.messageText = "EFI 挂载成功"
                                self.diskInfoObject[self.index].mounted = "已挂载"
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
                                self.diskInfoObject[self.index].mounted = "未挂载"
                                self.diskTableView.reloadData()
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
    
    func arrTools(_ arr: [String], _ i: Int, _ j: Int) -> [String] {
        var arr = arr
        arr[i-1] = arr[i-1] + arr[j-1]
        arr = arr.filter{$0 != arr[j-1]}
        return arr
    }
}

extension ViewControllerDisk: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return diskInfoObject.count
    }
    
}

extension ViewControllerDisk: NSTableViewDelegate {
    
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
                textField.stringValue = self.diskInfoObject[row].mounted
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
                if self.diskInfoObject[row].isboot == "当前引导分区" {
                    button.state = .on
                }
                else {
                    button.isHidden = true
                }
                return button
            case "mount":
                let button = NSButton()
                button.action = #selector(mountButtonAction(_:))
                button.bezelStyle = .recessed
                button.isBordered = false
                if self.diskInfoObject[row].mounted == "未挂载" {
                    let image = MyAsset.mount.image
                    image.isTemplate = true
                    button.image = image
                    button.toolTip = "挂着当前EFI分区"
                }
                else {
                    let image = MyAsset.unmount.image
                    image.isTemplate = true
                    button.image = image
                    button.toolTip = "卸载当前EFI分区"
                }
                button.tag = self.diskInfoObject[row].mounted == "未挂载" ? 0 : 1
                return button
            case "open":
                let button = NSButton()
                button.action = #selector(openButtonAction(_:))
                button.bezelStyle = .recessed
                button.isBordered = false
                let image = MyAsset.open.image
                image.isTemplate = true
                button.image = image
                button.tag = self.diskInfoObject[row].mounted == "未挂载" ? 0 : 1
                if self.diskInfoObject[row].mounted == "未挂载" {
                    button.isEnabled = false
                }
                button.toolTip = "打开当前EFI分区"
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
