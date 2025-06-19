import Foundation

public struct DeviceInfo {
    public let deviceId: String
    public let appVersion: String
    public let deviceModel: String
    public let osVersion: String
    
    public init(deviceId: String, appVersion: String, deviceModel: String, osVersion: String) {
        self.deviceId = deviceId
        self.appVersion = appVersion
        self.deviceModel = deviceModel
        self.osVersion = osVersion
    }
    
    public static var current: DeviceInfo {
        let processInfo = ProcessInfo.processInfo
        return DeviceInfo(
            deviceId: processInfo.hostName,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            deviceModel: processInfo.hostName,
            osVersion: processInfo.operatingSystemVersionString
        )
    }
} 