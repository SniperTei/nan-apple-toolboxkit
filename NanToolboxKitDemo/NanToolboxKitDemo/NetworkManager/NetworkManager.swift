import Foundation
import Alamofire

// 网络配置
struct NetworkConfig {
    static var baseURL = "http://localhost:3000"
    static var timeoutInterval: TimeInterval = 30
    static var defaultHeaders: HTTPHeaders = [
        "Content-Type": "application/json",
        "Accept": "application/json"
    ]
}

// 统一响应格式
struct APIResponse<T: Codable>: Codable {
    let code: String
    let statusCode: Int
    let msg: String
    let data: T?
    let timestamp: String
}

// 网络错误类型
enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(code: String, message: String)
    case networkError(Error)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .noData:
            return "没有数据"
        case .decodingError:
            return "数据解析错误"
        case .serverError(let code, let message):
            return "服务器错误[\(code)]: \(message)"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        }
    }
}

class NetworkManager {
    static let shared = NetworkManager()
    
    private let session: Session
    private let interceptor: RequestInterceptor
    
    private init() {
        // 配置
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = NetworkConfig.timeoutInterval
        
        // 请求拦截器
        interceptor = NetworkRequestInterceptor()
        
        // 创建session
        session = Session(
            configuration: configuration,
            interceptor: interceptor
        )
    }
    
    // 基本请求方法
    func request<T: Codable>(
        _ path: String,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        headers: HTTPHeaders? = nil,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        // 构建完整URL
        let url = NetworkConfig.baseURL + path
        
        // 合并请求头
        var finalHeaders = NetworkConfig.defaultHeaders
        headers?.forEach { finalHeaders.add($0) }
        
        // 创建请求
        session.request(
            url,
            method: method,
            parameters: parameters,
            encoding: method == .get ? URLEncoding.default : JSONEncoding.default,
            headers: finalHeaders
        )
        .validate()
        .responseDecodable(of: APIResponse<T>.self) { response in
            switch response.result {
            case .success(let apiResponse):
                if apiResponse.statusCode == 200 {
                    if let data = apiResponse.data {
                        completion(.success(data))
                    } else {
                        completion(.failure(.noData))
                    }
                } else {
                    completion(.failure(.serverError(
                        code: apiResponse.code,
                        message: apiResponse.msg
                    )))
                }
            case .failure(let error):
                completion(.failure(.networkError(error)))
            }
        }
    }
    
    // GET 请求
    func get<T: Codable>(
        _ path: String,
        parameters: Parameters? = nil,
        headers: HTTPHeaders? = nil,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        request(path, method: .get, parameters: parameters, headers: headers, completion: completion)
    }
    
    // POST 请求
    func post<T: Codable>(
        _ path: String,
        parameters: Parameters? = nil,
        headers: HTTPHeaders? = nil,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        request(path, method: .post, parameters: parameters, headers: headers, completion: completion)
    }
}

// 请求拦截器
class NetworkRequestInterceptor: RequestInterceptor {
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var urlRequest = urlRequest
        
        // 添加通用请求头，如token等
        if let token = UserDefaults.standard.string(forKey: "userToken") {
            urlRequest.headers.add(.authorization(bearerToken: token))
        }
        
        completion(.success(urlRequest))
    }
    
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        // 请求失败重试逻辑
        guard let statusCode = request.response?.statusCode else {
            completion(.doNotRetry)
            return
        }
        
        switch statusCode {
        case 408: // 请求超时
            completion(.retryWithDelay(1.0)) // 1秒后重试
        case 500...599: // 服务器错误
            completion(.retryWithDelay(2.0)) // 2秒后重试
        default:
            completion(.doNotRetry)
        }
    }
}

// API 服务扩展
extension NetworkManager {
    func login(username: String, password: String, completion: @escaping (Result<User, NetworkError>) -> Void) {
        let parameters: Parameters = [
            "username": username,
            "password": password
        ]
        post("/api/v1/user/login", parameters: parameters, completion: completion)
    }
}

// 使用示例扩展
extension NetworkManager {
    func fetchUserData(userId: String, completion: @escaping (Result<User, NetworkError>) -> Void) {
        let url = "https://api.example.com/users/\(userId)"
        get(url, completion: completion)
    }
}

// 示例数据模型
struct User: Codable {
    let id: String
    let name: String
    let email: String
}
