//
//  ViewControllerNvram.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2020/1/27.
//  Copyright © 2020 bugprogrammer,Arabaku. All rights reserved.
//

import Cocoa
import Highlightr

class NvramObject: OutBaseObject {
    
    class NVRAM: NSObject {
        var key: String = ""
        var value: String = ""
        
        init(_ key: String, _ value: String) {
            self.key = key
            self.value = value
        }
    }
    
    var nvram: [NVRAM] = []

    @IBOutlet weak var refreshButton: NSButton!
    @IBOutlet var nvramTextView: NSTextView!
    @IBOutlet weak var nvramTableView: NSTableView!
    
    var nvramInfo: String = ""
    var keysArr: [String] = []
    
    let taskQueue = DispatchQueue.global(qos: .default)
    
    override func willAppear(_ noti: Notification) {
        super.willAppear(noti)
        
        let index = noti.object as! Int
        if index != 4 { return }
        if !once { return }
        once = false
        
        runBuildScripts("nvram", [])
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let image = NSImage(named: "NSRefreshFreestandingTemplate")
        image?.size = CGSize(width: 64.0, height: 64.0)
        image?.isTemplate = true
        refreshButton.image = image
        refreshButton.bezelStyle = .recessed
        refreshButton.isBordered = false
        refreshButton.toolTip = "刷新 NVRAM 信息"
        nvramTableView.target = self
        nvramTableView.action = #selector(tableViewClick(_:))
    }
    
    @IBAction func refreshButtonDidClicked(_ sender: NSButton) {
        runBuildScripts("nvram",[])
    }
    
    func prettyFormat(xmlString: String) -> NSAttributedString? {
      do {
        let highlightr = Highlightr()
        highlightr!.setTheme(to: "paraiso-dark")
        let xml = try XMLDocument.init(xmlString: xmlString, options: [[.nodePrettyPrint, .nodeCompactEmptyElement, .documentTidyXML]])
        let data = xml.xmlData(options: [[.nodePrettyPrint]])
        let str:String? = String(data: data, encoding: .utf8)
        let nvStr = str?.replacingOccurrences(of: "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n", with: "")
        let highlightedCode = highlightr!.highlight(nvStr!, as: "xml")
        return highlightedCode
      }
      catch {
        print (error.localizedDescription)
      }
      return nil
    }
    
    func runBuildScripts(_ shell: String, _ arguments: [String]) {
        nvramInfo = ""
        taskQueue.async {
            if let path = Bundle.main.path(forResource: shell, ofType:"command") {
                let task = Process()
                task.launchPath = path
                task.arguments = arguments
                task.environment = ["PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:"]
                task.terminationHandler = { task in
                    DispatchQueue.main.async(execute: { [weak self] in
                        guard let `self` = self else { return }
                        if shell == "nvram" {
                            if !self.nvramInfo.isEmpty {
                                self.keysArr =  self.nvramInfo.components(separatedBy:"\n")
                                if self.keysArr.last == "" {
                                    self.keysArr.removeLast()
                                }
                                if self.keysArr.first == "" {
                                    self.keysArr.removeFirst()
                                }
                                
                                for item in self.keysArr {
                                    let arr = item.components(separatedBy: ":")
                                    self.nvram.append(NVRAM(arr[0].trimmingCharacters(in: .whitespaces), arr[1].trimmingCharacters(in: .whitespaces)))
                                    MyLog(arr)
                                }
                                self.nvramTableView.reloadData()
                                if self.nvram[0].value.contains("<array>") {
                                    self.nvramTextView.textStorage?.setAttributedString(self.prettyFormat(xmlString: self.nvram[0].value)!)
                                }
                                else {
                                    self.nvramTextView.textStorage?.setAttributedString(NSAttributedString(string: ""))
                                    self.nvramTextView.string = self.nvram[0].value
                                }
                            }
                        }
                    })
                }
                self.taskOutPut(task)
                task.launch()
                task.waitUntilExit()
            }
        }
    }
    
    func taskOutPut(_ task: Process) {
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading , queue: nil) { notification in
            let output = outputPipe.fileHandleForReading.availableData
            if output.count > 0 {
                outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
                let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
                DispatchQueue.main.async(execute: {
                    let previousOutput = self.nvramInfo
                    let nextOutput = previousOutput + outputString
                    self.nvramInfo = nextOutput
                })
            }
        }
    }
    
    @objc func tableViewClick(_ sender:AnyObject) {
        if nvramTableView.selectedRow != -1 {
            if nvram[nvramTableView.selectedRow].value.contains("<array>") {
                nvramTextView.textStorage?.setAttributedString(prettyFormat(xmlString: nvram[nvramTableView.selectedRow].value)!)
            }
            else {
                nvramTextView.textStorage?.setAttributedString(NSAttributedString(string: ""))
                nvramTextView.string = nvram[nvramTableView.selectedRow].value
            }
        }
    }

}

extension NvramObject: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return keysArr.count
    }
    
}

extension NvramObject: NSTableViewDelegate {
    
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
            case "key":
                let textField = NSTextField()
                textField.cell = VerticallyCenteredTextFieldCell()
                textField.stringValue = self.nvram[row].key
                textField.alignment = .left
                textField.isBordered = false
                return textField
            case "value":
                let textField = NSTextField()
                textField.cell = VerticallyCenteredTextFieldCell()
                textField.stringValue = self.nvram[row].value
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
