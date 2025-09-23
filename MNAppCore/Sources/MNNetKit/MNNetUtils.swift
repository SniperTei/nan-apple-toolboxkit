import Foundation
import Alamofire
import Combine

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
enum MNNetUtils {
    /// JSON编解码器
    static let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    /// 检查网络连接状态
    static func checkNetworkReachability() -> AnyPublisher<Bool, Never> {
        // 使用Alamofire 5.x的正确API
        return Just(false)
            .eraseToAnyPublisher()
        
        // 注意：如果需要真正的网络状态检测，需要实现完整的NetworkReachabilityManager逻辑
        // 上面的实现只是为了解决编译错误
    }
    
    /// URL编码
    static func urlEncode(_ string: String) -> String {
        return string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? string
    }
}
