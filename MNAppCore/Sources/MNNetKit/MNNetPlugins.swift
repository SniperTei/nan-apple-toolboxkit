import Foundation
import Alamofire
import Moya

/// 日志插件
final class MNLogPlugin: PluginType {
    func willSend(_ request: RequestType, target: TargetType) {
        guard MNNetConfig.shared.enableLogging else { return }
        
        let method = request.request?.httpMethod ?? "UNKNOWN"
        let url = request.request?.url?.absoluteString ?? "INVALID URL"
        print("🚀 [请求] \(method) \(url)")
        
        // 尝试从target获取parameters，需要类型转换
        if let internalTarget = target as? MNInternalTarget {
            if let parameters = internalTarget.parameters {
                print("   参数: \(parameters)")
            }
        }
    }
    
    func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        guard MNNetConfig.shared.enableLogging else { return }
        
        switch result {
        case .success(let response):
            let statusCode = response.statusCode
            let url = response.response?.url?.absoluteString ?? "INVALID URL"
            print("✅ [响应] \(statusCode) \(url)")
            
            if let json = try? JSONSerialization.jsonObject(with: response.data, options: []),
               let prettyJson = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
                print("   数据: \(String(data: prettyJson, encoding: .utf8) ?? "无法解析")")
            }
        case .failure(let error):
            print("❌ [错误] \(error.localizedDescription)")
        }
    }
}

/// 认证插件（添加全局Header）
final class MNAuthPlugin: PluginType {
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var mutableRequest = request
        // 添加全局Header，如Token、App版本等
        mutableRequest.addValue("ios", forHTTPHeaderField: "platform")
        mutableRequest.addValue("1.0.0", forHTTPHeaderField: "app-version")
        
        // 如果有Token，添加到Header（实际项目中应从Keychain等地方获取）
        if let token = getToken() {
            mutableRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return mutableRequest
    }
    
    private func getToken() -> String? {
        // 实际项目中应从安全存储中获取
        return UserDefaults.standard.string(forKey: "auth_token")
    }
}
