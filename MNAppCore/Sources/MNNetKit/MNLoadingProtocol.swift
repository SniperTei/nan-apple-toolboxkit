import Foundation

/// 定义网络请求加载状态管理的协议
public protocol MNLoadingProtocol: AnyObject {
    /// 开始加载状态
    /// - Parameters:
    ///   - request: 当前的网络请求
    ///   - title: 加载提示标题
    func startLoading<R: MNRequestProtocol>(for request: R, title: String?)
    
    /// 结束加载状态
    /// - Parameter request: 当前的网络请求
    func stopLoading<R: MNRequestProtocol>(for request: R)
}