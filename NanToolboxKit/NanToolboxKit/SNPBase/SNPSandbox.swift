//
//  SNPSandbox.swift
//  NanToolboxKit
//
//  Created by zhengnan on 2025/4/25.
//

import Foundation

struct SNPSandbox {
    // 沙盒路径
    static let sandboxPath: String = {
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        return documentDirectory
    }()
    // 日志文件路径
    static let logFilePath: String = {
        let logDirectory = (sandboxPath as NSString).appendingPathComponent("SNPLogs")
        let fileManager = FileManager.default
        return logDirectory
    }()
}
