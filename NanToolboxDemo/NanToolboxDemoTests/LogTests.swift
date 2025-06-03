import XCTest
@testable import NanToolboxDemo

final class LogTests: XCTestCase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        setupLogger()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }
    
    func testLogOutput() throws {
        // 测试基本日志输出
        let testMessage = "这是一条测试日志"
        
        // 测试不同级别的日志输出
        SNPLogManager.shared.writeLog(log: testMessage)
        
        // 等待日志写入
        let exp = expectation(description: "等待日志写入")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // 验证日志文件是否存在
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let logPath = (documentsPath as NSString).appendingPathComponent("Logs")
            
            // 获取当前日期
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let currentDate = dateFormatter.string(from: Date())
            
            // 构建完整的日志文件路径
            let logFileName = "SNPLog-simulatorS-\(currentDate)"
            let fullLogPath = (logPath as NSString).appendingPathComponent(logFileName)
            
            XCTAssertTrue(FileManager.default.fileExists(atPath: fullLogPath), "日志文件应该被创建")
            
            // 读取日志文件内容
            do {
                let logContent = try String(contentsOfFile: fullLogPath, encoding: .utf8)
                XCTAssertTrue(logContent.contains(testMessage), "日志文件应该包含测试消息")
            } catch {
                XCTFail("读取日志文件失败: \(error)")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 2.0)
    }
    
    func testMultipleLogsOutput() throws {
        // 测试多条日志输出
        let testMessages = [
            "第一条测试日志",
            "第二条测试日志",
            "第三条测试日志"
        ]
        
        // 写入多条日志
        for message in testMessages {
            SNPLogManager.shared.writeLog(log: message)
        }
        
        let exp = expectation(description: "等待多条日志写入")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let logPath = (documentsPath as NSString).appendingPathComponent("Logs")
            
            // 获取当前日期
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let currentDate = dateFormatter.string(from: Date())
            
            // 构建完整的日志文件路径
            let logFileName = "SNPLog-simulatorS-\(currentDate)"
            let fullLogPath = (logPath as NSString).appendingPathComponent(logFileName)
            
            do {
                let logContent = try String(contentsOfFile: fullLogPath, encoding: .utf8)
                
                // 验证所有测试消息都被写入
                for message in testMessages {
                    XCTAssertTrue(logContent.contains(message), "日志文件应该包含消息: \(message)")
                }
                
                // 验证日志的顺序
                var lastIndex = 0
                for message in testMessages {
                    let currentIndex = logContent.range(of: message)?.lowerBound.utf16Offset(in: logContent) ?? -1
                    XCTAssertGreaterThan(currentIndex, lastIndex, "日志应该按顺序写入")
                    lastIndex = currentIndex
                }
            } catch {
                XCTFail("读取日志文件失败: \(error)")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 2.0)
    }
    
    func testLogLevel() throws {
        // 测试日志级别过滤
        let testMessage = "日志级别测试"
        
        // 设置日志级别为 warning
//        SNPLogManager.setLogLevel(.release)
        
        // 写入不同级别的日志
        SNPLogManager.debug(testMessage + "_debug")
        SNPLogManager.info(testMessage + "_info")
        SNPLogManager.warning(testMessage + "_warning")
        SNPLogManager.error(testMessage + "_error")
        
        let exp = expectation(description: "等待日志级别测试")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let logPath = (documentsPath as NSString).appendingPathComponent("Logs/default.log")
            
            do {
                let logContent = try String(contentsOfFile: logPath, encoding: .utf8)
                
                // debug 和 info 级别的日志不应该出现
                XCTAssertFalse(logContent.contains(testMessage + "_debug"), "Debug级别的日志不应该出现")
                XCTAssertFalse(logContent.contains(testMessage + "_info"), "Info级别的日志不应该出现")
                
                // warning 和 error 级别的日志应该出现
                XCTAssertTrue(logContent.contains(testMessage + "_warning"), "Warning级别的日志应该出现")
                XCTAssertTrue(logContent.contains(testMessage + "_error"), "Error级别的日志应该出现")
            } catch {
                XCTFail("读取日志文件失败: \(error)")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 2.0)
    }
    
    func setupLogger() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let logPath = (documentsPath as NSString).appendingPathComponent("Logs")
        
        SNPLogManager.setup(config: SNPLogConfig(
            logFilePath: logPath,
            logFileName: "default.log",  // 这个参数实际上不会被使用，因为文件名是自动生成的
            deviceId: "simulatorS"
        ))
    }
} 
