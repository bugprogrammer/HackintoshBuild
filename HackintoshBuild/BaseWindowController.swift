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
        self.window?.toolbar = toolBar // retain
    }

}

extension BaseWindowController: NSToolbarDelegate {
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [buildIdentifier, otherIdentifier]
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [buildIdentifier, otherIdentifier]
    }
    
    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [buildIdentifier, otherIdentifier]
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
        case otherIdentifier:
            toolbarItem?.label = "其他"
            toolbarItem?.paletteLabel = "其他"
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
            self.contentViewController = MyTool.getViewControllerFromNib(ViewControllerBuild.self)
            break
        case otherIdentifier:
            self.contentViewController = MyTool.getViewControllerFromNib(ViewControllerOther.self)
            break
        default:
            break
        }
    }
}
