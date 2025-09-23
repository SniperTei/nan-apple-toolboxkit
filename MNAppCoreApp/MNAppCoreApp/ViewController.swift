//
//  ViewController.swift
//  MNAppCoreApp
//
//  Created by zhengnan on 2025/9/19.
//

import UIKit
import MNNetKit
import MNLoggerKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.red

        // 点击按钮调接口
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 100, y: 100, width: 200, height: 50)
        button.setTitle("点击我", for: .normal)
        button.addTarget(self, action: #selector(buttonClick), for: .touchUpInside)
        self.view.addSubview(button)
    }

    @objc func buttonClick() {
        // 调接口
        let loginRequest = LoginRequest(email: "admin@example.com", password: "admin123")
        _ = MNNetClient.shared.send(loginRequest, responseType: LoginResponse.self)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        print("登录失败: \(error.localizedDescription)")
                    case .finished:
                        print("登录请求完成")
                    }
                }, receiveValue: { userInfo in
                    print("登录成功，用户ID: \(userInfo.id)")
                    print("获取到Token: \(userInfo.token)")
                    // 保存用户信息或Token
                })
    }

}

