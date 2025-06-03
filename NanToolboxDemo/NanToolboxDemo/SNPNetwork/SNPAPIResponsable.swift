//
//  SNPAPIResponsable.swift
//  SNPNetworkDemo
//
//  Created by zhengnan on 2025/5/28.
//

import Foundation

protocol SNPAPIResponsable: Codable {
    associatedtype DataType: Codable

    var code: String { get set }
    var statusCode: Int { get set }
    var msg: String { get set }
    var data: DataType? { get set }
    var timestamp: String { get set }
//    var success: Bool { get set }
    
    /// 判断请求是否成功
    func isSuccess() -> Bool
}

extension SNPAPIResponsable {
    /// 默认实现：当 statusCode 为 200 且 code 为 "000000" 时表示成功
    func isSuccess() -> Bool {
        return statusCode == 200 && code == "000000"
    }
}
