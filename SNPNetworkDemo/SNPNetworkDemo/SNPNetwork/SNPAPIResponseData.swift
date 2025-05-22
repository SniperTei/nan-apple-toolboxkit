//
//  SNPAPIResponseData.swift
//  SNPNetworkDemo
//
//  Created by zhengnan on 2025/5/22.
//

import Foundation

class SNPAPIResponseData: Codable {
    var code: Int = 0
    var message: String = ""
    var success: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case code
        case message
        case success
    }
}
