// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CoreDataKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v14), .macOS(.v11), .macCatalyst(.v14), .tvOS(.v14), .watchOS(.v7)
    ],
    products: [
        .library(
            name: "CoreDataKit",
            targets: ["CoreDataKit"]),
    ],
    targets: [
        .target(
            name: "CoreDataKit",
            dependencies: []),
        .testTarget(
            name: "CoreDataKitTests",
            dependencies: ["CoreDataKit"]),
    ]
)
