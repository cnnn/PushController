// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WaveformView",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "WaveformView",
            targets: ["WaveformView"]),
    ],
    dependencies: [
        // No external dependencies needed for basic waveform rendering
    ],
    targets: [
        .target(
            name: "WaveformView",
            dependencies: []),
        .testTarget(
            name: "WaveformViewTests",
            dependencies: ["WaveformView"]),
    ]
)