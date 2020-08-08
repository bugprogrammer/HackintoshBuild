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
        
        case NSToolbarItem_Info = "NSToolbarItem_Info"
        case NSToolbarItem_Build = "NSToolbarItem_Build"
        case NSToolbarItem_EFI = "NSToolbarItem_EFI"
        case NSToolbarItem_Disk = "NSToolbarItem_Disk"
        case NSToolbarItem_Nvram = "NSToolbarItem_Nvram"
        case NSToolbarItem_Lock = "NSToolbarItem_Lock"
        case NSToolbarItem_Ioreg = "NSToolbarItem_Ioreg"
        case NSToolbarItem_Other = "NSToolbarItem_Other"
        case NSToolbarItem_Pay = "NSToolbarItem_Pay"
        case NSToolbarItem_GPU = "NSToolbarItem_GPU"
        case NSToolbarItem_OS = "NSToolbarItem_OS"
        case NSToolbarItem_Kexts = "NSToolbarItem_Kexts"
        case complate = "complate"
        case downloadAll = "downloadAll"
        case mount = "mount"
        case open = "open"
        case open1 = "open1"
        case refresh = "refresh"
        case refresh1 = "refresh1"
        case unmount = "unmount"
        case export = "export"
        case run = "run"
        case stop = "stop"
        case highsierra = "HighSierra"
        case mojave = "mojave"
        case catalina = "catalina"
        case NSToolbarItem_Compare = "NSToolbarItem_Compare"
        case file = "file"
        case compare = "compare"
    }
    
    convenience init!(asset: Asset) {
        self.init(named: asset.rawValue)
    }
}
