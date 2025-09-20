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
        
        // 根据配置或构建标志确定环境类型
        let isProduction = ProcessInfo.processInfo.environment["PRODUCTION"] == "true"
        let isTesting = ProcessInfo.processInfo.environment["TESTING"] == "true"
        
        let type: MNEnvironmentType
        let apiBaseURL: String
        
        if isProduction {
            type = .prod
            apiBaseURL = "https://api.example.com"
        } else if isTesting {
            type = .test
            apiBaseURL = "https://test-api.example.com"
        } else {
            type = .dev
            apiBaseURL = "https://dev-api.example.com"
        }
        
        return MNEnvironment(
            type: type,
            appId: appId,
            appName: appName,
            appVersion: appVersion,
            buildNumber: buildNumber,
            apiBaseURL: apiBaseURL
        )
    }
}

/// 全局环境单例
// public let CurrentEnvironment: MNEnvironment = {
//     // 默认返回开发环境配置
//     // 实际应用中，您应该根据构建配置或环境变量来选择正确的环境
//     return MNEnvironment.development(appId: "com.example.app", appName: "ExampleApp")
// }()