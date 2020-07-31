//
//  InstallKextsObject.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2020/7/29.
//  Copyright © 2020 bugprogrammer. All rights reserved.
//

import Cocoa

class InstallKextsObject: OutBaseObject {
    @IBOutlet weak var dragDropView: DragDropView!
    @IBOutlet weak var sipLabel: NSTextField!
    @IBOutlet weak var snapshotLabel: NSTextField!
    @IBOutlet weak var textField: NSTextField!
    
    override func willAppear(_ noti: Notification) {
        super.willAppear(noti)
        
        let index = noti.object as! Int
        if index != 9 { return }
        if !once { return }
        once = false
        
        let sip = sipStatus()
        
        dragDropView.acceptedFileExtensions = ["kext"]
        dragDropView.usedArrowImage = false
        dragDropView.setup({ (file) in
            if sip {
                
            } else {
                let alert = NSAlert()
                alert.messageText = "sip或快照未解锁，不能安装Kexts"
                alert.runModal()
            }
        }) { (files) in
            if sip {
                
            } else {
                let alert = NSAlert()
                alert.messageText = "sip或快照未解锁，不能安装Kexts"
                alert.runModal()
            }
        }
        
    }
        
    override func awakeFromNib() {
        super.awakeFromNib()
        
        dragDropView.backgroundColor = NSColor(named: "ColorGray")
        textField.isEnabled = false
        textField.stringValue = "拖入要安装的Kexts，可以一次多个"
    }
    
    func sipStatus() -> Bool {
        var status: Bool = false
        guard let sipEnabled = isSIPStatusEnabled else {
            sipLabel.textColor = NSColor.red
            sipLabel.stringValue = "SIP 状态未知"
            status = false
            return status
        }
        if #available(OSX 10.16, *) {
            guard let snapshotEnabled = isSnapshotStatusEnabled else {
                snapshotLabel.textColor = NSColor.red
                snapshotLabel.stringValue = "快照 状态未知"
                status = false
                return status
            }
            if sipEnabled && !snapshotEnabled {
                sipLabel.textColor = NSColor.red
                sipLabel.stringValue = "SIP 未关闭，请先关闭 SIP"
                snapshotLabel.textColor = NSColor(named: "ColorGreen")
                snapshotLabel.stringValue = "快照 已删除"
                status = false
            }
            else if !sipEnabled && snapshotEnabled {
                sipLabel.textColor = NSColor(named: "ColorGreen")
                sipLabel.stringValue = "SIP 已关闭"
                snapshotLabel.textColor = NSColor.red
                snapshotLabel.stringValue = "快照 未删除，请先删除 快照"
                status = false
            }
            else if sipEnabled && snapshotEnabled {
                sipLabel.textColor = NSColor.red
                sipLabel.stringValue = "SIP 未关闭，请先关闭 SIP"
                snapshotLabel.textColor = NSColor.red
                snapshotLabel.stringValue = "快照 未删除，请先删除 快照"
                status = false
            }
            else {
                sipLabel.textColor = NSColor(named: "ColorGreen")
                sipLabel.stringValue = "SIP 已关闭"
                snapshotLabel.textColor = NSColor(named: "ColorGreen")
                snapshotLabel.stringValue = "快照 已删除"
                status = true
            }
        } else {
            if sipEnabled {
                sipLabel.textColor = NSColor.red
                sipLabel.stringValue = "SIP 未关闭，请先关闭 SIP"
                snapshotLabel.stringValue = ""
                status = false
            } else {
                sipLabel.textColor = NSColor(named: "ColorGreen")
                sipLabel.stringValue = "SIP 已关闭"
                snapshotLabel.stringValue = ""
                status = true
            }
        }
        return status
    }
}

extension DragDropView {

    var backgroundColor: NSColor? {
        get {
            if let colorRef = self.layer?.backgroundColor {
                return NSColor(cgColor: colorRef)
            } else {
                return nil
            }
        }
        set {
            self.wantsLayer = true
            self.layer?.backgroundColor = newValue?.cgColor
        }
    }
}

