// 确保同时导入 MNLoggerKit 和 MNNetKit
import Foundation
import MNLoggerKit
import MNNetKit

// 修改为 public 类
public class MNAppCore: @unchecked Sendable {
    // 公开访问共享实例
    public static let shared = MNAppCore()
    // 私有初始化器，确保单例模式
    private init() {
        MNDebug("MNAppCore", "初始化")
    }
    
    // 公开测试方法
    public func test() {
        MNDebug("MNAppCore", "测试")
    }
    
    // 公开配置方法，这是主要的配置入口
    public func configure(with configuration: MNEnvironment) {
        // 配置日志系统
        configureLogger(with: configuration)
        
        // 配置网络系统
        configureNetwork(with: configuration)
        
        MNDebug("MNAppCore", "已使用环境配置初始化完成")
    }
    
    // 保持为私有，内部使用
    private func configureLogger(with configuration: MNEnvironment) {
        // 配置日志系统
        _ = MNLoggerCore.shared
        // 打印日志路径
        MNDebug("MNAppCore", "日志路径: \(MNLoggerCore.shared.getLogFileDirectory())")
        MNDebug("MNAppCore", "日志系统已配置")
    }
    
    // 保持为私有，内部使用
    private func configureNetwork(with configuration: MNEnvironment) {
        guard let baseURL = URL(string: configuration.apiBaseURL) else {
            MNDebug("MNAppCore", "无效的API基础URL: \(configuration.apiBaseURL)")
            return
        }
        
        let config = MNNetConfig.shared
        config.baseURL = baseURL
        config.timeoutInterval = configuration.timeoutInterval
        config.enableLogging = configuration.debugMode

        // 简化版本检查，只针对iOS平台
        if #available(iOS 13.0, *) {
            let netClient = MNNetClient.shared
            // 配置网络核心模块
            netClient.configure(baseURL: baseURL, timeoutInterval: configuration.timeoutInterval)
            
            // 根据环境设置Mock模式
            // if configuration.debugMode {
            //     netClient.setMockMode(.disabled) // 开发环境可以根据需要设置为.global或.
            // }
            
            MNDebug("MNAppCore", "网络系统已配置，基础URL: \(configuration.apiBaseURL)")
        } else {
            MNDebug("MNAppCore", "当前操作系统版本不支持MNNetClient，需要iOS 13.0+")
        }
    }
}
