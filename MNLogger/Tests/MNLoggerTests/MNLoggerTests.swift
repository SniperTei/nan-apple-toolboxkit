import XCTest
@testable import MNLogger

final class MNLoggerTests: XCTestCase {
    // 用于日志文件测试的日期格式化器
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    // 获取当前日期的日志文件路径
    private func getCurrentLogFilePath() -> String {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let currentDate = dateFormatter.string(from: Date())
        let logFileName = "app_\(currentDate).log"
        return documentsDirectory.appendingPathComponent(logFileName).path
    }
    
    // 在每个测试前重置日志级别
    override func setUp() {
        super.setUp()
        // 重置为最低日志级别，确保所有测试不受之前设置的影响
        MNLogger.setMinimumLogLevel(.debug)
    }
    
    // 测试基本日志功能（使用静态方法）
    func testBasicLogging() {
        // 记录不同级别的日志（使用静态方法）
        MNLogger.debug("这是一条调试日志")
        MNLogger.info("这是一条信息日志")
        MNLogger.warning("这是一条警告日志")
        MNLogger.error("这是一条错误日志")
        MNLogger.fatal("这是一条严重错误日志")
        
        // 立即刷新日志
        MNLogger.flush()
        
        // 验证日志文件存在
        let logFilePath = getCurrentLogFilePath()
        XCTAssertTrue(FileManager.default.fileExists(atPath: logFilePath), "日志文件应该存在")
    }
    
    // 测试日志级别过滤功能
    func testLogLevelFiltering() {
        // 设置最小日志级别为Warning
        MNLogger.setMinimumLogLevel(.warning)
        
        // 记录不同级别的日志，只有warning及以上级别会被记录
        MNLogger.debug("这条调试日志不会被记录")
        MNLogger.info("这条信息日志不会被记录")
        MNLogger.warning("这条警告日志会被记录")
        MNLogger.error("这条错误日志会被记录")
        MNLogger.fatal("这条严重错误日志会被记录")
        
        // 立即刷新日志
        MNLogger.flush()
        
        // 验证日志文件存在
        let logFilePath = getCurrentLogFilePath()
        XCTAssertTrue(FileManager.default.fileExists(atPath: logFilePath), "日志文件应该存在")
    }
    
    // 测试批量日志记录性能
    func testBulkLoggingPerformance() {
        let count = 10000
        
        // 测量大量日志记录的性能
        let startTime = Date()
        
        // 使用静态方法批量写入日志
        for i in 0..<count {
            MNLogger.debug("这是第\(i)条测试日志，用于测试性能")
        }
        
        // 等待所有日志写入完成
        MNLogger.flush()
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // 输出性能指标
        print("记录\(count)条日志耗时: \(String(format: "%.3f", duration))秒")
        print("每秒可记录: \(String(format: "%.0f", Double(count) / duration))条日志")
        
        // 性能断言 - 确保性能满足要求
        XCTAssertLessThan(duration, 2.0, "记录\(count)条日志耗时不应超过2秒")
    }
    
    // 新增：测试单例和静态方法的一致性
    func testSingletonAndStaticConsistency() {
        // 设置单例的日志级别
        MNLogger.shared.setMinimumLogLevel(.error)
        
        // 使用静态方法记录日志
        MNLogger.debug("这条调试日志不应该被记录")
        MNLogger.error("这条错误日志应该被记录")
        
        MNLogger.flush()
        
        // 验证日志文件存在
        let logFilePath = getCurrentLogFilePath()
        XCTAssertTrue(FileManager.default.fileExists(atPath: logFilePath), "日志文件应该存在")
    }
    
    // 新增：测试日期命名日志文件功能
    func testDateNamedLogFile() {
        // 获取当前日志文件路径
        let originalLogFilePath = getCurrentLogFilePath()
        
        // 写入一条测试日志并刷新
        MNLogger.info("测试日期命名的日志文件")
        MNLogger.flush()
        
        // 验证日志文件存在
        XCTAssertTrue(FileManager.default.fileExists(atPath: originalLogFilePath), "日期命名的日志文件应该存在")
    }
}