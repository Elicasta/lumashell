import AppKit
import SwiftUI
import LumaShellCore

struct FileBrowserView: View {
    @EnvironmentObject private var controller: ShellController
    @StateObject private var model: FileBrowserModel

    init(initialURL: URL) {
        _model = StateObject(wrappedValue: FileBrowserModel(initialURL: initialURL))
    }

    private var theme: ShellTheme { controller.theme }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Button { model.goBack() } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(ShellButtonStyle(theme: theme, compact: true))
                .disabled(!model.canGoBack)

                Button { model.goUp() } label: {
                    Image(systemName: "arrow.up")
                }
                .buttonStyle(ShellButtonStyle(theme: theme, compact: true))

                Text(model.currentURL.path)
                    .font(.system(size: 11, design: theme.preferredMonospacedUI ? .monospaced : .default))
                    .foregroundStyle(Color(hex: theme.colors.text))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
                    .background(Color(hex: theme.colors.panel))
                    .overlay(Rectangle().stroke(Color(hex: theme.colors.border).opacity(0.65), lineWidth: 1))
            }
            .padding(8)
            .background(Color(hex: theme.colors.panelAlt))

            Divider().overlay(Color(hex: theme.colors.border))

            if model.isLoading {
                Spacer()
                ProgressView().controlSize(.small)
                Spacer()
            } else if let message = model.errorMessage {
                Spacer()
                Text(message)
                    .foregroundStyle(Color(hex: theme.colors.text))
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 12) {
                        ForEach(model.items) { item in
                            Button {
                                model.open(item)
                            } label: {
                                VStack(spacing: 6) {
                                    FileSystemIcon(url: item.url, size: 42)
                                    Text(item.name)
                                        .font(theme.preferredMonospacedUI ? .system(size: 10, design: .monospaced) : .system(size: 10))
                                        .foregroundStyle(Color(hex: theme.colors.text))
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(width: 92, height: 82)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(14)
                }
                .background(Color(hex: theme.colors.panelAlt).opacity(0.96))
            }

            HStack {
                Text("\(model.items.count) items")
                Spacer()
                Text(model.currentURL.lastPathComponent.isEmpty ? "/" : model.currentURL.lastPathComponent)
            }
            .font(.system(size: 10))
            .foregroundStyle(Color(hex: theme.colors.mutedText))
            .padding(.horizontal, 9)
            .frame(height: 24)
            .background(Color(hex: theme.colors.panel))
        }
    }
}

private struct FileSystemIcon: View {
    let url: URL
    let size: CGFloat

    var body: some View {
        Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }
}

@MainActor
private final class FileBrowserModel: ObservableObject {
    @Published var currentURL: URL
    @Published var items: [FileBrowserItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var history: [URL] = []

    var canGoBack: Bool { !history.isEmpty }

    init(initialURL: URL) {
        currentURL = initialURL
        load()
    }

    func open(_ item: FileBrowserItem) {
        if item.isDirectory {
            history.append(currentURL)
            currentURL = item.url
            load()
        } else {
            NSWorkspace.shared.open(item.url)
        }
    }

    func goBack() {
        guard let previous = history.popLast() else { return }
        currentURL = previous
        load()
    }

    func goUp() {
        let parent = currentURL.deletingLastPathComponent()
        guard parent.path != currentURL.path else { return }
        history.append(currentURL)
        currentURL = parent
        load()
    }

    private func load() {
        let url = currentURL
        isLoading = true
        errorMessage = nil

        Task {
            let result = await Task.detached(priority: .utility) {
                do {
                    let keys: Set<URLResourceKey> = [.isDirectoryKey, .isHiddenKey, .localizedNameKey]
                    let urls = try FileManager.default.contentsOfDirectory(
                        at: url,
                        includingPropertiesForKeys: Array(keys),
                        options: [.skipsHiddenFiles]
                    )

                    let items = urls.compactMap { child -> FileBrowserItem? in
                        let values = try? child.resourceValues(forKeys: keys)
                        if values?.isHidden == true { return nil }
                        return FileBrowserItem(
                            name: values?.localizedName ?? child.lastPathComponent,
                            url: child,
                            isDirectory: values?.isDirectory ?? false
                        )
                    }
                    .sorted {
                        if $0.isDirectory != $1.isDirectory {
                            return $0.isDirectory && !$1.isDirectory
                        }
                        return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                    }
                    return Result<[FileBrowserItem], Error>.success(items)
                } catch {
                    return Result<[FileBrowserItem], Error>.failure(error)
                }
            }.value

            switch result {
            case .success(let items):
                self.items = items
            case .failure(let error):
                self.items = []
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }
}

private struct FileBrowserItem: Identifiable, Sendable {
    let name: String
    let url: URL
    let isDirectory: Bool
    var id: String { url.path }
}
