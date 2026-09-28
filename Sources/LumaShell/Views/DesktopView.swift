import SwiftUI
import LumaShellCore

struct DesktopView: View {
    @EnvironmentObject private var controller: ShellController

    private var theme: ShellTheme { controller.theme }

    var body: some View {
        VStack(spacing: 18) {
            DesktopIcon(symbol: "internaldrive.fill", label: theme.computerLabel) {
                controller.openHome()
            }
            DesktopIcon(symbol: "square.grid.2x2.fill", label: "Applications") {
                controller.openApplications()
            }
            DesktopIcon(symbol: "house.fill", label: "Home") {
                controller.openHome()
            }
            DesktopIcon(symbol: theme.id == .windowsXP ? "trash.fill" : "trash", label: theme.trashLabel) {
                controller.openTrash()
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: theme.layout == .classicMac ? .topTrailing : .topLeading)
        .padding(.top, theme.layout == .classicMac ? theme.panelHeight + 22 : 26)
        .padding(.horizontal, 22)
        .padding(.bottom, theme.layout == .classicMac ? 18 : theme.panelHeight + 18)
    }
}

private struct DesktopIcon: View {
    @EnvironmentObject private var controller: ShellController
    let symbol: String
    let label: String
    let action: () -> Void

    @State private var selected = false

    var theme: ShellTheme { controller.theme }

    var body: some View {
        Button {
            selected = true
            action()
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    if theme.id == .cyberpunk {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: theme.colors.panel).opacity(0.85))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color(hex: theme.colors.accent).opacity(0.7), lineWidth: 1)
                            )
                    }

                    Image(systemName: symbol)
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(theme.id == .cyberpunk ? Color(hex: theme.colors.accent) : Color.white)
                }
                .frame(width: 58, height: 52)
                .shadow(color: .black.opacity(0.35), radius: 3, x: 0, y: 2)

                Text(label)
                    .font(theme.preferredMonospacedUI ? .system(size: 11, weight: .medium, design: .monospaced) : .system(size: 11, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(selected ? Color(hex: theme.colors.selection) : Color.black.opacity(0.20))
                    .lineLimit(1)
            }
            .frame(width: 92)
        }
        .buttonStyle(.plain)
    }
}
