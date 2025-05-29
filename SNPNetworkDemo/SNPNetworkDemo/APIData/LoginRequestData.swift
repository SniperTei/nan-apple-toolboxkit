//
//  LoginRequestData.swift
//  SNPNetworkDemo
//
//  Created by zhengnan on 2025/5/22.
//

import Foundation

class LoginRequestData: SNPAPIRequestable {
    
    var username: String
    var password: String
    
    init(username: String, password: String) {
        self.username = username
        self.password = password
    }
    
    func method() -> SNPHTTPMethod {
        return .post
    }
    
    func url() -> String {
        return "/api/login"
    }
    
    func params() -> [String: Any]? {
        return [
            "username": username,
            "password": password
        ]
    }
    
    func encoding() -> SNPParameterEncoding {
        return .json
    }
}
