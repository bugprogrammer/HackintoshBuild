//
//  ViewControllerCompare.swift
//  HackintoshBuild
//
//  Created by wbx on 2020/5/8.
//  Copyright © 2020 bugprogrammer. All rights reserved.
//

import Cocoa
import WebKit

class CompareObject: OutBaseObject {
    
    @IBOutlet weak var dragDropViewLeft: DragDropView!
    @IBOutlet weak var dragDropViewRight: DragDropView!
    @IBOutlet weak var imageViewLeft: NSImageView!
    @IBOutlet weak var imageViewRight: NSImageView!
    @IBOutlet weak var textFieldLeft: NSTextField!
    @IBOutlet weak var textFieldRight: NSTextField!
    @IBOutlet weak var fileNameLeft: NSTextField!
    @IBOutlet weak var fileNameRight: NSTextField!
    @IBOutlet weak var compareButton: NSButton!
    
    var isFileLeft: Bool = false
    var isFileRight: Bool = false
    var fileLeftPath: String = ""
    var fileRightPath: String = ""
    
    override func willAppear(_ noti: Notification) {
        super.willAppear(noti)
        
        let index = noti.object as! Int
        if index != 8 { return }
        if !once { return }
        once = false
        
        imageViewLeft.isHidden = true
        imageViewRight.isHidden = true
        compareButton.isEnabled = false
        
        dragDropViewLeft.backgroundColor = NSColor(named: "ColorGray")
        dragDropViewLeft.usedArrowImage = false
        dragDropViewRight.backgroundColor = NSColor(named: "ColorGray")
        dragDropViewRight.usedArrowImage = false
        
        if !checkXcode() {
            let alert = NSAlert()
            alert.messageText = "尚未安装 Xcode，请先安装 Xcode"
            alert.runModal()
            textFieldLeft.textColor = .red
            textFieldRight.textColor = .red
            textFieldLeft.stringValue = "请安装 Xcode"
            textFieldRight.stringValue = "请安装 Xcode"
            return
        }
        dragDropViewLeft.acceptedFileExtensions = ["plist", "txt", "xml"]
        dragDropViewRight.acceptedFileExtensions = ["plist", "txt", "xml"]
        dragDropViewLeft.setup({ (file) in
            self.imageViewLeft.isHidden = false
            let image = MyAsset.file.image
            image.isTemplate = true
            self.imageViewLeft.image = image
            self.dragDropViewLeft.backgroundColor = NSColor.clear
            self.textFieldLeft.isHidden = true
            self.fileNameLeft.stringValue = file.absoluteString.components(separatedBy: "/").last!
            self.isFileLeft = true
            if self.isFileLeft && self.isFileRight {
                self.compareButton.isEnabled = true
            }
            self.fileLeftPath = file.absoluteString.urlDecoded()
            MyLog(self.fileLeftPath)
            
        }) { (files) in
            let alert = NSAlert()
            alert.messageText = "只支持拖入一个文件"
            alert.runModal()
        }
        
        dragDropViewRight.setup({ (file) in
            self.imageViewRight.isHidden = false
            let image = MyAsset.file.image
            image.isTemplate = true
            self.imageViewRight.image = image
            self.dragDropViewRight.backgroundColor = NSColor.clear
            self.textFieldRight.isHidden = true
            self.fileNameRight.stringValue = file.absoluteString.components(separatedBy: "/").last!
            self.isFileRight = true
            if self.isFileLeft && self.isFileRight {
                self.compareButton.isEnabled = true
            }
            self.fileRightPath = file.absoluteString.urlDecoded()
        }) { (files) in
            let alert = NSAlert()
            alert.messageText = "只支持拖入一个文件"
            alert.runModal()
        }
    }
    
    @IBAction func compareFiles(_ sender: Any) {
        let task = Process()

        task.launchPath = "/usr/bin/opendiff"
        task.arguments = [fileLeftPath.components(separatedBy: "//").last! as String, fileRightPath.components(separatedBy: "//").last! as String]
        task.launch()
        
        dragDropViewLeft.backgroundColor = NSColor(named: "ColorGray")
        dragDropViewRight.backgroundColor = NSColor(named: "ColorGray")
        imageViewLeft.isHidden = true
        imageViewRight.isHidden = true
        textFieldLeft.isHidden = false
        textFieldRight.isHidden = false
        compareButton.isEnabled = false
        isFileLeft = false
        isFileRight = false
        fileNameLeft.stringValue = ""
        fileNameRight.stringValue = ""
    }
    
    func checkXcode() -> Bool {
        let filemanager = FileManager.default
        if filemanager.fileExists(atPath: "/Applications/Xcode.app") || filemanager.fileExists(atPath: "/Applications/Xcode-beta.app") {
            return true
        } else {
            return false
        }
    }
    
}
