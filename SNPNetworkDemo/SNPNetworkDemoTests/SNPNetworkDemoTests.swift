//
//  SNPNetworkDemoTests.swift
//  SNPNetworkDemoTests
//
//  Created by zhengnan on 2025/5/22.
//

import XCTest
@testable import SNPNetworkDemo

final class SNPNetworkDemoTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let config = SNPNetworkConfig.shared
        config.baseURL = "http://localhost:3000"
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLogin() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let loginRequestData = LoginRequestData(username: "admin", password: "admin0104")
        let manager = SNPNetworkManager.shared
        // manager.request(loginRequestData) { (responseData, error) in
        //     if let error = error {
        //         print("login error: \(error)")
        //         return
        //     }
        //     if let responseData = responseData {
        //         print("login success: \(responseData)")
        //     }
        // }
        // let loginRequestData = LoginRequestData(username: "admin", password: "admin0104")
        // let manager = SNPNetworkManager.shared
        manager.request(loginRequestData) { (result: Result<LoginResponseData, Error>) in
            switch result {
            case .success(let responseData):
                print("login success: \(responseData)")
            case .failure(let error):
                print("login error: \(error)")
            }
        }
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
