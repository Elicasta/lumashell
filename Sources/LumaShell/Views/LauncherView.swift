import SwiftUI
import LumaShellCore

struct LauncherView: View {
    @EnvironmentObject private var controller: ShellController

    private var theme: ShellTheme { controller.theme }

    private var filteredApps: [ShellAppItem] {
        let query = controller.appSearch.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            return Array(controller.installedApps.prefix(theme.layout == .classicMac ? 10 : 14))
        }
        return Array(controller.installedApps.filter { $0.name.localizedCaseInsensitiveContains(query) }.prefix(18))
    }

    var body: some View {
        VStack(spacing: 0) {
            if theme.layout != .classicMac {
                header
            }

            if theme.layout != .classicMac {
                TextField(theme.id == .cyberpunk ? "RUN COMMAND / FIND APP" : "Search programs", text: $controller.appSearch)
                    .textFieldStyle(.plain)
                    .font(theme.preferredMonospacedUI ? .system(size: 12, design: .monospaced) : .system(size: 12))
                    .padding(10)
                    .background(Color(hex: theme.colors.panelAlt))
                    .foregroundStyle(Color(hex: theme.colors.text))
                    .overlay(Rectangle().stroke(Color(hex: theme.colors.border).opacity(0.8), lineWidth: 1))
                    .padding(10)
            }

            if theme.layout == .classicMac {
                classicCommands
            }

            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(filteredApps) { app in
                        Button {
                            controller.launch(app)
                        } label: {
                            HStack(spacing: 10) {
                                AppIconView(url: app.url, size: 24)
                                Text(app.name).lineLimit(1)
                                Spacer()
                            }
                            .font(theme.preferredMonospacedUI ? .system(size: 12, design: .monospaced) : .system(size: 12))
                            .foregroundStyle(Color(hex: theme.colors.text))
                            .padding(.horizontal, 10)
                            .frame(height: 34)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 6)
            }
            .frame(maxHeight: theme.layout == .classicMac ? 300 : 330)

            Divider().overlay(Color(hex: theme.colors.border))

            HStack {
                Button("Settings") {
                    controller.isSettingsOpen = true
                    controller.isLauncherOpen = false
                }
                .buttonStyle(ShellButtonStyle(theme: theme, compact: true))

                Spacer()

                Button(theme.id == .cyberpunk ? "DISENGAGE" : "Hide Shell") {
                    controller.hideShellRequested?()
                }
                .buttonStyle(ShellButtonStyle(theme: theme, compact: true))
            }
            .padding(8)
        }
        .background(Color(hex: theme.colors.panel).opacity(theme.id == .cyberpunk ? 0.96 : 1))
        .overlay(Rectangle().stroke(Color(hex: theme.colors.border), lineWidth: theme.id == .cyberpunk ? 2 : 1))
        .shadow(color: Color(hex: theme.colors.shadow).opacity(0.55), radius: 14, x: 0, y: 7)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(theme.id == .cyberpunk ? "LUMASHELL // COMMAND INDEX" : "LumaShell")
                    .font(theme.preferredMonospacedUI ? .system(size: 13, weight: .black, design: .monospaced) : .system(size: 17, weight: .bold))
                Text(theme.subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: theme.colors.mutedText))
            }
            Spacer()
        }
        .foregroundStyle(Color(hex: theme.colors.text))
        .padding(12)
        .background(Color(hex: theme.colors.panelAlt))
    }

    private var classicCommands: some View {
        VStack(spacing: 0) {
            classicRow("About This Mac", symbol: "info.circle") {
                controller.isSettingsOpen = true
                controller.isLauncherOpen = false
            }
            classicRow("Applications", symbol: "folder") {
                controller.openApplications()
            }
            classicRow("Control Panels", symbol: "slider.horizontal.3") {
                controller.isSettingsOpen = true
                controller.isLauncherOpen = false
            }
            Divider().padding(.vertical, 4)
        }
        .padding(.top, 5)
    }

    private func classicRow(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: symbol).frame(width: 22)
                Text(title)
                Spacer()
            }
            .font(.system(size: 12))
            .foregroundStyle(Color(hex: theme.colors.text))
            .padding(.horizontal, 9)
            .frame(height: 28)
        }
        .buttonStyle(.plain)
    }
}
