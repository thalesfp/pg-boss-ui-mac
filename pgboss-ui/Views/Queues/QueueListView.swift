//
//  QueueListView.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-29.
//

import SwiftUI

struct QueueListView: View {
    let queues: [Queue]
    let schedules: [Schedule]
    @Binding var selectedQueueId: String?
    let isLoading: Bool

    @State private var isQueuesExpanded = true
    @State private var isSchedulesExpanded = true

    var body: some View {
        Group {
            if isLoading && queues.isEmpty {
                VStack(spacing: DesignTokens.Spacing.medium) {
                    ProgressView()
                        .controlSize(.regular)
                    Text("Loading queues...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $selectedQueueId) {
                    Section(isExpanded: $isQueuesExpanded) {
                        if queues.isEmpty {
                            ContentUnavailableView {
                                Label("No Queues", systemImage: "tray")
                            } description: {
                                Text("No pg-boss queues found in this database.")
                            }
                        } else {
                            ForEach(queues) { queue in
                                QueueRowView(queue: queue, isSelected: selectedQueueId == queue.id)
                                    .tag(queue.id)
                            }
                        }
                    } header: {
                        Text("Queues")
                            .font(.system(size: 11))
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                    }

                    Section(isExpanded: $isSchedulesExpanded) {
                        if schedules.isEmpty {
                            ContentUnavailableView {
                                Label("No Schedules", systemImage: "calendar.badge.clock")
                            } description: {
                                Text("No pg-boss schedules found in this database.")
                            }
                        } else {
                            ForEach(schedules) { schedule in
                                ScheduleRowView(schedule: schedule)
                            }
                        }
                    } header: {
                        Text("Schedules")
                            .font(.system(size: 11))
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                    }
                }
                .listStyle(.sidebar)
            }
        }
    }
}

#Preview("With Queues") {
    struct PreviewWrapper: View {
        @State private var selectedQueueId: String? = nil

        var body: some View {
            QueueListView(
                queues: MockData.queues,
                schedules: MockData.schedules,
                selectedQueueId: $selectedQueueId,
                isLoading: false
            )
            .frame(width: 280, height: 500)
        }
    }

    return PreviewWrapper()
}

#Preview("Empty") {
    struct PreviewWrapper: View {
        @State private var selectedQueueId: String? = nil

        var body: some View {
            QueueListView(
                queues: [],
                schedules: [],
                selectedQueueId: $selectedQueueId,
                isLoading: false
            )
            .frame(width: 280, height: 400)
        }
    }

    return PreviewWrapper()
}

#Preview("Loading") {
    struct PreviewWrapper: View {
        @State private var selectedQueueId: String? = nil

        var body: some View {
            QueueListView(
                queues: [],
                schedules: [],
                selectedQueueId: $selectedQueueId,
                isLoading: true
            )
            .frame(width: 280, height: 400)
        }
    }

    return PreviewWrapper()
}
