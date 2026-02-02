//
//  QueueHealthSection.swift
//  BossDesk
//
//  Created by thales on 2026-01-30.
//

import SwiftUI

struct QueueHealthSection: View {
    let queueStatus: QueueStatus
    let historicalStats: DashboardStats
    let throughputData: ThroughputData
    let isLoadingQueueStatus: Bool
    let isLoadingHistoricalStats: Bool
    let isLoadingThroughput: Bool
    @Binding var timeRange: TimeRange
    var onTimeRangeChange: (TimeRange) async -> Void

    private var failureRateColor: Color {
        let rate = historicalStats.failureRate
        if rate < 5 {
            return .green
        } else if rate < 10 {
            return .orange
        } else {
            return .red
        }
    }

    private var failureSubtitle: String {
        let processed = historicalStats.completedJobs + historicalStats.failedJobs
        if processed == 0 {
            return "No processed jobs"
        }
        return "\(historicalStats.failedJobs) failed of \(processed.formatted())"
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.large) {
            // Queue Status Section (live snapshot - not affected by time range)
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                sectionHeader("Queue Status")

                HStack(spacing: DesignTokens.Spacing.medium) {
                    CompactHealthCard(
                        title: "Created",
                        value: isLoadingQueueStatus ? "-" : queueStatus.createdJobs.formatted(),
                        icon: "plus.circle.fill",
                        color: .gray,
                        tooltip: "Jobs waiting to be picked up"
                    )
                    CompactHealthCard(
                        title: "Active",
                        value: isLoadingQueueStatus ? "-" : queueStatus.activeJobs.formatted(),
                        icon: "play.circle.fill",
                        color: .blue,
                        tooltip: "Jobs currently being processed"
                    )
                    CompactHealthCard(
                        title: "Retry",
                        value: isLoadingQueueStatus ? "-" : queueStatus.retryJobs.formatted(),
                        icon: "arrow.clockwise.circle.fill",
                        color: .orange,
                        tooltip: "Jobs waiting to retry after failure"
                    )
                    CompactHealthCard(
                        title: "Est. Completion",
                        value: isLoadingQueueStatus ? "-" : queueStatus.estimatedCompletionFormatted,
                        icon: "hourglass",
                        color: .green,
                        tooltip: "Estimated time to clear pending jobs based on recent throughput"
                    )
                }
            }

            // Historical Section (affected by time range)
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                HStack {
                    sectionHeader(historicalStats.timeRange.displayName)
                    Spacer()
                    TimeRangePicker(selection: Binding(
                        get: { timeRange },
                        set: { newValue in
                            Task { await onTimeRangeChange(newValue) }
                        }
                    ))
                }

                // Summary row: Total Jobs and Failure Rate
                HStack(spacing: DesignTokens.Spacing.xLarge) {
                    HealthCard(
                        title: "Total Jobs",
                        value: isLoadingHistoricalStats ? "-" : historicalStats.totalJobs.formatted(),
                        subtitle: nil,
                        icon: "number.square.fill",
                        color: .blue,
                        tooltip: "All jobs created in the selected time range"
                    )

                    HealthCard(
                        title: "Failure Rate",
                        value: isLoadingHistoricalStats ? "-" : historicalStats.failureRateFormatted,
                        subtitle: isLoadingHistoricalStats ? nil : failureSubtitle,
                        icon: "exclamationmark.triangle.fill",
                        color: isLoadingHistoricalStats ? .gray : failureRateColor,
                        tooltip: "Percentage of processed jobs that failed"
                    )
                }

                // Outcomes row
                HStack(spacing: DesignTokens.Spacing.medium) {
                    CompactHealthCard(
                        title: "Completed",
                        value: isLoadingHistoricalStats ? "-" : historicalStats.completedJobs.formatted(),
                        icon: "checkmark.circle.fill",
                        color: .green,
                        tooltip: "Jobs that finished successfully"
                    )
                    CompactHealthCard(
                        title: "Failed",
                        value: isLoadingHistoricalStats ? "-" : historicalStats.failedJobs.formatted(),
                        icon: "xmark.circle.fill",
                        color: .red,
                        tooltip: "Jobs that ended in failure"
                    )
                    CompactHealthCard(
                        title: "Cancelled",
                        value: isLoadingHistoricalStats ? "-" : historicalStats.cancelledJobs.formatted(),
                        icon: "slash.circle.fill",
                        color: .purple,
                        tooltip: "Jobs that were cancelled before completion"
                    )
                }

                // Performance row
                HStack(spacing: DesignTokens.Spacing.medium) {
                    CompactHealthCard(
                        title: "Avg Processing",
                        value: isLoadingHistoricalStats ? "-" : historicalStats.avgProcessingTimeFormatted,
                        icon: "gearshape.fill",
                        color: .blue,
                        tooltip: "Mean time from job start to completion"
                    )
                    CompactHealthCard(
                        title: "Avg Wait",
                        value: isLoadingHistoricalStats ? "-" : historicalStats.avgWaitTimeFormatted,
                        icon: "clock.fill",
                        color: .orange,
                        tooltip: "Mean time jobs waited before starting"
                    )
                    CompactHealthCard(
                        title: "End-to-End",
                        value: isLoadingHistoricalStats ? "-" : historicalStats.avgEndToEndTimeFormatted,
                        icon: "arrow.right.circle.fill",
                        color: .purple,
                        tooltip: "Mean total time from creation to completion"
                    )
                }

                // Throughput chart
                ThroughputChartView(
                    data: throughputData,
                    timeRange: historicalStats.timeRange,
                    isLoading: isLoadingThroughput
                )
            }
        }
    }
}

struct CompactHealthCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let tooltip: String?

    init(title: String, value: String, icon: String, color: Color, tooltip: String? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.tooltip = tooltip
    }

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.small) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)
            }

            Spacer()
        }
        .padding(DesignTokens.Spacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
        .help(tooltip ?? "")
    }
}

#Preview("Healthy") {
    @Previewable @State var timeRange: TimeRange = .twentyFourHours
    let now = Date()
    let points: [ThroughputDataPoint] = (0..<12).flatMap { i -> [ThroughputDataPoint] in
        let timestamp = now.addingTimeInterval(-Double(11 - i) * 3600)
        return [
            ThroughputDataPoint(timestamp: timestamp, category: "Completed", count: Int.random(in: 50...200)),
            ThroughputDataPoint(timestamp: timestamp, category: "Failed", count: Int.random(in: 0...10))
        ]
    }
    QueueHealthSection(
        queueStatus: QueueStatus(
            createdJobs: 50,
            activeJobs: 25,
            retryJobs: 10,
            estimatedCompletion: 360
        ),
        historicalStats: DashboardStats(
            totalJobs: 1234,
            completedJobs: 1000,
            failedJobs: 25,
            cancelledJobs: 124,
            timeRange: .twentyFourHours,
            avgProcessingTime: 5.2,
            avgWaitTime: 12.8,
            avgEndToEndTime: 18.0
        ),
        throughputData: ThroughputData(points: points),
        isLoadingQueueStatus: false,
        isLoadingHistoricalStats: false,
        isLoadingThroughput: false,
        timeRange: $timeRange,
        onTimeRangeChange: { _ in }
    )
    .padding()
    .frame(width: 600)
}

#Preview("Warning") {
    @Previewable @State var timeRange: TimeRange = .sevenDays
    QueueHealthSection(
        queueStatus: QueueStatus(
            createdJobs: 10,
            activeJobs: 0,
            retryJobs: 5,
            estimatedCompletion: 7200
        ),
        historicalStats: DashboardStats(
            totalJobs: 500,
            completedJobs: 450,
            failedJobs: 35,
            cancelledJobs: 0,
            timeRange: .sevenDays,
            avgProcessingTime: 125,
            avgWaitTime: 3600,
            avgEndToEndTime: 3725
        ),
        throughputData: .empty,
        isLoadingQueueStatus: false,
        isLoadingHistoricalStats: false,
        isLoadingThroughput: false,
        timeRange: $timeRange,
        onTimeRangeChange: { _ in }
    )
    .padding()
    .frame(width: 600)
}

#Preview("Critical") {
    @Previewable @State var timeRange: TimeRange = .oneHour
    QueueHealthSection(
        queueStatus: QueueStatus(
            createdJobs: 0,
            activeJobs: 0,
            retryJobs: 5,
            estimatedCompletion: nil
        ),
        historicalStats: DashboardStats(
            totalJobs: 100,
            completedJobs: 80,
            failedJobs: 15,
            cancelledJobs: 0,
            timeRange: .oneHour,
            avgProcessingTime: nil,
            avgWaitTime: nil,
            avgEndToEndTime: nil
        ),
        throughputData: .empty,
        isLoadingQueueStatus: false,
        isLoadingHistoricalStats: false,
        isLoadingThroughput: false,
        timeRange: $timeRange,
        onTimeRangeChange: { _ in }
    )
    .padding()
    .frame(width: 600)
}

#Preview("Loading") {
    @Previewable @State var timeRange: TimeRange = .twentyFourHours
    QueueHealthSection(
        queueStatus: .empty,
        historicalStats: .empty,
        throughputData: .empty,
        isLoadingQueueStatus: true,
        isLoadingHistoricalStats: true,
        isLoadingThroughput: true,
        timeRange: $timeRange,
        onTimeRangeChange: { _ in }
    )
    .padding()
    .frame(width: 600)
}
