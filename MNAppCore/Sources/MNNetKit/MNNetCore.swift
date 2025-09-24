// 删除Combine导入
import Foundation
import Alamofire
import Moya

/// 网络库核心控制器，封装Moya实现
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
        modelType: M.Type,
        completion: @escaping (Result<M, Error>) -> Void
    ) {
        // 修复类型转换问题，将泛型 T 转换为 MultiTarget
        provider.request(MultiTarget(target)) { result in
            switch result {
            case .success(let response):
                do {
                    let data = response.data
                    let model = try JSONDecoder().decode(modelType, from: data)
                    completion(.success(model))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
