import AppKit
import SwiftUI

@main
struct LumaShellApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var coordinator: ShellWindowCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = ShellController()
        let coordinator = ShellWindowCoordinator(controller: controller)
        self.coordinator = coordinator
        coordinator.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
