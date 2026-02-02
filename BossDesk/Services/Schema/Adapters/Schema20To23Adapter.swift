//
//  Schema20To23Adapter.swift
//  BossDesk
//
//  Created by Claude Code on 2026-02-02.
//

import Foundation

/// Adapter for schema versions 20-23 (pg-boss v7.4 - v9.x)
/// - camelCase column naming
/// - No queue or schedule tables
/// - Basic job table structure
struct Schema20To23Adapter: SchemaProvider {
    let adapterGroup: AdapterGroup = .camelCase
    let supportedVersionRange: ClosedRange<Int> = 20...23
    let schema: String

    let jobColumns: JobColumnMapping = .camelCase
    let scheduleColumns: ScheduleColumnMapping? = nil

    nonisolated init(schema: String = "pgboss") {
        self.schema = schema
    }

    func fetchQueueConfigSQL() -> String? {
        nil  // No queue table in schema 20-23
    }

    func fetchSchedulesSQL() -> String? {
        nil  // No schedule table in schema 20-23
    }
}
