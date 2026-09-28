import SwiftUI
import LumaShellCore

struct ShellBarView: View {
    @EnvironmentObject private var controller: ShellController

    private var theme: ShellTheme { controller.theme }

    var body: some View {
        VStack(spacing: 0) {
            if theme.layout == .classicMac {
                classicMenuBar
                Spacer()
            } else {
                Spacer()
                modernTaskbar
            }
        }
    }

    private var classicMenuBar: some View {
        HStack(spacing: 14) {
            Button(theme.startLabel) {
                controller.isLauncherOpen.toggle()
            }
            .buttonStyle(.plain)
            .font(.system(size: 15, weight: .black))

            Text("File")
            Text("Edit")
            Text("View")
            Text("Special")

            Spacer()

            Text("LumaShell")
                .font(.system(size: 11, weight: .semibold))
            ClockText(theme: theme)
        }
        .foregroundStyle(Color(hex: theme.colors.text))
        .padding(.horizontal, 10)
        .frame(height: theme.panelHeight)
        .background(Color(hex: theme.colors.panel))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color(hex: theme.colors.border)).frame(height: 1)
        }
    }

    private var modernTaskbar: some View {
        HStack(spacing: theme.id == .cyberpunk ? 8 : 4) {
            Button {
                controller.isLauncherOpen.toggle()
            } label: {
                HStack(spacing: 6) {
                    if theme.id == .windowsXP {
                        Image(systemName: "flag.fill")
                    }
                    Text(theme.startLabel)
                }
                .font(theme.preferredMonospacedUI ? .system(size: 13, weight: .black, design: .monospaced) : .system(size: 14, weight: .bold))
                .foregroundStyle(Color(hex: theme.colors.text))
                .padding(.horizontal, theme.id == .cyberpunk ? 14 : 12)
                .frame(height: theme.panelHeight - 8)
                .background(Color(hex: theme.colors.accent).opacity(theme.id == .windowsXP ? 0.95 : 0.16))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadius)
                        .stroke(Color(hex: theme.id == .cyberpunk ? theme.colors.accent : theme.colors.border), lineWidth: theme.id == .cyberpunk ? 1.5 : 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius))
            }
            .buttonStyle(.plain)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(controller.runningApps) { running in
                        Button {
                            controller.activate(running)
                        } label: {
                            HStack(spacing: 6) {
                                AppIconView(url: running.bundleURL, size: 20)
                                Text(running.name).lineLimit(1)
                            }
                            .font(theme.preferredMonospacedUI ? .system(size: 11, design: .monospaced) : .system(size: 11))
                            .foregroundStyle(Color(hex: theme.colors.text))
                            .padding(.horizontal, 8)
                            .frame(height: theme.panelHeight - 10)
                            .background(Color(hex: theme.colors.panelAlt).opacity(0.88))
                            .overlay(
                                RoundedRectangle(cornerRadius: theme.cornerRadius)
                                    .stroke(Color(hex: theme.colors.border).opacity(0.7), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Spacer(minLength: 8)

            if theme.id == .cyberpunk {
                Text("SYSTEM READY")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: theme.colors.accent))
            }

            ClockText(theme: theme).padding(.horizontal, 10)
        }
        .padding(.horizontal, 6)
        .frame(height: theme.panelHeight)
        .background(Color(hex: theme.colors.panel).opacity(theme.id == .cyberpunk ? 0.94 : 1))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(hex: theme.id == .cyberpunk ? theme.colors.accent : theme.colors.border))
                .frame(height: theme.id == .cyberpunk ? 1.5 : 1)
        }
    }
}
