import Foundation

// 全局变量用于存储崩溃监控器实例
private var globalCrashMonitor: SNPCrashMonitor?

// 全局异常处理函数
private func globalExceptionHandler(exception: NSException) {
    globalCrashMonitor?.handleException(exception)
}

// MARK: - 崩溃监控器
public class SNPCrashMonitor {
    public static let shared = SNPCrashMonitor()
    
    public weak var delegate: SNPUncaughtExceptionHandlerDelegate?
    private var isMonitoring = false
    
    private init() {}
    
    public func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        // 记录监控启动日志
        SNPLogManager.shared.writeLog(
            log: "崩溃监控器已启动",
            type: .info,
            file: #file,
            function: #function,
            line: #line
        )
        
        // 设置全局引用
        globalCrashMonitor = self
        
        // 设置未捕获异常处理器
        NSSetUncaughtExceptionHandler(globalExceptionHandler)
        
        // 设置信号处理器
        SNPSignalHandler.shared.setupSignalHandler { [weak self] signal in
            self?.handleSignal(signal)
        }
    }
    
    public func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        
        // 记录监控停止日志
        SNPLogManager.shared.writeLog(
            log: "崩溃监控器已停止",
            type: .info,
            file: #file,
            function: #function,
            line: #line
        )
        
        // 清除全局引用
        globalCrashMonitor = nil
        
        // 移除异常处理器
        NSSetUncaughtExceptionHandler(nil)
        
        // 移除信号处理器
        SNPSignalHandler.shared.removeSignalHandler()
    }
    
    internal func handleException(_ exception: NSException) {
        // 记录异常崩溃日志
        let exceptionLog = """
        捕获到异常崩溃:
        - 异常名称: \(exception.name.rawValue)
        - 异常原因: \(exception.reason ?? "未知原因")
        - 调用栈: \(exception.callStackSymbols.joined(separator: "\n"))
        """
        
        SNPLogManager.shared.writeLog(
            log: exceptionLog,
            type: .crash,
            file: #file,
            function: #function,
            line: #line
        )
        
        let crash = SNPCrashModel(
            type: .exception(exception),
            name: exception.name.rawValue,
            reason: exception.reason ?? "Unknown reason",
            callStackSymbols: exception.callStackSymbols,
            timestamp: Date().timeIntervalSince1970,
            deviceInfo: .current
        )
        
        delegate?.crashMonitor(self, didCatchCrash: crash)
    }
    
    private func handleSignal(_ signal: Int32) {
        // 记录信号崩溃日志
        let signalLog = """
        捕获到信号崩溃:
        - 信号类型: \(signal)
        - 信号描述: \(getSignalDescription(signal))
        - 调用栈: \(Thread.callStackSymbols.joined(separator: "\n"))
        """
        
        SNPLogManager.shared.writeLog(
            log: signalLog,
            type: .crash,
            file: #file,
            function: #function,
            line: #line
        )
        
        let crash = SNPCrashModel(
            type: .signal(signal),
            name: "Signal",
            reason: "Signal \(signal)",
            callStackSymbols: Thread.callStackSymbols,
            timestamp: Date().timeIntervalSince1970,
            deviceInfo: .current
        )
        
        delegate?.crashMonitor(self, didCatchCrash: crash)
    }
    
    // 获取信号描述
    private func getSignalDescription(_ signal: Int32) -> String {
        switch signal {
        case SIGABRT:
            return "SIGABRT - 程序异常终止"
        case SIGILL:
            return "SIGILL - 非法指令"
        case SIGSEGV:
            return "SIGSEGV - 段错误"
        case SIGFPE:
            return "SIGFPE - 浮点异常"
        case SIGBUS:
            return "SIGBUS - 总线错误"
        case SIGPIPE:
            return "SIGPIPE - 管道破裂"
        case SIGTRAP:
            return "SIGTRAP - 跟踪陷阱"
        default:
            return "未知信号"
        }
    }
    
    // 记录崩溃信息的辅助方法
    public func logCrashInfo(_ info: [String: Any]) {
        let crashInfoLog = """
        崩溃信息记录:
        \(info.map { "- \($0.key): \($0.value)" }.joined(separator: "\n"))
        """
        
        SNPLogManager.shared.writeLog(
            log: crashInfoLog,
            type: .error,
            file: #file,
            function: #function,
            line: #line
        )
    }
} 