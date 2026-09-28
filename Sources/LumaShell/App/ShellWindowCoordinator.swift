import AppKit
import SwiftUI
import LumaShellCore

@MainActor
final class ShellWindowCoordinator: NSObject {
    private let controller: ShellController
    private var windows: [NSWindow] = []
    private var statusItem: NSStatusItem?
    private var localKeyMonitor: Any?
    private var globalKeyMonitor: Any?
    private var screenObserver: NSObjectProtocol?

    init(controller: ShellController) {
        self.controller = controller
        super.init()

        controller.hideShellRequested = { [weak self] in
            self?.hideShell()
        }
        controller.immersiveModeDidChange = { [weak self] _ in
            self?.applyPresentationMode()
        }
    }

    func start() {
        rebuildWindows()
        installStatusItem()
        installEscapeHotkey()

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.rebuildWindows()
                self?.showShell()
            }
        }

        showShell()
    }

    private func rebuildWindows() {
        windows.forEach {
            $0.orderOut(nil)
            $0.close()
        }
        windows.removeAll()

        let screens = NSScreen.screens
        guard !screens.isEmpty else {
            NSLog("LumaShell: no screens available yet")
            return
        }

        for screen in screens {
            let root = ShellRootView(screenName: screen.localizedName)
                .environmentObject(controller)

            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false,
                screen: screen
            )

            window.title = "LumaShell"
            window.contentViewController = NSHostingController(rootView: root)
            window.isReleasedWhenClosed = false
            window.hidesOnDeactivate = false
            window.canHide = false
            window.isOpaque = true
            window.backgroundColor = .black
            window.hasShadow = false
            window.level = .normal
            window.collectionBehavior = [
                .canJoinAllSpaces,
                .fullScreenAuxiliary,
                .stationary,
                .ignoresCycle
            ]
            window.setFrame(screen.frame, display: true)

            windows.append(window)
        }
    }

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "LS"

        let menu = NSMenu()

        let show = menu.addItem(withTitle: "Show LumaShell", action: #selector(showFromMenu), keyEquivalent: "")
        show.target = self

        let hide = menu.addItem(withTitle: "Hide LumaShell", action: #selector(hideFromMenu), keyEquivalent: "")
        hide.target = self

        let themeMenu = NSMenu(title: "Theme")
        for theme in ThemeCatalog.all {
            let menuItem = NSMenuItem(
                title: theme.name,
                action: #selector(selectThemeFromMenu(_:)),
                keyEquivalent: ""
            )
            menuItem.representedObject = theme.id.rawValue
            menuItem.target = self
            themeMenu.addItem(menuItem)
        }

        let themeRoot = NSMenuItem(title: "Theme", action: nil, keyEquivalent: "")
        themeRoot.submenu = themeMenu
        menu.addItem(themeRoot)
        menu.addItem(.separator())

        let quit = menu.addItem(withTitle: "Quit LumaShell", action: #selector(quitFromMenu), keyEquivalent: "q")
        quit.target = self

        item.menu = menu
        statusItem = item
    }

    private func installEscapeHotkey() {
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if Self.isEscapeChord(event) {
                Task { @MainActor [weak self] in
                    self?.hideShell()
                }
                return nil
            }
            return event
        }

        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard Self.isEscapeChord(event) else { return }
            Task { @MainActor [weak self] in
                self?.hideShell()
            }
        }
    }

    private static func isEscapeChord(_ event: NSEvent) -> Bool {
        event.keyCode == 53 &&
        event.modifierFlags.contains(.command) &&
        event.modifierFlags.contains(.shift)
    }

    private func applyPresentationMode() {
        guard windows.contains(where: { $0.isVisible }) else {
            NSApp.presentationOptions = []
            return
        }

        NSApp.presentationOptions = controller.immersiveMode
            ? [.autoHideDock, .autoHideMenuBar]
            : []
    }

    @objc private func showFromMenu() {
        showShell()
    }

    @objc private func hideFromMenu() {
        hideShell()
    }

    @objc private func quitFromMenu() {
        NSApp.presentationOptions = []
        NSApplication.shared.terminate(nil)
    }

    @objc private func selectThemeFromMenu(_ sender: NSMenuItem) {
        guard
            let raw = sender.representedObject as? String,
            let id = ShellThemeID(rawValue: raw)
        else { return }

        controller.selectedThemeID = id
        showShell()
    }

    func showShell() {
        guard !windows.isEmpty else {
            rebuildWindows()
            guard !windows.isEmpty else { return }
        }

        windows.forEach { window in
            window.setFrame(window.screen?.frame ?? window.frame, display: true)
            window.orderFrontRegardless()
        }

        NSApp.activate(ignoringOtherApps: true)
        applyPresentationMode()
    }

    func hideShell() {
        controller.closeAllPanels()
        windows.forEach { $0.orderOut(nil) }
        NSApp.presentationOptions = []
    }

    deinit {
        NSApp.presentationOptions = []

        if let localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
        }
        if let globalKeyMonitor {
            NSEvent.removeMonitor(globalKeyMonitor)
        }
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
        }
    }
}
