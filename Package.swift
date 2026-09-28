// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LumaShell",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "LumaShell", targets: ["LumaShell"])],
    targets: [
        .target(name: "LumaShellCore", path: "Sources/LumaShellCore"),
        .executableTarget(name: "LumaShell", dependencies: ["LumaShellCore"], path: "Sources/LumaShell"),
        .testTarget(name: "LumaShellCoreTests", dependencies: ["LumaShellCore"], path: "Tests/LumaShellCoreTests")
    ]
)
