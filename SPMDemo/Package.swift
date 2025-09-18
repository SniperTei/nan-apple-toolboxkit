// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SPMDemo",
    products: [
        // 保留原有的库产品
        .library(
            name: "SPMDemo",
            targets: ["SPMDemo"]),
        // 添加新的可执行产品（给别人用的话移除这部分）
        .executable(
            name: "SPMDemoApp",
            targets: ["SPMDemoApp"]
        )
    ],
    targets: [
        // C语言库目标 - 指定自定义路径
        .target(
            name: "CalculatorCore",
            dependencies: [],
            path: "Sources/SPMDemo",
            sources: ["calculator.c"],
            publicHeadersPath: "include",
            cSettings: [
                .define("DEBUG"),
                .headerSearchPath("include"),
                .unsafeFlags(["-std=c11"])
            ]
        ),
        // Swift语言目标，依赖C语言库
        .target(
            name: "SPMDemo",
            dependencies: ["CalculatorCore"],
            path: "Sources/SPMDemo",
            sources: ["SPMDemo.swift"]
        ),
        // 添加新的可执行目标
        .executableTarget(
            name: "SPMDemoApp",
            dependencies: ["SPMDemo"]
        ),
        .testTarget(
            name: "SPMDemoTests",
            dependencies: ["SPMDemo"]
        ),
    ]
)
