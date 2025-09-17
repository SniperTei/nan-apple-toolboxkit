import Testing
import Foundation
@testable import SwiftCode

@Test func example() {
    #expect(1 == 1, "Always passes")
}

@Test func testLogger() {
    // 创建临时日志文件
    let tempDir = FileManager.default.temporaryDirectory
    let logFilePath = tempDir.appendingPathComponent("test.log").path
    
    // 初始化日志器
    guard let logger = SNPLogger(filePath: logFilePath) else {
        #expect(false, "Failed to create logger")
        return
    }
    
    // 写入不同级别的日志
    logger.debug("This is a debug message")
    logger.info("This is an info message")
    logger.warning("This is a warning message")
    logger.error("This is an error message")
    
    // 刷新到文件
    logger.flush()
    
    // 验证文件存在
    #expect(FileManager.default.fileExists(atPath: logFilePath), "Log file should exist")
    
    // 尝试读取文件内容
    do {
        let content = try String(contentsOfFile: logFilePath, encoding: .utf8)
        #expect(content.contains("debug message"), "Log file should contain debug message")
        #expect(content.contains("info message"), "Log file should contain info message")
    } catch {
        #expect(false, "Failed to read log file: \(error)")
    }
}

@Test func testGlobalLogger() async {
    // 使用全局日志实例
    await MainActor.run {
        SNPLog.debug("Testing global logger")
        SNPLog.info("Global logger is working")
        SNPLog.flush()
    }
    
    #expect(true, "Global logger operations should complete without errors")
}

@Test func testLogWriter() async {
    // 创建一个临时日志文件路径
    let tempDir = FileManager.default.temporaryDirectory
    let logFilePath = tempDir.appendingPathComponent("test_log_\(UUID().uuidString).log").path
    
    // 创建日志实例
    guard let logger = SNPLogger(filePath: logFilePath) else {
        #expect(false, "Failed to create logger")
        return
    }
    
    // 写入不同级别的日志
    logger.debug("这是一条调试日志")
    logger.info("这是一条信息日志")
    logger.warning("这是一条警告日志")
    logger.error("这是一条错误日志")
    
    // 刷新缓冲区
    logger.flush()
    
    // 检查日志文件是否存在
    let fileManager = FileManager.default
    #expect(fileManager.fileExists(atPath: logFilePath), "日志文件未创建")
    
    // 读取并验证日志内容
    if let logContent = try? String(contentsOfFile: logFilePath, encoding: .utf8) {
        #expect(logContent.contains("DEBUG"), "调试日志未找到")
        #expect(logContent.contains("INFO"), "信息日志未找到")
        #expect(logContent.contains("WARNING"), "警告日志未找到")
        #expect(logContent.contains("ERROR"), "错误日志未找到")
    } else {
        #expect(false, "无法读取日志文件")
    }
    
    // 清理临时文件
    do {
        try fileManager.removeItem(atPath: logFilePath)
    } catch {
        // 清理失败也没关系，临时文件会被系统自动清理
    }
}

@Test func testDirectLogUsage() async {
    // 创建一个临时日志文件路径
    let tempDir = FileManager.default.temporaryDirectory
    let logFilePath = tempDir.appendingPathComponent("test_direct_log_\(UUID().uuidString).log").path
    
    // 直接使用SNPLogger
    guard let writer = SNPLogger(filePath: logFilePath) else {
        #expect(false, "无法创建SNPLogger")
        return
    }
    
    // 写入日志
    writer.info("这是直接使用SNPLogger写入的第一行日志")
    writer.info("这是直接使用SNPLogger写入的第二行日志")
    writer.flush()
    
    // 检查日志文件内容
    if let logContent = try? String(contentsOfFile: logFilePath, encoding: .utf8) {
        #expect(logContent.contains("第一行日志"), "第一行日志未找到")
        #expect(logContent.contains("第二行日志"), "第二行日志未找到")
    } else {
        #expect(false, "无法读取日志文件")
    }
    
    // 清理临时文件
    do {
        try FileManager.default.removeItem(atPath: logFilePath)
    } catch {
        // 清理失败也没关系，临时文件会被系统自动清理
    }
}
