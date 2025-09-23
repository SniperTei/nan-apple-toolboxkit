import Foundation
import Moya

/// 内部使用的Target，将MNRequestProtocol转换为Moya可识别的TargetType
struct MNInternalTarget: TargetType {
    let request: MNRequestProtocol
    
    var baseURL: URL {
        return request.baseURL ?? MNNetConfig.shared.baseURL
    }
    
    var path: String {
        return request.path
    }
    
    var method: Moya.Method {
        return request.method.moyaMethod
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        guard let parameters = request.parameters else {
            return .requestPlain
        }
        return .requestParameters(parameters: parameters, encoding: parameterEncoding)
    }
    
    var parameters: [String: Any]? {
        return request.parameters
    }
    
    var parameterEncoding: ParameterEncoding {
        switch request.method {
        case .get:
            return URLEncoding.default
        default:
            return JSONEncoding.default
        }
    }
    
    var headers: [String: String]? {
        return ["Content-Type": "application/json"]
    }
}
