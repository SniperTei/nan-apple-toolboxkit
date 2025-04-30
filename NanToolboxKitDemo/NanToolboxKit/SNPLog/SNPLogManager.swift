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
    
    // 添加日志队列和文件句柄缓存
    private let logQueue = DispatchQueue(label: "com.nan.logQueue", qos: .utility)
    private var fileHandle: FileHandle?
    private var currentLogPath: String = ""
    
    // 添加缓冲区
    private var logBuffer: [String] = []
    private let maxBufferSize = 20  // 达到20条时批量写入
    private let flushInterval: TimeInterval = 5  // 5秒未达到条数也写入
    private var lastFlushTime: Date = Date()
    
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
        
        // 启动定时器，定期刷新缓冲区
        startFlushTimer()
    }
    
    private func startFlushTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.checkAndFlushBuffer()
        }
    }
    
    private func checkAndFlushBuffer() {
        logQueue.async { [weak self] in
            guard let self = self else { return }
            let now = Date()
            if self.logBuffer.count > 0 && 
               (now.timeIntervalSince(self.lastFlushTime) >= self.flushInterval) {
                self.flushBuffer()
            }
        }
    }
    
    private func flushBuffer() {
        guard !logBuffer.isEmpty else { return }
        
        let currentFileName = getCurrentLogFileName()
        let logFilePath = (self.logFilePath as NSString).appendingPathComponent(currentFileName)
        
        // 如果文件路径变化，需要重新打开文件
        if currentLogPath != logFilePath {
            fileHandle?.closeFile()
            fileHandle = nil
            currentLogPath = logFilePath
            
            if !FileManager.default.fileExists(atPath: logFilePath) {
                FileManager.default.createFile(atPath: logFilePath, contents: nil, attributes: nil)
            }
        }
        
        // 懒加载方式打开文件
        if fileHandle == nil {
            fileHandle = FileHandle(forWritingAtPath: logFilePath)
            fileHandle?.seekToEndOfFile()
        }
        
        // 批量写入
        let logData = logBuffer.joined().data(using: .utf8)!
        fileHandle?.write(logData)
        
        // 清空缓冲区
        logBuffer.removeAll()
        lastFlushTime = Date()
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
        logQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 获取当前时间
            let timestamp = self.logTimeDateFormatter.string(from: Date())
            
            // 获取文件名（去掉路径）
            let fileName = (file as NSString).lastPathComponent
            
            // 组装日志内容
            let logContent = "[\(timestamp)] [\(fileName):\(line)] \(log)\n"
            
            // 添加到缓冲区
            self.logBuffer.append(logContent)
            
            // 如果缓冲区达到阈值，执行批量写入
            if self.logBuffer.count >= self.maxBufferSize {
                self.flushBuffer()
            }
        }
    }
    
    deinit {
        logQueue.sync {
            flushBuffer()
            fileHandle?.closeFile()
        }
    }
}
