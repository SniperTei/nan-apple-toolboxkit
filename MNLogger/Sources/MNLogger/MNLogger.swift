import Foundation

/// MNLogger主类
class MNLogger: @unchecked Sendable {
    @MainActor static let shared = MNLogger()
    
    private let queue = DispatchQueue(label: "com.mnlogger", qos: .background, attributes: .concurrent)
    private var outputs: [LogOutput] = []
    private var formatter: LogFormatter = DefaultLogFormatter()
    private var minimumLogLevel: LogLevel = .debug
    
    /// 初始化MNLogger
    private init() {
        // 默认添加控制台输出
        // addOutput(ConsoleLogOutput())
        addOutput(FileLogOutput())
    }
    
    /// 添加日志输出目标
    /// - Parameter output: 实现了LogOutput协议的输出目标
    func addOutput(_ output: LogOutput) {
        queue.async(flags: .barrier) {
            [weak self] in
            guard let self = self else { return }
            self.outputs.append(output)
        }
    }
    
    /// 设置日志格式化器
    /// - Parameter formatter: 实现了LogFormatter协议的格式化器
    func setFormatter(_ formatter: LogFormatter) {
        queue.async(flags: .barrier) {
            [weak self] in
            guard let self = self else { return }
            self.formatter = formatter
        }
    }
    
    /// 设置最小日志级别
    /// - Parameter level: 最小日志级别
    func setMinimumLogLevel(_ level: LogLevel) {
        queue.async(flags: .barrier) {
            [weak self] in
            guard let self = self else { return }
            self.minimumLogLevel = level
        }
    }
    
    /// 记录调试日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - file: 文件名，自动填充
    ///   - function: 函数名，自动填充
    ///   - line: 行号，自动填充
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .debug, message: message, file: file, function: function, line: line)
    }
    
    /// 记录信息日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - file: 文件名，自动填充
    ///   - function: 函数名，自动填充
    ///   - line: 行号，自动填充
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, message: message, file: file, function: function, line: line)
    }
    
    /// 记录警告日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - file: 文件名，自动填充
    ///   - function: 函数名，自动填充
    ///   - line: 行号，自动填充
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .warning, message: message, file: file, function: function, line: line)
    }
    
    /// 记录错误日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - file: 文件名，自动填充
    ///   - function: 函数名，自动填充
    ///   - line: 行号，自动填充
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .error, message: message, file: file, function: function, line: line)
    }
    
    /// 记录严重错误日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - file: 文件名，自动填充
    ///   - function: 函数名，自动填充
    ///   - line: 行号，自动填充
    func critical(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .critical, message: message, file: file, function: function, line: line)
    }
    
    /// 通用日志记录方法
    /// - Parameters:
    ///   - level: 日志级别
    ///   - message: 日志消息
    ///   - file: 文件名
    ///   - function: 函数名
    ///   - line: 行号
    private func log(level: LogLevel, message: String, file: String, function: String, line: Int) {
        // 检查日志级别是否满足最小日志级别要求
        queue.sync {
            [weak self] in
            guard let self = self else { return }
            if self.shouldLog(level: level) {
                let formattedMessage = self.formatter.format(logLevel: level, message: message, file: file, function: function, line: line)
                
                // 向所有输出目标写入日志
                for output in self.outputs {
                    output.write(message: formattedMessage)
                }
            }
        }
    }
    
    private func shouldLog(level: LogLevel) -> Bool {
        // 定义日志级别优先级
        let levelPriority: [LogLevel: Int] = [
            .debug: 0,
            .info: 1,
            .warning: 2,
            .error: 3,
            .critical: 4
        ]
        
        guard let levelValue = levelPriority[level], let minLevelValue = levelPriority[minimumLogLevel] else {
            return false
        }
        
        return levelValue >= minLevelValue
    }
}