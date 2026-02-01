import SwiftUI

/// Displays schedule identity information (name with calendar icon)
struct ScheduleIdentityView: View {
    let schedule: Schedule

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            HStack(spacing: DesignTokens.Spacing.small) {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
                    .font(.title2)

                Text(schedule.name)
                    .font(.system(size: 18, weight: DesignTokens.Typography.queueNameWeight))
            }

            // Show key if present (v11+ schedules)
            if let key = schedule.key, !key.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                    Text(key)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.medium)
    }
}

#Preview("Schedule Identity") {
    ScheduleIdentityView(schedule: MockData.schedules[0])
        .frame(width: 400)
}
