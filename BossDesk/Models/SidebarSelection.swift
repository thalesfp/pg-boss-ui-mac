import Foundation

/// Discriminated union representing sidebar selection in the Queues view.
/// Supports selecting either a queue or a schedule for display in the detail pane.
enum SidebarSelection: Hashable, Identifiable {
    case queue(String)
    case schedule(String)

    var id: String {
        switch self {
        case .queue(let id):
            return "queue-\(id)"
        case .schedule(let name):
            return "schedule-\(name)"
        }
    }
}
