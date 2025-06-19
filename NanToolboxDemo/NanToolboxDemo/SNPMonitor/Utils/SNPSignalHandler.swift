import Foundation

// 全局变量用于存储信号处理器
private var globalSignalHandler: ((Int32) -> Void)?

// 全局信号处理函数
private func signalHandler(signal: Int32, info: UnsafeMutablePointer<__siginfo>?, context: UnsafeMutableRawPointer?) {
    globalSignalHandler?(signal)
    
    // 恢复默认信号处理
    var defaultAction = sigaction()
    sigaction(signal, &defaultAction, nil)
    kill(getpid(), signal)
}

public class SNPSignalHandler {
    public static let shared = SNPSignalHandler()
    
    private init() {}
    
    public func setupSignalHandler(handler: @escaping (Int32) -> Void) {
        globalSignalHandler = handler
        let signals = [SIGABRT, SIGILL, SIGSEGV, SIGFPE, SIGBUS, SIGPIPE, SIGTRAP]
        
        signals.forEach { signal in
            var action = sigaction()
            action.__sigaction_u.__sa_sigaction = signalHandler
            action.sa_flags = SA_SIGINFO
            sigaction(signal, &action, nil)
        }
    }
    
    public func removeSignalHandler() {
        globalSignalHandler = nil
        let signals = [SIGABRT, SIGILL, SIGSEGV, SIGFPE, SIGBUS, SIGPIPE, SIGTRAP]
        signals.forEach { signal in
            var defaultAction = sigaction()
            sigaction(signal, &defaultAction, nil)
        }
    }
} 