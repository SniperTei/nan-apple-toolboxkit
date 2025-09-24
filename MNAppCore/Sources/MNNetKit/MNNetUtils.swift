// 删除Combine导入
import Foundation
import Alamofire

enum MNNetUtils {
    /// JSON编解码器
    static let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    /// 检查网络连接状态
    static func checkNetworkReachability(completion: @escaping (Bool) -> Void) {
        // 简单实现，实际项目中应使用NetworkReachabilityManager
        completion(false)
    }
    
    /// URL编码
    static func urlEncode(_ string: String) -> String {
        return string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? string
    }
}
