//
//  ViewControllerOpenCore.swift
//  HackintoshBuild
//
//  Created by wbx on 2020/5/5.
//  Copyright © 2020 bugprogrammer. All rights reserved.
//

import Cocoa
import Highlightr
import SwiftyMarkdown

class OpenCoreObject: InBaseObject {
    
    @IBOutlet var simpleText: NSTextView!
    @IBOutlet weak var configLabel: NSTextField!
    @IBOutlet var changeText: NSTextView!
    @IBOutlet weak var versionLabel: NSTextField!
    @IBOutlet weak var popList: NSPopUpButton!
    @IBOutlet weak var statusBar: NSProgressIndicator!
    @IBOutlet weak var exportButton: NSButton!
    @IBOutlet weak var exportURL: NSPathControl!
    
    let location = Bundle.main.path(forResource: "getEFI", ofType: "command")?.replacingOccurrences(of: "/getEFI.command", with: "")
    let taskQueue = DispatchQueue.global(qos: .default)
    var output: String = ""
    var versionList: [String] = []
    var exportPath: String = ""
    let filemanager = FileManager.default

    override func awakeFromNib() {
        super.awakeFromNib()
        
        statusBar.isHidden = true
        versionLabel.stringValue = "加载中……"
        configLabel.stringValue = "加载中……"
        exportButton.isEnabled = false
        let exportImg = MyAsset.export.image
        exportImg.isTemplate = true
        exportButton.image = exportImg
        exportButton.bezelStyle = .recessed
        exportButton.isBordered = false
        exportButton.toolTip = "导出 SimpleFull.plst"
        exportButton.target = self
        exportButton.action = #selector(exportSimple)
        
        if let exportURL = UserDefaults.standard.url(forKey: "exportURL") {
            if filemanager.fileExists(atPath: exportURL.path) {
                self.exportURL.url = exportURL
                exportPath = exportURL.path
                exportButton.isEnabled = true
            }
        }
    }
    
    override func willAppear(_ noti: Notification) {
        super.willAppear(noti)
        
        let index = noti.object as! Int
        if index != 6 { return }
        if !once { return }
        once = false
        
        runBuildScripts("syncDatas", [location!])
    }
    
    func runBuildScripts(_ shell: String,_ arguments: [String]) {
        self.statusBar.isHidden = false
        self.statusBar.startAnimation(self)
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
                        self.versionList = self.output.components(separatedBy: "\n")
                        if self.versionList.first == "" {
                            self.versionList.removeFirst()
                        }
                        if self.versionList.last == "" {
                            self.versionList.removeLast()
                        }
                        for i in 0..<self.versionList.count {
                            self.versionList[i] = "OpenCore-" + self.versionList[i]
                        }
                        MyLog(self.versionList)
                        self.popList.addItems(withTitles: self.versionList)
                        self.select(0)
                        self.statusBar.isHidden = true
                        self.statusBar.stopAnimation(self)
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
    
    func prettyFormat(xmlString: String) -> NSAttributedString? {
        let highlightr = Highlightr()
        highlightr!.setTheme(to: "paraiso-dark")
        let highlightedCode = highlightr!.highlight(xmlString, as: "xml")
        return highlightedCode
    }
        
    @IBAction func selectVersion(_ sender: Any) {
        select(popList.indexOfSelectedItem)
    }
    
    func select(_ num: Int) {
        self.versionLabel.stringValue = self.versionList[num] + " 修改日志"
        self.configLabel.stringValue = self.versionList[num] + " 配置模版"
        let url = self.location! + "/OpenCoreVersions/" + self.versionList[num].replacingOccurrences(of: "OpenCore-", with: "")
        do {
            let changeLog = try String(contentsOfFile: url + "/Changelog.md", encoding: String.Encoding.utf8)
            self.changeText.textStorage?.setAttributedString(SwiftyMarkdown(string: changeLog).attributedString())
            let simpleConfig = try String(contentsOfFile: url + "/SampleFull.plist", encoding: String.Encoding.utf8)
            self.simpleText.textStorage?.setAttributedString(self.prettyFormat(xmlString: simpleConfig.replacingOccurrences(of: "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n", with: "").replacingOccurrences(of: "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n", with: "").replacingOccurrences(of: "<plist version=\"1.0\">\n", with: ""))!)
        } catch {
            MyLog("Failed")
        }
    }
        
    @IBAction func selectLocation(_ sender: Any) {
        if let url = exportURL.url {
            exportPath = url.path
            exportButton.isEnabled = true
            UserDefaults.standard.set(url, forKey: "exportURL")
        }
    }
    
    @objc func exportSimple() {
        let atUrl = location! + "/OpenCoreVersions/" + versionList[popList.indexOfSelectedItem].replacingOccurrences(of: "OpenCore-", with: "") + "/SampleFull.plist"
        var toUrl = exportPath + "/" + versionList[popList.indexOfSelectedItem] + "-SimpleFull.plist"
        if filemanager.isWritableFile(atPath: exportPath) {
            if filemanager.fileExists(atPath: toUrl) {
                toUrl = toUrl.replacingOccurrences(of: "-SimpleFull.plist", with: "-SimpleFull-" + Date().milliStamp + ".plist" )
                try! filemanager.copyItem(atPath: atUrl, toPath: toUrl)
            }
            else {
                try! filemanager.copyItem(atPath: atUrl, toPath: toUrl)
            }
            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: toUrl)])
        }
        else {
            let alert = NSAlert()
            alert.messageText = "所选路径不可写"
            alert.runModal()
        }
    }
    
}
