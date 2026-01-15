// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Signaling",
    platforms: [.macOS(.v11), .iOS(.v13)],
    products: [
        .library(name: "CombineSignaling", targets: ["CombineSignaling"]),
        .library(name: "RxSignaing", targets: ["RxSignaing"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "6.0.0")),
        .package(url: "https://github.com/pointfreeco/combine-schedulers", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(name: "CombineSignaling", dependencies: []),
        .target(
            name: "RxSignaing",
            dependencies: ["RxSwift", .product(name: "RxCocoa", package: "RxSwift")]
        ),
        .testTarget(
            name: "RxSignaingTests",
            dependencies: ["RxSignaing", "RxSwift"]
        ),
        .testTarget(
            name: "CombineSignalingTests",
            dependencies: ["CombineSignaling", .product(name: "CombineSchedulers", package: "combine-schedulers")]
        ),
    ]
)
