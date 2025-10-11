// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MNAppCore",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MNAppCore",
            targets: ["MNAppCore"]),
    ],
    dependencies: [
        // 添加 CocoaLumberjack 依赖（用于日志记录）
        .package(url: "https://github.com/CocoaLumberjack/CocoaLumberjack.git", from: "3.8.0"),
        // 添加 Alamofire 依赖（用于网络请求）
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.9.0"),
        // 添加 Moya 依赖（网络请求抽象层，基于 Alamofire）
        .package(url: "https://github.com/Moya/Moya.git", from: "15.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "MNAppCore",
            dependencies: [
                "MNLoggerKit",
                "MNNetKit"
            ]
        ),
        .target(
            name: "MNLoggerKit",
            dependencies: [
                // 日志模块依赖 CocoaLumberjack
                .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack")
            ],
            path: "Sources/MNLoggerKit",
        ),
        .target(
            name: "MNNetKit",
            dependencies: [
                // 网络模块依赖 Alamofire 和 Moya
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "Moya", package: "Moya"),
            ],
            path: "Sources/MNNetKit",
        ),
        .testTarget(
            name: "MNAppCoreTests",
            dependencies: ["MNAppCore"]
        ),
    ]
)
