

/// 错误处理协议
public protocol MNErrorHandleProtocol {
    /// 显示错误信息
    /// - Parameter error: MNError 类型的错误
    func showError(_ error: MNError)
}

public struct MNDefaultErrorHandler: MNErrorHandleProtocol {
    /// 初始化
    public init() {}

    public func showError(_ error: MNError) {
        print("error handle msg : \(error)")
    }
}