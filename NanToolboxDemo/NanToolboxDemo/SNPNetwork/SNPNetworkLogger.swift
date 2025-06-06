import Foundation
import Alamofire

// 定义日志类型
public enum SNPNetworkLogType {
    case request
    case response
    case success
    case error
}

// 定义日志结构
public struct SNPNetworkLog {
    public let type: SNPNetworkLogType
    public let message: String
    public let url: String
    public let statusCode: Int?
    public let method: String?
    public let timestamp: Date
    public let duration: TimeInterval?
    public let error: Error?
    
    init(
        type: SNPNetworkLogType,
        message: String,
        url: String,
        statusCode: Int? = nil,
        method: String? = nil,
        duration: TimeInterval? = nil,
        error: Error? = nil
    ) {
        self.type = type
        self.message = message
        self.url = url
        self.statusCode = statusCode
        self.method = method
        self.timestamp = Date()
        self.duration = duration
        self.error = error
    }
}

// 让日志结构体可以打印
extension SNPNetworkLog: CustomStringConvertible {
    public var description: String {
        """
        [\(type)] \(timestamp)
        \(message)
        """
    }
}

class SNPNetworkLogger: EventMonitor {
    
    let queue = DispatchQueue(label: "com.snp.networklogger")
    
    // 日志处理回调
    var logHandler: ((SNPNetworkLog) -> Void)?
    
    init(logHandler: ((SNPNetworkLog) -> Void)? = nil) {
        self.logHandler = logHandler
        print("SNPNetworkLogger initialized with handler: \(logHandler != nil)")
    }
    
    // 安全地调用回调
    private func safeCallHandler(_ log: SNPNetworkLog) {
        print("Preparing to call handler for log type: \(log.type)")
        
        // 确保在主队列调用回调
        DispatchQueue.main.async { [weak self] in
            print("Calling handler for log: \(log)")
            self?.logHandler?(log)
        }
    }
    
    // 请求开始时调用
    func requestDidResume(_ request: Request) {
        let urlString = request.request?.url?.absoluteString ?? "nil"
        let method = request.request?.method?.rawValue ?? "nil"
        let headers = request.request?.headers.dictionary ?? [:]
        
        var message = """
        ======== Request Started ========
        URL: \(urlString)
        Method: \(method)
        Headers: \(headers)
        """
        
        if let body = request.request?.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            message += "\nBody: \(bodyString)"
        }
        
        if let params = (request as? DataRequest)?.convertible as? Parameters {
            message += "\nParameters: \(params)"
        }
        
        // 创建日志对象并回调
        let log = SNPNetworkLog(
            type: .request,
            message: message,
            url: urlString,
            method: method
        )
        safeCallHandler(log)
    }
    
    // 收到响应时调用
    func request<Value>(_ request: DataRequest, didParseResponse response: DataResponse<Value, AFError>) {
        let urlString = request.request?.url?.absoluteString ?? "nil"
        let statusCode = response.response?.statusCode ?? 0
        let method = request.request?.method?.rawValue
        
        var message = """
        ======== Response Received ========
        URL: \(urlString)
        Status Code: \(statusCode)
        """
        
        switch response.result {
        case .success(let value):
            // 安全地处理响应数据
            if let jsonObject = value as? [String: Any] {
                // 如果是字典类型，尝试格式化
                if let data = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
                   let prettyString = String(data: data, encoding: .utf8) {
                    message += "\nResponse: \(prettyString)"
                } else {
                    message += "\nResponse: \(jsonObject)"
                }
            } else if let jsonArray = value as? [[String: Any]] {
                // 如果是数组类型，尝试格式化
                if let data = try? JSONSerialization.data(withJSONObject: jsonArray, options: .prettyPrinted),
                   let prettyString = String(data: data, encoding: .utf8) {
                    message += "\nResponse: \(prettyString)"
                } else {
                    message += "\nResponse: \(jsonArray)"
                }
            } else {
                // 其他类型直接转字符串
                message += "\nResponse: \(String(describing: value))"
            }
            
            // 创建成功日志对象并回调
            let log = SNPNetworkLog(
                type: .success,
                message: message,
                url: urlString,
                statusCode: statusCode,
                method: method,
                duration: request.metrics?.taskInterval.duration
            )
            safeCallHandler(log)
            
        case .failure(let error):
            message += "\nError: \(error.localizedDescription)"
            if let responseData = response.data,
               let responseString = String(data: responseData, encoding: .utf8) {
                message += "\nResponse Data: \(responseString)"
            }
            
            // 创建错误日志对象并回调
            let log = SNPNetworkLog(
                type: .error,
                message: message,
                url: urlString,
                statusCode: statusCode,
                method: method,
                duration: request.metrics?.taskInterval.duration,
                error: error
            )
            safeCallHandler(log)
        }
    }
    
    // 请求完成时调用
    func requestDidFinish(_ request: Request) {
        let urlString = request.request?.url?.absoluteString ?? "nil"
        let method = request.request?.method?.rawValue
        let time = request.metrics?.taskInterval.duration ?? 0
        
        let message = """
        ======== Request Finished ========
        URL: \(urlString)
        Time: \(String(format: "%.2f", time))s
        """
        
        // 创建完成日志对象并回调
        let log = SNPNetworkLog(
            type: .response,
            message: message,
            url: urlString,
            method: method,
            duration: time
        )
        safeCallHandler(log)
    }
    
    // 请求失败时调用
    func request(_ request: Request, didFailTask task: URLSessionTask, earlyWithError error: AFError) {
        let urlString = request.request?.url?.absoluteString ?? "nil"
        let method = request.request?.method?.rawValue
        
        let message = """
        ======== Request Failed ========
        URL: \(urlString)
        Error: \(error.localizedDescription)
        """
        
        // 创建失败日志对象并回调
        let log = SNPNetworkLog(
            type: .error,
            message: message,
            url: urlString,
            method: method,
            error: error
        )
        safeCallHandler(log)
    }
} 
