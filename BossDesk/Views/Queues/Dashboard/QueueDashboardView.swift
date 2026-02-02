//
//  QueueDashboardView.swift
//  BossDesk
//
//  Created by thales on 2026-01-30.
//

import SwiftUI

struct QueueDashboardView: View {
    let queue: Queue
    @Bindable var store: QueueStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxLarge) {
                QueueHealthSection(
                    queueStatus: store.queueStatus,
                    historicalStats: store.dashboardStats,
                    throughputData: store.throughputData,
                    isLoadingQueueStatus: store.isLoadingQueueStatus,
                    isLoadingHistoricalStats: store.isLoadingDashboard,
                    isLoadingThroughput: store.isLoadingThroughput,
                    timeRange: $store.dashboardTimeRange,
                    onTimeRangeChange: { newValue in
                        await store.setDashboardTimeRange(newValue)
                    }
                )
            }
            .padding(DesignTokens.Spacing.xxLarge)
        }
        .task(id: store.selectedQueueId) {
            guard store.selectedQueueId != nil else { return }
            await store.refreshDashboardStats()
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var store = QueueStore()

        let queue = Queue(
            id: "email-notifications",
            stats: QueueStats(created: 5, retry: 2, active: 10, completed: 150, failed: 3, cancelled: 1)
        )

        var body: some View {
            QueueDashboardView(queue: queue, store: store)
                .frame(width: 700, height: 500)
                .onAppear {
                    store.queueStatus = QueueStatus(
                        createdJobs: 50,
                        activeJobs: 25,
                        retryJobs: 10,
                        estimatedCompletion: 360
                    )
                    store.dashboardStats = DashboardStats(
                        totalJobs: 1234,
                        completedJobs: 1000,
                        failedJobs: 25,
                        cancelledJobs: 124,
                        timeRange: .twentyFourHours,
                        avgProcessingTime: 5.2,
                        avgWaitTime: 12.8,
                        avgEndToEndTime: 18.0
                    )

                    // Generate sample throughput data
                    let now = Date()
                    let points: [ThroughputDataPoint] = (0..<12).flatMap { i -> [ThroughputDataPoint] in
                        let timestamp = now.addingTimeInterval(-Double(11 - i) * 3600)
                        return [
                            ThroughputDataPoint(timestamp: timestamp, category: "Completed", count: Int.random(in: 50...200)),
                            ThroughputDataPoint(timestamp: timestamp, category: "Failed", count: Int.random(in: 0...10))
                        ]
                    }
                    store.throughputData = ThroughputData(points: points)
                }
        }
    }

    return PreviewWrapper()
}
