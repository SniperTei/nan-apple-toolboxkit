//
//  AppDelegate.swift
//  MNAppCoreApp
//
//  Created by zhengnan on 2025/9/19.
//

import UIKit
import MNLoggerKit
import MNNetKit
import MNAppCore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
//        let fileLogger: DDFileLogger = DDFileLogger() // File Logger
//        fileLogger.rollingFrequency = 60 * 60 * 24 // 24 hours
//        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
//        DDLog.add(fileLogger)
//        let consoleLogger: DDOSLogger = DDOSLogger()
//        DDLog.add(consoleLogger)
        
//        DDLogVerbose("Verbose")
//        DDLogDebug("Debug")
//        DDLogInfo("Info")
//        DDLogWarn("Warn")
//        DDLogError("Error")
        
        // 日志
        // let logManager = MNLoggerCore.shared
        // let path = logManager.getLogFileDirectory()

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

        // 网络
        let environment = MNEnvironment(
            type: .dev,
            appId: "MNAppCoreApp",
            appName: "MNAppCoreAppName",
            appVersion: version,
            buildNumber: buildNumber,
            apiBaseURL: "http://localhost:8000",
//            apiBaseURL: "http://47.92.139.154:27050",
            apiKey: nil,
            debugMode: true
        )
        // configureNetwork(with: environment)
        MNAppCore.shared.configure(with: environment)
        
        MNNetConfig.shared.loadingHandler = DefaultLoading()
        
        MNInfo("info", "=================Start MNAppCoreApp===============")
        MNDebug("debug", "hello debug")
        MNWarn("warn", "hello warn")
        
        return true
    }

    // 实现网络配置方法
    private func configureNetwork(with configuration: MNEnvironment) {
        guard let baseURL = URL(string: configuration.apiBaseURL) else {
            MNDebug("MNAppCore", "无效的API基础URL: \(configuration.apiBaseURL)")
            return
        }

        MNNetConfig.shared.baseURL = baseURL
        MNNetConfig.shared.timeoutInterval = 30.0
        MNNetConfig.shared.loadingHandler = DefaultLoading()
        
        
        MNDebug("MNAppCore", "网络系统已配置，基础URL: \(configuration.apiBaseURL)")
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

