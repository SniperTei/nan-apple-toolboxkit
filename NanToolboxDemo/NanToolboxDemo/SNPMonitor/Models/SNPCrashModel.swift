import Foundation

public struct SNPCrashModel {
    public let type: CrashType
    public let name: String
    public let reason: String
    public let callStackSymbols: [String]
    public let timestamp: TimeInterval
    public let deviceInfo: DeviceInfo
    
    public init(type: CrashType, name: String, reason: String, callStackSymbols: [String], timestamp: TimeInterval, deviceInfo: DeviceInfo) {
        self.type = type
        self.name = name
        self.reason = reason
        self.callStackSymbols = callStackSymbols
        self.timestamp = timestamp
        self.deviceInfo = deviceInfo
    }
}

public enum CrashType {
    case exception(NSException)
    case signal(Int32)
    
    public var description: String {
        switch self {
        case .exception:
            return "Exception"
        case .signal(let signal):
            return "Signal(\(signal))"
        }
    }
} 