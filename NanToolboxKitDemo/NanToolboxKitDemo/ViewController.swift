//
//  ViewController.swift
//  NanToolboxKitDemo
//
//  Created by zhengnan on 2025/4/25.
//

import UIKit
import NanToolboxKit

class ViewController: UIViewController {
    
    // 添加两个计数器
    private var autoLogCount: Int = 0    // 自动写入计数
    private var manualLogCount: Int = 0  // 手动写入计数
    private var logTimer: Timer?
    
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
        // 开始测试按钮
        let startButton = UIButton(frame: CGRect(x: 50, y: 100, width: 200, height: 50))
        startButton.setTitle("开始频繁写入日志", for: .normal)
        startButton.setTitleColor(.blue, for: .normal)
        startButton.addTarget(self, action: #selector(startLoggingTest), for: .touchUpInside)
        view.addSubview(startButton)
        
        // 停止测试按钮
        let stopButton = UIButton(frame: CGRect(x: 50, y: 170, width: 200, height: 50))
        stopButton.setTitle("停止写入日志", for: .normal)
        stopButton.setTitleColor(.red, for: .normal)
        stopButton.addTarget(self, action: #selector(stopLoggingTest), for: .touchUpInside)
        view.addSubview(stopButton)
        
        // 单次写入按钮
        let singleButton = UIButton(frame: CGRect(x: 50, y: 240, width: 200, height: 50))
        singleButton.setTitle("写入一条测试日志", for: .normal)
        singleButton.setTitleColor(.green, for: .normal)
        singleButton.addTarget(self, action: #selector(writeSingleLog), for: .touchUpInside)
        view.addSubview(singleButton)
    }
    
    @objc private func startLoggingTest() {
        // 停止现有定时器
        stopLoggingTest()
        
        // 每0.1秒写入一条日志
        logTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.writeAutoLog()
        }
        print("开始频繁写入日志测试")
    }
    
    @objc private func stopLoggingTest() {
        logTimer?.invalidate()
        logTimer = nil
        print("停止写入日志测试，自动写入\(autoLogCount)条，手动写入\(manualLogCount)条，总计\(autoLogCount + manualLogCount)条日志")
        autoLogCount = 0
        manualLogCount = 0
    }
    
    @objc private func writeSingleLog() {
        manualLogCount += 1
        let timestamp = Date().timeIntervalSince1970
        let memory = getMemoryUsage()
        SNPLogManager.shared.writeLog(log: "手动测试日志 #\(manualLogCount) - 时间戳: \(timestamp) - 内存使用: \(memory.physical)MB, 虚拟内存: \(memory.virtual)MB")
        print("写入一条测试日志")
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
            let physical = Float(info.resident_size) / 1024.0 / 1024.0  // 物理内存
            let virtual = Float(info.virtual_size) / 1024.0 / 1024.0    // 虚拟内存
            return (physical, virtual)
        }
        return (0, 0)
    }
    
    private func writeAutoLog() {
        autoLogCount += 1
        let timestamp = Date().timeIntervalSince1970
        let memory = getMemoryUsage()
        SNPLogManager.shared.writeLog(log: "自动测试日志 #\(autoLogCount) - 时间戳: \(timestamp) - 物理内存: \(memory.physical)MB, 虚拟内存: \(memory.virtual)MB")
    }
    
    deinit {
        stopLoggingTest()
    }
}

