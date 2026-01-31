//
//  TimeRange.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-30.
//

import Foundation

enum TimeRange: String, CaseIterable, Identifiable {
    case oneHour = "1h"
    case threeHours = "3h"
    case twentyFourHours = "24h"
    case sevenDays = "7d"
    case thirtyDays = "30d"
    case all = "all"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .oneHour: return "1 Hour"
        case .threeHours: return "3 Hours"
        case .twentyFourHours: return "24 Hours"
        case .sevenDays: return "7 Days"
        case .thirtyDays: return "30 Days"
        case .all: return "All Time"
        }
    }

    func startDate(from date: Date = Date()) -> Date? {
        switch self {
        case .oneHour:
            return date.addingTimeInterval(-3600)
        case .threeHours:
            return date.addingTimeInterval(-3600 * 3)
        case .twentyFourHours:
            return date.addingTimeInterval(-3600 * 24)
        case .sevenDays:
            return date.addingTimeInterval(-3600 * 24 * 7)
        case .thirtyDays:
            return date.addingTimeInterval(-3600 * 24 * 30)
        case .all:
            return nil
        }
    }
}
