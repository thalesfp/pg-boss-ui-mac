import SwiftUI

/// Displays schedule creation and update timestamps
struct ScheduleTimestampsView: View {
    let schedule: Schedule
    @State private var createdRelative: String = ""
    @State private var updatedRelative: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            Text("Timestamps")
                .font(.headline)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                timestampRow(label: "Created", date: schedule.createdOn, relative: createdRelative)
                timestampRow(label: "Updated", date: schedule.updatedOn, relative: updatedRelative)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.medium)
        .task(id: "\(schedule.id)|\(schedule.createdOn)|\(schedule.updatedOn)") {
            // Initial calculation
            updateRelativeTimestamps()

            // Periodic recalculation loop (every 60 seconds)
            // Ensures relative timestamps stay fresh as time passes
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))

                guard !Task.isCancelled else { break }
                updateRelativeTimestamps()
            }
        }
    }

    @ViewBuilder
    private func timestampRow(label: String, date: Date, relative: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)

            Text(date, formatter: DesignTokens.DateFormat.shortDateTime)
                .font(.system(.body, design: .monospaced))

            Text("(\(relative))")
                .foregroundColor(.secondary)
        }
        .font(.subheadline)
    }

    private func updateRelativeTimestamps() {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        createdRelative = formatter.localizedString(for: schedule.createdOn, relativeTo: Date())
        updatedRelative = formatter.localizedString(for: schedule.updatedOn, relativeTo: Date())
    }
}

#Preview("Schedule Timestamps") {
    ScheduleTimestampsView(schedule: MockData.schedules[0])
        .frame(width: 400)
}
