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
    public let deviceId: String
    
    public init(
        logFilePath: String,
        logFileName: String,
        deviceId: String,
        logLevel: SNPLogLevel = .debug,
        logType: SNPLogType = .console
    ) {
        self.logFilePath = logFilePath
        self.logFileName = logFileName
        self.deviceId = deviceId
        self.logLevel = logLevel
        self.logType = logType
    }
}
