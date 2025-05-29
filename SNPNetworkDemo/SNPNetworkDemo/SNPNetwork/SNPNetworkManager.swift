import Foundation
import Alamofire

class SNPNetworkManager {
    static let shared = SNPNetworkManager()
    
    private init() {}
    
    // 定义网络错误类型
    enum NetworkError: Error {
        case invalidURL
        case invalidResponse
        case decodingError(Error)
        case networkError(Error)
        case serverError(code: String, message: String)
    }
    
    func request<Request: SNPAPIRequestable, Response: SNPAPIResponsable>(
        _ request: Request,
        completion: @escaping (Result<Response.DataType?, NetworkError>) -> Void
    ) {
        let url = SNPNetworkConfig.shared.baseURL + request.url()
        
        // 合并请求头
        var headers = SNPNetworkConfig.shared.commonHeaders
        if let requestHeaders = request.headers() {
            headers.merge(requestHeaders) { (_, new) in new }
        }
        
        // 转换为 Alamofire 的类型
        let afMethod = HTTPMethod(rawValue: request.method().rawValue)
        let afHeaders = HTTPHeaders(headers)
        let afEncoding: ParameterEncoding = request.encoding() == .json ? JSONEncoding.default : URLEncoding.default
        
        // 发起请求
        AF.request(url,
                  method: afMethod,
                  parameters: request.params(),
                  encoding: afEncoding,
                  headers: afHeaders)
        .validate()
        .responseDecodable(of: Response.self) { response in
            if SNPNetworkConfig.shared.enableLog {
                self.logResponse(url: url, headers: headers, params: request.params(), response: response)
            }
            
            switch response.result {
            case .success(let value):
                if value.success {
                    completion(.success(value.data))
                } else {
                    if request.showErrorInfo() {
                    // 这里可以替换为你自己的弹窗/Toast 
                        print("请求失败：\(value.msg)")
                    }
                    completion(.failure(.serverError(code: value.code, message: value.msg)))
                }
            case .failure(let error):
                if request.showErrorInfo() {
                    // 这里可以替换为你自己的弹窗/Toast
                    print("网络错误：\(error.localizedDescription)")
                }
                if let decodingError = error as? DecodingError {
                    completion(.failure(.decodingError(decodingError)))
                } else {
                    completion(.failure(.networkError(error)))
                }
            }
        }
    }
    
    // 日志打印辅助方法
    private func logResponse<T>(
        url: String,
        headers: [String: String],
        params: [String: Any]?,
        response: DataResponse<T, AFError>
    ) {
        print("=== Network Request Log ===")
        print("URL: \(url)")
        print("Headers: \(headers)")
        print("Params: \(String(describing: params))")
        if let data = response.data, let json = try? JSONSerialization.jsonObject(with: data) {
            print("Response: \(json)")
        } else {
            print("Response: \(String(describing: response.value))")
        }
        print("=========================")
    }
}
