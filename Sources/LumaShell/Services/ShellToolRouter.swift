import AppKit
import Foundation
import LumaShellCore

enum ShellToolRouter {
    @MainActor
    static func execute(
        name: String,
        arguments: [String: Any],
        controller: ShellController
    ) async -> String {
        guard let tool = AssistantToolName(rawValue: name) else {
            return "Unknown tool: \(name)"
        }

        switch tool {
        case .listApps:
            let names = controller.installedApps.prefix(80).map(\.name)
            return names.isEmpty ? "No applications found." : names.joined(separator: ", ")

        case .launchApp:
            guard let requested = arguments["app"] as? String else {
                return "Missing app name."
            }

            let exact = controller.installedApps.first {
                $0.name.compare(requested, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
            }
            let partial = controller.installedApps.first {
                $0.name.localizedCaseInsensitiveContains(requested)
            }

            guard let app = exact ?? partial else {
                return "Could not find an installed app matching \(requested)."
            }

            controller.launch(app)
            return "Launched \(app.name)."

        case .setTheme:
            guard
                let raw = arguments["theme"] as? String,
                let themeID = ShellThemeID(rawValue: raw)
            else {
                return "Theme must be macOS9, windowsXP, or cyberpunk."
            }

            controller.selectedThemeID = themeID
            return "Theme changed to \(controller.theme.name)."

        case .setWidget:
            guard
                let raw = arguments["widget"] as? String,
                let kind = WidgetKind(rawValue: raw),
                let visible = arguments["visible"] as? Bool
            else {
                return "Widget request was invalid."
            }

            controller.setWidget(kind, enabled: visible)
            return "\(kind.displayName) is now \(visible ? "visible" : "hidden")."

        case .openFolder:
            guard let location = arguments["location"] as? String else {
                return "Missing folder location."
            }

            let home = FileManager.default.homeDirectoryForCurrentUser
            let url: URL?
            switch location.lowercased() {
            case "home":
                url = home
            case "desktop":
                url = home.appendingPathComponent("Desktop", isDirectory: true)
            case "documents":
                url = home.appendingPathComponent("Documents", isDirectory: true)
            case "downloads":
                url = home.appendingPathComponent("Downloads", isDirectory: true)
            case "applications":
                url = URL(fileURLWithPath: "/Applications", isDirectory: true)
            default:
                url = nil
            }

            guard let url else {
                return "Allowed folders are Home, Desktop, Documents, Downloads, and Applications."
            }

            controller.openBrowser(at: url)
            return "Opened \(location)."

        case .hideShell:
            controller.hideShellRequested?()
            return "LumaShell hidden."
        }
    }
}
