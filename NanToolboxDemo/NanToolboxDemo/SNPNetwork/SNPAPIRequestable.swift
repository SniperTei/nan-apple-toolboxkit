//
//  SNPAPIRequestable.swift
//  SNPNetworkDemo
//
//  Created by zhengnan on 2025/5/28.
//

import Foundation

// 定义请求方法枚举
enum SNPHTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

// 定义参数编码方式
enum SNPParameterEncoding {
    case url
    case json
}

protocol SNPAPIRequestable {
    // HTTP 请求方法
    func method() -> SNPHTTPMethod
    
    // 请求URL
    func url() -> String
    
    // 请求参数
    func params() -> [String: Any]?
    
    // 请求头
    func headers() -> [String: String]?
    
    // 参数编码方式
    func encoding() -> SNPParameterEncoding

    // 是否需要认证
    func requiresAuthentication() -> Bool

    // 超时时间
    func timeoutInterval() -> TimeInterval

    // 如果失败是否默认展示错误信息
    func showErrorInfo() -> Bool
}

extension SNPAPIRequestable {
    func headers() -> [String: String]? {
        return nil
    }
    
    func params() -> [String: Any]? {
        return nil
    }
    
    func encoding() -> SNPParameterEncoding {
        return .json
    }
    
    func requiresAuthentication() -> Bool {
        return true
    }
    
    func timeoutInterval() -> TimeInterval {
        return 30
    }

    func showErrorInfo() -> Bool {
        return true
    }
}
