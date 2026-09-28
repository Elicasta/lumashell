import SwiftUI
import LumaShellCore

struct SettingsView: View {
    @EnvironmentObject private var controller: ShellController
    @State private var launchAtLogin = LaunchAtLoginManager.isEnabled
    @State private var serviceError: String?
    @State private var accessibilityTrusted = PermissionManager.isAccessibilityTrusted

    private var theme: ShellTheme { controller.theme }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                sectionTitle("THEMES")

                HStack(spacing: 10) {
                    ForEach(ThemeCatalog.all) { candidate in
                        Button {
                            controller.selectedThemeID = candidate.id
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 4) {
                                    Color(hex: candidate.colors.backgroundStart)
                                    Color(hex: candidate.colors.accent)
                                    Color(hex: candidate.colors.accent2)
                                }
                                .frame(height: 42)
                                .clipShape(RoundedRectangle(cornerRadius: max(candidate.cornerRadius, 2)))

                                Text(candidate.name)
                                    .font(.system(size: 12, weight: .bold))
                                Text(candidate.subtitle)
                                    .font(.system(size: 9))
                                    .foregroundStyle(Color(hex: theme.colors.mutedText))
                                    .lineLimit(2)
                            }
                            .foregroundStyle(Color(hex: theme.colors.text))
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: theme.colors.panel))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(
                                        Color(hex: controller.selectedThemeID == candidate.id ? theme.colors.accent : theme.colors.border),
                                        lineWidth: controller.selectedThemeID == candidate.id ? 2 : 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                sectionTitle("WIDGETS")

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 8)], spacing: 8) {
                    ForEach(WidgetKind.allCases) { kind in
                        Toggle(kind.displayName, isOn: Binding(
                            get: { controller.enabledWidgets.contains(kind) },
                            set: { controller.setWidget(kind, enabled: $0) }
                        ))
                        .toggleStyle(.switch)
                        .padding(9)
                        .background(Color(hex: theme.colors.panel))
                        .overlay(
                            RoundedRectangle(cornerRadius: max(theme.cornerRadius, 3))
                                .stroke(Color(hex: theme.colors.border).opacity(0.55), lineWidth: 1)
                        )
                    }
                }

                HStack {
                    Text("Each theme remembers its own widget layout.")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: theme.colors.mutedText))
                    Spacer()
                    Button("Reset Theme Widgets") {
                        controller.resetWidgetsForCurrentTheme()
                    }
                    .buttonStyle(ShellButtonStyle(theme: theme, compact: true))
                }

                sectionTitle("LUMA AI")

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(controller.isAIConfigured ? "Development AI connected" : "AI tool router ready")
                            .font(.system(size: 12, weight: .semibold))
                        Text(
                            controller.isAIConfigured
                                ? "GPT-5.6 Luna can launch apps, change themes, manage widgets, and open common folders."
                                : "For this private development build, launch with OPENAI_API_KEY set. A backend should replace direct-key mode before public distribution."
                        )
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: theme.colors.mutedText))
                    }

                    Spacer()

                    Button("Open Luma") {
                        controller.setWidget(.assistant, enabled: true)
                        controller.isAssistantOpen = true
                        controller.isSettingsOpen = false
                    }
                    .buttonStyle(ShellButtonStyle(theme: theme, compact: true))
                }

                sectionTitle("SHELL")

                Toggle("Immersive mode: auto-hide macOS Dock and menu bar while LumaShell is active", isOn: $controller.immersiveMode)
                    .toggleStyle(.switch)

                Toggle("Show real Desktop files inside LumaShell", isOn: $controller.showDesktopFiles)
                    .toggleStyle(.switch)

                Toggle("Launch LumaShell at login", isOn: $launchAtLogin)
                    .toggleStyle(.switch)
                    .onChange(of: launchAtLogin) { enabled in
                        serviceError = LaunchAtLoginManager.setEnabled(enabled)
                        launchAtLogin = LaunchAtLoginManager.isEnabled
                    }

                sectionTitle("SYSTEM CONTROL")

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Accessibility")
                            .font(.system(size: 12, weight: .semibold))
                        Text(accessibilityTrusted ? "Granted. Window-control modules can build on this permission." : "Not granted. Basic shell features still work.")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(hex: theme.colors.mutedText))
                    }
                    Spacer()
                    if !accessibilityTrusted {
                        Button("Request Access") {
                            _ = PermissionManager.requestAccessibility()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                accessibilityTrusted = PermissionManager.isAccessibilityTrusted
                            }
                        }
                        .buttonStyle(ShellButtonStyle(theme: theme, compact: true))
                    }
                }

                if let serviceError {
                    Text(serviceError)
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: theme.colors.accent2))
                }

                sectionTitle("SAFETY")
                Text("⌘⇧Esc hides LumaShell immediately. The LS menu-bar item can always show, hide, switch themes, or quit the shell.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: theme.colors.text))
            }
            .padding(18)
        }
        .background(Color(hex: theme.colors.panelAlt))
        .foregroundStyle(Color(hex: theme.colors.text))
    }

    private func sectionTitle(_ value: String) -> some View {
        Text(value)
            .font(theme.preferredMonospacedUI ? .system(size: 10, weight: .black, design: .monospaced) : .system(size: 10, weight: .black))
            .tracking(1.2)
            .foregroundStyle(Color(hex: theme.colors.accent))
    }
}
