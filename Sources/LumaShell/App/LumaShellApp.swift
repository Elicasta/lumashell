import AppKit

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var coordinator: ShellWindowCoordinator?

    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()

        application.delegate = delegate
        application.setActivationPolicy(.accessory)
        application.run()

        withExtendedLifetime(delegate) {}
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = ShellController()
        let coordinator = ShellWindowCoordinator(controller: controller)
        self.coordinator = coordinator
        coordinator.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        .terminateNow
    }

    func applicationWillTerminate(_ notification: Notification) {
        NSApp.presentationOptions = []
    }
}
