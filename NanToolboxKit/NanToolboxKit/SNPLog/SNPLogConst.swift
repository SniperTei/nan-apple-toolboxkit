//
//  SNPLogConst.swift
//  NanToolboxKit
//
//  Created by zhengnan on 2025/4/25.
//

import Foundation

// 日志级别
public enum SNPLogLevel {
    case debug
    case info
    case warning
    case error
}

// 日志输出类型
public enum SNPLogType {
    case console
    case file
}

// 日志记录类型
public enum SNPLogInfoType {
    case `default`
    case detailed
}

