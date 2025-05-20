import UIKit
import NanToolboxKit

// 登录请求模型
struct LoginRequest: Codable {
    let username: String
    let password: String
}

// 登录响应模型
struct LoginResponse: Codable {
    let code: String
    let statusCode: Int
    let msg: String
    let data: LoginData?  // 改为可选类型
    let timestamp: String
    
    struct LoginData: Codable {
        let token: String
        let user: UserInfo
    }
    
    struct UserInfo: Codable {
        let id: String
        let username: String
        let email: String
        let nickname: String
        let avatarUrl: String
        let isAdmin: Bool
        let createdAt: String
    }
}

class TestAPIController: UIViewController {
    
    private let usernameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "用户名"
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "密码"
        textField.isSecureTextEntry = true
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("测试登录", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let resultTextView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.font = .systemFont(ofSize: 14)
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.cornerRadius = 5
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // 设置默认值
        usernameTextField.text = "admin"
        passwordTextField.text = "admin0104"
    }
    
    private func setupUI() {
        title = "接口测试"
        view.backgroundColor = .white
        
        view.addSubview(usernameTextField)
        view.addSubview(passwordTextField)
        view.addSubview(loginButton)
        view.addSubview(resultTextView)
        
        NSLayoutConstraint.activate([
            usernameTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            usernameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            usernameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            usernameTextField.heightAnchor.constraint(equalToConstant: 40),
            
            passwordTextField.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: 20),
            passwordTextField.leadingAnchor.constraint(equalTo: usernameTextField.leadingAnchor),
            passwordTextField.trailingAnchor.constraint(equalTo: usernameTextField.trailingAnchor),
            passwordTextField.heightAnchor.constraint(equalToConstant: 40),
            
            loginButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 20),
            loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loginButton.heightAnchor.constraint(equalToConstant: 44),
            loginButton.widthAnchor.constraint(equalToConstant: 120),
            
            resultTextView.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 20),
            resultTextView.leadingAnchor.constraint(equalTo: usernameTextField.leadingAnchor),
            resultTextView.trailingAnchor.constraint(equalTo: usernameTextField.trailingAnchor),
            resultTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
        
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
    }
    
    // 修改请求处理逻辑
    @objc private func loginButtonTapped() {
        guard let username = usernameTextField.text, !username.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            resultTextView.text = "请输入用户名和密码"
            return
        }
        
        // 将请求参数转换为字典
        let parameters: [String: Any] = [
            "username": username,
            "password": password
        ]
        
        let baseURL = "http://localhost:3000"
        let loginURL = "\(baseURL)/api/v1/user/login"
        
        NetworkManager.shared.post(loginURL, parameters: parameters) { [weak self] (result: Result<LoginResponse, NetworkError>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    // 根据状态码判断是否成功
                    if response.statusCode == 200 {
                        guard let data = response.data else {
                            self?.resultTextView.text = "数据格式错误"
                            return
                        }
                        
                        let formattedResponse = """
                        登录成功！
                        
                        状态码: \(response.statusCode)
                        消息: \(response.msg)
                        Token: \(data.token)
                        
                        用户信息:
                        ID: \(data.user.id)
                        用户名: \(data.user.username)
                        昵称: \(data.user.nickname)
                        邮箱: \(data.user.email)
                        
                        时间戳: \(response.timestamp)
                        """
                        self?.resultTextView.text = formattedResponse
                    } else {
                        // 显示错误信息
                        let errorResponse = """
                        请求失败！
                        
                        状态码: \(response.statusCode)
                        错误码: \(response.code)
                        错误信息: \(response.msg)
                        时间戳: \(response.timestamp)
                        """
                        self?.resultTextView.text = errorResponse
                    }
                    
                case .failure(let error):
                    self?.resultTextView.text = "请求失败：\(error.localizedDescription)"
                }
            }
        }
    }
}
