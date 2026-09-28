import SwiftUI
import LumaShellCore

struct ShellRootView: View {
    @EnvironmentObject private var controller: ShellController
    let screenName: String

    private var theme: ShellTheme { controller.theme }

    var body: some View {
        ZStack {
            ThemeBackground(theme: theme)
                .contentShape(Rectangle())
                .onTapGesture {
                    controller.isLauncherOpen = false
                }

            DesktopView()

            if let url = controller.browserURL {
                FloatingShellWindow(
                    title: theme.computerLabel,
                    preferredSize: CGSize(width: 820, height: 560),
                    onClose: { controller.browserURL = nil }
                ) {
                    FileBrowserView(initialURL: url)
                }
                .zIndex(10)
            }

            if controller.isSettingsOpen {
                FloatingShellWindow(
                    title: theme.id == .cyberpunk ? "SYSTEM CONFIG" : "LumaShell Settings",
                    preferredSize: CGSize(width: 620, height: 500),
                    onClose: { controller.isSettingsOpen = false }
                ) {
                    SettingsView()
                }
                .zIndex(11)
            }

            LauncherPlacement()
                .zIndex(20)

            ShellBarView()
                .zIndex(30)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(screenName)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color(hex: theme.colors.mutedText).opacity(0.55))
                }
            }
            .padding(8)
            .padding(.bottom, theme.layout == .classicMac ? 0 : theme.panelHeight)
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

private struct LauncherPlacement: View {
    @EnvironmentObject private var controller: ShellController

    var body: some View {
        if controller.isLauncherOpen {
            LauncherView()
                .frame(width: controller.theme.layout == .classicMac ? 320 : 390)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: controller.theme.layout == .classicMac ? .topLeading : .bottomLeading)
                .padding(.leading, controller.theme.layout == .classicMac ? 4 : 8)
                .padding(.top, controller.theme.layout == .classicMac ? controller.theme.panelHeight + 3 : 0)
                .padding(.bottom, controller.theme.layout == .classicMac ? 0 : controller.theme.panelHeight + 7)
        }
    }
}

private struct ThemeBackground: View {
    let theme: ShellTheme

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [Color(hex: theme.colors.backgroundStart), Color(hex: theme.colors.backgroundEnd)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                if theme.id == .windowsXP {
                    XPFieldBackdrop(size: geometry.size)
                }

                if theme.id == .cyberpunk {
                    CyberGrid(size: geometry.size)
                    RadialGradient(
                        colors: [Color(hex: theme.colors.accent2).opacity(0.22), .clear],
                        center: .topTrailing,
                        startRadius: 20,
                        endRadius: min(geometry.size.width, geometry.size.height) * 0.7
                    )
                }
            }
        }
    }
}

private struct XPFieldBackdrop: View {
    let size: CGSize

    var body: some View {
        ZStack(alignment: .bottom) {
            Path { path in
                path.move(to: CGPoint(x: 0, y: size.height * 0.66))
                path.addCurve(
                    to: CGPoint(x: size.width, y: size.height * 0.70),
                    control1: CGPoint(x: size.width * 0.25, y: size.height * 0.42),
                    control2: CGPoint(x: size.width * 0.68, y: size.height * 0.86)
                )
                path.addLine(to: CGPoint(x: size.width, y: size.height))
                path.addLine(to: CGPoint(x: 0, y: size.height))
                path.closeSubpath()
            }
            .fill(Color(hex: "#3F9B3D"))

            Path { path in
                path.move(to: CGPoint(x: 0, y: size.height * 0.79))
                path.addCurve(
                    to: CGPoint(x: size.width, y: size.height * 0.77),
                    control1: CGPoint(x: size.width * 0.38, y: size.height * 0.66),
                    control2: CGPoint(x: size.width * 0.70, y: size.height * 0.92)
                )
                path.addLine(to: CGPoint(x: size.width, y: size.height))
                path.addLine(to: CGPoint(x: 0, y: size.height))
                path.closeSubpath()
            }
            .fill(Color(hex: "#2E7D32").opacity(0.75))
        }
    }
}

private struct CyberGrid: View {
    let size: CGSize

    var body: some View {
        Path { path in
            let step: CGFloat = 44
            stride(from: CGFloat.zero, through: size.width, by: step).forEach { x in
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            stride(from: CGFloat.zero, through: size.height, by: step).forEach { y in
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
        }
        .stroke(Color(hex: "#21E6FF").opacity(0.08), lineWidth: 1)
    }
}
