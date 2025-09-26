import Foundation
import UIKit
import Toast

public class MNErrorHandler {
    
    /// 显示错误信息
    /// - Parameter error: MNError 类型的错误
    public static func showError(_ error: MNError) {
        // 打印错误信息
        print("[MNNetKit] Error: \(error.localizedDescription)")
        
        // 在主线程上执行UI操作
        DispatchQueue.main.async {
            // 尝试获取根视图控制器
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                // 使用 Toast 显示错误信息
                rootViewController.view.makeToast(error.localizedDescription)
            } else {
                // 如果无法获取根视图控制器，打印错误信息
                print("[MNNetKit] 无法显示错误弹窗：找不到根视图控制器")
            }
        }
    }
}