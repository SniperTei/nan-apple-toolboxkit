import Foundation
import CCode

/// 日志级别枚举
enum LogLevel: String, Sendable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
}

/// 日志写入器类，封装C语言实现
public class SNPLogger: @unchecked Sendable {
    private var logger: UnsafeMutableRawPointer?
    private let queue: DispatchQueue
    private let dateFormatter: DateFormatter
    
    /// 初始化日志写入器
    /// - Parameter filePath: 日志文件路径
    public init?(filePath: String) {
        queue = DispatchQueue(label: "com.snplog.logger", attributes: .concurrent)
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        // 调用C函数创建日志写入器
        logger = snp_log_create(filePath)
        
        if logger == nil {
            return nil
        }
    }
    
    deinit {
        if let logger = logger {
            snp_log_destroy(logger)
        }
    }
    
    /// 写入调试日志
    /// - Parameter message: 日志消息
    public func debug(_ message: String) {
        log(level: .debug, message: message)
    }
    
    /// 写入信息日志
    /// - Parameter message: 日志消息
    public func info(_ message: String) {
        log(level: .info, message: message)
    }
    
    /// 写入警告日志
    /// - Parameter message: 日志消息
    public func warning(_ message: String) {
        log(level: .warning, message: message)
    }
    
    /// 写入错误日志
    /// - Parameter message: 日志消息
    public func error(_ message: String) {
        log(level: .error, message: message)
    }
    
    /// 刷新缓冲区到文件
    public func flush() {
        guard let logger = logger else { return }
        
        queue.sync {
            snp_log_flush(logger)
        }
    }
    
    private func log(level: LogLevel, message: String) {
        guard let logger = logger else { return }
        
        let timestamp = dateFormatter.string(from: Date())
        let threadName = Thread.current.name ?? "Unknown"
        let logMessage = "[\(timestamp)] [\(level.rawValue)] [\(threadName)] \(message)\n"
        
        queue.sync(flags: .barrier) {
            if let data = logMessage.data(using: .utf8) {
                _ = data.withUnsafeBytes { buffer in
                    snp_log_write(logger, buffer.baseAddress?.assumingMemoryBound(to: Int8.self), data.count)
                }
            }
        }
    }
}

/// 全局日志实例，方便快速使用
@MainActor public let SNPLog = {
    let tempDir = FileManager.default.temporaryDirectory
    let logFilePath = tempDir.appendingPathComponent("snp_log_default.log").path
    return SNPLogger(filePath: logFilePath) ?? {
        fatalError("Failed to initialize SNPLog")
    }()
}()