// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DependencyRunner",
    platforms: [
        .macOS(.v10_12),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .library(name: "DependencyRunner", targets: ["DependencyRunner"]),
        .executable(name: "DependencyRunnerMain", targets: ["DependencyRunnerMain"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/JohnSundell/ShellOut.git", from: "2.0.0"),
        .package(url: "https://github.com/JohnSundell/Files", from: "4.0.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "1.3.8")),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.4.0"),
        .package(url: "https://github.com/mtynior/ColorizeSwift.git", from: "1.6.0"),

    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "DependencyRunner",
            dependencies: [
                "Files",
                "ShellOut",
                "CryptoSwift",
                "ColorizeSwift"
            ]),
        .target(
            name: "DependencyRunnerMain",
            dependencies: [
                "DependencyRunner",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]),
        .testTarget(
            name: "DependencyRunnerTests",
            dependencies: ["DependencyRunner"]),
    ]
)
