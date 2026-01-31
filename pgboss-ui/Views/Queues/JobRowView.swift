//
//  JobRowView.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-29.
//

import SwiftUI

struct JobRowView: View {
    let job: Job


    var body: some View {
        HStack(spacing: DesignTokens.Spacing.large) {
            // ID (truncated)
            Text(job.id.uuidString.prefix(8))
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: DesignTokens.RowWidth.jobId, alignment: .leading)

            // State badge
            StateBadge(state: job.state)
                .frame(width: DesignTokens.RowWidth.state, alignment: .leading)

            // Priority
            Text("\(job.priority)")
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: DesignTokens.RowWidth.number, alignment: .center)

            // Retry info
            if job.retryLimit > 0 {
                Text("\(job.retryCount)/\(job.retryLimit)")
                    .font(.callout)
                    .foregroundStyle(job.retryCount > 0 ? DesignTokens.Colors.warning : .secondary)
                    .frame(width: DesignTokens.RowWidth.number, alignment: .center)
            } else {
                Text("—")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(width: DesignTokens.RowWidth.number, alignment: .center)
            }

            // Created date
            Text(DesignTokens.DateFormat.shortDateTime.string(from: job.createdOn))
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: DesignTokens.RowWidth.date, alignment: .leading)

            // Completed date
            if let completedOn = job.completedOn {
                Text(DesignTokens.DateFormat.shortDateTime.string(from: completedOn))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(width: DesignTokens.RowWidth.date, alignment: .leading)
            } else {
                Text("—")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(width: DesignTokens.RowWidth.date, alignment: .leading)
            }

            Spacer()
        }
        .padding(.vertical, DesignTokens.Spacing.xSmall)
        .contentShape(Rectangle())
    }
}

#Preview {
    VStack(spacing: 0) {
        JobRowView(job: Job(
            id: UUID(),
            name: "send-email",
            state: .completed,
            priority: 0,
            data: "{}",
            createdOn: Date().addingTimeInterval(-3600),
            startedOn: Date().addingTimeInterval(-3500),
            completedOn: Date().addingTimeInterval(-3400),
            retryCount: 0,
            retryLimit: 3,
            output: nil
        ))

        Divider()

        JobRowView(job: Job(
            id: UUID(),
            name: "send-email",
            state: .failed,
            priority: 1,
            data: "{}",
            createdOn: Date().addingTimeInterval(-7200),
            startedOn: Date().addingTimeInterval(-7100),
            completedOn: nil,
            retryCount: 2,
            retryLimit: 3,
            output: nil
        ))

        Divider()

        JobRowView(job: Job(
            id: UUID(),
            name: "send-email",
            state: .active,
            priority: 5,
            data: "{}",
            createdOn: Date(),
            startedOn: Date(),
            completedOn: nil,
            retryCount: 0,
            retryLimit: 0,
            output: nil
        ))
    }
    .padding()
}
