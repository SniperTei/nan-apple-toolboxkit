//
//  SNPNetworkDemoTests.swift
//  SNPNetworkDemoTests
//
//  Created by zhengnan on 2025/5/22.
//

import XCTest
@testable import SNPNetworkDemo

final class SNPNetworkDemoTests: XCTestCase {

    var expectation: XCTestExpectation!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let config = SNPNetworkConfig.shared
        config.baseURL = "http://localhost:3000/api"
        config.enableLog = true
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // 测试登录成功的情况
    func testLoginSuccess() throws {
        // 创建异步等待
        expectation = expectation(description: "Login Success Test")
        
        // 准备测试数据
        let loginRequestData = LoginRequestData(username: "admin", password: "admin0104")
        let manager = SNPNetworkManager.shared
        
        // 执行登录请求
        manager.request(loginRequestData, responseType: LoginResponseData.self) { (result: Result<LoginData?, SNPNetworkManager.NetworkError>) in
            switch result {
            case .success(let data):
                // 验证返回的数据
                XCTAssertNotNil(data, "登录成功应该返回数据")
                if let loginData = data {
                    XCTAssertNotNil(loginData.token, "登录成功应该包含 token")
                    XCTAssertNotNil(loginData.user, "登录成功应该包含用户信息")
                    XCTAssertEqual(loginData.user.username, "admin", "返回的用户名应该匹配")
                }
            case .failure(let error):
                XCTFail("登录不应该失败: \(error)")
            }
            
            // 标记测试完成
            self.expectation.fulfill()
        }
        
        // 等待异步操作完成，超时时间设置为 5 秒
        wait(for: [expectation], timeout: 5.0)
    }
    
    // 测试登录失败的情况 - 密码错误
    func testLoginFailureWithWrongPassword() throws {
        // 创建异步等待
        expectation = expectation(description: "Login Failure Test - Wrong Password")
        
        // 准备测试数据 - 使用错误的密码
        let loginRequestData = LoginRequestData(username: "admin", password: "wrongpassword")
        let manager = SNPNetworkManager.shared
        
        // 执行登录请求
        manager.request(loginRequestData, responseType: LoginResponseData.self) { (result: Result<LoginData?, SNPNetworkManager.NetworkError>) in
            switch result {
            case .success:
                XCTFail("使用错误的密码不应该登录成功")
            case .failure(let error):
                // 验证错误类型
                if case let SNPNetworkManager.NetworkError.serverError(code, message) = error {
                    XCTAssertEqual(code, "A00003", "应该返回密码错误的错误码")
                    XCTAssertFalse(message.isEmpty, "错误信息不应该为空")
                } else {
                    XCTFail("应该返回服务器错误，而不是其他类型的错误")
                }
            }
            
            // 标记测试完成
            self.expectation.fulfill()
        }
        
        // 等待异步操作完成，超时时间设置为 5 秒
        wait(for: [expectation], timeout: 5.0)
    }
    
    // 测试登录失败的情况 - 网络错误
    func testLoginFailureWithNetworkError() throws {
        // 创建异步等待
        expectation = expectation(description: "Login Failure Test - Network Error")
        
        // 修改为错误的基础 URL 来模拟网络错误
        SNPNetworkConfig.shared.baseURL = "https://invalid-url:3000"
        
        // 准备测试数据
        let loginRequestData = LoginRequestData(username: "admin", password: "admin0104")
        let manager = SNPNetworkManager.shared
        
        // 执行登录请求
        manager.request(loginRequestData, responseType: LoginResponseData.self) { (result: Result<LoginData?, SNPNetworkManager.NetworkError>) in
            switch result {
            case .success:
                XCTFail("网络错误情况下不应该登录成功")
            case .failure(let error):
                // 验证是否是网络错误
                if case SNPNetworkManager.NetworkError.networkError = error {
                    // 测试通过
                } else {
                    XCTFail("应该返回网络错误，而不是其他类型的错误")
                }
            }
            
            // 标记测试完成
            self.expectation.fulfill()
        }
        
        // 等待异步操作完成，超时时间设置为 5 秒
        wait(for: [expectation], timeout: 5.0)
        
        // 恢复正确的基础 URL
        SNPNetworkConfig.shared.baseURL = "http://localhost:3000"
    }
    
    // 测试空用户名或密码的情况
    func testLoginWithEmptyCredentials() throws {
        // 测试空用户名
        let emptyUsernameRequest = LoginRequestData(username: "", password: "password")
        XCTAssertFalse(emptyUsernameRequest.isValid(), "空用户名应该验证失败")
        
        // 测试空密码
        let emptyPasswordRequest = LoginRequestData(username: "admin", password: "")
        XCTAssertFalse(emptyPasswordRequest.isValid(), "空密码应该验证失败")
        
        // 测试都为空
        let emptyBothRequest = LoginRequestData(username: "", password: "")
        XCTAssertFalse(emptyBothRequest.isValid(), "空用户名和密码应该验证失败")
        
        // 测试正常情况
        let validRequest = LoginRequestData(username: "admin", password: "password")
        XCTAssertTrue(validRequest.isValid(), "有效的用户名和密码应该验证通过")
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
