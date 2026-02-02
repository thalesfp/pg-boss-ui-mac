//
//  Schema24To25Adapter.swift
//  BossDesk
//
//  Created by Claude Code on 2026-02-02.
//

import Foundation

/// Adapter for schema versions 24-25 (pg-boss v10.x)
/// - snake_case column naming
/// - Has queue and schedule tables
/// - Uses expire_in (interval) column
struct Schema24To25Adapter: SchemaProvider {
    let adapterGroup: AdapterGroup = .snakeCaseV10
    let supportedVersionRange: ClosedRange<Int> = 24...25
    let schema: String

    let jobColumns: JobColumnMapping = .snakeCase
    let scheduleColumns: ScheduleColumnMapping? = .snakeCaseV10

    nonisolated init(schema: String = "pgboss") {
        self.schema = schema
    }

    func fetchQueueConfigSQL() -> String? {
        """
        SELECT name, retention_minutes, expire_seconds, retry_limit, policy
        FROM \(schema).queue
        """
    }

    func fetchSchedulesSQL() -> String? {
        let cols = scheduleColumns!
        return """
            SELECT \(cols.name), \(cols.cron), \(cols.timezone), \
            \(cols.data)::text, \(cols.options)::text, \
            \(cols.createdOn), \(cols.updatedOn)
            FROM \(schema).schedule
            ORDER BY \(cols.name)
            """
    }
}
