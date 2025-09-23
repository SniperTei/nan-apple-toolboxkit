import Foundation
import Combine
import Moya

/// Mock模式枚举
public enum MockMode {
    case disabled // 禁用Mock
    case global   // 全局启用Mock
    case custom((MNRequestProtocol) -> Bool) // 自定义Mock规则
}

/// 网络库对外的主要接口，单例模式
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class MNNetClient: @unchecked Sendable {
    public static let shared = MNNetClient()
    private let core: MNNetCore
    
    // 私有化构造方法，确保单例
    private init() {
        self.core = MNNetCore()
    }
    
    /// 配置全局网络参数
    /// - Parameters:
    ///   - baseURL: 基础URL
    ///   - timeoutInterval: 默认超时时间（秒）
    public func configure(baseURL: URL, timeoutInterval: TimeInterval = 30) {
        MNNetConfig.shared.baseURL = baseURL
        MNNetConfig.shared.timeoutInterval = timeoutInterval
        core.setupProvider()
    }
    
    /// 设置Mock模式
    public func setMockMode(_ mode: MockMode) {
        core.mockMode = mode
    }
    
    /// 设置全局Mock数据提供者
    public func setGlobalMockProvider(_ provider: @escaping (MNRequestProtocol) -> Data?) {
        core.globalMockProvider = provider
    }
    
    /// 发送请求
    /// - Parameters:
    ///   - request: 实现了MNRequestProtocol的请求对象
    ///   - responseType: 期望返回的数据模型类型
    /// - Returns: 包含结果的Combine Publisher
    public func send<T: Decodable, R: MNRequestProtocol>(
        _ request: R,
        responseType: T.Type
    ) -> AnyPublisher<T, MNError> {
        // 转换为内部Target
        let target = MNInternalTarget(request: request)
        
        // 发起请求并处理结果
        return core.request(target, modelType: MNResponse<T>.self)
            .mapError { error -> MNError in
                // 转换底层错误为MNError
                if let moyaError = error as? MoyaError {
                    switch moyaError {
                    case .statusCode(let response):
                        return .businessError(code: response.statusCode, message: "HTTP状态码错误")
                    case .underlying(let error, _):
                        return .networkError(error.localizedDescription)
                    default:
                        return .networkError(moyaError.localizedDescription)
                    }
                }
                if error is DecodingError {
                    return .parseError("数据解析失败")
                }
                return .networkError("未知错误")
            }
            .map { $0.data }
            .eraseToAnyPublisher()
    }
}
