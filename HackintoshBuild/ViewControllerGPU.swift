//
//  ViewControllerGPU.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2020/3/28.
//  Copyright © 2020 bugprogrammer. All rights reserved.
//

import Cocoa
import Highlightr

class ViewControllerGPU: NSViewController {

    @IBOutlet weak var gpuLists: NSPopUpButton!
    @IBOutlet var plistTextView: NSTextView!
    @IBOutlet weak var exportButton: NSButton!
    @IBOutlet weak var exportURL: NSPathControl!
    
    let gpuArray: [String] = ["Vega 56", "Vega 64", "VII", "RX 5700", "RX 5700 XT"]
    let gfxutil = Bundle.main.path(forResource: "gfxutil", ofType: nil)
    let pathPlist = Bundle.main.path(forResource:"config", ofType: "plist")
    let url = Bundle.main.url(forResource:"config", withExtension: "plist")
    let taskQueue = DispatchQueue.global(qos: .default)
    var dict: NSMutableDictionary = NSMutableDictionary()
    var dict2: Dictionary = Dictionary<String, Any>()
    var output: String = ""
    var pathGPU: String = ""
    var ports: String = ""
    var select: String = "Vega 56"
    var exportPath: String = ""
    let filemanager = FileManager.default
    let lock = NSLock()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let image = MyAsset.export.image
        image.isTemplate = true
        gpuLists.addItems(withTitles: gpuArray)
        runBuildScripts("paths", [gfxutil!])
        exportButton.isBordered = false
        exportButton.bezelStyle = .recessed
        exportButton.image = image
        exportButton.isEnabled = false
        if let exportURL = UserDefaults.standard.url(forKey: "exportURL") {
            if filemanager.fileExists(atPath: exportURL.path) {
                self.exportURL.url = exportURL
                exportPath = exportURL.path
                exportButton.isEnabled = true
            }
        }
    }
        
    @IBAction func selectPath(_ sender: Any) {
        if let url = exportURL.url {
            exportPath = url.path
            exportButton.isEnabled = true
            UserDefaults.standard.set(url, forKey: "exportURL")
        }
    }
    
    @IBAction func select(_ sender: Any) {
        select = gpuArray[gpuLists.indexOfSelectedItem]
        runBuildScripts("paths", [gfxutil!])
    }
    
    func getPlist(_ devicePath: String, _ model: String, _ portNum: Int) {
        MyLog(portNum)
        var dict2: Dictionary<String, Any>
        if (url != nil) {
            dict = NSMutableDictionary(contentsOf: url!)!
            let keys = dict.allKeys as [Any]
            if keys.contains(where: {$0 as! String == devicePath}) {
                dict2 = dict[devicePath] as! Dictionary<String, Any>
            }
            else {
                dict2 = dict["devicepath"] as! Dictionary<String, Any>
                if devicePath != "" {
                    dict[devicePath] = dict2
                }
                else {
                    dict["无GFX0设备"] = dict2
                }
                dict.removeObject(forKey: "devicepath")
            }
            
            for i in 0..<portNum {
                switch model {
                case "Vega 56":
                    dict2["@" + String(i) + ",name"] = "ATY,Kamarang"
                    break
                case "Vega 64":
                    dict2["@" + String(i) + ",name"] = "ATY,Kamarang"
                    break
                case "VII":
                    dict2["@" + String(i) + ",name"] = "ATY,Donguil"
                    break
                case "RX 5700":
                    dict2["@" + String(i) + ",name"] = "ATY,Adder"
                    break
                case "RX 5700 XT":
                    dict2["@" + String(i) + ",name"] = "ATY,Adder"
                    break
                default:
                    break
                }
            }
            switch model {
            case "Vega 56":
                dict2["ATY,Card#"] = "109-D000A1-01"
                dict2["ATY,DeviceName"] = "Vega 56"
                dict2["ATY,EFIVersion"] = "016.001.001.000.008771"
                dict2["ATY,FamilyName"] = "Radeon Pro"
                dict2["ATY,Rom#"] = "113-D0500300-102"
                dict2["device_type"] = "ATY,KamarangParent"
                dict2["model"] = "Radeon Pro Vega 56"
                break
            case "Vega 64":
                dict2["ATY,Card#"] = "109-D000A1-01"
                dict2["ATY,DeviceName"] = "Vega 64"
                dict2["ATY,EFIVersion"] = "016.001.001.000.008771"
                dict2["ATY,FamilyName"] = "Radeon Pro"
                dict2["ATY,Rom#"] = "113-D0500300-102"
                dict2["device_type"] = "ATY,KamarangParent"
                dict2["model"] = "Radeon Pro Vega 64"
                break
            case "VII":
                dict2["ATY,EFIVersionB"] = "113-D163A1XT-045"
                dict2["ATY,EFIVersionROMB"] = "113-D163A1XT-045"
                dict2["ATY,DeviceName"] = "Vega II"
                dict2["ATY,EFIVersion"] = "01.01.186"
                dict2["ATY,FamilyName"] = "Radeon Pro"
                dict2["ATY,Rom#"] = "113-D160BW-444"
                dict2["device_type"] = "ATY,DonguilParent"
                dict2["model"] = "Radeon Pro Vega II"
                dict2.removeValue(forKey: "ATY,Card#")
                break
            case "RX 5700":
                dict2["ATY,Card#"] = "102-D32200-00"
                dict2["ATY,DeviceName"] = "W5700X"
                dict2["ATY,EFIVersion"] = "01.01.190"
                dict2["ATY,FamilyName"] = "Radeon Pro"
                dict2["ATY,Rom#"] = "113-D3220E-190"
                dict2["device_type"] = "ATY,AdderParent"
                dict2["model"] = "Radeon Pro W5700X"
                break
            case "RX 5700 XT":
                dict2["ATY,Card#"] = "102-D32200-00"
                dict2["ATY,DeviceName"] = "W5700X"
                dict2["ATY,EFIVersion"] = "01.01.190"
                dict2["ATY,FamilyName"] = "Radeon Pro"
                dict2["ATY,Rom#"] = "113-D3220E-190"
                dict2["device_type"] = "ATY,AdderParent"
                dict2["model"] = "Radeon Pro W5700X"
                break
            default:
                break
            }
            dict[devicePath] = dict2
            dict.write(to: url!, atomically: true)
            MyLog(dict as Any)
        }
    }
    
    func prettyFormat(xmlString: String) -> NSAttributedString? {
        let highlightr = Highlightr()
        highlightr!.setTheme(to: "paraiso-dark")
        let plistStr = xmlString.replacingOccurrences(of: "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n", with: "").replacingOccurrences(of: "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n", with: "").replacingOccurrences(of: "<plist version=\"1.0\">\n", with: "")
        let highlightedCode = highlightr!.highlight(plistStr, as: "xml")
        return highlightedCode
    }
        
    @IBAction func export(_ sender: Any) {
        if filemanager.isWritableFile(atPath: exportPath) {
            if filemanager.fileExists(atPath: exportPath + "/gpu_" + select + ".plist") {
                try! filemanager.copyItem(atPath: exportPath + "/gpu_" + select + ".plist", toPath: exportPath + "/gpu_" + select + Date().milliStamp + ".plist")
            }
            else {
                try! filemanager.copyItem(atPath: pathPlist!, toPath: exportPath + "/gpu_" + select + ".plist")
            }
            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: exportPath + "/gpu_" + select + ".plist")])
        }
        else {
            let alert = NSAlert()
            alert.messageText = "所选路径不可写"
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
                    if data.count > 0 {
                        let outputString = String(data: data, encoding: String.Encoding.utf8) ?? ""
                        OperationQueue.main.addOperation { [weak self] in
                            guard let `self` = self else { return }
                            self.lock.lock()
                            let previousOutput = self.output
                            let nextOutput = previousOutput + outputString
                            self.output = nextOutput
                            if shell == "paths" {
                                self.pathGPU = self.output.components(separatedBy: "\n").first!
                                self.runBuildScripts("ports", [])
                            } else if shell == "ports" {
                                self.ports = self.output.components(separatedBy: "\n").first!
                                MyLog(self.ports)
                                self.getPlist(self.pathGPU, self.select, Int(self.ports) ?? 0)
                                self.runBuildScripts("printPlist", [self.pathPlist!])
                            } else if shell == "printPlist" {
                                self.plistTextView.textStorage?.setAttributedString(self.prettyFormat(xmlString: outputString)!)
                            }
                            self.lock.unlock()
                        }
                    } else if (data.count == 0 && !task.isRunning) {
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

extension Date {
    var timeStamp: String {
        let timeInterval: TimeInterval = self.timeIntervalSince1970
        let timeStamp = Int(timeInterval)
        return "\(timeStamp)"
    }
    var milliStamp: String {
        let timeInterval: TimeInterval = self.timeIntervalSince1970
        let millisecond = CLongLong(round(timeInterval*1000))
        return "\(millisecond)"
    }
}
