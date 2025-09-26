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
        core.request(target, modelType: MNResponseModel<T>.self) { result in
            switch result {
            case .success(let response):
                // 添加调试信息
                print("[调试] 响应code: \(response.code)")
                print("[调试] isSuccess: \(response.isSuccess)")
                print("[调试] data是否为空: \(response.data == nil)")
                
                // 更健壮的成功条件检查
                if response.code == "000000" {
                    if let data = response.data {
                        completion(.success(data))
                    } else {
                        // 如果code是成功，但data为nil，仍然返回成功但data为空
                        completion(.success(try! JSONDecoder().decode(T.self, from: Data())))
                    }
                } else {
                    // 处理业务错误
                    let errorCode = response.code
                    let errorMessage = response.errorDescription ?? "请求失败"
                    completion(.failure(.businessError(code: errorCode, msg: errorMessage)))
                }
            case .failure(let error):
                // 转换底层错误为MNError
                let mnError: MNError
                if let moyaError = error as? MoyaError {
                    switch moyaError {
                    case .statusCode(let response):
                        // 修复参数标签和类型：将 message 改为 msg，并将 Int 转换为 String
                        mnError = .businessError(code: "\(response.statusCode)", msg: "HTTP状态码错误")
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
