// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MNLogger",
    products: [
        .library(
            name: "MNLogger",
            targets: ["MNLogger"]
        ),
    ],
    targets: [
        .target(
            name: "MNLoggerCore",
            path: "Sources/MNLoggerCore",
            sources: ["mn_logger_core.c"],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include"),
                .unsafeFlags(["-std=c11"])
            ]
        ),
        .target(
            name: "MNLogger",
            dependencies: ["MNLoggerCore"],
            path: "Sources/MNLogger",
            sources: ["MNLogger.swift"]
        ),
        .testTarget(
            name: "MNLoggerTests",
            dependencies: ["MNLogger"]
        ),
    ]
)