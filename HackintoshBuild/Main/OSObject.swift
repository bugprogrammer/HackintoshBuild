//
//  ViewControllerOS.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2020/4/2.
//  Copyright © 2020 bugprogrammer. All rights reserved.
//

import Cocoa
import Alamofire

class OSObject: OutBaseObject {

    @IBOutlet weak var popCatalogs: NSPopUpButton!
    @IBOutlet weak var downloadPath: NSPathControl!
    @IBOutlet weak var versionTableView: NSTableView!
    @IBOutlet weak var bar: NSProgressIndicator!
    @IBOutlet weak var popVersion: NSPopUpButton!
    @IBOutlet weak var downloadTableView: NSTableView!
    
    var isDownloading: Bool = false
    var downloadProgress: Double = 0.0
    let catalogsArr: [String] = ["Developer", "Beta", "Public"]
    let catalogsDict: NSDictionary = ["Developer": "https://swscan.apple.com/content/catalogs/others/index-10.15seed-10.15-10.14-10.13-10.12-10.11-10.10-10.9-mountainlion-lion-snowleopard-leopard.merged-1.sucatalog", "Beta": "https://swscan.apple.com/content/catalogs/others/index-10.15beta-10.15-10.14-10.13-10.12-10.11-10.10-10.9-mountainlion-lion-snowleopard-leopard.merged-1.sucatalog", "Public": "https://swscan.apple.com/content/catalogs/others/index-10.15-10.14-10.13-10.12-10.11-10.10-10.9-mountainlion-lion-snowleopard-leopard.merged-1.sucatalog"]
    let versionPopList: [String] = ["macOS Monterey - 12.x", "macOS Big Sur - 11.x", "macOS Catalina - 10.15", "macOS Mojave - 10.14", "macOS High Sierra - 10.13"]
    let downloadStatus: [String] = ["正在下载AppleDiagnostics.dmg", "正在下载AppleDiagnostics.chunklist", "正在下载BaseSystem.dmg", "正在下载BaseSystem.chunklist", "正在下载InstallInfo.plist", "正在下载InstallESDDmg.pkg", "正在制作镜像"]
    let downloadStatusBS: [String] = ["正在下载InstallInfo.plist", "正在下载UpdateBrain.zip", "正在下载MajorOSInfo.pkg", "正在下载Info.plist", "正在下载InstallAssistant.pkg", "正在下载BuildManifest.plist", "正在制作镜像"]
    let filemanager = FileManager.default
    let taskQueue = DispatchQueue.global(qos: .default)
    let alert = NSAlert()
    var downloadLocation: String = ""
    var output: String = ""
    var selectedVersion: String = ""
    var productsArr: [String] = []
    var distsArr: [String] = []
    var distsStr: String = ""
    var versionArr: [String] = []
    var versionDict: NSMutableDictionary = [:]
    var selectVersionList: [String] = []
    
    let queue : OperationQueue = {
        let que : OperationQueue = OperationQueue()
        que.maxConcurrentOperationCount = 1
        return que
    }()
    
    override func willAppear(_ noti: Notification) {
        super.willAppear(noti)
        
        let index = noti.object as! Int
        if index != 7 { return }
        if !once { return }
        once = false
        selectVersion()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        popCatalogs.addItems(withTitles: catalogsArr)
        popVersion.addItems(withTitles: versionPopList)
        versionTableView.target = self
        versionTableView.doubleAction = #selector(tableViewDoubleClick)
        downloadTableView.isEnabled = false
        //popVersion.action = #selector(selectVersion)
        
        if let downloadURL = UserDefaults.standard.url(forKey: "OSLocation") {
            if filemanager.fileExists(atPath: downloadURL.path) {
                self.downloadPath.url = downloadURL
                downloadLocation = downloadURL.path
                versionTableView.isEnabled = true
                UserDefaults.standard.set(downloadLocation, forKey: "OStmp")
                //selectVersion()
            }
        }
    }
    
    func setStatus(_ isRunning: Bool) {
        if isRunning {
            popCatalogs.isEnabled = false
            popVersion.isEnabled = false
            downloadPath.isEnabled = false
            versionTableView.isEnabled = false
        }
        else {
            popCatalogs.isEnabled = true
            popVersion.isEnabled = true
            downloadPath.isEnabled = true
            versionTableView.isEnabled = true
        }
    }
    
    @IBAction func path(_ sender: Any) {
        if let url = downloadPath.url {
            downloadLocation = url.path
            versionTableView.isEnabled = true
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
            if keyDict.allKeys.contains(where: {$0 as! String == "ExtendedMetaInfo"}) && keyDict.allKeys.contains(where: {$0 as! String == "Distributions"}) {
                let Distributions = keyDict["Distributions"] as! NSDictionary
                let ExtendedMetaInfo = keyDict["ExtendedMetaInfo"] as! NSDictionary
                let Packages = keyDict["Packages"] as! [NSDictionary]
                let subPackages = Packages[0]
                if ExtendedMetaInfo.allKeys.contains(where: {$0 as! String == "InstallAssistantPackageIdentifiers"}) {
                    let InstallAssistantPackageIdentifiers = ExtendedMetaInfo["InstallAssistantPackageIdentifiers"] as! NSDictionary
                    if selectedVersion.components(separatedBy: ".").first == " 10" {
                        if InstallAssistantPackageIdentifiers.allKeys.contains(where: {$0 as! String == "OSInstall"}) && InstallAssistantPackageIdentifiers["OSInstall"] as! String == "com.apple.mpkg.OSInstall" {
                            let URL: String = subPackages["URL"] as! String
                            productsArr.append(URL)
                            if Distributions.allKeys.contains(where: {$0 as! String == "zh_CN"}) {
                                distsArr.append(Distributions["zh_CN"] as! String)
                            }
                            else {
                                distsArr.append(Distributions["English"] as! String)
                            }
                        }
                    } else {
                        if InstallAssistantPackageIdentifiers.allKeys.contains(where: {$0 as! String == "SharedSupport"}) {
                            let SharedSupport = InstallAssistantPackageIdentifiers["SharedSupport"] as! String
                            if SharedSupport.contains("macOS1016") || SharedSupport.contains("macOSBigSur") || SharedSupport.contains("macOS12") || SharedSupport.contains("macOSMonterey") {
                                let URL: String = subPackages["URL"] as! String
                                productsArr.append(URL)
                                MyLog(productsArr)
                                if Distributions.allKeys.contains(where: {$0 as! String == "zh_CN"}) {
                                    distsArr.append(Distributions["zh_CN"] as! String)
                                }
                                else {
                                    distsArr.append(Distributions["English"] as! String)
                                    MyLog(distsArr)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func downloadCatalogs() {
        if filemanager.isWritableFile(atPath: downloadLocation) {
            setStatus(true)
            bar.isHidden = false
            bar.startAnimation(self)
            selectVersionList = []
            versionTableView.reloadData()
            if filemanager.fileExists(atPath: downloadLocation + "/macOSInstaller/catalogs") {
                try! filemanager.removeItem(atPath: downloadLocation + "/macOSInstaller/catalogs")
            }
            try! filemanager.createDirectory(atPath: downloadLocation + "/macOSInstaller/catalogs", withIntermediateDirectories: true,
            attributes: nil)
            let destination: DownloadRequest.Destination = { _, _ in
                let fileURL = URL(fileURLWithPath: self.downloadLocation + "/macOSInstaller/catalogs/catalogs.plist")
                
                return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
            }

            AF.download(catalogsDict[catalogsArr[popCatalogs.indexOfSelectedItem]] as! String, to: destination).responseData { response in
                debugPrint(response)
                switch response.result {
                case .success(_):
                    self.getProductOS()
                    MyLog(self.productsArr)
                    MyLog(self.distsArr)
                    for dist in self.distsArr {
                        self.distsStr.append(dist)
                        if dist != self.distsArr.last {
                            self.distsStr.append(",")
                        }
                    }
                    MyLog(self.distsStr)
                    self.runBuildScripts("versionInfo", [self.distsStr])
                case .failure(_):
                    break
                }
            }
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
    
    @IBAction func selectCatalog(_ sender: Any) {
        isDownloading = false
        downloadTableView.reloadData()
        selectVersion()
    }
    
    @IBAction func selectVersionButton(_ sender: Any) {
        isDownloading = false
        downloadTableView.reloadData()
        selectVersion()
    }
    
    func selectVersion() {
        selectedVersion = versionPopList[popVersion.indexOfSelectedItem].components(separatedBy: "-").last!
        MyLog(selectedVersion)
        downloadCatalogs()
    }
    
    @objc func tableViewDoubleClick() {
        if filemanager.isWritableFile(atPath: downloadLocation) {
            if versionTableView.selectedRow != -1 {
                setStatus(true)
                if filemanager.fileExists(atPath: downloadLocation + "/macOSInstaller/installer") {
                    try! filemanager.removeItem(atPath: downloadLocation + "/macOSInstaller/installer")
                }
                try! filemanager.createDirectory(atPath: downloadLocation + "/macOSInstaller/installer", withIntermediateDirectories: true,
                attributes: nil)
                
                if selectedVersion.components(separatedBy: ".").first != " 10" {
                    downloadOS(["/InstallInfo.plist", "/UpdateBrain.zip", "/MajorOSInfo.pkg", "/Info.plist", "/InstallAssistant.pkg", "/BuildManifest.plist"])
                } else {
                    downloadOS(["/AppleDiagnostics.dmg", "/AppleDiagnostics.chunklist", "/BaseSystem.dmg", "/BaseSystem.chunklist", "/InstallInfo.plist", "/InstallESDDmg.pkg"])
                }
            }
        }
        else {
            alert.messageText = "所选下载目录不可写"
            alert.runModal()
        }
    }
    
    func downloadOS(_ list: [String]) {
        
        isDownloading = true
        var first: Bool = true
        let urlStr = versionDict[selectVersionList[versionTableView.selectedRow]] as! String
        var urlArr = urlStr.components(separatedBy: "/")
        urlArr.removeLast()
        let url = urlArr.joined(separator: "/")
        
        for i in 0..<list.count {
            let semaphore = DispatchSemaphore(value: 0)
            let op : BlockOperation = BlockOperation { [weak self] in
                let destination: DownloadRequest.Destination = { _, _ in
                    let fileURL = URL(fileURLWithPath: self!.downloadLocation + "/macOSInstaller/installer" + list[i])
                    
                    return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
                }

                AF.download(url + list[i], to: destination).downloadProgress { progress in
                    print("Download Progress: \(progress.fractionCompleted)")
                    self?.downloadProgress = progress.fractionCompleted
                    self!.downloadTableView.reloadData(forRowIndexes: [i], columnIndexes: [0,1])
                }.responseData { [self] response in
                    debugPrint(response)
                    switch response.result {
                    case .success(_):
                        self?.downloadProgress = 1
                        self!.downloadTableView.reloadData(forRowIndexes: [i], columnIndexes: [0,1])
                        if i == list.count - 1 {
                            self?.downloadProgress = 0.0
                            self?.downloadTableView.reloadData(forRowIndexes: [list.count], columnIndexes: [0,1])
                            if self!.selectedVersion.components(separatedBy: ".").first == " 10" {
                                self!.runBuildScripts("makeInstaller", [self!.downloadLocation])
                            } else {
                                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: self!.downloadLocation + "/macOSInstaller/installer/InstallAssistant.pkg")
                                self?.setStatus(false)
                                self?.downloadProgress = 1.0
                                self!.downloadTableView.reloadData(forRowIndexes: [self!.downloadStatus.count - 1], columnIndexes: [0,1])
                            }
                        }
                    case .failure(_):
                        if first {
                            self!.alert.messageText = "下载失败，请重试"
                            self!.alert.runModal()
                            first = false
                            self!.isDownloading = false
                            self!.downloadTableView.reloadData()
                            self!.setStatus(false)
                        }
                    }
                    semaphore.signal()
                }
                semaphore.wait()
            }
            
            queue.addOperation(op)
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
                        if shell == "versionInfo" {
                            MyLog(self.output)
                            self.versionArr = self.output.components(separatedBy: "\n")
                            if self.versionArr.first == "" {
                                self.versionArr.removeFirst()
                            }
                            if self.versionArr.last == "" {
                                self.versionArr.removeLast()
                            }
                            self.versionDict = self.arrtoDict(self.versionArr, self.productsArr)
                            for version in self.versionDict.allKeys as! [String] {
                                MyLog(version)
                                if self.selectedVersion.components(separatedBy: ".").first == " 10" {
                                    if version.contains(self.selectedVersion) {
                                        self.selectVersionList.append(version)
                                    }
                                } else {
                                    if version.contains(self.selectedVersion.components(separatedBy: ".").first!) {
                                        self.selectVersionList.append(version)
                                    }
                                }
                            }
                            MyLog(self.selectVersionList)
                            self.versionTableView.reloadData()
                            self.setStatus(false)
                            self.bar.isHidden = true
                            self.bar.stopAnimation(self)
                        }
                        if shell == "makeInstaller" {
                            if self.output.contains("failed") {
                                self.setStatus(false)
                                self.alert.messageText = "下载不完整，镜像制作失败"
                                self.alert.runModal()
                                self.isDownloading = false
                                self.downloadTableView.reloadData()
                            } else {
                                self.setStatus(false)
                                self.downloadProgress = 1.0
                                self.downloadTableView.reloadData(forRowIndexes: [self.downloadStatus.count - 1], columnIndexes: [0,1])
                                self.alert.messageText = "制作镜像完成,位于应用程序下"
                                self.alert.runModal()
                            }
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
                    let previousOutput = self.output
                    let nextOutput = previousOutput + outputString
                    self.output = nextOutput
                })
            }
        }
    }
}

extension OSObject: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        var count: Int = 0
        if tableView == versionTableView {
            count = selectVersionList.count
        } else if tableView == downloadTableView {
            if selectedVersion.components(separatedBy: ".").first != " 10" {
                count = downloadStatusBS.count
            } else {
                count = downloadStatus.count
            }
        }
        return count
    }
}

extension OSObject: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, shouldTrackCell cell: NSCell, for tableColumn: NSTableColumn?, row: Int) -> Bool {
        return true
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableView == versionTableView {
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
        } else if tableView == downloadTableView && isDownloading {
            if tableColumn != nil {
                let identifier = tableColumn!.identifier.rawValue
                switch identifier {
                case "downloading":
                    let textField = NSTextField()
                    textField.cell = VerticallyCenteredTextFieldCell()
                    if selectedVersion.components(separatedBy: ".").first != " 10" {
                        textField.stringValue = self.downloadStatusBS[row]
                    } else {
                        textField.stringValue = self.downloadStatus[row]
                    }
                    textField.alignment = .left
                    textField.isBordered = false

                    return textField
                case "status":
                    var view = NSView()
                    
                    if downloadProgress < 1 {
                        let progress = NSProgressIndicator()
                        progress.style = .spinning
                        progress.controlSize = NSControl.ControlSize(rawValue: 5)!
                        progress.sizeToFit()
                        progress.isHidden = false
                        if downloadStatus[row] == "正在制作镜像" {
                            progress.isIndeterminate = true
                            progress.startAnimation(self)
                        } else {
                            progress.isIndeterminate = false
                            progress.minValue = 0
                            progress.maxValue = 1
                            progress.doubleValue = downloadProgress
                        }
                        
                        view = progress
                    } else {
                        let button = NSButton()
                        button.image = MyAsset.complate.image
                        button.bezelStyle = .recessed
                        button.isBordered = false
                        
                        view = button
                    }
                    
                    return view
                default:
                    return nil
                }
            }
            return nil
        }
        return nil
    }
}

