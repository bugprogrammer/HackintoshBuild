//
//  ViewControllerOS.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2020/4/2.
//  Copyright © 2020 bugprogrammer. All rights reserved.
//

import Cocoa

class OSObject: OutBaseObject {

    @IBOutlet weak var popCatalogs: NSPopUpButton!
    @IBOutlet weak var downloadPath: NSPathControl!
    @IBOutlet weak var HighSierraButton: NSButton!
    @IBOutlet weak var MojaveButton: NSButton!
    @IBOutlet weak var CatalinaButton: NSButton!
    @IBOutlet weak var tableview: NSTableView!
    @IBOutlet var textview: NSTextView!
    @IBOutlet weak var bar: NSProgressIndicator!
    
    let catalogsArr: [String] = ["Developer", "Beta", "Public"]
    let catalogsDict: NSDictionary = ["Developer": "https://swscan.apple.com/content/catalogs/others/index-10.15seed-10.15-10.14-10.13-10.12-10.11-10.10-10.9-mountainlion-lion-snowleopard-leopard.merged-1.sucatalog", "Beta": "https://swscan.apple.com/content/catalogs/others/index-10.15beta-10.15-10.14-10.13-10.12-10.11-10.10-10.9-mountainlion-lion-snowleopard-leopard.merged-1.sucatalog", "Public": "https://swscan.apple.com/content/catalogs/others/index-10.15-10.14-10.13-10.12-10.11-10.10-10.9-mountainlion-lion-snowleopard-leopard.merged-1.sucatalog"]
    let filemanager = FileManager.default
    let taskQueue = DispatchQueue.global(qos: .default)
    let alert = NSAlert()
    var downloadLocation: String = ""
    var output: String = ""
    var selectVersion: String = ""
    var productsArr: [String] = []
    var distsArr: [String] = []
    var distsStr: String = ""
    var versionArr: [String] = []
    var versionDict: NSMutableDictionary = [:]
    var selectVersionList: [String] = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        HighSierraButton.isBordered = false
        HighSierraButton.bezelStyle = .recessed
        HighSierraButton.image = MyAsset.highsierra.image
        HighSierraButton.frame.size = CGSize(width: 100.0, height: 100.0)
        
        MojaveButton.isBordered = false
        MojaveButton.bezelStyle = .recessed
        MojaveButton.image = MyAsset.mojave.image
        MojaveButton.frame.size = CGSize(width: 100.0, height: 100.0)
        
        CatalinaButton.isBordered = false
        CatalinaButton.bezelStyle = .recessed
        CatalinaButton.image = MyAsset.catalina.image
        CatalinaButton.frame.size = CGSize(width: 100.0, height: 100.0)
        
        HighSierraButton.isEnabled = false
        MojaveButton.isEnabled = false
        CatalinaButton.isEnabled = false
        tableview.isEnabled = false
        
        bar.isHidden = true
        
        HighSierraButton.target = self
        HighSierraButton.action = #selector(downloadHighSierra)
        MojaveButton.target = self
        MojaveButton.action = #selector(downloadMojave)
        CatalinaButton.target = self
        CatalinaButton.action = #selector(downloadCatalina)
        
        popCatalogs.addItems(withTitles: catalogsArr)
        tableview.target = self
        tableview.doubleAction = #selector(tableViewDoubleClick)
        
        if let downloadURL = UserDefaults.standard.url(forKey: "OSLocation") {
            if filemanager.fileExists(atPath: downloadURL.path) {
                self.downloadPath.url = downloadURL
                downloadLocation = downloadURL.path
                HighSierraButton.isEnabled = true
                MojaveButton.isEnabled = true
                CatalinaButton.isEnabled = true
                tableview.isEnabled = true
                UserDefaults.standard.set(downloadLocation, forKey: "OStmp")
            }
        }
    }
    
    func setStatus(_ isRunning: Bool) {
        if isRunning {
            popCatalogs.isEnabled = false
            downloadPath.isEnabled = false
            HighSierraButton.isEnabled = false
            MojaveButton.isEnabled = false
            CatalinaButton.isEnabled = false
            tableview.isEnabled = false
            bar.isHidden = false
            bar.startAnimation(self)
        }
        else {
            popCatalogs.isEnabled = true
            downloadPath.isEnabled = true
            HighSierraButton.isEnabled = true
            MojaveButton.isEnabled = true
            CatalinaButton.isEnabled = true
            tableview.isEnabled = true
            bar.isHidden = true
            bar.stopAnimation(self)
        }
    }
    
    @IBAction func path(_ sender: Any) {
        if let url = downloadPath.url {
            downloadLocation = url.path
            HighSierraButton.isEnabled = true
            MojaveButton.isEnabled = true
            CatalinaButton.isEnabled = true
            tableview.isEnabled = true
            UserDefaults.standard.set(url, forKey: "OSLocation")
            UserDefaults.standard.set(downloadLocation, forKey: "OStmp")
        }
    }
    
    func getProductOS() {
        productsArr = []
        distsArr = []
        distsStr = ""
        let dict = NSMutableDictionary(contentsOfFile: downloadLocation + "/macOSInstaller/catalogs/catalogs.plist")
        MyLog(downloadLocation + "/macOSInstaller/catalogs/catalogs.plist")
        let Products = dict!["Products"] as! NSDictionary
        for key in Products.allKeys {
            let keyDict = Products[key] as! NSDictionary
            if keyDict.allKeys.contains(where: {$0 as! String == "ExtendedMetaInfo"}) && keyDict.allKeys.contains(where: {$0 as! String == "Distributions"}) && keyDict.allKeys.contains(where: {$0 as! String == "ServerMetadataURL"}) {
                let Distributions = keyDict["Distributions"] as! NSDictionary
                let ExtendedMetaInfo = keyDict["ExtendedMetaInfo"] as! NSDictionary
                if ExtendedMetaInfo.allKeys.contains(where: {$0 as! String == "InstallAssistantPackageIdentifiers"}) {
                    let InstallAssistantPackageIdentifiers = ExtendedMetaInfo["InstallAssistantPackageIdentifiers"] as! NSDictionary
                    if InstallAssistantPackageIdentifiers.allKeys.contains(where: {$0 as! String == "OSInstall"}) && InstallAssistantPackageIdentifiers["OSInstall"] as! String == "com.apple.mpkg.OSInstall" && Distributions.allKeys.contains(where: {$0 as! String == "zh_CN"}) {
                        let ServerMetadataURL: String = keyDict["ServerMetadataURL"] as! String
                        productsArr.append(ServerMetadataURL.replacingOccurrences(of: "/InstallAssistantAuto.smd", with: ""))
                        distsArr.append(Distributions["zh_CN"] as! String)
                    }
                }
            }
        }
    }
    
    func downloadCatalogs() {
        if filemanager.isWritableFile(atPath: downloadLocation) {
            setStatus(true)
            textview.string = ""
            selectVersionList = []
            tableview.reloadData()
            var arguments: [String] = []
            arguments.append(downloadLocation)
            arguments.append(catalogsDict[catalogsArr[popCatalogs.indexOfSelectedItem]] as! String)
            runBuildScripts("downloadCatalogs", arguments)
        }
        else {
            alert.messageText = "所选下载目录不可写"
            alert.runModal()
        }
    }
    
    func arrtoDict(_ keyArr: [String], _ valueArr: [String]) -> NSMutableDictionary {
        let dict: NSMutableDictionary = [:]
        for i in 0..<keyArr.count {
            dict[keyArr[i]] = valueArr[i]
        }
        return dict
    }
    
    @objc func downloadHighSierra() {
        selectVersion = "10.13"
        downloadCatalogs()
    }
    
    @objc func downloadMojave() {
        selectVersion = "10.14"
        downloadCatalogs()
    }
    
    @objc func downloadCatalina() {
        selectVersion = "10.15"
        downloadCatalogs()
    }
    
    @objc func tableViewDoubleClick() {
        if filemanager.isWritableFile(atPath: downloadLocation) {
            if tableview.selectedRow != -1 {
                setStatus(true)
                textview.string = ""
                var arguments: [String] = []
                arguments.append(downloadLocation)
                arguments.append(versionDict[selectVersionList[tableview.selectedRow]] as! String)
                runBuildScripts("downloadInstaller", arguments)
            }
        }
        else {
            alert.messageText = "所选下载目录不可写"
            alert.runModal()
        }
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
                        if shell == "downloadCatalogs" {
                            self.getProductOS()
                            //MyLog(self.productsArr)
                            //MyLog(self.distsArr)
                            for dist in self.distsArr {
                                self.distsStr.append(dist)
                                if dist != self.distsArr.last {
                                    self.distsStr.append(",")
                                }
                            }
                            //MyLog(self.distsStr)
                            self.runBuildScripts("versionInfo", [self.distsStr])
                        }
                        if shell == "versionInfo" {
                            //MyLog(self.output)
                            self.versionArr = self.output.components(separatedBy: "\n")
                            if self.versionArr.first == "" {
                                self.versionArr.removeFirst()
                            }
                            if self.versionArr.last == "" {
                                self.versionArr.removeLast()
                            }
                            self.versionDict = self.arrtoDict(self.versionArr, self.productsArr)
                            for version in self.versionDict.allKeys as! [String] {
                                if version.contains(self.selectVersion) {
                                    self.selectVersionList.append(version)
                                }
                            }
                            self.tableview.reloadData()
                            self.setStatus(false)
                        }
                        if shell == "downloadInstaller" {
                            self.runBuildScripts("makeInstaller", [self.downloadLocation])
                        }
                        if shell == "makeInstaller" {
                            self.setStatus(false)
                        }
                    })
                }
                self.taskOutPut(task, shell)
                task.launch()
                task.waitUntilExit()
            }
        }
    }
    
    func taskOutPut(_ task:Process, _ shell: String) {
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
                    if shell != "downloadInstaller" && shell != "makeInstaller" {
                        let previousOutput = self.output
                        let nextOutput = previousOutput + outputString
                        self.output = nextOutput
                    }
                    else {
                        let previousOutput = self.textview.string
                        let nextOutput = previousOutput + outputString
                        self.textview.string = nextOutput
                    }
                })
            }
        }
    }
}

extension OSObject: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return selectVersionList.count
    }
}

extension OSObject: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, shouldTrackCell cell: NSCell, for tableColumn: NSTableColumn?, row: Int) -> Bool {
        return true
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if tableColumn != nil {
            let identifier = tableColumn!.identifier.rawValue
            switch identifier {
            case "version":
                let textField = NSTextField()
                textField.cell = VerticallyCenteredTextFieldCell()
                textField.stringValue = self.selectVersionList[row]
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

