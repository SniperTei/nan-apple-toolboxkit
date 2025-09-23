//
//  LoginResponse.swift
//  MNAppCoreApp
//
//  Created by zhengnan on 2025/9/23.
//

import Foundation


struct LoginResponse: Decodable {
    let id: String
    let username: String
    let nickname: String
    let avatar: String?
    let token: String
}
