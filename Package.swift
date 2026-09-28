// swift-tools-version: 5.9
import PackageDescription

var products: [Product] = []
var targets: [Target] = [
    .target(
        name: "LumaShellCore",
        path: "Sources/LumaShellCore"
    ),
    .testTarget(
        name: "LumaShellCoreTests",
        dependencies: ["LumaShellCore"],
        path: "Tests/LumaShellCoreTests"
    )
]

#if os(macOS)
products.append(
    .executable(name: "LumaShell", targets: ["LumaShell"])
)
targets.insert(
    .executableTarget(
        name: "LumaShell",
        dependencies: ["LumaShellCore"],
        path: "Sources/LumaShell"
    ),
    at: 1
)
#endif

let package = Package(
    name: "LumaShell",
    platforms: [.macOS(.v13)],
    products: products,
    targets: targets
)
