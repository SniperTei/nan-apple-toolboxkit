import Foundation

/// 日志格式化协议
protocol LogFormatter: Sendable {
    func format(logLevel: LogLevel, message: String, file: String, function: String, line: Int) -> String
}

/// 默认日志格式化实现
class DefaultLogFormatter: LogFormatter, @unchecked Sendable {
    func format(logLevel: LogLevel, message: String, file: String, function: String, line: Int) -> String {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let fileName = (file as NSString).lastPathComponent
        return "[\(timestamp)] [\(logLevel.rawValue)] [\(fileName):\(line)] \(function): \(message)"
    }
}