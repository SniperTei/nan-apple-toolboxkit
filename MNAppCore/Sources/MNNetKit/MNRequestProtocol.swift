import Foundation
import Moya

/// 抽象请求协议，调用方通过实现此协议定义接口
public protocol MNRequestProtocol {
    /// 接口路径（如 "/user/login"）
    var path: String { get }
    /// 请求方法
    var method: MNHTTPMethod { get }
    /// 请求参数
    var parameters: [String: Any]? { get }
    /// 基础URL（可选，默认使用全局配置）
    var baseURL: URL? { get }
    /// 超时时间（可选，默认使用全局配置）
    var timeoutInterval: TimeInterval? { get }
    /// Mock数据（可选）
    var mockData: Data? { get }
}

/// 默认实现，简化调用方代码
public extension MNRequestProtocol {
    var baseURL: URL? { nil }
    var timeoutInterval: TimeInterval? { nil }
    var mockData: Data? { nil }
}

/// HTTP方法枚举（隐藏Moya细节）
public enum MNHTTPMethod {
    case get, post, put, delete, patch
    
    /// 转换为Moya的Method
    internal var moyaMethod: Moya.Method {
        switch self {
        case .get: return .get
        case .post: return .post
        case .put: return .put
        case .delete: return .delete
        case .patch: return .patch
        }
    }
}
