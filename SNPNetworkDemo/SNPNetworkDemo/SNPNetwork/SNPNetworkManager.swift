//
//  SNPNetworkManager.swift
//  SNPNetworkDemo
//
//  Created by zhengnan on 2025/5/22.
//

import Foundation
import Alamofire

class SNPNetworkManager {
    static let shared = SNPNetworkManager()
    
    private init() {}
    
    func request<T: SNPAPIResponseData>(_ request: SNPAPIRequestData, completion: @escaping (Result<T, Error>) -> Void) {
        let url = SNPNetworkConfig.shared.baseURL + request.url()
        
        // 合并请求头
        var headers = SNPNetworkConfig.shared.commonHeaders
        if let requestHeaders = request.headers() {
            headers.add(requestHeaders)
        }
        
        // 创建请求配置
        let requestConfig = URLSessionConfiguration.default
        requestConfig.timeoutIntervalForRequest = SNPNetworkConfig.shared.timeoutInterval
        
        // 创建Session
        let session = Session(configuration: requestConfig)
        
        // 发起请求
        session.request(url,
                       method: request.method(),
                       parameters: request.params(),
                       encoding: request.encoding(),
                       headers: headers)
        .responseDecodable(of: T.self) { response in
            if SNPNetworkConfig.shared.enableLog {
                print("Request URL: \(url)")
                print("Request Headers: \(headers)")
                print("Request Params: \(String(describing: request.params()))")
                print("Response: \(String(describing: response.value))")
            }
            
            switch response.result {
            case .success(let value):
                completion(.success(value))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
