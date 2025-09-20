import Foundation
import CocoaLumberjackSwift

/// Custom log formatter
class MNLoggerFormatter: NSObject, DDLogFormatter {
    
    private let dateFormatter: DateFormatter
    
    override init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        dateFormatter.locale = Locale.current
        dateFormatter.timeZone = TimeZone.current
        super.init()
    }
    
    func format(message: DDLogMessage) -> String? {
        // Format date and time
        let timestamp = dateFormatter.string(from: message.timestamp)
        
        // Get log level
        let levelString: String
        switch message.flag {
        case .error:
            levelString = "ERROR"
        case .warning:
            levelString = "WARNING"
        case .info:
            levelString = "INFO"
        case .debug:
            levelString = "DEBUG"
        case .verbose:
            levelString = "VERBOSE"
        default:
            levelString = "UNKNOWN"
        }
        
        // Get thread information
        var threadName: String
        if Thread.isMainThread {
            threadName = "Main"
        } else if let currentThreadName = Thread.current.name, !currentThreadName.isEmpty {
            threadName = currentThreadName
        } else {
            threadName = String(format: "%p", Thread.current)
        }
        
        // Get file name and line number
        let fileInfo: String
        let fileName = message.fileName
        let lineNumber = message.line
        fileInfo = "\(fileName):\(lineNumber)"
        
        // Parse TAG and log content
        let messageString = message.message
        let content = messageString
        
        // Assemble the final log format
        return "[\(timestamp)] [\(levelString)] [\(threadName)] \(fileInfo) - \(content)"
    }
}
