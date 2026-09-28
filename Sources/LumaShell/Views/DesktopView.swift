import AppKit
import SwiftUI
import LumaShellCore

struct DesktopView: View {
    @EnvironmentObject private var controller: ShellController
    @State private var desktopItems: [DesktopFileItem] = []

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

            if controller.showDesktopFiles {
                ForEach(desktopItems.prefix(8)) { item in
                    DesktopFileIcon(item: item)
                }
            }

            Spacer()
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: theme.layout == .classicMac ? .topTrailing : .topLeading
        )
        .padding(.top, theme.layout == .classicMac ? theme.panelHeight + 22 : 26)
        .padding(.horizontal, 22)
        .padding(.bottom, theme.layout == .classicMac ? 18 : theme.panelHeight + 18)
        .onAppear(perform: reloadDesktopItems)
        .onChange(of: controller.showDesktopFiles) { _ in
            reloadDesktopItems()
        }
    }

    private func reloadDesktopItems() {
        guard controller.showDesktopFiles else {
            desktopItems = []
            return
        }

        let desktopURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop", isDirectory: true)

        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: desktopURL,
            includingPropertiesForKeys: [.isDirectoryKey, .isHiddenKey],
            options: [.skipsHiddenFiles]
        ) else {
            desktopItems = []
            return
        }

        desktopItems = urls
            .filter { url in
                let values = try? url.resourceValues(forKeys: [.isHiddenKey])
                return values?.isHidden != true
            }
            .sorted {
                $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending
            }
            .map(DesktopFileItem.init)
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
                    .font(
                        theme.preferredMonospacedUI
                            ? .system(size: 11, weight: .medium, design: .monospaced)
                            : .system(size: 11, weight: .medium)
                    )
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

private struct DesktopFileIcon: View {
    @EnvironmentObject private var controller: ShellController
    let item: DesktopFileItem

    private var theme: ShellTheme { controller.theme }

    var body: some View {
        Button {
            NSWorkspace.shared.open(item.url)
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    if theme.id == .cyberpunk {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: theme.colors.panel).opacity(0.78))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color(hex: theme.colors.accent).opacity(0.45), lineWidth: 1)
                            )
                    }

                    Image(nsImage: NSWorkspace.shared.icon(forFile: item.url.path))
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 42, height: 42)
                }
                .frame(width: 58, height: 52)
                .shadow(color: .black.opacity(0.35), radius: 3, x: 0, y: 2)

                Text(item.displayName)
                    .font(
                        theme.preferredMonospacedUI
                            ? .system(size: 10, weight: .medium, design: .monospaced)
                            : .system(size: 10, weight: .medium)
                    )
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.20))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 92)
        }
        .buttonStyle(.plain)
        .help(item.url.path)
    }
}

private struct DesktopFileItem: Identifiable {
    let url: URL

    var id: String { url.path }

    var displayName: String {
        url.deletingPathExtension().lastPathComponent
    }

    init(_ url: URL) {
        self.url = url
    }
}
