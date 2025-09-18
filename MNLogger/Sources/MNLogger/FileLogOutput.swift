import Foundation

/// 文件日志输出实现
class FileLogOutput: LogOutput, @unchecked Sendable {
    private let queue = DispatchQueue(label: "com.mnlogger.fileOutput", qos: .background)
    private var logFileHandle: FileHandle?
    private var currentLogDate: Date?
    private let fileManager = FileManager.default
    private let logDirectoryPath: String
    
    /// 初始化文件日志输出器
    /// - Parameter logDirectoryPath: 日志文件保存目录路径
    init(logDirectoryPath: String? = nil) {
        if let providedPath = logDirectoryPath {
            self.logDirectoryPath = providedPath
        } else {
            // 默认保存在应用沙盒的Logs目录下
            let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            self.logDirectoryPath = "\(documentDirectory)/Logs"
        }
        
        // 确保日志目录存在
        createLogDirectoryIfNeeded()
        
        // 初始化日志文件
        initializeLogFile()
        
        // 监听日期变化，以便在日期变更时创建新的日志文件
        scheduleDateChangeCheck()
    }
    
    private func createLogDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: logDirectoryPath) {
            do {
                try fileManager.createDirectory(atPath: logDirectoryPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Failed to create log directory: \(error)")
            }
        }
    }
    
    private func initializeLogFile() {
        queue.sync {
            let today = Date()
            let logFilePath = self.logFilePath(for: today)
            
            // 如果日志文件不存在，创建新文件
            if !fileManager.fileExists(atPath: logFilePath) {
                fileManager.createFile(atPath: logFilePath, contents: nil, attributes: nil)
            }
            
            // 打开日志文件以便追加内容
            do {
                logFileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: logFilePath))
                logFileHandle?.seekToEndOfFile()
                currentLogDate = today
            } catch {
                print("Failed to open log file: \(error)")
                logFileHandle = nil
            }
        }
    }
    
    private func logFilePath(for date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        return "\(logDirectoryPath)/log-\(dateString).log"
    }
    
    private func scheduleDateChangeCheck() {
        // 计算距离下一天开始的时间间隔
        let now = Date()
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else {
            return
        }
        
        let components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        guard let nextDayStart = calendar.date(from: components) else {
            return
        }
        
        let timeInterval = nextDayStart.timeIntervalSince(now)
        
        // 设置定时器，在日期变更时创建新的日志文件
        DispatchQueue.global().asyncAfter(deadline: .now() + timeInterval) {
            [weak self] in
            self?.initializeLogFile()
            self?.scheduleDateChangeCheck() // 继续监听下一次日期变更
        }
    }
    
    func write(message: String) {
        queue.async {
            [weak self] in
            // 检查日期是否变更，如果变更则重新初始化日志文件
            guard let self = self else { return }
            let today = Date()
            let calendar = Calendar.current
            if let currentDate = self.currentLogDate, !calendar.isDate(currentDate, inSameDayAs: today) {
                self.initializeLogFile()
            }
            
            // 将日志消息写入文件
            if let data = (message + "\n").data(using: .utf8) {
                self.logFileHandle?.write(data)
                // 刷新缓冲区到磁盘，确保日志不会丢失
                self.logFileHandle?.synchronizeFile()
            }
        }
    }
    
    deinit {
        logFileHandle?.closeFile()
    }
}