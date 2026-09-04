// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Prism",
    platforms: [
        .iOS(.v16),
        .macOS(.v14),
        .tvOS(.v17)
    ],
    products: [
        .library(name: "Prism", targets: ["Prism"]),
        .library(name: "PrismUI", targets: ["PrismUI"]),
        .library(name: "PrismCore", targets: ["PrismCore"]),
        .library(name: "PrismData", targets: ["PrismData"]),
        .library(name: "PrismStorage", targets: ["PrismStorage"]),
        .library(name: "PrismLogging", targets: ["PrismLogging"]),
    ],
    dependencies: [
        .package(url: "https://github.com/resoul/flux.git", from: "1.1.0"),
    ],
    targets: [
        // MARK: - PrismLogging
        .target(
            name: "PrismLogging",
            dependencies: [],
            path: "Sources/PrismLogging"
        ),
        .testTarget(
            name: "PrismLoggingTests",
            dependencies: ["PrismLogging"],
            path: "Tests/PrismLoggingTests"
        ),

        // MARK: - PrismCore
        .target(
            name: "PrismCore",
            dependencies: [
                .product(name: "Flux", package: "flux"),
                "PrismLogging",
            ],
            path: "Sources/PrismCore"
        ),
        .testTarget(
            name: "PrismCoreTests",
            dependencies: ["PrismCore"],
            path: "Tests/PrismCoreTests",
            resources: [
                .copy("Fixtures")
            ]
        ),

        // MARK: - PrismUI
        .target(
            name: "PrismUI",
            dependencies: [
                "PrismCore",
                "PrismLogging",
            ],
            path: "Sources/PrismUI"
        ),
        .testTarget(
            name: "PrismUITests",
            dependencies: ["PrismUI"],
            path: "Tests/PrismUITests"
        ),

        // MARK: - PrismStorage
        .target(
            name: "PrismStorage",
            dependencies: [
                .product(name: "Flux", package: "flux"),
                "PrismLogging",
            ],
            path: "Sources/PrismStorage"
        ),
        .testTarget(
            name: "PrismStorageTests",
            dependencies: ["PrismStorage"],
            path: "Tests/PrismStorageTests"
        ),

        // MARK: - PrismData
        .target(
            name: "PrismData",
            dependencies: [
                "PrismStorage",
                .product(name: "Flux", package: "flux"),
                "PrismLogging",
            ],
            path: "Sources/PrismData"
        ),
        .testTarget(
            name: "PrismDataTests",
            dependencies: ["PrismData"],
            path: "Tests/PrismDataTests"
        ),

        // MARK: - Umbrella Prism
        .target(
            name: "Prism",
            dependencies: [
                "PrismCore",
                "PrismUI",
                "PrismData",
                "PrismStorage",
                "PrismLogging",
                .product(name: "Flux", package: "flux"),
            ],
            path: "Sources/Prism"
        ),
        .testTarget(
            name: "PrismTests",
            dependencies: ["Prism"],
            path: "Tests/PrismTests"
        ),
    ]
)
