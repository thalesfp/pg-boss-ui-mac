//
//  ThroughputDataPoint.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-30.
//

import Foundation

/// A single data point for throughput chart (one per bucket per category)
struct ThroughputDataPoint: Identifiable, Equatable {
    var id: String { "\(timestamp.timeIntervalSince1970)-\(category)" }
    let timestamp: Date       // Start of the bucket
    let category: String      // "Completed" or "Failed"
    let count: Int            // Number of jobs
}

/// Container for all throughput data in a time range
struct ThroughputData: Equatable {
    let points: [ThroughputDataPoint]

    static let empty = ThroughputData(points: [])
}

extension TimeRange {
    /// Bucket interval for throughput chart (in seconds)
    var bucketIntervalSeconds: Int {
        switch self {
        case .oneHour: return 300        // 5 min (12 points)
        case .threeHours: return 900     // 15 min (12 points)
        case .twentyFourHours: return 3600  // 1 hour (24 points)
        case .sevenDays: return 86400    // 1 day (7 points)
        case .thirtyDays: return 86400   // 1 day (30 points)
        case .all: return 86400          // 1 day
        }
    }
}
