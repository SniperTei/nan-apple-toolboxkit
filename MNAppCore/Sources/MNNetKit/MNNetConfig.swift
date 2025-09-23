import Foundation

/// 网络库内部全局配置
final class MNNetConfig: @unchecked Sendable {
    static let shared = MNNetConfig()
    private init() {}
    
    /// 基础URL
    var baseURL: URL!
    /// 默认超时时间
    var timeoutInterval: TimeInterval = 30
    /// 是否开启日志
    var enableLogging: Bool = true
}
