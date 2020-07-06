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
    
    static func isAMDProcessor() -> Bool {
        var size = 0
        sysctlbyname("machdep.cpu.vendor", nil, &size, nil, 0)
        var buffer = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.vendor", &buffer, &size, nil, 0)
        let vendor = String(cString: buffer)
        
        let pattern: String = ".*amd.*"
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
            let matches = regex.matches(in: vendor, options: [], range: NSMakeRange(0, vendor.count))
            if matches.count == 1 && matches[0].range.location != NSNotFound {
                return true
            } else {
                return false
            }
        }
        return false
    }
    
}
