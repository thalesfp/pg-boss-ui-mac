//
//  JobMetadataView.swift
//  BossDesk
//
//  Created by thales on 2026-01-29.
//

import SwiftUI

struct JobMetadataView: View {
    let priority: Int
    let retryCount: Int
    let retryLimit: Int
    var singletonKey: String?
    var singletonOn: Date?
    var expireIn: TimeInterval?
    var keepUntil: Date?
    var startAfter: Date?
    var retryDelay: TimeInterval?
    var retryBackoff: Bool?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            SectionHeader("METADATA")

            Grid(alignment: .leading, horizontalSpacing: DesignTokens.Spacing.xLarge, verticalSpacing: DesignTokens.Spacing.small) {
                GridRow {
                    Text("Priority")
                        .foregroundStyle(.secondary)
                        .help("Higher values = higher priority. Jobs are processed in priority order within a queue.")
                    Text("\(priority)")
                }

                GridRow {
                    Text("Retries")
                        .foregroundStyle(.secondary)
                        .help("Number of retry attempts used / maximum allowed. Job moves to 'failed' when limit reached.")
                    Text("\(retryCount) / \(retryLimit)")
                }
            }
            .font(.callout)

            Divider()
                .padding(.vertical, DesignTokens.Spacing.small)

            SectionHeader("JOB SETTINGS")

            Grid(alignment: .leading, horizontalSpacing: DesignTokens.Spacing.xLarge, verticalSpacing: DesignTokens.Spacing.small) {
                GridRow {
                    Text("Singleton Key")
                        .foregroundStyle(.secondary)
                        .help("Ensures only one job with this key exists in pending/active states. Used for deduplication.")
                    if let singletonKey = singletonKey {
                        Text(singletonKey)
                            .fontDesign(.monospaced)
                    } else {
                        Text("-")
                            .foregroundStyle(.tertiary)
                    }
                }

                GridRow {
                    Text("Singleton On")
                        .foregroundStyle(.secondary)
                        .help("Time-based deduplication slot. Only one job per time slot (e.g., one per hour).")
                    if let singletonOn = singletonOn {
                        Text(singletonOn.formatted(date: .abbreviated, time: .standard))
                    } else {
                        Text("-")
                            .foregroundStyle(.tertiary)
                    }
                }

                GridRow {
                    Text("Expire In")
                        .foregroundStyle(.secondary)
                        .help("How long the job can run before timing out. If not completed in time, it's marked expired and can be retried.")
                    if let expireIn = expireIn {
                        Text(formatDuration(seconds: Int(expireIn)))
                    } else {
                        Text("-")
                            .foregroundStyle(.tertiary)
                    }
                }

                GridRow {
                    Text("Keep Until")
                        .foregroundStyle(.secondary)
                        .help("When this job record can be deleted. After this time, pg-boss maintenance will clean it up.")
                    if let keepUntil = keepUntil {
                        Text(keepUntil.formatted(date: .abbreviated, time: .standard))
                    } else {
                        Text("-")
                            .foregroundStyle(.tertiary)
                    }
                }

                GridRow {
                    Text("Start After")
                        .foregroundStyle(.secondary)
                        .help("When the job becomes eligible to run. Used for delayed or scheduled jobs.")
                    if let startAfter = startAfter {
                        Text(startAfter.formatted(date: .abbreviated, time: .standard))
                    } else {
                        Text("-")
                            .foregroundStyle(.tertiary)
                    }
                }

                GridRow {
                    Text("Retry Delay")
                        .foregroundStyle(.secondary)
                        .help("Base delay between retry attempts. Combined with backoff setting for exponential delays.")
                    if let retryDelay = retryDelay {
                        Text(formatDuration(seconds: Int(retryDelay)))
                    } else {
                        Text("-")
                            .foregroundStyle(.tertiary)
                    }
                }

                GridRow {
                    Text("Retry Backoff")
                        .foregroundStyle(.secondary)
                        .help("When enabled, retry delays increase exponentially (e.g., 1s, 2s, 4s, 8s...).")
                    if let retryBackoff = retryBackoff {
                        Text(retryBackoff ? "Enabled" : "Disabled")
                    } else {
                        Text("-")
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .font(.callout)
        }
    }

    private func formatDuration(seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds) seconds"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            let days = seconds / 86400
            return "\(days) day\(days == 1 ? "" : "s")"
        }
    }
}

#Preview("No Settings") {
    JobMetadataView(priority: 5, retryCount: 1, retryLimit: 3)
        .padding()
}

#Preview("All Settings") {
    JobMetadataView(
        priority: 5,
        retryCount: 1,
        retryLimit: 3,
        singletonKey: "user-123-daily-report",
        singletonOn: Date(),
        expireIn: 3600,
        keepUntil: Date().addingTimeInterval(86400 * 7),
        startAfter: Date().addingTimeInterval(300),
        retryDelay: 30,
        retryBackoff: true
    )
    .padding()
}

#Preview("Partial Settings") {
    JobMetadataView(
        priority: 10,
        retryCount: 2,
        retryLimit: 5,
        singletonKey: "payment-order-123",
        expireIn: 300,
        retryDelay: 60,
        retryBackoff: true
    )
    .padding()
}
