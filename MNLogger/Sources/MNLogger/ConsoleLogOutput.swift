import Foundation

/// 控制台日志输出实现
class ConsoleLogOutput: LogOutput, @unchecked Sendable {
    private let queue = DispatchQueue(label: "com.mnlogger.consoleOutput")
    
    func write(message: String) {
        queue.async {
            print(message)
        }
    }
}