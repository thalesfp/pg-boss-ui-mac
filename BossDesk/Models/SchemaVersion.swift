//
//  SchemaVersion.swift
//  BossDesk
//
//  Created by Claude Code on 2026-02-02.
//

import Foundation

/// Represents the pg-boss schema version number from the version table
nonisolated struct SchemaVersion: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    let rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    // Known schema version constants
    static let schema20 = SchemaVersion(rawValue: 20)
    static let schema24 = SchemaVersion(rawValue: 24)
    static let schema26 = SchemaVersion(rawValue: 26)
    static let schema27 = SchemaVersion(rawValue: 27)

    // Range-based grouping for adapter selection
    var adapterGroup: AdapterGroup {
        switch rawValue {
        case 20...23: return .camelCase
        case 24...25: return .snakeCaseV10
        case 26...27: return .snakeCaseV11Plus
        default: return .unknown
        }
    }

    var displayName: String {
        "Schema v\(rawValue)"
    }

    // Comparable conformance
    static func < (lhs: SchemaVersion, rhs: SchemaVersion) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

nonisolated enum AdapterGroup: String, Sendable {
    case camelCase          // Schema 20-23: camelCase columns, no queue table
    case snakeCaseV10       // Schema 24-25: snake_case, queue/schedule, expire_in
    case snakeCaseV11Plus   // Schema 26-27: snake_case, expire_seconds, advanced
    case unknown            // Unsupported schema version

    var displayName: String {
        switch self {
        case .camelCase: return "pg-boss v7-9 (camelCase)"
        case .snakeCaseV10: return "pg-boss v10 (snake_case)"
        case .snakeCaseV11Plus: return "pg-boss v11+ (snake_case)"
        case .unknown: return "Unknown/Unsupported"
        }
    }
}
