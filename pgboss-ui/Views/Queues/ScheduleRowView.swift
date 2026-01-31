//
//  ScheduleRowView.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-30.
//

import SwiftUI

struct ScheduleRowView: View {
    let schedule: Schedule

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            Text(schedule.name)
                .font(.headline)
                .lineLimit(1)

            HStack(spacing: DesignTokens.Spacing.xSmall) {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(schedule.cron)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let timezone = schedule.timezone {
                    Text("(\(timezone))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, DesignTokens.Spacing.xSmall)
        .contentShape(Rectangle())
    }
}

#Preview {
    List {
        ScheduleRowView(
            schedule: Schedule(
                name: "daily-report",
                cron: "0 9 * * *",
                timezone: "America/New_York",
                data: nil,
                options: nil,
                createdOn: Date(),
                updatedOn: Date()
            )
        )

        ScheduleRowView(
            schedule: Schedule(
                name: "cleanup-old-jobs",
                cron: "0 0 * * *",
                timezone: nil,
                data: nil,
                options: nil,
                createdOn: Date(),
                updatedOn: Date()
            )
        )

        ScheduleRowView(
            schedule: Schedule(
                name: "sync-every-5-minutes",
                cron: "*/5 * * * *",
                timezone: "UTC",
                data: nil,
                options: nil,
                createdOn: Date(),
                updatedOn: Date()
            )
        )
    }
    .frame(width: 280)
}
