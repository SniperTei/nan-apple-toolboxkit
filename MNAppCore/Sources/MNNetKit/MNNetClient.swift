// 删除Combine导入
import Foundation
import Moya

/// Mock模式枚举
public enum MockMode {
    case disabled // 禁用Mock
    case global   // 全局启用Mock
    case custom((MNRequestProtocol) -> Bool) // 自定义Mock规则
}

/// 网络库对外的主要接口，单例模式
public final class MNNetClient: @unchecked Sendable {
    public static let shared = MNNetClient()
    private let core: MNNetCore
    
    // 私有化构造方法，确保单例
    private init() {
        self.core = MNNetCore()
    }
    
    /// 配置全局网络参数
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
    public func send<T: Decodable, R: MNRequestProtocol>(
        _ request: R,
        responseType: T.Type,
        completion: @escaping (Result<T, MNError>) -> Void
    ) {
        // 转换为内部Target
        let target: MNInternalTarget = MNInternalTarget(request: request)
        
        // 检查是否需要使用Mock数据
        if MNMockHandler.shared.shouldUseMock(for: request, mode: core.mockMode) {
            MNMockHandler.shared.mockResponse(
                for: request,
                modelType: responseType,
                globalProvider: core.globalMockProvider,
                completion: completion
            )
            return
        }
        
        // 发起请求并处理结果
        core.request(target, modelType: MNResponse<T>.self) { result in
            switch result {
            case .success(let response):
                completion(.success(response.data))
            case .failure(let error):
                // 转换底层错误为MNError
                let mnError: MNError
                if let moyaError = error as? MoyaError {
                    switch moyaError {
                    case .statusCode(let response):
                        mnError = .businessError(code: response.statusCode, message: "HTTP状态码错误")
                    case .underlying(let error, _):
                        mnError = .networkError(error.localizedDescription)
                    default:
                        mnError = .networkError(moyaError.localizedDescription)
                    }
                } else if error is DecodingError {
                    mnError = .parseError("数据解析失败")
                } else {
                    mnError = .networkError("未知错误")
                }
                completion(.failure(mnError))
            }
        }
    }
}
