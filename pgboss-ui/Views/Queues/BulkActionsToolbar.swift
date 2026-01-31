//
//  BulkActionsToolbar.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-30.
//

import SwiftUI

enum BulkAction: Equatable {
    // Queue-wide actions
    case retryAllFailed
    case cancelAllPending
    case purgeCompleted
    case purgeFailed
    // Selection-based actions
    case retrySelected(Set<UUID>)
    case cancelSelected(Set<UUID>)
    case deleteSelected(Set<UUID>)

    var title: String {
        switch self {
        case .retryAllFailed: return "Retry All Failed"
        case .cancelAllPending: return "Cancel All Pending"
        case .purgeCompleted: return "Purge Completed"
        case .purgeFailed: return "Purge Failed"
        case .retrySelected(let ids): return "Retry Selected (\(ids.count))"
        case .cancelSelected(let ids): return "Cancel Selected (\(ids.count))"
        case .deleteSelected(let ids): return "Delete Selected (\(ids.count))"
        }
    }

    var icon: String {
        switch self {
        case .retryAllFailed, .retrySelected: return "arrow.clockwise"
        case .cancelAllPending, .cancelSelected: return "xmark.circle"
        case .purgeCompleted, .purgeFailed, .deleteSelected: return "trash"
        }
    }

    var isDestructive: Bool {
        switch self {
        case .retryAllFailed, .cancelAllPending, .retrySelected, .cancelSelected: return false
        case .purgeCompleted, .purgeFailed, .deleteSelected: return true
        }
    }

    func confirmationTitle(queueName: String, count: Int) -> String {
        switch self {
        case .retryAllFailed:
            return "Retry \(count) failed job\(count == 1 ? "" : "s")?"
        case .cancelAllPending:
            return "Cancel \(count) pending job\(count == 1 ? "" : "s")?"
        case .purgeCompleted:
            return "Delete \(count) completed job\(count == 1 ? "" : "s")?"
        case .purgeFailed:
            return "Delete \(count) failed job\(count == 1 ? "" : "s")?"
        case .retrySelected(let ids):
            return "Retry \(ids.count) selected job\(ids.count == 1 ? "" : "s")?"
        case .cancelSelected(let ids):
            return "Cancel \(ids.count) selected job\(ids.count == 1 ? "" : "s")?"
        case .deleteSelected(let ids):
            return "Delete \(ids.count) selected job\(ids.count == 1 ? "" : "s")?"
        }
    }

    func confirmationMessage(queueName: String) -> String {
        switch self {
        case .retryAllFailed:
            return "This will reset all failed jobs in '\(queueName)' to retry state."
        case .cancelAllPending:
            return "This will cancel all pending jobs in '\(queueName)'."
        case .purgeCompleted:
            return "This will permanently delete all completed jobs from '\(queueName)'. This action cannot be undone."
        case .purgeFailed:
            return "This will permanently delete all failed jobs from '\(queueName)'. This action cannot be undone."
        case .retrySelected:
            return "This will reset the selected jobs to retry state."
        case .cancelSelected:
            return "This will cancel the selected jobs."
        case .deleteSelected:
            return "This will permanently delete the selected jobs. This action cannot be undone."
        }
    }

    func affectedCount(stats: QueueStats) -> Int {
        switch self {
        case .retryAllFailed: return stats.failed
        case .cancelAllPending: return stats.created + stats.retry
        case .purgeCompleted: return stats.completed
        case .purgeFailed: return stats.failed
        case .retrySelected(let ids), .cancelSelected(let ids), .deleteSelected(let ids):
            return ids.count
        }
    }
}

struct BulkActionsToolbar: View {
    let queue: Queue
    let selectedJobIds: Set<UUID>
    @Bindable var store: QueueStore

    @State private var pendingAction: BulkAction?
    @State private var showError = false

    private var hasSelection: Bool {
        !selectedJobIds.isEmpty
    }

    var body: some View {
        Menu {
            if hasSelection {
                // Selection-specific actions
                Button {
                    pendingAction = .retrySelected(selectedJobIds)
                } label: {
                    Label("Retry Selected (\(selectedJobIds.count))", systemImage: "arrow.clockwise")
                }

                Button {
                    pendingAction = .cancelSelected(selectedJobIds)
                } label: {
                    Label("Cancel Selected (\(selectedJobIds.count))", systemImage: "xmark.circle")
                }

                Button(role: .destructive) {
                    pendingAction = .deleteSelected(selectedJobIds)
                } label: {
                    Label("Delete Selected (\(selectedJobIds.count))", systemImage: "trash")
                }

                Divider()
            }

            // Queue-wide actions
            Button {
                pendingAction = .retryAllFailed
            } label: {
                Label("Retry All Failed", systemImage: "arrow.clockwise")
            }
            .disabled(queue.stats.failed == 0)

            Button {
                pendingAction = .cancelAllPending
            } label: {
                Label("Cancel All Pending", systemImage: "xmark.circle")
            }
            .disabled(queue.stats.created + queue.stats.retry == 0)

            Divider()

            Button(role: .destructive) {
                pendingAction = .purgeCompleted
            } label: {
                Label("Purge Completed", systemImage: "trash")
            }
            .disabled(queue.stats.completed == 0)

            Button(role: .destructive) {
                pendingAction = .purgeFailed
            } label: {
                Label("Purge Failed", systemImage: "trash")
            }
            .disabled(queue.stats.failed == 0)
        } label: {
            HStack(spacing: DesignTokens.Spacing.small) {
                if store.isMutatingJob {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "ellipsis.circle")
                }
                if hasSelection {
                    Text("Actions (\(selectedJobIds.count))")
                } else {
                    Text("Bulk Actions")
                }
            }
        }
        .disabled(store.isMutatingJob)
        .confirmationDialog(
            pendingAction?.confirmationTitle(
                queueName: queue.name,
                count: pendingAction?.affectedCount(stats: queue.stats) ?? 0
            ) ?? "",
            isPresented: Binding(
                get: { pendingAction != nil },
                set: { if !$0 { pendingAction = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let action = pendingAction {
                Button(action.title, role: action.isDestructive ? .destructive : nil) {
                    Task {
                        await performAction(action)
                    }
                }
                Button("Cancel", role: .cancel) {
                    pendingAction = nil
                }
            }
        } message: {
            if let action = pendingAction {
                Text(action.confirmationMessage(queueName: queue.name))
            }
        }
        .alert("Operation Failed", isPresented: $showError) {
            Button("OK") {
                store.clearMutationError()
            }
        } message: {
            Text(store.mutationError ?? "An unknown error occurred")
        }
    }

    private func performAction(_ action: BulkAction) async {
        pendingAction = nil

        switch action {
        case .retryAllFailed:
            _ = await store.retryAllFailed()
        case .cancelAllPending:
            _ = await store.cancelAllPending()
        case .purgeCompleted:
            _ = await store.purgeCompleted()
        case .purgeFailed:
            _ = await store.purgeFailed()
        case .retrySelected(let ids):
            _ = await store.retryJobs(ids: ids)
        case .cancelSelected(let ids):
            _ = await store.cancelJobs(ids: ids)
        case .deleteSelected(let ids):
            _ = await store.deleteJobs(ids: ids)
        }

        if store.mutationError != nil {
            showError = true
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var store = QueueStore()

        let queue = Queue(
            id: "email-notifications",
            stats: QueueStats(created: 5, retry: 2, active: 10, completed: 150, failed: 3, cancelled: 1)
        )

        var body: some View {
            VStack(spacing: 20) {
                BulkActionsToolbar(queue: queue, selectedJobIds: [], store: store)
                BulkActionsToolbar(queue: queue, selectedJobIds: [UUID(), UUID()], store: store)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
