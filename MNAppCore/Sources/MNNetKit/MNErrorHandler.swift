import Foundation
import UIKit

/// 默认错误处理器
public class MNErrorHandler: MNErrorHandling  {
    
    /// 单例实例
    nonisolated(unsafe) public static let shared = MNErrorHandler()
    
    /// 自定义错误处理器（可以被外部替换）
    nonisolated(unsafe) public static var customHandler: MNErrorHandling?
    
    /// 显示错误信息
    /// - Parameter error: MNError 类型的错误
    public static func showError(_ error: MNError) {
        // 如果存在自定义处理器，则使用自定义处理器
        if let customHandler = customHandler {
            customHandler.showError(error)
        } else {
            // 否则使用默认处理器
            shared.showError(error)
        }
    }
    
    /// 实现 MNErrorHandling 协议的方法
    public func showError(_ error: MNError) {
        // 打印错误信息
        print("[MNNetKit] Error: \(error.localizedDescription)")
        
        // 在主线程上执行UI操作
        DispatchQueue.main.async {
            // 尝试获取根视图控制器
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                // 创建自定义Toast视图
                let toastView = UIView()
                toastView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
                toastView.layer.cornerRadius = 8
                toastView.clipsToBounds = true
                toastView.translatesAutoresizingMaskIntoConstraints = false
                
                // 添加错误信息标签
                let messageLabel = UILabel()
                messageLabel.text = error.localizedDescription
                messageLabel.textColor = .white
                messageLabel.font = UIFont.systemFont(ofSize: 14)
                messageLabel.numberOfLines = 0
                messageLabel.textAlignment = .center
                messageLabel.translatesAutoresizingMaskIntoConstraints = false
                
                toastView.addSubview(messageLabel)
                rootViewController.view.addSubview(toastView)
                
                // 设置约束
                NSLayoutConstraint.activate([
                    messageLabel.leadingAnchor.constraint(equalTo: toastView.leadingAnchor, constant: 16),
                    messageLabel.trailingAnchor.constraint(equalTo: toastView.trailingAnchor, constant: -16),
                    messageLabel.topAnchor.constraint(equalTo: toastView.topAnchor, constant: 12),
                    messageLabel.bottomAnchor.constraint(equalTo: toastView.bottomAnchor, constant: -12),
                    
                    toastView.centerXAnchor.constraint(equalTo: rootViewController.view.centerXAnchor),
                    toastView.bottomAnchor.constraint(equalTo: rootViewController.view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
                    toastView.widthAnchor.constraint(lessThanOrEqualTo: rootViewController.view.widthAnchor, constant: -40)
                ])
                
                // 添加淡入动画
                toastView.alpha = 0
                UIView.animate(withDuration: 0.3) {
                    toastView.alpha = 1
                }
                
                // 2秒后自动消失
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    UIView.animate(withDuration: 0.3, animations: {
                        toastView.alpha = 0
                    }) {
                        _ in
                        toastView.removeFromSuperview()
                    }
                }
            } else {
                // 如果无法获取根视图控制器，打印错误信息
                print("[MNNetKit] 无法显示错误弹窗：找不到根视图控制器")
            }
        }
    }
}
