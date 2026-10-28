// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GEORadarPro",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "GEORadarPro", targets: ["GEORadarPro"])
    ],
    targets: [
        .executableTarget(
            name: "GEORadarPro",
            path: "Sources/GEORadarPro"
        )
    ]
)
