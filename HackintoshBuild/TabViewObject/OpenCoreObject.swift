//
//  ViewControllerOpenCore.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2020/5/5.
//  Copyright © 2020 bugprogrammer. All rights reserved.
//

import Cocoa
import Highlightr
import SwiftyMarkdown
import Alamofire

class OpenCoreObject: InBaseObject {
    
    @IBOutlet var simpleText: NSTextView!
    @IBOutlet weak var configLabel: NSTextField!
    @IBOutlet var changeText: NSTextView!
    @IBOutlet weak var versionLabel: NSTextField!
    @IBOutlet weak var popList: NSPopUpButton!
    @IBOutlet weak var statusBar: NSProgressIndicator!
    @IBOutlet weak var exportButton: NSButton!
    @IBOutlet weak var exportURL: NSPathControl!
    
    var versionList: [String] = []
    var exportPath: String = ""
    let filemanager = FileManager.default
    var urlArr: [String] = []
    var nameArr: [String] = []
    var check: Int = 0
    
    let queue : OperationQueue = {
        let que : OperationQueue = OperationQueue()
        que.maxConcurrentOperationCount = 1
        return que
    }()

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
        
        syncDatas()
    }
    
    func isRunning(_ status: Bool) {
        if status {
            popList.isEnabled = false
            exportURL.isEnabled = false
            statusBar.isHidden = false
            statusBar.startAnimation(nil)
            exportButton.isEnabled = false
        } else {
            popList.isEnabled = true
            exportURL.isEnabled = true
            statusBar.isHidden = true
            statusBar.stopAnimation(nil)
            exportButton.isEnabled = true
        }
    }
    
    func syncDatas() {
        isRunning(true)
        let headers: HTTPHeaders = [
            "Accept": "application/json"
        ]
        AF.request("https://api.github.com/repos/acidanthera/OpenCorePkg/tags", method: .get, headers: headers).validate().responseJSON { response in
            switch response.result {
                case .success(let dict):
                    for tags in dict as! [NSDictionary] {
                        let tag = tags["name"] as! String
                        self.versionList.append("OpenCore-" + tag)
                    }
                    self.popList.addItems(withTitles: self.versionList)
                    self.select(0)
                case .failure(_):
                    let alert = NSAlert()
                    alert.messageText = "网络错误，请检查 https://api.github.com 连通性"
                    alert.runModal()
                    self.isRunning(true)
                    self.statusBar.isHidden = true
                    self.statusBar.stopAnimation(nil)
                    
                    break
            }
        }
    }
    
    func downloads(_ url: [String], _ name: [String], _ num: Int) {
        var first: Bool = true
        MyLog("download")
        if filemanager.fileExists(atPath: Bundle.main.bundlePath + "/Contents/Resources/tmps") {
            try! filemanager.removeItem(atPath: Bundle.main.bundlePath + "/Contents/Resources/tmps")
            try! filemanager.createDirectory(atPath: Bundle.main.bundlePath + "/Contents/Resources/tmps", withIntermediateDirectories: true,
            attributes: nil)
        }
        
        for i in 0..<url.count {
            let semaphore = DispatchSemaphore(value: 0)
            let op : BlockOperation = BlockOperation { [weak self] in
                let destination: DownloadRequest.Destination = { _, _ in
                    let fileURL = URL(fileURLWithPath: Bundle.main.bundlePath + "/Contents/Resources/tmps/" + name[i])
                    
                    return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
                }

                AF.download(url[i], to: destination).responseData { [self] response in
                    debugPrint(response)
                    switch response.result {
                    case .success(_):
                        MyLog("OK")
                        self!.show(num)
                    case .failure(_):
                        if first {
                            first = false
                            let alert = NSAlert()
                            alert.messageText = "网络错误，请检查 https://raw.githubusercontent.com 连通性"
                            alert.runModal()
                            
                            self!.versionLabel.stringValue = self!.versionList[num] + " 修改日志"
                            self!.configLabel.stringValue = self!.versionList[num] + " 配置模版"
                            
                            self!.simpleText.textColor = NSColor.white
                            self!.changeText.string = "网络错误，下载失败"
                            self!.simpleText.string = "网络错误，下载失败"
                            
                            self!.isRunning(true)
                            self!.statusBar.isHidden = true
                            self!.statusBar.stopAnimation(nil)
                            self!.popList.isEnabled = true
                            
                            
                            break
                        }
                    }
                    semaphore.signal()
                }
                semaphore.wait()
            }
            queue.addOperation(op)
        }
    }
    
    func prettyFormat(xmlString: String) -> NSAttributedString? {
        let highlightr = Highlightr()
        highlightr!.setTheme(to: "paraiso-dark")
        let highlightedCode = highlightr!.highlight(xmlString, as: "xml")
        return highlightedCode
    }
    
    func cutChangeLogs(_ changelog: String) -> String {
        let cutArr = changelog.components(separatedBy: "####")

        return cutArr[0] + "####" + cutArr[1]
    }
        
    @IBAction func selectVersion(_ sender: Any) {
        if popList.indexOfSelectedItem != check || changeText.string.contains("网络错误") {
            select(popList.indexOfSelectedItem)
            check = popList.indexOfSelectedItem
        }
    }
    
    func select(_ num: Int) {
        isRunning(true)
        urlArr = []
        nameArr = []
        urlArr.append("https://raw.githubusercontent.com/acidanthera/OpenCorePkg/" + self.versionList[num].replacingOccurrences(of: "OpenCore-", with: "") + "/Docs/Sample.plist")
        urlArr.append("https://raw.githubusercontent.com/acidanthera/OpenCorePkg/" + self.versionList[num].replacingOccurrences(of: "OpenCore-", with: "") + "/Changelog.md")
        nameArr.append("Sample-" + self.versionList[num].replacingOccurrences(of: "OpenCore-", with: "") + ".plist")
        nameArr.append("Changelog-" + self.versionList[num].replacingOccurrences(of: "OpenCore-", with: "") + ".md")
        downloads(urlArr, nameArr, num)
    }
    
    func show(_ num: Int) {
        self.versionLabel.stringValue = self.versionList[num] + " 修改日志"
        self.configLabel.stringValue = self.versionList[num] + " 配置模版"
        let url = Bundle.main.bundlePath + "/Contents/Resources/tmps"
        let version = versionList[num].replacingOccurrences(of: "OpenCore-", with: "")
        do {
            let changeLog = try String(contentsOfFile: url + "/Changelog-" + version + ".md", encoding: String.Encoding.utf8)
            self.changeText.textStorage?.setAttributedString(SwiftyMarkdown(string: cutChangeLogs(changeLog)).attributedString())
            let simpleConfig = try String(contentsOfFile: url + "/Sample-" + version + ".plist", encoding: String.Encoding.utf8)

            self.simpleText.textStorage?.setAttributedString(self.prettyFormat(xmlString: simpleConfig.replacingOccurrences(of: "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n", with: "").replacingOccurrences(of: "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n", with: "").replacingOccurrences(of: "<plist version=\"1.0\">\n", with: ""))!)
        } catch {
            MyLog("Failed")
        }
        isRunning(false)
    }
        
    @IBAction func selectLocation(_ sender: Any) {
        if let url = exportURL.url {
            exportPath = url.path
            exportButton.isEnabled = true
            UserDefaults.standard.set(url, forKey: "exportURL")
        }
    }
    
    @objc func exportSimple() {
        let url = Bundle.main.bundlePath + "/Contents/Resources/tmps"
        let version = versionList[popList.indexOfSelectedItem].replacingOccurrences(of: "OpenCore-", with: "")
        let atUrl = url + "/Sample-" + version + ".plist"
        var toUrl = exportPath + "/" + versionList[popList.indexOfSelectedItem] + "-Sample.plist"
        if filemanager.isWritableFile(atPath: exportPath) {
            if filemanager.fileExists(atPath: toUrl) {
                toUrl = toUrl.replacingOccurrences(of: "-Sample.plist", with: "-Sample-" + Date().milliStamp + ".plist" )
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
