import Foundation
import UIKit

/// 错误处理协议
public protocol MNErrorHandling {
    /// 显示错误信息
    /// - Parameter error: MNError 类型的错误
    func showError(_ error: MNError)
}