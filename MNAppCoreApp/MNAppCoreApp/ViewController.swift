//
//  ViewController.swift
//  MNAppCoreApp
//
//  Created by zhengnan on 2025/9/19.
//

import UIKit
import MNNetKit
import MNLoggerKit
import Combine

class ViewController: UIViewController {
    
    // 将cancellables改为类的属性
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.red

        // 点击按钮调接口
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 100, y: 100, width: 200, height: 50)
        button.setTitle("点击我", for: .normal)
        button.addTarget(self, action: #selector(buttonClick), for: .touchUpInside)
        self.view.addSubview(button)

        // 获取物品列表按钮
        let getItemListBtn = UIButton(type: .system)
        getItemListBtn.frame = CGRect(x: 100, y: 200, width: 200, height: 50)
        getItemListBtn.setTitle("获取物品列表", for: .normal)
        getItemListBtn.addTarget(self, action: #selector(getItemListClick), for: .touchUpInside)
        self.view.addSubview(getItemListBtn)

        // 创建物品按钮
        let createItemBtn = UIButton(type: .system)
        createItemBtn.frame = CGRect(x: 100, y: 300, width: 200, height: 50)
        createItemBtn.setTitle("创建物品", for: .normal)
        createItemBtn.addTarget(self, action: #selector(createItemClick), for: .touchUpInside)
        self.view.addSubview(createItemBtn)
    }

    @objc func buttonClick() {
        // 调接口
//        let loginRequest = LoginRequest(email: "admin@example.com", password: "admin123")
        let loginRequest = LoginRequest(email: "admin@examsdfple.com", password: "admin123444")
        print("22开始调接口")
        loginRequest.send(APIResponse<LoginResponse>.self) { result in
            switch result {
            case .success(let apiResponse):
                print("我的登录成功")
                print("我的获取到Token: \(apiResponse.data.access_token)")
            case .failure(let error):
                print("我的登录失败: \(error.localizedDescription)")
            }
        }
    }

    @objc func getItemListClick() {
        // 调接口
        let itemListRequest = ItemRequest()
        print("物品列表开始调接口")
        itemListRequest.send(APIResponse<ItemResponse>.self) { result in
            switch result {
            case .success(let apiResponse):
                print("我的获取物品列表成功")
                print("我的获取到物品列表: \(apiResponse.data)")
                print("我的获取到物品列表数量: \(apiResponse.data.total ?? 0)")
            case .failure(let error):
                print("我的获取物品列表失败: \(error.localizedDescription)")
            }
        }
    }

    @objc func createItemClick() {
        // 调接口
        let createItemRequest = ItemCreateRequest(title: "物品1", description: "物品1的描述", price: 100, owner_id: "1")
        print("创建物品开始调接口")
        createItemRequest.send(APIResponse<ItemCreateResponse>.self) { result in
            switch result {
            case .success(let apiResponse):
                print("我的创建物品成功")
                print("响应状态码: \(apiResponse.statusCode)")
                print("响应消息: \(apiResponse.msg)")
                if let itemCreateResponse = apiResponse.data {
                    print("我的创建到物品: \(itemCreateResponse.title ?? "无")")
                    print("我的创建到物品ID: \(itemCreateResponse.id ?? 0)")
                }
            case .failure(let error):
                print("我的创建物品失败: \(error.localizedDescription)")
            }
        }
    }

}

