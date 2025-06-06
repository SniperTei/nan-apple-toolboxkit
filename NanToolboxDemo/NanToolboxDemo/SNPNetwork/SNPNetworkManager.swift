import Foundation
import Alamofire

class SNPNetworkManager {
    static let shared = SNPNetworkManager()
    
    private let session: Session
    private let logger: SNPNetworkLogger
    
    // 设置日志处理器
    func setLogHandler(_ handler: @escaping (SNPNetworkLog) -> Void) {
        logger.logHandler = handler
    }
    
    private init() {
        // 创建日志拦截器
        self.logger = SNPNetworkLogger()
        // 创建带有日志拦截器的Session
        self.session = Session(eventMonitors: [logger])
    }
    
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
        responseType: Response.Type,
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
        
        // 使用带有日志拦截器的session发起请求
        session.request(url,
                       method: afMethod,
                       parameters: request.params(),
                       encoding: afEncoding,
                       headers: afHeaders)
        .validate()
        .responseDecodable(of: responseType) { response in
            switch response.result {
            case .success(let value):
                if value.isSuccess() {
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
}
