import XCTest
@testable import MNLogger

final class MNLoggerTests: XCTestCase {
    func testBasicLogging() {
        // 获取单例实例
        let logger = MNLogger.shared
        
        // 记录不同级别的日志
        logger.debug("这是一条调试日志")
        logger.info("这是一条信息日志")
        logger.warning("这是一条警告日志")
        logger.error("这是一条错误日志")
        logger.fatal("这是一条严重错误日志")  // 将 critical 改为 fatal
        
        // 立即刷新日志
        logger.flush()
        
        // 验证日志文件存在
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let logFilePath = documentsDirectory.appendingPathComponent("app.log").path
        XCTAssertTrue(FileManager.default.fileExists(atPath: logFilePath))
    }
    
    func testLogLevelFiltering() {
        let logger = MNLogger.shared
        
        // 设置最小日志级别为Warning
        logger.setMinimumLogLevel(.warning)
        
        // 记录不同级别的日志，只有warning及以上级别会被记录
        logger.debug("这条调试日志不会被记录")
        logger.info("这条信息日志不会被记录")
        logger.warning("这条警告日志会被记录")
        logger.error("这条错误日志会被记录")
        logger.fatal("这条严重错误日志会被记录")  // 将 critical 改为 fatal
        
        // 立即刷新日志
        logger.flush()
    }
    
    func testBulkLoggingPerformance() {
        let logger = MNLogger.shared
        let count = 10000
        
        // 测量大量日志记录的性能
        let startTime = Date()
        
        for i in 0..<count {
            logger.debug("这是第\(i)条测试日志，用于测试性能")
        }
        
        // 等待所有日志写入完成
        logger.flush()
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        print("记录\(count)条日志耗时: \(duration)秒")
        print("每秒可记录: \(Double(count) / duration)条日志")
        
        // 性能断言 - 确保性能满足要求
        XCTAssertLessThan(duration, 2.0, "记录\(count)条日志耗时不应超过2秒")
    }
}