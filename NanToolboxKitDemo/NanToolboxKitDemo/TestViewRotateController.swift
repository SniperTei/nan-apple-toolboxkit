//
//  TestViewRotateController.swift
//  NanToolboxKitDemo
//
//  Created by zhengnan on 2025/5/12.
//

import Foundation
import UIKit

class TestViewRotateController: UIViewController {
    
    private let rotateView: UIView = {
        let view = UIView()
        view.backgroundColor = .red
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 强制横屏
        // if #available(iOS 16.0, *) {
        //     setNeedsUpdateOfSupportedInterfaceOrientations()
        //     guard let windowScene = view.window?.windowScene else { return }
        //     let orientation = UIInterfaceOrientation.landscapeRight
        //     let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscapeRight)
        //     windowScene.requestGeometryUpdate(geometryPreferences) { error in
        //         print("Error: \(String(describing: error))")
        //     }
        // } else {
        //     let value = UIInterfaceOrientation.landscapeRight.rawValue
        //     UIDevice.current.setValue(value, forKey: "orientation")
        // }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 恢复竖屏
        // if #available(iOS 16.0, *) {
        //     setNeedsUpdateOfSupportedInterfaceOrientations()
        //     guard let windowScene = view.window?.windowScene else { return }
        //     let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
        //     windowScene.requestGeometryUpdate(geometryPreferences) { error in
        //         print("Error: \(String(describing: error))")
        //     }
        // } else {
        //     let value = UIInterfaceOrientation.portrait.rawValue
        //     UIDevice.current.setValue(value, forKey: "orientation")
        // }
    }
    
    // override func viewDidLayoutSubviews() {
    //     super.viewDidLayoutSubviews()
    //     // 在这里设置frame，确保获取到正确的view尺寸
    //     let viewWidth = view.bounds.width
    //     let viewHeight = view.bounds.height
    //     rotateView.frame = CGRect(
    //         x: (viewWidth - 200) / 2,  // 居中
    //         y: (viewHeight - 100) / 2,
    //         width: 200,
    //         height: 100
    //     )
    // }
    
    private func setupUI() {
        title = "旋转测试"
        view.backgroundColor = .white
        rotateView.frame = CGRect(x: 50, y: 100, width: 200, height: 100)
        view.addSubview(rotateView)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        print("viewWillTransition: \(size)")
    }
}
