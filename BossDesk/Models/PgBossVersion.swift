//
//  PgBossVersion.swift
//  BossDesk
//
//  Created by thales on 2026-01-30.
//

import Foundation

/// Represents the pg-boss schema version selected by the user
enum PgBossVersion: String, Comparable, Hashable, Codable, CaseIterable, Sendable {
    case legacy      // v7/v8 - camelCase columns, limited features
    case v9          // v9 - camelCase columns, no schedule table, has archive
    case v10         // v10 - snake_case columns, schedule support, has archive
    case v11Plus     // v11+ - snake_case columns, no archive table, partitioned

    /// Major version number for display purposes
    var majorVersion: Int {
        switch self {
        case .legacy: return 8
        case .v9: return 9
        case .v10: return 10
        case .v11Plus: return 11
        }
    }

    /// Whether this version uses snake_case column names (v10+)
    var hasSnakeCaseColumns: Bool {
        switch self {
        case .legacy, .v9:
            return false
        case .v10, .v11Plus:
            return true
        }
    }

    /// Whether this version has archive tables (pre-v11)
    var hasArchiveTables: Bool {
        switch self {
        case .legacy, .v9, .v10:
            return true
        case .v11Plus:
            return false
        }
    }

    /// Whether this version has the schedule table (v10+)
    var hasScheduleTable: Bool {
        switch self {
        case .legacy, .v9:
            return false
        case .v10, .v11Plus:
            return true
        }
    }

    /// Whether this version uses table partitioning (v11+)
    var usesPartitioning: Bool {
        switch self {
        case .v11Plus:
            return true
        case .legacy, .v9, .v10:
            return false
        }
    }

    /// Display name for UI presentation
    var displayName: String {
        switch self {
        case .legacy:
            return "pg-boss 7/8"
        case .v9:
            return "pg-boss 9.x"
        case .v10:
            return "pg-boss 10.x"
        case .v11Plus:
            return "pg-boss 11+"
        }
    }

    /// Comparable conformance for version ordering
    static func < (lhs: PgBossVersion, rhs: PgBossVersion) -> Bool {
        let order: [PgBossVersion] = [.legacy, .v9, .v10, .v11Plus]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}
