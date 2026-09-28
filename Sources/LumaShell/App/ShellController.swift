import AppKit
import Combine
import Foundation
import LumaShellCore

struct AssistantMessage: Identifiable {
    enum Role: Equatable {
        case user
        case assistant
    }

    let id = UUID()
    let role: Role
    let text: String
}

@MainActor
final class ShellController: ObservableObject {
    @Published var selectedThemeID: ShellThemeID {
        didSet {
            UserDefaults.standard.set(selectedThemeID.rawValue, forKey: Keys.theme)
            enabledWidgets = WidgetEngine.load(for: theme)
        }
    }

    @Published var immersiveMode: Bool {
        didSet {
            UserDefaults.standard.set(immersiveMode, forKey: Keys.immersive)
            immersiveModeDidChange?(immersiveMode)
        }
    }

    @Published var showDesktopFiles: Bool {
        didSet {
            UserDefaults.standard.set(showDesktopFiles, forKey: Keys.showDesktopFiles)
        }
    }

    @Published var enabledWidgets: Set<WidgetKind>
    @Published var isLauncherOpen = false
    @Published var isSettingsOpen = false
    @Published var isAssistantOpen = false
    @Published var assistantBusy = false
    @Published var assistantDraft = ""
    @Published var assistantMessages: [AssistantMessage] = [
        AssistantMessage(role: .assistant, text: "Luma online. Ask me to open an app, change the theme, manage widgets, or open a folder.")
    ]
    @Published var browserURL: URL?
    @Published var appSearch = ""
    @Published private(set) var installedApps: [ShellAppItem] = []
    @Published private(set) var runningApps: [RunningShellApp] = []

    var hideShellRequested: (() -> Void)?
    var immersiveModeDidChange: ((Bool) -> Void)?

    private var workspaceObservers: [NSObjectProtocol] = []
    private let aiClient = LumaAIClient()

    var theme: ShellTheme {
        ThemeCatalog.theme(selectedThemeID)
    }

    var isAIConfigured: Bool {
        let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
        return key?.isEmpty == false
    }

    init() {
        let themeID: ShellThemeID
        if
            let raw = UserDefaults.standard.string(forKey: Keys.theme),
            let saved = ShellThemeID(rawValue: raw)
        {
            themeID = saved
        } else {
            themeID = .cyberpunk
        }

        selectedThemeID = themeID
        enabledWidgets = WidgetEngine.load(for: ThemeCatalog.theme(themeID))

        if UserDefaults.standard.object(forKey: Keys.immersive) == nil {
            immersiveMode = true
        } else {
            immersiveMode = UserDefaults.standard.bool(forKey: Keys.immersive)
        }

        if UserDefaults.standard.object(forKey: Keys.showDesktopFiles) == nil {
            showDesktopFiles = true
        } else {
            showDesktopFiles = UserDefaults.standard.bool(forKey: Keys.showDesktopFiles)
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

    func setWidget(_ kind: WidgetKind, enabled: Bool) {
        if enabled {
            enabledWidgets.insert(kind)
        } else {
            enabledWidgets.remove(kind)
            if kind == .assistant {
                isAssistantOpen = false
            }
        }
        WidgetEngine.save(enabledWidgets, for: selectedThemeID)
    }

    func resetWidgetsForCurrentTheme() {
        enabledWidgets = WidgetEngine.reset(for: theme)
        isAssistantOpen = false
    }

    func sendAssistantMessage() {
        let prompt = assistantDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty, !assistantBusy else { return }

        assistantDraft = ""
        assistantMessages.append(AssistantMessage(role: .user, text: prompt))
        assistantBusy = true

        Task {
            do {
                let reply = try await aiClient.send(prompt, controller: self)
                assistantMessages.append(AssistantMessage(role: .assistant, text: reply.text))
            } catch {
                assistantMessages.append(
                    AssistantMessage(
                        role: .assistant,
                        text: error.localizedDescription
                    )
                )
            }
            assistantBusy = false
        }
    }

    func closeAllPanels() {
        browserURL = nil
        isSettingsOpen = false
        isLauncherOpen = false
        isAssistantOpen = false
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
        static let showDesktopFiles = "lumashell.showDesktopFiles"
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
