import Foundation

public enum WidgetKind: String, CaseIterable, Codable, Sendable, Identifiable, Hashable {
    case clock
    case system
    case memory
    case quickLaunch
    case assistant

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .clock: return "Clock"
        case .system: return "System"
        case .memory: return "Memory"
        case .quickLaunch: return "Quick Launch"
        case .assistant: return "Luma AI"
        }
    }
}
