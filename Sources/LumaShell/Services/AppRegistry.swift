import AppKit
import Foundation

struct ShellAppItem: Identifiable, Hashable, Sendable {
    let name: String
    let url: URL
    let bundleIdentifier: String?

    var id: String {
        bundleIdentifier ?? url.path
    }
}

enum AppRegistry {
    static func scanApplications() async -> [ShellAppItem] {
        await Task.detached(priority: .utility) {
            let manager = FileManager.default
            let roots = [
                URL(fileURLWithPath: "/Applications", isDirectory: true),
                manager.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true)
            ]

            var seen = Set<String>()
            var apps: [ShellAppItem] = []

            for root in roots where manager.fileExists(atPath: root.path) {
                guard let enumerator = manager.enumerator(
                    at: root,
                    includingPropertiesForKeys: [.isDirectoryKey, .isPackageKey],
                    options: [.skipsHiddenFiles, .skipsPackageDescendants]
                ) else { continue }

                for case let url as URL in enumerator where url.pathExtension.lowercased() == "app" {
                    guard let bundle = Bundle(url: url) else { continue }
                    let name =
                        bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
                        bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ??
                        url.deletingPathExtension().lastPathComponent
                    let bundleID = bundle.bundleIdentifier
                    let key = bundleID ?? url.standardizedFileURL.path
                    guard seen.insert(key).inserted else { continue }

                    apps.append(ShellAppItem(name: name, url: url, bundleIdentifier: bundleID))
                }
            }

            return apps.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }.value
    }
}
