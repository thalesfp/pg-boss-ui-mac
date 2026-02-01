//
//  QueueRowView.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-29.
//

import SwiftUI

struct QueueRowView: View {
    let queue: Queue
    var isSelected: Bool = false

    private var activeBadges: [(JobState, Int)] {
        [
            (.created, queue.stats.created),
            (.retry, queue.stats.retry),
            (.active, queue.stats.active),
            (.completed, queue.stats.completed),
            (.failed, queue.stats.failed),
            (.cancelled, queue.stats.cancelled)
        ].filter { $0.1 > 0 }
    }

    private var selectionIndicator: some View {
        Rectangle()
            .fill(DesignTokens.Selection.indicatorColor(isSelected: isSelected))
            .frame(width: DesignTokens.Sidebar.selectionIndicatorWidth)
            .cornerRadius(DesignTokens.Sidebar.selectionIndicatorCornerRadius)
    }

    private var badgeSection: some View {
        FlowLayout(spacing: DesignTokens.Sidebar.badgeSpacing) {
            ForEach(activeBadges, id: \.0) { state, count in
                CountBadge(count: count, color: state.color, label: "")
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            selectionIndicator

            VStack(alignment: .leading, spacing: DesignTokens.Sidebar.badgeRowSpacing) {
                // Queue name + total
                HStack(spacing: DesignTokens.Spacing.small) {
                    Text(queue.name)
                        .font(.system(size: DesignTokens.Sidebar.queueNameSize))
                        .fontWeight(DesignTokens.Typography.queueNameWeight)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer()

                    Text("\(queue.stats.total)")
                        .font(.system(size: DesignTokens.Sidebar.totalCountSize))
                        .fontWeight(DesignTokens.Typography.totalCountWeight)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }

                // Badges with flow layout
                if !activeBadges.isEmpty {
                    badgeSection
                }
            }
            .padding(.horizontal, DesignTokens.Sidebar.rowHorizontalPadding)
            .padding(.vertical, DesignTokens.Sidebar.rowVerticalPadding)
        }
        .background(DesignTokens.Selection.background(isSelected: isSelected))
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
