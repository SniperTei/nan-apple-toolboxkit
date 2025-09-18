import Foundation

/// 日志输出协议
protocol LogOutput: Sendable {
    func write(message: String)
}