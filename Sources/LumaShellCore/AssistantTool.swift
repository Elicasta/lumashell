import Foundation

public enum AssistantToolName: String, CaseIterable, Codable, Sendable {
    case listApps = "list_apps"
    case launchApp = "launch_app"
    case setTheme = "set_theme"
    case setWidget = "set_widget"
    case openFolder = "open_folder"
    case hideShell = "hide_shell"
}
