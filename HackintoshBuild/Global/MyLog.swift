//
//  MyLog.swift
//  HackintoshBuild
//
//  Created by 刘靖禹 on 2020/1/17.
//  Copyright © 2020 Arabaku. All rights reserved.
//

import Foundation

/**
 原则上只在 DEBUG 环境打印日志，所以封装一下
 */

func MyLog<T>(_ message: T, file: String = #file, funcName: String = #function, lineNum: Int = #line) {
    #if DEBUG
    let file = (file as NSString).lastPathComponent;
    print("\(file):(\(lineNum))--\(message)");
    #endif
}
