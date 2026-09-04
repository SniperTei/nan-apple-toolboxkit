//
//  DefaultLoading.swift
//  MNAppCoreApp
//
//  Created by zhengnan on 2025/10/14.
//

import Foundation
import MNNetKit
import UIKit

struct DefaultLoading: MNLoadingProtocol {

    private let loadingView = UIActivityIndicatorView(style: .medium)

    func startLoading<R>(for request: R, title: String?) where R : MNRequestProtocol {
        loadingView.startAnimating()
        let view = UIApplication.shared.keyWindow ?? UIView()
        loadingView.center = view.center
        view.addSubview(loadingView)
        // 打印loadingView的位置
        print("loadingView的位置: \(loadingView.center)")
    }
    
    func stopLoading<R>(for request: R) where R : MNRequestProtocol {
//        loadingView.stopAnimating()
//        loadingView.removeFromSuperview()
        // 打印loadingView的位置
        print("loadingView的位置: \(loadingView.center)")
    }
}
