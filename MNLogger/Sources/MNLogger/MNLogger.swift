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

/// 日志输出目标枚举
public enum LogOutput: Sendable {
    case console  // 仅输出到控制台
    case file     // 仅输出到文件
    case both     // 同时输出到控制台和文件
}

/// MNLogger主类 - 高性能、线程安全的日志组件
public class MNLogger: @unchecked Sendable {
    /// 单例实例
    public static let shared = MNLogger()  // 移除@MainActor标记
    
    // 当前日志文件的日期
    private var currentLogDate: String
    // 日志文件目录
    private let logDirectory: URL
    // 当前日志输出目标
    private var logOutput: LogOutput = .file // 默认只输出到文件
    
    /// 获取日志文件目录的只读访问
    public var logDirectoryURL: URL {
        return logDirectory
    }
    
    /// 初始化MNLogger
    private init() {
        // 1. 先初始化所有存储属性
        self.logDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as URL
        
        // 2. 使用静态方法获取当前日期（避免在所有属性初始化前使用self）
        let currentDate = Self.getCurrentDateStringStatic()
        self.currentLogDate = currentDate
        
        // 初始化日志文件
        let logFilePath = self.getLogFilePath(for: self.currentLogDate)
        
        // 初始化C语言日志核心，设置较大的缓冲区以提高性能
        mn_logger_init(logFilePath, 10000)
        
        // 注册应用退出时的清理函数
        atexit { 
            // 确保在应用退出时先刷新日志，再关闭
            mn_logger_flush()
            mn_logger_close()
        }
    }
    
    // 静态方法：获取当前日期的字符串表示（格式：YYYY-MM-DD）
    private static func getCurrentDateStringStatic() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: Date())
    }
    
    // 实例方法：获取当前日期的字符串表示（格式：YYYY-MM-DD）
    private func getCurrentDateString() -> String {
        return Self.getCurrentDateStringStatic()
    }
    
    // 获取指定日期的日志文件路径
    private func getLogFilePath(for date: String) -> String {
        let logFileName = "app_\(date).log"
        return logDirectory.appendingPathComponent(logFileName).path
    }
    
    // 检查并处理日期变化
    private func checkDateChange() {
        let newDate = self.getCurrentDateString()
        if newDate != self.currentLogDate {
            // 日期变化，先刷新当前日志
            self.flush()
            
            // 更新日期并创建新的日志文件
            self.currentLogDate = newDate
            let newLogFilePath = self.getLogFilePath(for: newDate)
            
            // 重新初始化C语言日志核心，指向新的日志文件
            mn_logger_close()
            mn_logger_init(newLogFilePath, 10000)
        }
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
        checkDateChange()
        
        // 根据输出目标决定输出方式
        switch logOutput {
        case .console:
            printToConsole(level: .debug, message: message, file: file, function: function, line: line)
        case .file:
            mn_logger_write(MN_LOG_LEVEL_DEBUG, message, file, function, Int32(line))
        case .both:
            printToConsole(level: .debug, message: message, file: file, function: function, line: line)
            mn_logger_write(MN_LOG_LEVEL_DEBUG, message, file, function, Int32(line))
        }
    }
    
    // 其他日志方法(info, warning, error, fatal)也需要类似修改
    
    /// 记录信息日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - file: 文件名，自动填充
    ///   - function: 函数名，自动填充
    ///   - line: 行号，自动填充
    public func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        checkDateChange()
        
        // 根据输出目标决定输出方式
        switch logOutput {
        case .console:
            printToConsole(level: .info, message: message, file: file, function: function, line: line)
        case .file:
            mn_logger_write(MN_LOG_LEVEL_INFO, message, file, function, Int32(line))
        case .both:
            printToConsole(level: .info, message: message, file: file, function: function, line: line)
            mn_logger_write(MN_LOG_LEVEL_INFO, message, file, function, Int32(line))
        }
    }
    
    /// 记录警告日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - file: 文件名，自动填充
    ///   - function: 函数名，自动填充
    ///   - line: 行号，自动填充
    public func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        checkDateChange()
        
        // 根据输出目标决定输出方式
        switch logOutput {
        case .console:
            printToConsole(level: .warning, message: message, file: file, function: function, line: line)
        case .file:
            mn_logger_write(MN_LOG_LEVEL_WARNING, message, file, function, Int32(line))
        case .both:
            printToConsole(level: .warning, message: message, file: file, function: function, line: line)
            mn_logger_write(MN_LOG_LEVEL_WARNING, message, file, function, Int32(line))
        }
    }
    
    /// 记录错误日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - file: 文件名，自动填充
    ///   - function: 函数名，自动填充
    ///   - line: 行号，自动填充
    public func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        checkDateChange()
        
        // 根据输出目标决定输出方式
        switch logOutput {
        case .console:
            printToConsole(level: .error, message: message, file: file, function: function, line: line)
        case .file:
            mn_logger_write(MN_LOG_LEVEL_ERROR, message, file, function, Int32(line))
        case .both:
            printToConsole(level: .error, message: message, file: file, function: function, line: line)
            mn_logger_write(MN_LOG_LEVEL_ERROR, message, file, function, Int32(line))
        }
    }
    
    /// 记录严重错误日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - file: 文件名，自动填充
    ///   - function: 函数名，自动填充
    ///   - line: 行号，自动填充
    public func fatal(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        checkDateChange()
        
        // 根据输出目标决定输出方式
        switch logOutput {
        case .console:
            printToConsole(level: .fatal, message: message, file: file, function: function, line: line)
        case .file:
            mn_logger_write(MN_LOG_LEVEL_FATAL, message, file, function, Int32(line))
        case .both:
            printToConsole(level: .fatal, message: message, file: file, function: function, line: line)
            mn_logger_write(MN_LOG_LEVEL_FATAL, message, file, function, Int32(line))
        }
        
        // 对于严重错误，立即刷新日志以确保记录不丢失
        flush()
    }
    
    /// 立即刷新所有待写入的日志到文件（内部使用）
    private func flush() {
        mn_logger_flush()
    }
    
    // MARK: - 静态日志方法
    
    /// 静态方法 - 记录调试日志
    public static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.debug(message, file: file, function: function, line: line)
    }
    
    // 其他静态日志方法也需要更新
    
    /// 静态方法 - 设置日志输出目标
    public static func setLogOutput(_ output: LogOutput) {
        shared.setLogOutput(output)
    }
    
    /// 静态方法 - 记录信息日志
    public static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.info(message, file: file, function: function, line: line)
    }
    
    /// 静态方法 - 记录警告日志
    public static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.warning(message, file: file, function: function, line: line)
    }
    
    /// 静态方法 - 记录错误日志
    public static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.error(message, file: file, function: function, line: line)
    }
    
    /// 静态方法 - 记录严重错误日志
    public static func fatal(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.fatal(message, file: file, function: function, line: line)
    }
    
    /// 静态方法 - 设置最小日志级别
    public static func setMinimumLogLevel(_ level: LogLevel) {
        shared.setMinimumLogLevel(level)
    }
    
    /// 设置日志输出目标
    /// - Parameter output: 日志输出目标
    public func setLogOutput(_ output: LogOutput) {
        self.logOutput = output
    }
    
    // 控制台输出辅助方法
    private func printToConsole(level: LogLevel, message: String, file: String, function: String, line: Int) {
        // 获取当前时间
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let currentTime = dateFormatter.string(from: Date())
        
        // 获取线程信息
        let threadName = Thread.current.name ?? "Main"
        
        // 获取日志级别字符串
        let levelStr: String
        switch level {
        case .debug: levelStr = "DEBUG"
        case .info: levelStr = "INFO"
        case .warning: levelStr = "WARNING"
        case .error: levelStr = "ERROR"
        case .fatal: levelStr = "FATAL"
        }
        
        // 从文件路径中提取简单文件名
        let simpleFileName = (file as NSString).lastPathComponent
        
        // 打印到控制台，格式与文件日志保持一致
        print("[\(currentTime)] [\(levelStr)] [Thread:\(threadName)] [\(simpleFileName):\(line)] - \(message)")
    }
}