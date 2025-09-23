import Foundation

/// 统一响应模型
public struct MNResponse<T: Decodable>: Decodable {
    public let code: Int
    public let message: String
    public let data: T
    
    // 自定义解码，如果API格式不一致可以在这里处理
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 尝试标准字段
        if let code = try? container.decode(Int.self, forKey: .code) {
            self.code = code
        } else if let code = try? container.decode(Int.self, forKey: .status) {
            // 如果使用status字段
            self.code = code
        } else {
            // 默认值
            self.code = 0
        }
        
        // 尝试标准字段
        if let message = try? container.decode(String.self, forKey: .message) {
            self.message = message
        } else if let message = try? container.decode(String.self, forKey: .msg) {
            // 如果使用msg字段
            self.message = message
        } else {
            // 默认值
            self.message = ""
        }
        
        // 尝试标准数据字段
        if let data = try? container.decode(T.self, forKey: .data) {
            self.data = data
        } else {
            // 如果没有data字段，直接解码整个响应
            let singleValueContainer = try decoder.singleValueContainer()
            self.data = try singleValueContainer.decode(T.self)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case code, status, message, msg, data
    }
}

/// 网络库统一错误类型
public enum MNError: Error, LocalizedError {
    case networkError(String)         // 网络错误（超时、无网络等）
    case businessError(code: Int, message: String)  // 业务错误（后端返回的错误）
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
