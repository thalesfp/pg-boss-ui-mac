//
//  QueueRowView.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-29.
//

import SwiftUI

struct QueueRowView: View {
    let queue: Queue

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            HStack {
                Text(queue.name)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Text("\(queue.stats.total)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: DesignTokens.Spacing.xSmall) {
                if queue.stats.created > 0 {
                    CountBadge(count: queue.stats.created, color: JobState.created.color, label: "")
                }
                if queue.stats.retry > 0 {
                    CountBadge(count: queue.stats.retry, color: JobState.retry.color, label: "")
                }
                if queue.stats.active > 0 {
                    CountBadge(count: queue.stats.active, color: JobState.active.color, label: "")
                }
                if queue.stats.completed > 0 {
                    CountBadge(count: queue.stats.completed, color: JobState.completed.color, label: "")
                }
                if queue.stats.failed > 0 {
                    CountBadge(count: queue.stats.failed, color: JobState.failed.color, label: "")
                }
                if queue.stats.cancelled > 0 {
                    CountBadge(count: queue.stats.cancelled, color: JobState.cancelled.color, label: "")
                }

                Spacer()
            }
        }
        .padding(.vertical, DesignTokens.Spacing.xSmall)
        .contentShape(Rectangle())
    }
}

#Preview {
    List {
        QueueRowView(
            queue: Queue(
                id: "email-notifications",
                stats: QueueStats(created: 5, retry: 2, active: 10, completed: 150, failed: 3, cancelled: 1)
            )
        )

        QueueRowView(
            queue: Queue(
                id: "process-payments",
                stats: QueueStats(created: 0, retry: 0, active: 3, completed: 500, failed: 0, cancelled: 0)
            )
        )

        QueueRowView(
            queue: Queue(
                id: "sync-data",
                stats: QueueStats(created: 100, retry: 0, active: 0, completed: 0, failed: 0, cancelled: 0)
            )
        )
    }
    .frame(width: 280)
}
