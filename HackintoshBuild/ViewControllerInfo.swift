//
//  ViewControllerInfo.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2020/2/5.
//  Copyright © 2020 bugprogrammer. All rights reserved.
//

import Cocoa

class ViewControllerInfo: NSViewController {
    
    @IBOutlet weak var BLKextsLabel: NSTextField!
    @IBOutlet weak var BLEfiLabel: NSTextField!
    @IBOutlet weak var BLSsdtLabel: NSTextField!
    @IBOutlet var SLETextView: NSTextView!
    @IBOutlet var loadedTextView: NSTextView!
    @IBOutlet var LETextView: NSTextView!
    @IBOutlet var BLTextView: NSTextView!
    @IBOutlet var efiTextView: NSTextView!
    @IBOutlet var amlTextView: NSTextView!
    @IBOutlet weak var bootLoaderCheck: NSComboBox!
    @IBOutlet weak var refreshButton: NSButton!
    @IBOutlet var outputTableView: NSTextView!
    
    
    let taskQueue = DispatchQueue.global(qos: .background)
    let kextPath = Bundle.main.path(forResource: "AppleIntelInfo", ofType: "kext")
    var output: String = ""
    var bootLoaderTypeArr: [String] = ["请选择引导类型","OpenCore","Clover"]
    var bootLoaderType: String = ""
    var nsDictionary: NSDictionary?
    var fileManager = FileManager.default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshButton.isEnabled = false
        runBuildScripts("kextInfo",[])
        bootLoaderCheck.numberOfVisibleItems = bootLoaderTypeArr.count
        bootLoaderCheck.addItems(withObjectValues: bootLoaderTypeArr)
        bootLoaderCheck.selectItem(at: 0)
        bootLoaderCheck.isSelectable = false
        
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
    
    @IBAction func Refresh(_ sender: Any) {
        refreshButton.isEnabled = false
        outputTableView.string = ""
        runBuildScripts("AppleIntelInfo", [kextPath!])
    }
    
    @IBAction func bootloaderSelected(_ sender: NSComboBox) {
        bootLoaderType = bootLoaderTypeArr[sender.indexOfSelectedItem]
        
        BLTextView.string = ""
        efiTextView.string = ""
        amlTextView.string = ""
        
        var BLArr: [String] = []
        if self.bootLoaderType == "OpenCore" {
            BLKextsLabel.stringValue = "OpenCore下的Kexts"
            BLArr = self.findFiles("/Volumes/EFI/EFI/OC/Kexts/", ".kext")
        }
        else if self.bootLoaderType == "Clover"  {
            BLKextsLabel.stringValue = "Clover下的Kexts"
            BLArr = self.findFiles("/Volumes/EFI/EFI/Clover/kexts/", ".kext")
        }
        else {
            BLKextsLabel.stringValue = "请选择引导类型"
            BLArr.append("reset")
        }
            if BLArr.isEmpty {
                if !fileManager.fileExists(atPath: "/Volumes/EFI/EFI/" ) {
                    self.BLTextView.string = "尚未挂载EFI分区"
                }
                else {
                    self.BLTextView.string = "神马情况？EFI下没有Kexts？？？"
                }
            }
            else if BLArr[0] == "reset" {
                self.BLTextView.string = ""
            }
            else {
                for kext in BLArr {
                    //self.BLTextView.string.append(kext.components(separatedBy: "/").last! + "\n")
                    self.BLTextView.string.append(kext + "\n")
                }
            }
        
        var efiArr: [String] = []
        if self.bootLoaderType == "OpenCore" {
            BLEfiLabel.stringValue = "OpenCore下的efi文件"
            efiArr = self.findFiles("/Volumes/EFI/EFI/OC/Drivers/", ".efi")
        }
        else if self.bootLoaderType == "Clover" {
            BLEfiLabel.stringValue = "Clover下的efi文件"
            efiArr = self.findFiles("/Volumes/EFI/EFI/Clover/", ".efi")
        }
        else {
            BLEfiLabel.stringValue = "请选择引导类型"
            efiArr.append("reset")
        }
        
            if efiArr.isEmpty {
                if !fileManager.fileExists(atPath: "/Volumes/EFI/EFI/" ) {
                    self.efiTextView.string = "尚未挂载EFI分区"
                }
                else {
                    self.efiTextView.string = "神马情况？EFI下没有.efi驱动？？？"
                }
                
            }
            else if efiArr[0] == "reset" {
                self.efiTextView.string = ""
            }
            else {
                for efi in efiArr {
                    //self.efiTextView.string.append(efi.components(separatedBy: "/").last! + "\n")
                    self.efiTextView.string.append(efi + "\n")
                }
            }
        var amlArr: [String] = []
        if self.bootLoaderType == "OpenCore" {
            BLSsdtLabel.stringValue = "OpenCore下的ssdt文件"
            amlArr = self.findFiles("/Volumes/EFI/EFI/OC/ACPI/", ".aml")
        }
        else if self.bootLoaderType == "Clover" {
            BLSsdtLabel.stringValue = "Clover下的ssdt文件"
            amlArr = self.findFiles("/Volumes/EFI/EFI/Clover/ACPI/patched/", ".aml")
        }
        else {
            BLSsdtLabel.stringValue = "请选择引导类型"
            amlArr.append("reset")
        }
        
        if amlArr.isEmpty {
            if !fileManager.fileExists(atPath: "/Volumes/EFI/EFI/" ) {
                self.amlTextView.string = "尚未挂载EFI分区"
            }
            else {
                self.amlTextView.string = "您未使用任何SSDT"
            }
        }
        else if amlArr[0] == "reset" {
            self.amlTextView.string = ""
        }
        else {
            for aml in amlArr {
                self.amlTextView.string.append(aml + "\n")
            }
        }
    }
    
    func HackinChanged(_ path: String,_ filterTypes: String) -> String {
        var fileString:String = ""
        let files = findFiles(path, filterTypes)
        //MyLog(files)
        for file in files {
            var url: String = ""
            if fileManager.fileExists(atPath: path + file + "/Contents/info.plist" ) {
                url = "/Contents/info.plist"
            }
            else {
                url = "/info.plist"
            }
            if getPlist(path + file + url) {
                //fileString.append(file.components(separatedBy: "/").last! + "\n")
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
                //files.append(filename.components(separatedBy: "/").last!)
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
                task.terminationHandler = { task in
                    DispatchQueue.main.async(execute: { [weak self] in
                        guard let `self` = self else { return }
                        if shell == "kextInfo" {
                            self.loadedTextView.string.append(self.output)
                            self.runBuildScripts("AppleIntelInfo", [self.kextPath!])
                        }
                        else {
                            self.refreshButton.isEnabled = true
                            AraHUDViewController.shared.hideHUD()
                            self.outputTableView.string.append(self.output)
                        }
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
                //MyLog(outputString)
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
                MyLog(nsDictionary![key] as! String)
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
