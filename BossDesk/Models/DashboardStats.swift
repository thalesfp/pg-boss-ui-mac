//
//  DashboardStats.swift
//  BossDesk
//
//  Created by thales on 2026-01-30.
//

import Foundation

// MARK: - Queue Status (Live, not time-filtered)

/// Live queue status showing current state of jobs.
/// This data is NOT affected by time range filters.
struct QueueStatus: Equatable {
    let createdJobs: Int
    let activeJobs: Int
    let retryJobs: Int
    let estimatedCompletion: TimeInterval?

    var pendingJobs: Int {
        createdJobs + retryJobs
    }

    var estimatedCompletionFormatted: String {
        formatDuration(estimatedCompletion)
    }

    private func formatDuration(_ interval: TimeInterval?) -> String {
        guard let interval = interval, interval >= 0 else { return "-" }

        let totalSeconds = Int(interval)

        if totalSeconds < 60 {
            return "\(totalSeconds)s"
        }

        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(hours)h"
        }

        if seconds > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(minutes)m"
    }

    static let empty = QueueStatus(
        createdJobs: 0,
        activeJobs: 0,
        retryJobs: 0,
        estimatedCompletion: nil
    )
}

// MARK: - Recent Completion Metrics

/// Metrics from recently completed jobs (last 15 minutes).
/// Used for calculating estimated completion time without historical time range dependency.
struct RecentCompletionMetrics: Equatable {
    let completedCount: Int
    let avgProcessingTime: TimeInterval?  // in seconds

    static let empty = RecentCompletionMetrics(
        completedCount: 0,
        avgProcessingTime: nil
    )
}

// MARK: - Dashboard Stats (Historical, time-filtered)

/// Historical statistics that ARE affected by time range filters.
struct DashboardStats: Equatable {
    let totalJobs: Int
    let completedJobs: Int
    let failedJobs: Int
    let cancelledJobs: Int
    let timeRange: TimeRange

    // Time-based metrics (in seconds, nil if no data available)
    let avgProcessingTime: TimeInterval?
    let avgWaitTime: TimeInterval?
    let avgEndToEndTime: TimeInterval?

    var failureRate: Double {
        let processedJobs = completedJobs + failedJobs
        guard processedJobs > 0 else { return 0 }
        return Double(failedJobs) / Double(processedJobs) * 100
    }

    var failureRateFormatted: String {
        String(format: "%.1f%%", failureRate)
    }

    // MARK: - Time Metric Formatting

    var avgProcessingTimeFormatted: String {
        formatDuration(avgProcessingTime)
    }

    var avgWaitTimeFormatted: String {
        formatDuration(avgWaitTime)
    }

    var avgEndToEndTimeFormatted: String {
        formatDuration(avgEndToEndTime)
    }

    private func formatDuration(_ interval: TimeInterval?) -> String {
        guard let interval = interval, interval >= 0 else { return "-" }

        let totalSeconds = Int(interval)

        if totalSeconds < 60 {
            return "\(totalSeconds)s"
        }

        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(hours)h"
        }

        if seconds > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(minutes)m"
    }

    static let empty = DashboardStats(
        totalJobs: 0,
        completedJobs: 0,
        failedJobs: 0,
        cancelledJobs: 0,
        timeRange: TimeRange.twentyFourHours,
        avgProcessingTime: nil as TimeInterval?,
        avgWaitTime: nil as TimeInterval?,
        avgEndToEndTime: nil as TimeInterval?
    )
}
