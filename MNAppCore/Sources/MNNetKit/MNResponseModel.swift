import Foundation

/// 实现 MNResponseProtocol 的具体响应模型类
public struct MNResponseModel<T: Decodable>: MNResponseProtocol {
    public let code: String
    public let status: Int
    public let msg: String
    public let data: T?
    public let timestamp: String
    
    public init(code: String, status: Int, msg: String, data: T? = nil, timestamp: String) {
        self.code = code
        self.status = status
        self.msg = msg
        self.data = data
        self.timestamp = timestamp
    }
    
    /// 自定义解码，如果API格式不一致可以在这里处理
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 尝试标准字段
        if let code = try? container.decode(String.self, forKey: .code) {
            self.code = code.trimmingCharacters(in: .whitespacesAndNewlines) // 去除空白字符
        } else {
            self.code = ""
        }
        
        // 尝试标准字段
        if let status = try? container.decode(Int.self, forKey: .status) {
            self.status = status
        } else if let status = try? container.decode(Int.self, forKey: .statusCode) {
            self.status = status
        } else {
            self.status = 0
        }
        
        // 尝试标准字段
        if let msg = try? container.decode(String.self, forKey: .msg) {
            self.msg = msg
        } else if let msg = try? container.decode(String.self, forKey: .message) {
            self.msg = msg
        } else {
            self.msg = ""
        }
        
        // 尝试标准数据字段
        if let data = try? container.decode(T.self, forKey: .data) {
            self.data = data
        } else {
            self.data = nil
        }
        
        // 尝试获取时间戳
        if let timestamp = try? container.decode(String.self, forKey: .timestamp) {
            self.timestamp = timestamp
        } else {
            // 如果没有时间戳，使用当前时间
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            self.timestamp = formatter.string(from: Date())
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case code, status, statusCode, msg, message, data, timestamp
    }
}
