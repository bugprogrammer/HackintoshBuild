//
//  InBaseObject.swift
//  HackintoshBuild
//
//  Created by 刘靖禹 on 2020/7/12.
//  Copyright © 2020 bugprogrammer. All rights reserved.
//

import Cocoa

class InBaseObject: NSObject {

    var once: Bool = true
    
    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(willAppear(_:)), name: NSNotification.Name.InTapChanged, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func willAppear(_ noti: Notification) {
        
    }
    
}
