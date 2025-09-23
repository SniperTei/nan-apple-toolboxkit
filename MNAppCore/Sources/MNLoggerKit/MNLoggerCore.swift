import Foundation
import CocoaLumberjackSwift

// 确保 MNLoggerCore 类标记为 public
public class MNLoggerCore: @unchecked Sendable {
    public static let shared = MNLoggerCore()
    
    public init() {
        // 初始化日志记录器
        setupLoggers()
    }

    // 移除错误的通知监听代码并添加正确的实现
    
    // 修改 rollLogFileNow 方法，添加 @objc 标记使其可被用作选择器
    @objc public func rollLogFileNow() {
        if let fileLogger = DDLog.allLoggers.first(where: { $0 is DDFileLogger }) as? DDFileLogger {
            // 使用非弃用的方法并添加完成块
            fileLogger.rollLogFile(withCompletion: nil)
        }
    }
    
    // 修改 setupLoggers 方法中的通知监听代码
    private func setupLoggers() {
        // 清除所有已存在的日志器
        DDLog.removeAllLoggers()
        
        // File Logger - 配置每日日志文件
        let fileLogger: DDFileLogger = DDFileLogger()
        
        // 设置日志文件滚动频率为24小时
        fileLogger.rollingFrequency = 60 * 60 * 24 // 24小时
        
        // 设置日志文件最大大小（可选，当日志增长过快时也会触发滚动）
        fileLogger.maximumFileSize = 1024 * 1024 * 10 // 10MB
        
        // 设置日志文件的最大数量
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        
        // 设置日志文件的格式（如果需要自定义文件名格式）
        let logFileManager = fileLogger.logFileManager as! DDLogFileManagerDefault
        logFileManager.logFilesDiskQuota = 1024 * 1024 * 100 // 100MB 磁盘配额
        
        // 添加文件日志器
        DDLog.add(fileLogger)
        
        // Console Logger - 控制台日志
        let consoleLogger: DDOSLogger = DDOSLogger.sharedInstance
        DDLog.add(consoleLogger)
    
        // 监听系统时钟变化，自动触发日志滚动
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(rollLogFileNow),
            name: .NSSystemClockDidChange,
            object: nil
        )
    }
    
    /// 获取日志文件存储路径
    public func getLogFileDirectory() -> String {
        if let fileLogger = DDLog.allLoggers.first(where: { $0 is DDFileLogger }) as? DDFileLogger {
            let logFileManager = fileLogger.logFileManager as! DDLogFileManagerDefault
            return logFileManager.logsDirectory
        }
        return ""
    }
}

public func MNDebug(_ tag: String = "", _ message: String) {
    DDLogDebug("[\(tag)] - \(message)")
}

public func MNInfo(_ tag: String = "", _ message: String) {
    DDLogInfo("[\(tag)] - \(message)")
}

public func MNWarn(_ tag: String = "", _ message: String) {
    DDLogWarn("[\(tag)] - \(message)")
}
