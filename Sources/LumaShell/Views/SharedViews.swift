import AppKit
import SwiftUI
import LumaShellCore

extension Color {
    init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var value: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&value)

        let red = Double((value >> 16) & 0xFF) / 255.0
        let green = Double((value >> 8) & 0xFF) / 255.0
        let blue = Double(value & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }
}

struct AppIconView: View {
    let url: URL?
    var size: CGFloat = 24

    var body: some View {
        Group {
            if let url {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "app.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
        .frame(width: size, height: size)
    }
}

struct ShellButtonStyle: ButtonStyle {
    let theme: ShellTheme
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(theme.preferredMonospacedUI ? .system(size: compact ? 11 : 13, weight: .semibold, design: .monospaced) : .system(size: compact ? 11 : 13, weight: .semibold))
            .foregroundStyle(Color(hex: theme.colors.text))
            .padding(.horizontal, compact ? 8 : 11)
            .padding(.vertical, compact ? 5 : 7)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .fill(Color(hex: configuration.isPressed ? theme.colors.selection : theme.colors.panelAlt))
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(Color(hex: theme.colors.border), lineWidth: 1)
            )
    }
}

struct FloatingShellWindow<Content: View>: View {
    @EnvironmentObject private var controller: ShellController
    let title: String
    let preferredSize: CGSize
    let onClose: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var restingOffset: CGSize = .zero
    @GestureState private var dragOffset: CGSize = .zero

    var theme: ShellTheme { controller.theme }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text(title)
                    .font(theme.preferredMonospacedUI ? .system(size: 12, weight: .bold, design: .monospaced) : .system(size: 12, weight: .bold))
                    .foregroundStyle(Color(hex: theme.colors.text))
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .black))
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color(hex: theme.colors.text))
                .background(Color(hex: theme.colors.panelAlt))
                .overlay(Rectangle().stroke(Color(hex: theme.colors.border), lineWidth: 1))
            }
            .padding(.horizontal, 8)
            .frame(height: 30)
            .background(Color(hex: theme.colors.panel))
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        restingOffset.width += value.translation.width
                        restingOffset.height += value.translation.height
                    }
            )

            content()
        }
        .frame(width: preferredSize.width, height: preferredSize.height)
        .background(Color(hex: theme.colors.panelAlt))
        .overlay(Rectangle().stroke(Color(hex: theme.colors.border), lineWidth: theme.id == .cyberpunk ? 2 : 1))
        .shadow(color: Color(hex: theme.colors.shadow).opacity(0.45), radius: theme.id == .cyberpunk ? 18 : 7, x: 0, y: 8)
        .offset(x: restingOffset.width + dragOffset.width, y: restingOffset.height + dragOffset.height)
    }
}

struct ClockText: View {
    let theme: ShellTheme

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            Text(context.date.formatted(date: .omitted, time: .shortened))
                .font(theme.preferredMonospacedUI ? .system(size: 11, weight: .medium, design: .monospaced) : .system(size: 11, weight: .medium))
                .foregroundStyle(Color(hex: theme.colors.text))
        }
    }
}
