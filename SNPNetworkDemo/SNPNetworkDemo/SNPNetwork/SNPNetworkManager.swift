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
            for (key, value) in requestHeaders {
                headers[key] = value
            }
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
