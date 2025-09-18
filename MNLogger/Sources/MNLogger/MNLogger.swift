import Foundation

// 导入C语言日志核心
import MNLoggerCore

/// 日志级别枚举
public enum LogLevel: Sendable {
    case debug
    case info
    case warning
    case error
    case fatal
}

/// MNLogger主类 - 高性能、线程安全的日志组件
public class MNLogger: @unchecked Sendable {
    /// 单例实例
    public static let shared = MNLogger()  // 移除@MainActor标记
    
    /// 初始化MNLogger
    private init() {
        // 获取文档目录
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let logFilePath = documentsDirectory.appendingPathComponent("app.log").path
        
        // 初始化C语言日志核心，设置较大的缓冲区以提高性能
        mn_logger_init(logFilePath, 10000)
        
        // 注册应用退出时的清理函数
        atexit { mn_logger_close() }
    }
    
    /// 设置最小日志级别
    /// - Parameter level: 最小日志级别
    public func setMinimumLogLevel(_ level: LogLevel) {
        // 转换为C语言的日志级别并设置
        let cLevel: MNLogLevel
        switch level {
        case .debug: cLevel = MN_LOG_LEVEL_DEBUG
        case .info: cLevel = MN_LOG_LEVEL_INFO
        case .warning: cLevel = MN_LOG_LEVEL_WARNING
        case .error: cLevel = MN_LOG_LEVEL_ERROR
        case .fatal: cLevel = MN_LOG_LEVEL_FATAL
        }
        
        mn_logger_set_min_level(cLevel)
    }
    
    /// 记录调试日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - file: 文件名，自动填充
    ///   - function: 函数名，自动填充
    ///   - line: 行号，自动填充
    public func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        mn_logger_write(MN_LOG_LEVEL_DEBUG, message, file, function, Int32(line))
    }
    
    /// 记录信息日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - file: 文件名，自动填充
    ///   - function: 函数名，自动填充
    ///   - line: 行号，自动填充
    public func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        mn_logger_write(MN_LOG_LEVEL_INFO, message, file, function, Int32(line))
    }
    
    /// 记录警告日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - file: 文件名，自动填充
    ///   - function: 函数名，自动填充
    ///   - line: 行号，自动填充
    public func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        mn_logger_write(MN_LOG_LEVEL_WARNING, message, file, function, Int32(line))
    }
    
    /// 记录错误日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - file: 文件名，自动填充
    ///   - function: 函数名，自动填充
    ///   - line: 行号，自动填充
    public func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        mn_logger_write(MN_LOG_LEVEL_ERROR, message, file, function, Int32(line))
    }
    
    /// 记录严重错误日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - file: 文件名，自动填充
    ///   - function: 函数名，自动填充
    ///   - line: 行号，自动填充
    public func fatal(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {  // 将 critical 改为 fatal
        mn_logger_write(MN_LOG_LEVEL_FATAL, message, file, function, Int32(line))
    }
    
    /// 立即刷新所有待写入的日志到文件
    public func flush() {
        mn_logger_flush()
    }
}