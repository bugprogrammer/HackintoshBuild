//
//  main.swift
//  HackintoshBuild
//
//  Created by 刘靖禹 on 2020/1/21.
//  Copyright © 2020 Arabaku. All rights reserved.
//

/**
 适配版本更新
 */

import Foundation
import Cocoa

fileprivate class LaunchTool {
    
    fileprivate func launchMyAppFromPath(path: String) {
        let cmd = "open -n \(path)"
        self.runCommand(cmd: cmd)
    }
    
    @discardableResult
    fileprivate func runCommand(cmd: String) -> String? {
        MyLog("run command: \(cmd)")
        
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", cmd]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        
        let output = String(data: data, encoding: .utf8)
        task.waitUntilExit()
        return output
    }
    
}

fileprivate let argc = CommandLine.argc
fileprivate let argv = CommandLine.unsafeArgv
fileprivate let arguments = CommandLine.arguments

fileprivate let needUpadte = UserDefaults.standard.bool(forKey: "update")

if needUpadte {
    UserDefaults.standard.set(false, forKey: "update")
    
    if arguments.count < 2 {
        exit(1)
    }
    
    let targetPath = arguments[1]
    let downloadedPath = arguments[2]

    let myFileManager = FileManager.default
    
    guard myFileManager.fileExists(atPath: targetPath) && myFileManager.fileExists(atPath: downloadedPath) else {
        exit(1)
    }
    
    let tool = LaunchTool()
    let rmCmd = "rm -rf \(targetPath)"
    tool.runCommand(cmd: rmCmd)
    let mvCmd = "mv \(downloadedPath) \(targetPath)"
    tool.runCommand(cmd: mvCmd)
    tool.launchMyAppFromPath(path: targetPath)
    
    exit(0)
}

_ = NSApplicationMain(argc, argv)
