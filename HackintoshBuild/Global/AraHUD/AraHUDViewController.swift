//
//  AraHUDViewController.swift
//  HackintoshBuild
//
//  Created by 刘靖禹 on 2020/2/4.
//  Copyright © 2020 Arabaku. All rights reserved.
//

import Cocoa

final class AraHUDViewController: NSObject {
    
    static let shared = AraHUDViewController()
    
    private var currentHUD: AraHUDView?
    private(set) var isShowing: Bool = false
    
    func showHUD() {
        showHUDWithTitle("任务执行中")
    }
    
    func showHUDWithTitle(_ title: String) {
        showHUDWithTitle(title, onView: nil)
    }
    
    func showHUDWithTitle(_ title: String, onView theView: NSView? = nil) {
        if currentHUD != nil {
            currentHUD?.removeFromSuperview()
        }
        
        let nib = NSNib(nibNamed: "AraHUDView", bundle: nil)!
        var myArray: NSArray? = nil
        nib.instantiate(withOwner: nil, topLevelObjects: &myArray)
        guard let objects = myArray else {
            return
        }
        for object in objects {
            if let HUD = object as? AraHUDView {
                currentHUD = HUD
                break
            }
        }
        
        isShowing = true
        (currentHUD?.viewWithTag(1) as? NSTextField)?.stringValue = title
        currentHUD?.setAccessibilityEnabled(false)
        currentHUD?.progressIndicator.startAnimation(nil)
        if theView == nil {
            let delegate = NSApplication.shared.delegate as! AppDelegate
            guard let view = delegate.window.contentView else {
                return
            }
            currentHUD?.frame = view.bounds
            view.addSubview(currentHUD!)
        } else {
            currentHUD?.frame = theView!.bounds
            theView!.addSubview(currentHUD!)
        }
    }
    
    func hideHUD() {
        isShowing = false
        if currentHUD == nil {
            return
        }
        currentHUD?.progressIndicator.stopAnimation(nil)
        self.currentHUD?.removeFromSuperview()
    }
}
