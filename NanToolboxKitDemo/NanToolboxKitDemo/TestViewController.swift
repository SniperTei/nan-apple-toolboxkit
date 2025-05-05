import UIKit
import NanToolboxKit

class TestViewController: UIViewController {
    
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)  // 使用分组样式
        table.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    // 使用结构体来组织测试项
    private struct TestSection {
        let title: String
        let items: [TestItem]
    }
    
    private struct TestItem {
        let title: String
        let action: () -> Void
    }
    
    // 测试项数据
    private lazy var sections: [TestSection] = [
        TestSection(title: "日志测试", items: [
            TestItem(title: "性能测试(1万条)", action: performanceTest),
            TestItem(title: "开始连续写入", action: startLoggingTest),
            TestItem(title: "停止写入", action: stopLoggingTest),
            TestItem(title: "并发写入测试", action: concurrentTest)
        ]),
        TestSection(title: "日志查看", items: [
            TestItem(title: "查看日志文件", action: showLogFile),
            TestItem(title: "清理日志文件", action: clearLogFiles)
        ]),
        TestSection(title: "监控测试", items: [
            TestItem(title: "内存监控", action: memoryMonitorTest),
            TestItem(title: "CPU监控", action: cpuMonitorTest),
            TestItem(title: "FPS监控", action: fpsMonitorTest)
        ])
    ]
    
    private var autoLogCount: Int = 0
    private var logTimer: Timer?
    private var startTime: CFAbsoluteTime = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLogger()
    }
    
    private func setupUI() {
        title = "日志测试"
        view.backgroundColor = .white
        
        // 添加TableView
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func setupLogger() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let logPath = (documentsPath as NSString).appendingPathComponent("Logs")
        
        SNPLogManager.setup(config: SNPLogConfig(
            logFilePath: logPath,
            logFileName: "default.log",
            logLevel: .debug,
            logType: .file,
            logInfoType: .default
        ))
    }
    
    // MARK: - 测试方法
    
    private func performanceTest() {
        startTime = CFAbsoluteTimeGetCurrent()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            for i in 1...10000 {
                let memory = self?.getMemoryUsage() ?? (0, 0)
                SNPLogManager.shared.writeLog(log: "性能测试 #\(i) - 内存: \(memory)MB")
            }
            
            let timeElapsed = CFAbsoluteTimeGetCurrent() - (self?.startTime ?? 0)
            DispatchQueue.main.async {
                self?.showAlert(title: "性能测试完成", message: """
                    总耗时: \(String(format: "%.3f", timeElapsed))秒
                    平均每条日志耗时: \(String(format: "%.3f", timeElapsed/10000*1000))毫秒
                    """)
            }
        }
    }
    
    private func startLoggingTest() {
        stopLoggingTest()
        startTime = CFAbsoluteTimeGetCurrent()
        
        logTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            self?.writeAutoLog()
        }
        showToast(message: "开始连续写入测试")
    }
    
    private func stopLoggingTest() {
        logTimer?.invalidate()
        logTimer = nil
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        let message = """
            写入数量: \(autoLogCount)条
            总耗时: \(String(format: "%.3f", timeElapsed))秒
            平均每条日志耗时: \(String(format: "%.3f", timeElapsed/Double(autoLogCount)*1000))毫秒
            """
        
        showAlert(title: "停止写入测试", message: message)
        autoLogCount = 0
    }
    
    private func concurrentTest() {
        startTime = CFAbsoluteTimeGetCurrent()
        
        let queues = (0..<5).map { index in
            DispatchQueue(label: "com.nan.logQueue.\(index)")
        }
        
        let group = DispatchGroup()
        
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
        
        group.notify(queue: .main) { [weak self] in
            let timeElapsed = CFAbsoluteTimeGetCurrent() - (self?.startTime ?? 0)
            self?.verifyLogFile { result in
                let message = """
                    总日志数: 10000条
                    总耗时: \(String(format: "%.3f", timeElapsed))秒
                    平均每条日志耗时: \(String(format: "%.3f", timeElapsed/10000*1000))毫秒
                    
                    验证结果：
                    \(result)
                    """
                self?.showAlert(title: "并发测试完成", message: message)
            }
        }
    }
    
    private func showLogFile() {
        verifyLogFile { [weak self] result in
            self?.showAlert(title: "日志文件内容", message: result)
        }
    }
    
    // MARK: - 新增测试方法
    
    private func clearLogFiles() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let logPath = (documentsPath as NSString).appendingPathComponent("Logs")
        
        do {
            let fileManager = FileManager.default
            let files = try fileManager.contentsOfDirectory(atPath: logPath)
            try files.forEach { file in
                let filePath = (logPath as NSString).appendingPathComponent(file)
                try fileManager.removeItem(atPath: filePath)
            }
            showToast(message: "日志文件已清理")
        } catch {
            showAlert(title: "清理失败", message: error.localizedDescription)
        }
    }
    
    private func memoryMonitorTest() {
        // TODO: 实现内存监控测试
        showAlert(title: "内存监控", message: "当前内存使用：\(getMemoryUsage().physical)MB")
    }
    
    private func cpuMonitorTest() {
        // TODO: 实现CPU监控测试
        showAlert(title: "CPU监控", message: "待实现")
    }
    
    private func fpsMonitorTest() {
        // TODO: 实现FPS监控测试
        showAlert(title: "FPS监控", message: "待实现")
    }
    
    // MARK: - 辅助方法
    
    private func writeAutoLog() {
        autoLogCount += 1
        let memory = getMemoryUsage()
        SNPLogManager.shared.writeLog(log: "连续测试 #\(autoLogCount) - 内存: \(memory)MB")
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
    
    private func verifyLogFile(completion: @escaping (String) -> Void) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let logPath = (documentsPath as NSString).appendingPathComponent("Logs")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let currentFileName = "SNPLog-\(dateFormatter.string(from: Date())).log"
        let logFilePath = (logPath as NSString).appendingPathComponent(currentFileName)
        
        do {
            let content = try String(contentsOfFile: logFilePath, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            let validLines = lines.filter { !$0.isEmpty }
            
            var result = "实际写入行数: \(validLines.count)\n\n"
            
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
            
            for (threadId, logs) in threadLogs {
                result += "线程\(threadId)写入日志数: \(logs.count)\n"
                if logs.count != 2000 {
                    result += "警告：线程\(threadId)日志不完整，缺少\(2000 - logs.count)条\n"
                }
            }
            
            completion(result)
        } catch {
            let errorMessage = """
                日志文件验证失败：\(error)
                文件路径：\(logFilePath)
                
                日志目录文件列表：
                \((try? FileManager.default.contentsOfDirectory(atPath: logPath).joined(separator: "\n")) ?? "无法读取目录")
                """
            completion(errorMessage)
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    private func showToast(message: String) {
        let toast = UILabel()
        toast.text = message
        toast.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toast.textColor = .white
        toast.textAlignment = .center
        toast.font = .systemFont(ofSize: 14)
        toast.layer.cornerRadius = 20
        toast.clipsToBounds = true
        toast.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(toast)
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            toast.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -40),
            toast.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        UIView.animate(withDuration: 0.3, delay: 2, options: [], animations: {
            toast.alpha = 0
        }) { _ in
            toast.removeFromSuperview()
        }
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension TestViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let item = sections[indexPath.section].items[indexPath.row]
        cell.textLabel?.text = item.title
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sections[indexPath.section].items[indexPath.row]
        item.action()
    }
} 