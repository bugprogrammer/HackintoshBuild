//
//  BaseObject.swift
//  HackintoshBuild
//
//  Created by 刘靖禹 on 2020/7/11.
//  Copyright © 2020 Arabaku. All rights reserved.
//

import Cocoa

class OutBaseObject: NSObject {
    
    var once: Bool = true
    
    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(willAppear(_:)), name: NSNotification.Name.TapChanged, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func willAppear(_ noti: Notification) {
        
    }
    
}
