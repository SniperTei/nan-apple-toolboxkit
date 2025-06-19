//
//  SNPCrashTestController.swift
//  NanToolboxDemo
//
//  Created by zhengnan on 2025/6/16.
//

import UIKit

class SNPCrashTestController: UIViewController, SNPUncaughtExceptionHandlerDelegate {
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        stack.isLayoutMarginsRelativeArrangement = true
        return stack
    }()
    
    private let logTextView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.backgroundColor = .systemBackground
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        return textView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCrashMonitor()
    }
    
    private func setupUI() {
        title = "崩溃测试"
        view.backgroundColor = .systemBackground
        
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加测试按钮
        let testButtons = [
            ("测试未捕获异常", #selector(testUncaughtException)),
            ("测试数组越界", #selector(testArrayOutOfBounds)),
            ("测试空指针", #selector(testNullPointer)),
            ("测试崩溃日志记录", #selector(testCrashLog)),
//            ("测试除零错误", #selector(testDivideByZero))
        ]
        
        testButtons.forEach { title, action in
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.addTarget(self, action: action, for: .touchUpInside)
            button.backgroundColor = .systemBlue
            button.setTitleColor(.white, for: .normal)
            button.layer.cornerRadius = 8
            button.heightAnchor.constraint(equalToConstant: 44).isActive = true
            stackView.addArrangedSubview(button)
        }
        
        // 添加日志视图
        stackView.addArrangedSubview(logTextView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            logTextView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    private func setupCrashMonitor() {
        SNPCrashMonitor.shared.delegate = self
        SNPCrashMonitor.shared.startMonitoring()
        log("崩溃监控已启动")
    }
    
    // MARK: - 测试方法
    
    @objc private func testUncaughtException() {
        log("触发未捕获异常...")
        NSException(name: .genericException, reason: "测试未捕获异常", userInfo: nil).raise()
    }
    
    @objc private func testArrayOutOfBounds() {
        log("触发数组越界...")
        let array = [1, 2, 3]
        _ = array[5] // 越界访问
    }
    
    @objc private func testNullPointer() {
        log("触发空指针...")
        let array: [Int]? = nil
        _ = array![0] // 强制解包空值
    }
    
    @objc private func testCrashLog() {
        log("测试崩溃日志记录...")
        
        // 模拟崩溃信息
        let mockCrashInfo = """
        模拟崩溃信息：
        - 类型：测试崩溃
        - 原因：模拟崩溃用于测试日志记录
        - 时间：\(Date())
        - 设备：iPhone模拟器
        - 系统：iOS 18.2
        - 版本：1.0.0
        """
        
        // 使用崩溃日志类型记录
        SNPLogManager.shared.writeLog(
            log: mockCrashInfo,
            type: .crash,
            file: #file,
            function: #function,
            line: #line
        )
        
        log("崩溃日志已记录到文件")
    }
    
//    @objc private func testDivideByZero() {
//        log("触发除零错误...")
//        let result = 1 / 0
//        print(result)
//    }
    
    // MARK: - 日志方法
    
    private func log(_ message: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
        let timestamp = dateFormatter.string(from: Date())
        let logMessage = "[\(timestamp)] \(message)\n"
        
        // 同时写入日志模块和UI显示
        SNPLogManager.shared.writeLog(
            log: message,
            type: .info,
            file: #file,
            function: #function,
            line: #line
        )
        
        DispatchQueue.main.async {
            self.logTextView.text += logMessage
            let range = NSRange(location: self.logTextView.text.count - 1, length: 1)
            self.logTextView.scrollRangeToVisible(range)
        }
    }
    
    // MARK: - SNPUncaughtExceptionHandlerDelegate
    
    func crashMonitor(_ monitor: SNPCrashMonitor, didCatchCrash crash: SNPCrashModel) {
        let crashInfo = """
        捕获到崩溃：
        类型：\(crash.type.description)
        名称：\(crash.name)
        原因：\(crash.reason)
        时间：\(Date(timeIntervalSince1970: crash.timestamp))
        设备：\(crash.deviceInfo.deviceModel)
        系统：\(crash.deviceInfo.osVersion)
        版本：\(crash.deviceInfo.appVersion)
        堆栈：
        \(crash.callStackSymbols.joined(separator: "\n"))
        """
        
        // 记录崩溃信息到日志模块
        SNPLogManager.shared.writeLog(
            log: crashInfo,
            type: .crash,
            file: #file,
            function: #function,
            line: #line
        )
        
        // 显示在UI上
        log(crashInfo)
    }
}
