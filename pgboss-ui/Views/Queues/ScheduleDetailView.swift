import SwiftUI

/// Main detail view for displaying schedule information
struct ScheduleDetailView: View {
    let schedule: Schedule

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Identity
                ScheduleIdentityView(schedule: schedule)

                Divider()
                    .frame(height: DesignTokens.Divider.height)

                // Cron Expression
                ScheduleCronView(schedule: schedule)

                Divider()
                    .frame(height: DesignTokens.Divider.height)

                // Timestamps
                ScheduleTimestampsView(schedule: schedule)

                // Schedule Data (if present)
                if let data = schedule.data {
                    Divider()
                        .frame(height: DesignTokens.Divider.height)

                    JobDataSectionView(
                        title: "Schedule Data",
                        json: data
                    )
                }

                // Job Options (if present)
                if let options = schedule.options {
                    Divider()
                        .frame(height: DesignTokens.Divider.height)

                    JobDataSectionView(
                        title: "Job Options",
                        json: options
                    )
                }
            }
            .padding()
        }
    }
}

#Preview("Schedule with Data") {
    ScheduleDetailView(schedule: MockData.schedules[2])
        .frame(width: 600, height: 800)
}

#Preview("Schedule without Data") {
    ScheduleDetailView(schedule: MockData.schedules[1])
        .frame(width: 600, height: 800)
}

#Preview("Daily Report Schedule") {
    ScheduleDetailView(schedule: MockData.schedules[0])
        .frame(width: 600, height: 800)
}
