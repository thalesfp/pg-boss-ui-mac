//
//  ScheduleRowView.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-30.
//

import SwiftUI

struct ScheduleRowView: View {
    let schedule: Schedule
    var isSelected: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            Text(schedule.name)
                .font(.system(size: DesignTokens.Sidebar.scheduleNameSize))
                .fontWeight(DesignTokens.Typography.scheduleNameWeight)
                .foregroundStyle(.primary)
                .lineLimit(1)

            HStack(spacing: DesignTokens.Spacing.xSmall) {
                Image(systemName: "clock")
                    .font(.system(size: DesignTokens.Sidebar.scheduleMetaSize))
                    .foregroundStyle(.secondary)

                Text(schedule.cron)
                    .font(.system(size: DesignTokens.Sidebar.scheduleMetaSize))
                    .fontWeight(DesignTokens.Typography.metaTextWeight)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let timezone = schedule.timezone {
                    Text("·")
                        .foregroundStyle(.quaternary)

                    Text(timezone)
                        .font(.system(size: DesignTokens.Sidebar.scheduleMetaSize))
                        .fontWeight(DesignTokens.Typography.metaTextWeight)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, DesignTokens.Sidebar.rowHorizontalPadding)
        .padding(.vertical, DesignTokens.Sidebar.rowVerticalPadding)
        .background(DesignTokens.Selection.background(isSelected: isSelected))
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
