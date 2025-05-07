//
//  ViewController.swift
//  NanToolboxKitDemo
//
//  Created by zhengnan on 2025/4/25.
//

import UIKit
import NanToolboxKit

class ViewController: UIViewController {
    
    // 添加计数器和性能测试相关属性
    private var autoLogCount: Int = 0    // 自动写入计数
    private var manualLogCount: Int = 0  // 手动写入计数
    private var logTimer: Timer?
    private var startTime: CFAbsoluteTime = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 初始化日志管理器
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let logPath = (documentsPath as NSString).appendingPathComponent("Logs")
        
        SNPLogManager.setup(config: SNPLogConfig(
            logFilePath: logPath,
            logFileName: "default.log",
            logLevel: .debug,
            logType: .file,
            logInfoType: .info,
            deviceId: "simulatorS"
        ))
        
        setupTestButtons()
    }
    
    private func setupTestButtons() {
        // 性能测试按钮
        let performanceButton = UIButton(frame: CGRect(x: 50, y: 100, width: 200, height: 50))
        performanceButton.setTitle("性能测试(1万条)", for: .normal)
        performanceButton.setTitleColor(.blue, for: .normal)
        performanceButton.addTarget(self, action: #selector(performanceTest), for: .touchUpInside)
        view.addSubview(performanceButton)
        
        // 连续写入按钮
        let startButton = UIButton(frame: CGRect(x: 50, y: 170, width: 200, height: 50))
        startButton.setTitle("开始连续写入", for: .normal)
        startButton.setTitleColor(.green, for: .normal)
        startButton.addTarget(self, action: #selector(startLoggingTest), for: .touchUpInside)
        view.addSubview(startButton)
        
        // 停止按钮
        let stopButton = UIButton(frame: CGRect(x: 50, y: 240, width: 200, height: 50))
        stopButton.setTitle("停止写入", for: .normal)
        stopButton.setTitleColor(.red, for: .normal)
        stopButton.addTarget(self, action: #selector(stopLoggingTest), for: .touchUpInside)
        view.addSubview(stopButton)
        
        // 添加并发测试按钮
        let concurrentButton = UIButton(frame: CGRect(x: 50, y: 310, width: 200, height: 50))
        concurrentButton.setTitle("并发写入测试", for: .normal)
        concurrentButton.setTitleColor(.purple, for: .normal)
        concurrentButton.addTarget(self, action: #selector(concurrentTest), for: .touchUpInside)
        view.addSubview(concurrentButton)
    }
    
    @objc private func performanceTest() {
        startTime = CFAbsoluteTimeGetCurrent()
        
        // 在后台队列执行，避免阻塞主线程
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // 写入1万条日志
            for i in 1...10000 {
                let memory = self?.getMemoryUsage() ?? (0, 0)
                SNPLogManager.shared.writeLog(log: "性能测试 #\(i) - 内存: \(memory)MB")
            }
            
            // 计算耗时
            let timeElapsed = CFAbsoluteTimeGetCurrent() - (self?.startTime ?? 0)
            DispatchQueue.main.async {
                print("性能测试完成：")
                print("总耗时: \(String(format: "%.3f", timeElapsed))秒")
                print("平均每条日志耗时: \(String(format: "%.3f", timeElapsed/10000*1000))毫秒")
            }
        }
    }
    
    @objc private func startLoggingTest() {
        stopLoggingTest() // 先停止现有的
        startTime = CFAbsoluteTimeGetCurrent()
        
        // 每0.01秒写入一条日志
        logTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            self?.writeAutoLog()
        }
        print("开始连续写入测试")
    }
    
    @objc private func stopLoggingTest() {
        logTimer?.invalidate()
        logTimer = nil
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        print("停止写入测试：")
        print("写入数量: \(autoLogCount)条")
        print("总耗时: \(String(format: "%.3f", timeElapsed))秒")
        if autoLogCount > 0 {
            print("平均每条日志耗时: \(String(format: "%.3f", timeElapsed/Double(autoLogCount)*1000))毫秒")
        }
        
        autoLogCount = 0
    }
    
    private func writeAutoLog() {
        autoLogCount += 1
        let memory = getMemoryUsage()
        SNPLogManager.shared.writeLog(log: "连续测试 #\(autoLogCount) - 物理内存: \(memory.physical)MB, 虚拟内存: \(memory.virtual)MB")
    }
    
    private func getMemoryUsage() -> (physical: Float, virtual: Float) {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let physical = Float(info.resident_size) / 1024.0 / 1024.0
            let virtual = Float(info.virtual_size) / 1024.0 / 1024.0
            return (physical, virtual)
        }
        return (0, 0)
    }
    
    @objc private func concurrentTest() {
        print("开始并发写入测试")
        startTime = CFAbsoluteTimeGetCurrent()
        
        // 创建5个并发队列
        let queues = (0..<5).map { index in
            DispatchQueue(label: "com.nan.logQueue.\(index)")
        }
        
        // 使用组来等待所有任务完成
        let group = DispatchGroup()
        
        // 每个队列写入2000条日志
        for (index, queue) in queues.enumerated() {
            group.enter()
            queue.async {
                for i in 1...2000 {
                    let memory = self.getMemoryUsage()
                    SNPLogManager.shared.writeLog(log: "并发测试 - 线程\(index) - #\(i) - 内存: \(memory)MB")
                }
                group.leave()
            }
        }
        
        // 所有任务完成后计算性能
        group.notify(queue: .main) {
            let timeElapsed = CFAbsoluteTimeGetCurrent() - self.startTime
            print("并发测试完成：")
            print("总日志数: 10000条")
            print("总耗时: \(String(format: "%.3f", timeElapsed))秒")
            print("平均每条日志耗时: \(String(format: "%.3f", timeElapsed/10000*1000))毫秒")
            
            // 验证日志文件完整性
            self.verifyLogFile()
        }
    }
    
    private func verifyLogFile() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let logPath = (documentsPath as NSString).appendingPathComponent("Logs")
        
        // 使用与SNPLogManager相同的日期格式
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let currentFileName = "SNPLog-\(dateFormatter.string(from: Date())).log"
        let logFilePath = (logPath as NSString).appendingPathComponent(currentFileName)
        
        print("验证日志文件路径: \(logFilePath)")  // 添加这行来调试文件路径
        
        do {
            let content = try String(contentsOfFile: logFilePath, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            let validLines = lines.filter { !$0.isEmpty }
            
            print("日志验证结果：")
            print("实际写入行数: \(validLines.count)")
            
            // 检查是否有重复的日志序号
            var threadLogs: [Int: Set<Int>] = [:]
            for line in validLines {
                if let range = line.range(of: "线程(\\d+).+#(\\d+)", options: .regularExpression) {
                    let match = String(line[range])
                    let matchComponents = match.split(separator: "线程").last?.split(separator: " - #")
                    if let components = matchComponents,
                       components.count >= 2,
                       let threadId = Int(components[0]),
                       let logId = Int(components[1]) {
                        threadLogs[threadId, default: []].insert(logId)
                    }
                }
            }
            
            // 检查每个线程的日志完整性
            for (threadId, logs) in threadLogs {
                print("线程\(threadId)写入日志数: \(logs.count)")
                if logs.count != 2000 {
                    print("警告：线程\(threadId)日志不完整，缺少\(2000 - logs.count)条")
                }
            }
            
        } catch {
            print("日志文件验证失败：\(error)")
            print("尝试验证的文件路径：\(logFilePath)")  // 添加这行来显示具体路径
            
            // 列出日志目录中的所有文件
            do {
                let files = try FileManager.default.contentsOfDirectory(atPath: logPath)
                print("日志目录中的文件：")
                for file in files {
                    print(file)
                }
            } catch {
                print("无法读取日志目录：\(error)")
            }
        }
    }
    
    deinit {
        stopLoggingTest()
    }
}

