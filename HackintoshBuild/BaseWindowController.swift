//
//  BaseWindowController.swift
//  HackintoshBuild
//
//  Created by 刘靖禹 on 2020/1/17.
//  Copyright © 2020 Arabaku. All rights reserved.
//

import Cocoa

class BaseWindowController: NSWindowController {

    let buildIdentifier = NSToolbarItem.Identifier(rawValue: "bugprogrammer.HackintoshBuild.NSToolbarItem.buildIdentifier")
    let efiIdentifier = NSToolbarItem.Identifier(rawValue: "bugprogrammer.HackintoshBuild.NSToolbarItem.efiIdentifier")
    let otherIdentifier = NSToolbarItem.Identifier(rawValue: "bugprogrammer.HackintoshBuild.NSToolbarItem.otherIdentifier")
    
    override func windowDidLoad() {
        super.windowDidLoad()
        setupToolbar()
    }
    
    func setupToolbar() {
        let toolBar = NSToolbar(identifier: "bugprogrammer.HackintoshBuild.NSToolbar.MyToolbar")
//        toolBar.allowsUserCustomization = false
//        toolBar.autosavesConfiguration = false
        toolBar.displayMode = .iconAndLabel
        toolBar.sizeMode = .default
        toolBar.delegate = self
        toolBar.selectedItemIdentifier = buildIdentifier
        self.window?.toolbar = toolBar // retain
    }

}

extension BaseWindowController: NSToolbarDelegate {
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [buildIdentifier, efiIdentifier, otherIdentifier]
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [buildIdentifier, efiIdentifier, otherIdentifier]
    }
    
    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [buildIdentifier, efiIdentifier, otherIdentifier]
    }
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        var toolbarItem: NSToolbarItem? = NSToolbarItem(itemIdentifier: itemIdentifier)
        switch itemIdentifier {
        case buildIdentifier:
            toolbarItem?.label = "编译"
            toolbarItem?.paletteLabel = "编译"
            toolbarItem?.toolTip = "编译一些常用的引导/驱动"
            toolbarItem?.image = MyAsset.NSToolbarItem_Build.image
            break
            
        case efiIdentifier:
            toolbarItem?.label = "常见机型EFI分享"
            toolbarItem?.paletteLabel = "常见机型EFI分享"
            toolbarItem?.toolTip = "常见机型EFI分享"
            toolbarItem?.image = MyAsset.NSToolbarItem_EFI.image
            break
            
        case otherIdentifier:
            toolbarItem?.label = "其他小功能"
            toolbarItem?.paletteLabel = "其他小功能"
            toolbarItem?.toolTip = "其他一些可能需要的东西"
            toolbarItem?.image = MyAsset.NSToolbarItem_Other.image
        default:
            toolbarItem = nil
            break
        }
        
        toolbarItem?.target = self
        toolbarItem?.action = #selector(toolbarItemDidTapped(_:))
        return toolbarItem
    }
     
    @objc func toolbarItemDidTapped(_ item: NSToolbarItem) {
        switch item.itemIdentifier {
        case buildIdentifier:
            self.window?.contentViewController = MyTool.getViewControllerFromMain(ViewControllerBuild.self)
            break
        case efiIdentifier:
            self.window?.contentViewController = MyTool.getViewControllerFromMain(ViewControllerEFI.self)
            break
        case otherIdentifier:
            self.window?.contentViewController = MyTool.getViewControllerFromMain(ViewControllerOther.self)
            break
        default:
            break
        }
    }
}
