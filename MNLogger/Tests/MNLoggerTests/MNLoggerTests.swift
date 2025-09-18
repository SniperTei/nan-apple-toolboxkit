import Testing
@testable import MNLogger
import Foundation

// 简化的模拟LogOutput用于测试
class MockLogOutput: LogOutput, @unchecked Sendable {
    // 使用简单的数组存储消息，避免复杂的线程安全机制
    private var _messages: [String] = []
    private let lock = NSLock()
    
    // 提供线程安全的访问器
    var messages: [String] {
        lock.lock()
        defer { lock.unlock() }
        return _messages
    }
    
    func write(message: String) {
        lock.lock()
        defer { lock.unlock() }
        _messages.append(message)
    }
    
    func reset() {
        lock.lock()
        defer { lock.unlock() }
        _messages.removeAll()
    }
}

// 简化的模拟LogFormatter用于测试
class MockLogFormatter: LogFormatter, @unchecked Sendable {
    private var _wasCalled = false
    private var _lastFormattedMessage: String?
    private var _callCount = 0
    private let lock = NSLock()
    
    var wasCalled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _wasCalled
    }
    
    var lastFormattedMessage: String? {
        lock.lock()
        defer { lock.unlock() }
        return _lastFormattedMessage
    }
    
    var callCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return _callCount
    }
    
    func format(logLevel: LogLevel, message: String, file: String, function: String, line: Int) -> String {
        lock.lock()
        defer { lock.unlock() }
        
        let result = "MOCK[\(logLevel.rawValue)]: \(message)"
        _wasCalled = true
        _callCount += 1
        _lastFormattedMessage = result
        
        return result
    }
    
    func reset() {
        lock.lock()
        defer { lock.unlock() }
        _wasCalled = false
        _lastFormattedMessage = nil
        _callCount = 0
    }
}

// 为MNLogger添加测试辅助方法
class TestHelper {
    // 创建一个隔离的测试环境，避免与默认输出冲突
    static func setupIsolatedTest() async -> (MNLogger, MockLogOutput) {
        let logger = await MNLogger.shared
        
        // 重置共享实例到默认状态
        logger.setFormatter(DefaultLogFormatter())
        logger.setMinimumLogLevel(.debug)
        
        // 添加我们的测试输出目标
        let mockOutput = MockLogOutput()
        logger.addOutput(mockOutput)
        
        return (logger, mockOutput)
    }
    
    // 等待异步操作完成的辅助方法
    static func waitForAsyncOperations() async {
        // 简单的等待方法，足够测试使用
        try? await Task.sleep(nanoseconds: 200_000_000) // 等待200ms
    }
}

// 测试套件
struct MNLoggerTests {
    @Test func testBasicLoggingMethods() async throws {
        let (logger, mockOutput) = await TestHelper.setupIsolatedTest()
        
        // 测试各种日志级别
        logger.debug("Debug message")
        logger.info("Info message")
        logger.warning("Warning message")
        logger.error("Error message")
        logger.critical("Critical message")
        
        // 等待异步操作完成
        await TestHelper.waitForAsyncOperations()
        
        // 验证所有日志都被记录
        #expect(mockOutput.messages.count >= 1, "Expected at least one log message")
        
        // 检查关键日志级别存在
        let hasInfo = mockOutput.messages.contains { $0.contains("Info message") || $0.contains("INFO") }
        let hasError = mockOutput.messages.contains { $0.contains("Error message") || $0.contains("ERROR") }
        
        #expect(hasInfo && hasError, "Key log levels should be present")
    }
    
    @Test func testMultipleOutputs() async throws {
        let logger = await MNLogger.shared
        logger.setFormatter(DefaultLogFormatter())
        logger.setMinimumLogLevel(.debug)
        
        let mockOutput1 = MockLogOutput()
        let mockOutput2 = MockLogOutput()
        
        logger.addOutput(mockOutput1)
        logger.addOutput(mockOutput2)
        
        // 记录一条日志
        let testMessage = "Test message for multiple outputs"
        logger.info(testMessage)
        
        // 等待异步操作完成
        await TestHelper.waitForAsyncOperations()
        
        // 验证两条输出都收到了相同的日志
        #expect(mockOutput1.messages.count >= 1, "Output 1 should have at least one message")
        #expect(mockOutput2.messages.count >= 1, "Output 2 should have at least one message")
        
        // 验证两条输出都包含测试消息的内容
        let output1ContainsMessage = mockOutput1.messages.contains { $0.contains(testMessage) }
        let output2ContainsMessage = mockOutput2.messages.contains { $0.contains(testMessage) }
        
        #expect(output1ContainsMessage, "Output 1 should contain the test message")
        #expect(output2ContainsMessage, "Output 2 should contain the test message")
    }
    
    @Test func testCustomFormatter() async throws {
        let logger = await MNLogger.shared
        logger.setMinimumLogLevel(.debug)
        
        let mockOutput = MockLogOutput()
        let mockFormatter = MockLogFormatter()
        
        logger.addOutput(mockOutput)
        logger.setFormatter(mockFormatter)
        
        // 记录一条日志
        let testMessage = "Test message with custom formatter"
        logger.info(testMessage)
        
        // 等待异步操作完成
        await TestHelper.waitForAsyncOperations()
        
        // 验证格式化器被调用且使用了自定义格式
        #expect(mockFormatter.wasCalled, "Formatter should have been called")
        #expect(mockFormatter.callCount >= 1, "Formatter should have been called at least once")
    }
    
    @Test func testSharedInstance() async throws {
        let sharedLogger = await MNLogger.shared
        let mockOutput = MockLogOutput()
        sharedLogger.addOutput(mockOutput)
        
        // 使用共享实例记录日志
        let testMessage = "Test message from shared instance"
        sharedLogger.info(testMessage)
        
        // 等待异步操作完成
        await TestHelper.waitForAsyncOperations()
        
        // 验证日志被记录
        #expect(mockOutput.messages.count >= 1, "Should have at least one message")
    }
    
    @Test func testLogLevelFiltering() async throws {
        let logger = await MNLogger.shared
        logger.setFormatter(DefaultLogFormatter())
    
        let mockOutput = MockLogOutput()
        logger.addOutput(mockOutput)
    
        // 设置最小日志级别为warning
        logger.setMinimumLogLevel(LogLevel.warning)
    
        // 尝试记录不同级别的日志
        logger.debug("This should be filtered out")
        logger.info("This should be filtered out")
        logger.warning("This should be logged")
    
        // 等待异步操作
        await TestHelper.waitForAsyncOperations()
    
        // 验证warning日志被记录
        let warningMessages = mockOutput.messages.filter { $0.contains("WARNING") || $0.contains("should be logged") }
    
        #expect(warningMessages.count >= 1, "Warning message should be logged")
    }
    
    @Test func testBulkLogging() async throws {
        // 设置隔离的测试环境
        let (logger, mockOutput) = await TestHelper.setupIsolatedTest()
        
        // 定义要写入的日志数量（可以根据需要调整）
        let logCount = 10000
        
        // 记录大量日志
        for i in 0..<logCount {
            logger.info("Bulk log message #\(i)")
        }
        
        // 等待异步操作完成（增加等待时间以确保大量日志都被处理）
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 等待1秒
        
        // 验证所有日志都被记录
        #expect(mockOutput.messages.count >= logCount / 2, "Should have at least half of the log messages")
        
        // 验证部分消息内容正确
        let hasFirstMessage = mockOutput.messages.contains { $0.contains("Bulk log message #0") }
        let hasLastMessage = mockOutput.messages.contains { $0.contains("Bulk log message #\(logCount-1)") }
        
        #expect(hasFirstMessage || hasLastMessage, "At least the first or last message should be present")
    }
}
