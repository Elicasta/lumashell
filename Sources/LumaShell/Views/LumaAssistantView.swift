import SwiftUI
import LumaShellCore

struct LumaAssistantView: View {
    @EnvironmentObject private var controller: ShellController

    private var theme: ShellTheme { controller.theme }

    var body: some View {
        if controller.enabledWidgets.contains(.assistant) {
            VStack {
                Spacer()
                HStack {
                    Spacer()

                    if controller.isAssistantOpen {
                        assistantPanel
                    } else {
                        assistantButton
                    }
                }
            }
            .padding(.trailing, 18)
            .padding(.bottom, theme.layout == .classicMac ? 18 : theme.panelHeight + 16)
            .zIndex(40)
        }
    }

    private var assistantButton: some View {
        Button {
            controller.isAssistantOpen = true
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "paperclip")
                    .font(.system(size: 18, weight: .black))
                Text(theme.id == .cyberpunk ? "LUMA" : "AI")
                    .font(theme.preferredMonospacedUI ? .system(size: 11, weight: .black, design: .monospaced) : .system(size: 11, weight: .bold))
            }
            .foregroundStyle(Color(hex: theme.colors.text))
            .padding(.horizontal, 13)
            .frame(height: 42)
            .background(Color(hex: theme.colors.panel))
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(Color(hex: theme.colors.border), lineWidth: theme.id == .cyberpunk ? 1.5 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius))
        }
        .buttonStyle(.plain)
        .help("Open Luma AI")
    }

    private var assistantPanel: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "paperclip")
                VStack(alignment: .leading, spacing: 1) {
                    Text(theme.id == .cyberpunk ? "LUMA // ASSIST" : "Luma AI")
                        .font(theme.preferredMonospacedUI ? .system(size: 11, weight: .black, design: .monospaced) : .system(size: 12, weight: .bold))
                    Text(controller.isAIConfigured ? "GPT-5.6 Luna • tools online" : "local shell • AI key not set")
                        .font(.system(size: 9))
                        .foregroundStyle(Color(hex: theme.colors.mutedText))
                }
                Spacer()
                Button {
                    controller.isAssistantOpen = false
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(Color(hex: theme.colors.text))
            .padding(10)
            .background(Color(hex: theme.colors.panel))

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 9) {
                        ForEach(controller.assistantMessages) { message in
                            messageBubble(message)
                                .id(message.id)
                        }

                        if controller.assistantBusy {
                            HStack(spacing: 6) {
                                ProgressView().controlSize(.small)
                                Text("thinking")
                            }
                            .font(.system(size: 10))
                            .foregroundStyle(Color(hex: theme.colors.mutedText))
                        }
                    }
                    .padding(10)
                }
                .onChange(of: controller.assistantMessages.count) { _ in
                    if let last = controller.assistantMessages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .frame(height: 240)
            .background(Color(hex: theme.colors.panelAlt).opacity(0.97))

            HStack(spacing: 8) {
                TextField("Ask Luma…", text: $controller.assistantDraft)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, design: theme.preferredMonospacedUI ? .monospaced : .default))
                    .foregroundStyle(Color(hex: theme.colors.text))
                    .padding(9)
                    .background(Color(hex: theme.colors.panel))
                    .overlay(Rectangle().stroke(Color(hex: theme.colors.border).opacity(0.65), lineWidth: 1))
                    .onSubmit {
                        controller.sendAssistantMessage()
                    }

                Button {
                    controller.sendAssistantMessage()
                } label: {
                    Image(systemName: "arrow.up")
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(ShellButtonStyle(theme: theme, compact: true))
                .disabled(controller.assistantBusy || controller.assistantDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(9)
            .background(Color(hex: theme.colors.panel))
        }
        .frame(width: 360)
        .background(Color(hex: theme.colors.panel))
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(Color(hex: theme.colors.border), lineWidth: theme.id == .cyberpunk ? 1.5 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius))
        .shadow(color: .black.opacity(0.38), radius: 18, y: 8)
    }

    @ViewBuilder
    private func messageBubble(_ message: AssistantMessage) -> some View {
        HStack {
            if message.role == .assistant {
                bubble(message)
                Spacer(minLength: 35)
            } else {
                Spacer(minLength: 35)
                bubble(message)
            }
        }
    }

    private func bubble(_ message: AssistantMessage) -> some View {
        Text(message.text)
            .font(.system(size: 11, design: theme.preferredMonospacedUI ? .monospaced : .default))
            .foregroundStyle(Color(hex: theme.colors.text))
            .padding(8)
            .background(
                Color(hex: message.role == .user ? theme.colors.selection : theme.colors.panel)
                    .opacity(message.role == .user ? 0.88 : 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: max(theme.cornerRadius, 3))
                    .stroke(Color(hex: theme.colors.border).opacity(0.45), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: max(theme.cornerRadius, 3)))
    }
}
