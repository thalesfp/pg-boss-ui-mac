//
//  JobIdentityView.swift
//  BossDesk
//
//  Created by thales on 2026-01-29.
//

import SwiftUI

struct JobIdentityView: View {
    let job: Job

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            HStack(spacing: DesignTokens.Spacing.medium) {
                StateBadge(state: job.state)

                Text(job.name)
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            HStack {
                Text(job.id.uuidString)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(job.id.uuidString, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .help("Copy job ID to clipboard")
            }
        }
    }
}

#Preview {
    JobIdentityView(job: Job(
        id: UUID(),
        name: "send-email",
        state: .completed,
        priority: 5,
        data: "{}",
        createdOn: Date(),
        startedOn: Date(),
        completedOn: Date(),
        retryCount: 1,
        retryLimit: 3,
        output: nil
    ))
    .padding()
}
