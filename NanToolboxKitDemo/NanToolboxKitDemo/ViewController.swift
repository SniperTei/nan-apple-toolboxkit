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
            logInfoType: .default
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
    
    deinit {
        stopLoggingTest()
    }
}

