import Foundation

/// 网络库内部全局配置
public final class MNNetConfig: @unchecked Sendable {
    public static let shared = MNNetConfig()
    private init() {}
    
    /// 基础URL
    public var baseURL: URL!
    /// 默认超时时间
    public var timeoutInterval: TimeInterval = 30
    /// 是否开启日志
    public var enableLogging: Bool = true
    /// 错误处理
    public var errorHandler: MNErrorHandleProtocol = MNDefaultErrorHandler()
    /// 加载状态处理
    public var loadingHandler: MNLoadingProtocol = MNDefaultLoadingHandler()
}
