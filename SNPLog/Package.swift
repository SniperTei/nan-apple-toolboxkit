// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SNPLog",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SNPLog",
            targets: ["SwiftCode"]),
    ],
    targets: [
        // C语言target
        .target(
            name: "CCode",
            publicHeadersPath: "include",
            cSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),
        // Swift语言target，依赖C语言target
        .target(
            name: "SwiftCode",
            dependencies: ["CCode"]
        ),
        .testTarget(
            name: "SNPLogTests",
            dependencies: ["SwiftCode"]
        ),
    ]
)
