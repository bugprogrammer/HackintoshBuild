//
//  MyTool.swift
//  HackintoshBuild
//
//  Created by 刘靖禹 on 2020/1/17.
//  Copyright © 2020 Arabaku. All rights reserved.
//

import Cocoa

/**
 用此类封装可能常用的工具
 */

final class MyTool {
    
    static func getViewControllerFromMain<T>(_ aClass: T.Type) -> T {
        let name = String(describing: aClass)
        let storyBoard = NSStoryboard(name: "Main", bundle: nil)
        if let vc = storyBoard.instantiateController(withIdentifier: name) as? T {
            return vc
        } else {
            fatalError("\(String(describing: aClass)) nib is not exist")
        }
    }
    
}
