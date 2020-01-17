//
//  MyAsset.swift
//  HackintoshBuild
//
//  Created by 刘靖禹 on 2020/1/17.
//  Copyright © 2020 Arabaku. All rights reserved.
//

import Cocoa

/**
 这里存放所有可能用到的图片素材
 使用方法：MyAsset.图片名称.image
 */

typealias MyAsset = NSImage.Asset

extension NSImage {
    enum Asset: String {
        
        var image: NSImage {
            return NSImage(asset: self)
        }
        
        case NSToolbarItem_Build = "NSToolbarItem_Build"
        case NSToolbarItem_Other = "NSToolbarItem_Other"
    }
    
    convenience init!(asset: Asset) {
        self.init(named: asset.rawValue)
    }
}
