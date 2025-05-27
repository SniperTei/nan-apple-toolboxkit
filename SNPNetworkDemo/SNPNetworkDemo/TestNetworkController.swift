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
        config.baseURL = "http://localhost:3000"
        config.enableLog = true
    }
    
    @objc private func loginButtonTapped() {
        let loginRequestData = LoginRequestData(username: "admin", password: "admin0104")
        let manager = SNPNetworkManager.shared
        manager.request(loginRequestData) { [weak self] (result: Result<LoginResponseData, Error>) in
            switch result {
            case .success(let responseData):
                print("登录成功: \(responseData)")
                DispatchQueue.main.async {
                    self?.showAlert(title: "成功", message: "登录成功")
                }
            case .failure(let error):
                print("登录失败: \(error)")
                DispatchQueue.main.async {
                    self?.showAlert(title: "错误", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}
