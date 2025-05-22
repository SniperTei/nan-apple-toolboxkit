import Foundation

// 定义请求方法枚举
enum SNPHTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

// 定义参数编码方式
enum SNPParameterEncoding {
    case url
    case json
}

class SNPAPIRequestData {
    
    // HTTP 请求方法
    func method() -> SNPHTTPMethod {
        return .get
    }
    
    // 请求URL
    func url() -> String {
        return ""
    }
    
    // 请求参数
    func params() -> [String: Any]? {
        return nil
    }
    
    // 请求头
    func headers() -> [String: String]? {
        return nil
    }
    
    // 参数编码方式
    func encoding() -> SNPParameterEncoding {
        return .url
    }
}