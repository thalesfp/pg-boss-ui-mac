//
//  QueueStatsCardsView.swift
//  BossDesk
//
//  Created by thales on 2026-01-29.
//

import SwiftUI

struct QueueStatsCardsView: View {
    let stats: QueueStats
    var config: QueueConfig?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            HStack(spacing: DesignTokens.Spacing.large) {
                StatCard(
                    title: "Created",
                    count: stats.created,
                    icon: JobState.created.icon,
                    color: JobState.created.color
                )

                StatCard(
                    title: "Retry",
                    count: stats.retry,
                    icon: JobState.retry.icon,
                    color: JobState.retry.color
                )

                StatCard(
                    title: "Active",
                    count: stats.active,
                    icon: JobState.active.icon,
                    color: JobState.active.color
                )

                StatCard(
                    title: "Completed",
                    count: stats.completed,
                    icon: JobState.completed.icon,
                    color: JobState.completed.color
                )

                StatCard(
                    title: "Failed",
                    count: stats.failed,
                    icon: JobState.failed.icon,
                    color: JobState.failed.color
                )

                StatCard(
                    title: "Cancelled",
                    count: stats.cancelled,
                    icon: JobState.cancelled.icon,
                    color: JobState.cancelled.color
                )
            }

            if let config = config {
                QueueConfigInfoView(config: config)
            }
        }
    }
}

struct QueueConfigInfoView: View {
    let config: QueueConfig

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.large) {
            if let retention = config.formattedRetention() {
                configItem(icon: "clock.badge.checkmark", label: "Retention", value: retention)
            }

            if let deletion = config.formattedDeletion() {
                configItem(icon: "trash.circle", label: "Delete after", value: deletion)
            }

            if let expire = config.formattedExpire() {
                configItem(icon: "hourglass", label: "Expire", value: expire)
            }

            if let retryLimit = config.retryLimit {
                configItem(icon: "arrow.counterclockwise", label: "Retry limit", value: "\(retryLimit)")
            }

            if let policy = config.policy {
                configItem(icon: "gearshape", label: "Policy", value: policy)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private func configItem(icon: String, label: String, value: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.small) {
            Image(systemName: icon)
            Text("\(label):")
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
    }
}

struct StatCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .imageScale(.large)
                Text(title)
                    .foregroundStyle(.secondary)
            }
            .font(.callout)

            Text("\(count)")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundStyle(count > 0 ? color : .secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
    }
}

#Preview("Without Config") {
    QueueStatsCardsView(stats: QueueStats(
        created: 5,
        retry: 2,
        active: 10,
        completed: 150,
        failed: 3,
        cancelled: 1
    ))
    .padding()
}

#Preview("With Config") {
    QueueStatsCardsView(
        stats: QueueStats(
            created: 5,
            retry: 2,
            active: 10,
            completed: 150,
            failed: 3,
            cancelled: 1
        ),
        config: QueueConfig(
            retentionSeconds: 86400 * 14,  // 14 days
            deletionSeconds: 86400 * 7,     // 7 days
            expireSeconds: 900,             // 15 minutes
            retryLimit: 3,
            policy: "standard"
        )
    )
    .padding()
}
