//
//  LoginResponseData.swift
//  SNPNetworkDemo
//
//  Created by zhengnan on 2025/5/22.
//

import Foundation

struct User: Codable {
    let id: String
    let username: String
    let email: String
    let isAdmin: Bool
    let createdAt: String
    // 可选字段
    let nickname: String?
    let avatarUrl: String?
}

struct LoginData: Codable {
    let token: String
    let user: User
}

struct LoginResponseData: SNPAPIResponsable {
    typealias DataType = LoginData

    var code: String
    var statusCode: Int
    var msg: String
    var data: LoginData?
    var timestamp: String
}
