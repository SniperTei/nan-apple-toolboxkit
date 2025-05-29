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
    var success: Bool { get set }
}
