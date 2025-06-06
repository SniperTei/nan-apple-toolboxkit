import UIKit

class LogTestViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        // 设置日志配置
//        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path
//        let logPath = (documentsPath as NSString).appendingPathComponent("Logs")
//        
//        let config = SNPLogConfig(
//            logFilePath: logPath,
//            deviceId: "myDevice",
//            logType: .file
//        )
//        
//        // 初始化日志管理器
//        SNPLogManager.setup(config: config)
//        
//        // 测试各种级别的日志
//        SNPLogManager.network("这是一条调试信息")
//        SNPLogManager.info("这是一条普通信息")
//        SNPLogManager.warning("这是一条警告信息")
//        SNPLogManager.error("这是一条错误信息")
    }
} 
