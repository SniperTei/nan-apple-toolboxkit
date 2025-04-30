//
//  SNPLogManager.swift
//  NanToolboxKit
//
//  Created by zhengnan on 2025/4/25.
//

import Foundation

public class SNPLogManager {
    // 单例
    private static var _shared: SNPLogManager?
    public static var shared: SNPLogManager {
        guard let shared = _shared else {
            fatalError("请先调用 SNPLogManager.setup(config:) 进行初始化")
        }
        return shared
    }
    
    public static func setup(config: SNPLogConfig) {
        _shared = SNPLogManager(config: config)
    }
    
    // 添加这些属性
    private let logFilePath: String
    private let logFileName: String
    private let logLevel: SNPLogLevel
    private let logType: SNPLogType
    private let logInfoType: SNPLogInfoType
    
    // 添加两个日期格式化器
    private let fileNameDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private let logTimeDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
    
    // 添加当前日志日期属性
    private var currentLogDate: String
    
    // 初始化 传SNPLogConfig参数
    public init(config: SNPLogConfig) {
        logFilePath = config.logFilePath
        logFileName = config.logFileName
        logLevel = config.logLevel
        logType = config.logType
        logInfoType = config.logInfoType
        currentLogDate = fileNameDateFormatter.string(from: Date())
        
        // 创建日志文件夹
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: logFilePath) {
            try! fileManager.createDirectory(atPath: logFilePath, withIntermediateDirectories: true, attributes: nil)
        }
        // 打印日志文件路径
        print("日志文件路径: \(logFilePath)")
    }
    
    // 获取当前日志文件名
    private func getCurrentLogFileName() -> String {
        let today = fileNameDateFormatter.string(from: Date())
        if today != currentLogDate {
            currentLogDate = today
        }
        return "SNPLog-\(currentLogDate).log"
    }

    // 写入日志
    public func writeLog(log: String, file: String = #file, line: Int = #line) {
        let currentFileName = getCurrentLogFileName()
        let logFilePath = (self.logFilePath as NSString).appendingPathComponent(currentFileName)
        
        // 获取当前时间
        let timestamp = logTimeDateFormatter.string(from: Date())
        
        // 获取文件名（去掉路径）
        let fileName = (file as NSString).lastPathComponent
        
        // 组装日志内容
        let logContent = "[\(timestamp)] [\(fileName):\(line)] \(log)\n"
        let logData = logContent.data(using: .utf8)!
        
        // 直接写入文件
        if !FileManager.default.fileExists(atPath: logFilePath) {
            FileManager.default.createFile(atPath: logFilePath, contents: nil, attributes: nil)
        }
        if let fileHandle = FileHandle(forWritingAtPath: logFilePath) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(logData)
            fileHandle.closeFile()
        }
    }

}
