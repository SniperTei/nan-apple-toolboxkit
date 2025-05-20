import Foundation
import Alamofire

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
}

class NetworkManager {
    static let shared = NetworkManager()
    
    private init() {}
    
    // 基本请求方法
    func request<T: Codable>(
        _ url: String,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        headers: HTTPHeaders? = nil,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        AF.request(
            url,
            method: method,
            parameters: parameters,
            headers: headers
        ).responseDecodable(of: T.self) { response in
            switch response.result {
            case .success(let value):
                completion(.success(value))
            case .failure(let error):
                completion(.failure(.serverError(error.localizedDescription)))
            }
        }
    }
    
    // GET 请求
    func get<T: Codable>(
        _ url: String,
        parameters: Parameters? = nil,
        headers: HTTPHeaders? = nil,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        request(url, method: .get, parameters: parameters, headers: headers, completion: completion)
    }
    
    // POST 请求
    func post<T: Codable>(
        _ url: String,
        parameters: Parameters? = nil,
        headers: HTTPHeaders? = nil,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        request(url, method: .post, parameters: parameters, headers: headers, completion: completion)
    }
    
    // 上传文件
    func upload(
        _ url: String,
        fileURL: URL,
        headers: HTTPHeaders? = nil,
        completion: @escaping (Result<String, NetworkError>) -> Void
    ) {
        AF.upload(
            fileURL,
            to: url,
            headers: headers
        ).responseString { response in
            switch response.result {
            case .success(let value):
                completion(.success(value))
            case .failure(let error):
                completion(.failure(.serverError(error.localizedDescription)))
            }
        }
    }
    
    // 下载文件
    func download(
        _ url: String,
        destination: DownloadRequest.Destination? = nil,
        completion: @escaping (Result<URL, NetworkError>) -> Void
    ) {
        AF.download(
            url,
            to: destination
        ).responseURL { response in
            switch response.result {
            case .success(let url):
                completion(.success(url))
            case .failure(let error):
                completion(.failure(.serverError(error.localizedDescription)))
            }
        }
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
