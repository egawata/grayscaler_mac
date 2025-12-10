// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Grayscaler",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Grayscaler", targets: ["Grayscaler"])
    ],
    targets: [
        .executableTarget(
            name: "Grayscaler",
            path: "Grayscaler",
            exclude: ["Info.plist", "Grayscaler.entitlements"]
        )
    ]
)
