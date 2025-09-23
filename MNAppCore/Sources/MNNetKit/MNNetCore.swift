import Foundation
import Combine
import Alamofire
import Moya

/// 网络库核心控制器，封装Moya实现
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class MNNetCore {
    private var provider: MoyaProvider<MultiTarget>!
    var mockMode: MockMode = .disabled
    var globalMockProvider: ((MNRequestProtocol) -> Data?)?
    
    /// 初始化MoyaProvider
    func setupProvider() {
        // 配置Alamofire Session
        let configuration = URLSessionConfiguration.af.default
        configuration.timeoutIntervalForRequest = MNNetConfig.shared.timeoutInterval
        
        let session = Session(configuration: configuration)
        
        // 创建MoyaProvider，添加插件
        provider = MoyaProvider<MultiTarget>(
            session: session,
            plugins: [MNLogPlugin(), MNAuthPlugin()]
        )
    }
    
    /// 发起请求（内部使用）
    func request<T: TargetType, M: Decodable>(
        _ target: T,
        modelType: M.Type
    ) -> AnyPublisher<M, Error> {
        // 检查是否需要使用Mock数据
        if let internalTarget = target as? MNInternalTarget,
           MNMockHandler.shared.shouldUseMock(for: internalTarget.request, mode: mockMode) {
            return MNMockHandler.shared.mockPublisher(
                for: internalTarget.request,
                modelType: modelType,
                globalProvider: globalMockProvider
            )
        }
        
        // 修复类型转换问题，将泛型 T 转换为 MultiTarget
        return Future<M, Error> { promise in
            self.provider.request(MultiTarget(target)) { result in
                switch result {
                case .success(let response):
                    do {
                        let data = response.data
                        let model = try JSONDecoder().decode(modelType, from: data)
                        promise(.success(model))
                    } catch {
                        promise(.failure(error))
                    }
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
}
