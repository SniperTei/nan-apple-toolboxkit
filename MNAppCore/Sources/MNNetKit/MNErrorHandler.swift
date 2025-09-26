import Foundation

/// 错误处理辅助类
public class MNErrorHandler {
    /// 显示错误信息弹窗
    /// - Parameter error: 错误对象
    public static func showError(_ error: MNError) {
        // 打印错误信息用于调试
        print("[MNNetKit] 显示错误弹窗: \(error.localizedDescription)")
        
        // 在主线程上执行UI操作
        // DispatchQueue.main.async {
        //     // 尝试获取根视图控制器
        //     if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
        //        let rootViewController = windowScene.windows.first?.rootViewController {
        //         // 创建弹窗控制器
        //         let alertController = UIAlertController(
        //             title: "提示",
        //             message: error.localizedDescription,
        //             preferredStyle: .alert
        //         )
                
        //         // 添加确认按钮
        //         let confirmAction = UIAlertAction(title: "确定", style: .default, handler: nil)
        //         alertController.addAction(confirmAction)
                
        //         // 显示弹窗
        //         rootViewController.present(alertController, animated: true, completion: nil)
        //     } else {
        //         // 如果无法获取根视图控制器，打印错误信息
        //         print("[MNNetKit] 无法显示错误弹窗：找不到根视图控制器")
        //     }
        // }
    }
}