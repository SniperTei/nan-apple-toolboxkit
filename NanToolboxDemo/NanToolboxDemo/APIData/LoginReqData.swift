//
//  LoginReqData.swift
//  NanToolboxDemo
//
//  Created by zhengnan on 2025/6/6.
//

import Foundation

struct LoginReqData: SNPAPIRequestable {
    let username: String
    let password: String
    
    func method() -> SNPHTTPMethod {
        return .post
    }
    
    func url() -> String {
        return "/v1/user/login"
    }
    
    func params() -> [String: Any]? {
        return [
            "username": username,
            "password": password
        ]
    }
    
    func headers() -> [String: String]? {
        return [
            "Content-Type": "application/json"
        ]
    }
    
    func encoding() -> SNPParameterEncoding {
        return .json
    }
    
    func showErrorInfo() -> Bool {
        return true
    }
}