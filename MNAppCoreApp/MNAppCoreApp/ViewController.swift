//
//  ViewController.swift
//  MNAppCoreApp
//
//  Created by zhengnan on 2025/9/19.
//

import UIKit
import MNNetKit
import MNLoggerKit
import Combine

class ViewController: UIViewController {
    
    // 将cancellables改为类的属性
    private var cancellables = Set<AnyCancellable>()

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
        print("22开始调接口")
        loginRequest.send(LoginResponse.self) { result in
            switch result {
            case .success(let userInfo):
                print("11登录成功")
                print("11获取到Token: \(userInfo.access_token)")
            case .failure(let error):
                print("11登录失败: \(error.localizedDescription)")
            }
        }
    }

}

