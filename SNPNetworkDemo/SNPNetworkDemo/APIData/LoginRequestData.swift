//
//  LoginRequestData.swift
//  SNPNetworkDemo
//
//  Created by zhengnan on 2025/5/22.
//

import Foundation

class LoginRequestData: SNPAPIRequestData {

    var username: String
    var password: String
    init(username: String, password: String) {
        self.username = username
        self.password = password
    }

    override func url() -> String {
        let baseURL = SNPNetworkConfig.shared.baseURL
        return baseURL + "/api/v1/login"
    }

    override func method() -> SNPHTTPMethod {
        return .post
    }

    override func params() -> [String : Any]? {
        return ["username": username, "password": password]
    }

    override func headers() -> [String : String]? {
        return nil
    }


}
