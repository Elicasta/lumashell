import Foundation

public enum ShellThemeID: String, CaseIterable, Codable, Sendable, Identifiable {
    case macOS9
    case windowsXP
    case cyberpunk

    public var id: String { rawValue }
}

public enum ShellLayout: String, Codable, Sendable {
    case classicMac
    case taskbar
    case commandDeck
}

public struct ShellThemeColors: Equatable, Sendable {
    public let backgroundStart: String
    public let backgroundEnd: String
    public let panel: String
    public let panelAlt: String
    public let border: String
    public let text: String
    public let mutedText: String
    public let accent: String
    public let accent2: String
    public let selection: String
    public let shadow: String

    public init(backgroundStart: String, backgroundEnd: String, panel: String, panelAlt: String, border: String, text: String, mutedText: String, accent: String, accent2: String, selection: String, shadow: String) {
        self.backgroundStart = backgroundStart
        self.backgroundEnd = backgroundEnd
        self.panel = panel
        self.panelAlt = panelAlt
        self.border = border
        self.text = text
        self.mutedText = mutedText
        self.accent = accent
        self.accent2 = accent2
        self.selection = selection
        self.shadow = shadow
    }

    public var allHexValues: [String] {
        [backgroundStart, backgroundEnd, panel, panelAlt, border, text, mutedText, accent, accent2, selection, shadow]
    }
}

public struct ShellTheme: Identifiable, Equatable, Sendable {
    public let id: ShellThemeID
    public let name: String
    public let subtitle: String
    public let layout: ShellLayout
    public let colors: ShellThemeColors
    public let panelHeight: Double
    public let cornerRadius: Double
    public let startLabel: String
    public let computerLabel: String
    public let trashLabel: String
    public let preferredMonospacedUI: Bool

    public init(id: ShellThemeID, name: String, subtitle: String, layout: ShellLayout, colors: ShellThemeColors, panelHeight: Double, cornerRadius: Double, startLabel: String, computerLabel: String, trashLabel: String, preferredMonospacedUI: Bool = false) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.layout = layout
        self.colors = colors
        self.panelHeight = panelHeight
        self.cornerRadius = cornerRadius
        self.startLabel = startLabel
        self.computerLabel = computerLabel
        self.trashLabel = trashLabel
        self.preferredMonospacedUI = preferredMonospacedUI
    }
}
