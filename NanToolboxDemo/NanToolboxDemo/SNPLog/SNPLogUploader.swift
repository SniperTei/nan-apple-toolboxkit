import Foundation
import Alamofire

// MARK: - 日志上传配置协议
public protocol SNPLogUploadConfig {
    /// 上传服务器的URL
    var uploadURL: String { get }
    
    /// 请求头
    var headers: [String: String] { get }
    
    /// 文件参数名
    var fileParameterName: String { get }
    
    /// 自定义元数据
    var customMetadata: [String: Any] { get }
    
    /// 认证Token
    var authToken: String? { get }
    
    /// 压缩文件名格式化
    func formatZipFileName(deviceId: String, timestamp: String) -> String
}

// MARK: - 默认配置实现
public struct SNPDefaultLogUploadConfig: SNPLogUploadConfig {
    public init() {}
    
    private var _authToken: String?
    
    public var uploadURL: String {
        return SNPNetworkConfig.shared.baseURL + "/v1/upload/single/archive"
    }
    
    public var headers: [String: String] {
        var headers = SNPNetworkConfig.shared.commonHeaders
        if let token = authToken {
            headers["Authorization"] = "Bearer \(token)"
        }
        return headers
    }
    
    public var fileParameterName: String {
        return "file"
    }
    
    public var customMetadata: [String: Any] {
        return [:]
    }
    
    public var authToken: String? {
        return _authToken
    }
    
    public func formatZipFileName(deviceId: String, timestamp: String) -> String {
        return "SNPLog-\(deviceId)-\(timestamp).zip"
    }
    
    // 添加设置token的方法
    public mutating func setAuthToken(_ token: String?) {
        _authToken = token
    }
}

// MARK: - 日志上传处理协议
public protocol SNPLogUploadHandler {
    /// 处理上传结果
    func handleUploadResponse(_ response: Result<Data, Error>, completion: @escaping (Result<[String], Error>) -> Void)
}

// MARK: - 默认上传处理实现
public struct SNPDefaultLogUploadHandler: SNPLogUploadHandler {
    public init() {}
    
    public func handleUploadResponse(_ response: Result<Data, Error>, completion: @escaping (Result<[String], Error>) -> Void) {
        switch response {
        case .success(let data):
            guard let uploadResponse = try? JSONDecoder().decode(SNPLogUploader.UploadResponse.self, from: data)
            else {
                completion(.failure(SNPLogUploader.UploadError.invalidResponse))
                return
            }
            
            if uploadResponse.isSuccess() {
                let urls = uploadResponse.data?.map { $0.url } ?? []
                completion(.success(urls))
            } else {
                completion(.failure(SNPLogUploader.UploadError.serverError(message: uploadResponse.msg)))
            }
            
        case .failure(let error):
            completion(.failure(error))
        }
    }
}

// MARK: - 日志上传器
public class SNPLogUploader {
    public static let shared = SNPLogUploader()
    
    /// 上传配置
    public var config: SNPLogUploadConfig
    
    /// 上传处理器
    public var handler: SNPLogUploadHandler
    
    public init(config: SNPLogUploadConfig = SNPDefaultLogUploadConfig(),
                handler: SNPLogUploadHandler = SNPDefaultLogUploadHandler()) {
        self.config = config
        self.handler = handler
    }
    
    /// 压缩并上传日志文件
    /// - Parameters:
    ///   - logFilePath: 日志文件路径
    ///   - deviceId: 设备ID
    ///   - completion: 完成回调
    public func uploadLog(logFilePath: String, deviceId: String, completion: @escaping (Result<[String], Error>) -> Void) {
        print("开始上传日志流程...")
        print("原始日志文件路径: \(logFilePath)")
        
        // 检查源文件是否存在
        guard FileManager.default.fileExists(atPath: logFilePath) else {
            print("错误：源日志文件不存在")
            completion(.failure(UploadError.compressionFailed))
            return
        }
        
        // 1. 创建临时压缩文件路径
        let tempDir = NSTemporaryDirectory()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let zipFileName = config.formatZipFileName(deviceId: deviceId, timestamp: timestamp)
        let zipFilePath = (tempDir as NSString).appendingPathComponent(zipFileName)
        
        print("准备创建压缩文件: \(zipFilePath)")
        
        // 2. 压缩日志文件
        do {
            let sourceURL = URL(fileURLWithPath: logFilePath)
            let destinationURL = URL(fileURLWithPath: zipFilePath)
            
            // 如果目标文件已存在，先删除
            if FileManager.default.fileExists(atPath: zipFilePath) {
                try FileManager.default.removeItem(atPath: zipFilePath)
                print("删除已存在的压缩文件")
            }
            
            // 读取源文件内容
            let fileData = try Data(contentsOf: sourceURL)
            print("成功读取源文件，大小: \(fileData.count) bytes")
            
            // 创建压缩文件
            let archive = try NSKeyedArchiver.archivedData(withRootObject: [logFilePath], requiringSecureCoding: true)
            try archive.write(to: destinationURL)
            
            // 验证压缩文件
            if FileManager.default.fileExists(atPath: zipFilePath) {
                let zipFileAttributes = try FileManager.default.attributesOfItem(atPath: zipFilePath)
                let zipFileSize = zipFileAttributes[.size] as? UInt64 ?? 0
                print("压缩文件创建成功:")
                print("- 路径: \(zipFilePath)")
                print("- 大小: \(zipFileSize) bytes")
            } else {
                print("错误：压缩文件创建失败，文件不存在")
                throw UploadError.compressionFailed
            }
            
            print("\n准备上传请求:")
            print("- URL: \(config.uploadURL)")
            print("- 文件参数名: \(config.fileParameterName)")
            print("- Headers: \(config.headers)")
            
            // 3. 创建上传请求
            AF.upload(multipartFormData: { [weak self] multipartFormData in
                guard let self = self else { return }
                
                // 添加压缩文件
                multipartFormData.append(destinationURL,
                                      withName: "\(self.config.fileParameterName)[]",
                                      fileName: zipFileName,
                                      mimeType: "application/zip")
                
                // 添加其他参数
                multipartFormData.append("log".data(using: .utf8)!,
                                      withName: "fileType")
                multipartFormData.append(deviceId.data(using: .utf8)!,
                                      withName: "deviceId")
                
                // 合并元数据
                var metadata: [String: Any] = [
                    "deviceId": deviceId,
                    "timestamp": timestamp,
                    "platform": "iOS",
                    "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
                ]
                // 添加自定义元数据
                metadata.merge(self.config.customMetadata) { (_, new) in new }
                
                if let metadataData = try? JSONSerialization.data(withJSONObject: metadata) {
                    multipartFormData.append(metadataData,
                                          withName: "metadata")
                }
                
                print("\n请求表单数据:")
                print("- 文件名: \(zipFileName)")
                print("- 设备ID: \(deviceId)")
                print("- 元数据: \(metadata)")
                
            }, to: config.uploadURL, headers: HTTPHeaders(config.headers))
            .responseData { [weak self] response in
                // 删除临时压缩文件
                try? FileManager.default.removeItem(atPath: zipFilePath)
                print("\n收到服务器响应:")
                print("- 状态码: \(response.response?.statusCode ?? 0)")
                if let data = response.data,
                   let responseString = String(data: data, encoding: .utf8) {
                    print("- 响应内容: \(responseString)")
                }
                
                // 使用处理器处理响应
                self?.handler.handleUploadResponse(
                    response.result.mapError { $0 as Error },
                    completion: completion
                )
            }
        } catch {
            print("压缩文件失败: \(error)")
            completion(.failure(error))
        }
    }
}

// MARK: - 辅助类型
extension SNPLogUploader {
    public enum UploadError: LocalizedError {
        case compressionFailed
        case serverError(message: String)
        case invalidResponse
        
        public var errorDescription: String? {
            switch self {
            case .compressionFailed:
                return "日志压缩失败"
            case .serverError(let message):
                return message
            case .invalidResponse:
                return "无效的服务器响应"
            }
        }
    }
    
    struct UploadResponse: SNPAPIResponsable {
        struct FileInfo: Codable {
            let url: String
            let fileName: String
            let originalName: String
            let size: Int
            let mimeType: String
            let type: String
        }
        
        var code: String
        var statusCode: Int
        var msg: String
        var data: [FileInfo]?
        var timestamp: String
        
        typealias DataType = [FileInfo]
    }
}

// MARK: - 使用示例

/*
 // 1. 默认用法
 SNPLogUploader.shared.uploadLog(
     logFilePath: "/path/to/log/file.log",
     deviceId: "device123"
 ) { result in
     // 处理结果
 }
 
 // 2. 自定义配置
 struct CustomConfig: SNPLogUploadConfig {
     var uploadURL: String {
         return "https://your-server.com/upload"
     }
     
     var headers: [String: String] {
         return [
             "Authorization": "Bearer your-token",
             "Custom-Header": "Value"
         ]
     }
     
     var fileParameterName: String {
         return "file"
     }
     
     var customMetadata: [String: Any] {
         return [
             "appName": "YourApp",
             "environment": "production"
         ]
     }
     
     func formatZipFileName(deviceId: String, timestamp: String) -> String {
         return "CustomLog_\(deviceId)_\(timestamp).zip"
     }
 }
 
 // 3. 自定义处理器
 struct CustomHandler: SNPLogUploadHandler {
     func handleUploadResponse(_ response: Result<Data?, Error>,
                             completion: @escaping (Result<[String], Error>) -> Void) {
         // 自定义响应处理逻辑
         switch response {
         case .success(let data):
             // 解析你的服务器响应格式
             if let data = data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let urls = json["files"] as? [String] {
                 completion(.success(urls))
             } else {
                 completion(.failure(SNPLogUploader.UploadError.invalidResponse))
             }
         case .failure(let error):
             completion(.failure(error))
         }
     }
 }
 
 // 4. 使用自定义配置和处理器
 let uploader = SNPLogUploader(
     config: CustomConfig(),
     handler: CustomHandler()
 )
 
 uploader.uploadLog(
     logFilePath: "/path/to/log/file.log",
     deviceId: "device123"
 ) { result in
     // 处理结果
 }
 */ 
