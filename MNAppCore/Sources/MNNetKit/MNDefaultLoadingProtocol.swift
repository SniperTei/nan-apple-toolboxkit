import Foundation

// 条件导入 UIKit，仅在支持的平台上导入
#if canImport(UIKit)
import UIKit
#endif

/// 默认的加载状态实现
public class MNDefaultLoadingProtocol: MNLoadingProtocol {
    
#if canImport(UIKit)
    private var loadingIndicators = NSHashTable<UIActivityIndicatorView>(options: .weakMemory)
    private let mainQueue = DispatchQueue.main
#else
    // 非 UIKit 平台的空实现
    private let mainQueue = DispatchQueue.main
#endif
    
    public init() {}
    
    public func startLoading<R: MNRequestProtocol>(for request: R, title: String?) {
#if canImport(UIKit)
        mainQueue.async {
            // 检查是否已有相同请求的加载指示器
            if let existingIndicator = self.findIndicator(for: request) {
                existingIndicator.startAnimating()
                return
            }
            
            // 创建新的加载指示器
            let indicator = UIActivityIndicatorView(style: .large)
            indicator.color = .gray
            
            // 查找最顶层的窗口来显示加载指示器
            if let window = UIApplication.shared.windows.last {
                window.addSubview(indicator)
                indicator.center = window.center
                indicator.startAnimating()
                
                // 存储指示器以便后续隐藏
                self.loadingIndicators.add(indicator)
            }
        }
#else
        // 非 UIKit 平台不做任何操作
        print("Loading started for request: \(request.path)")
#endif
    }
    
    public func stopLoading<R: MNRequestProtocol>(for request: R) {
#if canImport(UIKit)
        mainQueue.async {
            if let indicator = self.findIndicator(for: request) {
                indicator.stopAnimating()
                indicator.removeFromSuperview()
                self.loadingIndicators.remove(indicator)
            }
        }
#else
        // 非 UIKit 平台不做任何操作
        print("Loading stopped for request: \(request.path)")
#endif
    }
    
#if canImport(UIKit)
    // 查找与请求关联的加载指示器
    private func findIndicator<R: MNRequestProtocol>(for request: R) -> UIActivityIndicatorView? {
        // 简单实现：返回第一个活跃的指示器
        // 实际项目中可以实现更精确的匹配逻辑
        for indicator in loadingIndicators.allObjects {
            if indicator.isAnimating {
                return indicator
            }
        }
        return nil
    }
#endif
}