//
//  TestNetworkController.swift
//  SNPNetworkDemo
//
//  Created by zhengnan on 2025/5/22.
//

import Foundation
import UIKit

class TestNetworkController: UIViewController {
    
    private lazy var loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("登录", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNetwork()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(loginButton)
        
        // 设置按钮约束
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loginButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loginButton.widthAnchor.constraint(equalToConstant: 200),
            loginButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupNetwork() {
        let config = SNPNetworkConfig.shared
        config.baseURL = "http://localhost:3000/api"
        config.enableLog = true
    }
    
    @objc private func loginButtonTapped() {
        // 假设你有两个输入框 usernameTextField 和 passwordTextField
        let username = "admin"
        let password = "admin0104"
        let request = LoginRequestData(username: username, password: password)
        
        SNPNetworkManager.shared.request(request, responseType: LoginResponseData.self) { result in
            switch result {
            case .success(let loginData):
                if let loginData = loginData {
                    // 登录成功，处理token和用户信息
                    print("登录成功，token: \(loginData.token)")
                    print("用户昵称: \(loginData.user.nickname)")
                    // 这里可以保存token，跳转页面等
                } else {
                    print("登录成功，但未返回数据")
                }
            case .failure(let error):
                // 失败时，SNPNetworkManager 已经根据 showErrorInfo 自动弹窗或打印
                print("登录失败: \(error)")
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}
