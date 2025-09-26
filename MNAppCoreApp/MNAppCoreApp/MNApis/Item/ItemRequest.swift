//
//  ItemRequest.swift
//  MNAppCoreApp
//
//  Created by zhengnan on 2025/9/26.
//

import Foundation
import MNNetKit

// 物品列表请求
struct ItemRequest: MNRequestProtocol {
    var path: String = "api/v1/items"
    var method: MNHTTPMethod = .get
    var parameters: [String: Any]?

    // 构造方法
    init() {
        self.parameters = nil
    }
}

// 创建物品
struct ItemCreateRequest: MNRequestProtocol {
    var path: String = "api/v1/items"
    var method: MNHTTPMethod = .post
    var parameters: [String: Any]?

    // 构造方法
    init(title: String, description: String, price: Double, owner_id: String) {
        self.parameters = [
            "title": title,
            "description": description,
            "price": price
        ]
    }
}
