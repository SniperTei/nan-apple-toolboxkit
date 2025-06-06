import UIKit

class LogTestViewController: UIViewController {
    
    private let textField = UITextField()
    private let writeButton = UIButton(type: .system)
    private let textView = UITextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLogger()
    }
    
    private func setupUI() {
        title = "日志测试"
        view.backgroundColor = .white
        
        // 配置输入框
        textField.borderStyle = .roundedRect
        textField.placeholder = "请输入日志内容"
        view.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        // 配置写入按钮
        writeButton.setTitle("写入日志", for: .normal)
        writeButton.addTarget(self, action: #selector(writeLogButtonTapped), for: .touchUpInside)
        view.addSubview(writeButton)
        writeButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 配置日志显示区域
        textView.isEditable = false
        textView.font = .systemFont(ofSize: 14)
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.cornerRadius = 5
        view.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        // 设置约束
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textField.heightAnchor.constraint(equalToConstant: 40),
            
            writeButton.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 20),
            writeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            writeButton.heightAnchor.constraint(equalToConstant: 40),
            
            textView.topAnchor.constraint(equalTo: writeButton.bottomAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupLogger() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let logPath = (documentsPath as NSString).appendingPathComponent("Logs")
        
        SNPLogManager.setup(config: SNPLogConfig(
            logFilePath: logPath,
            deviceId: "simulatorS",
            logType: .file
        ))
    }
    
    @objc private func writeLogButtonTapped() {
        guard let logText = textField.text, !logText.isEmpty else {
            showAlert(message: "请输入日志内容")
            return
        }
        
        // 写入日志
        SNPLogManager.shared.writeLog(log: logText)
        
        // 读取并显示日志文件内容
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.readAndDisplayLog()
        }
        
        // 清空输入框
        textField.text = ""
        textField.resignFirstResponder()
    }
    
    private func readAndDisplayLog() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let logPath = (documentsPath as NSString).appendingPathComponent("Logs")
        
        // 获取当前日期
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let currentDate = dateFormatter.string(from: Date())
        
        // 构建完整的日志文件路径
        let logFileName = "SNPLog-simulatorS-\(currentDate).log"
        let fullLogPath = (logPath as NSString).appendingPathComponent(logFileName)
        
        do {
            let logContent = try String(contentsOfFile: fullLogPath, encoding: .utf8)
            textView.text = logContent
            // 滚动到底部
            let bottom = NSRange(location: logContent.count, length: 0)
            textView.scrollRangeToVisible(bottom)
        } catch {
            showAlert(message: "读取日志失败: \(error.localizedDescription)")
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
} 
