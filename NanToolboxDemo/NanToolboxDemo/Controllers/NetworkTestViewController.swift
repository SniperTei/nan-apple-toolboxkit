import UIKit
import Alamofire

class NetworkTestViewController: UIViewController {
    
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let testItems = ["登录接口测试", "日志上传测试"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupData()
    }
    
    private func setupUI() {
        title = "网络测试"
        view.backgroundColor = .white
        
        // 配置tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        // 添加tableView
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupData() {
        // 设置网络请求的baseUrl
        SNPNetworkConfig.shared.baseURL = "http://localhost:3000/api"

        // 在初始化网络管理器时设置日志处理
        // let logger = SNPNetworkLogger

        SNPNetworkManager.shared.setLogHandler { log in
            print("escape log: \(log)")
            // 根据日志类型进行不同处理
            switch log.type {
            case .request:
                // 处理请求日志
                SNPLogManager.network(log.message)
            case .response:
                // 处理响应日志
                SNPLogManager.network(log.message)
            case .success:
                // 处理成功日志
                SNPLogManager.network(log.message)
            case .error:
                // 处理错误日志
                SNPLogManager.error(log.message)
            }
            
            // // 或者使用自定义的日志系统
            // CustomLogger.log(
            //     type: log.type,
            //     message: log.message,
            //     url: log.url,
            //     statusCode: log.statusCode,
            //     timestamp: log.timestamp
            // )
        }
    }
    
    private func testLoginAPI() {
        
        // 创建登录请求
        let loginRequest = LoginReqData(username: "admin", password: "password123")
        
        // 发送登录请求
        SNPNetworkManager.shared.request(loginRequest, responseType: LoginResData.self) { result in
            switch result {
            case .success(let data):
                if let userData = data?.user {
                    let message = """
                    登录成功！
                    用户ID: \(userData.id)
                    用户名: \(userData.username)
                    昵称: \(userData.nickname ?? "无")
                    邮箱: \(userData.email ?? "无")
                    管理员: \(userData.isAdmin ? "是" : "否")
                    注册时间: \(userData.createdAt)
                    """
                    print("登录成功：\(message)")
                } else {
                    print("登录成功，但未返回用户信息")
                }
            case .failure(let error):
                print("登录失败：\(error.localizedDescription)")
            }
        }
    }
    
    private func testUploadLog() {
        // 获取日志文件路径
        let logFilePath = logFilePath()
        
        // 检查文件是否存在
        guard FileManager.default.fileExists(atPath: logFilePath) else {
            showAlert(message: "日志文件不存在：\(logFilePath)")
            return
        }
        
        // 设置认证token
        var config = SNPDefaultLogUploadConfig()
        config.setAuthToken(token())
        SNPLogUploader.shared.config = config
        
        // 上传日志文件
        SNPLogUploader.shared.uploadLog(
            logFilePath: logFilePath,
            deviceId: "simulatorS"
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let urls):
                    let message = """
                    日志上传成功！
                    文件路径：\(urls.joined(separator: "\n"))
                    """
                    self.showAlert(message: message)
                    
                case .failure(let error):
                    self.showAlert(message: "日志上传失败：\(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    private func logFilePath() -> String {
        // 验证日志文件是否存在
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let logPath = (documentsPath as NSString).appendingPathComponent("Logs")
        
        // 确保日志目录存在
        if !FileManager.default.fileExists(atPath: logPath) {
            try? FileManager.default.createDirectory(atPath: logPath, withIntermediateDirectories: true)
        }
        
        // 获取当前日期
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let currentDate = dateFormatter.string(from: Date())
        
        // 构建完整的日志文件路径
        let logFileName = "SNPLog-simulatorS-\(currentDate).log"
        let fullLogPath = (logPath as NSString).appendingPathComponent(logFileName)
        
        // 如果文件不存在，创建一个测试日志
        if !FileManager.default.fileExists(atPath: fullLogPath) {
            let testLog = """
            [INFO] \(Date()) 测试日志开始
            [DEBUG] 这是一条测试日志记录
            [INFO] 测试日志结束
            """
            try? testLog.write(to: URL(fileURLWithPath: fullLogPath), atomically: true, encoding: .utf8)
        }
        
        return fullLogPath
    }

    private func token() -> String {
        // 登录成功后返回的token
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2ODQ1MzE2NWFkNDVjNTUzNTc5MTY4YzUiLCJpYXQiOjE3NDk3MDI5MjMsImV4cCI6MTc0OTc4OTMyM30.czSOyDb5P0zAm0eFTomzdiKtHCxehXLyQW067rEk8d0"
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension NetworkTestViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return testItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = testItems[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case 0:
            testLoginAPI()
        case 1:
            testUploadLog()
        default:
            break
        }
    }
} 
