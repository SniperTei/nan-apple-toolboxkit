//
//  SNPAPIResponseData.swift
//  SNPNetworkDemo
//
//  Created by zhengnan on 2025/5/22.
//

import Foundation

class SNPAPIResponseData<T: Codable>: Codable {
    var code: String = "000000"
    var statusCode: Int = 200
    var msg: String = "success"
    var data: T?
    var timestamp: String = ""
    var success: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case code
        case statusCode = "status_code"
        case msg
        case data
        case timestamp
        case success
    }
}
