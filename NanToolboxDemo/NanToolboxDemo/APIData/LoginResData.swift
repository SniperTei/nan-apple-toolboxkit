//
//  LoginResData.swift
//  NanToolboxDemo
//
//  Created by zhengnan on 2025/6/6.
//

import Foundation

struct LoginResData: SNPAPIResponsable {
    // 用户信息结构
    struct UserInfo: Codable {
        let id: String
        let username: String
        let email: String?
        let nickname: String?
        let avatarUrl: String?
        let isAdmin: Bool
        let createdAt: String
    }
    
    // 登录数据结构
    struct LoginData: Codable {
        let token: String
        let user: UserInfo
    }
    
    // SNPAPIResponsable 协议要求的属性
    var code: String
    var statusCode: Int
    var msg: String
    var data: LoginData?
    var timestamp: String
    
    // SNPAPIResponsable 协议要求的方法
    func isSuccess() -> Bool {
        return code == "000000" && statusCode == 200
    }
    
    // 指定 DataType 为 LoginData
    typealias DataType = LoginData
}

