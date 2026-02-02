import SwiftUI

/// Displays cron expression details including pattern, human-readable description, timezone, and next run time
struct ScheduleCronView: View {
    let schedule: Schedule
    @State private var nextRunText: String = "Calculating..."

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            Text("Cron Expression")
                .font(.headline)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                // Cron pattern
                Text(schedule.cron)
                    .font(.system(.body, design: .monospaced))
                    .padding(DesignTokens.Spacing.small)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(DesignTokens.CornerRadius.small)

                // Human-readable description
                if let description = CronHelper.humanReadableDescription(schedule.cron) {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Timezone
                HStack(spacing: DesignTokens.Spacing.xSmall) {
                    Text("Timezone:")
                        .foregroundColor(.secondary)
                    Text(schedule.timezone ?? "UTC")
                        .font(.system(.body, design: .monospaced))
                }
                .font(.subheadline)

                // Next run time
                if !nextRunText.isEmpty && nextRunText != "Calculating..." {
                    HStack(spacing: DesignTokens.Spacing.xSmall) {
                        Text("Next run:")
                            .foregroundColor(.secondary)
                        Text(nextRunText)
                            .foregroundColor(DesignTokens.Colors.success)
                    }
                    .font(.subheadline)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.medium)
        .task(id: "\(schedule.id)|\(schedule.cron)|\(schedule.timezone ?? "")") {
            // Initial calculation
            nextRunText = calculateNextRun()

            // Periodic recalculation loop (every 60 seconds)
            // Ensures "Next run" always shows the next FUTURE occurrence
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))

                guard !Task.isCancelled else { break }
                nextRunText = calculateNextRun()
            }
        }
    }

    private func calculateNextRun() -> String {
        guard let nextRun = CronHelper.estimateNextRun(schedule.cron, timezone: schedule.timezone) else {
            return "Unable to calculate"
        }

        // Use RelativeDateTimeFormatter for static display (consistent with ScheduleTimestampsView)
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: nextRun, relativeTo: Date())
    }
}

#Preview("Hourly Schedule") {
    ScheduleCronView(schedule: Schedule(
        name: "hourly-task",
        key: nil,
        cron: "0 * * * *",
        timezone: "America/New_York",
        data: nil,
        options: nil,
        createdOn: Date(),
        updatedOn: Date()
    ))
    .frame(width: 400)
}

#Preview("Daily Schedule") {
    ScheduleCronView(schedule: MockData.schedules[0])
        .frame(width: 400)
}

#Preview("Every 15 Minutes") {
    ScheduleCronView(schedule: MockData.schedules[2])
        .frame(width: 400)
}
