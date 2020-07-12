//
//  AraHUDView.swift
//  HackintoshBuild
//
//  Created by 刘靖禹 on 2020/2/4.
//  Copyright © 2020 Arabaku. All rights reserved.
//

import Cocoa

class AraHUDView: NSView {
    
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var containerView: NSView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.wantsLayer = true
        containerView.layer?.cornerRadius = 10
        containerView.layer?.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.5).cgColor
    }
    
    // 覆盖原 NSView 点击事件
    override func mouseDown(with event: NSEvent) {
        
    }
}
