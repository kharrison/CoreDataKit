// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

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

for target in package.targets {
    var settings = target.swiftSettings ?? []
    settings.append(.enableExperimentalFeature("StrictConcurrency"))
    target.swiftSettings = settings
}
