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

    @IBOutlet weak var webview: WKWebView!
    
    let mergely = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "mergely")
    
    override func willAppear(_ noti: Notification) {
        super.willAppear(noti)
        
        let index = noti.object as! Int
        if index != 8 { return }
        if !once { return }
        once = false
        
        webview.loadFileURL(mergely!, allowingReadAccessTo: mergely!)
        let request = URLRequest(url: mergely!)
        webview.load(request)
    }
    
}
