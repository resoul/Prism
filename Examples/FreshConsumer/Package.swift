// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FreshPrismConsumer",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/resoul/Prism.git", revision: "5857d4b5d558bd59830112bef36607aa38ba7909"),
        .package(url: "https://github.com/resoul/flux.git", revision: "7966807e487438a62d636f9aa475239feaf468fd")
    ],
    targets: [
        .executableTarget(name: "FreshPrismConsumer", dependencies: [
            .product(name: "PrismUI", package: "Prism"),
            .product(name: "Flux", package: "flux")
        ])
    ]
)
