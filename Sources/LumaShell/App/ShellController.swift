import AppKit
import Combine
import Foundation
import LumaShellCore

@MainActor
final class ShellController: ObservableObject {
    @Published var selectedThemeID: ShellThemeID {
        didSet {
            UserDefaults.standard.set(selectedThemeID.rawValue, forKey: Keys.theme)
        }
    }

    @Published var immersiveMode: Bool {
        didSet {
            UserDefaults.standard.set(immersiveMode, forKey: Keys.immersive)
            immersiveModeDidChange?(immersiveMode)
        }
    }

    @Published var isLauncherOpen = false
    @Published var isSettingsOpen = false
    @Published var browserURL: URL?
    @Published var appSearch = ""
    @Published private(set) var installedApps: [ShellAppItem] = []
    @Published private(set) var runningApps: [RunningShellApp] = []

    var hideShellRequested: (() -> Void)?
    var immersiveModeDidChange: ((Bool) -> Void)?

    private var workspaceObservers: [NSObjectProtocol] = []

    var theme: ShellTheme {
        ThemeCatalog.theme(selectedThemeID)
    }

    init() {
        if
            let raw = UserDefaults.standard.string(forKey: Keys.theme),
            let saved = ShellThemeID(rawValue: raw)
        {
            selectedThemeID = saved
        } else {
            selectedThemeID = .cyberpunk
        }

        if UserDefaults.standard.object(forKey: Keys.immersive) == nil {
            immersiveMode = true
        } else {
            immersiveMode = UserDefaults.standard.bool(forKey: Keys.immersive)
        }

        observeWorkspace()
        refreshRunningApps()
        reloadApplications()
    }

    deinit {
        let center = NSWorkspace.shared.notificationCenter
        workspaceObservers.forEach(center.removeObserver)
    }

    func reloadApplications() {
        Task { [weak self] in
            let apps = await AppRegistry.scanApplications()
            guard let self else { return }
            self.installedApps = apps
        }
    }

    func launch(_ app: ShellAppItem) {
        isLauncherOpen = false
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: app.url, configuration: configuration) { _, error in
            if let error {
                NSLog("LumaShell could not launch %@: %@", app.name, error.localizedDescription)
            }
        }
    }

    func activate(_ running: RunningShellApp) {
        isLauncherOpen = false
        guard let app = NSRunningApplication(processIdentifier: pid_t(running.pid)) else { return }
        app.activate(options: [.activateAllWindows])
    }

    func openBrowser(at url: URL) {
        isLauncherOpen = false
        browserURL = url
    }

    func openApplications() {
        openBrowser(at: URL(fileURLWithPath: "/Applications", isDirectory: true))
    }

    func openHome() {
        openBrowser(at: FileManager.default.homeDirectoryForCurrentUser)
    }

    func openTrash() {
        openBrowser(at: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash"))
    }

    func closeAllPanels() {
        browserURL = nil
        isSettingsOpen = false
        isLauncherOpen = false
    }

    private func observeWorkspace() {
        let center = NSWorkspace.shared.notificationCenter
        let names: [Notification.Name] = [
            NSWorkspace.didLaunchApplicationNotification,
            NSWorkspace.didTerminateApplicationNotification,
            NSWorkspace.didActivateApplicationNotification,
            NSWorkspace.didHideApplicationNotification,
            NSWorkspace.didUnhideApplicationNotification
        ]

        workspaceObservers = names.map { name in
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.refreshRunningApps()
                }
            }
        }
    }

    private func refreshRunningApps() {
        runningApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && !$0.isTerminated }
            .map(RunningShellApp.init)
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private enum Keys {
        static let theme = "lumashell.theme"
        static let immersive = "lumashell.immersive"
    }
}

struct RunningShellApp: Identifiable {
    let pid: Int
    let name: String
    let bundleIdentifier: String?
    let bundleURL: URL?

    var id: Int { pid }

    init(_ app: NSRunningApplication) {
        pid = Int(app.processIdentifier)
        name = app.localizedName ?? app.bundleIdentifier ?? "Application"
        bundleIdentifier = app.bundleIdentifier
        bundleURL = app.bundleURL
    }
}
