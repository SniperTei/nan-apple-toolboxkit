//
//  LoginRequestData.swift
//  SNPNetworkDemo
//
//  Created by zhengnan on 2025/5/22.
//

import Foundation

struct LoginRequestData: SNPAPIRequestable {
    var username: String
    var password: String

    func method() -> SNPHTTPMethod { .post }
    func url() -> String { "/v1/user/login" }
    func params() -> [String: Any]? {
        ["username": username, "password": password]
    }
    func encoding() -> SNPParameterEncoding { .json }
}
