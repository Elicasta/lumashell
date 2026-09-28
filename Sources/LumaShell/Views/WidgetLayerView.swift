import AppKit
import SwiftUI
import LumaShellCore

struct WidgetLayerView: View {
    @EnvironmentObject private var controller: ShellController

    private var theme: ShellTheme { controller.theme }

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            if controller.enabledWidgets.contains(.clock) {
                ShellClockWidget()
            }

            if controller.enabledWidgets.contains(.system) {
                SystemStatusWidget()
            }

            if controller.enabledWidgets.contains(.memory) {
                MemoryWidget()
            }

            if controller.enabledWidgets.contains(.quickLaunch) {
                QuickLaunchWidget()
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: theme.layout == .classicMac ? .topLeading : .topTrailing)
        .padding(.top, theme.layout == .classicMac ? theme.panelHeight + 18 : 18)
        .padding(.horizontal, 18)
        .padding(.bottom, theme.layout == .classicMac ? 18 : theme.panelHeight + 18)
        .allowsHitTesting(true)
    }
}

private struct WidgetSurface<Content: View>: View {
    @EnvironmentObject private var controller: ShellController
    let title: String
    @ViewBuilder let content: () -> Content

    private var theme: ShellTheme { controller.theme }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(
                        theme.preferredMonospacedUI
                            ? .system(size: 9, weight: .black, design: .monospaced)
                            : .system(size: 10, weight: .bold)
                    )
                    .tracking(theme.id == .cyberpunk ? 1.2 : 0)
                Spacer()
            }
            .foregroundStyle(Color(hex: theme.id == .cyberpunk ? theme.colors.accent : theme.colors.text))

            content()
        }
        .padding(10)
        .frame(width: theme.id == .cyberpunk ? 220 : 190)
        .background(Color(hex: theme.colors.panel).opacity(theme.id == .cyberpunk ? 0.90 : 0.94))
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(Color(hex: theme.colors.border).opacity(0.9), lineWidth: theme.id == .cyberpunk ? 1.5 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius))
        .shadow(color: .black.opacity(theme.id == .cyberpunk ? 0.28 : 0.15), radius: 8, y: 4)
    }
}

private struct ShellClockWidget: View {
    @EnvironmentObject private var controller: ShellController
    private var theme: ShellTheme { controller.theme }

    var body: some View {
        WidgetSurface(title: theme.id == .cyberpunk ? "CHRONO // LOCAL" : "Clock") {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.date.formatted(date: .omitted, time: .shortened))
                        .font(
                            theme.preferredMonospacedUI
                                ? .system(size: 26, weight: .black, design: .monospaced)
                                : .system(size: 24, weight: .semibold)
                        )
                    Text(context.date.formatted(date: .long, time: .omitted))
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: theme.colors.mutedText))
                }
                .foregroundStyle(Color(hex: theme.colors.text))
            }
        }
    }
}

private struct SystemStatusWidget: View {
    @EnvironmentObject private var controller: ShellController
    private var theme: ShellTheme { controller.theme }

    var body: some View {
        WidgetSurface(title: theme.id == .cyberpunk ? "SYSTEM // STATUS" : "System") {
            VStack(spacing: 6) {
                StatRow(label: "CPU", value: "\(ProcessInfo.processInfo.processorCount) cores")
                StatRow(label: "RAM", value: ByteCountFormatter.string(fromByteCount: Int64(ProcessInfo.processInfo.physicalMemory), countStyle: .memory))
                StatRow(label: "UP", value: formattedUptime)
                StatRow(label: "THERMAL", value: thermalLabel)
            }
        }
    }

    private var formattedUptime: String {
        let seconds = Int(ProcessInfo.processInfo.systemUptime)
        let hours = seconds / 3600
        let days = hours / 24
        if days > 0 { return "\(days)d \(hours % 24)h" }
        return "\(hours)h \((seconds % 3600) / 60)m"
    }

    private var thermalLabel: String {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return "nominal"
        case .fair: return "fair"
        case .serious: return "serious"
        case .critical: return "critical"
        @unknown default: return "unknown"
        }
    }
}

private struct MemoryWidget: View {
    @EnvironmentObject private var controller: ShellController
    private var theme: ShellTheme { controller.theme }

    var body: some View {
        WidgetSurface(title: "Memory") {
            VStack(alignment: .leading, spacing: 5) {
                Text(ByteCountFormatter.string(fromByteCount: Int64(ProcessInfo.processInfo.physicalMemory), countStyle: .memory))
                    .font(.system(size: 19, weight: .bold))
                Text("\(controller.runningApps.count) foreground applications")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: theme.colors.mutedText))
            }
            .foregroundStyle(Color(hex: theme.colors.text))
        }
    }
}

private struct QuickLaunchWidget: View {
    @EnvironmentObject private var controller: ShellController
    private var theme: ShellTheme { controller.theme }

    var body: some View {
        WidgetSurface(title: theme.layout == .classicMac ? "Control Strip" : "Quick Launch") {
            HStack(spacing: 8) {
                ForEach(controller.installedApps.prefix(5)) { app in
                    Button {
                        controller.launch(app)
                    } label: {
                        AppIconView(url: app.url, size: 28)
                    }
                    .buttonStyle(.plain)
                    .help(app.name)
                }
            }
        }
    }
}

private struct StatRow: View {
    @EnvironmentObject private var controller: ShellController
    let label: String
    let value: String

    private var theme: ShellTheme { controller.theme }

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: theme.preferredMonospacedUI ? .monospaced : .default))
                .foregroundStyle(Color(hex: theme.colors.mutedText))
            Spacer()
            Text(value)
                .font(.system(size: 10, weight: .semibold, design: theme.preferredMonospacedUI ? .monospaced : .default))
                .foregroundStyle(Color(hex: theme.colors.text))
        }
    }
}
