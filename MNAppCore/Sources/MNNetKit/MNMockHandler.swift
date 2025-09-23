import Foundation
import Combine

/// Mock数据处理工具
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class MNMockHandler: @unchecked Sendable {
    static let shared = MNMockHandler()
    private init() {}
    
    /// 判断是否应该使用Mock数据
    func shouldUseMock(for request: MNRequestProtocol, mode: MockMode) -> Bool {
        switch mode {
        case .disabled:
            return false
        case .global:
            return true
        case .custom(let shouldMock):
            return shouldMock(request)
        }
    }
    
    /// 获取Mock数据的Publisher
    func mockPublisher<T: Decodable>(
        for request: MNRequestProtocol,
        modelType: T.Type,
        globalProvider: ((MNRequestProtocol) -> Data?)?
    ) -> AnyPublisher<T, Error> {
        // 1. 优先使用请求自身的mock数据
        if let data = request.mockData {
            return decodeMockData(data, modelType: modelType)
        }
        
        // 2. 其次使用全局mock提供者
        if let data = globalProvider?(request) {
            return decodeMockData(data, modelType: modelType)
        }
        
        // 3. 最后返回错误
        return Fail(error: MNError.parseError("未配置Mock数据")).eraseToAnyPublisher()
    }
    
    /// 解析Mock数据并添加延迟模拟网络请求
    private func decodeMockData<T: Decodable>(
        _ data: Data,
        modelType: T.Type
    ) -> AnyPublisher<T, Error> {
        return Just(data)
            .decode(type: modelType, decoder: JSONDecoder())
            .delay(for: .milliseconds(300), scheduler: DispatchQueue.global())
            .eraseToAnyPublisher()
    }
}
