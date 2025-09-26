import Foundation

/// 网络库统一错误类型
public enum MNError: Error, LocalizedError {
    case networkError(String)         // 网络错误（超时、无网络等）
    case businessError(code: String, msg: String)  // 业务错误（后端返回的错误）
    case parseError(String)           // 数据解析错误
    case invalidURL                   // 无效的URL
    
    public var errorDescription: String? {
        switch self {
        case .networkError(let msg):
            return "网络错误: \(msg)"
        case .businessError(let code, let msg):
            return "业务错误(\(code)): \(msg)"
        case .parseError(let msg):
            return "数据解析错误: \(msg)"
        case .invalidURL:
            return "无效的请求地址"
        }
    }
}