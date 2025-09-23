//
//  LoginRequest.swift
//  MNAppCoreApp
//
//  Created by zhengnan on 2025/9/23.
//

import Foundation
import MNNetKit


// 例如，创建一个用户登录请求
struct LoginRequest: MNRequestProtocol {
    var path: String = "api/v1/users/login"
    var method: MNHTTPMethod = .post
    var parameters: [String: Any]?
    
    // 构造方法
    init(email: String, password: String) {
        self.parameters = [
            "email": email,
            "password": password
        ]
    }
}
