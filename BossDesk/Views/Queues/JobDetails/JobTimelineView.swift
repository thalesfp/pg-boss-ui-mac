//
//  JobTimelineView.swift
//  BossDesk
//
//  Created by thales on 2026-01-29.
//

import SwiftUI

struct JobTimelineView: View {
    let createdOn: Date
    let startedOn: Date?
    let completedOn: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            SectionHeader("TIMELINE")

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                TimelineRow(label: "Created", date: createdOn, color: .accentColor)

                if let startedOn {
                    TimelineRow(label: "Started", date: startedOn, color: .secondary)
                }

                if let completedOn {
                    TimelineRow(label: "Completed", date: completedOn, color: .green)
                }
            }
        }
    }
}

struct TimelineRow: View {
    let label: String
    let date: Date
    let color: Color

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.medium) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .frame(width: 80, alignment: .leading)

            Text(DesignTokens.DateFormat.shortDateTime.string(from: date))
                .foregroundStyle(.secondary)
        }
        .font(.callout)
    }
}

#Preview {
    JobTimelineView(
        createdOn: Date().addingTimeInterval(-3600),
        startedOn: Date().addingTimeInterval(-3500),
        completedOn: Date().addingTimeInterval(-3400)
    )
    .padding()
}
