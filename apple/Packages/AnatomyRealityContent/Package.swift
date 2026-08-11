// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AnatomyRealityContent",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .tvOS(.v26),
        .visionOS(.v2),
    ],
    products: [
        .library(name: "AnatomyRealityContent", targets: ["AnatomyRealityContent"]),
    ],
    targets: [
        .target(name: "AnatomyRealityContent"),
    ]
)
