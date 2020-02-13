//
//  ViewControllerIoreg.swift
//  HackintoshBuild
//
//  Created by wbx on 2020/2/12.
//  Copyright © 2020 wbx. All rights reserved.
//

import Cocoa
import WebKit

class ViewControllerIoreg: NSViewController {
    
    @IBOutlet weak var webview: WKWebView!
    @IBOutlet weak var medolBox: NSComboBox!
    
    var medolList: [String] =
    [
    "MacPro6,1",
    "MacPro5,1",
    "MacPro4,1",
    "MacPro3,1",
    "MacMini8,1",
    "MacMini7,1",
    "MacBookPro14,1",
    "MacBookPro13,3",
    "MacBookPro12,1",
    "MacBookPro11,3",
    "MacBookPro11,2",
    "MacBookPro10,1",
    "MacBook8,1",
    "iMac19,1",
    "iMac18,3",
    "iMac17,1",
    "iMac16,2",
    "iMac16,1",
    "iMac15,1",
    "iMac14,1",
    "iMac13,2"
    ]
    override func viewDidLoad() {
        super.viewDidLoad()
        medolBox.numberOfVisibleItems = medolList.count
        medolBox.addItems(withObjectValues: medolList)
        medolBox.selectItem(at: 0)
        medolBox.isSelectable = false
        loadWeb(medolList[0] + "-IORegFileViewer")
    }
    
    @IBAction func selectedMedol(_ sender: NSComboBox) {
        loadWeb(medolList[sender.indexOfSelectedItem] + "-IORegFileViewer")
    }
    
    func loadWeb(_ name: String) {
        webview.configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        let localFilePath = Bundle.main.url(forResource: name, withExtension: "html")
        let request = URLRequest(url: localFilePath!)
        webview.load(request)
    }
    
}
