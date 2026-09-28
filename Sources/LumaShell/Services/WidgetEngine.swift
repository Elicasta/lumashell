import Foundation
import LumaShellCore

enum WidgetEngine {
    static func load(for theme: ShellTheme) -> Set<WidgetKind> {
        let key = storageKey(for: theme.id)
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return Set(theme.defaultWidgets)
        }

        do {
            return Set(try JSONDecoder().decode([WidgetKind].self, from: data))
        } catch {
            return Set(theme.defaultWidgets)
        }
    }

    static func save(_ widgets: Set<WidgetKind>, for themeID: ShellThemeID) {
        guard let data = try? JSONEncoder().encode(Array(widgets)) else { return }
        UserDefaults.standard.set(data, forKey: storageKey(for: themeID))
    }

    static func reset(for theme: ShellTheme) -> Set<WidgetKind> {
        UserDefaults.standard.removeObject(forKey: storageKey(for: theme.id))
        return Set(theme.defaultWidgets)
    }

    private static func storageKey(for themeID: ShellThemeID) -> String {
        "lumashell.widgets.\(themeID.rawValue)"
    }
}
