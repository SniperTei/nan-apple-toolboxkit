import Foundation

/// 定义网络请求加载状态管理的协议
public protocol MNLoadingProtocol {
    /// 开始加载状态
    /// - Parameters:
    ///   - request: 当前的网络请求
    ///   - title: 加载提示标题
    func startLoading<R: MNRequestProtocol>(for request: R, title: String?)
    
    /// 结束加载状态
    /// - Parameter request: 当前的网络请求
    func stopLoading<R: MNRequestProtocol>(for request: R)
}

public struct MNDefaultLoadingHandler: MNLoadingProtocol {
    public func startLoading<R: MNRequestProtocol>(for request: R, title: String?) {
        print("start loading \(request) \(title ?? "Loading...")")
    }
    
    public func stopLoading<R: MNRequestProtocol>(for request: R) {
        print("stop loading \(request)")
    }
}