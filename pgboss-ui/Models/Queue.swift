//
//  Queue.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-29.
//

import Foundation

struct Queue: Identifiable, Hashable {
    let id: String  // queue name
    var name: String { id }
    var stats: QueueStats
    var config: QueueConfig?  // nil for legacy/v9
}

struct QueueStats: Hashable {
    var created: Int = 0
    var retry: Int = 0
    var active: Int = 0
    var completed: Int = 0
    var failed: Int = 0
    var cancelled: Int = 0

    var total: Int {
        created + retry + active + completed + failed + cancelled
    }
}

struct QueueConfig: Hashable {
    var retentionSeconds: Int?     // stored as seconds (v10 converts from minutes)
    var deletionSeconds: Int?      // v11+ only (nil for v10)
    var expireSeconds: Int?
    var retryLimit: Int?
    var policy: String?
}

extension QueueConfig {
    func formattedRetention() -> String? {
        guard let seconds = retentionSeconds else { return nil }
        return Self.formatDuration(seconds: seconds)
    }

    func formattedDeletion() -> String? {
        guard let seconds = deletionSeconds else { return nil }
        return Self.formatDuration(seconds: seconds)
    }

    func formattedExpire() -> String? {
        guard let seconds = expireSeconds else { return nil }
        return Self.formatDuration(seconds: seconds)
    }

    static func formatDuration(seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes)m"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return "\(hours)h"
        } else {
            let days = seconds / 86400
            return "\(days)d"
        }
    }
}
