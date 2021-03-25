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
    
    func syncDatas() {
        statusBar.isHidden = false
        statusBar.startAnimation(self)
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
                    for item in self.versionList {
                        self.downloads("https://raw.githubusercontent.com/acidanthera/OpenCorePkg/" + item.replacingOccurrences(of: "OpenCore-", with: "") + "/Docs/Sample.plist", "Simple-" + item.replacingOccurrences(of: "OpenCore-", with: "") + ".plist")
                        self.downloads("https://raw.githubusercontent.com/acidanthera/OpenCorePkg/" + item.replacingOccurrences(of: "OpenCore-", with: "") + "/Changelog.md", "Changelog-" + item.replacingOccurrences(of: "OpenCore-", with: "") + ".md")
                    }
                    self.statusBar.isHidden = true
                    self.statusBar.stopAnimation(self)
                case .failure(_):
                    MyLog("bugs!!!!")
            }
        }
    }
    
    func downloads(_ url: String, _ name: String) {
        if !filemanager.fileExists(atPath: Bundle.main.bundlePath + "/Contents/Resources/tmps") {
            try! filemanager.createDirectory(atPath: Bundle.main.bundlePath + "/Contents/Resources/tmps", withIntermediateDirectories: true,
            attributes: nil)
        } else {
            if !filemanager.fileExists(atPath: Bundle.main.bundlePath + "/Contents/Resources/tmps/" + name) {
                let destination: DownloadRequest.Destination = { _, _ in
                    let fileURL = URL(fileURLWithPath: Bundle.main.bundlePath + "/Contents/Resources/tmps/" + name)
                    
                    return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
                }

                AF.download(url, to: destination).responseData { response in
                    debugPrint(response)
                    switch response.result {
                    case .success(_):
                        MyLog("OK")
                    case .failure(_):
                        break
                    }
                }
            }
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
        select(popList.indexOfSelectedItem)
    }
    
    func select(_ num: Int) {
        self.versionLabel.stringValue = self.versionList[num] + " 修改日志"
        self.configLabel.stringValue = self.versionList[num] + " 配置模版"
        let url = Bundle.main.bundlePath + "/Contents/Resources/tmps"
        let version = versionList[num].replacingOccurrences(of: "OpenCore-", with: "")
        do {
            let changeLog = try String(contentsOfFile: url + "/Changelog-" + version + ".md", encoding: String.Encoding.utf8)
            self.changeText.textStorage?.setAttributedString(SwiftyMarkdown(string: cutChangeLogs(changeLog)).attributedString())
            let simpleConfig = try String(contentsOfFile: url + "/Simple-" + version + ".plist", encoding: String.Encoding.utf8)
            
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
        let url = Bundle.main.bundlePath + "/Contents/Resources/tmps"
        let version = versionList[popList.indexOfSelectedItem].replacingOccurrences(of: "OpenCore-", with: "")
        let atUrl = url + "/Simple-" + version + ".plist"
        var toUrl = exportPath + "/" + versionList[popList.indexOfSelectedItem] + "-Simple.plist"
        if filemanager.isWritableFile(atPath: exportPath) {
            if filemanager.fileExists(atPath: toUrl) {
                toUrl = toUrl.replacingOccurrences(of: "-Simple.plist", with: "-Simple-" + Date().milliStamp + ".plist" )
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
