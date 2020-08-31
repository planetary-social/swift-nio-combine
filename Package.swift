// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "swift-nio-combine",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "NIOCombine",
            targets: ["NIOCombine"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio",
                 .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/apple/swift-nio-transport-services",
                 .upToNextMajor(from: "1.1.1"))
    ],
    targets: [
        .target(
            name: "NIOCombine",
            dependencies: [
                .product(name: "NIO",
                         package: "swift-nio"),
                .product(name: "NIOTransportServices",
                         package: "swift-nio-transport-services")
            ]),
        .testTarget(
            name: "NIOCombineTests",
            dependencies: ["NIOCombine"])
    ]
)
