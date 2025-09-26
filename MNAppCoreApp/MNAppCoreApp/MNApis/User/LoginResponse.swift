//
//  LoginResponse.swift
//  MNAppCoreApp
//
//  Created by zhengnan on 2025/9/23.
//

import Foundation


struct LoginResponse: Decodable {
    let access_token: String
    let token_type: String
}
