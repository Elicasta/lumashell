import Foundation

public enum ThemeCatalog {
    public static let all: [ShellTheme] = [
        ShellTheme(
            id: .macOS9,
            name: "Mac OS 9",
            subtitle: "Platinum-era desktop",
            layout: .classicMac,
            colors: ShellThemeColors(
                backgroundStart: "#5E8EA5", backgroundEnd: "#4E7E95",
                panel: "#DDDDDD", panelAlt: "#BDBDBD", border: "#222222",
                text: "#111111", mutedText: "#555555", accent: "#334FAD",
                accent2: "#FFFFFF", selection: "#334FAD", shadow: "#000000"
            ),
            panelHeight: 28, cornerRadius: 0, startLabel: "◆",
            computerLabel: "Macintosh HD", trashLabel: "Trash",
            defaultWidgets: [.clock, .memory, .quickLaunch, .assistant]
        ),
        ShellTheme(
            id: .windowsXP,
            name: "Windows XP",
            subtitle: "Blue taskbar, green fields, fast launch",
            layout: .taskbar,
            colors: ShellThemeColors(
                backgroundStart: "#1A74CC", backgroundEnd: "#63A6E8",
                panel: "#245EDB", panelAlt: "#3C81F3", border: "#0A2D91",
                text: "#FFFFFF", mutedText: "#D6E4FF", accent: "#3AA13B",
                accent2: "#F0B400", selection: "#2A63D4", shadow: "#071D5B"
            ),
            panelHeight: 46, cornerRadius: 7, startLabel: "start",
            computerLabel: "My Computer", trashLabel: "Recycle Bin",
            defaultWidgets: [.clock, .system, .quickLaunch, .assistant]
        ),
        ShellTheme(
            id: .cyberpunk,
            name: "Luma Neon",
            subtitle: "Cyberpunk command shell",
            layout: .commandDeck,
            colors: ShellThemeColors(
                backgroundStart: "#050511", backgroundEnd: "#10112A",
                panel: "#0A0B18", panelAlt: "#12152B", border: "#21E6FF",
                text: "#F4FBFF", mutedText: "#86A8B5", accent: "#21E6FF",
                accent2: "#FF37D1", selection: "#123E57", shadow: "#000000"
            ),
            panelHeight: 58, cornerRadius: 2, startLabel: "LUMA//",
            computerLabel: "CORE", trashLabel: "PURGE", preferredMonospacedUI: true,
            defaultWidgets: [.clock, .system, .assistant]
        )
    ]

    public static func theme(_ id: ShellThemeID) -> ShellTheme {
        all.first(where: { $0.id == id }) ?? all[0]
    }
}

public extension String {
    var isSixDigitHexColor: Bool {
        guard count == 7, first == "#" else { return false }
        return dropFirst().allSatisfy { $0.isHexDigit }
    }
}
