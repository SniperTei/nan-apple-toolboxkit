// 删除Combine导入
import Foundation

/// Mock数据处理工具
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
    
    /// 获取Mock数据
    func mockResponse<T: Decodable>(
        for request: MNRequestProtocol,
        modelType: T.Type,
        globalProvider: ((MNRequestProtocol) -> Data?)?,
        completion: @escaping (Result<T, MNError>) -> Void
    ) {
        // 1. 优先使用请求自身的mock数据
        if let data = request.mockData {
            decodeMockData(data, modelType: modelType, completion: completion)
            return
        }
        
        // 2. 其次使用全局mock提供者
        if let data = globalProvider?(request) {
            decodeMockData(data, modelType: modelType, completion: completion)
            return
        }
        
        // 3. 最后返回错误
        completion(.failure(.parseError("未配置Mock数据")))
    }
    
    /// 解析Mock数据并添加延迟模拟网络请求
    private func decodeMockData<T: Decodable>(
        _ data: Data,
        modelType: T.Type,
        completion: @escaping (Result<T, MNError>) -> Void
    ) {
        // 添加延迟模拟网络请求
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
            do {
                let model = try JSONDecoder().decode(modelType, from: data)
                completion(.success(model))
            } catch {
                completion(.failure(.parseError("Mock数据解析失败")))
            }
        }
    }
}
