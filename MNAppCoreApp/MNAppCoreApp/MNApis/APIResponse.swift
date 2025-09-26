//
//  APIResponse.swift
//  MNAppCoreApp
//
//  Created by zhengnan on 2025/9/26.
//

import Foundation


struct APIResponse<T: Decodable>: Decodable {
    let code: String
    let statusCode: Int
    let data: T
    let msg: String
    let timestamp: String
}
