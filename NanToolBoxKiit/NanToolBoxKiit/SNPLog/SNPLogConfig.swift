//
//  SNPLogConfig.swift
//  NanToolboxKit
//
//  Created by zhengnan on 2025/4/25.
//

import Foundation

public struct SNPLogConfig {
    public let logFilePath: String
    public let logFileName: String
    public let logLevel: SNPLogLevel
    public let logType: SNPLogType
    public let logInfoType: SNPLogInfoType
    
    public init(
        logFilePath: String,
        logFileName: String,
        logLevel: SNPLogLevel = .debug,
        logType: SNPLogType = .console,
        logInfoType: SNPLogInfoType = .default
    ) {
        self.logFilePath = logFilePath
        self.logFileName = logFileName
        self.logLevel = logLevel
        self.logType = logType
        self.logInfoType = logInfoType
    }
}
