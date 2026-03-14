// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ProjectNexus",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "ProjectNexus",
            targets: ["ProjectNexus"]
        ),
    ],
    targets: [
        .target(
            name: "ProjectNexus",
            path: "ProjectNexus",
            exclude: ["App/Info.plist"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "ProjectNexusTests",
            dependencies: ["ProjectNexus"],
            path: "ProjectNexusTests"
        ),
    ]
)
