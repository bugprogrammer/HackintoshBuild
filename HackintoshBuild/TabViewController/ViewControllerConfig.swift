//
//  ViewControllerConfig.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2020/2/29.
//  Copyright © 2020 bugprogrammer. All rights reserved.
//

import Cocoa

class ViewControllerConfig: NSViewController {
    
    @IBOutlet weak var BLKextsLabel: NSTextField!
    @IBOutlet weak var BLEfiLabel: NSTextField!
    @IBOutlet weak var BLSsdtLabel: NSTextField!
    @IBOutlet var SLETextView: NSTextView!
    @IBOutlet var loadedTextView: NSTextView!
    @IBOutlet var LETextView: NSTextView!
    @IBOutlet var BLTextView: NSTextView!
    @IBOutlet var efiTextView: NSTextView!
    @IBOutlet var amlTextView: NSTextView!
    @IBOutlet weak var bootLoaderCheck: NSPopUpButton!
    @IBOutlet weak var versionLabel: NSTextField!
    @IBOutlet weak var sipLabel: NSTextField!
    @IBOutlet weak var removeAllButton: NSButton!
    
    let taskQueue = DispatchQueue.global(qos: .background)
    let lock = NSLock()
    let bdmesg = Bundle.main.path(forResource: "bdmesg", ofType: "")
    var output: String = ""
    var bootLoaderTypeArr: [String] = ["请选择引导器类型","OpenCore","Clover"]
    var bootLoaderType: String = ""
    var nsDictionary: NSDictionary?
    var fileManager = FileManager.default
    var BLArr: [String] = []
    var efiArr: [String] = []
    var amlArr: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        //view.setContentSize(NSSize(width: 790, height: 630))
        guard let enabled = isSIPStatusEnabled else {
            sipLabel.textColor = NSColor.red
            sipLabel.stringValue = "SIP 状态未知"
            return
        }
        if enabled {
            sipLabel.textColor = NSColor.red
            sipLabel.stringValue = "SIP 未关闭，请先关闭 SIP"
        } else {
            sipLabel.textColor = NSColor.green
            sipLabel.stringValue = "SIP 已关闭"
        }
        view.setFrameSize(NSSize(width: 790, height: 630))
        
        versionLabel.stringValue = ""
        runBuildScripts("kextInfo", [])
        bootLoaderCheck.addItems(withTitles: bootLoaderTypeArr)
        bootLoaderCheck.selectItem(at: 0)
        
        let SLEString = self.HackinChanged("/System/Library/Extensions/", ".kext")
        if SLEString.isEmpty {
            self.SLETextView.string = "SLE未添加任何第三方Kexts"
        }
        else {
            self.SLETextView.string.append(SLEString)
        }

        let LEString = self.HackinChanged("/Library/Extensions/", ".kext")
        if LEString.isEmpty {
            self.LETextView.string = "LE未添加任何第三方Kexts"
        }
        else {
            self.LETextView.string.append(LEString)
        }
    }
    
    @IBAction func bootloaderSelected(_ sender: NSPopUpButton) {
            bootLoaderType = bootLoaderTypeArr[sender.indexOfSelectedItem]
            
            BLTextView.string = ""
            efiTextView.string = ""
            amlTextView.string = ""
            
            if self.bootLoaderType == "OpenCore" {
                autoSelect("OpenCore")
            }
            else if self.bootLoaderType == "Clover"  {
                autoSelect("Clover")
            }
            else {
                autoSelect("reset")
            }
            
            self.BLTextView.string = getArr(BLArr, "神马情况？EFI下没有Kexts？？？")
            self.efiTextView.string = getArr(efiArr, "神马情况？EFI下没有.efi驱动？？？")
            self.amlTextView.string = getArr(amlArr, "您未使用任何SSDT")
        }
        
        func autoSelect(_ blType: String) {
            if blType == "OpenCore" {
                versionLabel.stringValue = ""
                runBuildScripts("OCVersion", [])
                BLKextsLabel.stringValue = "OpenCore下的Kexts"
                BLArr = self.findFiles("/Volumes/EFI/EFI/OC/Kexts/", ".kext")
                
                BLEfiLabel.stringValue = "OpenCore下的efi文件"
                efiArr = self.findFiles("/Volumes/EFI/EFI/OC/Drivers/", ".efi")
                
                BLSsdtLabel.stringValue = "OpenCore下的ssdt文件"
                amlArr = self.findFiles("/Volumes/EFI/EFI/OC/ACPI/", ".aml")
            }
            
            else if blType == "Clover" {
                versionLabel.stringValue = ""
                runBuildScripts("CloverVersion", [bdmesg!])
                BLKextsLabel.stringValue = "Clover下的Kexts"
                BLArr = self.findFiles("/Volumes/EFI/EFI/Clover/kexts/", ".kext")
                
                BLEfiLabel.stringValue = "Clover下的efi文件"
                efiArr = self.findFiles("/Volumes/EFI/EFI/Clover/", ".efi")
                
                BLSsdtLabel.stringValue = "Clover下的ssdt文件"
                amlArr = self.findFiles("/Volumes/EFI/EFI/Clover/ACPI/patched/", ".aml")
            }
            
            else {
                versionLabel.stringValue = ""
                
                BLKextsLabel.stringValue = "请选择引导类型"
                BLArr = ["reset"]
                
                BLEfiLabel.stringValue = "请选择引导类型"
                efiArr = ["reset"]
                
                BLSsdtLabel.stringValue = "请选择引导类型"
                amlArr = ["reset"]
            }
        }
        
        func getArr(_ item: [String],_ text: String) -> String {
            var outputtext: String = ""
            
            if item.isEmpty {
                if !fileManager.fileExists(atPath: "/Volumes/EFI/EFI/" ) {
                    outputtext = "尚未挂载EFI分区"
                }
                else {
                    outputtext = text
                }
            }
            else if item == ["reset"] {
                outputtext = ""
            }
            else {
                for files in item {
                    outputtext += files + "\n"
                }
            }
            return outputtext
        }
        
        func HackinChanged(_ path: String,_ filterTypes: String) -> String {
            var fileString:String = ""
            let files = findFiles(path, filterTypes)
            for file in files {
                var url: String = ""
                if fileManager.fileExists(atPath: path + file + "/Contents/info.plist" ) {
                    url = "/Contents/info.plist"
                }
                else {
                    url = "/info.plist"
                }
                if getPlist(path + file + url) {
                    fileString.append(file + "\n")
                }
            }
            return fileString
        }
        
        func findFiles(_ path: String, _ filterTypes: String) -> [String] {
            let enumerator = FileManager.default.enumerator(atPath: path)
            var files: [String] = []

            while let filename = enumerator?.nextObject() as? String {
                if filename.extension == filterTypes {
                    files.append(filename)
                }
            }
            return files
        }
    
        func runBuildScripts(_ shell: String,_ arguments: [String]) {
            AraHUDViewController.shared.showHUDWithTitle(title: "正在进行中")
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
                            self.lock.lock()
                            
                            if shell == "kextInfo" {
                                self.loadedTextView.string.append(self.output)
                                AraHUDViewController.shared.hideHUD()
                            }
                            if shell == "CloverVersion" {
                                if self.output != "" {
                                    self.versionLabel.stringValue = "本地Clover版本：" + self.output
                                }
                                AraHUDViewController.shared.hideHUD()
                            }
                            if shell == "OCVersion" {
                                if self.output.count >= 3 {
                                    var str: String = ""
                                    let version = self.output.filter { !" \n".contains($0) }
                                    for item in version {
                                        if item == version.last {
                                            str.append(item)
                                        }
                                        else {
                                            str.append(String(item) + ".")
                                        }
                                    }
                                    self.versionLabel.stringValue = "本地OpenCore版本：" + str
                                }
                                AraHUDViewController.shared.hideHUD()
                            }
                            if shell == "remove" {
                                let SLEString = self.HackinChanged("/System/Library/Extensions/", ".kext")
                                if SLEString.isEmpty {
                                    self.SLETextView.string = "SLE未添加任何第三方Kexts"
                                }
                                else {
                                    self.SLETextView.string.append(SLEString)
                                }
                                if self.output.contains("success") {
                                    let alert = NSAlert()
                                    alert.messageText = "删除成功"
                                    alert.runModal()
                                }
                                AraHUDViewController.shared.hideHUD()
                            }
                            self.lock.unlock()
                        })
                    }
                    self.taskOutPut(task)
                    task.launch()
                    task.waitUntilExit()
                }
            }
        }
        
        func taskOutPut(_ task:Process) {
            let outputPipe = Pipe()
            task.standardOutput = outputPipe
            outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
            
            NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading , queue: nil) { notification in
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
        
        func getPlist(_ url:String) -> Bool {
            var isThird: Bool = true
            nsDictionary = NSDictionary(contentsOfFile: url)
            let keysArr = nsDictionary!.allKeys as! [String]
            for key in keysArr {
                if key == "CFBundleIdentifier" {
                    let CFBundleIdentifier = nsDictionary![key] as! String
                    let itemsArr: [String] = ["com.apple","com.Accusys","com.Areca","com.ATTO","com.CalDigit","com.intel","com.highpoint-tech","com.promise"
                    ,"com.softraid","org.virtualbox"]
                    if itemsArr.contains(where: CFBundleIdentifier.contains) {
                        isThird = false
                    }
                    else {
                        isThird = true
                    }
                }
            }
            return isThird
        }
    }

    extension String {
        var `extension`: String {
            if let index = self.lastIndex(of: ".") {
                return String(self[index...])
            } else {
                return ""
            }
        }
    }
