//
//  SNPLogManager.swift
//  NanToolboxKit
//
//  Created by zhengnan on 2025/4/25.
//

import Foundation

// 确保这些文件在同一个模块中
#if SWIFT_PACKAGE
import SNPLogCore
#endif

public class SNPLogManager {
    // 单例
    private static var _shared: SNPLogManager?
    public static var shared: SNPLogManager {
        guard let shared = _shared else {
            fatalError("请先调用 SNPLogManager.setup(config:) 进行初始化")
        }
        return shared
    }
    
    // 初始化方法
    public static func setup(config: SNPLogConfig) {
        _shared = SNPLogManager(config: config)
    }
    
    // MARK: - 私有属性
    private let config: SNPLogConfig
    private let logFilePath: String
    private let logType: SNPLogType
    private let logInfoType: SNPLogInfoType
    private let deviceId: String
    private var currentLogDate: String
    private var fileHandle: FileHandle?
    private let logQueue: DispatchQueue
    
//    #if DEBUG
//    private let isDebugMode = true
//    #else
//    private let isDebugMode = false
//    #endif
    
    // 日期格式化器
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
    
    // 私有初始化方法
    private init(config: SNPLogConfig) {
        self.config = config
        self.logFilePath = config.logFilePath
        self.logType = config.logType
        self.logInfoType = .info
        self.deviceId = config.deviceId
        self.logQueue = DispatchQueue(label: "com.nan.logQueue", qos: .utility)
        self.currentLogDate = fileNameDateFormatter.string(from: Date())
        
        // 完成所有属性初始化后，再进行文件操作
        setupLogFile()
        startFlushTimer()
    }
    
    private func setupLogFile() {
        let fileManager = FileManager.default
        do {
            // 确保日志目录存在
            if !fileManager.fileExists(atPath: logFilePath) {
                try fileManager.createDirectory(atPath: logFilePath, withIntermediateDirectories: true, attributes: nil)
            }
            
            // 获取完整的日志文件路径
            let currentFileName = getCurrentLogFileName()
            let fullPath = (self.logFilePath as NSString).appendingPathComponent(currentFileName)
            print("日志文件路径: \(fullPath)")
            
            // 如果文件不存在，创建文件
            if !fileManager.fileExists(atPath: fullPath) {
                fileManager.createFile(atPath: fullPath, contents: nil, attributes: nil)
                // 写入一条启动日志
                if let handle = FileHandle(forWritingAtPath: fullPath) {
                    try handle.seekToEnd()
                    let startupLog = "=== 日志系统启动 [\(logTimeDateFormatter.string(from: Date()))] ===\n"
                    if let data = startupLog.data(using: .utf8) {
                        try handle.write(contentsOf: data)
                    }
                    self.fileHandle = handle
                }
            } else {
                // 文件已存在，直接打开
                if let handle = FileHandle(forWritingAtPath: fullPath) {
                    try handle.seekToEnd()
                    self.fileHandle = handle
                } else {
                    print("错误：无法打开日志文件进行写入，路径：\(fullPath)")
                }
            }
        } catch {
            print("错误：创建或打开日志文件失败 - \(error.localizedDescription)")
        }
    }
    
    private func startFlushTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.synchronizeFile()
        }
    }
    
    private func synchronizeFile() {
        guard let fileHandle = fileHandle else { return }
        do {
            try fileHandle.synchronize()
        } catch {
            print("错误：同步文件失败 - \(error.localizedDescription)")
        }
    }
    
    public func writeLog(
        log: String,
        type: SNPLogInfoType = .info,
        file: String = #file, 
        function: String = #function, 
        line: Int = #line
    ) {
        // 获取时间戳
        let timestamp = logTimeDateFormatter.string(from: Date())
        
        let typeString = type.indicator
        
        // 构建完整日志
        let fileName = (file as NSString).lastPathComponent
        let fullLog = "[\(timestamp)] [\(typeString)] [\(fileName):\(line)] \(function) - \(log)"
        
        // 根据配置输出日志
//        if config.logType == .console || config.logType == .file {
//            print(fullLog)
//        }
        
        if config.logType == .file {
            writeToFile(log: fullLog)
        }
    }
    
    // 获取当前日志文件名
    private func getCurrentLogFileName() -> String {
        let today = fileNameDateFormatter.string(from: Date())
        if today != currentLogDate {
            currentLogDate = today
        }
        return "SNPLog-\(deviceId)-\(currentLogDate).log"
    }
    
    // 写入日志
    private func writeToFile(log: String) {
        logQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 确保日志以换行结束
            let logWithNewline = log.hasSuffix("\n") ? log : log + "\n"
            
            if let data = logWithNewline.data(using: .utf8) {
                do {
                    if let fileHandle = self.fileHandle {
                        try fileHandle.write(contentsOf: data)
                        try fileHandle.synchronize()
                    } else {
                        print("错误：文件句柄为空，尝试重新打开文件")
                        self.setupLogFile()
                        // 重试一次写入
                        if let fileHandle = self.fileHandle {
                            try fileHandle.write(contentsOf: data)
                            try fileHandle.synchronize()
                        }
                    }
                } catch {
                    print("错误：写入日志失败 - \(error.localizedDescription)")
                    // 如果写入失败，尝试重新打开文件
                    self.setupLogFile()
                    // 重试一次写入
                    if let fileHandle = self.fileHandle {
                        try? fileHandle.write(contentsOf: data)
                        try? fileHandle.synchronize()
                    }
                }
            }
        }
    }
    
    deinit {
        if let fileHandle = fileHandle {
            try? fileHandle.synchronize()
            try? fileHandle.close()
        }
    }
    
    // MARK: - 便捷日志方法
    public static func network(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.writeLog(log: message,  type: .network, file: file, function: function, line: line)
    }
    
    public static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.writeLog(log: message, type: .info, file: file, function: function, line: line)
    }
    
    public static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.writeLog(log: message, type: .warning, file: file, function: function, line: line)
    }
    
    public static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.writeLog(log: message, type: .error, file: file, function: function, line: line)
    }
}

// 扩展SNPLogInfoType添加指示器
extension SNPLogInfoType {
    var indicator: String {
        switch self {
        case .info:    return "INFO"
        case .network: return "NETWORK"
        case .error:   return "ERROR"
        case .warning: return "WARN"
        }
    }
}
