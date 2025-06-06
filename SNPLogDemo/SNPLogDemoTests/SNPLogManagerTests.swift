import XCTest
@testable import SNPLogDemo

class SNPLogManagerTests: XCTestCase {
    
    private var testLogDirectory: String!
    private var testDeviceId: String!
    private var logManager: SNPLogManager!
    
    override func setUp() {
        super.setUp()
        // 使用 Documents 目录
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        testLogDirectory = (documentsPath as NSString).appendingPathComponent("TestLogs")
        let deviceId = "test_device1"
        testDeviceId = deviceId
        // 确保目录存在
        try? FileManager.default.createDirectory(atPath: testLogDirectory, withIntermediateDirectories: true, attributes: nil)
        print("测试日志目录：\(testLogDirectory!)")
        
        // 初始化日志管理器
        let config = SNPLogConfig(
            logFilePath: testLogDirectory,
            deviceId: deviceId,
            logType: .file
        )
        SNPLogManager.setup(config: config)
        logManager = SNPLogManager.shared
    }
    
    override func tearDown() {
        // 清理测试文件
//        try? FileManager.default.removeItem(atPath: testLogDirectory)
        testLogDirectory = nil
        logManager = nil
        super.tearDown()
    }
    
    // MARK: - 基本功能测试
    
    func testLogFileCreation() {
        // 写入一条测试日志
        SNPLogManager.info("测试日志")
        
        // 验证日志文件是否创建
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fileName = "SNPLog-\(testDeviceId ?? "")-\(dateFormatter.string(from: Date())).log"
        let logFilePath = (testLogDirectory as NSString).appendingPathComponent(fileName)
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: logFilePath), "日志文件应该被创建")
    }
    
    func testLogContent() {
        // 写入测试日志
        let testMessage = "测试日志内容"
        SNPLogManager.info(testMessage)
        
        // 读取日志文件内容
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fileName = "SNPLog-\(testDeviceId ?? "")-\(dateFormatter.string(from: Date())).log"
        let logFilePath = (testLogDirectory as NSString).appendingPathComponent(fileName)
        
        // 等待一小段时间让日志写入（因为并发测试500条都能成功，1秒应该足够）
        Thread.sleep(forTimeInterval: 1.0)
        
        // 读取并验证日志内容
        guard let content = try? String(contentsOfFile: logFilePath, encoding: .utf8) else {
            XCTFail("无法读取日志文件")
            return
        }
        
        // 按行分割并查找包含测试消息的行
        let logLines = content.components(separatedBy: .newlines)
        let matchingLines = logLines.filter { line in
            line.contains(testMessage)
        }
        
        // 打印调试信息
        print("日志文件路径：\(logFilePath)")
        print("总日志行数：\(logLines.count)")
        print("匹配的行数：\(matchingLines.count)")
        if !matchingLines.isEmpty {
            print("匹配的行：")
            matchingLines.forEach { print($0) }
        }
        
        // 验证是否找到日志
        XCTAssertFalse(matchingLines.isEmpty, "应该能找到测试日志")
        
        // 验证日志格式
        if let logLine = matchingLines.first {
            XCTAssertTrue(logLine.contains("[INFO]"), "日志应该包含INFO标记")
            XCTAssertTrue(logLine.contains(testMessage), "日志应该包含测试消息")
        }
    }
    
    func testLogLevels() {
        // 测试不同级别的日志
        SNPLogManager.info("信息日志")
        SNPLogManager.warning("警告日志")
        SNPLogManager.error("错误日志")
        SNPLogManager.network("网络日志")
        
        // 读取日志文件
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fileName = "SNPLog-\(testDeviceId ?? "")-\(dateFormatter.string(from: Date())).log"
        let logFilePath = (testLogDirectory as NSString).appendingPathComponent(fileName)
        
        let content = try? String(contentsOfFile: logFilePath, encoding: .utf8)
        XCTAssertNotNil(content, "应该能够读取日志文件")
        
        // 验证各种日志级别的标记
        XCTAssertTrue(content?.contains("[INFO]") ?? false, "应该包含 INFO 标记")
        XCTAssertTrue(content?.contains("[WARN]") ?? false, "应该包含 WARN 标记")
        XCTAssertTrue(content?.contains("[ERROR]") ?? false, "应该包含 ERROR 标记")
        XCTAssertTrue(content?.contains("[NETWORK]") ?? false, "应该包含 NETWORK 标记")
    }
    
    // MARK: - 性能测试
    
    func testLoggingPerformance() {
        measure {
            // 测试写入1000条日志的性能
            for i in 1...1000 {
                SNPLogManager.info("性能测试日志 #\(i)")
            }
        }
    }
    
    // MARK: - 并发测试
    
    func testConcurrentLogging() {
        let expectation = XCTestExpectation(description: "并发日志写入")
        let group = DispatchGroup()
        
        // 获取日志文件路径
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fileName = "SNPLog-\(testDeviceId ?? "")-\(dateFormatter.string(from: Date())).log"
        let logFilePath = (testLogDirectory as NSString).appendingPathComponent(fileName)
        
        let queues = (0..<5).map { index in
            DispatchQueue(label: "com.test.queue.\(index)")
        }
        
        SNPLogManager.info("test concurrent begin")
        
        for (index, queue) in queues.enumerated() {
            group.enter()
            queue.async {
                // 每个队列写入100条日志
                for i in 1...100 {
                    SNPLogManager.info("CONCURRENT_TEST - 队列\(index) - #\(i)")
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            SNPLogManager.info("test concurrent end - all tasks completed")
            
            // 给一点时间让最后的日志写入
            Thread.sleep(forTimeInterval: 0.5)
            
            // 验证日志文件
            let content = try? String(contentsOfFile: logFilePath, encoding: .utf8)
            let concurrentTestLines = content?.components(separatedBy: .newlines)
                .filter { $0.contains("CONCURRENT_TEST") }
                .count ?? 0
            
            // 验证并发测试的日志数（5个队列 × 100条日志）
            XCTAssertEqual(concurrentTestLines, 500, "并发测试应该写入500条日志")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - 错误处理测试
    
    func testInvalidDirectory() {
        // 测试无效目录
        let invalidConfig = SNPLogConfig(
            logFilePath: "/invalid/path",
            deviceId: "test_device",
            logType: .file
        )
        
        SNPLogManager.setup(config: invalidConfig)
        // 应该能优雅地处理错误，不会崩溃
        SNPLogManager.info("测试日志")
    }
    
    func testFileHandleRecovery() {
        // 写入初始日志
        let initialMessage = "初始日志"
        SNPLogManager.info(initialMessage)
        
        // 模拟文件句柄失效（删除日志文件）
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fileName = "SNPLog-\(testDeviceId ?? "")-\(dateFormatter.string(from: Date())).log"
        let logFilePath = (testLogDirectory as NSString).appendingPathComponent(fileName)
        
        // 记录原始文件内容
        let originalContent = try? String(contentsOfFile: logFilePath, encoding: .utf8)
        
        // 写入新日志
        let recoveryMessage = "恢复测试日志"
        SNPLogManager.info(recoveryMessage)
        
        // 验证日志内容
        let newContent = try? String(contentsOfFile: logFilePath, encoding: .utf8)
        XCTAssertNotNil(newContent, "应该能够读取日志文件")
        XCTAssertTrue(newContent?.contains(initialMessage) ?? false, "应该包含初始日志")
        XCTAssertTrue(newContent?.contains(recoveryMessage) ?? false, "应该包含恢复测试日志")
    }
} 
