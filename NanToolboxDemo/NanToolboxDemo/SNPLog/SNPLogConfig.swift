//
//  SNPLogConfig.swift
//  NanToolboxKit
//
//  Created by zhengnan on 2025/4/25.
//

import Foundation

public struct SNPLogConfig {
    public let logFilePath: String
    public let logType: SNPLogType
    public let deviceId: String
    
    public init(
        logFilePath: String,
        deviceId: String,
        logType: SNPLogType = .console
    ) {
        self.logFilePath = logFilePath
        self.deviceId = deviceId
        self.logType = logType
    }
}
