//
//  AppleSiliconObject.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2020/12/3.
//  Copyright © 2020 bugprogrammer. All rights reserved.
//

import Cocoa

class AppleSiliconObject: InBaseObject {
    
    class Applications {
        var icon: NSImage
        var name: String
        var arch: String
        var version: String
        var path: String
        
        init(icon: NSImage, name: String, arch: String, version: String, path: String) {
            self.icon = icon
            self.name = name
            self.arch = arch
            self.version = version
            self.path = path
        }
    }
    
    @IBOutlet weak var dragView: DragDropView!
    @IBOutlet weak var tableview: NSTableView!
    
    var applications: [Applications] = []
    var searchAppList: [Applications] = []
    var dragPath: String = ""
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        appleSilicon("/Applications/")
    }
    
    override func willAppear(_ noti: Notification) {
        super.willAppear(noti)
        
        let index = noti.object as! Int
        if index != 7 { return }
        if !once { return }
        once = false
        //appleSilicon("/Applications/")
        dragView.backgroundColor = NSColor(named: "ColorGray")
        dragView.usedArrowImage = false
        dragView.acceptedFileExtensions = ["app"]
        dragView.setup({ [self] (file) in
            var isDir = ObjCBool( booleanLiteral: false )
            var arch: String = ""
            let fileManager = FileManager.default
            self.dragPath = file.absoluteString.urlDecoded().replacingOccurrences(of: "file://", with: "")
            MyLog(self.dragPath)
            if fileManager.fileExists(atPath: self.dragPath + "Wrapper/iTunesMetadata.plist") {
                arch = "IOS"
            } else if fileManager.fileExists(atPath: self.dragPath + "Contents/Info.plist") {
                let execs = try? fileManager.contentsOfDirectory(atPath: self.dragPath + "Contents/MacOS")
                for exec in execs! {
                    if fileManager.fileExists(atPath: self.dragPath + "Contents/MacOS/" + exec, isDirectory: &isDir) {
                        if !isDir.boolValue && URL(fileURLWithPath: self.dragPath + "Contents/MacOS/" + exec).pathExtension == "" {
                            arch = archs(self.dragPath + "Contents/MacOS/" + exec)
                            if arch != "未知" {
                                break
                            }
                        }
                    }
                }
            }
            let alert = NSAlert()
            alert.messageText = "该程序为" + arch + "程序"
            alert.runModal()
            
        }) { (files) in
            let alert = NSAlert()
            alert.messageText = "只支持拖入一个文件"
            alert.runModal()
        }
    }
    
    func appleSilicon(_ url: String) {
        var arch: String = ""
        var version: String = ""
        var isDir = ObjCBool( booleanLiteral: false )
        var list: NSMutableDictionary = [:]
        let fileManager = FileManager.default
        let apps = try? fileManager.contentsOfDirectory(atPath: url)
        for app in apps! {
            //macOS程序
            if app.components(separatedBy: ".").last == "app" && fileManager.fileExists(atPath: url + app + "/Contents/Info.plist") {
                list = NSMutableDictionary(contentsOfFile: url + app + "/Contents/Info.plist")!
                if list["CFBundleShortVersionString"] != nil {
                    version = list["CFBundleShortVersionString"] as! String
                }
                //arch
                let execs = try? fileManager.contentsOfDirectory(atPath: url + app + "/Contents/MacOS")
                for exec in execs! {
                    if fileManager.fileExists(atPath: url + app + "/Contents/MacOS/" + exec, isDirectory: &isDir) {
                        if !isDir.boolValue && URL(fileURLWithPath: url + app + "/Contents/MacOS/" + exec).pathExtension == "" {
                            arch = archs(url + app + "/Contents/MacOS/" + exec)
                            if arch != "未知" {
                                break
                            }
                        }
                    }
                }                
                self.applications.append(Applications(icon: NSWorkspace.shared.icon(forFile: url + app),  name: fileManager.displayName(atPath: url + app), arch: arch, version: version, path: url + app))
            }
            //IOS程序
            if app.components(separatedBy: ".").last == "app" && fileManager.fileExists(atPath: url + app + "/Wrapper/iTunesMetadata.plist") {
                list = NSMutableDictionary(contentsOfFile: url + app + "/Wrapper/iTunesMetadata.plist")!
                if list["bundleShortVersionString"] != nil {
                    version = list["bundleShortVersionString"] as! String
                }
                self.applications.append(Applications(icon: NSWorkspace.shared.icon(forFile: url + app), name: fileManager.displayName(atPath: url + app), arch: "IOS", version: version, path: url + app))
            }
        }
        searchAppList = applications
        tableview.reloadData()
    }
    
    func archs(_ path: String) -> String {
        var arch: String = ""
        let task = Process()
        let outputPipe = Pipe()

        task.launchPath = "/usr/bin/lipo"
        task.arguments = ["-archs", path]
        task.standardOutput = outputPipe
        task.launch()
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()

        let output = NSString(data: outputData, encoding: String.Encoding.utf8.rawValue)! as String
        if output.components(separatedBy: "\n").first == "x86_64 arm64" || output.components(separatedBy: "\n").first == "x86_64 arm64e" {
            arch = "通用"
        } else if output.components(separatedBy: "\n").first == "x86_64" {
            arch = "Intel"
        } else if output.components(separatedBy: "\n").first == "arm64" || output.components(separatedBy: "\n").first == "arm64e" {
            arch = "仅Apple芯片"
        } else {
            arch = "未知"
        }
        return arch
    }
    
    @objc func openURL(_ sender: NSButton) {
        let index = tableview.row(for: sender)
        NSWorkspace.shared.selectFile(applications[index].path, inFileViewerRootedAtPath: "/")
    }
        
    @IBAction func search(_ sender: NSSearchField) {
        applications = searchAppList
        if sender.stringValue != "" {
            applications = applications.filter {$0.name.lowercased().contains(sender.stringValue.lowercased())}
        }
        tableview.reloadData()
    }
    
}

extension AppleSiliconObject: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return applications.count
    }
}

extension AppleSiliconObject: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, shouldTrackCell cell: NSCell, for tableColumn: NSTableColumn?, row: Int) -> Bool {
        return true
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if tableColumn != nil {
            let identifier = tableColumn!.identifier.rawValue
            switch identifier {
            case "icon":
                let image = self.applications[row].icon
                return NSImageView(image: image)
            case "name":
                let textField = NSTextField()
                textField.cell = VerticallyCenteredTextFieldCell()
                textField.stringValue = self.applications[row].name
                MyLog(self.applications[row].name)
                textField.alignment = .left
                textField.isBordered = false
                return textField
            case "version":
                let textField = NSTextField()
                textField.cell = VerticallyCenteredTextFieldCell()
                textField.stringValue = self.applications[row].version
                textField.alignment = .left
                textField.isBordered = false
                return textField
            case "type":
                let textField = NSTextField()
                textField.cell = VerticallyCenteredTextFieldCell()
                textField.stringValue = self.applications[row].arch
                textField.alignment = .left
                textField.isBordered = false
                return textField
            case "result":
                let button = NSButton()
                button.setButtonType(.radio)
                button.bezelStyle = .inline
                button.title = ""
                button.alignment = .right
                if self.applications[row].arch == "通用" || self.applications[row].arch == "仅Apple芯片" || self.applications[row].arch == "IOS" {
                    button.state = .on
                    button.bezelColor = .green
                }
                else {
                    button.isHidden = true
                }
                return button
            case "path":
                let button = NSButton()
                button.target = self
                button.action = #selector(openURL(_:))
                button.bezelStyle = .recessed
                button.isBordered = false
                let image = NSImage(named: "NSRevealFreestandingTemplate")
                image!.isTemplate = true
                button.image = image
                return button
            default:
                return nil
            }
        }
        return nil
    }
    
}
