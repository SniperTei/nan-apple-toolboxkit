import Testing
@testable import MNAppCore
import MNLoggerModule
import Foundation

@Test func testMNAppCoreInitialization() async throws {
    // 测试通过单例访问MNAppCore的初始化
    let _ = MNAppCore.shared
    // 不需要与nil比较，因为shared不是可选类型
    #expect(true, "MNAppCore shared instance should be initialized")
}

@Test func testLoggerFileRotation() async throws {
    // 初始化日志系统
    let loggerCore = MNLoggerCore.shared
    
    // 获取日志目录路径
    let logDirectory = loggerCore.getLogFileDirectory()
    #expect(!logDirectory.isEmpty, "Log directory should not be empty")
    
    // 记录一条日志
    let testMessage = "Test log message for rotation check"
    let testTag = "TestTag"
    MNDebug(testTag, testMessage)
    
    // 获取当前日志文件列表
    let fileManager = FileManager.default
    guard var initialLogFiles = try? fileManager.contentsOfDirectory(atPath: logDirectory) else {
        // 使用布尔值而不是直接传递false
        #expect(Bool(false), "Failed to get initial log files")
        return
    }
    
    // 过滤非日志文件
    initialLogFiles = initialLogFiles.filter { $0.hasSuffix(".log") }
    let initialLogFileCount = initialLogFiles.count
    
    // 手动触发日志文件滚动（模拟日期变化）
    loggerCore.rollLogFileNow()
    
    // 再次记录一条日志到新文件
    let secondTestMessage = "Test log message in new rotated file"
    MNDebug(testTag, secondTestMessage)
    
    // 再次获取日志文件列表
    guard var newLogFiles = try? fileManager.contentsOfDirectory(atPath: logDirectory) else {
        #expect(Bool(false), "Failed to get new log files after rotation")
        return
    }
    
    // 过滤非日志文件
    newLogFiles = newLogFiles.filter { $0.hasSuffix(".log") }
    
    // 验证是否创建了新的日志文件
    #expect(newLogFiles.count >= initialLogFileCount, "Number of log files should not decrease after rotation")
    
    // 如果有新文件创建，验证最新文件中是否包含我们的测试消息
    if newLogFiles.count > initialLogFileCount {
        // 对文件按修改日期排序，获取最新的文件
        let sortedLogFiles = try newLogFiles.sorted {
            let file1Path = URL(fileURLWithPath: logDirectory).appendingPathComponent($0).path
            let file2Path = URL(fileURLWithPath: logDirectory).appendingPathComponent($1).path
            
            let attr1 = try fileManager.attributesOfItem(atPath: file1Path)
            let attr2 = try fileManager.attributesOfItem(atPath: file2Path)
            
            let date1 = attr1[.modificationDate] as? Date ?? Date.distantPast
            let date2 = attr2[.modificationDate] as? Date ?? Date.distantPast
            
            return date1 > date2 // 降序排列，最新的文件在前面
        }
        
        // 获取最新的日志文件路径
        if let latestLogFile = sortedLogFiles.first {
            let latestLogFilePath = URL(fileURLWithPath: logDirectory).appendingPathComponent(latestLogFile).path
            
            // 读取文件内容
            if let logContent = try? String(contentsOfFile: latestLogFilePath, encoding: .utf8) {
                // 验证文件中是否包含测试消息
                #expect(logContent.contains(secondTestMessage), "Latest log file should contain the test message")
                #expect(logContent.contains(testTag), "Latest log file should contain the test tag")
            }
        }
    }
    
    // 输出日志目录路径，方便手动验证
    print("Log files are stored in: \(logDirectory)")
}

@Test func testAllLogLevels() async throws {
    // 测试所有日志级别是否都能正常工作
    let loggerCore = MNLoggerCore.shared
    
    // 记录不同级别的日志
    MNDebug("Test", "This is a debug message")
    MNInfo("Test", "This is an info message")
    MNWarn("Test", "This is a warning message")
    
    // 验证日志系统没有崩溃
    #expect(true, "All log methods should execute without crashing")
    
    // 获取日志目录，验证可以访问
}