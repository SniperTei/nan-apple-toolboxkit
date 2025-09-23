import Foundation

/// 应用环境枚举
public enum MNEnvironmentType: String {
    case dev = "Development"
    case test = "Testing"
    case prod = "Production"
}

/// 应用环境配置结构体
public struct MNEnvironment {
    // 环境类型
    public let type: MNEnvironmentType
    
    // 应用基本信息
    public let appId: String
    public let appName: String
    public let appVersion: String
    public let buildNumber: String
    
    // API 配置
    public let apiBaseURL: String
    public let apiKey: String?
    
    // 日志配置
    public let loggingEnabled: Bool
    public let debugMode: Bool
    
    // 推送配置
    public let pushEnabled: Bool
    public let pushEnvironment: String
    
    // 分析配置
    public let analyticsEnabled: Bool
    
    // 初始化方法
    public init(
        type: MNEnvironmentType,
        appId: String,
        appName: String,
        appVersion: String,
        buildNumber: String,
        apiBaseURL: String,
        apiKey: String? = nil,
        loggingEnabled: Bool = true,
        debugMode: Bool = false,
        pushEnabled: Bool = true,
        pushEnvironment: String = "sandbox",
        analyticsEnabled: Bool = true
    ) {
        self.type = type
        self.appId = appId
        self.appName = appName
        self.appVersion = appVersion
        self.buildNumber = buildNumber
        self.apiBaseURL = apiBaseURL
        self.apiKey = apiKey
        self.loggingEnabled = loggingEnabled
        self.debugMode = debugMode
        self.pushEnabled = pushEnabled
        self.pushEnvironment = pushEnvironment
        self.analyticsEnabled = analyticsEnabled
    }
    
    /// 开发环境配置
    public static func development(appId: String, appName: String) -> MNEnvironment {
        MNEnvironment(
            type: .dev,
            appId: appId,
            appName: appName,
            appVersion: "1.0.0-dev",
            buildNumber: "1",
            apiBaseURL: "https://dev-api.example.com",
            loggingEnabled: true,
            debugMode: true,
            pushEnvironment: "sandbox"
        )
    }
    
    /// 测试环境配置
    public static func testing(appId: String, appName: String) -> MNEnvironment {
        MNEnvironment(
            type: .test,
            appId: appId,
            appName: appName,
            appVersion: "1.0.0-test",
            buildNumber: "100",
            apiBaseURL: "https://test-api.example.com",
            loggingEnabled: true,
            debugMode: false,
            pushEnvironment: "sandbox"
        )
    }
    
    /// 生产环境配置
    public static func production(appId: String, appName: String) -> MNEnvironment {
        MNEnvironment(
            type: .prod,
            appId: appId,
            appName: appName,
            appVersion: "1.0.0",
            buildNumber: "1000",
            apiBaseURL: "https://api.example.com",
            loggingEnabled: false,
            debugMode: false,
            pushEnvironment: "production"
        )
    }
    
    /// 从 Info.plist 加载环境配置
    public static func fromInfoPlist() -> MNEnvironment? {
        guard let infoDict = Bundle.main.infoDictionary else {
            return nil
        }
        
        guard
            let appId = infoDict["CFBundleIdentifier"] as? String,
            let appName = infoDict["CFBundleName"] as? String,
            let appVersion = infoDict["CFBundleShortVersionString"] as? String,
            let buildNumber = infoDict["CFBundleVersion"] as? String
        else {
            return nil
        }
        
        // API 基础 URL（从 Info.plist 或环境变量获取）
        let apiBaseURL = infoDict["API_BASE_URL"] as? String ?? "https://api.example.com"
        
        // API 密钥（可选）
        let apiKey = infoDict["API_KEY"] as? String
        
        // 添加 type 参数到 fromInfoPlist() 方法中的 MNEnvironment 初始化
        
        return MNEnvironment(
            type: .dev, // 或者根据需要选择默认类型
            appId: appId,
            appName: appName,
            appVersion: appVersion,
            buildNumber: buildNumber,
            apiBaseURL: apiBaseURL,
            apiKey: apiKey
        )
    }
}

/// 全局环境单例
// public let CurrentEnvironment: MNEnvironment = {
//     // 默认返回开发环境配置
//     // 实际应用中，您应该根据构建配置或环境变量来选择正确的环境
//     return MNEnvironment.development(appId: "com.example.app", appName: "ExampleApp")
// }()