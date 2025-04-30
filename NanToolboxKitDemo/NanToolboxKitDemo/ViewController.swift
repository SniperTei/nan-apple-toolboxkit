//
//  ViewController.swift
//  NanToolboxKitDemo
//
//  Created by zhengnan on 2025/4/25.
//

import UIKit
import NanToolboxKit

class ViewController: UIViewController {

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
        
        // 添加测试按钮
        let testButton = UIButton(frame: CGRect(x: 50, y: 100, width: 200, height: 50))
        testButton.setTitle("写入测试日志", for: .normal)
        testButton.setTitleColor(.blue, for: .normal)
        testButton.addTarget(self, action: #selector(writeTestLog), for: .touchUpInside)
        view.addSubview(testButton)
    }
    
    @objc private func writeTestLog() {
        let timestamp = Date().timeIntervalSince1970
        SNPLogManager.shared.writeLog(log: "这是一条测试日志 -v2 \(timestamp)")
        print("日志已写入")
    }
}

