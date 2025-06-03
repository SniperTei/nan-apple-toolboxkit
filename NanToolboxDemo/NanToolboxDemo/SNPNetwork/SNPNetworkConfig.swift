//
//  SNPNetworkConfig.swift
//  SNPNetworkDemo
//
//  Created by zhengnan on 2025/5/22.
//

import Foundation

class SNPNetworkConfig {
    static let shared = SNPNetworkConfig()
    
    private init() {}
    
    // 基础URL
    var baseURL: String = ""
    
    // 超时时间
    var timeoutInterval: TimeInterval = 30
    
    // 公共请求头
    var commonHeaders: [String: String] = [:]
    
    // 是否开启调试日志
    var enableLog: Bool = false
}
