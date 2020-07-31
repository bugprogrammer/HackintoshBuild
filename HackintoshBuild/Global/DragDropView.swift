//
//  DragDropView.swift
//  DragDrop
//
//  Created by Banaple on 2020/01/07.
//  Copyright © 2020 BUGKING. All rights reserved.
//

import Cocoa

public final class DragDropView: NSView {
    
    // highlight the drop zone when mouse drag enters the drop view
    fileprivate var highlight : Bool = false
    
    // check if the dropped file type is accepted
    fileprivate var fileTypeIsOk = false
    
    
    /// Allowed file type extensions to drop, eg: ["png", "jpg", "jpeg"]
    public var acceptedFileExtensions : [String] = []
    public var usedArrowImage:Bool = true
    public var droppedFileWithURL:((URL)->())?
    public var droppedFilesWithURLs:(([URL])->())?
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        if #available(OSX 10.13, *) {
            registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
        } else {
            // Fallback on earlier versions
            registerForDraggedTypes([NSPasteboard.PasteboardType("NSFilenamesPboardType")])
        }
    }
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if !usedArrowImage {
            return
        }
        // Drawing code here.
        if(NSAppKitVersion.current.rawValue < NSAppKitVersion.macOS10_10.rawValue) {
            NSColor.windowBackgroundColor.setFill()
        } else {
            NSColor.clear.set()
        }
        
        __NSRectFillUsingOperation(dirtyRect, NSCompositingOperation.sourceOver)
        
        let grayColor = NSColor(deviceWhite: 0, alpha: highlight ? 1.0/4.0 : 1.0/8.0)
        grayColor.set()
        grayColor.setFill()
        
        let bounds = self.bounds
        let size = min(bounds.size.width - 8.0, bounds.size.height - 8.0);
        let width =  max(2.0, size / 32.0)
        NSBezierPath.defaultLineWidth = width
        
        // draw arrow
        let arrowPath = NSBezierPath()
        let baseWidth = size / 8.0
        let baseHeight = size / 8.0
        let arrowWidth = baseWidth * 2.0
        let pointHeight = baseHeight * 3.0
        let offset = -size / 8.0

        arrowPath.move(to: NSMakePoint(bounds.size.width/2.0 - baseWidth, bounds.size.height/2.0 + baseHeight - offset))

        arrowPath.line(to: NSMakePoint(bounds.size.width/2.0 + baseWidth, bounds.size.height/2.0 + baseHeight - offset))
        arrowPath.line(to: NSMakePoint(bounds.size.width/2.0 + baseWidth, bounds.size.height/2.0 - baseHeight - offset))
        arrowPath.line(to: NSMakePoint(bounds.size.width/2.0 + arrowWidth, bounds.size.height/2.0 - baseHeight - offset))
        arrowPath.line(to: NSMakePoint(bounds.size.width/2.0, bounds.size.height/2.0 - pointHeight - offset))
        arrowPath.line(to: NSMakePoint(bounds.size.width/2.0 - arrowWidth, bounds.size.height/2.0 - baseHeight - offset))
        arrowPath.line(to: NSMakePoint(bounds.size.width/2.0 - baseWidth, bounds.size.height/2.0 - baseHeight - offset))

        arrowPath.fill()
        
        MyLog(arrowWidth)
        MyLog(pointHeight)
    }
    
    public func setup(_ droppedFileWithURL:((URL)->())?, droppedFilesWithURLs:(([URL])->())?) {
        self.droppedFileWithURL = droppedFileWithURL
        self.droppedFilesWithURLs = droppedFilesWithURLs
    }
    
    // MARK: - NSDraggingDestination
    public override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        highlight = true
        fileTypeIsOk = isExtensionAcceptable(draggingInfo: sender)
        
        self.setNeedsDisplay(self.bounds)
        return []
    }
    
    public override func draggingExited(_ sender: NSDraggingInfo?) {
        highlight = false
        self.setNeedsDisplay(self.bounds)
    }
    
    public override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        let ret:NSDragOperation = fileTypeIsOk ? .copy : []
        
        return ret
    }
    
    public override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        // finished with dragging so remove any highlighting
        highlight = false
        self.setNeedsDisplay(self.bounds)
        
        return true
    }
    
    public override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if sender.filePathURLs.count == 0 {
            return false
        }
        
        if(fileTypeIsOk) {
            if sender.filePathURLs.count == 1 {
                droppedFileWithURL?(sender.filePathURLs.first!)
            } else {
                droppedFilesWithURLs?(sender.filePathURLs)
            }
        }
        
        return true
    }
    
    fileprivate func isExtensionAcceptable(draggingInfo: NSDraggingInfo) -> Bool {
        if draggingInfo.filePathURLs.count == 0 {
            return false
        }
        
        for filePathURL in draggingInfo.filePathURLs {
            let fileExtension = filePathURL.pathExtension.lowercased()
            
            if !acceptedFileExtensions.contains(fileExtension){
                return false
            }
        }
        
        return true
    }
    
    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
    
}
