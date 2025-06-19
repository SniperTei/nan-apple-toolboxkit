import Foundation

public protocol SNPUncaughtExceptionHandlerDelegate: AnyObject {
    func crashMonitor(_ monitor: SNPCrashMonitor, didCatchCrash crash: SNPCrashModel)
} 