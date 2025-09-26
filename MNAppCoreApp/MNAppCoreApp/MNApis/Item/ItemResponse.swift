//
//  ItemResponse.swift
//  MNAppCoreApp
//
//  Created by zhengnan on 2025/9/26.
//

import Foundation


// 物品列表响应
struct ItemResponse: Decodable {
    var items: [Item]?
    var page_size: Int?
    var total: Int?
    var page: Int?
}

// 物品模型
struct Item: Codable {
    var id: String?
    var title: String?
    var description: String?
    var price: Double?
    var owner_id: String?
}

struct ItemCreateResponse: Decodable {
    var id: Int?
    var title: String?
    var description: String?
    var price: Double?
    var owner_id: String?
}
